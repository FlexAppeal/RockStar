import Dispatch

public struct AnyThread {
    enum ThreadType {
        case dispatch(DispatchQueue)
    }
    
    private let thread: ThreadType
    
    public func execute(_ closure: @escaping () -> ()) {
        switch thread {
        case .dispatch(let queue):
            queue.async(execute: closure)
        }
    }
    
    public func execute(after timeout: RSTimeInterval, _ closure: @escaping () -> ()) {
        switch thread {
        case .dispatch(let queue):
            let deadline = DispatchTime.now() + timeout.dispatch
            
            queue.asyncAfter(deadline: deadline, execute: closure)
        }
    }
    
    public static func dispatchQueue(_ queue: DispatchQueue) -> AnyThread {
        return AnyThread(thread: .dispatch(queue))
    }
}
