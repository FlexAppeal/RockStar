import UIKit

extension UILabel: Label {
    public var text: RichText? {
        get {
            return self.attributedText?.richText
        }
        set {
            self.attributedText = newValue?.attributedString
        }
    }
    
    public var color: Color? {
        get {
            return self.textColor.makeColor()
        }
        set {
            self.textColor = newValue?.uiColor
        }
    }
}
