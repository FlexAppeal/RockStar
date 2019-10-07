import Foundation

extension AnyBinding: Encodable where Bound: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = try encoder.singleValueContainer()
        try container.encode(bound)
    }
}

extension Binding: Decodable where Bound: Decodable {
    public convenience init(from decoder: Decoder) throws {
        try self.init(Bound(from: decoder))
    }
}
