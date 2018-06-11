import Rockstar
import UIKit

final class PostsTable: TableController<Post> {
    override func viewDidLoad() {
        self.rockstarSettings = TableSettings(source: StoreDataSource(store: AppState.default.postStore, tableView: self.tableView))
        super.viewDidLoad()
    }
}
