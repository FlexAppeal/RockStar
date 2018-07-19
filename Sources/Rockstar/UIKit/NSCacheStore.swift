import Foundation

fileprivate struct AnyNSCacheDataSource<E: Storeable> {
    let fetchOne: (E.Identifier) -> Future<E?>
    let fetchMany: (Set<E.Identifier>) -> Future<[E]>
    let count: () -> Future<Int>
    let all: () -> Future<[E]>
    let paginate: (Int, Int) -> Future<PaginatedResults<E>>
    
    init<Source: DataStoreSource>(source: Source) where Source.Entity == E {
        self.fetchOne = source.fetchOne
        self.fetchMany = source.fetchMany
        self.count = source.count
        self.all = source.all
        self.paginate = source.paginate
    }
}

fileprivate struct NoDataSource: RockstarError {
    let location = SourceLocation()
}

public final class NSCacheStore<Entity: Storeable>: Store {
    private final class AnyIdentifier {
        let identifier: Entity.Identifier
        
        init(identifier: Entity.Identifier) {
            self.identifier = identifier
        }
    }
    
    private final class AnyInstance {
        let instance: Entity
        
        init(instance: Entity) {
            self.instance = instance
        }
    }
    
    /// Do not change this variable while the cache is in use
    ///
    /// It may lead to unexpected release results
    public var cacheLifetime: RSTimeInterval = .seconds(3600 &* 4) // 4 hours
    
    private var lifetimes = [(Date, AnyIdentifier)]()
    private var entities = NSCache<AnyIdentifier, AnyInstance>()
    private var source: AnyNSCacheDataSource<Entity>?
    
    public func fetchData<Source: DataStoreSource>(fromSource source: Source) where Source.Entity == Entity {
        self.source = .init(source: source)
    }
    
    public init() {
        self.source = nil
    }
    
    public init<Source: DataStoreSource>(source: Source) where Source.Entity == Entity {
        self.source = .init(source: source)
    }
    
    public subscript(id: Entity.Identifier) -> Future<Entity?> {
        let identifier = AnyIdentifier(identifier: id)
        
        if let entity = entities.object(forKey: identifier) {
            return Future(result: entity.instance)
        }
        
        guard let source = source else {
            return nil
        }
        
        return source.fetchOne(id).then { object in
            if let object = object {
                self.cache(object)
            }
        }
    }
    
    public func invalidateCache() {
        entities.removeAllObjects()
    }
    
    public var count: Future<Int> { return source?.count() ?? 0 }
    public var all: Future<[Entity]> { return source?.all() ?? [] }
    
    private func cache(_ entity: Entity) {
        let identifier = AnyIdentifier(identifier: entity.identifier)
        let instance = AnyInstance(instance: entity)
        
        self.entities.setObject(instance, forKey: identifier)
        
//        var end = Date()
//        end.addTimeInterval(cacheLifetime.dispatch)
//        
//        self.lifetimes.append(())
    }
    
    public subscript<S: Sequence>(ids: S) -> Future<[Entity]> where S.Element == Entity.Identifier {
        var cachedEntities = [Entity]()
        var unresolvedIds = Set<Entity.Identifier>()
        
        for id in ids {
            let identifier = AnyIdentifier(identifier: id)
            if let entity = entities.object(forKey: identifier) {
                cachedEntities.append(entity.instance)
            } else {
                unresolvedIds.insert(id)
            }
        }
        
        if unresolvedIds.isEmpty {
            return Future(result: cachedEntities)
        } else {
            guard let source = source else {
                return Future(error: NoDataSource())
            }
            
            return source.fetchMany(unresolvedIds).map { newlyFetched in
                for entity in newlyFetched {
                    self.cache(entity)
                }
                
                return cachedEntities + newlyFetched
            }
        }
    }
}
