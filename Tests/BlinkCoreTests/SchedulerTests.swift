import XCTest
@testable import BlinkCore

final class SchedulerTests: XCTestCase {
    private func makeScheduler() -> (Scheduler, TestClock) {
        let clock = TestClock()
        return (Scheduler(config: BreakConfig(), now: clock.now), clock)
    }

    func test_no_break_due_before_shortInterval() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 19 * 60)
        XCTAssertNil(s.dueBreak(at: clock.now))
    }

    func test_short_due_at_20min() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 20 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .short)
    }

    func test_long_takes_precedence_at_60min() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 60 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .long)
    }

    func test_timeUntilNextBreak_counts_down() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 5 * 60)
        XCTAssertEqual(s.timeUntilNextBreak(at: clock.now), 15 * 60, accuracy: 0.001)
    }

    func test_reschedule_short_pushes_next_short() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 20 * 60)
        s.reschedule(.short, from: clock.now)
        XCTAssertNil(s.dueBreak(at: clock.now))
        clock.advance(by: 20 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .short)
    }

    func test_reschedule_long_also_resets_short() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 60 * 60)
        s.reschedule(.long, from: clock.now)
        // 직후 20분 지점에 short 뜨는지 (long이 short도 리셋했으므로)
        clock.advance(by: 20 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .short)
    }

    func test_postpone_long_also_pushes_stale_short() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 60 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .long)

        s.postpone(.long, until: clock.now.addingTimeInterval(5 * 60))

        // 미룬 직후엔 아무것도 도래하면 안 된다 (stale nextShort도 함께 밀렸어야 함)
        XCTAssertNil(s.dueBreak(at: clock.now))

        clock.advance(by: 5 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .long)
    }

    func test_shift_moves_timers_forward() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 20 * 60)
        s.shift(by: 30 * 60)          // 자리 비움 30분 보정
        XCTAssertNil(s.dueBreak(at: clock.now))
    }
}
