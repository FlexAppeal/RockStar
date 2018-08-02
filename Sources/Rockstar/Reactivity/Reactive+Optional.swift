extension Future {
    public func assert<T>(or error: Error) -> Future<T> where FutureValue == T? {
        return self.map { value in
            guard let value = value else {
                throw error
            }
            
            return value
        }
    }
    
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
    public func assert<T>(or error: Error) -> ReadStream<T> where FutureValue == T? {
        return self.map { value in
            guard let value = value else {
                throw error
            }
            
            return value
        }
    }
    
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
