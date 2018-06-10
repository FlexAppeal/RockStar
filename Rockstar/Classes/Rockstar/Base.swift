public protocol AnyRockstar {
    associatedtype RockstarType
    
    /// For deinitializing the Rockstar, make `RockstarMetadata` a class with a `deinit` function
    associatedtype RockstarMetadata
    
    var rockstar: Rockstar<RockstarType, RockstarMetadata> { get }
    static var defaultMetadata: RockstarMetadata { get }
}

public protocol BasicRockstar: AnyRockstar where RockstarType == Self {}

public extension BasicRockstar {
    var rockstar: Rockstar<RockstarType, RockstarMetadata> {
        return Rockstar(wrapping: self, metadata: Self.defaultMetadata)
    }
}

public protocol RockstarRepresentable: AnyRockstar {
    static var defaultMetadata: RockstarMetadata { get }
}

public struct Rockstar<Base, Metadata> {
    public var base: Base
    public var metadata: Metadata
    
    public init(wrapping wrapped: Base, metadata: Metadata) {
        self.base = wrapped
        self.metadata = metadata
    }
}
