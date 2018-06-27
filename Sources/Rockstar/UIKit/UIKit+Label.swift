import UIKit

extension UILabel: Label {
    public var richText: RichText {
        get {
            return self.attributedText?.richText ?? ""
        }
        set {
            self.attributedText = newValue.attributedString
        }
    }
}
