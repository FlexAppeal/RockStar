extension Binding {
    public func mapDifference<T>(_ map: @escaping (Bound, Bound) -> T) -> ComputedBinding<T> {
        var old = self.currentValue
        
        return self.map { new in
            defer {
                old = new
            }
            
            return map(old, new)
        }
    }
}
