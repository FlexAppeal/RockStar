import UIKit

public final class UIKitPlatform: GUIPlatform {
    private var _view: UIView!
    public var view: UIView {
        get {
            return _view
        }
        set {
            _view = newValue
        }
    }
    
    public init() {}
    
    public func start() throws {
        
    }
    
    public typealias ViewType = UIView
    public typealias TableCellType = UITableViewCell
    public typealias ButtonType = UIButton
    public typealias LabelType = UILabel
    public typealias NavigatorType = UINavigationController
    public typealias ImageType = UIImageView
    public typealias FormComponentType = UIKitFormComponent
}
