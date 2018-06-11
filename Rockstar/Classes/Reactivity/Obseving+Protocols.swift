/// Indirect so that futures nested in futures don't crash
public indirect enum Observation<FutureValue> {
    case success(FutureValue)
    case failure(Error)
}

public protocol PromiseProtocol {
    associatedtype FutureValue
    
    func fulfill(_ value: Observation<FutureValue>)
}

public protocol ObservationEmitter {
    associatedtype FutureValue
    
    func emit(_ value: Observation<FutureValue>)
}

public protocol ObserverProtocol {
    associatedtype FutureValue
    
    func onCompletion(_ run: @escaping (Observation<FutureValue>) -> ())
    func cancel()
}

extension Array where Element: ObserverProtocol {
    public func combined() -> Observer<[Element.FutureValue]> {
        var values = [Element.FutureValue]()
        var size = self.count
        values.reserveCapacity(size)
        let promise = Promise<[Element.FutureValue]>()
        
        for element in self {
            element.onCompletion { value in
                switch value {
                case .failure(let error):
                    promise.fail(error)
                case .success(let value):
                    /// TODO: Is this always a good idea?
                    for future in self {
                        future.cancel()
                    }
                    values.append(value)
                }
                
                size = size &- 1
                if size == 0 {
                    promise.complete(values)
                }
            }
        }
        
        return promise.future
    }
}
