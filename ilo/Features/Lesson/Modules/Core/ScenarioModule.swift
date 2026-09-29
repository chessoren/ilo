import SwiftUI

struct ScenarioModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Scenario").onAppear { session.hidesCheckBar = true }
    }
}
