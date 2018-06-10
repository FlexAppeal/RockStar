public enum ConfigurationOption<O> {
    case literal(O)
    case `default`
    case factory(() -> (O?))
    
    internal var value: O? {
        switch self {
        case .literal(let value): return value
        case .default: return nil
        case .factory(let factory): return factory()
        }
    }
}

extension ConfigurationOption : ExpressibleByBooleanLiteral where O == Bool {
    public typealias BooleanLiteralType = Bool
    
    public init(booleanLiteral value: Bool) {
        self = .literal(value)
    }
}

public protocol Configuration {}

public extension Configuration {
    func readValue<Value>(at path: KeyPath<Self, Value>) -> Value {
        return self[keyPath: path]
    }
    
    func readValue<Value>(_ path: WritableKeyPath<Self, Value>) -> Value {
        return self[keyPath: path]
    }
    
    mutating func setValue<Value>(_ value: Value, forKey path: WritableKeyPath<Self, Value>) {
        self[keyPath: path] = value
    }
}
