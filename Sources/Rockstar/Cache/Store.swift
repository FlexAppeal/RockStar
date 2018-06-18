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

public struct PaginatedResults<Result> {
    public var results: [Result]
    public let startIndex: Int
    public let endIndex: Int
    
    public init(results: [Result], from start: Int, to end: Int) {
        self.results = results
        self.startIndex = start
        self.endIndex = end
    }
}

public protocol DataManagerSource {
    associatedtype Entity: Storeable & AnyObject
    
    func save(_ entity: Entity) -> Future<Void>
    func count() -> Future<Int>
    
    /// Needs to be implemeted using OutputStream for multiple results
    func all() -> Future<[Entity]>
    func paginate(from: Int, to: Int) -> Future<PaginatedResults<Entity>>
    func fetchOne(byId id: Entity.Identifier) -> Future<Entity?>
    
    /// Needs to be implemeted using OutputStream for multiple results
    func fetchMany(byIds ids: Set<Entity.Identifier>) -> Future<[Entity]>
}

fileprivate struct EntityNotFound: RockstarError {
    let location = SourceLocation()
}

extension DataManagerSource {
    public func fetchMany(byIds ids: Set<Entity.Identifier>) -> Future<[Entity]> {
        var entities = [Future<Entity>]()
        for id in ids {
            let entity = fetchOne(byId: id).assert(or: EntityNotFound())
            
            #if ANALYZE
            entity.then { entity in
                Analytics.default.assert(check: entity.identifier == id)
            }
            #endif
            entities.append(entity)
        }
        
        return entities.joined()
    }
}

extension DataManagerSource {
    public var dataManager: DataManager<Entity> {
        return DataManager(source: self)
    }
}
