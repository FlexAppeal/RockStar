import Foundation

extension RichText {
    var attributedString: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self.string)
        
        for attribute in self.attributes {
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
                    .font: uiFont
                ]
            } else {
                return [
                    .font: uiFont
                ]
            }
        }
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
