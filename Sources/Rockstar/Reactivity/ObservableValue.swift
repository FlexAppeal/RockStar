public struct ObservableValue<FutureValue> {
    public var value: FutureValue {
        didSet {
            writeStream.next(value)
        }
    }
    
    private let writeStream = InputStream<FutureValue>()
    
    public var listener: OutputStream<FutureValue> {
         return writeStream.listener
    }
    
    public init(_ value: FutureValue) {
        self.value = value
    }
}
