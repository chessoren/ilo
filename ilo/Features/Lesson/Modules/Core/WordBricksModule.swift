import SwiftUI

struct WordBricksModule: View {
    let session: ModuleSession

    var body: some View {
        Text("WordBricks").onAppear { session.hidesCheckBar = true }
    }
}
