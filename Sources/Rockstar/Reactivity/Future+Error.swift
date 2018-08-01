extension Future {
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
