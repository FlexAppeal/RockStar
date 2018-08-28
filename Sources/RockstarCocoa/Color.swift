import Cocoa

#if canImport(RockstarApple)
    import RockstarApple
#endif

import Rockstar

extension Color {
    public var nsColor: NSColor {
        let floatView = self.floatView
        
        return NSColor(
            red: CGFloat(floatView.red),
            green: CGFloat(floatView.green),
            blue: CGFloat(floatView.blue),
            alpha: CGFloat(floatView.alpha)
        )
    }
}

