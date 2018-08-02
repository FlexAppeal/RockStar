public struct ObservableValue<FutureValue> {
    public var value: FutureValue {
        didSet {
            writeStream.next(value)
        }
    }
    
    private let writeStream = WriteStream<FutureValue>()
    
    public var listener: ReadStream<FutureValue> {
         return writeStream.listener
    }
    
    public init(_ value: FutureValue) {
        self.value = value
    }
}
