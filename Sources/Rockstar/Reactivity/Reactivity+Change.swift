extension AnyBinding {
    /// Keeps track of updates based on differences between the old and new value.
    ///
    ///     let currentIndex = Binding<Int>(0)
    ///     currentIndex.changeMap(>).then { changedForward in
    ///         if changedForward {
    ///             print("Next button clicked")
    ///         }
    ///     }
    ///
    /// The initial computed property value is calculated from the `currentValue` of this binding.
    public func changeMap<T>(_ map: @escaping (Bound, Bound) -> T) -> ComputedBinding<T> {
        var old = self.bound
        
        return self.map { new in
            defer {
                old = new
            }
            
            return map(old, new)
        }
    }
}
