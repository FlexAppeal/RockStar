internal final class BindChangeContext<Bound> {
    let value: Bound
    var previousHandlers = Set<ObjectIdentifier>()
    
    init(value: Bound, initiator: Binding<Bound>) {
        self.value = value
        
        for next in initiator.cascades {
            cascade(for: next)
        }
    }
    
    private func cascade(for cascade: CascadedBind<Bound>) {
        guard !self.previousHandlers.contains(cascade.id) else { return }
        
        if let binding = cascade.binding {
            self.previousHandlers.insert(cascade.id)
            
            binding.update(to: value)
            
            for next in binding.cascades {
                self.cascade(for: next)
            }
        }
    }
}

struct CascadedBind<Bound>: Hashable {
    weak var binding: Binding<Bound>?
    let id: ObjectIdentifier
    
    init(binding: Binding<Bound>) {
        self.id = ObjectIdentifier(binding)
        self.binding = binding
    }
    
    var hashValue: Int {
        return id.hashValue
    }
    
    static func ==(lhs: CascadedBind<Bound>, rhs: CascadedBind<Bound>) -> Bool {
        return lhs.id == rhs.id
    }
}

public final class Binding<Bound> {
    public var currentValue: Bound {
        didSet {
            writeStream.next(currentValue)
            
            if cascades.count > 0 {
                _ = BindChangeContext<Bound>(value: currentValue, initiator: self)
            }
        }
    }
    
    fileprivate var cascades = Set<CascadedBind<Bound>>()
    
    public init(_ value: Bound) {
        self.currentValue = value
    }
    
    public func update(to value: Bound) {
        self.currentValue = value
    }
    
    private let writeStream = WriteStream<Bound>()
    
    public var readStream: ReadStream<Bound> {
        return writeStream.listener
    }
    
    public func bind(to binding: Binding<Bound>, bidirectionally: Bool = false) {
        binding.update(to: self.currentValue)
        
        self.cascades.insert(CascadedBind(binding: binding))
        
        if bidirectionally {
            binding.bind(to: self)
        }
    }
    
    public func bind<C: AnyObject>(to object: C, atKeyPath path: WritableKeyPath<C, Bound>) {
        weak var object = object
        
        func update(to currentvalue: Bound) {
            object?[keyPath: path] = currentValue
        }
        
        object?[keyPath: path] = self.currentValue
        _ = self.readStream.then(update)
    }
}

extension Binding {
    public func map<T>(_ mapper: @escaping (Bound) -> T) -> Binding<T> {
        let binding = Binding<T>(mapper(currentValue))
        
        _ = self.readStream.map(mapper).then(binding.update)
        
        return binding
    }
}
