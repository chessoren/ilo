import XCTest

/// d. Every core module in isolation (`-demoLesson -demoModule <type> -demoSkipIntro`): interact and expect feedback.
final class ModulesE2ETests: IloUITestCase {
    private func run(_ type: String, graded: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        launch(["-skipOnboarding", "-unlockPro", "-demoLesson", "-demoModule", type, "-demoSkipIntro", "-demoDelay", "0.3"])
        let header = element("module-\(type)")
        waitFor(header, timeout: 20, "\(type) never appeared", file: file, line: line)
        playCurrentModule(shotPrefix: "50")
        if graded {
            let appeared = feedbackContinue.waitForExistence(timeout: 12)
            if !appeared { shot("FAIL-\(type)-no-feedback") }
            XCTAssertTrue(appeared, "\(type): feedback panel did not appear", file: file, line: line)
            pause(1.0)
            shot("51-\(type)-feedback")
            tap(feedbackContinue)
        }
        // A missed question comes back once at the end (Duolingo-style retry); play it, then the lesson ends.
        pause(1.0)
        playLessonToEnd(maxSteps: 6)
        XCTAssertTrue(button("celebration-continue").waitForExistence(timeout: 12), "\(type): lesson did not finish",
                      file: file, line: line)
        // Leave the app idle on its root screen before teardown.
        finishCelebration()
    }

    func testStoryCards() { run("storyCards", graded: false) }
    func testAudioLesson() { run("audioLesson", graded: false) }
    func testFlashcards() { run("flashcards", graded: false) }
    func testMultipleChoice() { run("multipleChoice") }
    func testTrueFalse() { run("trueFalse") }
    func testMatchPairs() { run("matchPairs") }
    func testReorder() { run("reorder") }
    func testWordBricks() { run("wordBricks") }
    func testFillBlank() { run("fillBlank") }
    func testEstimate() { run("estimate") }
    func testSpotTheMistake() { run("spotTheMistake") }
    func testCategorize() { run("categorize") }
    func testSpeedRound() { run("speedRound") }
    func testScenario() { run("scenario") }
    func testHighlight() { run("highlight") }
}
