import UIKit

public struct Background {
    public var color: Color
    
    public init(color: Color) {
        self.color = color
    }
}

public protocol GUIElement {
    var background: Background { get set }
}

public protocol GUIElementRepresentable {
    associatedtype Element: GUIElement
    
    var guiElement: Element { get }
}

public protocol ColorRepresentable {
    func makeColor() -> Color
}

public struct Color {
    public struct FloatView {
        public var red: Float
        public var green: Float
        public var blue: Float
        public var alpha: Float
    }
    
    public struct ByteView {
        public var red: UInt8
        public var green: UInt8
        public var blue: UInt8
        public var alpha: UInt8
    }
    
    public var floatView: FloatView {
        get {
            return FloatView(
                red: Float(byteView.red) / 255,
                green: Float(byteView.green) / 255,
                blue: Float(byteView.blue) / 255,
                alpha: Float(byteView.alpha) / 255
            )
        }
        set {
            assert(newValue.red >= 0 && newValue.red <= 1, "Invalid floating point received for the red value")
            assert(newValue.green >= 0 && newValue.green <= 1, "Invalid floating point received for the green value")
            assert(newValue.blue >= 0 && newValue.blue <= 1, "Invalid floating point received for the blue value")
            assert(newValue.alpha >= 0 && newValue.alpha <= 1, "Invalid floating point received for the alpha value")
            
            self.byteView = ByteView(
                red: UInt8(newValue.red * 255),
                green: UInt8(newValue.green * 255),
                blue: UInt8(newValue.blue * 255),
                alpha: UInt8(newValue.alpha * 255)
            )
        }
    }
    
    public var byteView: ByteView
    
    public static func fromFloats(red: Float, green: Float, blue: Float, alpha: Float = 1.0) -> Color {
        assert(red > 0 && red < 1, "Invalid floating point received for the red value")
        assert(green > 0 && green < 1, "Invalid floating point received for the green value")
        assert(blue > 0 && blue < 1, "Invalid floating point received for the blue value")
        assert(alpha > 0 && alpha < 1, "Invalid floating point received for the alpha value")
        
        let view = ByteView(
            red: UInt8(red * 255),
            green: UInt8(green * 255),
            blue: UInt8(blue * 255),
            alpha: UInt8(alpha * 255)
        )
        
        return Color(byteView: view)
    }
    
    public static func fromBytes(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) -> Color {
        let view = ByteView(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
        
        return Color(byteView: view)
    }
    
    public static var none: Color {
        return Color.fromBytes(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    public static var red: Color {
        return Color.fromBytes(red: 255, green: 0, blue: 0, alpha: 255)
    }
    
    public static var green: Color {
        return Color.fromBytes(red: 0, green: 255, blue: 0, alpha: 255)
    }
    
    public static var blue: Color {
        return Color.fromBytes(red: 0, green: 0, blue: 255, alpha: 255)
    }
    
    public static var white: Color {
        return Color.fromBytes(red: 255, green: 255, blue: 255, alpha: 255)
    }
    
    public static var black: Color {
        return Color.fromBytes(red: 0, green: 0, blue: 0, alpha: 255)
    }
}
