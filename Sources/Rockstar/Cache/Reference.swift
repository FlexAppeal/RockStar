public enum Reference<S: Store> {
    case reference(S.Entity.Identifier)
    case concrete(S.Entity)
}

extension Reference: Decodable where S.Entity: Decodable, S.Entity.Identifier: Decodable {
    public init(from decoder: Decoder) throws {
        do {
            self = try .concrete(S.Entity.init(from: decoder))
        } catch {
            self = try .reference(S.Entity.Identifier.init(from: decoder))
        }
    }
}

extension Store {
    func resolve(_ reference: Reference<Self>) -> Future<Entity?> {
        switch reference {
        case .reference(let identifier):
            return self[identifier]
        case .concrete(let model):
            return Future(result: model)
        }
    }
}
