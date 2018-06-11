import Rockstar

struct Post: Storeable, Content, TableRow {
    func makeTableCell() -> UITableViewCell {
        fatalError()
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
    
    init<Client: HTTPClient>(using client: Client) {
        self.client = AnyHTTPClient(client).rockstar
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
