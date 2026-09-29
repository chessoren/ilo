import SwiftUI

struct AudioLessonModule: View {
    let session: ModuleSession

    var body: some View {
        Text("AudioLesson").onAppear { session.hidesCheckBar = true }
    }
}
