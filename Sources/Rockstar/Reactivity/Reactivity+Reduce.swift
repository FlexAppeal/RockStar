extension _AnyBinding {
    public func reduceMap<T, C>(_ function: @escaping (Bound, T) -> C, value: T) -> ComputedBinding<C> {
        return self.map { bound in
            return function(bound, value)
        }
    }

    public func reduceMap<T, C>(_ function: @escaping (Bound, T) -> C, value: _AnyBinding<T>) -> ComputedBinding<C> {
        return self.map { bound in
            return function(bound, value.bound)
        }
    }

    public func map<T>(toValueAt path: KeyPath<Bound, T>) -> ComputedBinding<T> {
        return self.map { bound in
            return bound[keyPath: path]
        }
    }

    public func reduce<B, C>(_ base: B, function: @escaping (B, C) -> B) -> ComputedBinding<B> where Bound == [C] {
        return self.map { array in
            return array.reduce(base, function)
        }
    }
}

extension Future {
    public func reduceMap<T, C>(_ function: @escaping (FutureValue, T) -> C, value: T) -> Future<C> {
        return self.map { bound in
            return function(bound, value)
        }
    }
    
    public func reduceMap<T, C>(_ function: @escaping (FutureValue, T) -> C, value: Future<T>) -> Future<C> {
        return self.flatMap { bound in
            return value.map { value in
                return function(bound, value)
            }
        }
    }
    
    public func reduceFlatMap<T, C>(_ function: @escaping (FutureValue, T) -> Future<C>, value: T) -> Future<C> {
        return self.flatMap { bound in
            return function(bound, value)
        }
    }
    
    public func reduceFlatMap<T, C>(_ function: @escaping (FutureValue, T) -> Future<C>, value: Future<T>) -> Future<C> {
        return self.flatMap { bound in
            return value.flatMap { value in
                return function(bound, value)
            }
        }
    }
}
