import SwiftUI

struct FreeAnswerModule: View {
    let session: ModuleSession

    var body: some View {
        Text("FreeAnswer").onAppear { session.hidesCheckBar = true }
    }
}
