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
    func reloadData() -> Observable<Void>
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
        
        func reloadData() -> Observable<Void> {
            return self.all.onCompletion(emitter.emit).map { _ in }
        }
        
        return ObservableTableDataSource(Observable: emitter.observable, table: table, reload: reloadData)
    }
}

extension Observable where FutureValue: Sequence, FutureValue.Element: TableRow {
    public func makeDataSource(for table: UITableView) -> RSTableViewDataSource {
        let data = self.map(Array.init)
        
        return ObservableTableDataSource(Observable: data, table: table) {
            return .done
        }
    }
}

/// FIXME: UITableViewDataPrefetching
fileprivate final class ObservableTableDataSource<Entity: TableRow>: NSObject, RSTableViewDataSource {
    private var entities = [Entity]()
    private let table: UITableView
    let reload: () -> Observable<Void>
    
    public init(Observable: Observable<[Entity]>, table: UITableView, reload: @escaping () -> Observable<Void>) {
        self.table = table
        self.reload = reload
        super.init()
        
        Observable.write(to: self, atKeyPath: \.entities).switchThread(to: .dispatchQueue(.main)).finally(self.table.reloadData)
    }
    
    @discardableResult
    func reloadData() -> Observable<Void> {
        return reload()
    }
    
    public final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    public final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.entities[indexPath.item].makeTableCell()
    }
}
