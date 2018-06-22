import Foundation

public struct Performance {
    internal let start: Date
    internal let end: Date
    internal let successful: Bool
    
    internal init(start: Date, end: Date, successful: Bool) {
        self.start = start
        self.end = end
        self.successful = successful
    }
}

public struct SanityCheck {
    public let isSane: Bool
    public let message: String
}

public struct Measurement {
    public enum MeasurementData {
        case performance(Performance)
        case sanity(SanityCheck)
    }
    
    public let data: MeasurementData
    public let location: SourceLocation
}
