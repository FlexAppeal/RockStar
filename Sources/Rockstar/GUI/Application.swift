//import UIKit
//
//public enum OperatingSystem {
//    case macOS, iOS, linux
//}
//
//public protocol ViewRepresentable {
//    associatedtype Platform: GUIPlatform
//}
//
//extension UIViewController: UIViewControllerRepresentable {
//    public var controller: UIViewController { return self }
//}
//
//public final class ConfigurationHandle<Configurable> {
//    public let configurable: Configurable
//    private var afterConfiguration: () -> ()
//
//    public init(_ configurable: Configurable, whenComplete run: @escaping () -> ()) {
//        self.configurable = configurable
//        self.afterConfiguration = run
//    }
//
//    deinit {
//        afterConfiguration()
//    }
//}
//
//public protocol Navigator {
//    associatedtype Platform: GUIPlatform
//    associatedtype Navigateable
//    associatedtype NavigationConfiguration
//
//    func setView(to view: Navigateable) -> ConfigurationHandle<NavigationConfiguration>
//    func open(_ view: Navigateable) -> ConfigurationHandle<NavigationConfiguration>
//    func `return`(to view: Navigateable)
//}
//
//public struct ActionHandle {
//    public let action: Action
//}
//
//struct UnnassignedNavigationController: Error {}
//
//public protocol RSErrorHandler {
//    func handleError(_ error: RockstarError)
//}
//
//struct AnyRockstarError: Error {
//    var location: SourceLocation
//    var error: Error
//}
//
//public final class FormBuilder<P: GUIPlatform> {
//    typealias Row = [P.FormComponentType]
//    var rows = [Row]()
//
//    public init() {}
//
//    public func addRow(_ component: P.FormComponentType) {
//        rows.append([component])
//    }
//}
//
//extension FormBuilder where P == UIKitPlatform {
//    /// TODO: Form-encoded/JSON generator
//
////    @available(iOS 9.0, *)
////    public func makeFormController() -> UIViewController {
////        let controller = UIViewController()
////
////        for row in self.rows {
////            let view = row[0].view
////
////            let base = view.viewConstraint
////            let parent = controller.view.viewConstraint
////
////            base.addConstraint(base.width == parent.width)
////
////            let width = NSLayoutConstraint(
////                item: view,
////                attribute: .width,
////                relatedBy: .equal,
////                toItem: controller.view,
////                attribute: .width,
////                multiplier: 1,
////                constant: 0
////            )
////        }
////
////        return controller
////    }
//
//    public func addSelection<R>(
//        result: R.Type,
//        _ options: [String: R]
//    ) -> UIKitSelection<R> {
//        let selection = UIKitSelection<R>(options: options)
//        self.rows.append([selection])
//
//        return selection
//    }
//}
//
//public func ==(lhs: ConstraintType, rhs: ConstraintType) -> Constraint {
//    return Constraint(
//        lhs: lhs.builder.view,
//        lhsAttribute: lhs.attribute,
//        relation: .equal,
//        rhs: rhs.builder.view,
//        rhsAttribute: rhs.attribute
//    )
//}
//
//public struct Constraint {
//    internal var lhs: Any
//    internal var lhsAttribute: NSLayoutAttribute
//
//    internal var relation: NSLayoutRelation
//
//    internal var rhs: Any?
//    internal var rhsAttribute: NSLayoutAttribute
//}
//
//public final class ConstraintType {
//    let builder: ConstraintBuilder
//    let attribute: NSLayoutAttribute
//
//    init(builder: ConstraintBuilder, attribute: NSLayoutAttribute) {
//        self.builder = builder
//        self.attribute = attribute
//    }
//}
//
///// Do not kepe a strong reference to this entity
//public final class ConstraintBuilder {
//    public var width: ConstraintType {
//        return ConstraintType(builder: self, attribute: .width)
//    }
//
//    public func addConstraint(_ constraint: Constraint, multipliedBy multiplier: CGFloat = 1, addingConstant constant: CGFloat = 0) {
//        let layoutConstraint = NSLayoutConstraint(
//            item: constraint.lhs,
//            attribute: constraint.lhsAttribute,
//            relatedBy: constraint.relation,
//            toItem: constraint.rhs,
//            attribute: constraint.rhsAttribute,
//            multiplier: multiplier,
//            constant: constant
//        )
//
//        view.addConstraint(layoutConstraint)
//    }
//
//    let view: UIView
//
//    init(for view: UIView) {
//        self.view = view
//    }
//}
//
//extension UIView {
//    public var viewConstraint: ConstraintBuilder {
//        return ConstraintBuilder(for: self)
//    }
//}
//
//public final class FormButton: UIKitFormComponent {
//    public let isValid = true
//
//    private let _button = UIButton()
//    private var clickHandler: () -> () = { }
//    public var view: UIView { return _button }
//
//    public init() {
//        self._button.addTarget(self, action: #selector(self.didClick), for: .touchUpInside)
//    }
//
//    @objc private func didClick() {
//        self.clickHandler()
//    }
//
//    public func onClick(run: @escaping () -> ()) {
//        self.clickHandler = run
//    }
//}
//
//public final class UIKitSelection<R>: NSObject, UIKitFormComponent, UIPickerViewDataSource, UIPickerViewDelegate {
//    private var beforeChangeHandler: (R) -> () = { _ in }
//
//    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return options
//    }
//
//    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return optionNames[row]
//    }
//
//    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        self.selectedIndex = row
//    }
//
//    public let view: UIView
//
//    /// Self regularing, always valid
//    public let isValid = true
//
//    public var selectedIndex = 0 {
//        willSet {
//            beforeChangeHandler(self.optionValues[newValue])
//        }
//        didSet {
//            assert(selectedIndex >= 0 && selectedIndex < options, "Invalid selected index")
//        }
//    }
//
//    let optionNames: [String]
//    let optionValues: [R]
//    let options: Int
//
//    public var selected: R {
//        return optionValues[selectedIndex]
//    }
//
//    public func beforeChange(run: @escaping (R) -> ()) {
//        self.beforeChangeHandler = run
//    }
//
//    public init(options: [String: R]) {
//        assert(options.count > 0, "No options available to select in selection")
//        self.optionNames = Array(options.keys)
//        self.optionValues = Array(options.values)
//        self.options = options.count
//
//        let picker = UIPickerView()
//        self.view = picker
//
//        super.init()
//
//        // Weak references are fine
//        picker.dataSource = self
//        picker.delegate = self
//    }
//}
//
//public protocol FormComponent: class {
//    var isValid: Bool { get }
//}
//
//public protocol UIKitFormComponent: FormComponent {
//    var view: UIView { get }
//}
//
//public protocol Validator {
//    associatedtype ValidationType
//
//    func validate(_ value: ValidationType) -> Bool
//}
//
//public final class TextField: NSObject, UIKitFormComponent, UITextFieldDelegate {
//    private var beforeChangeHandler: (String) -> () = { _ in }
//    private var invalidTextHandler: (String, TextField) -> () = { oldValue, textField in
//        textField.text = oldValue
//    }
//
//    private var preEditableText = ""
//
//    public var text: String {
//        get {
//            return _textField.text ?? ""
//        }
//        set {
//            _textField.text = newValue
//        }
//    }
//
//    public var placeholder: String {
//        get {
//            return _textField.placeholder ?? ""
//        }
//        set {
//            _textField.placeholder = newValue
//        }
//    }
//
//    public func onInvalidText(run: @escaping (String, TextField) -> ()) {
//        self.invalidTextHandler = run
//    }
//
//    public func beforeChange(run: @escaping (String) -> ()) {
//        self.beforeChangeHandler = run
//    }
//
//    private let validator: (String) -> Bool
//    private let _textField: UITextField
//
//    public var view: UIView { return _textField }
//
//    public var isValid: Bool {
//        guard validator(text) else {
//            invalidTextHandler(preEditableText, self)
//            return false
//        }
//
//        self.preEditableText = text
//        return true
//    }
//
//    public override init() {
//        self.validator = { _ in
//            return true
//        }
//
//        self._textField = UITextField()
//        super.init()
//        self._textField.delegate = self
//    }
//
//    public func textFieldDidEndEditing(_ textField: UITextField) {
//        self.beforeChangeHandler(self.text)
//    }
//
//    public init<V: Validator>(validator: V) where V.ValidationType == String {
//        self.validator = validator.validate
//
//        self._textField = UITextField()
//        super.init()
//        self._textField.delegate = self
//    }
//
//    public static func password() -> TextField {
//        let field = TextField()
//        field._textField.isSecureTextEntry = true
//        return field
//    }
//}
//
//open class UIKitApplication: UIViewController {
//    private let context = ApplicationContext()
//
//    public final override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.configure(context)
//        self.view.addSubview(context.view)
//    }
//
//    open func configure(_ application: ApplicationContext) {
//
//    }
//}
//
//public final class ApplicationContext {
//    internal var view = UIView()
//    internal var controller: UIViewController?
//    internal var associatedReferences = [AnyObject]()
//
//    public func display(_ controller: UIViewControllerRepresentable) {
//        self.controller = controller.controller
//        self.view = controller.controller.view
//    }
//
//    init() {}
//}
//
//public final class TableView<P: GUIPlatform> {
//    public init() {}
//}
//
//extension TableView: UIViewControllerRepresentable where P == UIKitPlatform {
//    public var controller: UIViewController {
//        let table = UITableViewController()
//        return table
//    }
//}
