import Foundation

extension HTTPBody {
    public init<E: Encodable>(json: E) throws {
        try self.init(data: JSONEncoder().encode(json))
    }
}
