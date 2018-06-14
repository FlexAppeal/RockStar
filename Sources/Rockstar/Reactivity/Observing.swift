public enum ObservableType {
    /// A single notification emitted by a Promise
    case notification
    
    /// Many events emitted by an Observable
    case observation
}

// FIXME: Cancellable observables
public struct Observer<FutureValue>: ObservationEmitter {
    let promise: Promise<FutureValue>
    
    public init() {
        self.promise = Promise(singleUse: false)
    }
    
    public func next(_ value: FutureValue) {
        promise.complete(value)
    }
    
    public func error(_ error: Error) {
        promise.fail(error)
    }
    
    public func fatal(_ error: Error) {
        promise.fail(error)
        promise.cancel()
    }
    
    public func emit(_ value: Observation<FutureValue>) {
        switch value {
        case .failure(let error): self.error(error)
        case .success(let value): self.next(value)
        case .cancelled: self.emit(.cancelled)
        }
    }
    
    public var observable: Observable<FutureValue> {
        return promise.future
    }
}

public final class Promise<FutureValue>: PromiseProtocol {
    typealias FutureCallback = (Observation<FutureValue>) -> ()
    
    public var future: Observable<FutureValue> {
        return Observable(promise: self)
    }
    
    public var isCompleted: Bool {
        return finalized
    }
    
    fileprivate var finalized = false {
        didSet {
            self.callbacks = []
        }
    }
    fileprivate let singleUse: Bool
    fileprivate var cancelAction: (()->())?
    
    public convenience init() {
        self.init(singleUse: true)
    }
    
    public func onCancel(_ run: @escaping () -> ()) {
        self.cancelAction = run
    }
    
    internal init(singleUse: Bool) {
        self.singleUse = singleUse
        self.cancelAction = nil
    }
    
    private var result: Observation<FutureValue>?
    private var callbacks = [FutureCallback]()
    
    internal func registerCallback(_ callback: @escaping FutureCallback) {
        self.callbacks.append(callback)
    }
    
    private func triggerCallbacks(with result: Observation<FutureValue>) {
        for callback in callbacks {
            callback(result)
        }
        
        if singleUse {
            finalized = true
        } else if case .cancelled = result {
            finalized = true
        }
    }
    
    public func complete(_ value: FutureValue) {
        if finalized { return }
        
        let result = Observation.success(value)
        triggerCallbacks(with: result)
        self.result = result
    }
    
    public func cancel() {
        if finalized { return }
        
        triggerCallbacks(with: .cancelled)
        self.cancelAction?()
    }
    
    public func fail(_ error: Error) {
        if finalized { return }
        
        let result = Observation<FutureValue>.failure(error)
        triggerCallbacks(with: result)
        self.result = result
    }
    
    public func fulfill(_ result: Observation<FutureValue>) {
        if finalized { return }
        
        triggerCallbacks(with: result)
    }
}

public struct Observable<FutureValue>: ObservableProtocol {
    private enum Storage {
        case concrete(Observation<FutureValue>)
        case promise(Promise<FutureValue>)
    }
    
    private let storage: Storage
    public let type: ObservableType
    
    public init(error: Error) {
        self.storage = .concrete(.failure(error))
        self.type = .notification
    }
    
    public init(result: FutureValue) {
        self.storage = .concrete(.success(result))
        self.type = .notification
    }
    
    private init() {
        self.storage = .concrete(.cancelled)
        self.type = .notification
    }
    
    public static var cancelled: Observable<FutureValue> {
        return .init()
    }
    
    fileprivate init(promise: Promise<FutureValue>) {
        self.storage = .promise(promise)
        self.type = promise.singleUse ? .notification : .observation
    }
    
    public func cancel() {
        if case .promise(let promise) = storage {
            promise.cancel()
        }
    }
    
    public func finally(_ run: @escaping () -> ()) {
        self.onCompletion { _ in run() }
    }
    
    @discardableResult
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) -> Observable<FutureValue> {
        switch storage {
        case .concrete(let result):
            handle(result)
        case .promise(let promise):
            promise.registerCallback(handle)
        }
        
        return self
    }
    
    public func then(_ handle: @escaping (FutureValue) -> ()) -> Observable<FutureValue> {
        switch storage {
        case .concrete(let result):
            if case .success(let value) = result {
                handle(value)
            }
        case .promise(let promise):
            promise.registerCallback { result in
                if case .success(let value) = result {
                    handle(value)
                }
            }
        }
        
        return self
    }
    
    @discardableResult
    public func `catch`(_ handle: @escaping (Error) -> ()) -> Observable<FutureValue> {
        switch storage {
        case .concrete(let result):
            if case .failure(let error) = result {
                handle(error)
            }
        case .promise(let promise):
            promise.registerCallback { result in
                if case .failure(let error) = result {
                    handle(error)
                }
            }
        }
        
        return self
    }
    
    @discardableResult
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> Observable<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Observable<R>(error: error)
            case .success(let value):
                do {
                    return Observable<R>(result: try mapper(value))
                } catch {
                    return Observable<R>(error: error)
                }
            case .cancelled:
                return Observable<R>.cancelled
            }
        case .promise(let promise):
            let newPromise = Promise<R>()
            promise.registerCallback { result in
                do {
                    switch result {
                    case .success(let value):
                        try newPromise.complete(mapper(value))
                    case .failure(let error):
                        newPromise.fail(error)
                    case .cancelled:
                        newPromise.cancel()
                    }
                } catch {
                    newPromise.fail(error)
                }
            }
            
            return newPromise.future
        }
    }
    
    @discardableResult
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Observable<R>)) -> Observable<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Observable<R>(error: error)
            case .success(let value):
                do {
                    return try mapper(value)
                } catch {
                    return Observable<R>(error: error)
                }
            case .cancelled:
                return Observable<R>.cancelled
            }
        case .promise(let promise):
            let newPromise = Promise<R>()
            promise.future.then { value in
                do {
                    try mapper(value).onCompletion(newPromise.fulfill)
                } catch {
                    newPromise.fail(error)
                }
            }.catch(newPromise.fail)
            
            return newPromise.future
        }
    }
    
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue>) -> Observable<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
}

extension Observable: ExpressibleByIntegerLiteral where FutureValue == Int {
    public typealias IntegerLiteralType = Int
    
    public init(integerLiteral value: Int) {
        self.init(result: value)
    }
}

extension Observable: ExpressibleByBooleanLiteral where FutureValue == Bool {
    public typealias BooleanLiteralType = Bool
    
    public init(booleanLiteral value: Bool) {
        self.init(result: value)
    }
}

extension Observable where FutureValue == Void {
    public static var done: Observable<Void> {
        return Observable(result: ())
    }
}
