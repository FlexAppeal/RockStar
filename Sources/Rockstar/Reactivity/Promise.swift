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
    
    var cancelAction: (()->())?
    
    var result: Observation<FutureValue>?
    var callbacks = [FutureCallback<FutureValue>]()
    
    public init() {}
    
    public func onCancel(_ run: @escaping () -> ()) {
        self.cancelAction = run
    }
    
    func registerCallback(_ callback: @escaping FutureCallback<FutureValue>) {
        self.callbacks.append(callback)
    }
    
    func triggerCallbacks(with result: Observation<FutureValue>) {
        let callbacks = self.callbacks
        finalized = true
        
        for callback in callbacks {
            callback(result)
        }
    }
    
    public func complete(_ value: FutureValue) {
        if finalized { return }
        
        let result = Observation.success(value)
        triggerCallbacks(with: result)
        self.result = result
    }
    
    public func cancel() {
        if finalized { return }
        
        triggerCallbacks(with: .cancelled)
        self.cancelAction?()
    }
    
    public func fail(_ error: Error) {
        if finalized { return }
        
        let result = Observation<FutureValue>.failure(error)
        triggerCallbacks(with: result)
        self.result = result
    }
    
    public func fulfill(_ result: Observation<FutureValue>) {
        if finalized { return }
        
        triggerCallbacks(with: result)
    }
}
