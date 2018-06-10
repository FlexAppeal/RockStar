import UIKit

extension UINavigationController: BasicRockstar {
    public typealias RockstarType = UINavigationController
    public typealias RockstarMetadata = NavigationSettings
    
    public static let defaultMetadata = NavigationSettings()
}

public struct NavigationSettings {
    public var animate: ConfigurationOption<Bool>
    
    init() {
        self.animate = true
    }
}

extension Rockstar where Base == UINavigationController, Metadata == NavigationSettings {
    public mutating func withAnimations<T>(_ run: () throws -> T) rethrows -> T {
        let existingSetting = metadata.animate
        metadata.animate = true
        defer {
            metadata.animate = existingSetting
        }
        
        return try run()
    }
    
    public mutating func withoutAnimations<T>(_ run: () throws -> T) rethrows -> T {
        let existingSetting = metadata.animate
        metadata.animate = false
        defer {
            metadata.animate = existingSetting
        }
        
        return try run()
    }
    
    private var animate: Bool {
        return metadata.animate.value ?? true
    }
    
    public func push(_ controller: UIViewController) {
        self.base.pushViewController(controller, animated: animate)
    }
    
    public func pop() -> UIViewController? {
        return self.base.popViewController(animated: animate)
    }
    
    @discardableResult
    public func push(_ controller: Observer<UIViewController>) -> Observer<Void> {
        let animate = self.animate
        
        return controller.map { controller in
            self.base.pushViewController(controller, animated: animate)
        }
    }
}
