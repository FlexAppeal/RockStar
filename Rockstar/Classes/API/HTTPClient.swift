public protocol HTTPClient {
    func request(_ request: HTTPRequest) -> Observer<HTTPResponse>
}

public struct AnyHTTPClient: HTTPClient, BasicRockstar {
    let requestClosure: (HTTPRequest) -> Observer<HTTPResponse>
    
    public init(_ client: HTTPClient) {
        requestClosure = client.request
    }
    
    public func request(_ request: HTTPRequest) -> Observer<HTTPResponse> {
        return self.requestClosure(request)
    }
}
