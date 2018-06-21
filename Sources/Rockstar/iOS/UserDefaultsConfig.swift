import Foundation

public struct UserDefaultsConfig: Configuration {
    public let defaults: UserDefaults
    
    public init(_ defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}
