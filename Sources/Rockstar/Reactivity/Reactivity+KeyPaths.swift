extension Future {
    /// Writes the successful result to value at the writable value at the keyPath
    /// in the second argument in the class provided in the first argument.
    ///
    ///    api.login(email: "admin@example.com", password: 'admin")
    ///       .write(to: ApplicationState.defaut, atKeyPath: \.currentUser)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue>) -> Future<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }

    /// Writes the successful result to value at the writable computed property's specified by the keypath
    /// in the second argument in the class provided in the first argument.
    ///
    ///    api.login(email: "admin@example.com", password: 'admin")
    ///       .write(to: ApplicationState.defaut, atKeyPath: \.currentUser)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue>) -> Future<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
    
    /// Writes the successful result to value at the writable value at the keyPath
    /// in the second argument in the class provided in the first argument.
    ///
    /// Functions similarly to the other computed property, except non-optional values can also be written to optional values thanks to this function.
    ///
    ///    api.login(email: "admin@example.com", password: 'admin")
    ///       .write(to: ApplicationState.defaut, atKeyPath: \.currentUser)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue?>) -> Future<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
    
    /// Writes the successful result to value at the writable computed property's specified by the keypath
    /// in the second argument in the class provided in the first argument.
    ///
    /// Functions similarly to the other computed property, except non-optional values can also be written to optional values thanks to this function.
    ///
    ///    api.login(email: "admin@example.com", password: 'admin")
    ///       .write(to: ApplicationState.defaut, atKeyPath: \.currentUser)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue?>) -> Future<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
    
    public func map<T>(toValueAt path: KeyPath<FutureValue, T>) -> Future<T> {
        return self.map { bound in
            return bound[keyPath: path]
        }
    }
}

extension ReadStream {
    /// Writes all successful changes to value at the writable value at the keyPath
    /// in the second argument in the class provided in the first argument.
    ///
    ///    textInput.textUpdates.write(to: titleBar, atKePath: \.string)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue>) -> ReadStream<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
    
    /// Writes all successful changes to value at the writable computed property at the keyPath
    /// in the second argument in the class provided in the first argument.
    ///
    ///    textInput.textUpdates.write(to: titleBar, atKePath: \.string)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue>) -> ReadStream<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
    
    /// Writes all successful changes to value at the writable value at the keyPath
    /// in the second argument in the class provided in the first argument.
    ///
    /// Functions similarly to the other computed property, except non-optional values can also be written to optional values thanks to this function.
    ///
    ///    textInput.textUpdates.write(to: titleBar, atKePath: \.string)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: WritableKeyPath<O, FutureValue?>) -> ReadStream<FutureValue> {
        return self.then { value in
            var type = type
            type[keyPath: path] = value
        }
    }
    
    
    /// Writes all successful changes to value at the writable computed property at the keyPath
    /// in the second argument in the class provided in the first argument.
    ///
    /// Functions similarly to the other computed property, except non-optional values can also be written to optional values thanks to this function.
    ///
    ///    textInput.textUpdates.write(to: titleBar, atKePath: \.string)
    @discardableResult
    public func write<O: AnyObject>(to type: O, atKeyPath path: ReferenceWritableKeyPath<O, FutureValue?>) -> ReadStream<FutureValue> {
        return self.then { value in
            let type = type
            type[keyPath: path] = value
        }
    }
}
