import Foundation

public final class Analytics {
    let observer = Observer<Measurement>()
    public let observable: Observable<Measurement>
    
    public static let `default` = Analytics()
    
    public init() {
        self.observable = observer.observable
    }
    
    public func measure<T>(
        location: SourceLocation = SourceLocation(),
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
        location: SourceLocation = SourceLocation(),
        check: @autoclosure () throws -> Bool
    ) {
        #if ANALYZE
        let success = try? check() == true
        let check = SanityCheck(isSane: success)
        observable.next(Measurement(data: .sanity(check), location: location))
        #endif
    }
}