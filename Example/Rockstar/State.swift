import Rockstar

final class AppState: ApplicationState, NavigationState {
    static var `default` = AppState()
    private init() {}
    
    static var navigatorPath: WritableKeyPath<AppState, NavigationController?> = \.navigator
    
    var navigator: NavigationController?
}
