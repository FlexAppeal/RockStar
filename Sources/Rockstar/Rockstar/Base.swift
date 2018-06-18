public protocol AnyRockstar {
    associatedtype RockstarType
    
    var rockstar: Rockstar<RockstarType> { get }
}

public protocol BasicRockstar: AnyRockstar where RockstarType == Self {}

public extension BasicRockstar {
    var rockstar: Rockstar<RockstarType> {
        return Rockstar(wrapping: self)
    }
}

public final class Rockstar<Base> {
    public let base: Base
    
    public init(wrapping wrapped: Base) {
        self.base = wrapped
    }
}
