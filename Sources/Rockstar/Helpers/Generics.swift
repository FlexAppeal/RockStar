public protocol _ArrayInitializable {
    associatedtype Element
    
    init(array: [Element])
}

extension Array: _ArrayInitializable {
    public init(array: [Element]) {
        self = array
    }
}

extension Set: _ArrayInitializable {
    public init(array: [Element]) {
        self = Set(array)
    }
}
