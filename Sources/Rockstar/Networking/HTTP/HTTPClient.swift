public protocol HTTPClient {
    func request(_ request: HTTPRequest) -> Future<HTTPResponse>
}

public struct AnyHTTPClient: HTTPClient, BasicRockstar {
    let requestClosure: (HTTPRequest) -> Future<HTTPResponse>
    
    public init(_ client: HTTPClient) {
        requestClosure = client.request
    }
    
    public func request(_ request: HTTPRequest) -> Future<HTTPResponse> {
        return self.requestClosure(request)
    }
}
