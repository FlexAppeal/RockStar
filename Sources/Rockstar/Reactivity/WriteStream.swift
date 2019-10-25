import Dispatch
import Foundation

/// Similar to the Promise in the Promise/Future relationship
/// This is a write-only view into the Write/ReadStream relationship.
///
/// ReadStreams are produced from a WriteStream and can regiser callbacks to notifications written
/// to a WriteStream. ReadStreams cannot exist without their associated WriteStream
///
/// Streams can emit many notifications where Promises/Futures can only emit one.
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
public final class WriteStream<FutureValue> {
    /// Creates a `ReadStream` linked to this WriteStream
    public var listener: ReadStream<FutureValue> {
        return ReadStream(writeStream: self)
    }
    
    var cancelAction: (()->())?
    
    var result: Observation<FutureValue>?
    var callbacks = [FutureCallback<FutureValue>]()
    
    /// If `true`, halts this Stream permanently after an error has been emitted
    ///
    /// Defaults to `false`
    public var closeOnError = false
    
    /// If `true`, halts this Stream permanently after a cancel has been emitted
    ///
    /// Defaults to `true`
    public var closeOnCancel = true
    
    /// If `false`, ReadStream cancel requests will be ignored
    ///
    /// Defaults to `true`
    public var allowsCancel = true
    
    /// If `true`, this stream cannot emit more information
    public private(set) var isClosed = false
    
    /// Creates a new WriteStream
    public init() {}
    
    /// Adds an action that allows cancelling the operation linked to the stream's emitting behaviour
    ///
    ///     let buttonClicks = WriteStream<Void>()
    ///     ... // set up a click event to emit to `buttonClicks`
    ///     clickStream.onCancel { button.isUserInterationenabled = false }
    public func onCancel(run: @escaping () -> ()) {
        self.cancelAction = run
    }
    
    /// Sends a successful notification to the stream containing a next value
    public func next(_ value: FutureValue) {
        triggerCallbacks(with: .success(value))
    }
    
    /// Sends an error to the stream
    public func error(_ error: Error) {
        triggerCallbacks(with: .failure(error))
    }
    
    /// Emits an error and cancel notification
    ///
    /// Always closes the stream independent of configuration
    public func fatal(_ error: Error) {
        self.error(error)
        self.cancel()
        
        isClosed = true
        self.callbacks = []
    }
    
    /// Sends a cancel signal on the stream
    public func cancel() {
        if allowsCancel {
            triggerCallbacks(with: .cancelled)
        }
    }
    
    /// Writes any Observation to the stream
    ///
    /// Useful in conjunction with Future
    ///
    ///    future.onCompletion(stream.write)
    public func write(_ value: Observation<FutureValue>) {
        switch value {
        case .failure(let error): self.error(error)
        case .success(let value): self.next(value)
        case .cancelled: self.cancel()
        }
    }
    
    /// An internal function that allows adding callbacks
    func registerCallback(_ callback: @escaping FutureCallback<FutureValue>) {
        if isClosed { return }
        
        self.callbacks.append(callback)
    }
    
    /// Used to trigger callbacks and possible close logic when writing a value
    private func triggerCallbacks(with result: Observation<FutureValue>) {
        if isClosed { return }
        let callbacks = self.callbacks
        
        if closeOnCancel, case .cancelled = result {
            self.cancelAction?()
            self.isClosed = true
            self.callbacks = []
            return
        }
        
        if closeOnError, case .failure = result {
            self.isClosed = true
            self.callbacks = []
        }
        
        for callback in callbacks {
            callback(result)
        }
        
        if case .cancelled = result {
            cancelAction?()
        }
    }
}
