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

extension Navigator {
    public var navigationSettings: NavigationConfig {
        get {
            return navigationSettings
        }
        set {
            navigationSettings = newValue
        }
    }
    
    public func withAnimations<T>(
        setTo animate: ConfigurationOption<Bool>,
        _ run: () throws -> T
    ) rethrows -> T {
        let existingSetting = navigationSettings.animate
        navigationSettings.animate = animate
        defer {
            navigationSettings.animate = existingSetting
        }
        
        return try run()
    }
    
    public func withAnimationsAsync<T>(
        setTo animate: ConfigurationOption<Bool>,
        _ run: () throws -> Future<T>
    ) rethrows -> Future<T> {
        let existingSetting = navigationSettings.animate
        navigationSettings.animate = animate
        
        return try run().always {
            self.navigationSettings.animate = existingSetting
        }
    }
}
