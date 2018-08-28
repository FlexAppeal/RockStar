import UIKit
import Rockstar
import RockstarApple

extension Color {
    public var uiColor: UIColor { return nativeColor }
}

extension UIColor {
    public func makeColor() -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return Color.fromFloats(
            red: Float(red),
            green: Float(green),
            blue: Float(blue),
            alpha: Float(alpha)
        )
    }
}
