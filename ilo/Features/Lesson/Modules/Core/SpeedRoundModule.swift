import SwiftUI

struct SpeedRoundModule: View {
    let session: ModuleSession

    var body: some View {
        Text("SpeedRound").onAppear { session.hidesCheckBar = true }
    }
}
