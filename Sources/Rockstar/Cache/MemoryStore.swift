import Foundation

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
    
    func count() -> Observable<Int>
    
    /// Needs to be implemeted using Observable for multiple results
    func all() -> Observable<[Entity]>
    func paginate(from: Int, to: Int) -> Observable<PaginatedResults<Entity>>
    func fetchOne(byId id: Entity.Identifier) -> Observable<Entity?>
    
    /// Needs to be implemeted using Observable for multiple results
    func fetchMany(byIds ids: Set<Entity.Identifier>) -> Observable<[Entity]>
}

extension DataManagerSource {
    public func fetchMany(byIds ids: Set<Entity.Identifier>) -> Observable<[Entity]> {
        var entities = [Observable<Entity>]()
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

fileprivate struct AnyMemoryDataSources<E: Storeable> {
    let fetchOne: (E.Identifier) -> Observable<E?>
    let fetchMany: (Set<E.Identifier>) -> Observable<[E]>
    let count: () -> Observable<Int>
    let all: () -> Observable<[E]>
    let paginate: (Int, Int) -> Observable<PaginatedResults<E>>
    
    init<Source: DataManagerSource>(source: Source) where Source.Entity == E {
        self.fetchOne = source.fetchOne
        self.fetchMany = source.fetchMany
        self.count = source.count
        self.all = source.all
        self.paginate = source.paginate
    }
}

fileprivate struct NoDataSource: Error {}
fileprivate struct EntityNotFound: Error {}

public final class DataManager<Entity: Storeable> {
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
    
    private var entities = NSCache<AnyIdentifier, AnyInstance>()
    private var source: AnyMemoryDataSources<Entity>?
    
    public func fetchData<Source: DataManagerSource>(fromSource source: Source) where Source.Entity == Entity {
        self.source = .init(source: source)
    }
    
    public init() {
        self.source = nil
    }
    
    public init<Source: DataManagerSource>(source: Source) where Source.Entity == Entity {
        self.source = .init(source: source)
    }
    
    public subscript(id: Entity.Identifier) -> Observable<Entity?> {
        let identifier = AnyIdentifier(identifier: id)
        
        if let entity = entities.object(forKey: identifier) {
            return Observable(result: entity.instance)
        }
        
        guard let source = source else {
            return nil
        }
        
        return source.fetchOne(id).then { object in
            if let object = object {
                let instance = AnyInstance(instance: object)
                Analytics.default.assert(check: object.identifier == id)
                
                self.entities.setObject(instance, forKey: identifier)
            }
        }
    }
    
    public func invalidateCache() {
        entities.removeAllObjects()
    }
    
    public var count: Observable<Int> { return source?.count() ?? 0 }
    public var all: Observable<[Entity]> { return source?.all() ?? [] }
    
    public subscript<S: Sequence>(ids: S) -> Observable<[Entity]> where S.Element == Entity.Identifier {
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
            return Observable(result: cachedEntities)
        } else {
            guard let source = source else {
                return Observable(error: NoDataSource())
            }
            
            return source.fetchMany(unresolvedIds).map { newlyFetched in
                for entity in newlyFetched {
                    let identifier = AnyIdentifier(identifier: entity.identifier)
                    let instance = AnyInstance(instance: entity)
                    
                    self.entities.setObject(instance, forKey: identifier)
                }
                
                return cachedEntities + newlyFetched
            }
        }
    }
}
