public enum ObserverType {
    /// A single notification emitted by a Promise
    case notification
    
    /// Many events emitted by an Observable
    case observation
}

public struct Observable<FutureValue>: ObservationEmitter {
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
        promise.finalize()
    }
    
    public func emit(_ value: Observation<FutureValue>) {
        switch value {
        case .failure(let error): self.error(error)
        case .success(let value): self.next(value)
        }
    }
    
    public var observer: Observer<FutureValue> {
        return promise.future
    }
}

public final class Promise<FutureValue>: PromiseProtocol {
    typealias FutureCallback = (Observation<FutureValue>) -> ()
    
    public var future: Observer<FutureValue> {
        return Observer(promise: self)
    }
    
    public var isCompleted: Bool {
        return finalized
    }
    
    fileprivate var finalized = false
    fileprivate let singleUse: Bool
    fileprivate let cancel: (()->())?
    
    public convenience init() {
        self.init(singleUse: true)
    }
    
    public init(cancel: @escaping ()->()) {
        self.singleUse = true
        self.cancel = cancel
    }
    
    internal init(singleUse: Bool) {
        self.singleUse = singleUse
        self.cancel = nil
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
            self.callbacks = []
        }
    }
    
    public func complete(_ value: FutureValue) {
        if finalized { return }
        
        let result = Observation.success(value)
        triggerCallbacks(with: result)
        self.result = result
    }
    
    internal func finalize() {
        self.finalized = true
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

public struct Observer<FutureValue>: ObserverProtocol {
    private enum Storage {
        case concrete(Observation<FutureValue>)
        case promise(Promise<FutureValue>)
    }
    
    private let storage: Storage
    public let type: ObserverType
    
    public init(error: Error) {
        self.storage = .concrete(.failure(error))
        self.type = .notification
    }
    
    public init(result: FutureValue) {
        self.storage = .concrete(.success(result))
        self.type = .notification
    }
    
    fileprivate init(promise: Promise<FutureValue>) {
        self.storage = .promise(promise)
        self.type = promise.singleUse ? .notification : .observation
    }
    
    public func cancel() {
        if case .promise(let promise) = storage {
            promise.cancel?()
        }
    }
    
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) {
        switch storage {
        case .concrete(let result):
            handle(result)
        case .promise(let promise):
            promise.registerCallback(handle)
        }
    }
    
    public func then(_ handle: @escaping (FutureValue) -> ()) -> Observer<FutureValue> {
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
    public func `catch`(_ handle: @escaping (Error) -> ()) -> Observer<FutureValue> {
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
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> Observer<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Observer<R>(error: error)
            case .success(let value):
                do {
                    return Observer<R>(result: try mapper(value))
                } catch {
                    return Observer<R>(error: error)
                }
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
                    }
                } catch {
                    newPromise.fail(error)
                }
            }
            
            return newPromise.future
        }
    }
    
    @discardableResult
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Observer<R>)) -> Observer<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Observer<R>(error: error)
            case .success(let value):
                do {
                    return try mapper(value)
                } catch {
                    return Observer<R>(error: error)
                }
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
}
