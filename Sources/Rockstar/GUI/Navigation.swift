public protocol Navigator: class {
    associatedtype Controller: ViewController
    associatedtype View: GUIElement
    
    var navigationSettings: NavigationConfig { get set }
    
    func navigateForward(to controller: Controller)
    func navigateBackwards()
}

public struct NavigationConfig: Configuration {
    public var animate: ConfigurationOption<Bool>
    
    init() {
        self.animate = true
    }
}
