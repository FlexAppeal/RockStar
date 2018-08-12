import Foundation

public enum PromiseConfig {
    public static var threadSafe = true
}

internal extension Optional where Wrapped == NSRecursiveLock {
    func withLock<T>(_ run: () throws -> T) rethrows -> T {
        switch self {
        case .none:
            return try run()
        case .some(let lock):
            lock.lock()
            defer { lock.unlock() }
            
            return try run()
        }
    }
}

public final class Promise<FutureValue> {
    public var future: Future<FutureValue> {
        return Future(promise: self)
    }
    
    public var isCompleted: Bool {
        return finalized
    }
    
    private var _finalized = false {
        didSet {
            self.callbacks = []
        }
    }
    
    internal var finalized: Bool {
        get {
            return lock.withLock {
                return _finalized
            }
        }
        set {
            lock.withLock {
                _finalized = newValue
            }
        }
    }
    
    public var failOnDeinit = true
    private let lock: NSRecursiveLock?
    
    private var cancelAction: (()->())?
    
    private var result: Observation<FutureValue>?
    private var callbacks = [FutureCallback<FutureValue>]()
    
    public init(threadSafe: Bool = PromiseConfig.threadSafe) {
        self.lock = threadSafe ? .init() : nil
    }
    
    internal convenience init(threadSafe: Bool = PromiseConfig.threadSafe, onCancel: @escaping () -> ()) {
        self.init(threadSafe: threadSafe)
        
        self.cancelAction = onCancel
    }
    
    public func onCancel(run: @escaping () -> ()) {
        self.lock.withLock {
            self.cancelAction = run
        }
    }
    
    internal func registerCallback(_ callback: @escaping FutureCallback<FutureValue>) {
        lock.withLock {
            if let result = self.result {
                callback(result)
            } else {
                self.callbacks.append(callback)
            }
        }
    }
    
    private func triggerCallbacks(with result: Observation<FutureValue>) {
        lock.withLock {
            let callbacks = self.callbacks
            finalized = true
            self.result = result
            
            for callback in callbacks {
                callback(result)
            }
        }
    }
    
    public func complete(_ value: FutureValue) {
        if finalized { return }
        
        triggerCallbacks(with: .success(value))
    }
    
    public func cancel() {
        if finalized { return }
        
        triggerCallbacks(with: .cancelled)
        self.cancelAction?()
    }
    
    public func fail(_ error: Error) {
        if finalized { return }
        
        triggerCallbacks(with: .failure(error))
    }
    
    public func fulfill(_ result: Observation<FutureValue>) {
        if finalized { return }
        
        triggerCallbacks(with: result)
    }
    
    deinit {
        if failOnDeinit {
            self.fail(NeverCompleted())
        }
    }
}

struct NeverCompleted: Error {}

