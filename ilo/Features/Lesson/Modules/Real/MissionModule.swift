import SwiftUI

struct MissionModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Mission").onAppear { session.hidesCheckBar = true }
    }
}
