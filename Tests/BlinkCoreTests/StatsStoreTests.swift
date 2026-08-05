import XCTest
@testable import BlinkCore

final class StatsStoreTests: XCTestCase {
    private var tmpURL: URL!

    override func setUp() {
        super.setUp()
        tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("blink-test-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tmpURL)
        super.tearDown()
    }

    func test_starts_empty_for_today() {
        let now = Date(timeIntervalSince1970: 0)
        let store = StatsStore(fileURL: tmpURL, now: now)
        XCTAssertEqual(store.today.breaksCompleted, 0)
        XCTAssertEqual(store.today.breaksSkipped, 0)
    }

    func test_records_and_persists() {
        let now = Date(timeIntervalSince1970: 0)
        let store = StatsStore(fileURL: tmpURL, now: now)
        store.recordCompleted(now: now)
        store.recordCompleted(now: now)
        store.recordSkipped(now: now)
        XCTAssertEqual(store.today.breaksCompleted, 2)
        XCTAssertEqual(store.today.breaksSkipped, 1)

        // 같은 날 재로드 시 유지
        let reloaded = StatsStore(fileURL: tmpURL, now: now)
        XCTAssertEqual(reloaded.today.breaksCompleted, 2)
        XCTAssertEqual(reloaded.today.breaksSkipped, 1)
    }

    func test_resets_on_new_day() {
        let day1 = Date(timeIntervalSince1970: 0)                 // 1970-01-01
        let store = StatsStore(fileURL: tmpURL, now: day1)
        store.recordCompleted(now: day1)

        let day2 = Date(timeIntervalSince1970: 60 * 60 * 24 * 2)  // 이틀 뒤
        let reloaded = StatsStore(fileURL: tmpURL, now: day2)
        XCTAssertEqual(reloaded.today.breaksCompleted, 0)         // 새 날 → 리셋
    }

    func test_corrupt_file_starts_empty() {
        try? "garbage".data(using: .utf8)!.write(to: tmpURL)
        let store = StatsStore(fileURL: tmpURL, now: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(store.today.breaksCompleted, 0)
    }
}
