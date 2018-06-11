import UIKit

public protocol TableRow {
    func makeTableCell() -> UITableViewCell
}

public struct TableSettings<Row: TableRow> {
    public let dataSource: UITableViewDataSource
    
    public init(dataSource: UITableViewDataSource) {
        self.dataSource = dataSource
    }
}

public protocol TablePresenter {
    associatedtype Row: TableRow
    
    func append(contentsOf observer: Observer<Row>) -> Observer<Void>
    func replace(withContentsOf observer: Observer<Row>) -> Observer<Void>
}

open class TableController<Row: TableRow>: UITableViewController, AnyRockstar {
    public var rockstar: Rockstar<TableController<Row>> {
        return Rockstar(wrapping: self)
    }
    
    open override func viewDidLoad() {
        guard let rockstarSettings = rockstarSettings else {
            fatalError("You must override the `rockstarSettings` with an appropriate setting")
        }
        
        self.tableView.dataSource = rockstarSettings.source
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

public final class StoreDataSource<Entity: TableRow & Storeable>: NSObject, UITableViewDataSource {
    let store: MemoryStore<Entity>
    private var entities = [Entity]()
    private let table: UITableView
    
    public init(store: MemoryStore<Entity>, tableView: UITableView) {
        self.store = store
        self.table = tableView
        super.init()
        
        self.updateEntities()
    }
    
    private func updateEntities() {
        store.all.write(to: self, atKeyPath: \.entities).switchThread(to: DispatchQueue.main).finally(self.table.reloadData)
    }
    
    public final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    public final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.entities[indexPath.item].makeTableCell()
    }
}
