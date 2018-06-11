import Rockstar
import UIKit

final class PostsTable: TableController<Post> {
    override func viewDidLoad() {
        self.rockstarSettings = TableSettings(dataSource: StoreDataSource(store: AppState.default.postStore, tableView: self.tableView))
        super.viewDidLoad()
    }
}
