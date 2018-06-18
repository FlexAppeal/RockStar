import UIKit

extension UIView: GUIElement {
    public var background: Background {
        get {
            return Background(color: self.backgroundColor?.makeColor() ?? .none)
        }
        set {
            self.backgroundColor = newValue.color.uiColor
        }
    }
}
