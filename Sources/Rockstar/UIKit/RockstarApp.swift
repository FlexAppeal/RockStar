import UIKit

public protocol EmptyInitializable {
    init()
}

extension UIViewController: EmptyInitializable {}

open class RockstarUIKitApp<App: RockstarApp>: UIResponder, UIApplicationDelegate {
    public internal(set) var window: UIWindow!
    
    public static var `default`: RockstarUIKitApp! {
        return UIApplication.shared.delegate as? RockstarUIKitApp
    }
    
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
    ) -> Bool {
        let uiKitApp = Application(uiKit: application)
        let app = App()
        
        do {
            let description = try app.describe(application: uiKitApp)
            try description.apply(to: self)
            
            return true
        } catch {
            return false
        }
    }
}

public final class TableRowDescription {
    internal enum _TableRowDescription {
        case view(ViewControllerDescription)
    }
    
    let description: _TableRowDescription
    
    public init(view: ViewControllerDescription) {
        self.description = .view(view)
    }
}

public protocol TableRowRepresentable {
    func describe() throws -> TableRowDescription
}

public protocol DataSource: class {
    associatedtype Entity
    
    func all() -> Future<[Entity]>
}

public protocol PaginatableDataSource: DataSource {
    associatedtype Index
    
    func paginate(from start: Index, to end: Index) -> Future<PaginatedResults<Entity>>
}

internal struct AnyDataSource<Entity> {
    typealias All = () -> Future<[Entity]>
    
    let all: All
    
    init<Source: DataSource>(
        dataSource: Source
    ) where Source.Entity == Entity {
        self.all = dataSource.all
    }
}

open class FlatTableController: Controller {
    public let title = Binding<String?>(nil)
    private let source: AnyDataSource<TableRowRepresentable>
    
    public static var platforms: [SupportedPlatform] {
        return [
            .iOS(iOS(versions: .all))
        ]
    }
    
    public init<Source: DataSource>(
        dataSource: Source
    ) where Source.Entity == TableRowRepresentable {
        self.source = AnyDataSource(dataSource: dataSource)
    }
    
    public func describeView() throws -> ViewControllerDescription {
        let flatTable = TableDescription.Flat(rowSource: source)
        let table = TableDescription(flat: flatTable)
        
        return .table(fromDescription: table)
    }
}

internal final class UIFlatTableViewController: UITableViewController {
    internal init(description: TableDescription.Flat) {
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

public final class TableDescription {
    public struct Flat {
        let rowSource: AnyDataSource<TableRowRepresentable>
    }
    
    internal enum _TableDescription {
        case flat(TableDescription.Flat)
    }
    
    internal let description: _TableDescription
    
    public init(flat description: Flat) {
        self.description = .flat(description)
    }
}

public final class Binding<Bound> {
    public private(set) var currentValue: Bound {
        didSet {
            for update in bindingUpdates {
                update()
            }
        }
    }
    
    private var bindingUpdates = [() -> ()]()
    
    public init(_ value: Bound) {
        self.currentValue = value
    }
    
    public func update(to value: Bound) {
        self.currentValue = value
    }
    
    public func bind<C: AnyObject>(to object: C, atKeyPath path: WritableKeyPath<C, Bound>) {
        weak var object = object
        
        func update() {
            object?[keyPath: path] = currentValue
        }
        
        update()
        self.bindingUpdates.append(update)
    }
}

public struct ViewDetails {
    public let title = Binding<String?>(nil)
    
    public init() {}
}

public final class ViewControllerDescription {
    internal enum _ViewControllerDescription {
        case table(TableDescription)
    }
    
    internal let details: ViewDetails
    internal let description: _ViewControllerDescription
    
    internal init(_ description: _ViewControllerDescription, details: ViewDetails) {
        self.description = description
        self.details = details
    }
    
    public static func table(fromDescription table: TableDescription, details: ViewDetails = ViewDetails()) -> ViewControllerDescription {
        return ViewControllerDescription(.table(table), details: details)
    }
}

public protocol PlatformComponent {
    static var platforms: [SupportedPlatform] { get }
}

public protocol Controller: PlatformComponent {
    func describeView() throws -> ViewControllerDescription
}

public protocol RockstarApp: EmptyInitializable, PlatformComponent {
    func describe(application: Application) throws -> ApplicationDescription
}

public final class ApplicationWindow {
    internal var controller: (Controller & EmptyInitializable).Type?
    
    internal init() {}
    
    public func displayController<C: Controller & EmptyInitializable>(_ controller: C.Type) {
        self.controller = controller
    }
}

extension Set where Element: PlatformVersion {
    public static var all: Set<Element> {
        return Element.all
    }
}

public final class ApplicationDescription {
    public let mainWindow = ApplicationWindow()
    
    public init() {}
    
    internal func apply<App: RockstarApp>(to app: RockstarUIKitApp<App>) throws {
        app.window = UIWindow(frame: UIScreen.main.bounds)
        defer { app.window.makeKeyAndVisible() }
        
        if let controllerType = self.mainWindow.controller {
            let controller = controllerType.init()
            
            let view = try controller.describeView().representUIKit()
            let viewController = UIViewController()
//            viewController.view = view
            
            app.window.rootViewController = viewController
        }
    }
}

extension ViewControllerDescription {
    func representUIKit() throws -> UIViewController {
        struct TempError: Error {}
        throw TempError()
//        let view: UIView
//
//        switch self.description {
//        case .table(let table):
//            view = try table.representUIKit()
//        }
//
//        return view
    }
}

extension ViewDetails {
    func apply(to viewController: UIViewController) {
        self.title.bind(to: viewController, atKeyPath: \.title)
    }
}

extension TableRowDescription {
    func representUIKit() throws -> UITableViewCell {
        let cell = UITableViewCell()
        
        switch self.description {
        case .view(let view):
//            let subView = try view.representUIKit()
//            cell.addSubview(subView)
        }
        
        return cell
    }
}

extension TableDescription {
    func representUIKit() throws -> UITableViewController {
        switch self.description {
        case .flat(let flatTable):
            return try flatTable.representUIKit()
        }
    }
}

extension TableDescription.Flat {
    func representUIKit() throws -> UIFlatTableViewController {
        return UIFlatTableViewController(description: self)
    }
}

public final class Application {
    internal init(uiKit app: UIApplication) {}
}

public enum SupportedPlatform {
    case iOS(iOS)
}

public protocol PlatformVersion: Comparable, Hashable {
    static var all: Set<Self> { get }
}

public protocol Platform {
    associatedtype Version: PlatformVersion
    
    var versions: Set<Version> { get }
}

public struct iOS: Platform {
    public enum Version: Int, PlatformVersion {
        public static func < (lhs: iOS.Version, rhs: iOS.Version) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        case iOS8 = 8
        case iOS9 = 9
        case iOS10 = 10
        case iOS11 = 11
        case iOS12 = 12
        
        public static var all: Set<Version> {
            return [
                iOS8, iOS9, iOS10, iOS11, iOS12
            ]
        }
    }
    
    public var versions: Set<Version>
    
    public init(versions: Set<Version>) {
        self.versions = versions
    }
}

public final class MemoryDataSource<Entity>: DataSource {
    private var entities = [Entity]()
    
    public init() {}
    
    public func all() -> Future<[Entity]> {
        return Future(result: entities)
    }
    
    public func set(to entities: [Entity]) {
        self.entities = entities
    }
}
