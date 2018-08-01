public final class Promise<FutureValue> {
    public var future: Future<FutureValue> {
        return Future(promise: self)
    }
    
    public var isCompleted: Bool {
        return finalized
    }
    
    var finalized = false {
        didSet {
            self.callbacks = []
        }
    }
    
    public var failOnDeinit = true
    
    var cancelAction: (()->())?
    
    var result: Observation<FutureValue>?
    var callbacks = [FutureCallback<FutureValue>]()
    
    public init() {}
    
    internal init(onCancel: @escaping () -> ()) {
        self.cancelAction = onCancel
    }
    
    public func onCancel(run: @escaping () -> ()) {
        self.cancelAction = run
    }
    
    func registerCallback(_ callback: @escaping FutureCallback<FutureValue>) {
        if let result = self.result {
            callback(result)
        } else {
            self.callbacks.append(callback)
        }
    }
    
    func triggerCallbacks(with result: Observation<FutureValue>) {
        let callbacks = self.callbacks
        finalized = true
        self.result = result
        
        for callback in callbacks {
            callback(result)
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

