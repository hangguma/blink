import XCTest
@testable import BlinkCore

final class BreakEngineTests: XCTestCase {
    private func make() -> (BreakEngine, TestClock) {
        let clock = TestClock()
        return (BreakEngine(config: BreakConfig(), clock: clock), clock)
    }

    func test_starts_working() {
        let (e, _) = make()
        XCTAssertEqual(e.state, .working)
    }

    func test_enters_preBreak_short_after_20min() {
        let (e, clock) = make()
        clock.advance(by: 20 * 60); e.update()
        XCTAssertEqual(e.state, .preBreak(.short))
    }

    func test_preBreak_transitions_to_onBreak_after_warning() {
        let (e, clock) = make()
        clock.advance(by: 20 * 60); e.update()
        clock.advance(by: 10); e.update()
        XCTAssertEqual(e.state, .onBreak(.short))
    }

    func test_onBreak_completes_to_working_and_fires_completed() {
        let (e, clock) = make()
        var completed = 0
        e.onBreakCompleted = { completed += 1 }
        clock.advance(by: 20 * 60); e.update()   // preBreak
        clock.advance(by: 10); e.update()        // onBreak
        clock.advance(by: 20); e.update()        // shortDuration 경과
        XCTAssertEqual(e.state, .working)
        XCTAssertEqual(completed, 1)
    }

    func test_skip_returns_to_working_and_fires_skipped() {
        let (e, clock) = make()
        var skipped = 0
        e.onBreakSkipped = { skipped += 1 }
        clock.advance(by: 20 * 60); e.update()
        e.skipCurrent()
        XCTAssertEqual(e.state, .working)
        XCTAssertEqual(skipped, 1)
    }

    func test_postpone_reschedules_without_skip() {
        let (e, clock) = make()
        var skipped = 0
        e.onBreakSkipped = { skipped += 1 }
        clock.advance(by: 20 * 60); e.update()   // preBreak(.short)
        e.postponeCurrent()
        XCTAssertEqual(e.state, .working)
        XCTAssertEqual(skipped, 0)
        e.update()
        XCTAssertEqual(e.state, .working)         // 아직 도래 안 함
        clock.advance(by: 5 * 60); e.update()     // postponeInterval 뒤
        XCTAssertEqual(e.state, .preBreak(.short))
    }

    func test_startBreakNow_enters_onBreak_short() {
        let (e, _) = make()
        e.startBreakNow()
        XCTAssertEqual(e.state, .onBreak(.short))
    }

    func test_currentBreakKind_reflects_state() {
        let (e, clock) = make()
        XCTAssertNil(e.currentBreakKind())
        clock.advance(by: 60 * 60); e.update()    // preBreak(.long)
        XCTAssertEqual(e.currentBreakKind(), .long)
    }

    func test_onStateChange_fires_on_transition() {
        let (e, clock) = make()
        var seen: [EngineState] = []
        e.onStateChange = { seen.append($0) }
        clock.advance(by: 20 * 60); e.update()
        XCTAssertEqual(seen, [.preBreak(.short)])
    }
}
