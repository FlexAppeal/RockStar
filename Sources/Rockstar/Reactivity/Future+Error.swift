// TODO: Stream support
// TODO: Examples

extension Future {
    /// Attempt to map an error into a new succcessful scenario
    public func catchMap(run: @escaping (Error) throws -> FutureValue) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        
        self.then(promise.complete).catch { error in
            do {
                try promise.complete(run(error))
            } catch {
                promise.fail(error)
            }
        }
        
        return promise.future
    }
    
    /// Attempt to map an error of the provided Error type scenarios into a new succcessful scenario
    public func catchMap<E: Error>(_ type: E.Type, run: @escaping (E) throws -> FutureValue) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        
        self.then(promise.complete).catch(type) { error in
            do {
                try promise.complete(run(error))
            } catch {
                promise.fail(error)
            }
        }
        
        return promise.future
    }
    
    /// Attempt to flatMap an error into a new future that might be successful
    public func catchFlatMap(run: @escaping (Error) throws -> Future<FutureValue>) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        
        self.then(promise.complete).catch { error in
            do {
                try run(error).onCompletion(promise.fulfill)
            } catch {
                promise.fail(error)
            }
        }
        
        return promise.future
    }
    
    /// Attempt to flatMap an error of the provided Error type scenarios into a new future that might be successful
    public func catchFlatMap<E: Error>(_ type: E.Type, run: @escaping (E) throws -> Future<FutureValue>) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        
        self.then(promise.complete).catch(type) { error in
            do {
                try run(error).onCompletion(promise.fulfill)
            } catch {
                promise.fail(error)
            }
        }
        
        return promise.future
    }
}
