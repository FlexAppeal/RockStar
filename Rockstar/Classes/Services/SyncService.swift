public protocol ServiceFactory {
    associatedtype Result: Service
    
    func make(from services: Services) throws -> Result
}

public protocol Service {}

struct SingleValueFactory<Result: Service>: ServiceFactory {
    let service: Result
    
    init(service: Result) {
        self.service = service
    }
    
    func make(from services: Services) -> Result {
        return service
    }
}

struct AnySyncClosureFactory<Result: Service>: ServiceFactory {
    typealias Closure = (Services) throws -> Result
    let factory: Closure
    
    init(factory: @escaping Closure) {
        self.factory = factory
    }
    
    func make(from services: Services) throws -> Result {
        return try factory(services)
    }
}

public struct AnyServiceFactory {
    let identifier: ObjectIdentifier
    private let factoryMethod: (Services) throws -> Any
    
    init<Factory: ServiceFactory>(factory: Factory) {
        self.identifier = ObjectIdentifier(Factory.Result.self)
        self.factoryMethod = { services in
            return try factory.make(from: services) as Any
        }
    }
    
    public func make(from services: Services) throws -> Any {
        return try factoryMethod(services)
    }
}

extension ServiceBuilder {
    public typealias SyncClosureFactory<S: Service> = (Services) throws -> S
    
    public func register<S: Service, Result>(_ service: S, substituting type: Result.Type) {
        assert(service is Result, "The registered service does not match the resulting type")
        
        self.register(SingleValueFactory(service: service), substituting: type)
    }
    
    public func register<S: Service, Result>(
        substitutionFor type: Result.Type,
        _ factory: @escaping SyncClosureFactory<S>
    ) {
        assert(S.self is Result, "The registered service does not match the resulting type")
        
        self.register(AnySyncClosureFactory(factory: factory), substituting: type)
    }
    
    public func register<Factory: ServiceFactory, Result>(_ factory: Factory, substituting type: Result.Type) {
        let id = ObjectIdentifier(type)
        var factory = AnyServiceFactory(factory: factory)
        
        if let existing = self.syncFactories[id] {
            factory = self.syncResolution.resolve(old: existing, new: factory)
        }
        
        self.syncFactories[id] = factory
    }
}
