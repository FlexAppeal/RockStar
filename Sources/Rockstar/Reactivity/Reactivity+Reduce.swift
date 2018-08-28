extension Binding {
    public func reduceMap<T, C>(_ function: @escaping (Bound, T) -> C, value: T) -> Binding<C> {
        return self.map { bound in
            return function(bound, value)
        }
    }

    public func reduceMap<T, C>(_ function: @escaping (Bound, T) -> C, value: Binding<T>) -> Binding<C> {
        return self.map { bound in
            return function(bound, value.currentValue)
        }
    }

    public func map<T>(toValueAt path: KeyPath<Bound, T>) -> Binding<T> {
        return self.map { bound in
            return bound[keyPath: path]
        }
    }

    public func reduce<B, C>(_ base: B, function: @escaping (B, C) -> B) -> Binding<B> where Bound == [C] {
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
