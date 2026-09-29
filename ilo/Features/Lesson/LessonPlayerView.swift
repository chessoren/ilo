import SwiftUI

/// Full-screen lesson player. Presented with `.fullScreenCover`.
struct LessonPlayerView: View {
    let course: Course
    let node: PathNode
    var onClose: () -> Void

    var body: some View {
        Button("Close", action: onClose)
    }
}
