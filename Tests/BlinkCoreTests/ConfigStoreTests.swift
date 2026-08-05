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

    func test_load_falls_back_to_defaults_when_marker_set_but_numeric_keys_unwritten() {
        // Simulates opening Settings (which sets the marker via onAppear/onDisappear)
        // without editing any control, so @AppStorage never writes the numeric keys.
        defaults.set(true, forKey: "blink.hasConfig")

        let reloaded = ConfigStore(defaults: defaults).load()

        XCTAssertEqual(reloaded.shortInterval, 20 * 60)
        XCTAssertEqual(reloaded.shortDuration, 20)
        XCTAssertEqual(reloaded.longInterval, 60 * 60)
        XCTAssertEqual(reloaded.longDuration, 5 * 60)
        XCTAssertEqual(reloaded.preBreakWarning, 10)
        XCTAssertEqual(reloaded.idleThreshold, 2 * 60)
        XCTAssertEqual(reloaded.postponeInterval, 5 * 60)
        XCTAssertEqual(reloaded, BreakConfig())
    }
}
