import SwiftUI

/// Hard paywall shown after onboarding (no close button). Two pages: the learner's path + benefits, then trial timeline + plans.
struct PaywallView: View {
    @Environment(PurchaseService.self) private var store
    @Environment(AppModel.self) private var model

    @State private var page = 0
    @State private var selectedID: String?
    @State private var visible = false
    @State private var confetti = 0
    @State private var success = false
    @State private var showError = false
    @State private var heartbeat = 0

    private var course: Course? { model.activeCourse }
    private var tint: CourseTint { course?.tint ?? .periwinkle }

    private var selected: PaywallPackage? {
        store.packages.first { $0.id == selectedID } ?? store.annual ?? store.packages.first
    }

    var body: some View {
        ZStack {
            IloBackground(tint: page == 0 ? tint.base : Palette.periwinkle)
                .animation(.smooth(duration: 0.8), value: page)

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 4)
                ZStack {
                    if page == 0 {
                        PaywallHeroPage(course: course, player: model.player, visible: visible)
                            .transition(.asymmetric(insertion: .offset(x: -80).combined(with: .opacity),
                                                    removal: .offset(x: -80).combined(with: .opacity)))
                    } else {
                        PaywallPlansPage(selectedID: selectionBinding, heartbeat: heartbeat)
                            .transition(.asymmetric(insertion: .offset(x: 80).combined(with: .opacity),
                                                    removal: .offset(x: 80).combined(with: .opacity)))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }

            ConfettiView(trigger: confetti)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if success {
                PaywallSuccessOverlay(player: model.player, trialDays: selected?.trialDays)
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
                    .zIndex(2)
            }
        }
        .onAppear {
            visible = true
            Haptics.shared.heartbeat()
            #if DEBUG
            if UserDefaults.standard.string(forKey: "paywallPage") == "1" { page = 1 }
            #endif
        }
        .task {
            if store.packages.isEmpty || store.packages.allSatisfy(\.isPlaceholder) { await store.loadPackages() }
        }
        .onChange(of: store.errorMessage) { _, message in showError = message != nil }
        .alert("Hmm, something went wrong", isPresented: $showError) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: page)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: success)
    }

    private var selectionBinding: Binding<String?> {
        Binding(get: { selected?.id }, set: { selectedID = $0; heartbeat += 1; Haptics.shared.heartbeat() })
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            GlassIconButton(systemImage: "chevron.left", size: 44) { page = 0 }
                .opacity(page == 1 ? 1 : 0)
                .disabled(page == 0)
            Spacer()
            logo
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Palette.ink : Palette.ink.opacity(0.18))
                        .frame(width: i == page ? 20 : 7, height: 7)
                }
            }
            .frame(width: 44)
        }
        .frame(height: 48)
    }

    private var logo: some View {
        HStack(spacing: 6) {
            Text("ilo").font(.display(24, weight: .heavy)).foregroundStyle(Palette.ink)
            Text("PRO")
                .font(.display(12, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .frame(height: 20)
                .background(Palette.ink, in: .capsule)
        }
        .contentShape(.rect)
        .onLongPressGesture(minimumDuration: 1.5) {
            #if DEBUG
            store.isCelebrating = true
            store.debugUnlock()
            celebrateAndEnter()
            #endif
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if page == 0 {
                Button {
                    Haptics.shared.softTap()
                    SoundFX.shared.play(.bubble)
                    page = 1
                    heartbeat += 1
                    Haptics.shared.heartbeat()
                } label: {
                    HStack(spacing: 8) {
                        Text("Unlock my path")
                        Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                    }
                }
                .buttonStyle(.pill(.ink))
                Text(trialLine)
                    .font(.body(13, weight: .medium))
                    .foregroundStyle(Palette.muted)
            } else {
                Button {
                    Task { await buy() }
                } label: {
                    HStack(spacing: 10) {
                        if store.isPurchasing {
                            ProgressView().tint(.white)
                        }
                        Text(ctaTitle)
                    }
                }
                .buttonStyle(.pill(.victory))
                .disabled(store.isPurchasing || store.isRestoring || selected == nil)
                .phaseAnimator([1.0, 1.035, 1.0, 1.02, 1.0], trigger: heartbeat) { view, s in
                    view.scaleEffect(s)
                } animation: { _ in .easeInOut(duration: 0.14) }
                Text(trialLine)
                    .font(.body(13, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .contentTransition(.opacity)
            }
            legal
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 14)
        .padding(.bottom, 2)
        .background {
            LinearGradient(stops: [.init(color: Palette.canvas.opacity(0), location: 0),
                                   .init(color: Palette.canvas.opacity(0.94), location: 0.14),
                                   .init(color: Palette.canvas, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .animation(.smooth, value: selected?.id)
        .task(id: page) {
            // A soft heartbeat on the CTA every few seconds on the plans page.
            guard page == 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.5))
                heartbeat += 1
            }
        }
    }

    private var legal: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.shared.tap()
                Task { await restore() }
            } label: {
                if store.isRestoring { ProgressView().controlSize(.mini) } else { Text("Restore purchases") }
            }
            .disabled(store.isRestoring || store.isPurchasing)
            Text("·").foregroundStyle(Palette.faint)
            Link("Terms", destination: URL(string: "https://ilo.app/terms")!)
            Text("·").foregroundStyle(Palette.faint)
            Link("Privacy", destination: URL(string: "https://ilo.app/privacy")!)
        }
        .font(.body(12.5, weight: .semibold))
        .foregroundStyle(Palette.muted)
        .tint(Palette.muted)
        .frame(height: 26)
    }

    private var ctaTitle: String {
        guard let selected else { return "Continue" }
        if store.isPurchasing { return "Just a sec…" }
        return selected.hasTrial ? "Start my free week" : "Continue with \(selected.title)"
    }

    private var trialLine: String {
        guard let selected else { return "Cancel anytime." }
        if selected.hasTrial, let days = selected.trialDays {
            return "\(days) days free, then \(selected.price)/\(selected.periodWord). Cancel anytime."
        }
        return "\(selected.price)/\(selected.periodWord). Cancel anytime."
    }

    // MARK: Actions

    private func buy() async {
        guard let selected else { return }
        store.isCelebrating = true
        let ok = await store.purchase(selected)
        if ok {
            celebrateAndEnter()
        } else {
            store.isCelebrating = false
            if store.errorMessage == nil { Haptics.shared.softTap() } else { Haptics.shared.wrong() }
        }
    }

    private func restore() async {
        store.isCelebrating = true
        let ok = await store.restore()
        if ok { celebrateAndEnter() } else { store.isCelebrating = false }
    }

    private func celebrateAndEnter() {
        success = true
        confetti += 1
        Haptics.shared.celebrate()
        SoundFX.shared.play(.levelUp)
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            store.isCelebrating = false
        }
    }
}

#Preview {
    PaywallView()
        .environment(AppModel())
        .environment(PurchaseService())
}
