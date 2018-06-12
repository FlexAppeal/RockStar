import UIKit
import Rockstar

struct Post: Storeable, Content, TableRow {
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

final class PostSource: Service, MemoryStoreDataSource {
    typealias Entity = Post
    
    let client: Rockstar<AnyHTTPClient>
    
    init(using client: HTTPClient) {
        self.client = AnyHTTPClient(client).rockstar
    }
    
    convenience init() throws {
        try self.init(using: Services.default.make())
    }
    
    func count() -> Observer<Int> {
        return 100
    }
    
    func all() -> Observer<[Post]> {
        return client.get([Post].self, from: "https://jsonplaceholder.typicode.com/posts/", headers: [:]).flatMap { response in
            return response.decodeBody()
        }
    }
    
    func fetchOne(byId id: Int) -> Observer<Post> {
        return client.get(Post.self, from: "https://jsonplaceholder.typicode.com/posts/\(id)", headers: [:]).flatMap { response in
            return response.decodeBody()
        }
    }
}
