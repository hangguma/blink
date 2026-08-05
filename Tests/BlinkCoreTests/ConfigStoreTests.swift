import XCTest
@testable import BlinkCore

final class ConfigStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "blink-configstore-test"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func test_load_returns_defaults_when_empty() {
        let store = ConfigStore(defaults: defaults)
        XCTAssertEqual(store.load(), BreakConfig())
    }

    func test_save_then_load_roundtrips() {
        let store = ConfigStore(defaults: defaults)
        var c = BreakConfig()
        c.shortInterval = 25 * 60
        c.shortMode = .overlay
        c.longMode = .notification
        store.save(c)

        let reloaded = ConfigStore(defaults: defaults).load()
        XCTAssertEqual(reloaded.shortInterval, 25 * 60)
        XCTAssertEqual(reloaded.shortMode, .overlay)
        XCTAssertEqual(reloaded.longMode, .notification)
    }
}
