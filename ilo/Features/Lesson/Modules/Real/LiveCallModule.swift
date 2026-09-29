import SwiftUI

struct LiveCallModule: View {
    let session: ModuleSession

    var body: some View {
        Text("LiveCall").onAppear { session.hidesCheckBar = true }
    }
}
