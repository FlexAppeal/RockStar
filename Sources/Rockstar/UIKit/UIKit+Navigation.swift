import UIKit

open class NavigationController: UINavigationController, Navigator, BasicRockstar {
    public var navigationSettings = NavigationConfig()
    
    public func navigateBackwards() {
        self.popViewController(animated: animate)
    }
    
    private var animate: Bool {
        return navigationSettings.animate.value ?? true
    }
    
    public func navigateForward(to controller: UIViewController) {
        self.pushViewController(controller, animated: animate)
    }
}

public protocol NavigationState: ApplicationState {
    static var navigatorPath: WritableKeyPath<Self, NavigationController?> { get }
}

extension StateComponent where Self: NavigationController, State: NavigationState {
    public func updateState(_ state: inout State) {
        state[keyPath: State.navigatorPath] = self as NavigationController
    }
}

extension Rockstar: Navigator where Base: Navigator {
    public typealias Controller = Base.Controller
    public typealias View = Base.View
    
    public var navigationSettings: NavigationConfig {
        get {
            return base.navigationSettings
        }
        set {
            base.navigationSettings = newValue
        }
    }
    
    public func withAnimations<T>(_ run: () throws -> T) rethrows -> T {
        let existingSetting = base.navigationSettings.animate
        base.navigationSettings.animate = true
        defer {
            base.navigationSettings.animate = existingSetting
        }
        
        return try run()
    }
    
    public func withoutAnimations<T>(_ run: () throws -> T) rethrows -> T {
        let existingSetting = base.navigationSettings.animate
        base.navigationSettings.animate = false
        defer {
            base.navigationSettings.animate = existingSetting
        }
        
        return try run()
    }
    
    public func navigateForward(to controller: Base.Controller) {
        self.base.navigateForward(to: controller)
    }
    
    public func navigateBackwards() {
        self.base.navigateBackwards()
    }
}
