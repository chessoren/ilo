import XCTest

/// d. Every core module in isolation (`-demoLesson -demoModule <type> -demoSkipIntro`): interact and expect feedback.
final class ModulesE2ETests: IloUITestCase {
    private func run(_ type: String, graded: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        launch(["-skipOnboarding", "-unlockPro", "-demoLesson", "-demoModule", type, "-demoSkipIntro", "-demoDelay", "0.3"])
        let header = element("module-\(type)")
        waitFor(header, timeout: 20, "\(type) never appeared", file: file, line: line)
        playCurrentModule(shotPrefix: "50-\(type)")
        if graded {
            let appeared = feedbackContinue.waitForExistence(timeout: 12)
            if !appeared { shot("FAIL-\(type)-no-feedback") }
            XCTAssertTrue(appeared, "\(type): feedback panel did not appear", file: file, line: line)
            pause(1.0)
            shot("51-\(type)-feedback")
            tap(feedbackContinue)
        }
        // A one-module lesson ends in the celebration.
        let done = button("celebration-continue")
        let reachedEnd = done.waitForExistence(timeout: 12) || feedbackContinue.exists
        XCTAssertTrue(reachedEnd, "\(type): lesson did not finish", file: file, line: line)
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
