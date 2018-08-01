fileprivate extension String {
    private func padded(to charCount: Int, with character: Character = " ") -> String {
        return self + [Character](repeating: character, count: charCount - self.count)
    }
    
    static let fatal = "FATAL".padded(to: 5)
    static let error = "ERR".padded(to: 5)
    static let warning = "WARN".padded(to: 5)
    static let info = "INFO".padded(to: 5)
    static let debug = "DEBUG".padded(to: 5)
    static let verbose = "VERB".padded(to: 5)
}

fileprivate extension LogLevel {
    var shortCode: String {
        switch self {
        case .fatal: return .fatal
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        case .debug: return .debug
        case .verbose: return .verbose
        }
    }
}

public struct PrintLogger: LogDestination, Service {
    public var detailed = true
    
    public init() {}
    
    public func log(_ message: LogMessage<String>) {
        // These 2 prints statements are purposely separated even though they're similar. This is for performance and future-proofness
        if detailed {
            print("[\(message.level.shortCode)]: \(message.message) @ \(message.location.file) [line: \(message.location.line), column: \(message.location.column)]")
        } else {
            print("[\(message.level.shortCode)]: \(message.message) @ \(message.location.file)")
        }
    }
}
