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

extension Reference: Decodable where S: Decodable, S.Identifier: Decodable {
    public init(from decoder: Decoder) throws {
        do {
            self = try .concrete(S.init(from: decoder))
        } catch {
            self = try .reference(S.Identifier.init(from: decoder))
        }
    }
}

extension Store {
    func resolve(_ reference: Reference<Entity>) -> Future<Entity?> {
        switch reference {
        case .reference(let identifier):
            return self[identifier]
        case .concrete(let model):
            return Future(result: model)
        }
    }
}
