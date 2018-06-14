/// Indirect so that futures nested in futures don't crash
public indirect enum Observation<FutureValue> {
    case success(FutureValue)
    case failure(Error)
    case cancelled
}

public protocol PromiseProtocol {
    associatedtype FutureValue
    
    func fulfill(_ value: Observation<FutureValue>)
}

public protocol ObservationEmitter {
    associatedtype FutureValue
    
    func emit(_ value: Observation<FutureValue>)
}

public protocol ObservableProtocol {
    associatedtype FutureValue
    
    @discardableResult
    func onCompletion(_ run: @escaping (Observation<FutureValue>) -> ()) -> Self
    func cancel()
}
