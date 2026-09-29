import SwiftUI

struct StoryCardsModule: View {
    let session: ModuleSession

    var body: some View {
        Text("StoryCards").onAppear { session.hidesCheckBar = true }
    }
}
