import SwiftUI

struct FlashcardsModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Flashcards").onAppear { session.hidesCheckBar = true }
    }
}
