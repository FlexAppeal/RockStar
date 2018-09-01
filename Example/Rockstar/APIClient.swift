import Rockstar
import Dispatch

final class APIClient {
    private let client: HTTPClient
    
    init() throws {
        self.client = try Services.default.make()
    }
    
    func allPosts() -> Future<[Post]> {
        return client.get(
            [Post].self,
            from: "https://jsonplaceholder.typicode.com/posts",
            headers: [:]
        ).body().switchThread(to: .dispatchQueue(.main))
    }
}

struct Post: ContentCodable {
    private enum CodingKeys: String, CodingKey {
        case id, title, body
        case posterId = "userId"
    }
    
    let id: Int
    let posterId: Int
    var title: String
    var body: String
}
