extension Future {
    public func transform<B>(to newValue: B) -> Future<B> {
        return self.map { _ in
            return newValue
        }
    }
    
    public func transform<B>(to newValue: Future<B>) -> Future<B> {
        return self.flatMap { _ in
            return newValue
        }
    }
    
    public func lazyTransform<B>(to function: @escaping @autoclosure () -> B) -> Future<B> {
        return self.map { _ in
            return function()
        }
    }
    
    public func lazyTransform<B>(to function: @escaping @autoclosure () -> Future<B>) -> Future<B> {
        return self.flatMap { _ in
            return function()
        }
    }
}

// TODO: typealias CancellableFuture = CancellableFuture
// 
