import XCTest

/// Shared helpers for ilo's end-to-end UI tests.
///
/// Screenshots are attached to the test result (kept always) and also written as PNGs to `ILO_E2E_SHOTS`
/// (defaults to the agent scratchpad folder) so they can be reviewed without opening the .xcresult.
@MainActor
class IloUITestCase: XCTestCase {
    var app = XCUIApplication()

    static let shotDir: URL = {
        let env = ProcessInfo.processInfo.environment["ILO_E2E_SHOTS"]
        let path = env ?? "/private/tmp/claude-501/-Users-oren-ilo-app/fbeea653-4671-44a4-bee6-080428aa02eb/scratchpad/e2e"
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    override nonisolated func setUpWithError() throws {
        continueAfterFailure = false
    }

    func launch(_ arguments: [String]) {
        app = XCUIApplication()
        app.launchArguments = arguments + ["-noStore"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20), "app did not launch")
    }

    /// Attaches a screenshot and writes it to the shots folder.
    func shot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let file = Self.shotDir.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: file)
    }

    // MARK: Queries

    func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func button(_ id: String) -> XCUIElement {
        app.buttons.matching(identifier: id).firstMatch
    }

    @discardableResult
    func waitFor(_ element: XCUIElement, timeout: TimeInterval = 10, _ message: String? = nil,
                 file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        if !element.waitForExistence(timeout: timeout) {
            shot("FAIL-\(name.replacingOccurrences(of: " ", with: "_"))-\(line)")
            XCTFail(message ?? "Timed out waiting for \(element)", file: file, line: line)
        }
        return element
    }

    /// Waits until the element exists, is hittable and enabled, then taps it.
    func tap(_ element: XCUIElement, timeout: TimeInterval = 10, _ message: String? = nil,
             file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable && element.isEnabled {
                element.tap()
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        shot("FAIL-\(name.replacingOccurrences(of: " ", with: "_"))-\(line)")
        XCTFail(message ?? "Not tappable in time: \(element)", file: file, line: line)
    }

    func pause(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// True when `element` becomes hittable within `timeout` (no failure).
    func appears(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists && element.isHittable { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return false
    }

    var mainTabs: XCUIElement { app.tabBars.buttons["Home"] }
}
