import SwiftUI

/// Settings: profile, goal, reminders, sound/haptics, purchases, reset, about.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(PurchaseService.self) private var store
    @Environment(\.openURL) private var openURL
    @AppStorage("sound.enabled") private var soundOn = true
    @AppStorage("haptics.enabled") private var hapticsOn = true
    @State private var confirmReset = false
    @State private var restoring = false
    @State private var restoreMessage: String?
    @State private var claudeConnected = AnthropicKeyStore.isConnected
    @State private var showClaude = false

    private let goals: [(Int, String)] = [(10, "Casual"), (20, "Regular"), (30, "Serious"), (50, "Intense")]

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                HStack(spacing: 14) {
                    PlayerAvatar(size: 56, showsLevel: false)
                    TextField("Your name", text: $model.player.name)
                        .font(.display(20, weight: .bold))
                        .submitLabel(.done)
                        .onSubmit { model.save() }
                }
                NavigationLink { BloubStudioView() } label: { Label("Customize my bloub", systemImage: "paintpalette.fill") }
            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(claudeConnected ? Palette.orange : Palette.faint, in: .rect(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(claudeConnected ? "Claude connected" : "Offline brain").font(.body(16, weight: .semibold))
                        Text(claudeConnected ? (AnthropicKeyStore.maskedKey ?? "") : "Connect your Anthropic key for live research")
                            .font(.body(13)).foregroundStyle(Palette.muted)
                    }
                }
                Button(claudeConnected ? "Replace API key" : "Connect Claude") { showClaude = true }
                if claudeConnected {
                    Button("Remove API key", role: .destructive) {
                        AnthropicKeyStore.remove()
                        withAnimation { claudeConnected = false }
                        Haptics.shared.warning()
                    }
                }
            } header: {
                Text("AI brain")
            } footer: {
                Text("Your key stays in this iPhone's Keychain and is only sent to api.anthropic.com. You pay Anthropic directly for what you use.")
            }

            Section("Daily goal") {
                Picker("Daily goal", selection: $model.player.dailyGoalXP) {
                    ForEach(goals, id: \.0) { xp, name in Text("\(name) · \(xp) XP").tag(xp) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Reminder") {
                DatePicker("Daily reminder", selection: reminderBinding, displayedComponents: .hourAndMinute)
            }

            Section("Feel") {
                Group {
                Toggle(isOn: $soundOn) { Label("Sound effects", systemImage: "speaker.wave.2.fill") }
                    .onChange(of: soundOn) { _, on in SoundFX.shared.enabled = on; if on { SoundFX.shared.play(.pop) } }
                Toggle(isOn: $hapticsOn) { Label("Haptics", systemImage: "iphone.radiowaves.left.and.right") }
                    .onChange(of: hapticsOn) { _, on in Haptics.shared.enabled = on; if on { Haptics.shared.correct() } }
                }
                .tint(Palette.success)
            }

            Section("Subscription") {
                Button {
                    restoring = true
                    Task {
                        let ok = await store.restore()
                        restoring = false
                        restoreMessage = ok && store.isPro
                            ? "ilo Pro is active on this account."
                            : (store.errorMessage ?? "No active subscription was found for this account.")
                    }
                } label: {
                    HStack {
                        Label("Restore purchases", systemImage: "arrow.clockwise.circle.fill")
                        Spacer()
                        if restoring { ProgressView() }
                    }
                }
                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") { openURL(url) }
                } label: {
                    Label("Manage subscription", systemImage: "creditcard.fill")
                }
            }

            Section {
                Button(role: .destructive) { confirmReset = true } label: {
                    Label("Reset everything", systemImage: "trash.fill").foregroundStyle(Palette.danger)
                }
            } footer: {
                Text("Deletes your courses, progress, XP and badges on this device.")
            }

            Section("About") {
                HStack(spacing: 14) {
                    BloubView(shape: .circle, color: .ilo, expression: .happy).frame(width: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ilo").font(.display(18, weight: .heavy))
                        Text("Learn anything, one bite at a time.").font(.body(13)).foregroundStyle(Palette.muted)
                    }
                }
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                LabeledContent("Made for", value: "RevenueCat Shipaton 2026")
                LabeledContent("Mascot", value: "bloub")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.canvas)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.player.dailyGoalXP) { Haptics.shared.tick(); model.save() }
        .onDisappear { model.save() }
        .sheet(isPresented: $showClaude) {
            ClaudeKeySheet(connected: $claudeConnected)
        }
        .alert("Restore purchases", isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })) {
            Button("OK") {}
        } message: { Text(restoreMessage ?? "") }
        .confirmationDialog("Reset everything?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) {
                Haptics.shared.thud()
                model.reset()
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    private var reminderBinding: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: model.player.reminderHour, minute: 0, second: 0, of: .now) ?? .now
        } set: { date in
            model.player.reminderHour = Calendar.current.component(.hour, from: date)
            model.save()
            // Ask for permission if onboarding's "Not now" skipped it — otherwise the reminder could never fire.
            let hour = model.player.reminderHour, name = model.player.name, goal = model.activeCourse?.title ?? ""
            Task { _ = await OnboardingReminders.requestAndSchedule(hour: hour, name: name, goal: goal) }
        }
    }
}


/// Settings sheet that reuses the onboarding "Connect your Claude" step.
private struct ClaudeKeySheet: View {
    @Binding var connected: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var justConnected = false

    var body: some View {
        NavigationStack {
            ZStack {
                IloBackground()
                OBClaudeStep(connected: $justConnected) { dismiss() }
            }
            .navigationTitle("Connect your Claude")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .onChange(of: justConnected) { _, now in if now { connected = true } }
    }
}
