import SwiftUI

struct SpotTheMistakeModule: View {
    let session: ModuleSession

    var body: some View {
        Text("SpotTheMistake").onAppear { session.hidesCheckBar = true }
    }
}
