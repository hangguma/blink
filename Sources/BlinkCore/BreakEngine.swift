import Foundation

public final class BreakEngine {
    public private(set) var state: EngineState = .working {
        didSet {
            if state != oldValue { onStateChange?(state) }
        }
    }

    public var onStateChange: ((EngineState) -> Void)?
    public var onBreakCompleted: (() -> Void)?
    public var onBreakSkipped: (() -> Void)?

    private let config: BreakConfig
    private let clock: Clock
    private let scheduler: Scheduler
    private var phaseEndsAt: Date?
    private var pausedAt: Date?

    public init(config: BreakConfig, clock: Clock) {
        self.config = config
        self.clock = clock
        self.scheduler = Scheduler(config: config, now: clock.now)
    }

    // MARK: 조회 (UI용)

    public func timeUntilNextBreak() -> TimeInterval {
        scheduler.timeUntilNextBreak(at: clock.now)
    }

    public func phaseRemaining() -> TimeInterval {
        guard let end = phaseEndsAt else { return 0 }
        return max(0, end.timeIntervalSince(clock.now))
    }

    public func currentBreakKind() -> BreakKind? {
        switch state {
        case .preBreak(let k), .onBreak(let k): return k
        default: return nil
        }
    }

    // MARK: tick

    public func update() {
        let now = clock.now
        switch state {
        case .working:
            if let kind = scheduler.dueBreak(at: now) {
                enterPreBreak(kind, now: now)
            }
        case .preBreak(let kind):
            if now >= (phaseEndsAt ?? now) {
                enterOnBreak(kind, now: now)
            }
        case .onBreak(let kind):
            if now >= (phaseEndsAt ?? now) {
                completeBreak(kind, now: now)
            }
        case .paused:
            break
        }
    }

    // MARK: 사용자 액션

    public func skipCurrent() {
        guard let kind = currentBreakKind() else { return }
        scheduler.reschedule(kind, from: clock.now)
        phaseEndsAt = nil
        onBreakSkipped?()
        state = .working
    }

    public func postponeCurrent() {
        guard let kind = currentBreakKind() else { return }
        scheduler.postpone(kind, until: clock.now.addingTimeInterval(config.postponeInterval))
        phaseEndsAt = nil
        state = .working
    }

    public func startBreakNow() {
        enterOnBreak(.short, now: clock.now)
    }

    // MARK: 일시정지 (Task 5에서 테스트)

    public func pause() {
        guard state == .working else { return }
        pausedAt = clock.now
        state = .paused
    }

    public func resume() {
        guard state == .paused, let since = pausedAt else { return }
        scheduler.shift(by: clock.now.timeIntervalSince(since))
        pausedAt = nil
        state = .working
    }

    // MARK: 내부 전이

    private func enterPreBreak(_ kind: BreakKind, now: Date) {
        phaseEndsAt = now.addingTimeInterval(config.preBreakWarning)
        state = .preBreak(kind)
    }

    private func enterOnBreak(_ kind: BreakKind, now: Date) {
        phaseEndsAt = now.addingTimeInterval(config.duration(for: kind))
        state = .onBreak(kind)
    }

    private func completeBreak(_ kind: BreakKind, now: Date) {
        scheduler.reschedule(kind, from: now)
        phaseEndsAt = nil
        onBreakCompleted?()
        state = .working
    }
}
