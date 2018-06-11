/// FIXME: Save state
public protocol ApplicationState {
    static var `default`: Self { get }
}

public protocol StateComponent {
    associatedtype State: ApplicationState
    
    func updateState(_ state: inout State)
}
