public struct OutputStream<FutureValue> {
    let inputStream: InputStream<FutureValue>
    
    init(inputStream: InputStream<FutureValue>) {
        self.inputStream = inputStream
    }
    
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> OutputStream<R> {
        let newInputStream = InputStream<R>()
        self.inputStream.registerCallback { result in
            do {
                switch result {
                case .success(let value):
                    try newInputStream.next(mapper(value))
                case .failure(let error):
                    newInputStream.error(error)
                case .cancelled:
                    newInputStream.cancel()
                }
            } catch {
                newInputStream.error(error)
            }
        }
        
        return newInputStream.listener
    }
    
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Future<R>)) -> OutputStream<R> {
        let newInputStream = InputStream<R>()
        self.then { value in
            do {
                try mapper(value).onCompletion(newInputStream.write)
            } catch {
                newInputStream.error(error)
            }
        }.catch(newInputStream.error)
        
        return newInputStream.listener
    }
    
    public func cancel() {
        self.inputStream.cancel()
    }
    
    public func always(run: @escaping () -> ()) {
        self.onCompletion { _ in run() }
    }
    
    @discardableResult
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) -> OutputStream<FutureValue> {
        self.inputStream.registerCallback(handle)
        
        return self
    }
    
    public func then(_ handle: @escaping (FutureValue) -> ()) -> OutputStream<FutureValue> {
        self.inputStream.registerCallback { result in
            if case .success(let value) = result {
                handle(value)
            }
        }
        
        return self
    }
    
    @discardableResult
    public func `catch`(_ handle: @escaping (Error) -> ()) -> OutputStream<FutureValue> {
        self.inputStream.registerCallback { result in
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
    ) -> OutputStream<FutureValue> {
        self.catch { error in
            if let error = error as? E {
                handle(error)
            }
        }
        
        return self
    }
}
