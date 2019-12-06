import Foundation

public struct HTTPMethod: ExpressibleByStringLiteral, RawRepresentable {
    public let rawValue: String
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static let get: HTTPMethod = "GET"
    public static let put: HTTPMethod = "PUT"
    public static let post: HTTPMethod = "POST"
    public static let patch: HTTPMethod = "PATCH"
    public static let delete: HTTPMethod = "DELETE"
    public static let options: HTTPMethod = "OPTIONS"
}

public struct HTTPStatus: ExpressibleByIntegerLiteral, RawRepresentable {
    public let rawValue: Int
    
    public init(integerLiteral value: Int) {
        self.rawValue = value
    }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct HTTPRequest: Hashable {
    private let internalId = UUID()
    
    public var hashValue: Int { return internalId.hashValue }
    
    public static func ==(lhs: HTTPRequest, rhs: HTTPRequest) -> Bool {
        return lhs.internalId == rhs.internalId
    }
    
    public var method: HTTPMethod
    public var url: URL
    public var headers: HTTPHeaders
    public var body: HTTPBody
    
    public init(method: HTTPMethod, url: URL, headers: HTTPHeaders, body: HTTPBody) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
    
    public func makeURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        for (key, value) in headers.storage {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}

public struct HTTPResponse {
    public var status: HTTPStatus
    public var headers: HTTPHeaders
    public var body: HTTPBody
}

public struct HTTPBody {
    internal indirect enum Storage {
        case data(Data)
        case none
        
        public var count: Int {
            switch self {
            case .data(let data): return data.count
            case .none: return 0
            }
        }
    }
    
    internal let storage: Storage
    
    public init() {
        self.storage = .none
    }
    
    public init(data: Data) {
        self.storage = .data(data)
    }
    
    public var data: Data? {
        switch storage {
        case .none:
            return nil
        case .data(let data):
            return data
        }
    }
    
    public func makeData() -> Future<Data?> {
        switch storage {
        case .none:
            return nil
        case .data(let data):
            return Future(result: data)
        }
    }
}
