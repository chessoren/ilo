import SwiftUI

struct TeachBackModule: View {
    let session: ModuleSession

    var body: some View {
        Text("TeachBack").onAppear { session.hidesCheckBar = true }
    }
}
