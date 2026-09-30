import SwiftUI

// MARK: - Loading

/// Shown while the lesson is generated: ilo thinking, rotating fun lines, and a warm-up if it takes a while.
struct LessonLoadingView: View {
    let course: Course
    let node: PathNode
    var onClose: () -> Void

    @State private var lineIndex = 0
    @State private var showWarmup = false
    @State private var appeared = false

    private var lines: [String] {
        let sources = course.sources.count > 2 ? course.sources.count : 12
        return [
            "Reading \(sources) sources…",
            "Picking the best exercises for you…",
            "Writing your story cards…",
            "Tuning it to your level…",
            "Finding real-life examples…",
            "Adding a pinch of fun…",
            "Almost there, promise!",
        ]
    }

    var body: some View {
        ZStack {
            IloBackground(tint: course.tint.base, lines: true)
            VStack(spacing: 0) {
                HStack {
                    GlassIconButton(systemImage: "xmark", size: 44, action: onClose)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer(minLength: 10)

                VStack(spacing: 18) {
                    BloubView(shape: .circle, color: .ilo, expression: .curious, mode: .thinking)
                        .frame(width: showWarmup ? 110 : 150, height: showWarmup ? 110 : 150)
                        .appear(appeared)
                    VStack(spacing: 8) {
                        Text("Building your lesson")
                            .font(.body(13, weight: .bold))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(course.tint.deep)
                        Text(node.title)
                            .font(.display(30, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.center)
                    }
                    .appear(appeared, delay: 0.08)
                    Text(lines[lineIndex % lines.count])
                        .font(.body(16, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                        .id(lineIndex)
                        .transition(.asymmetric(insertion: .offset(y: 14).combined(with: .opacity),
                                                removal: .offset(y: -14).combined(with: .opacity)))
                        .frame(height: 24)
                        .appear(appeared, delay: 0.16)
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 10)

                if showWarmup {
                    WarmupCard(tint: course.tint)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: showWarmup)
        .onAppear { appeared = true }
        .task {
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.9))
                tick += 1
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { lineIndex += 1 }
                if tick == 2 { showWarmup = true; Haptics.shared.softTap() }
            }
        }
    }
}

/// A tiny true/false game to play while the lesson is generated.
private struct WarmupCard: View {
    var tint: CourseTint

    private static let pool: [(String, Bool, String)] = [
        ("Testing yourself beats re-reading your notes.", true, "Retrieval practice is one of the strongest ways to remember."),
        ("Cramming everything the night before sticks best.", false, "Spacing practice over days wins, by a lot."),
        ("Making mistakes while learning helps you remember.", true, "Errors followed by feedback make memories stronger."),
        ("You only use 10% of your brain.", false, "A myth — you use all of it, just not all at once."),
        ("Short daily sessions beat one long weekly session.", true, "Little and often keeps things fresh."),
        ("Sleep has nothing to do with memory.", false, "Sleep is when your brain files away what you learned."),
        ("Explaining an idea out loud helps you understand it.", true, "That's the “teach it back” effect."),
    ]

    @State private var order = Array(0..<WarmupCard.pool.count).shuffled()
    @State private var position = 0
    @State private var answered: Bool?
    @State private var score = 0
    @State private var shakes = 0

    private var item: (String, Bool, String) { Self.pool[order[position % order.count]] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Warm-up while ilo writes", systemImage: "bolt.fill")
                    .font(.body(13, weight: .bold))
                    .foregroundStyle(tint.deep)
                Spacer()
                Text("\(score) right")
                    .font(.display(14, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .contentTransition(.numericText(value: Double(score)))
            }
            Text(item.0)
                .font(.display(20, weight: .bold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .id(position)
                .transition(.blurReplace)
                .moduleShake(shakes)
            if let answered {
                HStack(spacing: 8) {
                    Image(systemName: answered == item.1 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(answered == item.1 ? Palette.success : Palette.danger)
                    Text(item.2)
                        .font(.body(14, weight: .medium))
                        .foregroundStyle(Palette.ink2)
                }
                .transition(.opacity.combined(with: .offset(y: 6)))
            }
            HStack(spacing: 10) {
                answerButton(false)
                answerButton(true)
            }
        }
        .padding(20)
        .background(.white, in: .rect(cornerRadius: 30, style: .continuous))
        .compositingGroup()
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.1), radius: 24, y: 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: answered)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: position)
    }

    private func answerButton(_ value: Bool) -> some View {
        Button {
            guard answered == nil else { return }
            answered = value
            if value == item.1 {
                score += 1
                Haptics.shared.correct(); SoundFX.shared.play(.correct)
            } else {
                shakes += 1
                Haptics.shared.wrong(); SoundFX.shared.play(.wrong)
            }
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                answered = nil
                position += 1
            }
        } label: {
            Label(value ? "True" : "False", systemImage: value ? "checkmark" : "xmark")
                .font(.display(17, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.answerTile(state(for: value), radius: 18))
    }

    private func state(for value: Bool) -> AnswerTileState {
        guard let answered else { return .idle }
        if value == item.1 { return .correct }
        return answered == value ? .wrong : .dimmed
    }
}

// MARK: - Error

struct LessonErrorView: View {
    var message: String?
    var onRetry: () -> Void
    var onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            IloBackground(lines: false)
            VStack(spacing: 18) {
                HStack {
                    GlassIconButton(systemImage: "xmark", size: 44, action: onClose)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                Spacer()
                BloubView(shape: .circle, color: .ilo, expression: .sad)
                    .frame(width: 140, height: 140)
                    .appear(appeared)
                Text("ilo tripped over a wire")
                    .font(.display(28, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .appear(appeared, delay: 0.06)
                Text(message ?? "Couldn't build this lesson right now.")
                    .font(.body(16, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .appear(appeared, delay: 0.12)
                Spacer()
                Button {
                    onRetry()
                } label: {
                    Label("Try again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.pill(.ink))
                .padding(.horizontal, Metrics.gutter)
                Button("Back to my path", action: onClose)
                    .font(.display(16, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .padding(.bottom, 8)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Intro

/// ilo introduces the lesson before the first module.
struct LessonIntroView: View {
    let lesson: Lesson
    let course: Course
    let node: PathNode
    var onStart: () -> Void
    var onClose: () -> Void

    @State private var appeared = false
    @State private var mood: BloubExpression = .attentive

    private var minutes: Int { max(2, Int((Double(lesson.modules.count) * 0.9).rounded())) }
    private var moduleTypes: [ModuleType] {
        var seen = Set<ModuleType>()
        return lesson.modules.map(\.type).filter { seen.insert($0).inserted }
    }

    var body: some View {
        ZStack {
            IloBackground(tint: course.tint.base, lines: true)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    GlassIconButton(systemImage: "xmark", size: 44, action: onClose)
                    Spacer()
                    Label(node.kind.label, systemImage: node.symbol.isEmpty ? node.kind.defaultSymbol : node.symbol)
                        .font(.body(14, weight: .bold))
                        .foregroundStyle(course.tint.deep)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .glassEffect(.regular, in: .capsule)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(course.title)
                            .font(.body(13, weight: .bold))
                            .tracking(1.1)
                            .textCase(.uppercase)
                            .foregroundStyle(Palette.muted)
                            .appear(appeared)
                        Text(lesson.title.isEmpty ? node.title : lesson.title)
                            .font(.display(38, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .appear(appeared, delay: 0.05)
                            .padding(.top, -12)

                        HStack(alignment: .bottom, spacing: 10) {
                            IloReactor(mood: mood, size: 92)
                            IloSpeechBubble(text: lesson.intro.isEmpty ? "Let's learn something great together!" : lesson.intro)
                        }
                        .appear(appeared, delay: 0.12)

                        HStack(spacing: 8) {
                            Chip(text: "\(lesson.modules.count) steps", systemImage: "square.stack.fill", fill: .white)
                            Chip(text: "~\(minutes) min", systemImage: "clock.fill", fill: .white)
                            Chip(text: "+\(node.xp) XP", systemImage: "bolt.fill", fill: Palette.victory.opacity(0.14), foreground: Palette.victoryDeep)
                        }
                        .appear(appeared, delay: 0.18)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's inside")
                                .font(.display(18, weight: .bold))
                                .foregroundStyle(Palette.ink)
                            ModuleFlowLayout(spacing: 8, lineSpacing: 8) {
                                ForEach(Array(moduleTypes.enumerated()), id: \.element) { i, type in
                                    HStack(spacing: 7) {
                                        Image(systemName: type.symbol)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 28, height: 28)
                                            .background(ModulePastels.deep(i), in: .circle)
                                        Text(type.displayName)
                                            .font(.body(14, weight: .semibold))
                                            .foregroundStyle(Palette.ink)
                                    }
                                    .padding(.leading, 5)
                                    .padding(.trailing, 12)
                                    .padding(.vertical, 5)
                                    .background(ModulePastels.fill(i).opacity(0.55), in: .capsule)
                                    .appear(appeared, delay: 0.24 + Double(i) * 0.05)
                                }
                            }
                        }
                        .card(radius: 30, padding: 18)
                        .appear(appeared, delay: 0.22)
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 18)
                    .padding(.bottom, 20)
                }
                .scrollBounceBehavior(.basedOnSize)

                Button {
                    Haptics.shared.thud()
                    SoundFX.shared.play(.whoosh)
                    onStart()
                } label: {
                    Label("Start lesson", systemImage: "play.fill")
                }
                .buttonStyle(.pill(.ink))
                .accessibilityIdentifier("lesson-start")
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 8)
                .appear(appeared, delay: 0.3)
            }
        }
        .onAppear {
            appeared = true
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                mood = .happy
                try? await Task.sleep(for: .seconds(1.6))
                mood = .excited
            }
        }
    }
}

/// White speech bubble with a tail pointing left/down to ilo.
struct IloSpeechBubble: View {
    var text: String
    var fill: Color = .white

    var body: some View {
        Text(text)
            .font(.body(17, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(alignment: .bottomLeading) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(fill)
                    BubbleTail()
                        .fill(fill)
                        .frame(width: 18, height: 16)
                        .offset(x: -9, y: -12)
                }
            }
            .compositingGroup()
            .shadow(color: Color(hex: 0x3A4470, alpha: 0.08), radius: 16, y: 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.midY + 2))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - 2), control: CGPoint(x: rect.midX + 4, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
