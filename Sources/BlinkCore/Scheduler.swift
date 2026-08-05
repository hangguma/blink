import Foundation

public final class Scheduler {
    private let config: BreakConfig
    private var nextShort: Date
    private var nextLong: Date

    public init(config: BreakConfig, now: Date) {
        self.config = config
        self.nextShort = now.addingTimeInterval(config.shortInterval)
        self.nextLong = now.addingTimeInterval(config.longInterval)
    }

    /// long이 우선. 둘 다 도래하면 long.
    public func dueBreak(at now: Date) -> BreakKind? {
        if now >= nextLong { return .long }
        if now >= nextShort { return .short }
        return nil
    }

    public func timeUntilNextBreak(at now: Date) -> TimeInterval {
        max(0, min(nextShort, nextLong).timeIntervalSince(now))
    }

    /// 브레이크 완료/스킵 후 해당 종류 타이머 리셋. long은 short도 리셋(방금 쉬었으므로).
    public func reschedule(_ kind: BreakKind, from now: Date) {
        switch kind {
        case .short:
            nextShort = now.addingTimeInterval(config.shortInterval)
        case .long:
            nextLong = now.addingTimeInterval(config.longInterval)
            nextShort = now.addingTimeInterval(config.shortInterval)
        }
    }

    /// 미루기: 해당 종류의 다음 발동을 지정 시각으로.
    public func postpone(_ kind: BreakKind, until date: Date) {
        switch kind {
        case .short: nextShort = date
        case .long: nextLong = date
        }
    }

    /// 일시정지(자리 비움) 보정: 모든 타이머를 뒤로 민다.
    public func shift(by interval: TimeInterval) {
        nextShort = nextShort.addingTimeInterval(interval)
        nextLong = nextLong.addingTimeInterval(interval)
    }
}
