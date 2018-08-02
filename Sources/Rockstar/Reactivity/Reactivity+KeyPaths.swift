extension Future {
    /// MARK - Normal
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue>) -> Future<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }

    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue>) -> Future<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
    
    /// MARK - Optional
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue?>) -> Future<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
    
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue?>) -> Future<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
}

extension ReadStream {
    /// MARK - Normal
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue>) -> ReadStream<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
    
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue>) -> ReadStream<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
    
    /// MARK - Optional
    
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue?>) -> ReadStream<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
    
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue?>) -> ReadStream<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
}
