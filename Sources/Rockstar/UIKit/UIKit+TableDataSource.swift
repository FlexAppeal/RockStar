import UIKit

extension DataManager where Entity: UITableViewCellRepresentable {
    public func makeDataSource(for table: UITableView) -> UITableViewDataSource {
        let inputStream = InputStream<[Entity]>()
        
        func reloadData() -> Future<Void> {
            return self.all.onCompletion(inputStream.write).map { _ in }
        }
        
        return OutputStreamTableDataSource(observable: inputStream.listener, table: table, reload: reloadData)
    }
}

extension OutputStream where FutureValue: Sequence, FutureValue.Element: UITableViewCellRepresentable {
    public func makeDataSource(for table: UITableView) -> UITableViewDataSource {
        let data = self.map(Array.init)
        
        return OutputStreamTableDataSource(observable: data, table: table) {
            return .done
        }
    }
}

/// FIXME: UITableViewDataPrefetching
fileprivate final class OutputStreamTableDataSource<Entity: UITableViewCellRepresentable>: NSObject, UITableViewDataSource {
    private var entities = [Entity]()
    private let table: UITableView
    let reload: () -> Future<Void>
    
    public init(observable: OutputStream<[Entity]>, table: UITableView, reload: @escaping () -> Future<Void>) {
        self.table = table
        self.reload = reload
        super.init()
        
        observable.write(
            to: self,
            atKeyPath: \.entities
        ).switchThread(to: .dispatchQueue(.main)).always(self.table.reloadData)
    }
    
    @discardableResult
    func reloadData() -> Future<Void> {
        return reload()
    }
    
    public final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    public final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.entities[indexPath.item].makeTableCell()
    }
}
