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
    
    func append(contentsOf observable: Observable<Row>) -> Observable<Void>
    func replace(withContentsOf observable: Observable<Row>) -> Observable<Void>
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
    func append(contentsOf Observable: Observable<Base.Row>) -> Observable<Void> {
        return base.append(contentsOf: Observable)
    }
    
    func replace(withContentsOf Observable: Observable<Base.Row>) -> Observable<Void> {
        return base.append(contentsOf: Observable)
    }
}

extension DataManager where Entity: TableRow {
    public func makeDataSource(for table: UITableView) -> RSTableViewDataSource {
        let emitter = Observer<[Entity]>()
        
        func reloadData() -> Future<Void> {
            return self.all.onCompletion(emitter.emit).map { _ in }
        }
        
        return ObservableTableDataSource(observable: emitter.observable, table: table, reload: reloadData)
    }
}

extension Observable where FutureValue: Sequence, FutureValue.Element: TableRow {
    public func makeDataSource(for table: UITableView) -> RSTableViewDataSource {
        let data = self.map(Array.init)
        
        return ObservableTableDataSource(observable: data, table: table) {
            return .done
        }
    }
}

/// FIXME: UITableViewDataPrefetching
fileprivate final class ObservableTableDataSource<Entity: TableRow>: NSObject, RSTableViewDataSource {
    private var entities = [Entity]()
    private let table: UITableView
    let reload: () -> Future<Void>
    
    public init(observable: Observable<[Entity]>, table: UITableView, reload: @escaping () -> Future<Void>) {
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
