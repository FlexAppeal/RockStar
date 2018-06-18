public final class ValueInputStream<Value> {
    public var currentValue: Value
    private var observation: NSKeyValueObservation!
    private let inputStream = InputStream<Value>()
    
    public var observable: OutputStream<Value> {
        return inputStream.listener
    }
    
    public init<Base: NSObject>(keyPath: KeyPath<Base, Value>, in base: Base) {
        self.currentValue = base[keyPath: keyPath]
        self.observation = base.observe(keyPath, changeHandler: self.update)
    }
    
    private func update<Base: NSObject>(object: Base, change: NSKeyValueObservedChange<Value>) {
        if let newValue = change.newValue {
            self.currentValue = newValue
            inputStream.next(newValue)
        }
    }
}
