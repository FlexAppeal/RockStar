import UIKit

extension Store where Entity: UITableViewCellRepresentable {
    public func makeDataSource(forTable table: UITableView) {
        let inputStream = InputStream<[Entity]>()
        
        func reloadData() -> Future<Void> {
            return self.all.onCompletion(inputStream.write).map { _ in }
        }
        
        let source = OutputStreamTableDataSource(observable: inputStream.listener, table: table, reload: reloadData)
        
        table.dataSource = source
    }
}

extension OutputStream where FutureValue: Sequence, FutureValue.Element: UITableViewCellRepresentable {
    public func makeDataSource(forTable table: UITableView) {
        let data = self.map(Array.init)
        
        let source = OutputStreamTableDataSource(observable: data, table: table) {
            return .done
        }
        
        table.dataSource = source
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
            ).switchThread(to: .dispatchQueue(.main)).always(run: self.table.reloadData)
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
