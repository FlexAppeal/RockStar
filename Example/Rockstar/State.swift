import Rockstar

final class UIKitAppState: ApplicationState {
    typealias Platform = UIKitPlatform
    
    static var `default` = UIKitAppState()
    private init() {}
    
//    let postStore = try! PostSource().memoryStore
    var currentNavigator: UIKitPlatform.NavigatorType?
}
