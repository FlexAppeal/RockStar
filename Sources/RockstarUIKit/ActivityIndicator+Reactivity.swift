import UIKit
import Rockstar

extension UIActivityIndicatorView {
    public func animate<T>(untilCompletion future: Future<T>) -> Future<T> {
        self.startAnimating()
        
        return future.always {
            self.stopAnimating()
        }
    }
}
