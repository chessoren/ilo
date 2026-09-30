import XCTest

/// a. Fresh install → onboarding → path building → commit → paywall → purchase → main tabs.
final class OnboardingE2ETests: IloUITestCase {
    func testFullOnboardingHappyPath() {
        launch(["-resetOnboarding", "-resetPro"])

        // Splash → Welcome
        let start = button("welcome-start")
        if !appears(start, timeout: 8) { tap(element("splash")) }
        waitFor(start, timeout: 10)
        pause(0.8)
        shot("01-welcome")
        tap(start)

        // How it works
        let cta = button("onboarding-continue")
        pause(1.2)
        shot("02-how-it-works")
        tap(cta)

        // Goal
        let field = waitFor(element("goal-field"))
        field.tap()
        field.typeText("Salsa for my grandma's wedding")
        pause(0.5)
        shot("03-goal")
        tap(cta)

        // Why / deadline / level / styles / minutes
        let choices = app.buttons.matching(identifier: "choice")
        tap(choices.element(boundBy: 0))
        shot("04-why")
        tap(cta)

        tap(choices.element(boundBy: 1)) // "In a month"
        tap(cta)

        tap(choices.element(boundBy: 0))
        tap(cta)

        tap(choices.element(boundBy: 0))
        tap(choices.element(boundBy: 2))
        shot("05-styles")
        tap(cta)

        tap(choices.element(boundBy: 1))
        pause(0.4)
        shot("06-minutes")
        tap(cta)

        // Name
        let name = waitFor(element("name-field"))
        name.tap()
        name.typeText("Sophia")
        tap(cta)

        // bloub maker
        pause(1.0)
        shot("07-bloub")
        tap(cta)

        // Reminders → Not now
        tap(app.buttons["Not now"])

        // Connect your Claude → skip (offline brain; no key in CI)
        let skip = button("claude-skip")
        waitFor(skip, timeout: 10, "Claude step never appeared")
        shot("07b-claude")
        tap(skip)

        // Path building (LocalAI ~8s + reveal)
        pause(3)
        shot("08-building")
        let ready = button("path-ready")
        waitFor(ready, timeout: 90, "Path never finished building")
        pause(1.0)
        shot("09-path-ready")
        tap(ready)

        // Commit: press and hold
        let hold = waitFor(element("commit-hold"))
        pause(0.8)
        shot("10-commit")
        hold.press(forDuration: 2.6)

        // Paywall
        let next = button("paywall-next")
        waitFor(next, timeout: 15, "Paywall did not appear after commit")
        pause(1.2)
        shot("11-paywall-hero")
        tap(next)
        let buy = button("paywall-cta")
        waitFor(buy)
        pause(1.2)
        shot("12-paywall-plans")
        tap(buy)

        // Either the purchase is simulated, a StoreKit sheet appears, or we fall back to the debug unlock.
        if !appears(mainTabs, timeout: 12) {
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            for label in ["Subscribe", "Confirm", "Buy", "OK"] {
                let b = springboard.buttons[label]
                if b.exists { b.tap(); pause(1) }
                let inApp = app.buttons[label]
                if inApp.exists && inApp.isHittable { inApp.tap(); pause(1) }
            }
        }
        if !appears(mainTabs, timeout: 12) {
            shot("12b-paywall-stuck")
            let logo = element("paywall-logo")
            if logo.exists { logo.press(forDuration: 2.0) }
        }
        waitFor(mainTabs, timeout: 15, "Main tabs never appeared after purchase")
        pause(1.5)
        shot("13-home")
        XCTAssertTrue(element("home-hero").exists, "Home should show the new course")
    }
}
