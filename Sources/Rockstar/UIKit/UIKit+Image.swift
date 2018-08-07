import UIKit

extension UIImageView: Image {
    public var imageFile: ImageFile? {
        get {
            guard
                let image = self.image,
                let data = UIImageJPEGRepresentation(image, 1)
            else {
                return nil
            }
            
            return ImageFile(jpeg: data)
        }
        set {
            if let data = newValue?.data {
                self.image = UIImage(data: data)
            }
        }
    }
}
