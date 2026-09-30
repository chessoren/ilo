import XCTest

final class SmokeTests: XCTestCase {
    @MainActor func testLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
