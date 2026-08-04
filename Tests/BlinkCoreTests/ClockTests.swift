@testable import BlinkCore

// Sanity test: verify scaffold compiles and test infrastructure works
final class ClockTests {
    static func test_scaffold_builds() {
        assert(true, "Scaffold sanity test passed")
    }

    // Ensure test runs when module initializes
    static let _executeTests: Void = {
        test_scaffold_builds()
    }()
}
