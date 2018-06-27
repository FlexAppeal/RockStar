import UIKit

public protocol UIViewControllerRepresentable {
    var controller: UIViewController { get }
}

public struct UINavigationItemConfiguration {
    fileprivate let controller: UIViewController
    fileprivate let navigator: UINavigationController
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
        let action = AnyNavigationAction {
            let navigator = self.configurable.navigator
            
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
        
        let button = UIBarButtonItem(title: name, style: .plain, target: action, action: #selector(AnyNavigationAction.run))
        
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

extension UINavigationController: Navigator {
    public typealias Platform = UIKitPlatform
    public typealias Navigateable = UIViewControllerRepresentable
    public typealias NavigationConfiguration = UINavigationItemConfiguration
    
    @discardableResult
    public func setView(to navigateable: Navigateable) -> ConfigurationHandle<NavigationConfiguration> {
        let item = UINavigationItemConfiguration(
            controller: navigateable.controller,
            navigator: self
        )
        
        return ConfigurationHandle(item) {
            print(navigateable.controller.title)
            self.setViewControllers([navigateable.controller], animated: false)
        }
    }
    
    @discardableResult
    public func open(_ navigateable: Navigateable) -> ConfigurationHandle<NavigationConfiguration> {
        let item = UINavigationItemConfiguration(
            controller: navigateable.controller,
            navigator: self
        )
        
        return ConfigurationHandle(item) {
            self.pushViewController(navigateable.controller, animated: true)
        }
    }
    
    public func `return`(to navigateable: Navigateable) {
        self.popToViewController(navigateable.controller, animated: true)
    }
    
    public var background: Background {
        get {
            return view.background
        }
        set {
            view.background = newValue
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
