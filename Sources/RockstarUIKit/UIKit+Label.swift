import UIKit
import Rockstar

extension UILabel: RichTextConvertible {
    public var richText: RichText {
        get {
            return self.attributedText?.richText ?? ""
        }
        set {
            self.attributedText = newValue.richText.attributedString
        }
    }
}
