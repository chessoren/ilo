import SwiftUI

/// "ilo is building your path" — runs the research agent live and reveals the path. Reused by Create.
struct PathBuildingView: View {
    let request: CourseRequest
    /// Called with the finished course (already added to the model).
    var onDone: (Course) -> Void

    var body: some View {
        Text("Building…")
    }
}
