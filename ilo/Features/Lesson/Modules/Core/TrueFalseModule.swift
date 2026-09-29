import SwiftUI

struct TrueFalseModule: View {
    let session: ModuleSession

    var body: some View {
        Text("TrueFalse").onAppear { session.hidesCheckBar = true }
    }
}
