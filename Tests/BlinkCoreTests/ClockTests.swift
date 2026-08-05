import XCTest
@testable import BlinkCore

final class ClockTests: XCTestCase {
    func test_testClock_advances() {
        let clock = TestClock(Date(timeIntervalSince1970: 0))
        XCTAssertEqual(clock.now.timeIntervalSince1970, 0)
        clock.advance(by: 90)
        XCTAssertEqual(clock.now.timeIntervalSince1970, 90)
    }

    func test_defaultConfig_values() {
        let c = BreakConfig()
        XCTAssertEqual(c.shortInterval, 20 * 60)
        XCTAssertEqual(c.shortDuration, 20)
        XCTAssertEqual(c.longInterval, 60 * 60)
        XCTAssertEqual(c.longDuration, 5 * 60)
        XCTAssertEqual(c.preBreakWarning, 10)
        XCTAssertEqual(c.idleThreshold, 2 * 60)
        XCTAssertEqual(c.postponeInterval, 5 * 60)
        XCTAssertEqual(c.shortMode, .notification)
        XCTAssertEqual(c.longMode, .overlay)
    }
}
