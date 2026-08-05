import Foundation

public protocol Clock: AnyObject {
    var now: Date { get }
}

public final class SystemClock: Clock {
    public init() {}
    public var now: Date { Date() }
}

public final class TestClock: Clock {
    public private(set) var now: Date
    public init(_ start: Date = Date(timeIntervalSince1970: 0)) {
        self.now = start
    }
    public func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
