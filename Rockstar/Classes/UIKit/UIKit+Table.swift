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
    
    func append(contentsOf observer: Observer<Row>) -> Observer<Void>
    func replace(withContentsOf observer: Observer<Row>) -> Observer<Void>
}

public protocol RSTableViewDataSource: UITableViewDataSource {
    @discardableResult
    func reloadData() -> Observer<Void>
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
    func append(contentsOf observer: Observer<Base.Row>) -> Observer<Void> {
        return base.append(contentsOf: observer)
    }
    
    func replace(withContentsOf observer: Observer<Base.Row>) -> Observer<Void> {
        return base.append(contentsOf: observer)
    }
}

extension MemoryStore where Entity: TableRow {
    public func makeDataSource(for table: UITableView) -> RSTableViewDataSource {
        let emitter = Observable<[Entity]>()
        
        func reloadData() -> Observer<Void> {
            return self.all.onCompletion(emitter.emit).map { _ in }
        }
        
        return ObserverTableDataSource(observer: emitter.observer, table: table, reload: reloadData)
    }
}

extension Observer where FutureValue: Sequence, FutureValue.Element: TableRow {
    public func makeDataSource(for table: UITableView) -> RSTableViewDataSource {
        let data = self.map(Array.init)
        
        return ObserverTableDataSource(observer: data, table: table) {
            return .done
        }
    }
}

/// FIXME: UITableViewDataPrefetching
fileprivate final class ObserverTableDataSource<Entity: TableRow>: NSObject, RSTableViewDataSource {
    private var entities = [Entity]()
    private let table: UITableView
    let reload: () -> Observer<Void>
    
    public init(observer: Observer<[Entity]>, table: UITableView, reload: @escaping () -> Observer<Void>) {
        self.table = table
        self.reload = reload
        super.init()
        
        observer.write(to: self, atKeyPath: \.entities).switchDispatchQueue(to: .main).finally(self.table.reloadData)
    }
    
    @discardableResult
    func reloadData() -> Observer<Void> {
        return reload()
    }
    
    public final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    public final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.entities[indexPath.item].makeTableCell()
    }
}
