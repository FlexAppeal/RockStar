/// FIXME: Save state
/// FIXME: Dynamic member lookup (Swift 4.2) on state
public protocol ApplicationState {
    associatedtype Platform: GUIPlatform
    
    static var `default`: Self { get }
}

public protocol StateComponent {
    associatedtype State: ApplicationState
    
    func updateState(_ state: inout State)
}
