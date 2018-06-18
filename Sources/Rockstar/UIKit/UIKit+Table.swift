import UIKit

public protocol TableRow {
    func makeTableCell() -> UITableViewCell
}

public struct TableSettings<Row: TableRow> {
    public let dataSource: RSTableViewDataSource
    
    public init(dataSource: RSTableViewDataSource) {
        self.dataSource = dataSource
    }
}

public protocol TablePresenter {
    associatedtype Row: TableRow
    
    func append(contentsOf observable: OutputStream<Row>) -> OutputStream<Void>
    func replace(withContentsOf observable: OutputStream<Row>) -> OutputStream<Void>
}

public protocol RSTableViewDataSource: UITableViewDataSource {
    @discardableResult
    func reloadData() -> Future<Void>
}

open class TableController<Row: TableRow>: UITableViewController, AnyRockstar {
    public var rockstar: Rockstar<TableController<Row>> {
        return Rockstar(wrapping: self)
    }
    
    open override func viewDidLoad() {
        guard let rockstarSettings = rockstarSettings else {
            fatalError("You must override the `rockstarSettings` with an appropriate setting")
        }
        
        self.tableView.dataSource = rockstarSettings.dataSource
    }
    
    public var rockstarSettings: TableSettings<Row>!
}

extension Rockstar where Base: TablePresenter {
    func append(contentsOf OutputStream: OutputStream<Base.Row>) -> OutputStream<Void> {
        return base.append(contentsOf: OutputStream)
    }
    
    func replace(withContentsOf OutputStream: OutputStream<Base.Row>) -> OutputStream<Void> {
        return base.append(contentsOf: OutputStream)
    }
}

extension DataManager where Entity: TableRow {
    public func makeDataSource(for table: UITableView) -> RSTableViewDataSource {
        let inputStream = InputStream<[Entity]>()
        
        func reloadData() -> Future<Void> {
            return self.all.onCompletion(inputStream.write).map { _ in }
        }
        
        return OutputStreamTableDataSource(observable: inputStream.listener, table: table, reload: reloadData)
    }
}

extension OutputStream where FutureValue: Sequence, FutureValue.Element: TableRow {
    public func makeDataSource(for table: UITableView) -> RSTableViewDataSource {
        let data = self.map(Array.init)
        
        return OutputStreamTableDataSource(observable: data, table: table) {
            return .done
        }
    }
}

/// FIXME: UITableViewDataPrefetching
fileprivate final class OutputStreamTableDataSource<Entity: TableRow>: NSObject, RSTableViewDataSource {
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
