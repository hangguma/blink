import Foundation

public final class ConfigStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults) { self.defaults = defaults }

    private enum Key {
        static let shortInterval = "blink.shortInterval"
        static let shortDuration = "blink.shortDuration"
        static let longInterval = "blink.longInterval"
        static let longDuration = "blink.longDuration"
        static let preBreakWarning = "blink.preBreakWarning"
        static let idleThreshold = "blink.idleThreshold"
        static let postponeInterval = "blink.postponeInterval"
        static let shortMode = "blink.shortMode"
        static let longMode = "blink.longMode"
        static let marker = "blink.hasConfig"
    }

    private func number(_ key: String, default fallback: Double) -> Double {
        defaults.object(forKey: key) != nil ? defaults.double(forKey: key) : fallback
    }

    public func load() -> BreakConfig {
        guard defaults.bool(forKey: Key.marker) else { return BreakConfig() }
        var c = BreakConfig()
        c.shortInterval = number(Key.shortInterval, default: c.shortInterval)
        c.shortDuration = number(Key.shortDuration, default: c.shortDuration)
        c.longInterval = number(Key.longInterval, default: c.longInterval)
        c.longDuration = number(Key.longDuration, default: c.longDuration)
        c.preBreakWarning = number(Key.preBreakWarning, default: c.preBreakWarning)
        c.idleThreshold = number(Key.idleThreshold, default: c.idleThreshold)
        c.postponeInterval = number(Key.postponeInterval, default: c.postponeInterval)
        c.shortMode = BreakMode(rawValue: defaults.string(forKey: Key.shortMode) ?? "") ?? c.shortMode
        c.longMode = BreakMode(rawValue: defaults.string(forKey: Key.longMode) ?? "") ?? c.longMode
        return c
    }

    public func save(_ config: BreakConfig) {
        defaults.set(config.shortInterval, forKey: Key.shortInterval)
        defaults.set(config.shortDuration, forKey: Key.shortDuration)
        defaults.set(config.longInterval, forKey: Key.longInterval)
        defaults.set(config.longDuration, forKey: Key.longDuration)
        defaults.set(config.preBreakWarning, forKey: Key.preBreakWarning)
        defaults.set(config.idleThreshold, forKey: Key.idleThreshold)
        defaults.set(config.postponeInterval, forKey: Key.postponeInterval)
        defaults.set(config.shortMode.rawValue, forKey: Key.shortMode)
        defaults.set(config.longMode.rawValue, forKey: Key.longMode)
        defaults.set(true, forKey: Key.marker)
    }
}
