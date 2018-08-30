extension Future {
    /// Triggers the closure only if the FutureValue is completed with a `nil` value
    ///
    /// Only works on Future's containing an optional success state.
    ///
    /// Returns the original future so that further actions can be chained easily
    public func ifNil<B>(run: @escaping () -> ()) -> Future<FutureValue> where FutureValue == Optional<B> {
        return self.then { value in
            if value == nil {
                run()
            }
        }
    }
    
    /// Triggers the closure only if the FutureValue is completed with a value contained in the optional result
    ///
    /// Triggers the closure with the wrapped (non-optional) value
    ///
    /// Returns the original future so that further actions can be chained easily
    public func ifNotNil<B>(run: @escaping (B) -> ()) -> Future<FutureValue> where FutureValue == Optional<B> {
        return self.then { value in
            if let value = value {
                run(value)
            }
        }
    }
    
    /// Maps the future to a non-optional value and throws an error if the value was not found when unwrapping the successful state. Errors and cancelled states will be cascaded.
    ///
    /// Returns the original future so that further actions can be chained easily
    public func assertNotNil<B>() -> Future<B> where FutureValue == Optional<B> {
        return self.map { value in
            guard let value = value else {
                throw ValueUnwrappedNil()
            }
            
            return value
        }
    }
}

fileprivate struct ValueUnwrappedNil: Error {}
