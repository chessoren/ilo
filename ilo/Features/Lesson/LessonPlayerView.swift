import SwiftUI

/// Full-screen lesson player. Presented with `.fullScreenCover`.
///
/// Flow: generate (bloub thinking + warm-up) → intro from ilo → modules with Check / feedback → celebration sequence.
struct LessonPlayerView: View {
    let course: Course
    let node: PathNode
    var onClose: () -> Void

    @Environment(AppModel.self) private var model

    private enum Stage: Equatable { case loading, failed, intro, playing, complete }

    @State private var stage: Stage = .loading
    @State private var lesson: Lesson?
    @State private var errorText: String?
    @State private var loadAttempt = 0
    @State private var runner: LessonRunner?
    @State private var result: LessonResult?
    @State private var summary: RewardSummary?

    var body: some View {
        ZStack {
            switch stage {
            case .loading:
                LessonLoadingView(course: course, node: node, onClose: onClose)
                    .transition(.opacity)
            case .failed:
                LessonErrorView(message: errorText, onRetry: retry, onClose: onClose)
                    .transition(.opacity)
            case .intro:
                if let lesson {
                    LessonIntroView(lesson: lesson, course: course, node: node, onStart: start, onClose: onClose)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                                removal: .opacity.combined(with: .offset(y: -30))))
                }
            case .playing:
                if let runner {
                    LessonPlayingView(runner: runner, onQuit: onClose)
                        .transition(.opacity.combined(with: .offset(y: 40)))
                }
            case .complete:
                if let result, let summary, let lesson {
                    LessonCompleteFlow(result: result, summary: summary, lesson: lesson, course: course, onDone: onClose)
                        .transition(.opacity)
                }
            }
        }
        .animation(.smooth(duration: 0.45), value: stage)
        .task(id: loadAttempt) { await load() }
        .onChange(of: runner?.isFinished ?? false) { _, finished in
            if finished { finish() }
        }
    }

    // MARK: Actions

    private func load() async {
        if lesson != nil { return }
        do {
            let generated = try await model.lesson(for: node, in: course)
            lesson = generated
            stage = .intro
            SoundFX.shared.play(.bubble)
            Haptics.shared.softTap()
            #if DEBUG
            if LessonDemoArgs.has("-demoSkipIntro") { start() }
            #endif
        } catch {
            errorText = error.localizedDescription
            stage = .failed
            Haptics.shared.warning()
        }
    }

    private func retry() {
        errorText = nil
        stage = .loading
        loadAttempt += 1
    }

    private func start() {
        guard let lesson else { return }
        let r = LessonRunner(lesson: lesson, course: course, node: node, ai: model.ai)
        r.onMistake = { [model] text in model.recordMistake(text) }
        r.onComboMilestone = { _ in
            Task {
                try? await Task.sleep(for: .milliseconds(280))
                Haptics.shared.thud()
                SoundFX.shared.play(.coin)
            }
        }
        runner = r
        stage = .playing
    }

    private func finish() {
        guard let runner, runner.isFinished, result == nil else { return }
        let r = runner.makeResult()
        result = r
        summary = model.complete(r)
        stage = .complete
    }
}

// MARK: - Playing

/// The in-lesson screen: glass top bar, module area with ilo, Check bar / feedback panel.
struct LessonPlayingView: View {
    let runner: LessonRunner
    var onQuit: () -> Void

    @State private var showQuit = false

    private var session: ModuleSession { runner.session }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 6)
            moduleHeader
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 14)
            ZStack {
                ModuleRouter.view(for: session)
                    .id(session.module.id)
                    .transition(ModuleSlideTransition())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.86), value: runner.index)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(isPresented: $showQuit) {
            LessonQuitSheet(onStay: { showQuit = false }, onQuit: {
                showQuit = false
                // Late resolves (delayed grading, timers) must not play sounds or record results after quitting.
                // (Not done in onDisappear: full-screen covers inside modules — call, camera — also trigger it.)
                runner.session.detach()
                onQuit()
            })
            .presentationDetents([.height(420)])
            .presentationCornerRadius(36)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            GlassIconButton(systemImage: "xmark", size: 44) {
                Haptics.shared.warning()
                showQuit = true
            }
            .accessibilityIdentifier("lesson-close")
            GlossyProgressBar(progress: runner.progress, tint: runner.combo >= 3 ? Palette.flame : Palette.success, height: 16)
                .animation(.smooth, value: runner.combo >= 3)
            if runner.combo >= 3 {
                LessonComboPill(combo: runner.combo)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: runner.combo >= 3)
        .frame(height: 48)
    }

    // MARK: Module header (ilo + module type)

    private var moduleHeader: some View {
        HStack(spacing: 10) {
            IloReactor(mood: session.mood, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                if runner.current?.isRetry == true {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                        Text("Previous mistake")
                    }
                    .font(.body(12, weight: .bold))
                    .foregroundStyle(Palette.orange)
                }
                HStack(spacing: 6) {
                    Image(systemName: session.module.type.symbol)
                        .font(.system(size: 12, weight: .bold))
                    Text(session.module.type.displayName)
                        .font(.body(13, weight: .bold))
                }
                .foregroundStyle(session.tint.deep)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(session.tint.soft, in: .capsule)
                .contentTransition(.opacity)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("module-\(session.module.type.rawValue)")
            }
            Spacer()
        }
        .animation(.smooth, value: runner.index)
    }

    // MARK: Bottom

    @ViewBuilder
    private var bottomBar: some View {
        ZStack(alignment: .bottom) {
            if session.isResolved {
                LessonFeedbackPanel(session: session, combo: runner.combo) {
                    session.finish()
                }
                .id(session.module.id)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if !session.hidesCheckBar {
                LessonCheckBar(session: session)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: session.isResolved)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: session.hidesCheckBar)
    }
}

/// Slide + blur between modules.
struct ModuleSlideTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .offset(x: phase == .willAppear ? 70 : (phase == .didDisappear ? -70 : 0))
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 12)
            .scaleEffect(phase.isIdentity ? 1 : 0.97)
    }
}

// MARK: - Pieces

/// ilo in the corner, bouncing whenever its mood changes.
struct IloReactor: View {
    var mood: BloubExpression
    var size: CGFloat = 46
    var mode: BloubMode = .face

    private struct Bounce { var y: CGFloat = 0; var sx: CGFloat = 1; var sy: CGFloat = 1 }

    var body: some View {
        BloubView(shape: .circle, color: .ilo, expression: mood, mode: mode)
            .frame(width: size, height: size)
            .keyframeAnimator(initialValue: Bounce(), trigger: mood) { content, v in
                content
                    .scaleEffect(x: v.sx, y: v.sy, anchor: .bottom)
                    .offset(y: v.y)
            } keyframes: { _ in
                KeyframeTrack(\.sy) {
                    SpringKeyframe(0.82, duration: 0.1)
                    SpringKeyframe(1.12, duration: 0.18)
                    SpringKeyframe(1, duration: 0.3)
                }
                KeyframeTrack(\.sx) {
                    SpringKeyframe(1.14, duration: 0.1)
                    SpringKeyframe(0.92, duration: 0.18)
                    SpringKeyframe(1, duration: 0.3)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(0, duration: 0.1)
                    SpringKeyframe(-size * 0.28, duration: 0.18)
                    SpringKeyframe(0, duration: 0.3)
                }
            }
    }
}

/// 🔥 x5 combo counter.
struct LessonComboPill: View {
    var combo: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [Palette.gold, Palette.flame], startPoint: .top, endPoint: .bottom))
                .symbolEffect(.bounce, value: combo)
            Text("x\(combo)")
                .font(.display(16, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText(value: Double(combo)))
                .animation(.spring, value: combo)
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .glassEffect(.regular.tint(Palette.flame.opacity(0.18)), in: .capsule)
    }
}

/// Liquid Glass bar holding the Check pill.
struct LessonCheckBar: View {
    let session: ModuleSession

    var body: some View {
        Button {
            session.check()
        } label: {
            Text(session.checkTitle)
                .contentTransition(.opacity)
        }
        .buttonStyle(.pill(.ink))
        .accessibilityIdentifier("lesson-check")
        .disabled(!session.canCheck)
        .animation(.smooth(duration: 0.2), value: session.canCheck)
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 36, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

/// Green "Nice!" / red "Not quite" panel after grading.
struct LessonFeedbackPanel: View {
    let session: ModuleSession
    var combo: Int
    var onContinue: () -> Void

    @State private var title = ""
    @State private var appeared = false

    private var correct: Bool { session.phase == .correct }
    private var accent: Color { correct ? Palette.success : Palette.danger }
    private var textColor: Color { correct ? Color(hex: 0x1C7F4E) : Color(hex: 0xB3322A) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(.white)
                    Image(systemName: correct ? "checkmark" : "xmark")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(accent)
                        .symbolEffect(.bounce, value: appeared)
                }
                .frame(width: 42, height: 42)
                .scaleEffect(appeared ? 1 : 0.3)
                Text(title)
                    .font(.display(26, weight: .heavy))
                    .foregroundStyle(textColor)
                Spacer()
                if correct && combo >= 3 {
                    Label("\(combo) in a row", systemImage: "flame.fill")
                        .font(.body(13, weight: .bold))
                        .foregroundStyle(Palette.flame)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.white, in: .capsule)
                }
            }
            if !correct, let answer = session.correctAnswer, !answer.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Correct answer:")
                        .font(.body(15, weight: .bold))
                    Text(answer)
                        .font(.body(16, weight: .semibold))
                        .lineLimit(6)
                        .minimumScaleFactor(0.85)
                }
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(textColor)
            }
            if let feedback = session.feedback, !feedback.isEmpty {
                Text(feedback)
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(textColor.opacity(0.9))
                    .lineLimit(8)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button(correct ? "Continue" : "Got it") {
                onContinue()
            }
            .buttonStyle(.pill(correct ? .success : .danger))
            .accessibilityIdentifier("lesson-feedback-continue")
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                .fill(correct ? Palette.successSoft : Palette.dangerSoft)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: accent.opacity(0.18), radius: 20, y: -4)
        }
        .onAppear {
            title = Self.title(correct: correct, combo: combo)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.05)) { appeared = true }
        }
    }

    static func title(correct: Bool, combo: Int) -> String {
        if correct {
            if combo >= 5 { return ["Unstoppable!", "On fire!", "Legendary!"].randomElement()! }
            return ["Nice!", "Brilliant!", "Nailed it!", "Spot on!", "Amazing!", "Great job!"].randomElement()!
        }
        return ["Not quite", "Almost!", "So close"].randomElement()!
    }
}

/// "Wait, don't go!" confirm sheet.
struct LessonQuitSheet: View {
    var onStay: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            BloubView(shape: .circle, color: .ilo, expression: .sad)
                .frame(width: 96, height: 96)
                .padding(.top, 28)
            Text("Wait, don't go!")
                .font(.display(28, weight: .heavy))
                .foregroundStyle(Palette.ink)
            Text("You'll lose your progress in this lesson.")
                .font(.body(16, weight: .medium))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 8)
            Button("Keep learning", action: onStay)
                .buttonStyle(.pill(.ink))
                .accessibilityIdentifier("quit-stay")
            Button {
                Haptics.shared.thud()
                onQuit()
            } label: {
                Text("End lesson")
                    .font(.display(17, weight: .bold))
                    .foregroundStyle(Palette.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.squish)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}
