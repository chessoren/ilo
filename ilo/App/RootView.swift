import SwiftUI

/// Routes between onboarding, the hard paywall and the main app.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(PurchaseService.self) private var store
    /// Gives the store a moment to report an existing subscription before showing the paywall.
    @State private var entitlementGraceOver = false

    private var showsPaywall: Bool { !store.isPro || store.isCelebrating }

    var body: some View {
        ZStack {
            if !model.hasOnboarded {
                OnboardingFlow()
                    .transition(.opacity)
            } else if showsPaywall {
                if store.hasCheckedEntitlements || entitlementGraceOver {
                    PaywallView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    ZStack {
                        IloBackground()
                        BloubView(shape: .circle, color: .ink, mode: .thinking).frame(width: 90, height: 90)
                    }
                    .transition(.opacity)
                }
            } else {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
        .animation(.smooth(duration: 0.5), value: model.hasOnboarded)
        .animation(.smooth(duration: 0.5), value: showsPaywall)
        .animation(.smooth(duration: 0.3), value: store.hasCheckedEntitlements || entitlementGraceOver)
        .onAppear {
            model.isPro = store.isPro
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-resetOnboarding") { model.reset() }
            if args.contains("-skipOnboarding") { model.hasOnboarded = true }
            #endif
        }
        .onChange(of: store.isPro) { _, isPro in model.isPro = isPro }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            entitlementGraceOver = true
        }
    }
}
