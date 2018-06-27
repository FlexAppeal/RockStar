import Rockstar
import UIKit

final class PostsTable: UITableViewController {
    override func viewDidLoad() {
        try! NSCacheStore<Post>(source: PostSource()).makeDataSource(forTable: self.tableView)
        
        super.viewDidLoad()
    }
}
