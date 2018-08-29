internal final class BindChangeContext<Bound> {
    let value: Bound
    var previousHandlers = Set<ObjectIdentifier>()
    
    init(value: Bound, initiator: _AnyBinding<Bound>) {
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
    weak var binding: _AnyBinding<Bound>?
    let id: ObjectIdentifier
    
    init(binding: _AnyBinding<Bound>) {
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

public class _AnyBinding<Bound> {
    internal var bound: Bound {
        didSet {
            writeStream.next(bound)
            
            if cascades.count > 0 {
                _ = BindChangeContext<Bound>(value: bound, initiator: self)
            }
        }
    }
    
    private let writeStream = WriteStream<Bound>()
    
    public var readStream: ReadStream<Bound> {
        return writeStream.listener
    }
    
    var cascades = Set<CascadedBind<Bound>>()
    
    internal init(bound: Bound) {
        self.bound = bound
    }
    
    public func update(to value: Bound) {
        self.bound = value
    }
    
    public func bind(to binding: _AnyBinding<Bound>, bidirectionally: Bool = false) {
        binding.update(to: self.bound)
        
        self.cascades.insert(CascadedBind(binding: binding))
        
        if bidirectionally {
            binding.bind(to: self)
        }
    }
    
    public func bind<C: AnyObject>(to object: C, atKeyPath path: WritableKeyPath<C, Bound>) {
        weak var object = object
        
        func update(to currentvalue: Bound) {
            object?[keyPath: path] = bound
        }
        
        object?[keyPath: path] = self.bound
        _ = self.readStream.then(update)
    }
}

public final class Binding<Bound>: _AnyBinding<Bound> {
    public private(set) var currentValue: Bound {
        get {
            return bound
        }
        set {
            bound = newValue
        }
    }
    
    public init(_ value: Bound) {
        super.init(bound: value)
    }
}

public final class ComputedBinding<Bound>: _AnyBinding<Bound> {
    public private(set) var currentValue: Bound {
        get {
            return bound
        }
        set {
            bound = newValue
        }
    }
    
    internal init(_ value: Bound) {
        super.init(bound: value)
    }
}

// TODO: Make binding codable where the contained value is codable
extension Binding {
    /// TODO: -> ComputedBinding which can not be mutated
    public func map<T>(_ mapper: @escaping (Bound) -> T) -> ComputedBinding<T> {
        let binding = ComputedBinding<T>(mapper(currentValue))
        
        _ = self.readStream.map(mapper).then(binding.update)
        
        return binding
    }
}
