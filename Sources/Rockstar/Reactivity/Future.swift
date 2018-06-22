public struct Future<FutureValue> {
    enum Storage {
        case concrete(Observation<FutureValue>)
        case promise(Promise<FutureValue>)
    }
    
    let storage: Storage
    
    public init(error: Error) {
        self.storage = .concrete(.failure(error))
    }
    
    public init(result: FutureValue) {
        self.storage = .concrete(.success(result))
    }
    
    private init() {
        self.storage = .concrete(.cancelled)
    }
    
    public static var cancelled: Future<FutureValue> {
        return .init()
    }
    
    init(promise: Promise<FutureValue>) {
        self.storage = .promise(promise)
    }
    
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> Future<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Future<R>(error: error)
            case .success(let value):
                do {
                    return Future<R>(result: try mapper(value))
                } catch {
                    return Future<R>(error: error)
                }
            case .cancelled:
                return Future<R>.cancelled
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
    
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Future<R>)) -> Future<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Future<R>(error: error)
            case .success(let value):
                do {
                    return try mapper(value)
                } catch {
                    return Future<R>(error: error)
                }
            case .cancelled:
                return Future<R>.cancelled
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
    
    public func cancel() {
        if case .promise(let promise) = storage {
            promise.cancel()
        }
    }
    
    @discardableResult
    public func always(_ run: @escaping () -> ()) -> Future<FutureValue> {
        self.onCompletion { _ in run() }
        return self
    }
    
    @discardableResult
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) -> Future<FutureValue> {
        switch storage {
        case .concrete(let result):
            handle(result)
        case .promise(let promise):
            promise.registerCallback(handle)
        }
        
        return self
    }
    
    public func then(_ handle: @escaping (FutureValue) -> ()) -> Future<FutureValue> {
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
    public func `catch`(_ handle: @escaping (Error) -> ()) -> Future<FutureValue> {
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
    public func `catch`<E: Error>(
        _ errorType: E.Type,
        _ handle: @escaping (E) -> ()
    ) -> Future<FutureValue> {
        self.catch { error in
            if let error = error as? E {
                handle(error)
            }
        }
        
        return self
    }
}
