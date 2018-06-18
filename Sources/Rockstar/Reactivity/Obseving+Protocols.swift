/// Indirect so that futures nested in futures don't crash
public indirect enum Observation<FutureValue> {
    case success(FutureValue)
    case failure(Error)
    case cancelled
}

public typealias CancelAction = ()->()
typealias FutureCallback<T> = (Observation<T>) -> ()
