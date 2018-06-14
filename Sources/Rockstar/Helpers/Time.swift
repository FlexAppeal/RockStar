import Foundation
import Dispatch

public struct RSTimeInterval {
    public let dispatch: DispatchTimeInterval
    
    public static func seconds(_ seconds: Int) -> RSTimeInterval {
        return .dispatch(.seconds(seconds))
    }
    
    public static func dispatch(_ interval: DispatchTimeInterval) -> RSTimeInterval {
        return RSTimeInterval(dispatch: interval)
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
