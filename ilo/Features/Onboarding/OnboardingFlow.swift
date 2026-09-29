import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(spacing: 24) {
            BloubView(expression: .excited).frame(width: 180)
            Button("Start") { model.hasOnboarded = true }.buttonStyle(.pill())
        }
        .padding()
        .background(IloBackground())
    }
}
