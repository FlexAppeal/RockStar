import Foundation

public protocol MemoryStoreDataSource {
    associatedtype Entity: Storeable & AnyObject
    
    func count() -> Observer<Int>
    
    /// Needs to be implemeted using Observable for multiple results
    func all() -> Observer<[Entity]>
    func fetchOne(byId id: Entity.Identifier) -> Observer<Entity>
    
    /// Needs to be implemeted using Observable for multiple results
    func fetchMany(byIds ids: Set<Entity.Identifier>) -> Observer<[Entity]>
}

extension MemoryStoreDataSource {
    public func fetchMany(byIds ids: Set<Entity.Identifier>) -> Observer<[Entity]> {
        var entities = [Observer<Entity>]()
        for id in ids {
            let entity = fetchOne(byId: id)
            #if ANALYZE
            entity.then { entity in
                Analytics.default.assert(check: entity.identifier == id)
            }
            #endif
            entities.append(entity)
        }
        
        return entities.combined()
    }
}

extension MemoryStoreDataSource {
    public var memoryStore: MemoryStore<Entity> {
        return MemoryStore(source: self)
    }
}

fileprivate struct AnyMemoryDataSources<E: Storeable> {
    let fetchOne: (E.Identifier) -> Observer<E>
    let fetchMany: (Set<E.Identifier>) -> Observer<[E]>
    let count: () -> Observer<Int>
    let all: () -> Observer<[E]>
    
    init<Source: MemoryStoreDataSource>(source: Source) where Source.Entity == E {
        self.fetchOne = source.fetchOne
        self.fetchMany = source.fetchMany
        self.count = source.count
        self.all = source.all
    }
}

public final class MemoryStore<Entity: Storeable & AnyObject>: Store {
    private final class AnyIdentifier {
        let identifier: Entity.Identifier
        
        init(identifier: Entity.Identifier) {
            self.identifier = identifier
        }
    }
    
    private var entities = NSCache<AnyIdentifier, Entity>()
    private let source: AnyMemoryDataSources<Entity>
    
    public init<Source: MemoryStoreDataSource>(source: Source) where Source.Entity == Entity {
        self.source = .init(source: source)
    }
    
    public subscript(id: Entity.Identifier) -> Observer<Entity> {
        let identifier = AnyIdentifier(identifier: id)
        
        if let entity = entities.object(forKey: identifier) {
            return Observer(result: entity)
        }
        
        return source.fetchOne(id).then { object in
            Analytics.default.assert(check: object.identifier == id)
            
            self.entities.setObject(object, forKey: identifier)
        }
    }
    
    public var count: Observer<Int> { return source.count() }
    public var all: Observer<[Entity]> { return source.all() }
    
    public subscript<S: Sequence>(ids: S) -> Observer<[Entity]> where S.Element == Entity.Identifier {
        var cachedEntities = [Entity]()
        var unresolvedIds = Set<Entity.Identifier>()
        
        for id in ids {
            let identifier = AnyIdentifier(identifier: id)
            if let entity = entities.object(forKey: identifier) {
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
                    let identifier = AnyIdentifier(identifier: entity.identifier)
                    self.entities.setObject(entity, forKey: identifier)
                }
                
                return cachedEntities + newlyFetched
            }
        }
    }
}
