public protocol MemoryStoreable {
    associatedtype Identifier: Hashable
    
    var identifier: Identifier { get }
}

public protocol MemoryStoreDataSource {
    associatedtype Entity: MemoryStoreable
    
    func fetchOne(byId id: Entity.Identifier) -> Observer<Entity>
    func fetchMany(byIds ids: Set<Entity.Identifier>) -> Observer<[Entity]>
}

fileprivate struct AnyMemoryDataSources<E: MemoryStoreable> {
    var fetchOne: (E.Identifier) -> Observer<E>
    var fetchMany: (Set<E.Identifier>) -> Observer<[E]>
    
    init<Source: MemoryStoreDataSource>(source: Source) where Source.Entity == E {
        self.fetchOne = source.fetchOne
        self.fetchMany = source.fetchMany
    }
}

public final class MemoryStore<Entity: MemoryStoreable> {
    private var entities = [Entity.Identifier: Entity]()
    private let source: AnyMemoryDataSources<Entity>
    
    public init<Source: MemoryStoreDataSource>(source: Source) where Source.Entity == Entity {
        self.source = .init(source: source)
    }
    
    public subscript(id: Entity.Identifier) -> Observer<Entity> {
        if let entity = entities[id] {
            return Observer(result: entity)
        }
        
        return source.fetchOne(id).then { object in
            self.entities[object.identifier] = object
        }
    }
    
    public func cleanMemory() {
        self.entities = [:]
    }
    
    public subscript<S: Sequence>(ids: S) -> Observer<[Entity]> where S.Element == Entity.Identifier {
        var cachedEntities = [Entity]()
        var unresolvedIds = Set<Entity.Identifier>()
        
        for id in ids {
            if let entity = entities[id] {
                cachedEntities.append(entity)
            } else {
                unresolvedIds.insert(id)
            }
        }
        
        if unresolvedIds.isEmpty {
            return Observer(result: cachedEntities)
        } else {
            return source.fetchMany(unresolvedIds).map { newlyFetched in
                for entity in newlyFetched {
                    self.entities[entity.identifier] = entity
                }
                
                return cachedEntities + newlyFetched
            }
        }
    }
}
