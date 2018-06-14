public protocol HTTPClient {
    func request(_ request: HTTPRequest) -> Observable<HTTPResponse>
}

public struct AnyHTTPClient: HTTPClient, BasicRockstar {
    let requestClosure: (HTTPRequest) -> Observable<HTTPResponse>
    
    public init(_ client: HTTPClient) {
        requestClosure = client.request
    }
    
    public func request(_ request: HTTPRequest) -> Observable<HTTPResponse> {
        return self.requestClosure(request)
    }
}
