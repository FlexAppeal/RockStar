fileprivate extension String {
    static let defaultCrashMessage = "No resolution was specified for conflicting services"
}

public final class ServiceBuilder {
    public let environment: Environment
    var syncFactories = [(AnyServiceFactory, [ObjectIdentifier])]()
    var asyncFactories = [(AnyAsyncServiceFactory, [ObjectIdentifier])]()
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
        var services = Services()
        
        for (factory, ids) in syncFactories {
            services.sync.append(factory, forKeys: ids, resolution: syncResolution)
        }
        
        for (factory, ids) in asyncFactories {
            services.async.append(factory, forKeys: ids, resolution: asyncResolution)
        }
        
        return services
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

fileprivate extension Dictionary where Key == ObjectIdentifier {
    mutating func append(_ value: Value, forKeys newKeys: [Key], resolution: ServiceResolution<Value>) {
        for key in newKeys {
            if let old = self[key] {
                self[key] = resolution.resolve(old: old, new: value)
            } else {
                self[key] = value
            }
        }
    }
}

public struct Services {
    fileprivate var sync = [ObjectIdentifier: AnyServiceFactory]()
    fileprivate var async = [ObjectIdentifier: AnyAsyncServiceFactory]()
}
