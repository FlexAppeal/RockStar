import Dispatch

/// A type-erasing wrapper around a thread's core functionalities
///
/// Currently only supports DispatchQueue, but this will also support NIO, pThread and Foundation Thread
public struct AnyThread {
    enum ThreadType {
        case dispatch(DispatchQueue)
    }
    
    private let thread: ThreadType
    
    /// Executes a closure after changing to this thread
    public func execute(_ closure: @escaping () -> ()) {
        switch thread {
        case .dispatch(let queue):
            queue.async(execute: closure)
        }
    }
    
    /// Executes a closure after changing to this thread with a specified delay
    public func execute(after timeout: RSTimeInterval, _ closure: @escaping () -> ()) {
        switch thread {
        case .dispatch(let queue):
            let deadline = DispatchTime.now() + timeout.dispatch
            
            queue.asyncAfter(deadline: deadline, execute: closure)
        }
    }
    
    /// Creates a thread based on a DispatchQueue
    ///
    /// You can use shorthands such as `AnyThread.dispatchQueue(.main)` for the main DispatchQueue
    public static func dispatchQueue(_ queue: DispatchQueue) -> AnyThread {
        return AnyThread(thread: .dispatch(queue))
    }
}
