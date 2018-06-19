import Rockstar
import UIKit

final class PostsTable: UITableViewController {
    override func viewDidLoad() {
        try! NSCacheStore<Post>(source: PostSource()).makeDataSource(for: self.tableView)
        
        super.viewDidLoad()
    }
}
