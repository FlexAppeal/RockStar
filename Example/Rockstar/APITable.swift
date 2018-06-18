import Rockstar
import UIKit

final class PostsTable: UITableViewController {
    override func viewDidLoad() {
        try! DataManager<Post>(source: PostSource()).makeDataSource(for: self.tableView)
        
        super.viewDidLoad()
    }
}
