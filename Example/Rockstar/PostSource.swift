import UIKit
import Rockstar

/// FIXME: run vmmap on memgraph
/// FIXME: run leaks on memgraph
/// FIXME: run heap  on memgraph

struct Post: Storeable, Codable, Content, UITableViewCellRepresentable {
    func makeTableCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = self.title
        return cell
    }
    
    var identifier: Int { return id }
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

final class PostSource: Service, DataStoreSource {
    typealias Entity = Post
    
    let client: AnyHTTPClient
    
    init(using client: HTTPClient) {
        self.client = AnyHTTPClient(client)
    }
    
    convenience init() throws {
        try self.init(using: Services.default.make())
    }
    
    func count() -> Future<Int> {
        return 100
    }
    
    func all() -> Future<[Post]> {
        return client.get([Post].self, from: "https://jsonplaceholder.typicode.com/posts/", headers: [:]).flatMap { response in
            return response.decodeBody()
        }
    }
    
    func fetchOne(byId id: Int) -> Future<Post?> {
        return client.get(Post.self, from: "https://jsonplaceholder.typicode.com/posts/\(id)", headers: [:]).flatMap { response in
            return response.decodeBody().map { $0 }
        }
    }
    
    func paginate(from: Int, to: Int) -> Future<PaginatedResults<Post>> {
        return Future(error: Unsupported(reason: "Pagination"))
    }
}

struct Unsupported: Error {
    var reason: String
}
