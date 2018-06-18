import Foundation

public struct UserDefaultsConfig: Configuration {
    let defaults: UserDefaults
    
    init(_ defaults: UserDefaults) {
        self.defaults = defaults
    }
}
