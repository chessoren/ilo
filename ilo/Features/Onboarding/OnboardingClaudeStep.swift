import SwiftUI
import UIKit

/// "Connect your Claude": the learner plugs in their own Anthropic API key, so every path and lesson is written by Claude
/// and billed to their own Anthropic account. Skippable: ilo then runs on its offline brain.
struct OBClaudeStep: View {
    @Binding var connected: Bool
    var onNext: () -> Void

    @State private var key = ""
    @State private var checking = false
    @State private var error: String?
    @State private var shake = 0
    @State private var visible = false
    @FocusState private var focused: Bool

    private var trimmed: String { key.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    if connected { connectedCard } else { explainer; keyField }
                    benefits.appear(visible, delay: 0.25)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: 10) {
                if connected {
                    Button { onNext() } label: {
                        HStack(spacing: 8) { Text("Build my path"); Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold)) }
                    }
                    .buttonStyle(.pill(.ink))
                    .accessibilityIdentifier("claude-continue")
                } else {
                    Button { connect() } label: {
                        HStack(spacing: 8) {
                            if checking { ProgressView().tint(.white) }
                            Text(checking ? "Checking your key…" : "Connect Claude")
                        }
                    }
                    .buttonStyle(.pill(.ink))
                    .disabled(trimmed.count < 20 || checking)
                    .accessibilityIdentifier("claude-connect")

                    Button {
                        Haptics.shared.tap()
                        onNext()
                    } label: {
                        Text("Skip for now, use ilo's offline brain")
                            .font(.body(15, weight: .semibold))
                            .foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("claude-skip")
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .obBottomFade()
        }
        .onAppear { visible = true }
    }

    // MARK: Pieces

    private var explainer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Palette.orange, in: .rect(cornerRadius: 10, style: .continuous))
                Text("ilo runs on Claude").font(.display(19, weight: .bold)).foregroundStyle(Palette.ink)
            }
            Text("Paste your own Anthropic API key. Claude researches your goal on the web and writes every lesson for you. You pay Anthropic directly for what you use, usually a few cents a lesson. No middleman, no markup.")
                .font(.body(15))
                .foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
            Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                HStack(spacing: 6) {
                    Text("Get a key on console.anthropic.com")
                    Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .bold))
                }
                .font(.body(14, weight: .semibold))
                .foregroundStyle(Palette.periwinkleDeep)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .appear(visible)
    }

    private var keyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "key.fill").foregroundStyle(Palette.periwinkleDeep)
                SecureField("sk-ant-…", text: $key)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit { connect() }
                    .accessibilityIdentifier("claude-key-field")
                Button {
                    if let pasted = UIPasteboard.general.string {
                        key = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                        Haptics.shared.tick()
                    }
                } label: {
                    Text("Paste").font(.body(14, weight: .bold)).padding(.horizontal, 12).frame(height: 32)
                        .background(Palette.periwinkleSoft, in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(.white, in: .rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(error == nil ? (focused ? Palette.periwinkleDeep : Palette.hairline) : Palette.danger, lineWidth: 2)
            }
            .modifier(ShakeEffect(shakes: CGFloat(shake)))
            .animation(.default, value: shake)

            if let error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Palette.danger)
                    .transition(.opacity)
            } else {
                Label("Stored only in this iPhone's Keychain. Remove it anytime in Settings.", systemImage: "lock.fill")
                    .font(.body(13, weight: .medium))
                    .foregroundStyle(Palette.muted)
            }
        }
        .appear(visible, delay: 0.12)
    }

    private var connectedCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Palette.successSoft).frame(width: 84, height: 84)
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Palette.success)
                    .symbolEffect(.bounce, value: connected)
            }
            Text("Claude is connected").font(.display(22, weight: .heavy)).foregroundStyle(Palette.ink)
            Text(AnthropicKeyStore.maskedKey ?? "")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.muted)
            Text("Your path will be researched live on the web and written by Claude Opus.")
                .font(.body(15))
                .foregroundStyle(Palette.ink2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card()
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private var benefits: some View {
        VStack(spacing: 10) {
            row("globe", "Live web research for any goal", Palette.sky)
            row("wand.and.stars", "Lessons written for you, on the spot", Palette.lavender)
            row("bubble.left.and.bubble.right.fill", "Real conversations and graded answers", Palette.peach)
        }
    }

    private func row(_ symbol: String, _ text: String, _ tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 36, height: 36)
                .background(tint, in: .rect(cornerRadius: 11, style: .continuous))
            Text(text).font(.body(15, weight: .semibold)).foregroundStyle(Palette.ink)
            Spacer()
        }
    }

    // MARK: Actions

    private func connect() {
        guard trimmed.count >= 20, !checking else { return }
        focused = false
        checking = true
        error = nil
        Task {
            do {
                try await AnthropicClient.validate(trimmed)
                AnthropicKeyStore.save(trimmed)
                Haptics.shared.celebrate()
                SoundFX.shared.play(.levelUp)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { connected = true }
            } catch {
                self.error = (error as? LocalizedError)?.errorDescription ?? "Couldn't reach Anthropic. Check your connection."
                Haptics.shared.wrong()
                shake += 1
            }
            checking = false
        }
    }
}

/// Horizontal shake used for a rejected key.
private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 4), y: 0))
    }
}
