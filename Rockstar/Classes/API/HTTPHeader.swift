public protocol HTTPHeaderValue {
    var headerValue: String { get }
}

public struct HTTPHeaderKey<Value: HTTPHeaderValue>: ExpressibleByStringLiteral {
    public let headerKey: String
    
    public init(stringLiteral value: String) {
        self.headerKey = value
    }
}

extension HTTPHeaderKey where Value == MediaType {
    public static let contentType: HTTPHeaderKey<MediaType> = "Content-Type"
}

extension String: HTTPHeaderValue {
    public var headerValue: String {
        return self
    }
}

extension MediaType: HTTPHeaderValue {
    public var headerValue: String { return "\(self.type)/\(self.subType)" }
}

public struct HTTPHeaders: ExpressibleByDictionaryLiteral {
    internal var storage = [(String, String)]()
    
    public init() {}
    
    public init(dictionaryLiteral elements: (String, String)...) {
        self.storage = elements
    }
    
    public mutating func add<Value: HTTPHeaderValue>(
        _ key: HTTPHeaderKey<Value>,
        value: Value
    ) {
        storage.append((key.headerKey, value.headerValue))
    }
    
    public mutating func add(_ key: String, value: String) {
        storage.append((key, value))
    }
}
