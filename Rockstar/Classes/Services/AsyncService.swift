public protocol AsyncServiceFactory {
    associatedtype Result: AsyncService
    
    func make() -> Observer<Result>
}

public protocol AsyncService {}

struct AsyncSingleValueFactory<Result: AsyncService>: AsyncServiceFactory {
    let service: Observer<Result>
    
    init(service: Observer<Result>) {
        self.service = service
    }
    
    func make() -> Observer<Result> {
        return service
    }
}

public struct AnyAsyncServiceFactory {
    let identifier: ObjectIdentifier
    private let factoryMethod: () throws -> Observer<Any>
    
    init<Factory: AsyncServiceFactory>(factory: Factory) {
        self.identifier = ObjectIdentifier(Factory.Result.self)
        self.factoryMethod = {
            return factory.make().map { $0 as Any }
        }
    }
    
    public func make() throws -> Observer<Any> {
        return try factoryMethod()
    }
}

extension ServiceBuilder {
    public func register<S: AsyncService, Result>(_ service: Observer<S>, substituting type: Result.Type) {
        assert(S.self is Result, "The registered service does not match the resulting type")
        
        self.register(AsyncSingleValueFactory(service: service), substituting: type)
    }
    
    public func register<Factory: AsyncServiceFactory, Result>(_ factory: Factory, substituting type: Result.Type) {
        let id = ObjectIdentifier(type)
        var factory = AnyAsyncServiceFactory(factory: factory)
        
        if let existing = self.asyncFactories[id] {
            factory = self.asyncResolution.resolve(old: existing, new: factory)
        }
        
        self.asyncFactories[id] = factory
    }
}
