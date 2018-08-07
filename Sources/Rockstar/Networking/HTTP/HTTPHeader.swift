import Foundation

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
    public static let contentLength: HTTPHeaderKey<Int> = "Content-Length"
}

extension String: HTTPHeaderValue {
    public var headerValue: String {
        return self
    }
}

extension Int: HTTPHeaderValue {
    public var headerValue: String {
        return "\(self)"
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
            self[key] = value
        }
    }
    
    public mutating func add<Value>(
        _ key: HTTPHeaderKey<Value>,
        value: Value
    ) {
        self[key.headerKey] = value.headerValue
    }
    
    public subscript(key: String) -> String? {
        get {
            return self.storage.first { $0.0 == key }?.1
        }
        set {
            if let index = self.storage.index(where: { $0.0 == key }) {
                if let newValue = newValue {
                    storage[index].1 = newValue
                } else {
                    storage.remove(at: index)
                }
            } else if let newValue = newValue {
                storage.append((key, newValue))
            }
        }
    }
}

public func +(lhs: HTTPHeaders, rhs: HTTPHeaders) -> HTTPHeaders {
    var headers = HTTPHeaders()
    
    for (key, value) in lhs.storage {
        headers[key] = value
    }
    
    for (key, value) in rhs.storage {
        headers[key] = value
    }
    
    return headers
}

public func +=(lhs: inout HTTPHeaders, rhs: HTTPHeaders) {
    for (key, value) in rhs.storage {
        lhs[key] = value
    }
}
