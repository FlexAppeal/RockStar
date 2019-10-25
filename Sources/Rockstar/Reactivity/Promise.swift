import Foundation

// TODO: Promise examples

/// Specified the default settings for promises statically
public enum RockstarConfig {
    /// Defines whether promises are threadSafe by default.
    ///
    /// This behaviour can always be overridden in the `Promise` initializer
    public static var threadSafePromises = true
    
    /// Defines whether bindings are threadSafe by default.
    ///
    /// This behaviour can always be overridden in the `Promise` initializer
    public static var threadSafeBindings = true
}

struct PromiseSettings {
    /// Used for applying thread safety when requested
    var lock: NSRecursiveLock?
    
    /// When set to true, all cancel requests will be ignored leaving the promise finalized state unaltered
    var ignoreCancel = false
    
    static let `default` = PromiseSettings(lock: nil, ignoreCancel: false)
}

/// Promises are types that provide a single notification during their lifetime.
///
/// After creating a promise, a `future` can be fabricated as a read-only API to this model where Promise itself is a write-only API to this model
///
/// Promises can consist of any of the Observation states which means futures can be successful, failed or cancelled.
///
/// Unlike a traditional promise model, the cancelled state allows for futures to indicate the disinterest in the value due to a change in user interation such as browsing away from the view interested in the data.
///
/// The cancelled optimization can become very useful in providing a more smooth and optimized experience.
public final class Promise<FutureValue> {
    /// Creates a Future that is linked to the results of this Promise.
    ///
    /// Futures can be given away as handles to read the results of this Promise.
    public var future: Future<FutureValue> {
        return Future(promise: self)
    }
    
    /// Returns `true` is the promise has been fulfilled.
    ///
    /// This does not represent any final state, just the precense of one.
    public private(set) var isCompleted: Bool {
        get {
            return _finalized
        }
        set {
            _finalized = newValue
        }
    }
    
    internal var settings: PromiseSettings
    
    /// An internal detail that represents `isCompleted`.
    ///
    /// The reason this is not a public property is because the finalized property can be modified on another thread.
    /// Without locks this would have a chance of crashing.
    private var _finalized = false {
        didSet {
            self.callbacks = []
            self.cancelAction = nil
        }
    }
    
    /// When set to true, all cancel requests will be ignored leaving the promise finalized state unaltered
    public var ignoreCancel: Bool {
        get { return settings.ignoreCancel }
        set { settings.ignoreCancel = newValue }
    }
    
    /// This closure is used to cancel the operation linked to this promise
    ///
    /// If the operation is not cancellable, this is `nil`
    private var cancelAction: (()->())?
    
    /// Contains the final result of this future
    private var result: Observation<FutureValue>?
    
    /// Contains all closures that are awaiting the `result` for further action
    private var callbacks = [FutureCallback<FutureValue>]()
    
    /// Creates a new promise. Allows overriding the thread safety for advanced users.
    public convenience init(threadSafe: Bool = RockstarConfig.threadSafePromises) {
        var settings = PromiseSettings.default
        
        if threadSafe {
            settings.lock = NSRecursiveLock()
        }
        
        self.init(settings: settings)
    }
    
    /// Creates a new promise with a cancel action. Allows overriding the thread safety for advanced users.
    internal convenience init(threadSafe: Bool = RockstarConfig.threadSafePromises, onCancel: @escaping () -> ()) {
        self.init(threadSafe: threadSafe)
        
        self.cancelAction = onCancel
    }
    
    internal init(settings: PromiseSettings) {
        self.settings = settings
    }
    
    /// Allows adding a cancel action after promie creation
    ///
    /// Cancel actions are useful for network related actions which allow closing the socket or ignoring the output related to this promise.
    ///
    /// Cancelling can help reduce performance impact of an now unneccesary operation
    public func onCancel(run: @escaping () -> ()) {
        self.settings.lock.withLock {
            self.cancelAction = run
        }
    }
    
    /// Used by future that allows adding handlers for promise results
    ///
    /// If the result is available, the calback will be called immediately
    ///
    /// Otherwise, the callback will be called when the promise is finalized
    internal func registerCallback(_ callback: @escaping FutureCallback<FutureValue>) {
        self.settings.lock.withLock {
            if let result = self.result {
                callback(result)
            } else {
                self.callbacks.append(callback)
            }
        }
    }
    
    /// Used by promise's public functions to handle the
    private func triggerCallbacks(with result: Observation<FutureValue>) {
        self.settings.lock.withLock {
            // Is completed will remove the callbacks
            // This way the futures won't indefinitely retain the promise (and vice-versa)
            // Preventing memory leaks
            self.isCompleted = true
            self.result = result
            
            // Callbacks are triggered after Promise's state is set so the closures can read details from the future/promise
            for callback in self.callbacks {
                callback(result)
            }
        }
    }
    
    /// Finalizes a promise successfully sending a notification to all futures
    ///
    /// Any further changes to Promise's state will be ignored
    public func complete(_ value: FutureValue) {
        if isCompleted { return }
        
        triggerCallbacks(with: .success(value))
    }
    
    /// Cancels the promise.
    /// If the successful or failed result is still sent afterwards it will be ignored.
    public func cancel() {
        if isCompleted || ignoreCancel { return }
        
        triggerCallbacks(with: .cancelled)
        self.cancelAction?()
    }
    
    /// Finalizes the promise with a failure state.
    ///
    /// Any further changes to Promise's state will be ignored
    public func fail(_ error: Error) {
        if isCompleted { return }
        
        triggerCallbacks(with: .failure(error))
    }
    
    /// Fulfills the promise with a raw Observation. This is useful in conjunction with Streams.
    public func fulfill(_ result: Observation<FutureValue>) {
        if isCompleted { return }
        
        triggerCallbacks(with: result)
    }
}

fileprivate struct NeverCompleted: Error {}
