public struct ParameterSet {
    private var parameters: [Any]
    
    internal init(_ parameters: [Any]) {
        self.parameters = parameters
    }
    
    public mutating func next<T>(_ type: T.Type) throws -> T {
        let parameterCount = parameters.count
        
        guard parameterCount > 0 else {
            throw ParameterNotFound()
        }
        
        for i in 0..<parameterCount {
            if let value = parameters[i] as? T {
                self.parameters.remove(at: i)
                return value
            }
        }
        
        throw ParameterNotFound()
    }
}
