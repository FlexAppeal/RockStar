import UIKit
import Foundation

extension RichText {
    public var attributedString: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self.string)
        
        for attribute in self.textAttributes {
            attributedString.addAttributes(
                attribute.foundationAttributes,
                range: NSRange(location: attribute.from, length: (attribute.to - attribute.from) + 1)
            )
        }
        
        return NSAttributedString(attributedString: attributedString)
    }
}

extension NSAttributedString {
    public var richText: RichText {
        fatalError("Unimplemented")
    }
}

extension RangedRichTextAttributes {
    var foundationAttributes: [NSAttributedStringKey: Any] {
        switch attribute {
        case .color(let color):
            return [
                .foregroundColor: color.uiColor
            ]
        case .font(let font):
            guard let uiFont = font.uiFont else {
                return [:]
            }
            
            if font.underlined {
                /// FIXME:
                return [
                    .font: uiFont,
                    .underlineStyle: NSUnderlineStyle.patternSolid
                ]
            } else {
                return [
                    .font: uiFont
                ]
            }
        case .centered:
            var style = NSMutableParagraphStyle()
            style.alignment = .center
            
            return [
                .paragraphStyle: style
            ]
        }
    }
}

extension UIFont {
    public var textFont: TextFont {
        return TextFont(named: fontName, size: Float(pointSize))
    }
}

extension TextFont {
    public var uiFont: UIFont? {
        let size = CGFloat(self.size)
        
        if let name = self.name {
            /// FIXME: Bold/italic system fonts
            return UIFont(name: name, size: size)
        } else {
            switch self.representation {
            case .normal:
                return UIFont.systemFont(ofSize: size)
            case .bold:
                return UIFont.boldSystemFont(ofSize: size)
            case .italic:
                return UIFont.italicSystemFont(ofSize: size)
            }
        }
    }
}
