/// Indirect so that futures nested in futures don't crash
public indirect enum Observation<T> {
    case success(T)
    case failure(Error)
}

public enum ObserverType {
    /// A single notification emitted by a Promise
    case notification
    
    /// Many events emitted by an Observable
    case observation
}

public struct Observable<T> {
    let promise: Promise<T>
    
    public init() {
        self.promise = Promise(singleUse: false)
    }
    
    public func next(_ value: T) {
        promise.complete(value)
    }
    
    public func fail(_ error: Error) {
        promise.fail(error)
    }
    
    public func fatal(_ error: Error) {
        promise.fail(error)
        promise.finalize()
    }
    
    public var observer: Observer<T> {
        return promise.future
    }
}

public final class Promise<T> {
    typealias FutureCallback = (Observation<T>) -> ()
    
    public var future: Observer<T> {
        return Observer(promise: self)
    }
    
    public var isCompleted: Bool {
        return finalized
    }
    
    private var finalized = false
    fileprivate let singleUse: Bool
    
    public init() {
        self.singleUse = true
    }
    
    internal init(singleUse: Bool) {
        self.singleUse = singleUse
    }
    
    private var result: Observation<T>?
    private var callbacks = [FutureCallback]()
    
    internal func registerCallback(_ callback: @escaping FutureCallback) {
        self.callbacks.append(callback)
    }
    
    private func triggerCallbacks(with result: Observation<T>) {
        for callback in callbacks {
            callback(result)
        }
        
        if singleUse {
            self.callbacks = []
        }
    }
    
    public func complete(_ value: T) {
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
        
        let result = Observation<T>.failure(error)
        triggerCallbacks(with: result)
        self.result = result
    }
    
    public func fulfill(_ result: Observation<T>) {
        if finalized { return }
        
        triggerCallbacks(with: result)
    }
}

public struct Observer<T> {
    private enum Storage {
        case concrete(Observation<T>)
        case promise(Promise<T>)
    }
    
    private let storage: Storage
    public let type: ObserverType
    
    public init(error: Error) {
        self.storage = .concrete(.failure(error))
        self.type = .notification
    }
    
    public init(result: T) {
        self.storage = .concrete(.success(result))
        self.type = .notification
    }
    
    fileprivate init(promise: Promise<T>) {
        self.storage = .promise(promise)
        self.type = promise.singleUse ? .notification : .observation
    }
    
    public func onCompletion(_ handle: @escaping (Observation<T>) -> ()) {
        switch storage {
        case .concrete(let result):
            handle(result)
        case .promise(let promise):
            promise.registerCallback(handle)
        }
    }
    
    public func then(_ handle: @escaping (T) -> ()) -> Observer<T> {
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
    public func `catch`(_ handle: @escaping (Error) -> ()) -> Observer<T> {
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
    public func map<R>(_ mapper: @escaping (T) throws -> (R)) -> Observer<R> {
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
    public func flatMap<R>(_ mapper: @escaping (T) throws -> (Observer<R>)) -> Observer<R> {
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
