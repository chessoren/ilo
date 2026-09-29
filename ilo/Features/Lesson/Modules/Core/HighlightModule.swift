import SwiftUI

struct HighlightModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Highlight").onAppear { session.hidesCheckBar = true }
    }
}
