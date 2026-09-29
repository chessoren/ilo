import SwiftUI

struct CategorizeModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Categorize").onAppear { session.hidesCheckBar = true }
    }
}
