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
    public func register<S: AsyncService>(_ service: Observer<S>, substituting type: Any.Type) {
        self.register(AsyncSingleValueFactory(service: service), substituting: type)
    }
    
    public func register<S: AsyncService>(_ service: Observer<S>, substituting types: [Any.Type]) {
        self.register(AsyncSingleValueFactory(service: service), substituting: types)
    }
    
    public func register<Factory: AsyncServiceFactory>(_ factory: Factory, substituting type: Any.Type) {
        self.register(factory, substituting: [type])
    }
    
    public func register<Factory: AsyncServiceFactory>(_ factory: Factory, substituting types: [Any.Type]) {
        let ids = types.map(ObjectIdentifier.init)
        let factory = AnyAsyncServiceFactory(factory: factory)
        self.asyncFactories.append((factory, ids))
    }
}
