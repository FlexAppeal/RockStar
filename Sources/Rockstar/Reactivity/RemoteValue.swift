/// An internally used enum to keep the `ExternalValue` state.
fileprivate enum ExternalState<T> {
    case available(T)
    case preserved(T?, Future<T>)
    case error(Error)
    case unavailable
    case future(Future<T>)
}

/// A value that is linked to the result of a function call such as an API call
/// where the result is not readily available.
public class ExternalValue<T>: AnyBinding<T?> {
    public typealias LoadFunction = () -> Future<T>
    
    fileprivate var state: ExternalState<T>
    private let load: LoadFunction
    
    /// Should only be used if you're explicitly interested in the value _now_
    ///
    /// Does not guarantee that the value has attempted to load yet
    public var current: T? {
        switch state {
        case .available(let value):
            return value
        case .preserved(let value, _):
            return value
        case .unavailable:
            _ = reload(invalidating: true)
            return nil
        default:
            return nil
        }
    }
    
    /// If the value is readily available, the Future will be precompleted with this result.
    ///
    /// Otherwise, the future will receive the (un-)successful value based on the function call's results
    public var futureValue: Future<T> {
        switch state {
        case .available(let value):
            return Future(result: value)
        case .preserved(let current, let future):
            if let current = current {
                return Future(result: current)
            } else {
                return future
            }
        case .error(let error):
            return Future(error: error)
        case .unavailable:
            return reload(invalidating: true)
        case .future(let future):
            return future
        }
    }
    
    /// Creates a new ExternalValue which fetches the value from the
    public init(source: @escaping LoadFunction, preload: Bool = true, threadSafe: Bool = RockstarConfig.threadSafeBindings) {
        self.load = source
        
        if preload {
            let future = source()
            self.state = .future(future)
            
            super.init(bound: nil, threadSafe: threadSafe)
            
            future.then { value in
                self.state = .available(value)
                self.update(to: value)
            }.catch { error in
                self.state = .error(error)
                self.update(to: nil)
            }.onCancel {
                self.update(to: nil)
            }
        } else {
            self.state = .unavailable
            
            super.init(bound: nil, threadSafe: threadSafe)
        }
    }
    
    /// Reloads the local value. Allows invalidation of the local value so that the currently
    /// present value is released and a new value is required.
    public func reload(invalidating invalidate: Bool) -> Future<T> {
        let future = load()
        
        if invalidate {
            self.state = .future(future)
        } else {
            self.state = .preserved(self.current, future)
        }
        
        future.then { value in
            self.state = .available(value)
            self.update(to: value)
        }.catch { error in
            self.state = .error(error)
            self.update(to: nil)
        }.onCancel {
            self.update(to: nil)
        }
        
        return future
    }
}

/// An ExternalValue of which yo can override the `current` state to circumvent needless API calls
public final class MutableExternalValue<T>: ExternalValue<T> {
    public override var current: T? {
        get {
            return super.current
        }
        set {
            if let value = newValue {
                self.state = .available(value)
            } else {
                self.state = .unavailable
            }
            
            self.writeStream.next(newValue)
        }
    }
}
