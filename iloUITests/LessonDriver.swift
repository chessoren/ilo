import XCTest

/// Plays lesson modules generically with real taps.
extension IloUITestCase {
    /// Identifier of the module currently on screen (e.g. "multipleChoice"), from the header chip `module-<type>`.
    func currentModuleType() -> String? {
        let header = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'module-' AND identifier != 'module-done'"))
            .firstMatch
        guard header.exists else { return nil }
        return String(header.identifier.dropFirst("module-".count))
    }

    var feedbackContinue: XCUIElement { button("lesson-feedback-continue") }
    var checkButton: XCUIElement { button("lesson-check") }

    private func tapIfPossible(_ element: XCUIElement) -> Bool {
        guard element.exists, element.isHittable, element.isEnabled else { return false }
        element.tap()
        return true
    }

    private func check() {
        tap(checkButton, timeout: 6, "Check never became enabled for \(currentModuleType() ?? "?")")
    }

    /// Interacts with the module on screen until it is graded (feedback panel) or it finishes by itself.
    /// Returns the type that was played.
    @discardableResult
    func playCurrentModule(shotPrefix: String? = nil) -> String {
        guard let type = currentModuleType() else {
            shot("FAIL-no-module")
            XCTFail("No module header on screen")
            return "?"
        }
        pause(0.6) // entrance animations
        if let shotPrefix { shot("\(shotPrefix)-\(type)") }

        switch type {
        case "storyCards":
            let area = element("story-cards")
            let done = button("module-done")
            for _ in 0..<12 where !done.exists {
                if area.exists { area.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).tap() }
                pause(0.5)
            }
            tap(done)

        case "audioLesson":
            tap(button("module-done"))

        case "flashcards":
            let gotIt = button("flash-gotit")
            let done = button("module-done")
            for _ in 0..<20 where !done.exists {
                if gotIt.exists && gotIt.isHittable { gotIt.tap() }
                pause(0.6)
            }
            tap(done)

        case "multipleChoice", "scenario", "fillBlank":
            tap(button("answer-0"))
            check()

        case "trueFalse":
            let t = button("tf-true")
            for _ in 0..<10 where !feedbackContinue.exists {
                if t.exists && t.isHittable { t.tap() }
                pause(0.7)
            }

        case "matchPairs":
            playMatchPairs()

        case "reorder":
            let first = element("reorder-row-0")
            let second = element("reorder-row-1")
            waitFor(first)
            first.press(forDuration: 0.2, thenDragTo: second)
            pause(0.5)
            check()

        case "wordBricks":
            let bricks = app.buttons.matching(identifier: "brick")
            for _ in 0..<12 {
                let b = bricks.firstMatch
                guard b.exists, b.isHittable else { break }
                b.tap()
                pause(0.3)
            }
            check()

        case "estimate":
            let track = element("estimate-track")
            waitFor(track)
            track.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            pause(0.3)
            check()

        case "spotTheMistake", "highlight":
            tap(button("segment-0"))
            check()

        case "categorize":
            let items = app.descendants(matching: .any).matching(identifier: "cat-item")
            let bucket = element("cat-bucket-0")
            for _ in 0..<12 {
                let item = items.firstMatch
                guard item.exists, item.isHittable else { break }
                item.tap()
                pause(0.3)
                bucket.tap()
                pause(0.4)
            }
            check()

        case "speedRound":
            tap(app.buttons["Start"])
            let t = button("speed-true")
            for _ in 0..<60 where !feedbackContinue.exists {
                if t.exists && t.isHittable && t.isEnabled { t.tap() }
                pause(0.5)
            }

        default:
            // Real-world modules: look for a way out (skip / done), otherwise report.
            for label in ["Skip for now", "Skip", "I did it!", "Not now", "Continue"] {
                if tapIfPossible(app.buttons[label]) { break }
            }
            if tapIfPossible(checkButton) { break }
        }
        return type
    }

    private func playMatchPairs() {
        var lefts: [XCUIElement] = []
        for i in 0..<8 {
            let l = button("match-L-\(i)")
            if l.exists { lefts.append(l) } else { break }
        }
        XCTAssertFalse(lefts.isEmpty, "No match tiles")
        for left in lefts {
            for j in 0..<lefts.count {
                guard left.isEnabled else { break }
                let right = button("match-R-\(j)")
                guard right.exists, right.isEnabled else { continue }
                left.tap()
                right.tap()
                pause(0.75) // wrong pairs reset after 550 ms
            }
        }
    }

    /// Plays modules until the celebration appears (or `maxSteps` is hit). Returns the module types played in order.
    @discardableResult
    func playLessonToEnd(maxSteps: Int = 40, shotPrefix: String? = nil) -> [String] {
        var played: [String] = []
        let celebration = button("celebration-continue")
        var seen: Set<String> = []
        for step in 0..<maxSteps {
            if celebration.exists { return played }
            if feedbackContinue.exists && feedbackContinue.isHittable {
                pause(0.4)
                feedbackContinue.tap()
                pause(0.9)
                continue
            }
            guard currentModuleType() != nil else {
                pause(1)
                if step > 5 && currentModuleType() == nil && !celebration.exists {
                    shot("FAIL-lesson-stuck-\(step)")
                }
                continue
            }
            let type = currentModuleType() ?? "?"
            let prefix = (shotPrefix != nil && !seen.contains(type)) ? shotPrefix : nil
            seen.insert(type)
            played.append(playCurrentModule(shotPrefix: prefix))
            // Wait for grading / the next module.
            let deadline = Date().addingTimeInterval(8)
            while Date() < deadline {
                if feedbackContinue.exists || celebration.exists { break }
                if let now = currentModuleType(), now != type { break }
                pause(0.3)
            }
            if feedbackContinue.exists, let prefix, played.count <= 12 {
                pause(0.5)
                shot("\(prefix)-\(type)-feedback")
            }
        }
        if !celebration.exists {
            shot("FAIL-lesson-never-ended")
            XCTFail("Lesson did not reach the celebration after \(maxSteps) steps; played \(played)")
        }
        return played
    }

    /// Taps through the celebration screens back to the path.
    func finishCelebration(shotPrefix: String? = nil) {
        let celebration = button("celebration-continue")
        waitFor(celebration, timeout: 10)
        var i = 0
        while celebration.exists && i < 8 {
            pause(1.6) // count-ups / confetti
            if let shotPrefix { shot("\(shotPrefix)-celebration-\(i)") }
            if celebration.isHittable { celebration.tap() }
            i += 1
            pause(1.0)
        }
        XCTAssertFalse(celebration.exists, "Celebration never closed")
    }
}
