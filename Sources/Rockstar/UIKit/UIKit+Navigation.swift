import UIKit

open class NavigationController: UINavigationController, BasicRockstar {
    public var rockstarSettings = NavigationSettings()
}

public struct NavigationSettings {
    public var animate: ConfigurationOption<Bool>
    
    init() {
        self.animate = true
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

extension Rockstar where Base == NavigationController {
    public var settings: NavigationSettings {
        get {
            return base.rockstarSettings
        }
        set {
            base.rockstarSettings = newValue
        }
    }
    
    public mutating func withAnimations<T>(_ run: () throws -> T) rethrows -> T {
        let existingSetting = settings.animate
        settings.animate = true
        defer {
            settings.animate = existingSetting
        }
        
        return try run()
    }
    
    public mutating func withoutAnimations<T>(_ run: () throws -> T) rethrows -> T {
        let existingSetting = settings.animate
        settings.animate = false
        defer {
            settings.animate = existingSetting
        }
        
        return try run()
    }
    
    private var animate: Bool {
        return settings.animate.value ?? true
    }
    
    public func push(_ controller: UIViewController) {
        self.base.pushViewController(controller, animated: animate)
    }
    
    public func pop() -> UIViewController? {
        return self.base.popViewController(animated: animate)
    }
    
    @discardableResult
    public func push(_ controller: Observable<UIViewController>) -> Observable<Void> {
        let animate = self.animate
        
        return controller.map { controller in
            self.base.pushViewController(controller, animated: animate)
        }
    }
}
