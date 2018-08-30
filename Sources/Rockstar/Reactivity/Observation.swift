import Foundation

/// Indirect so that futures nested in futures don't crash
public indirect enum Observation<FutureValue> {
    /// A successful stream/future result
    case success(FutureValue)
    
    /// An error
    case failure(Error)
    
    // TODO: Work around this with a helper struct `Cancellable<Void>`?
    
    /// The request for information was cancelled
    ///
    /// No further (un-)successful data will be emitted
    case cancelled
}

public typealias CancelAction = ()->()
typealias FutureCallback<T> = (Observation<T>) -> ()
