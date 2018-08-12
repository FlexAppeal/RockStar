public enum Language: ExpressibleByStringLiteral, Hashable {
    case nl
    case enGB
    case enUS
    case custom(String)
    
    public init(stringLiteral value: String) {
        self = .custom(value)
    }
    
    public var rawValue: String {
        switch self {
        case .nl: return "nl_NL"
        case .enGB: return "en_GB"
        case .enUS: return "en_US"
        case .custom(let string): return string
        }
    }
}

public protocol Translateable {
    var translation: String { get }
}

public protocol ContextTranslateable {
    associatedtype Context
    
    func translation(in context: Context) -> String
}

public protocol VariadicTranslateable {
    associatedtype Parameters
    
    func translation(withParameters parameters: inout ParameterSet) throws -> String
}

public struct BasicTranslateable: Translateable, ExpressibleByStringLiteral {
    enum Storage {
        case literal(String)
        case closure(() -> (String))
        
        var translation: String {
            switch self {
            case .literal(let string): return string
            case .closure(let makeString): return makeString()
            }
        }
    }
    
    public init(stringLiteral value: String) {
        self.storage = .literal(value)
    }
    
    public init(_ run: @autoclosure @escaping () -> (String)) {
        self.storage = .closure(run)
    }
    
    private var storage: Storage
    
    public var translation: String {
        return storage.translation
    }
}

public struct BasicContextTranslateable<Context>: ContextTranslateable {
    private let run: (Context) -> String
    
    public init(_ run: @escaping (Context) -> String) {
        self.run = run
    }
    
    public func translation(in context: Context) -> String {
        return run(context)
    }
}

public final class Translator<Phrases> {
    private var languages = [Language: Phrases]()
    private var language: Language
    private let initialLanguage: Language
    
    internal var currentLanguage: Phrases {
        return self.languages[language] ?? self.languages[initialLanguage]!
    }
    
    public init(
        defaultLanguage: Phrases,
        identifier: Language
    ) {
        self.languages[identifier] = defaultLanguage
        self.language = identifier
        self.initialLanguage = identifier
    }
    
    public func register(_ phrases: Phrases, for language: Language) {
        self.languages[language] = phrases
    }
    
    public func translation<T: Translateable>(for path: KeyPath<Phrases, T>) -> String {
        return self.currentLanguage[keyPath: path].translation
    }
    
    public func translation<T: ContextTranslateable>(for path: KeyPath<Phrases, T>, withContext context: T.Context) -> String {
        return self.currentLanguage[keyPath: path].translation(in: context)
    }
    
    public func translation<T: VariadicTranslateable>(for path: KeyPath<Phrases, T>, withParameters parameters: Any...) throws -> String {
        var parameters = ParameterSet(parameters)
        
        return try self.currentLanguage[keyPath: path].translation(withParameters: &parameters)
    }
}
