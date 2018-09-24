import Rockstar
import Foundation

#if os(macOS)
import Cocoa

public typealias NativeColor = NSColor
public typealias NativeFont = NSFont
#else
import UIKit

public typealias NativeColor = UIColor
public typealias NativeFont = UIFont
#endif

extension RichText {
    public var attributedString: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self.string)
        
        for attribute in self.textAttributes {
            attributedString.addAttributes(
                attribute.foundationAttributes,
                range: NSRange(location: attribute.from, length: attribute.to - attribute.from + 1) // Inclusive to
            )
        }
        
        return NSAttributedString(attributedString: attributedString)
    }
}

extension NSAttributedString {
    public var richText: RichText {
        // TODO: Markup
        return self.string.richText
    }
}

extension RangedRichTextAttributes {
    var foundationAttributes: [NSAttributedStringKey: Any] {
        switch attribute {
        case .color(let color):
            return [
                .foregroundColor: color.nativeColor
            ]
        case .font(let font):
            guard let nativeFont = font.nativeFont else {
                return [:]
            }
            
            if font.underlined {
                /// FIXME:
                return [
                    .font: nativeFont,
                    .underlineStyle: NSUnderlineStyle.patternSolid
                ]
            } else {
                return [
                    .font: nativeFont
                ]
            }
        case .centered:
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            
            return [
                .paragraphStyle: style
            ]
        }
    }
}

extension TextFont {
    public var nativeFont: NativeFont? {
        let size = CGFloat(self.size)
        
        if let name = self.name {
            /// FIXME: Bold/italic system fonts
            return NativeFont(name: name, size: size)
        } else {
            switch self.representation {
            case .normal:
                return NativeFont.systemFont(ofSize: size)
            case .bold:
                return NativeFont.boldSystemFont(ofSize: size)
            case .italic:
                #if os(iOS)
                return NativeFont.italicSystemFont(ofSize: size)
                #else
                return NativeFont.systemFont(ofSize: size)
                #endif
            }
        }
    }
}


extension Color {
    public var nativeColor: NativeColor {
        let floatView = self.floatView
        
        return NativeColor(
            red: CGFloat(floatView.red),
            green: CGFloat(floatView.green),
            blue: CGFloat(floatView.blue),
            alpha: CGFloat(floatView.alpha)
        )
    }
}

extension NativeFont {
    public var textFont: TextFont {
        return TextFont(named: fontName, size: Float(pointSize))
    }
}
