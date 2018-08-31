extension Future: ExpressibleByIntegerLiteral where FutureValue: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = FutureValue.IntegerLiteralType
    
    /// Creates a precompleted future using the initializer of the `FutureValue` type's Integer literal initializer
    public init(integerLiteral value: FutureValue.IntegerLiteralType) {
        self.init(result: FutureValue(integerLiteral: value))
    }
}

extension Future: ExpressibleByBooleanLiteral where FutureValue == Bool {
    public typealias BooleanLiteralType = Bool
    
    public init(booleanLiteral value: Bool) {
        self.init(result: value)
    }
}

extension Binding: ExpressibleByIntegerLiteral where Bound: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Bound.IntegerLiteralType
    
    /// Creates a precompleted future using the initializer of the `FutureValue` type's Integer literal initializer
    public convenience init(integerLiteral value: Bound.IntegerLiteralType) {
        self.init(Bound(integerLiteral: value))
    }
}

extension Binding: ExpressibleByBooleanLiteral where Bound == Bool {
    public typealias BooleanLiteralType = Bool
    
    public convenience init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension Future where FutureValue == Void {
    /// Returns an precompleted `Future<Void>`
    public static var done: Future<Void> {
        return Future(result: ())
    }
}

extension Future: ExpressibleByArrayLiteral where FutureValue: _ArrayInitializable {
    public typealias ArrayLiteralElement = FutureValue.Element
    
    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(result: FutureValue(array: elements))
    }
}

extension Future: ExpressibleByNilLiteral where FutureValue: ExpressibleByNilLiteral {
    /// Creates a precompleted future using the initializer of the `FutureValue` type's nil literal initializer
    ///
    /// Particularly useful for futures that contain an optional and are known to contain a `nil` value
    ///
    ///     let user: Future<User?> = nil
    public init(nilLiteral: ()) {
        self.init(result: nil)
    }
}

public func +=<F: FixedWidthInteger>(lhs: Binding<F>, rhs: F) {
    return lhs.update(to: lhs.currentValue - rhs)
}

public func -=<F: FixedWidthInteger>(lhs: Binding<F>, rhs: F) {
    return lhs.update(to: lhs.currentValue - rhs)
}
