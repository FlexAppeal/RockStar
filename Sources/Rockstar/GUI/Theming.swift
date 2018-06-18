import UIKit

public struct Background {
    public var color: UIColor?
    
    public init(
        color: UIColor?
    ) {
        self.color = color
    }
}

public protocol GUIElement {
    var background: Background { get set }
}

public protocol ViewController {
    associatedtype View: GUIElement
    
    var element: View { get }
}

extension UIView: GUIElement {
    public var background: Background {
        get {
            return Background(color: self.backgroundColor)
        }
        set {
            self.backgroundColor = newValue.color
        }
    }
}

extension UIViewController: ViewController {
    public typealias View = UIView
    
    public var element: UIView {
        return self.view
    }
}
