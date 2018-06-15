public protocol ArrayInitializable {
    associatedtype Element
    
    init(array: [Element])
}

extension Array: ArrayInitializable {
    public init(array: [Element]) {
        self = array
    }
}

extension Set: ArrayInitializable {
    public init(array: [Element]) {
        self = Set(array)
    }
}
