import SwiftUI

/// The first-run experience: one continuous flow from splash to commitment. Ends with `model.hasOnboarded = true`
/// (RootView then shows the paywall).
struct OnboardingFlow: View {
    @Environment(AppModel.self) private var model
    @State private var answers = OnboardingAnswers()
    @State private var step: OnboardingStep = .splash
    @State private var forward = true

    var body: some View {
        ZStack {
            IloBackground(tint: backgroundTint)
                .animation(.smooth(duration: 0.8), value: step)

            VStack(spacing: 0) {
                if step.showsChrome {
                    topBar
                        .padding(.horizontal, Metrics.gutter)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if let header = header {
                    mascotHeader(header)
                        .padding(.horizontal, Metrics.gutter)
                        .padding(.top, 14)
                }
                ZStack {
                    stepView
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .offset(x: forward ? 80 : -80).combined(with: .opacity),
                            removal: .offset(x: forward ? -80 : 80).combined(with: .opacity)))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let cta = defaultCTA {
                Button {
                    advance()
                } label: {
                    HStack(spacing: 8) {
                        Text(cta)
                        Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                    }
                }
                .buttonStyle(.pill(.ink))
                .accessibilityIdentifier("onboarding-continue")
                .disabled(!canContinue)
                .animation(.smooth, value: canContinue)
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .obBottomFade()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear(perform: applyDebugHooks)
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack(spacing: 14) {
            GlassIconButton(systemImage: "chevron.left", size: 44) { back() }
                .opacity(step.canGoBack ? 1 : 0)
                .disabled(!step.canGoBack)
                .animation(.smooth, value: step.canGoBack)
            GlossyProgressBar(progress: step.progress, tint: Palette.periwinkleDeep, height: 14)
            Text("\(step.rawValue - OnboardingStep.howItWorks.rawValue + 1)/\(OnboardingStep.commit.rawValue - OnboardingStep.howItWorks.rawValue + 1)")
                .font(.display(13, weight: .bold))
                .foregroundStyle(Palette.muted)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(step.rawValue)))
                .frame(minWidth: 34)
        }
        .frame(height: 48)
    }

    private struct Header: Equatable {
        var line: String
        var title: String
    }

    private func mascotHeader(_ header: Header) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                OBBounce(trigger: answers.reactions) {
                    BloubView(shape: .circle, color: .ink, expression: iloExpression, lookAt: iloLookAt)
                        .frame(width: 66, height: 66)
                }
                OBSpeechBubble(text: header.line)
                    .id(header.line)
                    .transition(.opacity)
            }
            Text(header.title)
                .font(.display(31, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .id(header.title)
                .transition(.asymmetric(insertion: .offset(y: 12).combined(with: .opacity), removal: .opacity))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Steps

    @ViewBuilder private var stepView: some View {
        switch step {
        case .splash: OBSplashStep { advance(from: .splash) }
        case .welcome: OBWelcomeStep { advance(from: .welcome) }
        case .howItWorks: OBHowItWorksStep()
        case .goal: OBGoalStep(answers: answers) { if canContinue { advance() } }
        case .why: OBWhyStep(answers: answers)
        case .deadline: OBDeadlineStep(answers: answers)
        case .level: OBLevelStep(answers: answers)
        case .styles: OBStylesStep(answers: answers)
        case .minutes: OBMinutesStep(answers: answers)
        case .name: OBNameStep(answers: answers) { if canContinue { advance() } }
        case .bloub: OBBloubMakerStep(answers: answers)
        case .reminders: OBRemindersStep(answers: answers) { advance(from: .reminders) }
        case .building:
            PathBuildingView(request: answers.request) { course in
                answers.course = course
                advance(from: .building)
            }
        case .commit: OBCommitStep(answers: answers) { finish() }
        }
    }

    private var header: Header? {
        let name = answers.displayName
        switch step {
        case .howItWorks:
            return Header(line: "Hi, I'm ilo! I turn any goal into a game you can play in minutes a day.", title: "Here's the magic")
        case .goal:
            let line = answers.trimmedGoal.count > 3 ? "Ooh, I already have ideas…" : "Anything. Big, small, weird. Try me!"
            return Header(line: line, title: "What do you want to learn?")
        case .why:
            return Header(line: "\(shortGoal)? I love it!", title: "Why does it matter to you?")
        case .deadline:
            let line = answers.motivation.map { "\($0.title). Got it! Is there a deadline?" } ?? "Is there a date circled on your calendar?"
            return Header(line: line, title: "When do you need it by?")
        case .level:
            let line: String = switch answers.level {
            case .zero: "A fresh start! I'll go gently."
            case .beginner: "Nice, we'll build on what you know."
            case .intermediate: "Ooh, we can skip the boring bits."
            case .advanced: "Challenge accepted. I'll push you."
            case nil: "No judgement. Everyone starts somewhere."
            }
            return Header(line: line, title: "How much do you already know?")
        case .styles:
            let line = answers.styles.count >= 3 ? "A little bit of everything. My favourite!" : "Pick as many as you like. I'll mix them into every lesson."
            return Header(line: line, title: "How do you like to learn?")
        case .minutes:
            return Header(line: "Small daily sessions beat long weekend binges.", title: "How much time a day?")
        case .name:
            let line = answers.trimmedName.isEmpty ? "I'm ilo. And you are…?" : "Nice to meet you, \(answers.trimmedName)!"
            return Header(line: line, title: "What should I call you?")
        case .reminders:
            return Header(line: "A tiny nudge a day keeps the streak alive.", title: "Want a daily reminder?")
        case .commit:
            return Header(line: "Last thing, \(name). Make a promise to yourself.", title: "Commit to your streak")
        case .splash, .welcome, .bloub, .building:
            return nil
        }
    }

    private var shortGoal: String {
        let goal = answers.goalLabel
        return goal.count > 34 ? String(goal.prefix(32)) + "…" : goal
    }

    private var iloExpression: BloubExpression {
        switch step {
        case .howItWorks: return .happy
        case .goal:
            let n = answers.trimmedGoal.count
            return n == 0 ? .curious : (n > 8 ? .excited : .attentive)
        case .why: return answers.motivation == nil ? .curious : .happy
        case .deadline:
            switch answers.deadline {
            case .week: return .surprised
            case .month: return .happy
            case .quarter: return .proud
            case .noRush: return .sleepy
            case .date: return .excited
            case nil: return .attentive
            }
        case .level:
            switch answers.level {
            case .zero: return .shy
            case .beginner: return .happy
            case .intermediate: return .proud
            case .advanced: return .excited
            case nil: return .curious
            }
        case .styles:
            return answers.styles.isEmpty ? .curious : (answers.styles.count >= 3 ? .laughing : .happy)
        case .minutes:
            switch answers.pace?.minutes {
            case 20: return .surprised
            case 15: return .proud
            case .some: return .happy
            case nil: return .attentive
            }
        case .name: return answers.trimmedName.isEmpty ? .shy : .happy
        case .reminders: return .attentive
        case .commit: return .proud
        default: return .happy
        }
    }

    private var iloLookAt: CGPoint? {
        switch step {
        case .goal:
            let n = Double(answers.goal.count)
            return CGPoint(x: -0.4 + min(n / 30, 1) * 1.1, y: 0.8)
        case .name:
            let n = Double(answers.name.count)
            return CGPoint(x: -0.2 + min(n / 12, 1) * 0.6, y: 0.8)
        case .why, .deadline, .level, .styles, .minutes:
            return CGPoint(x: 0.2, y: 0.9)
        default:
            return nil
        }
    }

    private var defaultCTA: String? {
        switch step {
        case .howItWorks: "Love it"
        case .goal, .why, .deadline, .level, .styles, .minutes, .name: "Continue"
        case .bloub: "That's me!"
        default: nil
        }
    }

    private var canContinue: Bool {
        switch step {
        case .goal: answers.trimmedGoal.count >= 2
        case .why: answers.motivation != nil
        case .deadline: answers.deadline != nil
        case .level: answers.level != nil
        case .styles: !answers.styles.isEmpty
        case .minutes: answers.pace != nil
        case .name: !answers.trimmedName.isEmpty
        default: true
        }
    }

    private var backgroundTint: Color {
        switch step {
        case .splash, .welcome: Palette.periwinkle
        case .bloub: answers.color.color
        case .commit: Palette.orange
        case .building: Palette.lavender
        default: Palette.periwinkle
        }
    }

    // MARK: Navigation

    private func advance(from expected: OnboardingStep? = nil) {
        if let expected, expected != step { return }
        guard let next = step.next else { return }
        Haptics.shared.softTap()
        SoundFX.shared.play(.bubble)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            forward = true
            step = next
        }
    }

    private func back() {
        guard step.canGoBack, var previous = step.previous else { return }
        if previous == .splash { previous = .welcome }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            forward = false
            step = previous
        }
    }

    private func finish() {
        var player = model.player
        player.name = answers.trimmedName
        player.bloubShape = answers.shape
        player.bloubColor = answers.color
        player.dailyGoalXP = answers.pace?.xp ?? 20
        player.streakGoal = answers.streakGoal
        player.reminderHour = answers.reminderHour
        model.player = player
        model.lastRequest = answers.request
        model.questsDay = .distantPast
        model.refreshDailyState()
        model.hasOnboarded = true
        model.save()
    }

    private func applyDebugHooks() {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "onboardingStep"), let n = Int(raw),
           let target = OnboardingStep(rawValue: n) {
            answers.fillForTesting(upTo: target)
            step = target
        }
        #endif
    }
}

#Preview {
    OnboardingFlow()
        .environment(AppModel())
        .environment(PurchaseService())
}
