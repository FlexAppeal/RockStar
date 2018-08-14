public enum Reference<S: Storeable> {
    case reference(S.Identifier)
    case concrete(S)
    
    public var identifier: S.Identifier {
        switch self {
        case .reference(let id): return id
        case .concrete(let entity): return entity.identifier
        }
    }
}

extension Reference: Encodable where S.Identifier: Encodable {
    public func encode(to encoder: Encoder) throws {
        try identifier.encode(to: encoder)
    }
}

extension Reference: Decodable where S: Decodable, S.Identifier: Decodable {
    public init(from decoder: Decoder) throws {
        do {
            self = try .reference(S.Identifier.init(from: decoder))
        } catch {
            self = try .concrete(S.init(from: decoder))
        }
    }
}

extension DataStore {
    func resolve(_ reference: Reference<Entity>) -> Future<Entity?> {
        switch reference {
        case .reference(let identifier):
            return self[identifier]
        case .concrete(let model):
            return Future(result: model)
        }
    }
}
