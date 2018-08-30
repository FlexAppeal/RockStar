public final class BindableCollection<Element>: Collection, ExpressibleByArrayLiteral {
    let storage: [Binding<Element>]
    
    public var startIndex: Int {
        return storage.startIndex
    }
    
    public var endIndex: Int {
        return storage.endIndex
    }
    
    public init(arrayLiteral elements: Element...) {
        self.storage = elements.map(Binding.init)
    }
    
    public init() {
        self.storage = []
    }
    
    public subscript(index: Int) -> Binding<Element> {
        return self.storage[index]
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
}
