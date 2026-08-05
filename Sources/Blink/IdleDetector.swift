import CoreGraphics
import Foundation

enum IdleDetector {
    /// 마지막 입력(키/마우스) 이후 경과 초.
    static func idleSeconds() -> TimeInterval {
        let anyInput = CGEventType(rawValue: ~0)!
        return CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInput)
    }
}
