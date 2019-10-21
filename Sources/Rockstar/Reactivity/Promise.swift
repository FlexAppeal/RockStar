import Foundation
@_exported import NIO
@_exported import Dispatch
@_exported import NIOTransportServices

// TODO: Promise examples

/// Specified the default settings for promises statically
public enum RockstarConfig {
    /// Defines whether bindings are threadSafe by default.
    ///
    /// This behaviour can always be overridden in the `Promise` initializer
    public static var threadSafeBindings = true
    
    public static var executeOnMainThread = true
    
    public static let eventLoopGroup: EventLoopGroup = {
        if #available(iOS 12, *) {
            return NIOTSEventLoopGroup()
        } else {
            return MultiThreadedEventLoopGroup(numberOfThreads: 1)
        }
    }()
    
    public static let eventLoop = eventLoopGroup.next()
}

struct PromiseSettings {
    let eventLoop: EventLoop
    
    /// If the promise deinits without having a completed value whilst this value is `true`, the promise will fulfill itself as failed
    ///
    /// This specific property is not thread safe and should be changed directly after initialization
    var failOnDeinit = false
    
    /// If the promise deinits without having a completed value whilst this value is `true`, the promise will fulfill itself as cancelled
    ///
    /// This specific property is not thread safe and should be changed directly after initialization
    var cancelOnDeinit = true
    
    /// When set to true, all cancel requests will be ignored leaving the promise finalized state unaltered
    var ignoreCancel = false
    
    static var `default`: () -> PromiseSettings = {
        PromiseSettings(
            eventLoop: RockstarConfig.eventLoop,
            failOnDeinit: false,
            cancelOnDeinit: true,
            ignoreCancel: false
        )
    }
}

enum CancelResult<FutureValue> {
    case result(FutureValue)
    case cancelled
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
    let promise: EventLoopPromise<CancelResult<FutureValue>>
    
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
    
    private var didDeinit = false
    internal var settings: PromiseSettings
    
    /// An internal detail that represents `isCompleted`.
    ///
    /// The reason this is not a public property is because the finalized property can be modified on another thread.
    /// Without locks this would have a chance of crashing.
    private var _finalized = false {
        didSet {
            self.cancelAction = nil
        }
    }
    
    /// If the promise deinits without having a completed value whilst this value is `true`, the promise will fulfill itself as failed
    ///
    /// This specific property is not thread safe and should be changed directly after initialization
    public var failOnDeinit: Bool {
        get { return settings.failOnDeinit }
        set {
            settings.failOnDeinit = newValue
            
            if newValue {
                cancelOnDeinit = false
            }
        }
    }
    
    /// If the promise deinits without having a completed value whilst this value is `true`, the promise will fulfill itself as cancelled
    ///
    /// This specific property is not thread safe and should be changed directly after initialization
    public var cancelOnDeinit: Bool {
        get { return settings.cancelOnDeinit }
        set {
            settings.cancelOnDeinit = newValue
            
            if newValue {
                failOnDeinit = false
            }
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
    
    /// Creates a new promise. Allows overriding the thread safety for advanced users.
    public convenience init() {
        self.init(settings: .default())
    }
    
    /// Creates a new promise with a cancel action. Allows overriding the thread safety for advanced users.
    internal convenience init(onCancel: @escaping () -> ()) {
        self.init()
        
        self.cancelAction = onCancel
    }
    
    internal init(settings: PromiseSettings) {
        self.settings = settings
        self.promise = settings.eventLoop.makePromise()
    }
    
    /// Allows adding a cancel action after promie creation
    ///
    /// Cancel actions are useful for network related actions which allow closing the socket or ignoring the output related to this promise.
    ///
    /// Cancelling can help reduce performance impact of an now unneccesary operation
    public func onCancel(run: @escaping () -> ()) {
        self.cancelAction = run
    }
    
    /// Used by future that allows adding handlers for promise results
    ///
    /// If the result is available, the calback will be called immediately
    ///
    /// Otherwise, the callback will be called when the promise is finalized
    internal func registerCallback(_ callback: @escaping FutureCallback<FutureValue>) {
        promise.futureResult.whenComplete { result in
            switch result {
            case let .failure(error):
                callback(.failure(error))
            case let .success(.result(result)):
                callback(.success(result))
            case .success(.cancelled):
                callback(.cancelled)
            }
        }
    }
    
    /// Used by promise's public functions to handle the
    private func triggerCallbacks(with result: Observation<FutureValue>) {
        func complete() {
            switch result {
            case .cancelled:
                self.promise.succeed(.cancelled)
            case let .failure(error):
                self.promise.fail(error)
            case let .success(result):
                self.promise.succeed(.result(result))
            }
        }
        
        if RockstarConfig.executeOnMainThread {
            if Thread.current.isMainThread {
                complete()
            } else {
                DispatchQueue.main.async(execute: complete)
            }
        } else {
            complete()
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
    
    deinit {
        self.didDeinit = true
        
        if failOnDeinit {
            self.fail(NeverCompleted())
        } else if cancelOnDeinit {
            self.cancel()
        }
    }
}

fileprivate struct NeverCompleted: Error {}

