fileprivate extension String {
    static let defaultCrashMessage = "No resolution was specified for conflicting services"
}

public final class ServiceBuilder {
    public let environment: Environment
    var syncFactories = [ObjectIdentifier: AnyServiceFactory]()
    var asyncFactories = [ObjectIdentifier: AnyAsyncServiceFactory]()
    public var syncResolution = ServiceResolution<AnyServiceFactory>.crash(.defaultCrashMessage)
    public var asyncResolution = ServiceResolution<AnyAsyncServiceFactory>.crash(.defaultCrashMessage)
    
    public init(environment: Environment) {
        self.environment = environment
    }
    
    public func forEnvironment(_ environment: Environment, run: () throws -> ()) rethrows {
        if self.environment == environment {
            try run()
        }
    }
    
    public func forEnvironments(_ environments: Environment..., run: () throws -> ()) rethrows {
        for environment in environments {
            if self.environment == environment {
                try run()
                return
            }
        }
    }
    
    public func forEnvironments(_ environments: Set<Environment>, run: () throws -> ()) rethrows {
        for environment in environments {
            if self.environment == environment {
                try run()
                return
            }
        }
    }
    
    public func finalize() -> Services {
        return Services(sync: self.syncFactories, async: self.asyncFactories)
    }
}

public enum ServiceResolution<Value> {
    public typealias CustomResolution = (Value, Value) -> Value
    
    case crash(String)
    case newest
    case oldest
    case custom(CustomResolution)
    
    func resolve(old: Value, new: Value) -> Value {
        switch self {
        case .crash(let message):
            fatalError(message)
        case .newest:
            return new
        case .oldest:
            return old
        case .custom(let resolution):
            return resolution(old, new)
        }
    }
}

struct ServiceNotFound: Error {}

public struct Services {
    public private(set) static var `default`: Services = {
        let builder = ServiceBuilder(environment: .automatic())
        
        var coderRegistery = CoderRegistery()
        coderRegistery.register(JSONEncoder())
        coderRegistery.register(JSONDecoder())
        
        builder.register(coderRegistery, substituting: CoderRegistery.self)
        builder.register(URLSessionConfiguration.default, substituting: URLSessionConfiguration.self)
        
        builder.register(substitutionFor: URLSession.self) { services in
            return try URLSession(configuration: services.make())
        }
        
        builder.register(substitutionFor: HTTPClient.self) { services in
            return try URLSession(configuration: services.make())
        }
        
        return builder.finalize()
    }()
    
    fileprivate var sync: [ObjectIdentifier: AnyServiceFactory]
    fileprivate var async: [ObjectIdentifier: AnyAsyncServiceFactory]
    
    public func make<Result>(_ type: Result.Type = Result.self) throws -> Result {
        guard let factory = self.sync[ObjectIdentifier(type)] else {
            throw ServiceNotFound()
        }
        
        return try factory.make(from: self) as! Result
    }
    
    public func makeAsync<Result>(_ type: Result.Type = Result.self) -> Future<Result> {
        guard let factory = self.async[ObjectIdentifier(type)] else {
            return Future(error: ServiceNotFound())
        }
        
        return factory.make(from: self).map { $0 as! Result }
    }
    
    public func makeDefault() {
        Services.default = self
    }
}
