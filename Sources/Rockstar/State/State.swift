/// FIXME: Save state
/// FIXME: Dynamic member lookup (Swift 4.2) on state
public protocol ApplicationState: class {
    associatedtype Platform: GUIPlatform
    
    static var `default`: Self { get }
}
