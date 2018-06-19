public enum Reference<S: Store> where S.Entity: Decodable, S.Entity.Identifier: Decodable {
    case reference(S.Entity.Identifier)
    case concrete(S.Entity)
    
    init(from decoder: Decoder) throws {
        do {
            self = try .concrete(S.Entity.init(from: decoder))
        } catch {
            self = try .reference(S.Entity.Identifier.init(from: decoder))
        }
    }
    
    func resolve(from store: S) -> Future<S.Entity?> {
        switch self {
        case .reference(let identifier):
            return store[identifier]
        case .concrete(let model):
            return Future(result: model)
        }
    }
}
