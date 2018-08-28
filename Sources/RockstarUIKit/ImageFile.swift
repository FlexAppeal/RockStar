import Rockstar
import UIKit

extension File {
    public static func jpeg(_ image: UIImage, named name: String, quality: CGFloat) -> File? {
        let filename: String
        let lowercasedName = name.lowercased()
        
        if lowercasedName.hasSuffix(".jpeg") || lowercasedName.hasSuffix(".jpg") {
            filename = name
        } else {
            filename = name + ".jpeg"
        }
        
        guard let data = UIImageJPEGRepresentation(image, quality) else { return nil }
        
        return File(
            name: filename,
            type: .jpeg,
            data: data
        )
    }
}
