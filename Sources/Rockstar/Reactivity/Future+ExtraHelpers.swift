// TODO: Transform on binding/stream

extension Future {
    /// Ignores the successful state of this future and maps it to the `newValue`.
    /// Primarily useful when you're no longer interested in transforming this future for it's contained value but care about it's successful completion instead.
    ///
    ///     // Assumes Chat is a class
    ///     func loadChat(_ chat: Chat) -> Future<Chat> {
    ///         let otherUsers = api.fetchConversationPartners(forChat: chat)
    ///                             .write(to: chat, atKeyPath: \.users)
    ///
    ///         return api.fetchMessages(inChat: chat)
    ///            .write(to: chat, atKeyPath: \.messages)
    ///            .transform(to: otherUsers).transform(to: chat)
    ///     }
    ///
    /// Errors and cancelled states will be cascaded.
    /// Returns the original future so that further actions can be chained easily
    public func transform<B>(to newValue: B) -> Future<B> {
        return self.map { _ in
            return newValue
        }
    }
    
    /// Transforms the successful state of this future into a new successful state containing the `newValue`
    ///
    ///     // Assumes Chat is a class
    ///     func loadChat(_ chat: Chat) -> Future<Chat> {
    ///         let otherUsers = api.fetchConversationPartners(forChat: chat)
    ///                             .write(to: chat, atKeyPath: \.users)
    ///
    ///         return api.fetchMessages(inChat: chat)
    ///            .write(to: chat, atKeyPath: \.messages)
    ///            .transform(to: otherUsers).transform(to: chat)
    ///     }
    ///
    /// Errors and cancelled states will be cascaded.
    /// Returns the original future so that further actions can be chained easily
    public func transform<B>(to newValue: Future<B>) -> Future<B> {
        return self.flatMap { _ in
            return newValue
        }
    }
    
    /// Similar to `transform` except the value will be loaded lazily using an `@autoclosure`.
    ///
    /// For heavier operations that could take a while to complete this can save performance and wait time.
    public func lazyTransform<B>(to function: @escaping @autoclosure () -> B) -> Future<B> {
        return self.map { _ in
            return function()
        }
    }
    
    /// Similar to the `transform` to Futures except the value will be loaded lazily using an `@autoclosure`.
    ///
    /// For heavier operations that could take a while to complete this can save performance and wait time.
    public func lazyTransform<B>(to function: @escaping @autoclosure () -> Future<B>) -> Future<B> {
        return self.flatMap { _ in
            return function()
        }
    }
}
