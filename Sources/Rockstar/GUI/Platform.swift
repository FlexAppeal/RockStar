public protocol GUIPlatform: class {
    associatedtype ViewType: GUIElement
    associatedtype LabelType: Label
    associatedtype ButtonType: Button
    associatedtype NavigatorType: Navigator
    associatedtype ImageType: Image
    associatedtype FormComponentType
    
    init()
    func start() throws
    var view: ViewType { get set }
}
