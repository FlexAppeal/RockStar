import Foundation

public final class Analytics {
    let writeStream = WriteStream<Measurement>()
    public let observable: ReadStream<Measurement>
    
    public static let `default` = Analytics()
    
    public init() {
        self.observable = writeStream.listener
    }
    
    public func measure<T>(
        location: SourceLocation,
        _ function: @autoclosure () throws -> (T)
    ) rethrows -> T {
        #if ANALYZE
        let result: T
        let start = Date()
        let success = true
        
        defer {
            let end = Date()
            let check = Performance(start: start, end: end, successful: success)
            observable.next(Measurement(data: .performance(check), location: location))
        }
        
        return try location()
        success = false
        
        return result
        #else
        return try function()
        #endif
    }
    
    public func assert(
        location: SourceLocation,
        check: @autoclosure () throws -> Bool,
        message: String = ""
    ) {
        #if ANALYZE
        let success = try? check() == true
        let check = SanityCheck(isSane: success, message: message)
        observable.next(Measurement(data: .sanity(check), location: location))
        #endif
    }
}
