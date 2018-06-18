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
