import SwiftUI

struct FillBlankModule: View {
    let session: ModuleSession

    var body: some View {
        Text("FillBlank").onAppear { session.hidesCheckBar = true }
    }
}
