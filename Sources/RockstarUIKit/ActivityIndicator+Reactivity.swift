import UIKit
import Rockstar

extension UIActivityIndicatorView {
    public func awaitingActivity<T>(from future: Future<T>) -> Future<T> {
        self.startAnimating()
        
        return future.always {
            self.stopAnimating()
        }
    }
}
