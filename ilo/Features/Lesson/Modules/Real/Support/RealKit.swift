import SwiftUI

// Shared building blocks for the "real world" modules (freeAnswer, teachBack, roleplay, liveCall,
// mission, codeLab, cameraCoach, practiceTimer). Everything is prefixed `Real` to avoid clashing with other modules.

// MARK: - Header

/// Module type chip + big title, used at the top of every real-world module.
struct RealHeader: View {
    var type: ModuleType
    var title: String?
    var tint: CourseTint
    var subtitle: String? = nil
    /// The lesson player already shows the module chip next to ilo, so it's off by default.
    var showsChip = false
    @State private var visible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsChip {
            HStack(spacing: 6) {
                Image(systemName: type.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .symbolEffect(.bounce, value: visible)
                Text(type.displayName.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.1)
            }
            .foregroundStyle(tint.deep)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tint.soft, in: .capsule)
            .appear(visible)
            }

            if let title, !title.isEmpty {
                Text(title)
                    .font(.display(28, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .appear(visible, delay: 0.06)
            }
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .appear(visible, delay: 0.1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { visible = true }
    }
}

// MARK: - ilo speech bubble

/// ilo (ink bloub) with a speech bubble next to it.
struct RealIloSays: View {
    var text: String
    var expression: BloubExpression = .attentive
    var mode: BloubMode = .face
    var bloubColor: BloubColor = .ink
    var bloubShape: BloubShape = .circle
    var size: CGFloat = 64
    var bubbleFill: Color = .white
    @State private var bounce = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            BloubView(shape: bloubShape, color: bloubColor, expression: expression, mode: mode)
                .frame(width: size, height: size)
                .keyframeAnimator(initialValue: RealSquash(), trigger: bounce) { view, v in
                    view.scaleEffect(x: v.x, y: v.y, anchor: .bottom)
                } keyframes: { _ in
                    KeyframeTrack(\.x) {
                        SpringKeyframe(1.12, duration: 0.12)
                        SpringKeyframe(0.94, duration: 0.14)
                        SpringKeyframe(1, duration: 0.3)
                    }
                    KeyframeTrack(\.y) {
                        SpringKeyframe(0.88, duration: 0.12)
                        SpringKeyframe(1.08, duration: 0.14)
                        SpringKeyframe(1, duration: 0.3)
                    }
                }
            Text(text)
                .font(.body(16, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(RealBubbleShape(tailLeft: true).fill(bubbleFill))
                .shadow(color: Color(hex: 0x3A4470, alpha: 0.07), radius: 14, y: 6)
                .contentTransition(.opacity)
                .animation(.smooth, value: text)
            Spacer(minLength: 0)
        }
        .onChange(of: expression) { bounce += 1 }
        .onChange(of: text) { bounce += 1 }
    }
}

struct RealSquash {
    var x: CGFloat = 1
    var y: CGFloat = 1
}

/// Rounded bubble with a small tail at the bottom left (or right).
struct RealBubbleShape: Shape {
    var tailLeft = true
    var radius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var p = Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
        let tailY = rect.maxY - 14
        if tailLeft {
            p.move(to: CGPoint(x: rect.minX + 2, y: tailY - 8))
            p.addQuadCurve(to: CGPoint(x: rect.minX - 7, y: rect.maxY - 2), control: CGPoint(x: rect.minX - 1, y: rect.maxY - 6))
            p.addQuadCurve(to: CGPoint(x: rect.minX + 14, y: rect.maxY - 1), control: CGPoint(x: rect.minX + 4, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.maxX - 2, y: tailY - 8))
            p.addQuadCurve(to: CGPoint(x: rect.maxX + 7, y: rect.maxY - 2), control: CGPoint(x: rect.maxX + 1, y: rect.maxY - 6))
            p.addQuadCurve(to: CGPoint(x: rect.maxX - 14, y: rect.maxY - 1), control: CGPoint(x: rect.maxX - 4, y: rect.maxY))
        }
        return p
    }
}

// MARK: - Text area

/// Multiline glass text editor with placeholder, character count and optional mic accessory.
struct RealTextArea<Accessory: View>: View {
    @Binding var text: String
    var placeholder: String
    var minHeight: CGFloat = 150
    var disabled = false
    var focus: FocusState<Bool>.Binding
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body(17, weight: .medium))
                        .foregroundStyle(Palette.faint)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.body(17, weight: .medium))
                    .foregroundStyle(Palette.ink)
                    .scrollContentBackground(.hidden)
                    .focused(focus)
                    .disabled(disabled)
                    .frame(minHeight: minHeight)
            }
            HStack(spacing: 10) {
                accessory()
                Spacer()
                let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
                Text("\(words) word\(words == 1 ? "" : "s")")
                    .font(.body(12, weight: .semibold))
                    .foregroundStyle(Palette.faint)
                    .contentTransition(.numericText(value: Double(words)))
                    .animation(.snappy, value: words)
            }
        }
        .padding(14)
        .background(.white.opacity(0.55), in: .rect(cornerRadius: 26, style: .continuous))
        .glassEffect(.regular, in: .rect(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(focus.wrappedValue ? Palette.periwinkle.opacity(0.9) : .white.opacity(0.6), lineWidth: focus.wrappedValue ? 2 : 1)
                .animation(.smooth(duration: 0.25), value: focus.wrappedValue)
        }
    }
}

// MARK: - Waveform

/// Live bar waveform driven by an array of 0...1 levels.
struct RealWaveform: View {
    var levels: [CGFloat]
    var color: Color = Palette.ink
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 3

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(color)
                    .frame(width: barWidth, height: max(barWidth, 30 * min(1, level)))
            }
        }
        .frame(height: 30)
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: levels)
    }
}

/// Mic button that toggles dictation into a text binding, with a live waveform while listening.
struct RealMicButton: View {
    @Bindable var voice: RealVoiceInput
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Button {
                Task { await toggle() }
            } label: {
                ZStack {
                    Circle()
                        .fill(voice.isListening ? Palette.danger : Palette.ink)
                        .frame(width: 42, height: 42)
                    if voice.isListening {
                        Circle()
                            .stroke(Palette.danger.opacity(0.35), lineWidth: 6)
                            .frame(width: 42 + 18 * voice.level, height: 42 + 18 * voice.level)
                            .animation(.spring(response: 0.15), value: voice.level)
                    }
                    Image(systemName: voice.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(.squish)
            .accessibilityLabel(voice.isListening ? "Stop dictation" : "Dictate")

            if voice.isListening {
                RealWaveform(levels: voice.levels, color: Palette.danger, barWidth: 3, spacing: 2.5)
                    .transition(.scale(scale: 0.4, anchor: .leading).combined(with: .opacity))
            } else if let problem = voice.problem {
                Text(problem)
                    .font(.body(12, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .lineLimit(2)
                    .transition(.opacity)
            } else {
                Text("Tap to speak")
                    .font(.body(12, weight: .semibold))
                    .foregroundStyle(Palette.faint)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: voice.isListening)
        .onChange(of: voice.transcript) {
            if voice.isListening || !voice.transcript.isEmpty { text = voice.fullText }
        }
        .onDisappear { voice.stop() }
    }

    private func toggle() async {
        if voice.isListening {
            Haptics.shared.softTap()
            voice.stop()
        } else {
            Haptics.shared.press()
            await voice.start(prefix: text)
        }
    }
}

// MARK: - Score

/// Animated score ring with a percentage and 3 stars that pop in one by one.
struct RealScoreRing: View {
    var score: Double
    var passed: Bool
    var size: CGFloat = 104
    @State private var shown: Double = 0

    var stars: Int { score >= 0.85 ? 3 : score >= 0.6 ? 2 : score >= 0.3 ? 1 : 0 }
    var color: Color { passed ? Palette.success : Palette.orange }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(color.opacity(0.15), lineWidth: 11)
                Circle()
                    .trim(from: 0, to: shown)
                    .stroke(AngularGradient(colors: [color.opacity(0.7), color], center: .center),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                CountUpText(value: Int((score * 100).rounded()), font: .display(size * 0.24, weight: .heavy), suffix: "%")
                    .foregroundStyle(Palette.ink)
            }
            .frame(width: size, height: size)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    RealStar(filled: i < stars, delay: 0.5 + Double(i) * 0.22)
                }
            }
        }
        .onAppear {
            withAnimation(.smooth(duration: 1.1).delay(0.1)) { shown = max(0.02, score) }
        }
    }
}

private struct RealStar: View {
    var filled: Bool
    var delay: Double
    @State private var on = false

    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(on && filled ? Palette.gold : Palette.canvasDeep)
            .scaleEffect(on ? 1 : 0.3)
            .rotationEffect(.degrees(on ? 0 : -40))
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(delay)) { on = true }
                if filled {
                    Task {
                        try? await Task.sleep(for: .seconds(delay))
                        Haptics.shared.tap()
                        SoundFX.shared.play(.coin)
                    }
                }
            }
    }
}

/// Result card after an AI grade: ring + stars, feedback and a "better answer".
struct RealGradeCard: View {
    var grade: Grade
    var sample: String?
    var tint: CourseTint
    var headline: String? = nil
    @State private var visible = false

    var better: String? {
        if let improved = grade.improved, !improved.isEmpty { return improved }
        if let sample, !sample.isEmpty { return sample }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                RealScoreRing(score: grade.score, passed: grade.passed)
                VStack(alignment: .leading, spacing: 6) {
                    Text(headline ?? (grade.passed ? "Great answer!" : "Almost there"))
                        .font(.display(22, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text(grade.feedback)
                        .font(.body(15, weight: .medium))
                        .foregroundStyle(Palette.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let better {
                VStack(alignment: .leading, spacing: 8) {
                    Label(grade.passed && grade.score >= 0.85 ? "Model answer" : "Better answer", systemImage: "sparkles")
                        .font(.body(13, weight: .heavy))
                        .foregroundStyle(tint.deep)
                    Text(better)
                        .font(.body(15, weight: .medium))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tint.soft.opacity(0.7), in: .rect(cornerRadius: 20, style: .continuous))
                .appear(visible, delay: 0.5)
            }
        }
        .card(radius: 30, padding: 20)
        .onAppear { visible = true }
    }
}

// MARK: - Thinking / error

/// "ilo is thinking" row with the thinking bloub.
struct RealThinkingRow: View {
    var text: String

    var body: some View {
        HStack(spacing: 14) {
            BloubView(color: .ilo, expression: .curious, mode: .thinking)
                .frame(width: 54, height: 54)
            Text(text)
                .font(.body(16, weight: .semibold))
                .foregroundStyle(Palette.ink2)
            Spacer()
        }
        .card(radius: 26, padding: 16)
        .phaseAnimator([0.97, 1.0]) { view, s in view.scaleEffect(s) } animation: { _ in .easeInOut(duration: 0.9) }
    }
}

/// Sad bloub + retry button.
struct RealErrorRow: View {
    var text: String
    var retry: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            BloubView(color: .ilo, expression: .sad)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(.body(15, weight: .semibold))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Try again", action: retry)
                    .buttonStyle(.pill(.ink, height: 40, fullWidth: false))
            }
            Spacer(minLength: 0)
        }
        .card(radius: 26, padding: 16)
    }
}

// MARK: - Helpers

extension String {
    var realTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

/// Stable pseudo-random picks from a string (for persona colours/shapes).
enum RealHash {
    static func value(_ s: String) -> Int {
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return Int(h % 1_000_000)
    }

    static func bloubColor(for s: String) -> BloubColor {
        let options: [BloubColor] = [.orange, .pink, .violet, .turquoise, .blue, .amber, .red, .green]
        return options[value(s) % options.count]
    }

    static func bloubShape(for s: String) -> BloubShape {
        let options: [BloubShape] = [.pebble, .squircle, .cloud, .droplet, .hexagon, .capsule]
        return options[(value(s) / 7) % options.count]
    }
}

/// Horizontal shake for wrong attempts.
struct RealShake: GeometryEffect {
    var amount: CGFloat = 9
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakes * 2), y: 0))
    }
}

// MARK: - DEBUG autoplay (screenshots / demo recording)

extension View {
    /// DEBUG only: when launched with `-demoAuto`, runs a scripted interaction once the module appears. No-op in release.
    func realDemoAuto(_ script: @escaping @MainActor () async -> Void) -> some View {
        #if DEBUG
        return task {
            guard ProcessInfo.processInfo.arguments.contains("-demoAuto") else { return }
            await script()
        }
        #else
        return self
        #endif
    }
}

/// Sleep helper for demo scripts.
func realPause(_ seconds: Double) async {
    try? await Task.sleep(for: .seconds(seconds))
}
