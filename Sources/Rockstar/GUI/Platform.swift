public protocol GUIPlatform {
    associatedtype LabelType: Label
    associatedtype ButtonType: Button
    associatedtype NavigatorType: Navigator
    associatedtype ImageType: Image
}
