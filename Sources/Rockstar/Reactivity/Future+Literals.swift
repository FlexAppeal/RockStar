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
    
    public func `if`(_ literal: Bool, run: @escaping () -> ()) -> Future<Bool> {
        return self.then { value in
            if value == literal {
                run()
            }
        }
    }
}

extension Future where FutureValue == Void {
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
    public init(nilLiteral: ()) {
        self.init(result: nil)
    }
}

extension Future {
    public func ifNil<B>(run: @escaping () -> ()) -> Future<FutureValue> where FutureValue == Optional<B> {
        return self.then { value in
            if value == nil {
                run()
            }
        }
    }
    
    public func ifNotNil<B>(run: @escaping (B) -> ()) -> Future<FutureValue> where FutureValue == Optional<B> {
        return self.then { value in
            if let value = value {
                run(value)
            }
        }
    }
    
    public func assertNotNil<B>() -> Future<B> where FutureValue == Optional<B> {
        return self.map { value in
            guard let value = value else {
                throw ValueUnwrappedNil()
            }
            
            return value
        }
    }
}

struct ValueUnwrappedNil: RockstarError {
    var location = SourceLocation()
}
