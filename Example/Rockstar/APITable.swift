import Rockstar
import UIKit

final class PostsTable: TableController<Post> {
    override func viewDidLoad() {
        let source = AppState.default.postStore.all.makeDataSource(for: self.tableView)
        self.rockstarSettings = TableSettings(dataSource: source)
        super.viewDidLoad()
    }
}
