import UIKit

public protocol TableRow {
    func makeTableCell() -> UITableViewCell
}

public struct TableSettings<Row: TableRow> {
    internal var rows = [Row]()
}

public protocol TablePresenter {
    associatedtype Row: TableRow
    
    func append(contentsOf observer: Observer<Row>) -> Observer<Void>
    func replace(withContentsOf observer: Observer<Row>) -> Observer<Void>
}

open class TableController<Row: TableRow>: UINavigationController, AnyRockstar {
    public var rockstar: Rockstar<TableController<Row>> {
        return Rockstar(wrapping: self)
    }
    
    public var rockstarSettings = TableSettings<Row>()
}

extension Rockstar where Base: TablePresenter {
    func append(contentsOf observer: Observer<Base.Row>) -> Observer<Void> {
        return base.append(contentsOf: observer)
    }
    
    func replace(withContentsOf observer: Observer<Base.Row>) -> Observer<Void> {
        return base.append(contentsOf: observer)
    }
}

public final class StoreDataSource<Entity: TableRow & Storeable>: NSObject, UITableViewDelegate, UITableViewDataSource {
    let store: MemoryStore<Entity>
    private var entities = [Entity]()
    private weak var table: UITableView?
    
    public init(store: MemoryStore<Entity>, controller: UITableView) {
        self.store = store
        super.init()
        
        self.updateEntities()
    }
    
    private func updateEntities() {
        func reloadData() {
            self.table?.reloadData()
        }
        
        store.all.write(to: self, atKeyPath: \.entities).finally(reloadData)
    }
    
    public final func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    public final func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.entities[indexPath.item].makeTableCell()
    }
}
