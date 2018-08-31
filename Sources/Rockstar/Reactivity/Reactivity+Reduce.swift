extension AnyBinding {
    /// Uses a function and a static value. Uses this binding's updates and maps those changes using the function.
    ///
    /// Puts this binding's value at the `lhs` of the function, and the static value on the `rhs`.
    ///
    ///     var e
    ///
    /// Like all closures, operators are supported as a function.
    ///
    ///     var entities: [Element] = ...
    ///     let index = Binding(0)
    ///     let disableNextButton: ComputedBinding<Bool> = index.reduceMap(==, entities.count - 1)
    ///
    /// Operators are also useful for other smaller computational transformations.
    ///
    ///     // Shows 3 photos at a time
    ///     let firstImageIndex: Binding<Int> = 0
    ///     let secondImageIndex = index.reduceMap(+, 1)
    ///     let lastImageIndex = index.reduceMap(+, 2)
    ///
    ///     imageIndex += 3
    ///     // other indices are also 3 higher
    public func reduceMap<T, C>(_ function: @escaping (Bound, T) -> C, value: T) -> ComputedBinding<C> {
        return self.map { bound in
            return function(bound, value)
        }
    }

    /// Uses a function and a static value. Uses this binding's updates and maps those changes using the function.
    /// Useful when you want to join 2 binded values to compute a new binding.
    ///
    /// Puts this binding's value at the `lhs` of the function, and the other binding's current value on the `rhs`.
    ///
    /// Like all closures, operators are supported as a function.
    ///
    ///     var entities: Binding<[Element]> = ...
    ///     let index = Binding(0)
    ///     let lastIndex = entities.map { $0.count - 1 }
    ///     let disableNextButton: ComputedBinding<Bool> = index.reduceMap(==, lastIndex)
    public func reduceMap<T, C>(_ function: @escaping (Bound, T) -> C, value: AnyBinding<T>) -> ComputedBinding<C> {
        return self.map { bound in
            return function(bound, value.bound)
        }
    }

    /// Uses a (computed) property from within the current value.
    ///
    ///     let currentUser: Binding<User>
    ///     let currentUserIsAdmin = currentUser.map(toValueAt: \.isAdmin)
    public func map<T>(toValueAt path: KeyPath<Bound, T>) -> ComputedBinding<T> {
        return self.map { bound in
            return bound[keyPath: path]
        }
    }

    /// Similar to a normal `reduce` on `Array`, but is applied to the array value within the binding instead.
    ///
    /// Returns a computed binding with the result of the array reduce.
    public func reduce<B, C>(_ base: B, function: @escaping (B, C) -> B) -> ComputedBinding<B> where Bound == [C] {
        return self.map { array in
            return array.reduce(base, function)
        }
    }
}

// TODO: Docs & ReadStream reduce helpers
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

extension Array {
    /// Similar to a normal array `reduce` except a future is returned and will be waited upon before reduce continues
    ///
    /// Returns a future containing the final value
    public func asyncReduce<Value>(_ element: Value, _ function: @escaping (Value, Element) throws -> Future<Value>) -> Future<Value> {
        var iterator = self.makeIterator()
        var element = Future(result: element)
        var cancelled = false
        
        let promise = Promise<Value> {
            cancelled = true
        }
        
        func next() {
            if cancelled {
                return
            }
            
            if let iterable = iterator.next() {
                element = element.flatMap { element in
                    let element = try function(element, iterable)
                    
                    return element
                }.ifNotCancelled(run: next)
            } else {
                element.onCompletion(promise.fulfill)
            }
        }
        
        next()
        
        return promise.future
    }
}
