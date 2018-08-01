extension Future {
    public func switchThread(to thread: AnyThread) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                promise.fulfill(result)
            }
        }
        
        promise.onCancel(run: self.cancel)
        return promise.future
    }
    
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        self.onCompletion(promise.fulfill)
        
        timeout.execute {
            promise.fail(error)
        }
        
        return promise.future
    }
}


extension OutputStream {
    public func switchThread(to thread: AnyThread) -> OutputStream<FutureValue> {
        let inputStream = InputStream<FutureValue>()
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                inputStream.write(result)
            }
        }
        
        inputStream.onCancel(run: self.cancel)
        return inputStream.listener
    }
    
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> OutputStream<FutureValue> {
        let inputStream = InputStream<FutureValue>()
        self.onCompletion(inputStream.write)
        
        timeout.execute {
            inputStream.fatal(error)
        }
        
        return inputStream.listener
    }
}
