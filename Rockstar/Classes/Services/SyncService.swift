public protocol ServiceFactory {
    associatedtype Result: Service
    
    func make() throws -> Result
}

public protocol Service {}

struct SingleValueFactory<Result: Service>: ServiceFactory {
    let service: Result
    
    init(service: Result) {
        self.service = service
    }
    
    func make() -> Result {
        return service
    }
}

public struct AnyServiceFactory {
    let identifier: ObjectIdentifier
    private let factoryMethod: () throws -> Any
    
    init<Factory: ServiceFactory>(factory: Factory) {
        self.identifier = ObjectIdentifier(Factory.Result.self)
        self.factoryMethod = {
            return try factory.make() as Any
        }
    }
    
    public func make() throws -> Any {
        return try factoryMethod()
    }
}

extension ServiceBuilder {
    public func register<S: Service, Result>(_ service: S, substituting type: Result.Type) {
        assert(service is Result, "The registered service does not match the resulting type")
        
        self.register(SingleValueFactory(service: service), substituting: type)
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
