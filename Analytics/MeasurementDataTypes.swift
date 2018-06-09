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

public enum Measurement {
    case performance(Performance, at: SourceLocation)
}
