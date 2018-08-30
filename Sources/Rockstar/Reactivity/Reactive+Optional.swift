extension Future {
    /// Throws the provided error if the value is `nil` and returns a non-optional future
    public func assertNotNil<T>(or error: @escaping @autoclosure () -> (Error)) -> Future<T> where FutureValue == T? {
        return self.map { value in
            guard let value = value else {
                throw error()
            }
            
            return value
        }
    }
    
    /// Maps this future to another value, like `map`, but if the optional value contained in the future is `nil` the value `nil` will not be mapped but passed on instead
    public func optionalMap<B, T>(
        run: @escaping (B) throws -> T
    ) -> Future<T?> where FutureValue == B? {
        return self.map { value -> T? in
            if let value = value {
                return try run(value)
            }
            
            return nil
        }
    }
}

extension ReadStream {
    /// Throws the provided error if the value is `nil` and returns a non-optional future
    public func assertNotNil<T>(or error: @escaping @autoclosure () -> (Error)) -> ReadStream<T> where FutureValue == T? {
        return self.map { value in
            guard let value = value else {
                throw error()
            }
            
            return value
        }
    }
    
    /// Maps this future to another value, like `map`, but if the optional value contained in the future is `nil` the value `nil` will not be mapped but passed on instead
    public func optionalMap<B, T>(
        run: @escaping (B) throws -> T
    ) -> ReadStream<T?> where FutureValue == B? {
        return self.map { value -> T? in
            if let value = value {
                return try run(value)
            }
            
            return nil
        }
    }
    
    /// Transforms this stream into a non-optional stream containing the same information
    ///
    /// Any `nil` values will be ignored and not passed on in any way
    public func notNil<B>() -> ReadStream<B> where FutureValue == B? {
        let input = WriteStream<B>()
        
        self.then { value in
            if let value = value {
                input.next(value)
            }
        }.catch(input.error)
        
        return input.listener
    }
}
