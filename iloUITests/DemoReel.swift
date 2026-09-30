import XCTest

/// Scripted, human-paced walkthrough used to record the submission demo video (docs/SUBMISSION.md "Video script").
///
/// Not a regression test: it favours pacing (pauses so a viewer can read, smooth scrolls, character-by-character
/// typing) over speed. Run it while `xcrun simctl io <id> recordVideo` is capturing the simulator; every scene start
/// is logged as `<label> <epoch seconds>` to `reel-markers.txt` in the shots folder so the recording can be cut
/// automatically afterwards.
///
/// Story: fresh install → onboarding → path building → commit → paywall → home → path → first lesson (answers
/// correctly) → celebration → Leagues / Quests / Profile → Create "Code my first website" → Home,
/// then two short relaunches: the salsa metronome (practice timer) and the code lab with live preview.
final class DemoReelTests: IloUITestCase {
    private static let markerURL = shotDir.appendingPathComponent("reel-markers.txt")

    private func mark(_ label: String) {
        let line = String(format: "%@ %.3f\n", label, Date().timeIntervalSince1970)
        if let handle = try? FileHandle(forWritingTo: Self.markerURL) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? Data(line.utf8).write(to: Self.markerURL)
        }
    }

    // MARK: Human-like helpers

    /// Types word by word (XCUITest types each chunk key by key, so it reads as live typing).
    private func typeSlowly(_ text: String, into field: XCUIElement) {
        var chunk = ""
        for ch in text {
            chunk.append(ch)
            if ch == " " || ch == "\n" {
                field.typeText(chunk)
                chunk = ""
            }
        }
        if !chunk.isEmpty { field.typeText(chunk) }
    }

    private func point(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
    }

    /// A slow finger drag (reads as a smooth scroll on video).
    private func drag(from: (CGFloat, CGFloat), to: (CGFloat, CGFloat), velocity: CGFloat = 700) {
        point(from.0, from.1).press(forDuration: 0.05, thenDragTo: point(to.0, to.1),
                                    withVelocity: XCUIGestureVelocity(velocity), thenHoldForDuration: 0.15)
    }

    private func smoothScrollUp(_ amount: CGFloat = 0.35) { drag(from: (0.5, 0.72), to: (0.5, 0.72 - amount)) }
    private func smoothScrollDown(_ amount: CGFloat = 0.35) { drag(from: (0.5, 0.3), to: (0.5, 0.3 + amount)) }

    private func tab(_ name: String) -> XCUIElement {
        let inBar = app.tabBars.buttons[name]
        return inBar.exists ? inBar : app.buttons[name]
    }

    // MARK: The reel

    /// Only runs when recording the reel: `TEST_RUNNER_ILO_REEL=1 xcodebuild test … -only-testing:iloUITests/DemoReelTests`.
    func testDemoReel() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ILO_REEL"] == "1", "Demo reel runs only when recording")
        try? FileManager.default.removeItem(at: Self.markerURL)
        mark("launch")
        launch(["-resetOnboarding", "-resetPro"])
        onboarding()
        buildingCommitPaywall()
        firstLesson()
        tour()
        create()
        metronome()
        codeLab()
        mark("end")
        // Keep the app on screen until the recorder has stopped (it writes `reel-stop` next to the markers):
        // the simulator may be shut down when the test ends, which would corrupt an unfinished recording.
        let stop = Self.shotDir.appendingPathComponent("reel-stop")
        let deadline = Date().addingTimeInterval(Double(ProcessInfo.processInfo.environment["REEL_HOLD"] ?? "") ?? 120)
        while Date() < deadline && !FileManager.default.fileExists(atPath: stop.path) { pause(0.5) }
        try? FileManager.default.removeItem(at: stop)
    }

    private func onboarding() {
        // Splash (mascot morph) → Welcome
        let start = button("welcome-start")
        waitFor(element("splash"), timeout: 15)
        mark("splash")
        if !appears(start, timeout: 9) { tap(element("splash")) }
        waitFor(start, timeout: 10)
        mark("welcome")
        pause(1.6)
        tap(start)

        let cta = button("onboarding-continue")
        mark("howItWorks")
        pause(2.2)
        tap(cta)

        // Goal, typed like a human
        let field = waitFor(element("goal-field"))
        mark("goal")
        pause(0.8)
        field.tap()
        pause(0.4)
        typeSlowly("Salsa for my grandma's wedding", into: field)
        pause(1.2)
        tap(cta)

        let choices = app.buttons.matching(identifier: "choice")
        // Why
        mark("why")
        pause(1.2)
        tap(choices.element(boundBy: 0))
        pause(0.8)
        tap(cta)
        // Deadline
        mark("deadline")
        pause(1.2)
        tap(choices.element(boundBy: 1)) // "In a month"
        pause(0.9)
        tap(cta)
        // Level
        mark("level")
        pause(1.0)
        tap(choices.element(boundBy: 0))
        pause(0.7)
        tap(cta)
        // Styles (multi-select)
        mark("styles")
        pause(1.0)
        tap(choices.element(boundBy: 0))
        pause(0.5)
        tap(choices.element(boundBy: 2))
        pause(0.8)
        tap(cta)
        // Minutes a day
        mark("minutes")
        pause(1.0)
        tap(choices.element(boundBy: 1))
        pause(0.8)
        tap(cta)

        // Name
        let name = waitFor(element("name-field"))
        mark("name")
        pause(0.6)
        name.tap()
        typeSlowly("Sophia", into: name)
        pause(0.8)
        tap(cta)

        // bloub maker: second shape, then the purple colour
        mark("bloub")
        pause(1.4)
        point(0.32, 0.645).tap()
        pause(1.0)
        point(0.423, 0.846).tap()
        pause(1.6)
        tap(cta)

        // Reminders → Not now
        mark("reminders")
        pause(1.6)
        tap(app.buttons["Not now"])
    }

    private func buildingCommitPaywall() {
        mark("building")
        let ready = button("path-ready")
        waitFor(ready, timeout: 90, "Path never finished building")
        mark("pathReady")
        pause(1.2)
        smoothScrollUp(0.3)
        pause(1.0)
        smoothScrollDown(0.3)
        pause(0.6)
        tap(ready)

        // Commit: press and hold
        let hold = waitFor(element("commit-hold"))
        mark("commit")
        pause(1.8)
        hold.press(forDuration: 2.8)

        // Paywall page 1 → page 2 → start trial
        let next = button("paywall-next")
        waitFor(next, timeout: 15, "Paywall did not appear after commit")
        mark("paywall1")
        pause(2.4)
        tap(next)
        let buy = button("paywall-cta")
        waitFor(buy)
        mark("paywall2")
        pause(2.6)
        tap(buy)
        mark("purchase")

        if !appears(mainTabs, timeout: 10) {
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            for label in ["Subscribe", "Confirm", "Buy", "OK"] {
                let b = springboard.buttons[label]
                if b.exists { pause(0.8); b.tap(); pause(1) }
                let inApp = app.buttons[label]
                if inApp.exists && inApp.isHittable { pause(0.8); inApp.tap(); pause(1) }
            }
        }
        if !appears(mainTabs, timeout: 12) {
            let logo = element("paywall-logo")
            if logo.exists { logo.press(forDuration: 2.0) }
        }
        waitFor(mainTabs, timeout: 20, "Main tabs never appeared after purchase")
        mark("home")
        pause(2.2)
    }

    // MARK: Lesson

    /// Correct answers for the curated "Meet salsa" lesson (substring of the right option / statement → truth).
    private let correctOptions = ["Sauce", "Join in", "8", "Your systems", "smaller steps", "quick-quick-slow"]
    private let statements: [(String, Bool)] = [
        ("roots in Cuban", true), ("every single beat", false), ("need a partner", false),
        ("step on beat 4", false), ("step on beat 5", true), ("step on beat 8", false), ("has 8 beats", true),
        ("Steps 1 and 2 are quick", true),
    ]
    private let pairs: [String: String] = [
        "Salsa": "Spanish for 'sauce'", "Cuban son": "One of salsa's musical roots",
        "New York": "Where the name 'salsa' took off", "8": "Counts in one salsa phrase",
    ]

    private func firstLesson() {
        tap(element("home-hero"))
        let node0 = element("node-0")
        waitFor(node0, timeout: 10, "Path did not open")
        mark("path")
        pause(1.6)
        tap(node0)
        let start = button("node-start")
        waitFor(start)
        pause(1.4)
        tap(start)

        let begin = button("lesson-start")
        waitFor(begin, timeout: 60, "Lesson never loaded")
        mark("lessonIntro")
        pause(2.0)
        tap(begin)

        let celebration = button("celebration-continue")
        var index = 0
        for _ in 0..<30 {
            if celebration.exists { break }
            if feedbackContinue.exists && feedbackContinue.isHittable {
                pause(1.8) // read the feedback
                feedbackContinue.tap()
                pause(0.8)
                continue
            }
            guard let type = currentModuleType() else { pause(0.5); continue }
            mark("module\(index)-\(type)")
            index += 1
            playNicely(type)
            let deadline = Date().addingTimeInterval(8)
            while Date() < deadline {
                if feedbackContinue.exists || celebration.exists { break }
                if let now = currentModuleType(), now != type { break }
                pause(0.3)
            }
        }
        waitFor(celebration, timeout: 10, "Lesson did not reach the celebration")
        mark("celebration")
        var step = 0
        while celebration.exists && step < 8 {
            mark("celebration\(step)")
            pause(2.6) // count-ups, confetti, streak flame
            if celebration.isHittable { celebration.tap() }
            step += 1
            pause(0.6)
        }
        waitFor(element("node-0"), timeout: 10, "Did not return to the path")
        mark("pathAfter")
        pause(2.4)
    }

    private func playNicely(_ type: String) {
        pause(1.0) // entrance animation + let the viewer read the prompt
        switch type {
        case "storyCards":
            let done = button("module-done")
            for _ in 0..<10 where !done.exists {
                pause(1.5)
                point(0.8, 0.5).tap()
            }
            pause(0.6)
            tap(done)

        case "multipleChoice", "scenario", "fillBlank":
            pause(1.4)
            tap(correctAnswer() ?? button("answer-0"))
            pause(0.9)
            tap(checkButton)

        case "trueFalse":
            let t = button("tf-true")
            for _ in 0..<6 where !feedbackContinue.exists {
                guard t.waitForExistence(timeout: 2) else { break }
                pause(1.4)
                let truth = currentStatementTruth() ?? true
                drag(from: (0.5, 0.58), to: (truth ? 0.95 : 0.05, 0.6), velocity: 900)
                pause(0.7)
            }

        case "matchPairs":
            pause(0.4)
            playPairs()

        case "flashcards":
            let gotIt = button("flash-gotit")
            let done = button("module-done")
            // Flip the first card to show the back, then breeze through the rest.
            point(0.5, 0.45).tap()
            pause(1.3)
            for _ in 0..<8 where !done.exists {
                guard gotIt.exists else { break }
                gotIt.tap()
                pause(0.5)
            }
            tap(done)

        default:
            playCurrentModule()
        }
    }

    private func correctAnswer() -> XCUIElement? {
        for i in 0..<6 {
            let b = button("answer-\(i)")
            guard b.exists else { break }
            let label = b.label
            if correctOptions.contains(where: { opt in
                opt.count <= 2 ? label.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains(Substring(opt))
                               : label.localizedCaseInsensitiveContains(opt)
            }) { return b }
        }
        return nil
    }

    private func currentStatementTruth() -> Bool? {
        for (text, truth) in statements {
            let q = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
            let direct = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
            if (direct.exists && direct.isHittable) || (q.exists && q.isHittable) { return truth }
        }
        return nil
    }

    private func playPairs() {
        var lefts: [XCUIElement] = []
        var rights: [XCUIElement] = []
        for i in 0..<10 {
            let l = button("match-L-\(i)"), r = button("match-R-\(i)")
            if l.exists { lefts.append(l) }
            if r.exists { rights.append(r) }
        }
        for left in lefts {
            guard left.isEnabled else { continue }
            let target = pairs[left.label]
            let right = rights.first { $0.isEnabled && target != nil && $0.label == target }
            if let right {
                left.tap(); pause(0.35); right.tap(); pause(0.8)
            } else {
                // Unknown content: brute force.
                for r in rights where left.isEnabled && r.isEnabled {
                    left.tap(); r.tap(); pause(0.75)
                }
            }
        }
    }

    // MARK: Tabs

    private func tour() {
        tap(tab("Leagues"))
        mark("leagues")
        pause(1.8)
        smoothScrollUp(0.3)
        pause(1.2)
        smoothScrollDown(0.5) // back to the top: the tab bar minimises while scrolled
        pause(0.5)

        tap(tab("Quests"))
        mark("quests")
        pause(2.2)
        let claim = button("quest-claim")
        if claim.exists && claim.isHittable {
            claim.tap()
            pause(1.8)
        }

        tap(tab("Profile"))
        mark("profile")
        pause(1.8)
        smoothScrollUp(0.3)
        pause(1.2)
        smoothScrollDown(0.5)
        pause(0.5)
    }

    private func create() {
        tap(tab("Create"))
        let field = waitFor(element("create-goal-field"))
        mark("create")
        pause(1.0)
        field.tap()
        pause(0.3)
        typeSlowly("Code my first website", into: field)
        pause(0.6)
        app.staticTexts["New path"].firstMatch.tap() // dismiss keyboard
        pause(0.5)
        tap(button("create-build"))
        mark("createBuilding")
        let ready = button("path-ready")
        waitFor(ready, timeout: 120, "Create: path never finished building")
        mark("createReady")
        pause(1.6)
        tap(ready)
        waitFor(element("node-0"), timeout: 15)
        mark("createPath")
        pause(1.8)
        tap(tab("Home"))
        mark("homeEnd")
        pause(3.5)
    }

    // MARK: Relaunches: real-world modules

    private func metronome() {
        launch(["-skipOnboarding", "-unlockPro", "-demoLesson", "-demoModule", "practiceTimer", "-demoSkipIntro", "-demoDelay", "0.3"])
        waitFor(element("module-practiceTimer"), timeout: 20)
        mark("metronome")
        pause(1.2)
        tap(app.buttons["Start practice"])
        mark("metronomeRunning")
        pause(7.5)
        mark("metronomeEnd")
    }

    private func codeLab() {
        launch(["-skipOnboarding", "-unlockPro", "-demoLesson", "-demoModule", "codeLab", "-demoSkipIntro", "-demoDelay", "0.3"])
        waitFor(element("module-codeLab"), timeout: 20)
        mark("codeLab")
        pause(1.5)
        let editor = app.textViews.firstMatch
        tap(editor)
        pause(0.3)
        // Replace the starter with our own code, typed live.
        editor.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
            pause(0.2)
            editor.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        typeSlowly("<h1>Hello</h1>\n<button>Start</button>", into: editor)
        pause(0.8)
        mark("codePreview")
        tap(app.buttons["Preview"])
        pause(2.6)
        tap(checkButton)
        mark("codeCheck")
        waitFor(feedbackContinue, timeout: 12)
        pause(2.4)
        mark("codeEnd")
    }
}
