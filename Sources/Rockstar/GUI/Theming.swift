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
    public var alpha: Float
    public var red: Float
    public var green: Float
    public var blue: Float
    
    public init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public static var none: Color {
        return Color(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    public static var red: Color {
        return Color(red: 1, green: 0, blue: 0, alpha: 1)
    }
    
    public static var green: Color {
        return Color(red: 0, green: 1, blue: 0, alpha: 1)
    }
    
    public static var blue: Color {
        return Color(red: 0, green: 0, blue: 1, alpha: 1)
    }
}
