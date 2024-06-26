import Foundation

public struct HTTPClientConfig: Service {
    public var timeout: RSTimeout? = RSTimeout(after: .seconds(30), onThread: .dispatchQueue(.main))
    public var switchThread: AnyThread? = .dispatchQueue(.main)
    
    public var debugLogs: LogDestination?
    
    public var middleware = [HTTPClientMiddleware]()
    
    public init() {}
}

public protocol HTTPClientMiddleware {
    func transform(request: HTTPRequest, client: HTTPClient) throws -> Future<HTTPRequest>
    func transform(response: HTTPResponse, forRequest request: HTTPRequest, client: HTTPClient) throws -> Future<HTTPResponse>
}

fileprivate extension HTTPResponse {
    init(response: HTTPURLResponse, data: Data?) {
        var headers = HTTPHeaders()
        
        for (key, value) in response.allHeaderFields {
            headers[key.description] = "\(value)"
        }
        
        let body: HTTPBody
        if let data = data {
           body = HTTPBody(data: data)
        } else {
            body = HTTPBody()
        }
        
        self = HTTPResponse(status: HTTPStatus(rawValue: response.statusCode), headers: headers, body: body)
    }
}

public final class RSHTTPClient: Service, HTTPClient {
    let session: URLSession
    let config: HTTPClientConfig
    
    public init(config: HTTPClientConfig) {
        self.session = URLSession(configuration: .default)
        self.config = config
    }
    
    public func request(_ request: HTTPRequest) -> Future<HTTPResponse> {
        let allMiddleware = config.middleware
        
        var response = allMiddleware.asyncReduce(request) { request, middleware in
            return try middleware.transform(request: request, client: self)
        }.flatMap { request in
            return self.session.request(request).flatMap { response in
                return allMiddleware.asyncReduce(response) { response, middleware in
                    return try middleware.transform(response: response, forRequest: request, client: self)
                }
            }
        }
        
        if let switchThread = config.switchThread {
            response = response.switchThread(to: switchThread)
        }
        
        if let timeout = config.timeout {
            response = response.timeout(timeout)
        }
        
        return response
    }
}

extension URLSession: Service {}
extension URLSessionConfiguration: Service {}

extension URLSession: HTTPClient {
    public func request(_ request: HTTPRequest) -> Future<HTTPResponse> {
        let urlRequest = request.makeURLRequest()
        return withBody(request.body.storage, on: urlRequest).flatMap { request in
            let promise = Promise<HTTPResponse>()
            
            let task = self.dataTask(with: request) { data, response, error in
                guard let response = response as? HTTPURLResponse else {
                    promise.fail(error ?? UnknownError())
                    return
                }
                
                promise.complete(HTTPResponse(response: response, data: data))
            }
                
            task.resume()
            promise.onCancel(run: task.cancel)
            
            return promise.future
        }
    }
    
    private func withBody(_ storage: HTTPBody.Storage, on request: URLRequest) -> Future<URLRequest> {
        var request = request
        
        switch storage {
        case .stream(let stream):
            request.httpBodyStream = stream
            return Future(result: request)
        case .data(let data):
            request.httpBody = data
            return Future(result: request)
        case .none:
            return Future(result: request)
        }
    }
}

extension HTTPClient {
    public func send(_ body: HTTPBody, to url: URLRepresentable, headers: HTTPHeaders, method: HTTPMethod) -> Future<HTTPResponse> {
        return Future.do {
            let request = HTTPRequest(
                method: method,
                url: try url.makeURL(),
                headers: headers,
                body: body
            )
            
            return self.request(request)
        }
    }
    
    public func get<C: ContentDecodable>(
        _ type: C.Type,
        from url: URLRepresentable,
        headers: HTTPHeaders
    ) -> Future<ContentResponse<C>> {
        return Future.do {
            let request = HTTPRequest(
                method: .get,
                url: try url.makeURL(),
                headers: headers,
                body: HTTPBody()
            )
            
            return self.wrapResponse(
                self.request(request),
                forRequest: request
            )
        }
    }
    
    public func put<Input: ContentEncodable, Output: ContentDecodable>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Future<ContentResponse<Output>> {
        return encode(input).flatMap { body in
            var headers = headers
            headers.add(.contentType, value: Input.defaultContentType)
//            headers.add(.contentLength, value: body.storage.count)
            
            let request = HTTPRequest(
                method: .put,
                url: try url.makeURL(),
                headers: headers,
                body: body
            )
            
            return self.wrapResponse(
                self.request(request),
                forRequest: request
            )
        }
    }
    
    public func post<Input: ContentEncodable, Output: ContentDecodable>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Future<ContentResponse<Output>> {
        return encode(input).flatMap { body in
            var headers = headers
            headers.add(.contentType, value: Input.defaultContentType)
//            headers.add(.contentLength, value: body.storage.count)
            
            let request = HTTPRequest(
                method: .post,
                url: try url.makeURL(),
                headers: headers,
                body: body
            )
            
            return self.wrapResponse(
                self.request(request),
                forRequest: request
            )
        }
    }
    
    public func patch<Input: ContentEncodable, Output: ContentDecodable>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Future<ContentResponse<Output>> {
        return encode(input).flatMap { body in
            var headers = headers
            headers.add(.contentType, value: Input.defaultContentType)
            
            let request = HTTPRequest(
                method: .patch,
                url: try url.makeURL(),
                headers: headers,
                body: body
            )
            
            return self.wrapResponse(
                self.request(request),
                forRequest: request
            )
        }
    }
    
    public func delete<C: ContentDecodable>(
        _ type: C.Type,
        from url: URLRepresentable,
        headers: HTTPHeaders
    ) -> Future<ContentResponse<C>> {
        return Future.do {
            let request = HTTPRequest(
                method: .delete,
                url: try url.makeURL(),
                headers: headers,
                body: HTTPBody()
            )
            
            return self.wrapResponse(
                self.request(request),
                forRequest: request
            )
        }
    }
    
    private func encode<C: ContentEncodable>(_ input: C) -> Future<HTTPBody> {
        do {
            let registery = try Services.default.make(CoderRegistery.self)
            
            guard let encoder = registery.encoder(for: C.defaultContentType) else {
                return Future(error: TodoError())
            }
            
            return encoder.encodeContent(input)
        } catch {
            return Future(error: error)
        }
    }
    
    private func wrapResponse<C: Content>(
        _ response: Future<HTTPResponse>,
        forRequest request: HTTPRequest?,
        for content: C.Type = C.self
    ) -> Future<ContentResponse<C>> {
        return response.map { response in
            return ContentResponse<C>(request: request, response: response)
        }
    }
}

extension Future {
    public func body<C: ContentDecodable>(_ type: C.Type = C.self) -> Future<C> where FutureValue == ContentResponse<C> {
        return self.flatMap { $0.decodeBody() }
    }
}
