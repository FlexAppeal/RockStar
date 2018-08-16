public protocol Storeable {
    associatedtype Identifier: Hashable
    
    var dataStoreIdentifier: Identifier { get }
}

public protocol DataStore {
    associatedtype Entity: Storeable
    
    func resolve(_ identifier: Entity.Identifier) -> Future<Entity?>
}

fileprivate struct EntityNotFound: RockstarError {
    let location = SourceLocation()
}
