extension Future: ExpressibleByIntegerLiteral where FutureValue == Int {
    public typealias IntegerLiteralType = Int
    
    public init(integerLiteral value: Int) {
        self.init(result: value)
    }
}

extension Future: ExpressibleByBooleanLiteral where FutureValue == Bool {
    public typealias BooleanLiteralType = Bool
    
    public init(booleanLiteral value: Bool) {
        self.init(result: value)
    }
}

extension Future where FutureValue == Void {
    public static var done: Future<Void> {
        return Future(result: ())
    }
}

extension Future: ExpressibleByArrayLiteral where FutureValue: ArrayInitializable {
    public typealias ArrayLiteralElement = FutureValue.Element
    
    public init(arrayLiteral elements: ArrayLiteralElement ...) {
        self.init(result: FutureValue(array: elements))
    }
}

extension Future: ExpressibleByNilLiteral where FutureValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(result: nil)
    }
}
