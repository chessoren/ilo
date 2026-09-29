import SwiftUI

struct EstimateModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Estimate").onAppear { session.hidesCheckBar = true }
    }
}
