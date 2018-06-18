import UIKit

extension UITableViewCell: TableCell {}

public protocol UITableViewCellRepresentable {
    func makeTableCell() -> UITableViewCell
}
