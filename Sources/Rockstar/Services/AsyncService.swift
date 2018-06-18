public protocol AsyncServiceFactory {
    associatedtype Result: AsyncService
    
    func make(from services: Services) -> Future<Result>
}

public protocol AsyncService {}

struct AsyncSingleValueFactory<Result: AsyncService>: AsyncServiceFactory {
    let service: Future<Result>
    
    init(service: Future<Result>) {
        self.service = service
    }
    
    func make(from services: Services) -> Future<Result> {
        return service
    }
}

struct AnyAsyncClosureFactory<Result: AsyncService>: AsyncServiceFactory {
    typealias Closure = (Services) -> Future<Result>
    let factory: Closure
    
    init(factory: @escaping Closure) {
        self.factory = factory
    }
    
    func make(from services: Services) -> Future<Result> {
        return factory(services)
    }
}

public struct AnyAsyncServiceFactory {
    let identifier: ObjectIdentifier
    private let factoryMethod: (Services) throws -> Future<Any>
    
    init<Factory: AsyncServiceFactory>(factory: Factory) {
        self.identifier = ObjectIdentifier(Factory.Result.self)
        self.factoryMethod = { services in
            return factory.make(from: services).map { $0 as Any }
        }
    }
    
    public func make(from services: Services) -> Future<Any> {
        do {
            return try factoryMethod(services)
        } catch {
            return Future<Any>(error: error)
        }
    }
}

extension ServiceBuilder {
    public typealias AsyncClosureFactory<S: AsyncService> = (Services) -> Future<S>
    
    public func register<S: AsyncService, Result>(_ service: Future<S>, substituting type: Result.Type) {
        assert(S.self is Result, "The registered service does not match the resulting type")
        
        self.register(AsyncSingleValueFactory(service: service), substituting: type)
    }
    
    public func register<S: AsyncService, Result>(
        substitutionFor type: Result.Type,
        _ factory: @escaping AsyncClosureFactory<S>
    ) {
        assert(S.self is Result, "The registered service does not match the resulting type")
        
        self.register(AnyAsyncClosureFactory(factory: factory), substituting: type)
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
