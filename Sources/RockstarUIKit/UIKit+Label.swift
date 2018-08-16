import UIKit

extension UILabel: Label {
    public var richText: RichTextRepresentable {
        get {
            return self.attributedText
        }
        set {
            self.attributedText = newValue.richText.attributedString
        }
    }
}
