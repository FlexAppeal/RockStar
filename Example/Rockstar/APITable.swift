//import Rockstar
//import UIKit
//
//final class PostsTable: UITableViewController {
//    override func viewDidLoad() {
//        try! NSCacheStore<Post>(source: PostSource()).makeDataSource(forTable: self.tableView)
//
//        super.viewDidLoad()
//    }
//}

import Rockstar

final class PostsController: UITableViewController {
    let data = BindableTableCollection<Post>()
    let isLoading = Binding(true)
    
    override func viewDidLoad() {
        self.tableView.dataSource = data
        
        Future.do {
            return try APIClient().allPosts()
        }.then(data.append).catch { error in
            // TODO: Show Error view
        }.always {
            self.isLoading.update(to: false)
            self.tableView.reloadData()
        }
    }
}

extension Post: UITableViewCellRepresentable {
    func makeTableViewCell() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.title
        return cell
    }
}
