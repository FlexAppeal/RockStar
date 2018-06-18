public final class ValueObserver<Value> {
    public var currentValue: Value
    private var observation: NSKeyValueObservation!
    private let observer = Observer<Value>()
    
    public var observable: Observable<Value> {
        return observer.observable
    }
    
    public init<Base: NSObject>(keyPath: KeyPath<Base, Value>, in base: Base) {
        self.currentValue = base[keyPath: keyPath]
        self.observation = base.observe(keyPath, changeHandler: self.update)
    }
    
    private func update<Base: NSObject>(object: Base, change: NSKeyValueObservedChange<Value>) {
        if let newValue = change.newValue {
            self.currentValue = newValue
            observer.next(newValue)
        }
    }
}
