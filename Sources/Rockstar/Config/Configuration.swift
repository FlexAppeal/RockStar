import Foundation

/// FIXME: Dynamic member lookup (Swift 4.2) on config files

public struct ConfigurationOption<O> {
    internal enum Storage {
        case literal(O)
        case `default`
        case factory(() -> (O?))
        case WriteStream(ValueWriteStream<O>)
    }

    private let storage: Storage
    
    public static func literal(_ value: O) -> ConfigurationOption<O> {
        return ConfigurationOption<O>(storage: .literal(value))
    }
    
    public static var `default`: ConfigurationOption<O> {
        return ConfigurationOption<O>(storage: .default)
    }
    
    public static func factory(_ factory: @escaping () -> (O?)) -> ConfigurationOption<O> {
        return ConfigurationOption<O>(storage: .factory(factory))
    }
    
    public static func observing<Base: NSObject>(
        keyPath: KeyPath<Base, O>,
        in object: Base
    ) -> ConfigurationOption<O> {
        return ConfigurationOption<O>(
            storage: .WriteStream(ValueWriteStream(keyPath: keyPath, in: object))
        )
    }

    public var value: O? {
        switch storage {
        case .literal(let value): return value
        case .default: return nil
        case .factory(let factory): return factory()
        case .WriteStream(let WriteStream): return WriteStream.currentValue
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

struct ValueNotFound<Base, Value>: Error {
    var type: Any.Type
    var keyPath: KeyPath<Base, Value>
}

public extension Configuration {
    func readValue<Value>(at path: KeyPath<Self, Value>) -> Value {
        return self[keyPath: path]
    }
    
    func assertValue<Value>(at path: KeyPath<Self, Value?>) throws -> Value {
        guard let value = self[keyPath: path] else {
            throw ValueNotFound(type: Value.self, keyPath: path)
        }
        
        return value
    }
    
    func readValue<Value>(_ path: WritableKeyPath<Self, Value>) -> Value {
        return self[keyPath: path]
    }
    
    mutating func setValue<Value>(_ value: Value, forKey path: WritableKeyPath<Self, Value>) {
        self[keyPath: path] = value
    }
}
