import SwiftUI

struct MatchPairsModule: View {
    let session: ModuleSession

    var body: some View {
        Text("MatchPairs").onAppear { session.hidesCheckBar = true }
    }
}
