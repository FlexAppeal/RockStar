import UIKit

extension UILabel: Label {
    public var color: Color? {
        get {
            return self.textColor.makeColor()
        }
        set {
            self.textColor = newValue?.uiColor
        }
    }
}
