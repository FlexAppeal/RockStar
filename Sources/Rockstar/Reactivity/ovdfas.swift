public struct Observable<FutureValue> {
    typealias PromiseType = Promise<FutureValue>
    
    let observer: Observer<FutureValue>
    
    init(promise: Promise<FutureValue>) {
        self.storage = .promise(promise)
    }
    
    @discardableResult
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> Observable<R> {
        let newObserver = Observable<R>()
        observer.registerCallback { result in
            do {
                switch result {
                case .success(let value):
                    try newPromise.complete(mapper(value))
                case .failure(let error):
                    newObserver.fail(error)
                case .cancelled:
                    newObserver.cancel()
                }
            } catch {
                newObserver.fail(error)
            }
        }
        
        return newObserver.future
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
            let observer = Observer<R>()
            promise.future.then { value in
                do {
                    try mapper(value).onCompletion(observer.fulfill)
                } catch {
                    observer.fail(error)
                }
                }.catch(observer.fail)
            
            return observer.observable
        }
    }
    
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue>) -> Observable<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
}
