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
    internal var data: Data {
        var data = Data()
        
        for (key, value) in storage {
            data.append(key, count: key.utf8.count)
            data.append(.colon)
            data.append(.space)
            data.append(value, count: value.utf8.count)
            data.append(.carriageReturn)
            data.append(.newLine)
        }
        
        return data
    }
    
    public init() {}
    
    public init(dictionaryLiteral elements: (String, String)...) {
        for (key, value) in elements {
            self.add(key, value: value)
        }
    }
    
    public mutating func add<Value: HTTPHeaderValue>(
        _ key: HTTPHeaderKey<Value>,
        value: Value
    ) {
        self.add(key.headerKey, value: value.headerValue)
    }
    
    public mutating func add(_ key: String, value: String) {
        if let index = self.storage.index(where: { $0.0 == key }) {
            storage[index].1 = value
        } else {
            storage.append((key, value))
        }
    }
}

public func +(lhs: HTTPHeaders, rhs: HTTPHeaders) -> HTTPHeaders {
    var headers = HTTPHeaders()
    
    for (key, value) in lhs.storage {
        headers.add(key, value: value)
    }
    
    for (key, value) in rhs.storage {
        headers.add(key, value: value)
    }
    
    return headers
}

public func +=(lhs: inout HTTPHeaders, rhs: HTTPHeaders) {
    for (key, value) in rhs.storage {
        lhs.add(key, value: value)
    }
}
