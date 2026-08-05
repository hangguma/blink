import Foundation

public final class ConfigStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults) { self.defaults = defaults }
    public func load() -> BreakConfig { BreakConfig() }
    public func save(_ config: BreakConfig) {}
}
