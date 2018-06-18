public struct Observable<FutureValue> {
    let observer: Observer<FutureValue>
    
    init(observer: Observer<FutureValue>) {
        self.observer = observer
    }
    
    @discardableResult
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> Observable<R> {
        let newObserver = Observer<R>()
        self.observer.registerCallback { result in
            do {
                switch result {
                case .success(let value):
                    try newObserver.next(mapper(value))
                case .failure(let error):
                    newObserver.error(error)
                case .cancelled:
                    newObserver.cancel()
                }
            } catch {
                newObserver.error(error)
            }
        }
        
        return newObserver.observable
    }
    
    @discardableResult
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Observable<R>)) -> Observable<R> {
        let newObserver = Observer<R>()
        self.then { value in
            do {
                try mapper(value).onCompletion(newObserver.emit)
            } catch {
                newObserver.error(error)
            }
        }.catch(newObserver.error)
        
        return newObserver.observable
    }
    
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue>) -> Observable<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
    
    public func cancel() {
        self.observer.cancel()
    }
    
    public func always(_ run: @escaping () -> ()) {
        self.onCompletion { _ in run() }
    }
    
    @discardableResult
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) -> Observable<FutureValue> {
        self.observer.registerCallback(handle)
        
        return self
    }
    
    public func then(_ handle: @escaping (FutureValue) -> ()) -> Observable<FutureValue> {
        self.observer.registerCallback { result in
            if case .success(let value) = result {
                handle(value)
            }
        }
        
        return self
    }
    
    @discardableResult
    public func `catch`(_ handle: @escaping (Error) -> ()) -> Observable<FutureValue> {
        self.observer.registerCallback { result in
            if case .failure(let error) = result {
                handle(error)
            }
        }
        
        return self
    }
    
    @discardableResult
    public func `catch`<E: Error>(
        _ errorType: E.Type,
        _ handle: @escaping (E) -> ()
    ) -> Observable<FutureValue> {
        self.catch { error in
            if let error = error as? E {
                handle(error)
            }
        }
        
        return self
    }
}
