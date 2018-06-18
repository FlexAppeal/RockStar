import Foundation

public struct HTTPClientConfig {
    public static var `default` = HTTPClientConfig()
    
    public var timeout: RSTimeout?
    public var services: () -> (Services) = { return .default }
}

fileprivate extension HTTPResponse {
    init(response: HTTPURLResponse, data: Data?) {
        var headers = HTTPHeaders()
        
        for (key, value) in response.allHeaderFields {
            headers.add(key.description, value: "\(value)")
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

extension URLSession: Service {}
extension URLSessionConfiguration: Service {}

extension URLSession: BasicRockstar {
    public static var settings: HTTPClientConfig { return .default }
}

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
            promise.onCancel(task.cancel)
            
            if let timeout = URLSession.settings.timeout {
                return promise.timeout(timeout).future
            } else {
                return promise.future
            }
        }
    }
    
    private func withBody(_ storage: HTTPBody.Storage, on request: URLRequest) -> Future<URLRequest> {
        var request = request
        
        switch storage {
        case .data(let data):
            request.httpBody = data
            return Future(result: request)
        case .async(let body):
            return body.flatMap { storage in
                return self.withBody(storage, on: request)
            }
        case .none:
            return Future(result: request)
        }
    }
}

extension HTTPClient {
    public func send(_ body: Future<HTTPBody>, to url: URLRepresentable, headers: HTTPHeaders, method: HTTPMethod) -> Future<HTTPResponse> {
        return body.flatMap { body in
            let request = HTTPRequest(
                method: method,
                url: try url.makeURL(),
                headers: headers,
                body: body
            )
            
            return self.request(request)
        }
    }
    
    public func get<C: Content>(
        _ type: C.Type,
        from url: URLRepresentable,
        headers: HTTPHeaders
    ) -> Future<ContentResponse<C>> {
        let body = Future(result: HTTPBody())
        return wrap(self.send(body, to: url, headers: headers, method: .get))
    }
    
    public func put<Input: Content, Output: Content>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Future<ContentResponse<Output>> {
        return wrap(self.send(encode(input), to: url, headers: headers, method: .put))
    }
    
    public func post<Input: Content, Output: Content>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Future<ContentResponse<Output>> {
        return wrap(self.send(encode(input), to: url, headers: headers, method: .post))
    }
    
    public func patch<Input: Content, Output: Content>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Future<ContentResponse<Output>> {
        return wrap(self.send(encode(input), to: url, headers: headers, method: .patch))
    }
    
    public func delete<C: Content>(
        _ type: C.Type,
        from url: URLRepresentable,
        headers: HTTPHeaders
    ) -> Future<ContentResponse<C>> {
        let body = Future(result: HTTPBody())
        return wrap(self.send(body, to: url, headers: headers, method: .delete))
    }
    
    private func encode<C: Content>(_ input: C) -> Future<HTTPBody> {
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
    
    private func wrap<C: Content>(
        _ response: Future<HTTPResponse>,
        for content: C.Type = C.self
    ) -> Future<ContentResponse<C>> {
        return response.map(ContentResponse<C>.init)
    }
}
