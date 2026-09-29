import SwiftUI

struct CameraCoachModule: View {
    let session: ModuleSession

    var body: some View {
        Text("CameraCoach").onAppear { session.hidesCheckBar = true }
    }
}
