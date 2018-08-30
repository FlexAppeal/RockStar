/// Used by RockStar as the default promise timeout error
public struct PromiseTimeout: Error {
    public init() {}
}

extension Promise {
    /// Times out the promise with an error after the specified timeout
    ///
    /// Custom errors can be provided
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
    /// Cancels the future after the specified timeout
    ///
    /// Custom errors can be provided
    @discardableResult
    public func cancelAfter(
        _ timeout: RSTimeout
    ) -> Future<FutureValue> {
        timeout.execute(self.cancel)
        
        return self
    }
    
    /// Returns a new future that fails after the timeout has been reached
    ///
    /// Does not cancel the promise
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
        ) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        self.onCompletion(promise.fulfill)
        
        timeout.execute {
            self.cancel()
            promise.fail(error)
        }
        
        return promise.future
    }
    
    /// Returns a future that is completed after the provided `future` is also completed
    ///
    /// Useful for situations where you require an action to be successfully completed before this result
    /// is further processed.
    public func withDelayedCompletion<T>(untilAfter future: Future<T>) -> Future<FutureValue> {
        return future.transform(to: self)
    }
}
