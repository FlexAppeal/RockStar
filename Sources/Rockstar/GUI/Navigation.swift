public protocol Navigator: class {
    associatedtype Element: GUIElementRepresentable
    
    func forward(to element: Element)
    func backwards()
}

public struct NavigationConfig: Configuration {
    public var animate: ConfigurationOption<Bool>
    
    init() {
        self.animate = true
    }
}
