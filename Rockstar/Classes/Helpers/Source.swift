public struct SourceLocation {
    public let file: String
    public let line: UInt
    public let column: UInt
    public let function: String
    
    public init(file: String = #file, line: UInt = #line, column: UInt = #column, function: String = #function) {
        self.file = file
        self.line = line
        self.column = column
        
        self.function = function
    }
}