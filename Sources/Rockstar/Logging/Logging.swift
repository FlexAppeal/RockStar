public protocol LogDestination {
    func log(_ message: LogMessage<String>)
}

public protocol CodableLogDestination {
    func log<E: Encodable>(_ message: LogMessage<E>)
}

public enum LogLevel: String, Codable {
    case fatal, error, warning, info, debug, verbose
}

public struct LogMessage<E: Encodable> {
    public let level: LogLevel
    public let message: E
    public let location: SourceLocation
    
    init(level: LogLevel, message: E, location: SourceLocation = SourceLocation()) {
        self.level = level
        self.message = message
        self.location = location
    }
}

public extension LogDestination {
    /// Enabled by compiling with the `LOGVERBOSE` compilation flag
    ///
    /// Also included in the `LOGDEBUG` and `LOGALL` compilation flags
    @inline(__always)
    func verbose(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGVERBOSE || LOGDEBUG || LOGALL
        self.log(LogMessage(level: .verbose, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGDEBUG` compilation flag
    ///
    /// Also included in the `LOGALL` compilation flag
    @inline(__always)
    func debug(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGDEBUG || LOGALL
        self.log(LogMessage(level: .debug, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGINFO` compilation flag
    ///
    /// Also included in the `LOGALL` compilation flag
    @inline(__always)
    func info(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGINFO || LOGALL
        self.log(LogMessage(level: .info, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGWARNING` compilation flag
    ///
    /// Also included in the `LOGERROR`, `LOGFATAL` and `LOGALL` flags
    @inline(__always)
    func warning(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGWARNING || LOGERROR || LOGFATAL || LOGALL
        self.log(LogMessage(level: .warning, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGERROR` compilation flag
    ///
    /// Also included in the `LOGALL` flag
    @inline(__always)
    func error(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGERROR || LOGALL
        self.log(LogMessage(level: .error, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGFATAL` compilation flag
    ///
    /// Also included in the `LOGERROR` and `LOGALL` flags
    @inline(__always)
    func fatal(_ message: @autoclosure () -> (String), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGERROR || LOGFATAL || LOGALL
        self.log(LogMessage(level: .fatal, message: message()))
        #endif
    }
}

public extension CodableLogDestination {
    /// Enabled by compiling with the `LOGVERBOSE` compilation flag
    ///
    /// Also included in the `LOGDEBUG` and `LOGALL` compilation flags
    @inline(__always)
    func verbose<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGVERBOSE || LOGDEBUG || LOGALL
        self.log(LogMessage(level: .verbose, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGDEBUG` compilation flag
    ///
    /// Also included in the `LOGALL` compilation flag
    @inline(__always)
    func debug<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGDEBUG || LOGALL
        self.log(LogMessage(level: .debug, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGINFO` compilation flag
    ///
    /// Also included in the `LOGALL` compilation flag
    @inline(__always)
    func info<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGINFO || LOGALL
        self.log(LogMessage(level: .info, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGWARNING` compilation flag
    ///
    /// Also included in the `LOGERROR`, `LOGFATAL` and `LOGALL` flags
    @inline(__always)
    func warning<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGWARNING || LOGERROR || LOGFATAL || LOGALL
        self.log(LogMessage(level: .warning, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGERROR` compilation flag
    ///
    /// Also included in the `LOGALL` flag
    @inline(__always)
    func error<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGERROR || LOGALL
        self.log(LogMessage(level: .error, message: message()))
        #endif
    }
    
    /// Enabled by compiling with the `LOGFATAL` compilation flag
    ///
    /// Also included in the `LOGERROR` and `LOGALL` flags
    @inline(__always)
    func fatal<E: Encodable>(_ message: @autoclosure () -> (E), file: String = #file, line: UInt = #line, function: String = #function) {
        #if LOGERROR || LOGFATAL || LOGALL
        self.log(LogMessage(level: .fatal, message: message()))
        #endif
    }
}
