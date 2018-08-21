public protocol LogDestination {
    func log(_ message: @autoclosure () -> (LogMessage<String>))
}

public protocol CodableLogDestination {
    func log<E: Encodable>(_ message: @autoclosure () -> (LogMessage<E>))
}

public enum LogLevel: String, Codable, Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.severity < rhs.severity
    }
    
    case fatal, error, warning, info, debug, verbose
    
    var severity: Int {
        switch self {
        case .fatal:
            return 5
        case .error:
            return 4
        case .warning:
            return 3
        case .info:
            return 2
        case .debug:
            return 1
        case .verbose:
            return 0
        }
    }
}

public struct LogMessage<E: Encodable> {
    public let level: LogLevel
    public let message: E
    public let location: SourceLocation
    
    public init(level: LogLevel, message: E, location: SourceLocation = SourceLocation()) {
        self.level = level
        self.message = message
        self.location = location
    }
}

public extension LogDestination {
    @inline(__always)
    func verbose(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .verbose, message: message()))
    }
    
    @inline(__always)
    func debug(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .debug, message: message()))
    }
    
    @inline(__always)
    func info(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .info, message: message()))
    }
    
    @inline(__always)
    func warning(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .warning, message: message()))
    }
    
    @inline(__always)
    func error(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .error, message: message()))
    }
    
    @inline(__always)
    func fatal(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .fatal, message: message()))
    }
}

public extension CodableLogDestination {
    @inline(__always)
    func verbose<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .verbose, message: message()))
    }
    
    @inline(__always)
    func debug<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .debug, message: message()))
    }
    
    @inline(__always)
    func info<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .info, message: message()))
    }
    
    @inline(__always)
    func warning<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .warning, message: message()))
    }
    
    @inline(__always)
    func error<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .error, message: message()))
    }
    
    @inline(__always)
    func fatal<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        self.log(LogMessage(level: .fatal, message: message()))
    }
}
