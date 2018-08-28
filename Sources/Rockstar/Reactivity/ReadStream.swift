public struct ReadStream<FutureValue> {
    let writeStream: WriteStream<FutureValue>
    
    init(writeStream: WriteStream<FutureValue>) {
        self.writeStream = writeStream
    }
    
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> ReadStream<R> {
        let newWriteStream = WriteStream<R>()
        self.writeStream.registerCallback { result in
            do {
                switch result {
                case .success(let value):
                    try newWriteStream.next(mapper(value))
                case .failure(let error):
                    newWriteStream.error(error)
                case .cancelled:
                    newWriteStream.cancel()
                }
            } catch {
                newWriteStream.error(error)
            }
        }
        
        return newWriteStream.listener
    }
    
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Future<R>)) -> ReadStream<R> {
        let newWriteStream = WriteStream<R>()
        self.then { value in
            do {
                try mapper(value).onCompletion(newWriteStream.write)
            } catch {
                newWriteStream.error(error)
            }
            }.catch(newWriteStream.error)
        
        return newWriteStream.listener
    }
    
    public func cancel() {
        self.writeStream.cancel()
    }
    
    public func ifNotCancelled(run: @escaping () -> ()) {
        self.onCompletion { value in
            if case .cancelled = value { return }
            
            run()
        }
    }
    
    public func always(run: @escaping () -> ()) {
        self.onCompletion { _ in run() }
    }
    
    @discardableResult
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) -> ReadStream<FutureValue> {
        self.writeStream.registerCallback(handle)
        
        return self
    }
    
    public func then(_ handle: @escaping (FutureValue) -> ()) -> ReadStream<FutureValue> {
        self.writeStream.registerCallback { result in
            if case .success(let value) = result {
                handle(value)
            }
        }
        
        return self
    }
    
    @discardableResult
    public func `catch`(_ handle: @escaping (Error) -> ()) -> ReadStream<FutureValue> {
        self.writeStream.registerCallback { result in
            if case .failure(let error) = result {
                handle(error)
            }
        }
        
        return self
    }
    
    public func bind(to binding: Binding<FutureValue>) {
        weak var binding = binding
        
        self.then { newValue in
            binding?.update(to: newValue)
        }
    }
    
    @discardableResult
    public func `catch`<E: Error>(
        _ errorType: E.Type,
        _ handle: @escaping (E) -> ()
        ) -> ReadStream<FutureValue> {
        self.catch { error in
            if let error = error as? E {
                handle(error)
            }
        }
        
        return self
    }
    
    @discardableResult
    public func onCancel(_ run: @escaping () -> ()) -> ReadStream<FutureValue> {
        return self.onCompletion { value in
            if case .cancelled = value {
                run()
            }
        }
    }
    
    public func flatten<T>() -> ReadStream<T> where FutureValue == Future<T> {
        let write = WriteStream<T>()
        
        self.then { future in
            future.then(write.next).catch(write.error).onCancel(write.cancel)
            }.catch(write.error).onCancel(write.cancel)
        
        return write.listener
    }
    
    public func filterMap<T>(_  mapper: @escaping (FutureValue) -> T?) -> ReadStream<T> {
        let writer = WriteStream<T>()
        
        self.then { value in
            if let mapped = mapper(value) {
                writer.next(mapped)
            }
            }.catch { error in
                writer.error(error)
        }
        
        return writer.listener
    }
    
    public func filter(_ condition: @escaping (FutureValue) -> (Bool)) -> ReadStream<FutureValue> {
        let writer = WriteStream<FutureValue>()
        
        self.then { value in
            if condition(value) {
                writer.next(value)
            }
            }.catch { error in
                writer.error(error)
        }
        
        return writer.listener
    }
}
