import Foundation

fileprivate class AnyNSObject<Base>: NSObject {
    let base: Base
    
    init(base: Base) {
        self.base = base
    }
}

public final class ValueWriteStream<Value> {
    public var currentValue: Value
    private var observation: NSKeyValueObservation!
    private let writeStream = WriteStream<Value>()
    
    public var observable: ReadStream<Value> {
        return writeStream.listener
    }
    
    public init<Base: AnyObject>(keyPath: KeyPath<Base, Value>, in base: Base) {
        self.currentValue = base[keyPath: keyPath]
        let object = AnyNSObject(base: base)
        let newKeyPath = \AnyNSObject<Base>.base
        let finalKeyPath = newKeyPath.appending(path: keyPath)
        self.observation = object.observe(finalKeyPath, changeHandler: self.update)
    }
    
    public init<Base: AnyObject>(keyPath: WritableKeyPath<Base, Value>, in base: Base) {
        self.currentValue = base[keyPath: keyPath]
        let object = AnyNSObject(base: base)
        let newKeyPath = \AnyNSObject<Base>.base
        let finalKeyPath = newKeyPath.appending(path: keyPath)
        self.observation = object.observe(finalKeyPath, changeHandler: self.update)
    }
    
    public init<Base: AnyObject>(keyPath: ReferenceWritableKeyPath<Base, Value>, in base: Base) {
        self.currentValue = base[keyPath: keyPath]
        let object = AnyNSObject(base: base)
        let newKeyPath = \AnyNSObject<Base>.base
        let finalKeyPath = newKeyPath.appending(path: keyPath)
        self.observation = object.observe(finalKeyPath, changeHandler: self.update)
    }
    
    private func update<Base: NSObject>(object: Base, change: NSKeyValueObservedChange<Value>) {
        if let newValue = change.newValue {
            self.currentValue = newValue
            writeStream.next(newValue)
        }
    }
}
