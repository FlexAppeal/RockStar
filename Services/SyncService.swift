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
    public func register<S: Service>(_ service: S, substituting type: Any.Type) {
        self.register(SingleValueFactory(service: service), substituting: type)
    }
    
    public func register<S: Service>(_ service: S, substituting types: [Any.Type]) {
        self.register(SingleValueFactory(service: service), substituting: types)
    }
    
    public func register<Factory: ServiceFactory>(_ factory: Factory, substituting type: Any.Type) {
        self.register(factory, substituting: [type])
    }
    
    public func register<Factory: ServiceFactory>(_ factory: Factory, substituting types: [Any.Type]) {
        let ids = types.map(ObjectIdentifier.init)
        let factory = AnyServiceFactory(factory: factory)
        self.syncFactories.append((factory, ids))
    }
}
