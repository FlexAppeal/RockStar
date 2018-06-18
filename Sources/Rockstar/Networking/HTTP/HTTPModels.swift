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

public struct HTTPRequest {
    public var method: HTTPMethod
    public var url: URL
    public var headers: HTTPHeaders
    public var body: HTTPBody
    
    public func makeURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        for (key, value) in headers.storage {
            request.addValue(key, forHTTPHeaderField: value)
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
    public indirect enum Storage {
        case data(Data)
        case async(Future<Storage>)
        case none
    }
    
    public let storage: Storage
    
    public init() {
        self.storage = .none
    }
    
    public init(data: Data) {
        self.storage = .data(data)
    }
    
    public init(data: Future<Data>) {
        self.storage = .async(data.map {
            Storage.data($0)
        })
    }
}
