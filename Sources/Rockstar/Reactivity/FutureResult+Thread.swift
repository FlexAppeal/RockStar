extension Future {
    public func switchThread(to thread: AnyThread) -> Future<FutureValue> {
        let promise = Promise<FutureValue>()
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                promise.fulfill(result)
            }
        }
        
        promise.onCancel(self.cancel)
        return promise.future
    }
    
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> Future<FutureValue> {
        let promise = Promise<FutureValue>()
        self.onCompletion(promise.fulfill)
        
        timeout.execute {
            promise.fail(error)
        }
        
        return promise.future
    }
}


extension Observable {
    public func switchThread(to thread: AnyThread) -> Observable<FutureValue> {
        let observer = Observer<FutureValue>()
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                observer.emit(result)
            }
        }
        
        observer.onCancel(self.cancel)
        return observer.observable
    }
    
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> Observable<FutureValue> {
        let observer = Observer<FutureValue>()
        self.onCompletion(observer.emit)
        
        timeout.execute {
            observer.fatal(error)
        }
        
        return observer.observable
    }
}
