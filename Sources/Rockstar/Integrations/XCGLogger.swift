#if canImport(XCGLogger)
import XCGLogger

extension LogLevel {
    public var xcg: XCGLogger.LEvel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .severe
        }
    }
}

extension LogMessage where E == String {
    public var xcg: LogDetails {
        return LogDetails(
            level: self.level.xcg,
            date: Date(),
            message: self.message,
            functionName: location.function,
            fileName: location.file,
            lineNumber: location.line
        )
    }
}
#endif
