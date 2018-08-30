extension Array {
    /// Takes all futures in th the array and joins them into a single `Future<[T]>``.
    ///
    ///     // Friends is `[Future<User>]
    ///     let friends = user.friends.map { friendId -> Future<User. in
    ///         return api.fetchUser(byId: friendId)
    ///     }
    ///
    ///     friends.joined() // Future<[User]>
    ///
    /// Used to simplify logic where many futures are found of the same type.
    ///
    /// `ordered` can be set to `false` if the order in which results are put into the array are not important
    ///
    /// If `ordered` is true, the array is guaranteed to have the same resolved values at the indices their futures were at
    public func joined<T>(ordered: Bool = true) -> Future<[T]> where Element == Future<T> {
        if ordered {
            return _orderedJoin()
        } else {
            return _unorderedJoin()
        }
    }
    
    /// An internal implementation for ordered `joined`
    private func _orderedJoin<T>() -> Future<[T]> where Element == Future<T> {
        var values = [T]()
        values.reserveCapacity(self.count)
        var iterator = self.makeIterator()
        let promise = Promise<[T]>()
        var i = 0
        
        func next() {
            if let value = iterator.next() {
                value.onCompletion { value in
                    switch value {
                    case .cancelled:
                        promise.cancel()
                    case .failure(let error):
                        promise.fail(error)
                    case .success(let value):
                        values.append(value)
                        
                        next()
                    }
                }
            } else {
                promise.complete(values)
            }
        }
        
        next()
        
        return promise.future
    }
    
    /// An internal implementation for unordered `joined`
    private func _unorderedJoin<T>() -> Future<[T]> where Element == Future<T> {
        var values = [T]()
        var size = self.count
        values.reserveCapacity(size)
        let promise = Promise<[T]>()
        
        for element in self {
            element.onCompletion { value in
                switch value {
                case .cancelled:
                    promise.cancel()
                case .failure(let error):
                    promise.fail(error)
                case .success(let value):
                    values.append(value)
                }
                
                size = size &- 1
                if size == 0 {
                    promise.complete(values)
                }
            }
        }
        
        return promise.future
    }
    
    /// Drains all entities in the array into the stream
    ///
    /// If `sequentially` is true, the values will be sent to the stream in the order of which they occur in the array
    ///
    /// Otherwise, the order will be ignored and the order in the stream is equal to the order in which the futures are completed
    public func streamed<T>(sequentially: Bool) -> ReadStream<T> where Element == Future<T> {
        let writeStream = WriteStream<T>()
        
        if sequentially {
            var iterator = self.makeIterator()
            
            func next() {
                guard let future = iterator.next() else {
                    return
                }
                
                future.onCompletion(writeStream.write).ifNotCancelled(run: next)
            }
            
            next()
        } else {
            for element in self {
                element.onCompletion(writeStream.write)
            }
        }
        
        return writeStream.listener
    }
}

extension Future {
    /// FIXME: Joined?
    public func flattened<T>() -> Future<[T]> where FutureValue == [Future<T>] {
        return self.flatMap { sequence in
            var values = [T]()
            var iterator = sequence.makeIterator()
            let promise = Promise<[T]>()
            
            func next() {
                if let nextFuture = iterator.next() {
                    nextFuture.onCompletion { observation in
                        switch observation {
                        case .cancelled:
                            promise.cancel()
                        case .success(let value):
                            values.append(value)
                            next()
                        case .failure(let error):
                            promise.fail(error)
                        }
                    }
                } else {
                    promise.complete(values)
                }
            }
            
            next()
            
            return promise.future
        }
    }
    
    /// After completion filters all elements in the array which are `nil`
    ///
    /// Returns an array containing the non-nil elements in original order
    ///
    ///     let ids = [UserId]()
    ///
    ///     // fetchUser returns `Future<User?>`
    ///     let userResults: [Future<User?>] = ids.map(api.fetchUser)
    ///     let foundUsers: Future<[User]> = results.flatten().filteringNil()
    public func filteringNil<T>() -> Future<[T]> where FutureValue == [T?] {
        return self.map { array in
            return array.compactMap { $0 }
        }
    }
}

extension ReadStream where FutureValue: Sequence {
    /// Takes all elements individually in the sequence and maps them to an array of the new type
    ///
    ///     let chatMessages: ReadStream<[ChatMessage]> = ...
    ///
    ///     // ReadStream<[String]>
    ///     chatMessages.mapContents { message in
    ///         return message.text
    ///     }
    public func mapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> NewValue
    ) -> ReadStream<[NewValue]> {
        return self.map { sequence in
            return try sequence.map(transform)
        }
    }
    
    /// Takes all elements individually in the sequence and maps them to an array of a Future containing the new type
    ///
    ///     let notifications: ReadStream<[Notification]> = ...
    ///
    ///     // ReadStream<[User]>
    ///     notifications.mapContents { notification -> Future<User> in
    ///         return api.fetchUser(byId: notification.senderId)
    ///     }
    public func flatMapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> Future<NewValue>
    ) -> ReadStream<[NewValue]> {
        return self.flatMap { sequence in
            return try sequence.map(transform).joined()
        }
    }
}

extension Future where FutureValue: Sequence {
    /// Takes all elements individually in the sequence and maps them to an array of the new type
    ///
    ///     // Future<[ChatMessage]>
    ///     let chatMessages = api.fetchChatMessages()
    ///
    ///     // Future<[String]>
    ///     chatMessages.mapContents { message in
    ///         return message.text
    ///     }
    public func mapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> NewValue
    ) -> Future<[NewValue]> {
        return self.map { sequence in
            return try sequence.map(transform)
        }
    }
    
    /// Takes all elements individually in the sequence and maps them to an array of a Future containing the new type
    ///
    ///     // Future<[Notification]>
    ///     let notifications = api.fetchNotifications()
    ///
    ///     // Future<[User]>
    ///     notifications.mapContents { notification -> Future<User> in
    ///         return api.fetchUser(byId: notification.senderId)
    ///     }
    public func flatMapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> Future<NewValue>
    ) -> Future<[NewValue]> {
        return self.flatMap { sequence in
            return try sequence.map(transform).joined()
        }
    }
}
