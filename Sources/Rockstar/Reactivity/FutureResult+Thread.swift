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


extension ReadStream {
    public func switchThread(to thread: AnyThread) -> ReadStream<FutureValue> {
        let writeStream = WriteStream<FutureValue>()
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                writeStream.write(result)
            }
        }
        
        writeStream.onCancel(run: self.cancel)
        return writeStream.listener
    }
    
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> ReadStream<FutureValue> {
        let writeStream = WriteStream<FutureValue>()
        self.onCompletion(writeStream.write)
        
        timeout.execute {
            writeStream.fatal(error)
        }
        
        return writeStream.listener
    }
}
