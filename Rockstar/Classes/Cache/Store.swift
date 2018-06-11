public protocol Storeable {
    associatedtype Identifier: Hashable
    
    var identifier: Identifier { get }
}

public protocol Store {
    associatedtype Entity: Storeable
    
    var count: Observer<Int> { get }
    var all: Observer<[Entity]> { get }
    subscript(id: Entity.Identifier) -> Observer<Entity> { get }
    subscript<S: Sequence>(ids: S) -> Observer<[Entity]> where S.Element == Entity.Identifier { get }
}
