extension Rockstar where Base: NSObject {
    public var observers: NSObjectObservers<Base> {
        return NSObjectObservers(observing: base)
    }
}

public final class NSObjectObservers<O: NSObject> {
    fileprivate let object: O
    
    fileprivate init(observing object: O) {
        self.object = object
    }
    
    var observations = [NSKeyValueObservation]()
    
    public func observeChanges<Value>(atPath path: KeyPath<O, Value>) -> Observer<Value> {
        let promise = Observable<Value>()
        
        let observation = object.observe(path) { base, change in
            promise.next(self.object[keyPath: path])
        }
        
        observations.append(observation)
        
        return promise.observer
    }
}
