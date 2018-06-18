import UIKit

extension UILabel: Label {
    public var color: UIColor? {
        get {
            return self.textColor
        }
        set {
            self.textColor = newValue
        }
    }
}
