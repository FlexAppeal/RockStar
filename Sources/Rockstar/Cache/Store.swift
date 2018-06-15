public protocol Storeable {
    associatedtype Identifier: Hashable
    
    var identifier: Identifier { get }
}

public protocol Store {
    static var `default`: Self { get }
    associatedtype Entity: Storeable
    
    var count: Observable<Int> { get }
    var all: Observable<[Entity]> { get }
    subscript(id: Entity.Identifier) -> Observable<Entity?> { get }
    subscript<S: Sequence>(ids: S) -> Observable<[Entity]> where S.Element == Entity.Identifier { get }
}
