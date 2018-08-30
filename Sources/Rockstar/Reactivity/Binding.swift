import Foundation

// TODO: Bidirectionally update computed bindings
// TODO: Binding unit test helpers

/// Keeps track of all bindings that have been updated to a new value
///
/// Recursively iterates over all bindings and updates them
internal final class BindChangeContext<Bound> {
    let value: Bound
    var previousHandlers = Set<ObjectIdentifier>()
    
    init(value: Bound, initiator: AnyBinding<Bound>) {
        self.value = value
        
        for next in initiator.cascades {
            cascade(for: next)
        }
    }
    
    private func cascade(for cascade: CascadedBind<Bound>) {
        guard !self.previousHandlers.contains(cascade.id) else { return }
        
        if let binding = cascade.binding {
            // Add to the list of notified bindings so this loop doesn't go on forever
            self.previousHandlers.insert(cascade.id)
            
            func notifyUpdate() {
                binding.bound = value
            }
            
            if let newThread = binding.newThread {
                newThread.execute(notifyUpdate)
            } else {
                notifyUpdate()
            }
            
            for next in binding.cascades {
                self.cascade(for: next)
            }
        }
    }
}

/// Stores a weak reference to a binding and updates it when one is available
struct CascadedBind<Bound>: Hashable {
    weak var binding: AnyBinding<Bound>?
    let id: ObjectIdentifier
    
    init(binding: AnyBinding<Bound>) {
        self.id = ObjectIdentifier(binding)
        self.binding = binding
    }
    
    var hashValue: Int {
        return id.hashValue
    }
    
    static func ==(lhs: CascadedBind<Bound>, rhs: CascadedBind<Bound>) -> Bool {
        return lhs.id == rhs.id
    }
}

/// An type that generalizes all types of bindings
///
/// Bindings are wrappers around a value that can notify other bindings of changes,
/// get notified of changes and bind their results to another (non-binding) type
///
/// This is used to reduce state complexity and improve stability
public class AnyBinding<Bound> {
    internal var bound: Bound {
        didSet {
            writeStream.next(bound)
        }
    }
    
    private let writeStream = WriteStream<Bound>()
    
    /// A stream that emits only successful change notifications
    public var readStream: ReadStream<Bound> {
        return writeStream.listener
    }
    
    /// Used for applying thread safety when requested
    internal let lock: NSRecursiveLock?
    
    /// Switches to this thread when updating if set
    internal var newThread: AnyThread?
    var cascades = Set<CascadedBind<Bound>>()
    
    /// An un-thread safe function that is ideally called directly fafter initialization
    ///
    /// Changes the thread to the new value for each update
    public func setThread(to thread: AnyThread) {
        self.newThread = thread
    }
    
    /// This *must* be inernal as it's dependent on the specific Binding implementation
    internal init(bound: Bound, threadSafe: Bool) {
        self.bound = bound
        
        if threadSafe {
            lock = NSRecursiveLock()
        } else {
            lock = nil
        }
    }
    
    /// Updates the current value of this binding according to locking/thread preferences and cascades to peers
    internal func update(to value: Bound) {
        func run() {
            self.bound = value
            
            if cascades.count > 0 {
                _ = BindChangeContext<Bound>(value: bound, initiator: self)
            }
        }
        
        if let newThread = newThread {
            newThread.execute(run)
        } else {
            lock.withLock {
                run()
            }
        }
    }
    
    public func bind<C: AnyObject>(to object: C, atKeyPath path: WritableKeyPath<C, Bound>) {
        weak var object = object
        
        func update(to currentvalue: Bound) {
            object?[keyPath: path] = bound
        }
        
        object?[keyPath: path] = self.bound
        _ = self.readStream.then(update)
    }
}

/// A manually managed bindable value that represents a mutable value like any other.
///
/// Used with helpers to reduce state complexity and increase stability.
///
/// Initially it will only be a wrapper around another value. Can be bound to other types and synchronize between many bindings.
///
///     let pages = [Page]()
///     let pageIndex = Binding(0)
///
///     // Changes the rendered page when the index changes
///     pageIndex.map { index in
///         return pages[index]
///     }.bind(to: pageView.renderedPage)
public final class Binding<Bound>: AnyBinding<Bound> {
    /// Allows modification of the currentValue using a more natural syntax
    public var currentValue: Bound {
        get {
            return bound
        }
        set {
            update(to: newValue)
        }
    }
    
    /// Changes the value, triggering bindings and the readStream
    public override func update(to value: Bound) {
        super.update(to: value)
    }
    
    /// Cannot bind to computed bindings because they are programmatically defined and do not (yet) work bidirectionally
    public func bind(to binding: Binding<Bound>, bidirectionally: Bool = false) {
        binding.update(to: self.bound)
        
        self.cascades.insert(CascadedBind(binding: binding))
        
        if bidirectionally {
            binding.bind(to: self)
        }
    }
    
    /// Creates a new binding based on a concrete value
    public init(_ value: Bound, threadSafe: Bool = RockstarConfig.threadSafeBindings) {
        super.init(bound: value, threadSafe: threadSafe)
    }
}

/// A computed, programmatically defined bindable value that represents a computed value like any other. Cannot be written to and is derived from another binding and always (in-)directly from a manually managed binding. d d
///
/// Used with helpers to reduce state complexity and increase stability.
///
///     let pages = [Page]()
///     let pageIndex = Binding(0)
///
///     // Changes the rendered page when the index changes
///     pageIndex.map { index in
///         return pages[index]
///     }.bind(to: pageView.renderedPage)
public final class ComputedBinding<Bound>: AnyBinding<Bound> {
    /// Allow sreading but not writing the currentValue because the value is programmatically defined
    public private(set) var currentValue: Bound {
        get {
            return bound
        }
        set {
            update(to: newValue)
        }
    }
    
    /// Cannot bind to computed bindings because they are programmatically defined and do not (yet) work bidirectionally
    public func bind(to binding: Binding<Bound>) {
        binding.update(to: self.bound)
        
        self.cascades.insert(CascadedBind(binding: binding))
    }
    
    /// Can not be manually instantiated since the value is programmatically defined
    internal init(_ value: Bound, threadSafe: Bool = RockstarConfig.threadSafeBindings) {
        super.init(bound: value, threadSafe: threadSafe)
    }
}

extension AnyBinding {
    /// Maps any binding to a computed binding
    public func map<T>(_ mapper: @escaping (Bound) -> T) -> ComputedBinding<T> {
        let binding = ComputedBinding<T>(mapper(bound))
        
        _ = self.readStream.map(mapper).then(binding.update)
        
        return binding
    }
}
