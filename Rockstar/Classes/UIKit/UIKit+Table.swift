import UIKit

public protocol TableRow {
    
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
