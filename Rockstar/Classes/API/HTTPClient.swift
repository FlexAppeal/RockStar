public protocol HTTPClient {
    func request(_ request: HTTPRequest) -> Observer<HTTPResponse>
}
