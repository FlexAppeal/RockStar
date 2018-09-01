import Rockstar

public protocol UITableViewCellRepresentable {
    func makeTableViewCell() -> UITableViewCell
}

public final class BindableTableCollection<E: UITableViewCellRepresentable>: BindableCollection<E>, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self[indexPath.row].currentValue.makeTableViewCell()
    }
}
