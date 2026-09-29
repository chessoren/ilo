import SwiftUI

struct CodeLabModule: View {
    let session: ModuleSession

    var body: some View {
        Text("CodeLab").onAppear { session.hidesCheckBar = true }
    }
}
