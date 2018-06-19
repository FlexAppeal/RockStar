import UIKit

extension UINavigationController: Navigator {
    public typealias Element = UIViewController
    
    public func backwards() {
        self.popViewController(animated: true)
    }
    
    public func forward(to controller: Element) {
        self.pushViewController(controller, animated: true)
    }
}