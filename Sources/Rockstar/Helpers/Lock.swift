import Foundation

internal extension Optional where Wrapped == NSRecursiveLock {
    /// This helper will use the lock if it's available and otherwise directly run the function
    func withLock<T>(_ run: () throws -> T) rethrows -> T {
        switch self {
        case .none:
            return try run()
        case .some(let lock):
            lock.lock()
            defer { lock.unlock() }
            
            return try run()
        }
    }
}
