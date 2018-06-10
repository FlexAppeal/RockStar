import Foundation

fileprivate extension String {
    static let defaultCollector = "_rockstar_defaultcollector"
}

final class DefaultAnalyticsThreadCollector: AnalyticsCollector {
    var measurements = [Measurement]()
    
    init() {}
    
    func logPerformance(_ performance: Performance, atLocation source: SourceLocation) {
        measurements.append(.performance(performance, at: source))
    }
    
    func generateReport() {
        print(measurements)
    }
    
    deinit {
        generateReport()
    }
}

final class DefaultAnalyticsCollector: AnalyticsCollector {
    init() {}
    
    var collectors = [DefaultAnalyticsThreadCollector]()
    
    func logPerformance(_ performance: Performance, atLocation source: SourceLocation) {
        withThreadCollector { collector in
            collector.logPerformance(performance, atLocation: source)
        }
    }
    
    private func withThreadCollector<T>(run: (DefaultAnalyticsThreadCollector) throws -> T) rethrows -> T {
        let threadCollector: DefaultAnalyticsThreadCollector
        
        if let subCollector = Thread.current.threadDictionary.value(forKey: .defaultCollector) as? DefaultAnalyticsThreadCollector {
            threadCollector = subCollector
        } else {
            threadCollector = DefaultAnalyticsThreadCollector()
            Thread.current.threadDictionary.setValue(threadCollector, forKey: .defaultCollector)
            self.collectors.append(threadCollector)
        }
        
        return try run(threadCollector)
    }
    
    /// Ironically, this is not thread safe although it accesses many threads.
    /// Call this when no other logging is happening such as at the application lifecycle end
    func generateReport() {
        for collector in collectors {
            collector.generateReport()
        }
    }
}
