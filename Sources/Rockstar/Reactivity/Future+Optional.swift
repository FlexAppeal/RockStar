extension Future {
    public func assert<T>(or error: Error) -> Future<T> where FutureValue == T? {
        return self.map { value in
            guard let value = value else {
                throw error
            }
            
            return value
        }
    }
}

extension Observable {
    public func assert<T>(or error: Error) -> Observable<T> where FutureValue == T? {
        return self.map { value in
            guard let value = value else {
                throw error
            }
            
            return value
        }
    }
}
