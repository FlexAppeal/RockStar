import SystemConfiguration

struct UnknownReachabilityError: Error {}

public final class ReachabilityListener {
    private let observer = Observer<NetworkStatus>()
    
    public var notifications: Observable<NetworkStatus> {
        return observer.observable
    }
    
    private let reachability: SCNetworkReachability
    
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
            let notifier = Unmanaged<ReachabilityListener>.fromOpaque(info!).takeUnretainedValue()
            notifier.observer.next(NetworkStatus(reachability: reachability, flags: flags))
        }, &context) else {
            throw UnknownReachabilityError()
        }
    }
    
    private func callback(status: SCNetworkReachability, flags: SCNetworkReachabilityFlags, metadata: UnsafeMutableRawPointer?) {
        observer.next(NetworkStatus(reachability: status, flags: flags))
    }
    
    deinit {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
}

public struct NetworkStatus {
    public let reachability: SCNetworkReachability
    public let flags: SCNetworkReachabilityFlags
    
    public var requiresUserInteraction: Bool {
        return flags.contains(.interventionRequired)
    }
    
    public var canConnectAutomatically: Bool {
        return flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
    }
    
    public var isReachable: Bool {
        return flags.contains(.reachable) && (!flags.contains(.connectionRequired) || canConnectAutomatically && !requiresUserInteraction)
    }
}

extension SCNetworkReachabilityFlags {
    static let reachableFlags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired]
}
