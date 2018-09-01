import UIKit

public final class UIKitApplication {
    let window: UIWindow
    
    public var willFinishLaunching: Future<UIApplication> {
        return _AppDelegate.willFinishLaunching.future
    }
    
    public var didLaunch: Future<UIApplication> {
        return _AppDelegate.didLaunch.future
    }
    
    public var willTerminate: Future<UIApplication> {
        return _AppDelegate.didLaunch.future
    }
    
    public var willEnterForeground: ReadStream<UIApplication> {
        return _AppDelegate.willEnterForeground.listener
    }
    
    public var didEnterBackground: ReadStream<UIApplication> {
        return _AppDelegate.didEnterBackground.listener
    }
    
    public func setRootView(to controller: UIViewController) {
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }
    
    public init() {
        window = UIWindow(frame: UIScreen.main.bounds)
    }
    
    public func start() -> Never {
        var argv = CommandLine.unsafeArgv.pointee!
        
        UIApplicationMain(
            CommandLine.argc,
            &argv,
            nil,
            NSStringFromClass(_AppDelegate.self)
        )
        
        while true { sleep(.max) }
    }
}

public typealias UIApplicationLaunchOptions = [UIApplicationLaunchOptionsKey : Any]?

internal final class _AppDelegate: UIResponder, UIApplicationDelegate {
    static let willFinishLaunching = Promise<UIApplication>()
    static let didLaunch = Promise<UIApplication>()
    static let willTerminate = Promise<UIApplication>()
    static let didEnterBackground = WriteStream<UIApplication>()
    static let willEnterForeground = WriteStream<UIApplication>()
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: UIApplicationLaunchOptions = nil) -> Bool {
        _AppDelegate.willFinishLaunching.complete(application)
        return true
    }
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        _AppDelegate.didLaunch.complete(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        _AppDelegate.willTerminate.complete(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        _AppDelegate.willEnterForeground.next(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        _AppDelegate.didEnterBackground.next(application)
    }
}
