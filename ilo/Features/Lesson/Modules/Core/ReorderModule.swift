import SwiftUI

struct ReorderModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Reorder").onAppear { session.hidesCheckBar = true }
    }
}
