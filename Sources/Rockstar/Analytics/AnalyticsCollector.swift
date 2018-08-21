import Foundation

public final class Analytics {
    let writeStream = WriteStream<Measurement>()
    public let errorStream: ReadStream<Measurement>
    
    public static let `default` = Analytics()
    
    public var analyze = false
    
    public init() {
        self.errorStream = writeStream.listener
    }
    
    public func measureAsync<T>(
        location: SourceLocation,
        _ function: @autoclosure () throws -> (Future<T>)
    ) rethrows  -> Future<T> {
        if analyze {
            let start = Date()
            var success = true
            
            func log() {
                let end = Date()
                let check = Performance(start: start, end: end, successful: success)
                self.writeStream.next(Measurement(data: .performance(check), location: location))
            }
            
            do {
                return try function().onCompletion { observation in
                    if case .failure = observation {
                        success = false
                    }
                    
                    log()
                }
            } catch {
                success = false
                log()
                throw error
            }
        } else {
            return try function()
        }
    }
    
    public func measure<T>(
        location: SourceLocation,
        _ function: @autoclosure () throws -> (T)
    ) rethrows -> T {
        if analyze {
            let result: T
            let start = Date()
            var success = true
            
            defer {
                let end = Date()
                let check = Performance(start: start, end: end, successful: success)
                writeStream.next(Measurement(data: .performance(check), location: location))
            }
            
            do {
                return try function()
            } catch {
                success = false
                throw error
            }
        } else {
            return try function()
        }
    }
    
    public func assert(
        location: SourceLocation,
        check: @autoclosure () throws -> Bool,
        message: String = ""
    ) {
        if analyze {
            let success: Bool
            
            do {
                success = try check()
            } catch {
                success = false
            }
            
            let check = SanityCheck(isSane: success, message: message)
            writeStream.next(Measurement(data: .sanity(check), location: location))
        }
    }
}
