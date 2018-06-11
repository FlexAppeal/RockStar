import Rockstar

final class AppState: ApplicationState, NavigationState {
    static var `default` = AppState()
    private init() {}
    
    static var navigatorPath: WritableKeyPath<AppState, NavigationController?> = \.navigator
    
    let store = MemoryStore<Post>(source: PostSource(using: URLSession(configuration: .default)))
    var navigator: NavigationController?
}
