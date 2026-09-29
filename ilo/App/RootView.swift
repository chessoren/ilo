import SwiftUI

/// Routes between onboarding, the hard paywall and the main app.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(PurchaseService.self) private var store

    var body: some View {
        ZStack {
            if !model.hasOnboarded {
                OnboardingFlow()
                    .transition(.opacity)
            } else if !store.isPro {
                PaywallView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
        .animation(.smooth(duration: 0.5), value: model.hasOnboarded)
        .animation(.smooth(duration: 0.5), value: store.isPro)
    }
}
