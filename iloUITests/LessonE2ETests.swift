import XCTest

/// b. Path → current node → Start → curated salsa lesson → celebration → back on the path with node 1 done.
final class LessonE2ETests: IloUITestCase {
    /// Onboarding shortcut: jump to path building with pre-filled answers ("Salsa for my grandma's wedding"),
    /// Pro unlocked so we land on the main tabs.
    func onboardFast() {
        launch(["-resetOnboarding", "-unlockPro", "-onboardingStep", "12"])
        let ready = button("path-ready")
        waitFor(ready, timeout: 90, "Path never finished building")
        tap(ready)
        let hold = waitFor(element("commit-hold"))
        hold.press(forDuration: 2.6)
        waitFor(mainTabs, timeout: 20, "Main tabs never appeared")
    }

    func testPlayFirstLessonFromPath() {
        onboardFast()

        tap(element("home-hero"))
        let node0 = element("node-0")
        waitFor(node0, timeout: 10, "Path did not open")
        pause(1.5)
        shot("20-path")
        XCTAssertEqual(node0.value as? String, "current")

        tap(node0)
        let start = button("node-start")
        waitFor(start)
        pause(0.8)
        shot("21-node-popover")
        tap(start)

        // Loading → intro
        let begin = button("lesson-start")
        waitFor(begin, timeout: 60, "Lesson never loaded")
        pause(1.2)
        shot("22-lesson-intro")
        tap(begin)

        let played = playLessonToEnd(maxSteps: 40, shotPrefix: "23-module")
        print("Played modules: \(played)")
        finishCelebration(shotPrefix: "24")

        // Back on the path: node 0 completed, node 1 current.
        let n0 = element("node-0")
        waitFor(n0, timeout: 10, "Did not return to the path")
        pause(2.0)
        shot("25-path-after-lesson")
        XCTAssertEqual(n0.value as? String, "completed")
        XCTAssertEqual(element("node-1").value as? String, "current")
    }
}
