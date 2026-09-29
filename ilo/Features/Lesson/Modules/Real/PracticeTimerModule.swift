import SwiftUI

struct PracticeTimerModule: View {
    let session: ModuleSession

    var body: some View {
        Text("PracticeTimer").onAppear { session.hidesCheckBar = true }
    }
}
