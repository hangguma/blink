import Foundation

public enum BreakKind: Equatable, Sendable {
    case short
    case long
}

public enum BreakMode: String, Equatable, Sendable, Codable {
    case overlay
    case notification
}

public enum EngineState: Equatable, Sendable {
    case working
    case preBreak(BreakKind)
    case onBreak(BreakKind)
    case paused
}

public struct BreakConfig: Equatable, Sendable {
    public var shortInterval: TimeInterval
    public var shortDuration: TimeInterval
    public var longInterval: TimeInterval
    public var longDuration: TimeInterval
    public var preBreakWarning: TimeInterval
    public var idleThreshold: TimeInterval
    public var postponeInterval: TimeInterval
    public var shortMode: BreakMode
    public var longMode: BreakMode

    public init(
        shortInterval: TimeInterval = 20 * 60,
        shortDuration: TimeInterval = 20,
        longInterval: TimeInterval = 60 * 60,
        longDuration: TimeInterval = 5 * 60,
        preBreakWarning: TimeInterval = 10,
        idleThreshold: TimeInterval = 2 * 60,
        postponeInterval: TimeInterval = 5 * 60,
        shortMode: BreakMode = .notification,
        longMode: BreakMode = .overlay
    ) {
        self.shortInterval = shortInterval
        self.shortDuration = shortDuration
        self.longInterval = longInterval
        self.longDuration = longDuration
        self.preBreakWarning = preBreakWarning
        self.idleThreshold = idleThreshold
        self.postponeInterval = postponeInterval
        self.shortMode = shortMode
        self.longMode = longMode
    }

    public func duration(for kind: BreakKind) -> TimeInterval {
        kind == .short ? shortDuration : longDuration
    }

    public func mode(for kind: BreakKind) -> BreakMode {
        kind == .short ? shortMode : longMode
    }
}

public struct DayStats: Codable, Equatable, Sendable {
    public var date: String
    public var breaksCompleted: Int
    public var breaksSkipped: Int

    public init(date: String = "", breaksCompleted: Int = 0, breaksSkipped: Int = 0) {
        self.date = date
        self.breaksCompleted = breaksCompleted
        self.breaksSkipped = breaksSkipped
    }
}
