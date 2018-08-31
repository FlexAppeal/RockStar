// TODO: Helpers for retain cycles with strong `self`

/// Similar to the Future in the Promise/Future relationship
/// This is a read-only view into the Write/ReadStream relationship.
///
/// ReadStreams are produced from a WriteStream and can regiser callbacks to notifications written
/// to a WriteStream. ReadStreams cannot exist without their associated WriteStream
///
/// Streams can emit many notifications where Promises/Futures can only emit one.
///
/// WARNING: When adding listeners to a ReadStream, please ensure you're _not_ capturing `self` strongly
/// This often leads to retain cycles.
///
///     let chat = WriteStream<ChatMessage>()
///
///     // sendButton.onClick is a `ReadStream<Void>`
///     sendButton.onClick
///               .transform(to: chatBox, atKeyPath: \.string)
///               .map(ChatMessage.init)
///               .then(chat.next)
///               .then(api.sendMessage)
///
///     // ReadStream<ChatMessage>
///     let stream = chat.listener
///
///     stream.map(ChatMessageCell.init).then(chatTable.append)
public struct ReadStream<FutureValue> {
    weak var writeStream: WriteStream<FutureValue>?
    
    init(writeStream: WriteStream<FutureValue>) {
        self.writeStream = writeStream
    }
    
    /// Transforms this `ReadStream` into a new ReadStream with each successful ntification transformed
    /// into a new value. Errors thrown in the transform will not pass on a successful value but an error instead.
    ///
    /// Error/Cancelled statesw will be cascaded similar to Futures.
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> ReadStream<R> {
        let newWriteStream = WriteStream<R>()
        newWriteStream.onCancel(run: self.cancel)
        
        self.writeStream?.registerCallback { result in
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
    
    // TODO: OrderedFlatMap
    
    /// Transforms this `ReadStream` into a new ReadStream with each successful ntification transformed
    /// into a new value. Errors thrown in the transform will not pass on a successful value but an error instead.
    ///
    /// Does not guarantee the original values order
    ///
    /// Error/Cancelled statesw will be cascaded similar to Futures.
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Future<R>)) -> ReadStream<R> {
        let newWriteStream = WriteStream<R>()
        newWriteStream.onCancel(run: self.cancel)
        
        self.then { value in
            do {
                try mapper(value).onCompletion(newWriteStream.write)
            } catch {
                newWriteStream.error(error)
            }
        }.catch(newWriteStream.error)
        
        return newWriteStream.listener
    }
    
    /// Requests a cancel state from the writeStream
    public func cancel() {
        self.writeStream?.cancel()
    }
    
    /// This callback is triggered if any non-cancel notification was emitted
    public func ifNotCancelled(run: @escaping () -> ()) {
        self.onCompletion { value in
            if case .cancelled = value { return }
            
            run()
        }
    }
    
    /// This callback is triggered for any notification, including cancel
    public func always(run: @escaping () -> ()) {
        self.onCompletion { _ in run() }
    }
    
    /// This callback is triggered for any notification, including cancel, and will call the closure with this value
    ///
    /// Returns the same ReadStream so more actions can be chained
    @discardableResult
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) -> ReadStream<FutureValue> {
        self.writeStream?.registerCallback(handle)
        
        return self
    }
    
    /// Calls the callback with successful notifications only
    ///
    /// Returns the same ReadStream so more actions can be chained
    public func then(_ handle: @escaping (FutureValue) -> ()) -> ReadStream<FutureValue> {
        self.writeStream?.registerCallback { result in
            if case .success(let value) = result {
                handle(value)
            }
        }
        
        return self
    }
    
    /// Calls the callback with failure notifications only
    ///
    /// Returns the same ReadStream so more actions can be chained
    @discardableResult
    public func `catch`(_ handle: @escaping (Error) -> ()) -> ReadStream<FutureValue> {
        self.writeStream?.registerCallback { result in
            if case .failure(let error) = result {
                handle(error)
            }
        }
        
        return self
    }
    
    /// Binds successful updates in this stream to a binding, updating it's state
    public func bind(to binding: Binding<FutureValue>) {
        weak var binding = binding
        
        self.then { newValue in
            binding?.update(to: newValue)
        }
    }
    
    /// Used for handling errors of the provided error type only
    ///
    /// Returns the same ReadStream so more actions can be chained
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
    
    /// Only triggers the callback on cacelled notifications
    ///
    /// Returns the same ReadStream so more actions can be chained
    @discardableResult
    public func onCancel(_ run: @escaping () -> ()) -> ReadStream<FutureValue> {
        return self.onCompletion { value in
            if case .cancelled = value {
                run()
            }
        }
    }
    
    /// Flattens all futures in this stream so the returned Stream is just an unordered sequence of the future's (un-)successful results
    public func flatten<T>() -> ReadStream<T> where FutureValue == Future<T> {
        let write = WriteStream<T>()
        write.onCancel(run: self.cancel)
        
        self.then { future in
            future.then(write.next).catch(write.error).onCancel(write.cancel)
        }.catch(write.error).onCancel(write.cancel)
        
        return write.listener
    }
    
    /// Maps the stream but filters optionals that are `nil`
    public func filterMap<T>(_  mapper: @escaping (FutureValue) -> T?) -> ReadStream<T> {
        let writer = WriteStream<T>()
        writer.onCancel(run: self.cancel)
        
        self.then { value in
            if let mapped = mapper(value) {
                writer.next(mapped)
            }
        }.catch { error in
            writer.error(error)
        }
        
        return writer.listener
    }
    
    /// Checks all successful states with the provided function before cascading the value to the next
    ///
    ///     let chat = WriteStream<ChatMessage>()
    ///
    ///     // sendButton.onClick is a `ReadStream<Void>`
    ///     sendButton.onClick
    ///               .transform(to: chatBox, atKeyPath: \.string)
    ///               .filter { $0.isEmpty } // <-----
    ///               .map(ChatMessage.init)
    ///               .then(chat.next)
    ///               .then(api.sendMessage)
    ///
    ///     // ReadStream<ChatMessage>
    ///     let stream = chat.listener
    ///
    ///     stream.map(ChatMessageCell.init).then(chatTable.append)
    ///
    /// Returns a similar ReadStream containing only values that passed the test where it returned `false`
    public func filter(_ condition: @escaping (FutureValue) -> (Bool)) -> ReadStream<FutureValue> {
        let writer = WriteStream<FutureValue>()
        writer.onCancel(run: self.cancel)
        
        self.then { value in
            if !condition(value) {
                writer.next(value)
            }
        }.catch { error in
            writer.error(error)
        }.catch(writer.error).onCancel(writer.cancel)
        
        return writer.listener
    }
    
    /// Captures the provided value weakly. If the value is deinitialized the stream will no longer emit events
    public func and<O: AnyObject>(weaklyCaptured object: O) -> ReadStream<(O, FutureValue)> {
        weak var object = object
        let writeStream = WriteStream<(O, FutureValue)>()
        
        self.then { value in
            if let object = object {
                writeStream.next((object ,value))
            }
        }.catch(writeStream.error).onCancel(writeStream.cancel)
        
        return writeStream.listener
    }
    
    /// Maps the error to a new type which can be used for debugging or improvements in error handling.
    ///
    /// Returns a new stream and cascades the successful and cancels states whilst mapping the errors.
    public func errorMap(_ map: @escaping (Error) throws -> (Error)) -> ReadStream<FutureValue> {
        let writeStream = WriteStream<FutureValue>()
        writeStream.onCancel(run: self.cancel)
        
        self.then(writeStream.next).catch { base in
            do {
                writeStream.error(try map(base))
            } catch {
                writeStream.error(error)
            }
        }.onCancel(writeStream.cancel)
        
        return writeStream.listener
    }
}
