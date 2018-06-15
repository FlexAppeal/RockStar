import SystemConfiguration

struct UnknownReachabilityError: Error {}

public final class ReachabilityNotifier {
    private let observer = Observer<NetworkStatus>()
    
    public var notifications: Observable<NetworkStatus> {
        return observer.observable
    }
    
    private let reachability: SCNetworkReachability
    private var context: SCNetworkReachabilityContext!
    
    public init(forHost host: String) throws {
        guard let currentReachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            throw UnknownReachabilityError()
        }
        
        reachability = currentReachability
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        guard SCNetworkReachabilitySetCallback(reachability, { reachability, flags, info in
            let notifier = Unmanaged<ReachabilityNotifier>.fromOpaque(info!).takeUnretainedValue()
            notifier.observer.next(NetworkStatus(reachability: reachability, flags: flags))
        }, &context) else {
            throw UnknownReachabilityError()
        }
        
        self.context = context
        
        try self.startEmitting()
    }
    
    private func startEmitting() throws {
    }
    
    private func callback(status: SCNetworkReachability, flags: SCNetworkReachabilityFlags, metadata: UnsafeMutableRawPointer?) {
        observer.next(NetworkStatus(reachability: status, flags: flags))
    }
}

public struct NetworkStatus {
    public let reachability: SCNetworkReachability
    public let flags: SCNetworkReachabilityFlags
}
