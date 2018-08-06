import Foundation

/// Indirect so that futures nested in futures don't crash
public indirect enum Observation<FutureValue> {
    case success(FutureValue)
    case failure(Error)
    
    /// FIXME: Work around this with a helper struct `Cancellable<Void>`
    case cancelled
}

public typealias CancelAction = ()->()
typealias FutureCallback<T> = (Observation<T>) -> ()
