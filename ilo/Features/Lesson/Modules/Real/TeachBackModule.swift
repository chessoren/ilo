import SwiftUI

/// "Teach ilo": ilo turns into a curious five-year-old and the learner explains the idea back in simple words.
struct TeachBackModule: View {
    let session: ModuleSession
    @State private var model = RealAnswerModel()
    @State private var speaker = RealVoiceOutput()
    @State private var visible = false
    @State private var confetti = 0
    @State private var hop = 0
    @FocusState private var focused: Bool

    private var module: LessonModule { session.module }

    private var topic: String { module.prompt ?? module.title ?? "this idea" }

    /// What little ilo asks.
    private var kidQuestion: String {
        let p = topic.realTrimmed
        let lower = p.lowercased()
        if p.hasSuffix("?") || p.hasSuffix("!") || lower.hasPrefix("explain") || lower.hasPrefix("teach") || lower.hasPrefix("why") || lower.hasPrefix("how") {
            return p
        }
        return "Can you explain \(p) to me like I'm five?"
    }

    private var rubric: [String] {
        (module.rubric ?? []) + ["Uses simple words a five-year-old understands", "Uses an example or comparison from everyday life"]
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RealHeader(type: module.type, title: module.title ?? "Teach ilo", tint: session.tint,
                               subtitle: "The best way to learn is to teach. ilo is five today — keep it simple!")

                    kidStage
                        .appear(visible, delay: 0.08)
                        .id("kid")

                    if model.grade == nil {
                        RealTextArea(text: $model.text, placeholder: "So, imagine that…", minHeight: 130,
                                     disabled: model.isLocked, focus: $focused) {
                            RealMicButton(voice: model.voice, text: $model.text)
                                .disabled(model.isLocked)
                        }
                        .appear(visible, delay: 0.18)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        Text("“\(model.text.realTrimmed)”")
                            .font(.body(15, weight: .medium))
                            .italic()
                            .foregroundStyle(Palette.muted)
                            .lineLimit(3)
                            .padding(.horizontal, 6)
                            .transition(.opacity)
                    }

                    switch model.status {
                    case .grading:
                        RealThinkingRow(text: "Little ilo is thinking really hard…")
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    case .graded(let grade):
                        RealGradeCard(grade: grade, sample: module.sampleAnswer, tint: session.tint,
                                      headline: grade.passed ? "ilo understood!" : "ilo is still confused")
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("result")
                    case .failed(let why):
                        RealErrorRow(text: why) { model.resetError(session: session); Task { await check() } }
                    case .writing:
                        tips.appear(visible, delay: 0.26)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.status) { _, status in
                if case .graded = status {
                    focused = false
                    withAnimation(.smooth(duration: 0.6)) { proxy.scrollTo("kid", anchor: .top) }
                }
            }
        }
        .overlay { ConfettiView(trigger: confetti).ignoresSafeArea() }
        .onAppear(perform: setup)
        .onChange(of: model.text) {
            if !model.isLocked { session.canCheck = model.hasAnswer }
        }
        .onDisappear {
            model.voice.stop()
            speaker.stop()
        }
        .realDemoAuto {
            await realPause(1.5)
            model.text = "It's like a train! After something you already do, like brushing your teeth, you hook on one tiny new thing."
            await realPause(1.2)
            session.check()
        }
    }

    // MARK: Kid stage

    private var kidStage: some View {
        VStack(spacing: 14) {
            Text(kidLine)
                .font(.display(20, weight: .bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(RealKidBubble().fill(.white))
                .shadow(color: Color(hex: 0x3A4470, alpha: 0.08), radius: 16, y: 8)
                .contentTransition(.opacity)
                .animation(.smooth, value: kidLine)

            ZStack(alignment: .topTrailing) {
                BloubView(color: .ilo, expression: kidExpression, mode: model.status == .grading ? .thinking : .face,
                          lookAt: model.voice.isListening ? CGPoint(x: 0, y: 0.6) : nil)
                    .frame(width: 150, height: 150)
                    .overlay(alignment: .top) {
                        partyHat
                            .offset(x: 14, y: -6)
                            .opacity(model.status == .grading ? 0 : 1)
                            .animation(.smooth, value: model.status == .grading)
                    }
                    .keyframeAnimator(initialValue: RealSquash(), trigger: hop) { view, v in
                        view.scaleEffect(x: v.x, y: v.y, anchor: .bottom).offset(y: (v.y - 1) * -120)
                    } keyframes: { _ in
                        KeyframeTrack(\.x) {
                            SpringKeyframe(1.15, duration: 0.1)
                            SpringKeyframe(0.9, duration: 0.18)
                            SpringKeyframe(1.05, duration: 0.18)
                            SpringKeyframe(1, duration: 0.3)
                        }
                        KeyframeTrack(\.y) {
                            SpringKeyframe(0.85, duration: 0.1)
                            SpringKeyframe(1.18, duration: 0.18)
                            SpringKeyframe(0.95, duration: 0.18)
                            SpringKeyframe(1, duration: 0.3)
                        }
                    }

                Button {
                    Haptics.shared.tap()
                    Task { await speaker.speak(kidLine) }
                } label: {
                    Image(systemName: speaker.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .symbolEffect(.variableColor.iterative, isActive: speaker.isSpeaking)
                        .frame(width: 40, height: 40)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .offset(x: 40, y: 20)
                .accessibilityLabel("Hear ilo's question")
            }
            .frame(maxWidth: .infinity)

            Text("ilo · age 5")
                .font(.body(12, weight: .heavy))
                .foregroundStyle(Palette.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Palette.butter, in: .capsule)
        }
        .padding(.vertical, 8)
    }

    private var partyHat: some View {
        Canvas { gc, size in
            var cone = Path()
            cone.move(to: CGPoint(x: size.width / 2, y: 0))
            cone.addLine(to: CGPoint(x: size.width, y: size.height))
            cone.addLine(to: CGPoint(x: 0, y: size.height))
            cone.closeSubpath()
            gc.fill(cone, with: .linearGradient(Gradient(colors: [Palette.orchid, Palette.periwinkle]),
                                                startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            for i in 0..<3 {
                let y = size.height * (0.35 + Double(i) * 0.22)
                gc.fill(Path(ellipseIn: CGRect(x: size.width * (0.3 + Double(i % 2) * 0.25), y: y, width: 5, height: 5)), with: .color(.white))
            }
            gc.fill(Path(ellipseIn: CGRect(x: size.width / 2 - 6, y: -6, width: 12, height: 12)), with: .color(Palette.gold))
        }
        .frame(width: 34, height: 40)
        .rotationEffect(.degrees(18))
    }

    private var tips: some View {
        HStack(spacing: 8) {
            ForEach(["Short sentences", "Everyday example", "No jargon"], id: \.self) { tip in
                Text(tip)
                    .font(.body(12, weight: .bold))
                    .foregroundStyle(session.tint.deep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(session.tint.soft, in: .capsule)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var kidLine: String {
        switch model.status {
        case .writing:
            if model.voice.isListening { return "Ooh, I'm listening!" }
            let words = model.text.split(separator: " ").count
            if words > 25 { return "Whoa, that's a lot of words! Is that all of it?" }
            if words > 6 { return "Uh-huh… and then what?" }
            return kidQuestion
        case .grading: return "Hmmmmm…"
        case .graded(let g): return g.passed ? "Ohhh! Now I get it! You're the best teacher!" : "Hmm… I'm still a bit confused. Can you use easier words next time?"
        case .failed: return "Wait, I got distracted by a butterfly."
        }
    }

    private var kidExpression: BloubExpression {
        switch model.status {
        case .writing: model.voice.isListening ? .attentive : (model.text.isEmpty ? .curious : .excited)
        case .grading: .curious
        case .graded(let g): g.passed ? .laughing : .confused
        case .failed: .confused
        }
    }

    private func setup() {
        visible = true
        session.hidesCheckBar = false
        session.checkTitle = "Teach ilo"
        session.mood = .curious
        session.canCheck = model.hasAnswer && !model.isLocked
        session.onCheck = { Task { await check() } }
    }

    private func check() async {
        focused = false
        speaker.stop()
        await model.submit(session: session, question: "Explain to a five-year-old: \(topic)", rubric: rubric, sample: module.sampleAnswer) { grade in
            if grade.passed {
                hop += 1
                confetti += 1
                Haptics.shared.celebrate()
            }
        }
    }
}

/// Speech bubble with a centered tail pointing down to the kid.
struct RealKidBubble: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(roundedRect: rect, cornerRadius: 26, style: .continuous)
        let mid = rect.midX
        p.move(to: CGPoint(x: mid - 14, y: rect.maxY - 1))
        p.addQuadCurve(to: CGPoint(x: mid + 2, y: rect.maxY + 14), control: CGPoint(x: mid - 2, y: rect.maxY + 4))
        p.addQuadCurve(to: CGPoint(x: mid + 12, y: rect.maxY - 1), control: CGPoint(x: mid + 6, y: rect.maxY + 4))
        p.closeSubpath()
        return p
    }
}
