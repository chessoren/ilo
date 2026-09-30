import XCTest

/// c. Leagues, Quests (claim), Profile (settings, bloub studio, badges), Create (goal → build → path).
final class TabsE2ETests: IloUITestCase {
    private func seeded(_ extra: [String] = []) {
        launch(["-seedDemo", "-unlockPro"] + extra)
        waitFor(mainTabs, timeout: 20, "Main tabs never appeared")
        pause(1.5)
    }

    private func tab(_ name: String) -> XCUIElement {
        let inBar = app.tabBars.buttons[name]
        return inBar.exists ? inBar : app.buttons[name]
    }

    func testHomeAndLeagues() {
        seeded()
        shot("30-home-seeded")
        tap(tab("Leagues"))
        pause(2.0)
        shot("31-leagues")
        app.swipeUp()
        pause(1.0)
        shot("31b-leagues-scrolled")
    }

    func testQuestsClaim() {
        seeded()
        tap(tab("Quests"))
        pause(2.0)
        shot("32-quests")
        let claim = button("quest-claim")
        if claim.exists {
            tap(claim)
            pause(2.0)
            shot("32b-quests-claimed")
        }
    }

    func testProfileScreens() {
        seeded()
        tap(tab("Profile"))
        pause(2.0)
        shot("33-profile")

        // Badge detail
        let badge = button("badge")
        tap(badge)
        pause(1.2)
        shot("33b-badge-detail")
        app.swipeDown(velocity: .fast)
        pause(1.0)

        // Bloub studio
        let studio = element("link-bloub")
        for _ in 0..<4 where !studio.isHittable { app.swipeUp(); pause(0.5) }
        tap(studio)
        pause(1.5)
        shot("34-bloub-studio")
        app.navigationBars.buttons.firstMatch.tap()
        pause(1.0)

        // Settings
        let settings = element("link-settings")
        for _ in 0..<4 where !settings.isHittable { app.swipeUp(); pause(0.5) }
        tap(settings)
        pause(1.5)
        shot("35-settings")
        app.navigationBars.buttons.firstMatch.tap()
        pause(1.0)

        // Shop
        let shop = element("link-shop")
        for _ in 0..<4 where !shop.isHittable { app.swipeUp(); pause(0.5) }
        tap(shop)
        pause(1.5)
        shot("36-shop")
    }

    func testCreateBuildsPath() {
        seeded()
        tap(tab("Create"))
        let field = waitFor(element("create-goal-field"))
        pause(1.0)
        shot("37-create")
        field.tap()
        field.typeText("Learn to juggle three balls")
        // Dismiss keyboard by tapping the header area.
        app.staticTexts["New path"].firstMatch.tap()
        pause(0.5)
        tap(button("create-build"))
        pause(3)
        shot("38-create-building")
        let ready = button("path-ready")
        waitFor(ready, timeout: 120, "Create: path never finished building")
        pause(1.0)
        shot("39-create-ready")
        tap(ready)
        let node0 = element("node-0")
        waitFor(node0, timeout: 15, "Create CTA did not open the new path")
        pause(1.5)
        shot("40-create-path")
        XCTAssertEqual(node0.value as? String, "current")
    }
}
