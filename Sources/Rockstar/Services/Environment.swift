public enum ApplicationEnvironment: RawRepresentable, ExpressibleByStringLiteral, Hashable {
    case development, testing, acceptation, production
    case custom(String)
    
    /// FIXME: Better environment detection
    public static func automatic() -> ApplicationEnvironment {
        #if DEBUG
            return .development
        #else
            return .development
        #endif
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case "development":
            self = .development
        case "testing":
            self = .testing
        case "acceptation":
            self = .acceptation
        case "production":
            self = .production
        default:
            self = .custom(rawValue)
        }
    }
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
    public var rawValue: String {
        switch self {
        case .development: return "development"
        case .testing: return "testing"
        case .acceptation: return "acceptation"
        case .production: return "production"
        case .custom(let type): return type
        }
    }
}
