import Foundation

public struct HTTPClientConfig {
    public static var `default` = HTTPClientConfig()
    
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
    public static let defaultMetadata = HTTPClientConfig.default
}

extension URLSession: HTTPClient {
    public func request(_ request: HTTPRequest) -> Observer<HTTPResponse> {
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
            
            return promise.future
        }
    }
    
    private func withBody(_ storage: HTTPBody.Storage, on request: URLRequest) -> Observer<URLRequest> {
        var request = request
        
        switch storage {
        case .data(let data):
            request.httpBody = data
            return Observer(result: request)
        case .async(let body):
            return body.flatMap { storage in
                return self.withBody(storage, on: request)
            }
        case .none:
            return Observer(result: request)
        }
    }
}

extension Rockstar where Base: HTTPClient {
    public func send(_ body: Observer<HTTPBody>, to url: URLRepresentable, headers: HTTPHeaders, method: HTTPMethod) -> Observer<HTTPResponse> {
        return body.flatMap { body in
            let request = HTTPRequest(
                method: method,
                url: try url.makeURL(),
                headers: headers,
                body: body
            )
            
            return self.base.request(request)
        }
    }
    
    public func get<C: Content>(
        _ type: C.Type,
        from url: URLRepresentable,
        headers: HTTPHeaders
    ) -> Observer<ContentResponse<C>> {
        let body = Observer(result: HTTPBody())
        return wrap(self.send(body, to: url, headers: headers, method: .get))
    }
    
    public func put<Input: Content, Output: Content>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Observer<ContentResponse<Output>> {
        return wrap(self.send(encode(input), to: url, headers: headers, method: .put))
    }
    
    public func post<Input: Content, Output: Content>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Observer<ContentResponse<Output>> {
        return wrap(self.send(encode(input), to: url, headers: headers, method: .post))
    }
    
    public func patch<Input: Content, Output: Content>(
        _ input: Input,
        to url: URLRepresentable,
        headers: HTTPHeaders,
        expecting response: Output.Type
    ) -> Observer<ContentResponse<Output>> {
        return wrap(self.send(encode(input), to: url, headers: headers, method: .patch))
    }
    
    public func delete<C: Content>(
        _ type: C.Type,
        from url: URLRepresentable,
        headers: HTTPHeaders
        ) -> Observer<ContentResponse<C>> {
        let body = Observer(result: HTTPBody())
        return wrap(self.send(body, to: url, headers: headers, method: .delete))
    }
    
    private func encode<C: Content>(_ input: C) -> Observer<HTTPBody> {
        do {
            let registery = try Services.default.make(CoderRegistery.self)
            
            guard let encoder = registery.encoder(for: C.defaultContentType) else {
                return Observer(error: TodoError())
            }
            
            return encoder.encodeContent(input)
        } catch {
            return Observer(error: error)
        }
    }
    
    private func wrap<C: Content>(
        _ response: Observer<HTTPResponse>,
        for content: C.Type = C.self
    ) -> Observer<ContentResponse<C>> {
        return response.map(ContentResponse<C>.init)
    }
}
