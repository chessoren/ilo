import SwiftUI

struct RoleplayModule: View {
    let session: ModuleSession

    var body: some View {
        Text("Roleplay").onAppear { session.hidesCheckBar = true }
    }
}
