public struct MediaType: ExpressibleByStringLiteral {
    public let type: String
    public let subType: String
    
    public init(type: String, subType: String) {
        self.type = type
        self.subType = subType
        
        let fullType = "\(type)/\(subType)"
        
        if !MediaType.registery.keys.contains(fullType) {
            MediaType.registery[fullType] = self
        }
    }
    
    public init(stringLiteral value: String) {
        let values = value.split(separator: "/", maxSplits: 1)
        
        self.init(type: String(values[0]), subType: String(values[1]))
    }
    
    public private(set) static var registery = [String: MediaType]()
}

public protocol Content: Codable {
    static var defaultContentType: MediaType { get }
}
