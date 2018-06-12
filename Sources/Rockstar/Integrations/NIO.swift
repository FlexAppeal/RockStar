/// FIXME: Implement

#if canImport(NIO)
import NIO

extension EventLoopFuture: ObserverProtocol {
    public func onCompletion(_ run: @escaping (Observation<T>) -> ()) -> Self {
        whenSuccess { result in
            run(.success(result))
        }
        whenFailure { error in
            run(.failure(error))
        }
        
        return self
    }
    
    public func cancel() {}
    
    public typealias FutureValue = T
}
#endif
