import Foundation
import Dispatch

public struct RSTimeInterval {
    public var nanoseconds: Int? {
        switch dispatch {
        case .seconds(let s):
            return s * 1_000_000_000
        case .milliseconds(let ms):
            return ms * 1_000_000
        case .microseconds(let ms):
            return ms * 1_000
        case .nanoseconds(let ns):
            return ns
        case .never:
            return nil
        }
    }
    
    public var milliseconds: Int? {
        switch dispatch {
        case .seconds(let s):
            return s * 1_000
        case .milliseconds(let ms):
            return ms
        case .microseconds(let ms):
            return ms / 1_000
        case .nanoseconds(let ns):
            return ns / 1_000_000
        case .never:
            return nil
        }
    }
    
    public let dispatch: DispatchTimeInterval
    
    public static func seconds(_ seconds: Int) -> RSTimeInterval {
        return RSTimeInterval(dispatch: .seconds(seconds))
    }
    
    public static func milliseconds(_ ms: Int) -> RSTimeInterval {
        return RSTimeInterval(dispatch: .milliseconds(ms))
    }
    
    public static func microseconds(_ ms: Int) -> RSTimeInterval {
        return RSTimeInterval(dispatch: .microseconds(ms))
    }
    
    public static func nanoseconds(_ ns: Int) -> RSTimeInterval {
        return RSTimeInterval(dispatch: .nanoseconds(ns))
    }
    
    public static func seconds(_ seconds: Double) -> RSTimeInterval {
        return .milliseconds(Int(seconds * 1000)) // Don't trust more precision
    }
    
    public static func dispatch(_ interval: DispatchTimeInterval) -> RSTimeInterval {
        switch interval {
        case .seconds(let s):
            return .milliseconds(s * 1_000)
        case .milliseconds(let ms):
            return .milliseconds(ms)
        case .microseconds(let ms):
            return .nanoseconds(ms * 1_000)
        case .nanoseconds(let ns):
            return .nanoseconds(ns)
        case .never:
            return .nanoseconds(.max)
        }
    }
}

public struct RSTimeout {
    public var timeout: RSTimeInterval
    public var thread: AnyThread
    
    public init(after timeout: RSTimeInterval, onThread thread: AnyThread) {
        self.timeout = timeout
        self.thread = thread
    }
    
    public func execute(_ closure: @escaping () -> ()) {
        thread.execute(after: timeout, closure)
    }
}
