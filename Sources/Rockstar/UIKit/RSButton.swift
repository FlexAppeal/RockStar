import UIKit

public final class RSButton: UIButton {
    typealias ControlAction = () -> ()
    
    internal var touchDownAction: ControlAction = { }
    internal var touchUpInsideAction: ControlAction = { }
    internal var touchUpOutsideAction: ControlAction = { }
    
    @objc private func didTouchDown() {
        touchDownAction()
    }
    
    @objc private func didTouchUpInside() {
        touchDownAction()
    }
    
    @objc private func didTouchUpOutside() {
        touchDownAction()
    }
    
    public func onTouchDown(run: @escaping () -> ()) {
        self.touchDownAction = run
        self.addTarget(self, action: #selector(didTouchDown), for: .touchDown)
    }
    
    public func onTouchUpInside(run: @escaping () -> ()) {
        self.touchUpInsideAction = run
        self.addTarget(self, action: #selector(didTouchUpInside), for: .touchUpInside)
    }
    
    public func onTouchUpOutside(run: @escaping () -> ()) {
        self.touchUpOutsideAction = run
        self.addTarget(self, action: #selector(didTouchUpOutside), for: .touchUpOutside)
    }
}
