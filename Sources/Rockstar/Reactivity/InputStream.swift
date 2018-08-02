public final class WriteStream<FutureValue> {
    public var listener: ReadStream<FutureValue> {
        return ReadStream(writeStream: self)
    }
    
    public var isCompleted: Bool {
        return finalized
    }
    
    var finalized = false {
        didSet {
            if finalized {
                
                
            }
        }
    }
    
    var cancelAction: (()->())?
    
    var result: Observation<FutureValue>?
    var callbacks = [FutureCallback<FutureValue>]()
    
    public init() {}
    
    public func onCancel(run: @escaping () -> ()) {
        self.cancelAction = run
    }
    
    public func next(_ value: FutureValue) {
        triggerCallbacks(with: .success(value))
    }
    
    public func error(_ error: Error) {
        triggerCallbacks(with: .failure(error))
    }
    
    public func fatal(_ error: Error) {
        self.error(error)
        self.cancel()
    }
    
    public func cancel() {
        triggerCallbacks(with: .cancelled)
    }
    
    public func write(_ value: Observation<FutureValue>) {
        switch value {
        case .failure(let error): self.error(error)
        case .success(let value): self.next(value)
        case .cancelled: self.write(.cancelled)
        }
    }
    
    func registerCallback(_ callback: @escaping FutureCallback<FutureValue>) {
        self.callbacks.append(callback)
    }
    
    func triggerCallbacks(with result: Observation<FutureValue>) {
        let callbacks = self.callbacks
        
        if case .cancelled = result {
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
