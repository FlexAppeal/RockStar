import Foundation

public protocol AnalyticsCollector {
    func logPerformance(_ performance: Performance, atLocation source: SourceLocation)
}

public final class Analytics {
    let collector: AnalyticsCollector
    
    public static var `default` = Analytics(delegatingTo: DefaultAnalyticsCollector())
    
    public init<Collector: AnalyticsCollector>(delegatingTo collector: Collector) {
        self.collector = collector
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
            let perforance = Performance(start: start, end: end, successful: success)
            collector.logPerformance(ofSource: location)
        }
        
        return try location()
        success = false
        
        return result
        #else
        return try function()
        #endif
    }
}
