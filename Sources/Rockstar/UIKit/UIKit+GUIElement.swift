import UIKit

extension UIView: GUIElement, GUIElementRepresentable {
    public var guiElement: UIView { return self }
    
    public var background: Background {
        get {
            return Background(color: self.backgroundColor?.makeColor() ?? .none)
        }
        set {
            self.backgroundColor = newValue.color.uiColor
        }
    }
}

extension UIViewController: GUIElementRepresentable {
    public var guiElement: UIView { return view }
}
