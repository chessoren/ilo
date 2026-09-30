import SwiftUI
import Observation

/// Main-app navigation state: selected tab, Home navigation stack and the lesson being played.
@Observable
@MainActor
final class AppRouter {
    enum TabID: Hashable { case home, leagues, quests, profile, create }

    struct LessonLaunch: Identifiable, Hashable {
        var course: Course
        var node: PathNode
        var id: UUID { node.id }
    }

    var tab: TabID = .home
    /// Home stack: course ids of pushed PathViews.
    var homePath: [UUID] = []
    var lesson: LessonLaunch?
    /// Global frame of the gems pill (so rewards can fly into it).
    var gemsTarget: CGRect = .zero
    var showShop = false

    func play(_ node: PathNode, in course: Course) {
        Haptics.shared.press()
        SoundFX.shared.play(.whoosh)
        lesson = LessonLaunch(course: course, node: node)
    }

    func openPath(_ course: Course) {
        guard tab != .home else {
            if homePath.last != course.id { homePath = [course.id] }
            return
        }
        // Switching tab and pushing onto that tab's stack in the same update leaves the pushed PathView blank
        // (seen from Create → "Let's go"): switch first, push once the Home stack is on screen.
        homePath = []
        tab = .home
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            if homePath.last != course.id { homePath = [course.id] }
        }
    }
}
