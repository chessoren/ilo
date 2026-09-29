import SwiftUI

struct MultipleChoiceModule: View {
    let session: ModuleSession

    var body: some View {
        Text("MultipleChoice").onAppear { session.hidesCheckBar = true }
    }
}
