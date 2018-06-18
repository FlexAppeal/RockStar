public protocol Storeable {
    associatedtype Identifier: Hashable
    
    var identifier: Identifier { get }
}

public protocol Store {
    static var `default`: Self { get }
    associatedtype Entity: Storeable
    
    var count: Future<Int> { get }
    var all: Future<[Entity]> { get }
    subscript(id: Entity.Identifier) -> Future<Entity?> { get }
    subscript<S: Sequence>(ids: S) -> Future<[Entity]> where S.Element == Entity.Identifier { get }
}
