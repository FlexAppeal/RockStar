import Rockstar

public final class RemoteValue<T> {
    public typealias LoadFunction = () -> Future<T>
    
    private enum State {
        case available(T)
        case preserved(T?, Future<T>)
        case error(Error)
        case unavailable
        case future(Future<T>)
    }
    
    private var state: State
    private let load: LoadFunction
    
    public var current: T? {
        switch state {
        case .available(let value):
            return value
        case .preserved(let value, _):
            return value
        default:
            return nil
        }
    }
    
    public var futureValue: Future<T> {
        switch state {
        case .available(let value):
            return Future(result: value)
        case .preserved(let current, _):
            if let current = current {
                return Future(result: current)
            } else {
                return reload(invalidatingCurrentValue: true)
            }
        case .error(let error):
            return Future(error: error)
        case .unavailable:
            return reload(invalidatingCurrentValue: true)
        case .future(let future):
            return future
        }
    }
    
    public init(source: @escaping LoadFunction, preload: Bool = true) {
        self.load = source
        
        if preload {
            let future = source()
            self.state = .future(future)
            
            future.then { value in
                self.state = .available(value)
                }.catch { error in
                    self.state = .error(error)
            }
        } else {
            self.state = .unavailable
        }
    }
    
    public func reload(invalidatingCurrentValue invalidate: Bool) -> Future<T> {
        let future = load()
        
        if invalidate {
            self.state = .future(future)
        } else {
            self.state = .preserved(self.current, future)
        }
        
        future.then { value in
            self.state = .available(value)
            }.catch { error in
                self.state = .error(error)
        }
        
        return future
    }
}
