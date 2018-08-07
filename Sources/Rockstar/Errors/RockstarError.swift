import UIKit

public protocol RockstarError: Error {
    var location: SourceLocation { get }
}

public protocol RockstarAlertError: RockstarError {
    var title: String { get }
    var message: String { get }
    
    var actions: [AlertAction] { get }
}

extension RockstarAlertError {
    public func popup() {
        let controller = UIAlertController(
            title: self.title,
            message: self.message,
            preferredStyle: .alert
        )
        
        for action in actions {
            let alertAction = UIAlertAction(title: action.name, style: action.type) { _ in
                action.execute()
            }
            
            controller.addAction(alertAction)
        }
        
        UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true, completion: nil)
    }
}

public protocol AlertAction {
    var name: String { get }
    var type: UIAlertActionStyle { get }
    
    func execute()
}
