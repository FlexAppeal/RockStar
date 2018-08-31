import Foundation
import Dispatch

public struct RSTimeInterval {
    public internal(set) var nanoseconds: Int
    
    public var dispatch: DispatchTimeInterval {
        return DispatchTimeInterval.nanoseconds(nanoseconds)
    }
    
    public static func seconds(_ seconds: Int) -> RSTimeInterval {
        return .milliseconds(seconds * 1_000_000_000)
    }
    
    public static func milliseconds(_ ms: Int) -> RSTimeInterval {
        return .milliseconds(ms * 1_000_000)
    }
    
    public static func microseconds(_ ms: Int) -> RSTimeInterval {
        return .milliseconds(ms * 1_000)
    }
    
    public static func nanoseconds(_ ns: Int) -> RSTimeInterval {
        return RSTimeInterval(nanoseconds: ns)
    }
    
    public static func seconds(_ seconds: Double) -> RSTimeInterval {
        return .milliseconds(Int(seconds * 1000)) // Don't trust more precision
    }
    
    public static func dispatch(_ interval: DispatchTimeInterval) -> RSTimeInterval {
        switch interval {
        case .seconds(let s):
            return .nanoseconds(s * 1_000_000_000)
        case .milliseconds(let ms):
            return .nanoseconds(ms * 1_000_000)
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
