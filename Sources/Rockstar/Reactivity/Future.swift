// TODO: Future examples

/// Futures are types that can receive a single notification during their lifetime.
///
/// This notification originates from the linked promise in a symbiotic relationship.
///
/// Unlike the stereotypical future model, Rockstar Futures allow two extra optimizations.
/// - Futures can be pre-completed, ommitting the need for a Promise if the value is readily available
/// - Futures can cancel their associated promise, allowing the future to request the promise to cancel further computational costs towards producing the results
///
/// Although a single notification is received, a Future can register many closures that will receive a copy of the notification
///
/// Futures can almost always capture `self` strongly because of their short lived nature
public struct Future<FutureValue> {
    /// An enum that decides whether a Future is already completed or awaits a promise's notification
    private indirect enum Storage {
        case concrete(Observation<FutureValue>)
        case promise(Promise<FutureValue>)
    }

    private let storage: Storage
    
    /// Indicates that the storage is not dependent on a Promise
    ///
    /// Can be used to take advantage of the un-asynchronous nature of registered callbacks when a result is readily available
    public var isPrecompleted: Bool {
        switch storage {
        case .concrete: return true
        case .promise: return false
        }
    }
    
    /// Indicates that the future value has been received
    ///
    /// Can be used to take advantage of the un-asynchronous nature of registered callbacks when a result is readily available
    public var isCompleted: Bool {
        switch storage {
        case .concrete:
            return true
        case .promise(let promise):
            return promise.isCompleted
        }
    }
    
    /// Creates a precompleted future with a failure state
    public init(error: Error) {
        self.storage = .concrete(.failure(error))
    }
    
    /// Creates a precompleted future with a successful state
    public init(result: FutureValue) {
        self.storage = .concrete(.success(result))
    }
    
    private init() {
        self.storage = .concrete(.cancelled)
    }
    
    /// A helper that will create a precompleted, cancelledm, future
    public static var cancelled: Future<FutureValue> {
        return Future()
    }
    
    /// An internal function that creates a promise-linked future
    init(promise: Promise<FutureValue>) {
        self.storage = .promise(promise)
    }
    
    /// Maps the successful result of this future into a new future type.
    ///
    ///     let futureUser = ... // Future<User>
    ///     let futureUsername = futureUser.map { user -> String in
    ///         return user.username
    ///     }
    ///
    /// - If the closure throws an error, the new future will be in a failed state.
    /// - If this future will receive a failure state, the new future will find the same error
    /// - Cancelled states will also be cascaded to the new future
    ///
    /// Returns a new future derived from the base future.
    public func map<R>(_ mapper: @escaping (FutureValue) throws -> (R)) -> Future<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Future<R>(error: error)
            case .success(let value):
                do {
                    return Future<R>(result: try mapper(value))
                } catch {
                    return Future<R>(error: error)
                }
            case .cancelled:
                return Future<R>.cancelled
            }
        case .promise(let promise):
            let newPromise = Promise<R>(onCancel: self.cancel)
            promise.registerCallback { result in
                do {
                    switch result {
                    case .success(let value):
                        try newPromise.complete(mapper(value))
                    case .failure(let error):
                        newPromise.fail(error)
                    case .cancelled:
                        newPromise.cancel()
                    }
                } catch {
                    newPromise.fail(error)
                }
            }
            
            return newPromise.future
        }
    }
    
    /// Maps the successful result of this future into a new future type.
    /// The map function used for mapping _must_ return a future.
    ///
    /// The flatMap function will await the result of this new future and make
    /// the result of that function the result of the flatMap function's future.
    ///
    ///     let futureUser = ... // Future<User>
    ///     futureUser.flatMap { user -> Future<[User]> in
    ///         return user.fetchFriends()
    ///     }
    ///
    /// - If the closure throws an error, the new future will be in a failed state.
    /// - If this future will receive a failure state, the new future will find the same error
    /// - Cancelled states will also be cascaded to the new future
    ///
    /// Returns a new future derived from the base future.
    public func flatMap<R>(_ mapper: @escaping (FutureValue) throws -> (Future<R>)) -> Future<R> {
        switch storage {
        case .concrete(let result):
            switch result {
            case .failure(let error):
                return Future<R>(error: error)
            case .success(let value):
                do {
                    return try mapper(value)
                } catch {
                    return Future<R>(error: error)
                }
            case .cancelled:
                return Future<R>.cancelled
            }
        case .promise(let promise):
            let newPromise = Promise<R>(onCancel: self.cancel)
            promise.future.then { value in
                do {
                    try mapper(value).onCompletion(newPromise.fulfill)
                } catch {
                    newPromise.fail(error)
                }
            }.catch(newPromise.fail)
            
            return newPromise.future
        }
    }
    
    /// Requests cancellation of the promise's workload
    public func cancel() {
        if case .promise(let promise) = storage {
            promise.cancel()
        }
    }
    
    /// Registers a closure that's executed in success and failure but not cancelled states
    ///
    /// Returns the original future so that further actions can be chained easily
    @discardableResult
    public func ifNotCancelled(run: @escaping () -> ()) -> Future<FutureValue> {
        self.onCompletion { value in
            if case .cancelled = value {
                return
            }
            
            run()
        }
        
        return self
    }
    
    /// Registers a closure that will be always executed upon completion.
    /// Useful when you want to handle cleanup after any completion state
    ///
    ///     showReloadAnimation()
    ///     api.fetchTableItems.then { items in
    ///         self.items = items
    ///     }.catch { ... }.always {
    ///         hideReloadAnimation()
    ///     }
    ///
    /// Returns the original future so that further actions can be chained easily
    @discardableResult
    public func always(run: @escaping () -> ()) -> Future<FutureValue> {
        self.onCompletion { _ in run() }
        return self
    }
    
    /// Registers a closure that is interested in any completion state
    ///
    /// Returns the original future so that further actions can be chained easily
    @discardableResult
    public func onCompletion(_ handle: @escaping (Observation<FutureValue>) -> ()) -> Future<FutureValue> {
        switch storage {
        case .concrete(let result):
            handle(result)
        case .promise(let promise):
            promise.registerCallback(handle)
        }
        
        return self
    }
    
    /// Registers a closure that will be executed with successful results only.
    ///
    /// Often combined with `.catch` for error handling. `then` and `catch` are used for handling of final results
    /// Often providing user feedback or triggering other normal logic
    ///
    /// Returns the original future so that further actions can be chained easily
    public func then(_ handle: @escaping (FutureValue) -> ()) -> Future<FutureValue> {
        switch storage {
        case .concrete(let result):
            if case .success(let value) = result {
                handle(value)
            }
        case .promise(let promise):
            promise.registerCallback { result in
                if case .success(let value) = result {
                    handle(value)
                }
            }
        }
        
        return self
    }
    
    /// Registers a closure that's only executed for failure states.
    ///
    ///     api.login(email: inputForm.email, password: inputForm.password).then { profile in
    ///         self.showAlert("Welcome! You're logged in")
    ///     }.catch { error in
    ///         self.showAlert("Login failed, please check if the entered information is correct")
    ///     }
    ///
    /// Often combined with `.catch` for error handling. `then` and `catch` are used for handling of final results
    /// Often providing user feedback or triggering other normal logic
    ///
    /// Returns the original future so that further actions can be chained easily
    @discardableResult
    public func `catch`(_ handle: @escaping (Error) -> ()) -> Future<FutureValue> {
        switch storage {
        case .concrete(let result):
            if case .failure(let error) = result {
                handle(error)
            }
        case .promise(let promise):
            promise.registerCallback { result in
                if case .failure(let error) = result {
                    handle(error)
                }
            }
        }
        
        return self
    }
    
    /// Registers a closure that's only executed for failure states of sthe provided type. Useful when you're looking to differentiate errors.
    ///
    ///     api.login(email: inputForm.email, password: inputForm.password).then { profile in
    ///         self.showAlert("Welcome! You're logged in")
    ///     }.catch(ApiError.self) { apiError in
    ///         self.showAlert(apiError.reason)
    ///     }.catch {
    ///         self.showAlert("An unknown error occurred, please check your network connectivity")
    ///     }
    ///
    /// Often combined with `.catch` for error handling. `then` and `catch` are used for handling of final results
    /// Often providing user feedback or triggering other normal logic
    ///
    /// Returns the original future so that further actions can be chained easily
    @discardableResult
    public func `catch`<E: Error>(
        _ errorType: E.Type,
        _ handle: @escaping (E) -> ()
    ) -> Future<FutureValue> {
        self.catch { error in
            if let error = error as? E {
                handle(error)
            }
        }
        
        return self
    }
    
    /// A static function that uses the returned future as the result
    ///
    ///     func fetchFriends() -> Future<[User]> {
    ///         Future.do {
    ///             guard let user = MyApplicationState.currentUser else { throw NotLoggedIn() }
    ///
    ///             return api.fetchFriends(relatedTo: user)
    ///         }
    ///     }
    ///
    /// If the provided closure throws, a failed future will be provided instead
    public static func `do`(run: () throws -> Future<FutureValue>) -> Future<FutureValue> {
        do {
            return try run()
        } catch {
            return Future(error: error)
        }
    }
    
    /// Registers a closure that triggers only when the result is cancelled.
    ///
    /// Returns the original future so that further actions can be chained easily
    @discardableResult
    public func onCancel(_ run: @escaping () -> ()) -> Future<FutureValue> {
        return self.onCompletion { value in
            if case .cancelled = value {
                run()
            }
        }
    }
    
    /// Similar to `map`, but rather than mapping successful states it's mapping failure states into another failure state.
    ///
    /// Returns a new future derived from the base future.
    ///
    /// Successful states will be cascaded to the resulting future.
    public func errorMap(_ map: @escaping (Error) throws -> (Error)) -> Future<FutureValue> {
        let promise = Promise<FutureValue>()
        
        self.then(promise.complete).catch { base in
            do {
                promise.fail(try map(base))
            } catch {
                promise.fail(error)
            }
        }.onCancel(promise.cancel)
        
        return promise.future
    }
}

