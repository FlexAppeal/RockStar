public struct PromiseTimeout: Error {
    public init() {}
}

extension Promise {
    @discardableResult
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> Promise<FutureValue> {
        timeout.execute {
            self.fail(error)
        }
        
        return self
    }
}

extension Future {
    @discardableResult
    public func cancelAfter(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> Future<FutureValue> {
        timeout.execute(self.cancel)
        
        return self
    }
    
    public func deplayCompletion<T>(untilAfter future: Future<T>) -> Future<FutureValue> {
        return future.transform(to: self)
    }
}
