public struct MediaType: ExpressibleByStringLiteral, Hashable {
    public let type: String
    public let subType: String
    
    public init(type: String, subType: String) {
        self.type = type
        self.subType = subType
        
        let fullType = "\(type)/\(subType)"
        
        if !MediaType.registery.keys.contains(fullType) {
            MediaType.registery[fullType] = self
        }
    }
    
    public init(stringLiteral value: String) {
        let values = value.split(separator: "/", maxSplits: 1)
        
        self.init(type: String(values[0]), subType: String(values[1]))
    }
    
    public private(set) static var registery = [String: MediaType]()
    
    public static let json: MediaType = "application/json"
}

public protocol Content: Codable {
    static var defaultContentType: MediaType { get }
}

extension Content {
    public static var defaultContentType: MediaType { return .json }
}

public protocol APIContent: Content {
    associatedtype M: Model
    
    func makeModel() throws -> M
}

public protocol Model: Codable {}

public struct ContentResponse<C: Content> {
    public let raw: HTTPResponse
    
    public func decodeBody() -> Observer<C> {
        do {
            let coders = try Services.default.make(CoderRegistery.self)
            guard let decoder = coders.decoder(for: C.defaultContentType) else {
                throw ServiceNotFound()
            }
            
            return decoder.decodeContent(C.self, from: raw.body)
        } catch {
            return Observer(error: error)
        }
    }
}

public protocol ContentEncoder {
    static var mediaType: MediaType { get }
    
    func encodeContent<E: Encodable>(_ input: E) -> Observer<HTTPBody>
}

public protocol ContentDecoder {
    static var mediaType: MediaType { get }
    
    func decodeContent<D: Decodable>(_ type: D.Type, from body: HTTPBody) -> Observer<D>
}

extension JSONEncoder: ContentEncoder {
    public static let mediaType = MediaType.json
    
    public func encodeContent<E>(_ input: E) -> Observer<HTTPBody> where E : Encodable {
        do {
            return try Observer(result: HTTPBody(data: self.encode(input)))
        } catch {
            return Observer(error: error)
        }
    }
}

extension JSONDecoder: ContentDecoder {
    public static let mediaType = MediaType.json
    
    public func decodeContent<D>(_ type: D.Type, from body: HTTPBody) -> Observer<D> where D : Decodable {
        func decode(_ storage: HTTPBody.Storage) -> Observer<D> {
            do {
                switch storage {
                case .none:
                    return Observer(result: try self.decode(D.self, from: Data()))
                case .data(let data):
                    return Observer(result: try self.decode(D.self, from: data))
                case .async(let future):
                    return future.flatMap(decode)
                }
            } catch {
                return Observer(error: error)
            }
        }
        
        return decode(body.storage)
    }
}

public struct CoderRegistery: Service {
    private var encoders = [MediaType: ContentEncoder]()
    private var decoders = [MediaType: ContentDecoder]()
    
    public init() {}
    
    public mutating func register<Encoder: ContentEncoder>(_ encoder: Encoder) {
        self.encoders[Encoder.mediaType] = encoder
    }
    
    public mutating func register<Decoder: ContentDecoder>(_ decoder: Decoder) {
        self.decoders[Decoder.mediaType] = decoder
    }
    
    public func encoder(for mediaType: MediaType) -> ContentEncoder? {
        return encoders[mediaType]
    }
    
    public func decoder(for mediaType: MediaType) -> ContentDecoder? {
        return decoders[mediaType]
    }
}

extension Array: Content where Element: Content {
    public static var defaultContentType: MediaType { return Element.defaultContentType }
}
