import UIKit


final class NavigationActions {
    var items = [AnyNavigationAction]()
    
    public init() {}
}

extension ConfigurationHandle where Configurable == UINavigationItemConfiguration {
    public var title: String {
        get {
            return self.configurable.controller.title ?? ""
        }
        set {
            self.configurable.controller.title = newValue
        }
    }
    
    @discardableResult
    public func addAction(
        named name: String,
        alignment: HorizontalDirection = .right,
        run action: @escaping (UINavigationController) throws -> ()
    ) -> ActionHandle {
        let navigator = Weak(value: self.configurable.navigator)
        
        let action = AnyNavigationAction {
            guard let navigator = navigator.value else { return }
            
            do {
                try action(navigator)
            } catch let error as RockstarError {
                if let handler = navigator as? RSErrorHandler {
                    handler.handleError(error)
                }
            } catch {
                if let handler = navigator as? RSErrorHandler {
                    let error = AnyRockstarError(location: SourceLocation(), error: error)
                    handler.handleError(error)
                }
            }
        }
        
        self.configurable.actions.items.append(action)
        
        let button = UIBarButtonItem(title: name, style: .plain, target: action, action: #selector(action.run))
        
        switch alignment {
        case .left:
            var items = self.configurable.controller.navigationItem.leftBarButtonItems ?? []
            items.append(button)
            
            self.configurable.controller.navigationItem.setLeftBarButtonItems(items, animated: true)
        case .right:
            var items = self.configurable.controller.navigationItem.rightBarButtonItems ?? []
            items.append(button)
            
            self.configurable.controller.navigationItem.setRightBarButtonItems(items, animated: true)
        }
        
        return ActionHandle(action: action)
    }
}

public final class UIKitNavigator: Navigator, UIViewControllerRepresentable {
    private let navigator: UINavigationController
    private var items = [UINavigationItemConfiguration]()
    
    public var controller: UIViewController { return navigator }
    
    public typealias Platform = UIKitPlatform
    public typealias Navigateable = UIViewControllerRepresentable
    public typealias NavigationConfiguration = UINavigationItemConfiguration
    
    public init() {
        navigator = UINavigationController(rootViewController: UIViewController())
    }
    
    @discardableResult
    public func setView(to navigateable: Navigateable) -> ConfigurationHandle<NavigationConfiguration> {
        let item = UINavigationItemConfiguration(
            controller: navigateable.controller,
            navigator: navigator,
            actions: NavigationActions()
        )
        
        return ConfigurationHandle(item) {
            self.items = [item]
            
            /// FIXME: navigateable.controller has no tit
            self.navigator.setViewControllers([item.controller], animated: false)
        }
    }
    
    @discardableResult
    public func open(_ navigateable: Navigateable) -> ConfigurationHandle<NavigationConfiguration> {
        let item = UINavigationItemConfiguration(
            controller: navigateable.controller,
            navigator: navigator,
            actions: NavigationActions()
        )
        
        return ConfigurationHandle(item) {
            self.items.append(item)
            self.navigator.pushViewController(item.controller, animated: true)
        }
    }
    
    public func `return`(to navigateable: Navigateable) {
        let count = navigator.popToViewController(navigateable.controller, animated: true)?.count
        
        if let count = count {
            self.items.removeLast(count)
        }
    }
    
    public var background: Background {
        get {
            return navigator.view.background
        }
        set {
            navigator.view.background = newValue
        }
    }
}

public protocol Action {
    func run()
}

final class AnyNavigationAction: Action {
    var action: () -> ()
    
    internal init(_ action: @escaping () -> ()) {
        self.action = action
    }
    
    @objc func run() {
        self.action()
    }
}

public enum HorizontalDirection {
    case left, right
}
