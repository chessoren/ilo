import SwiftUI

/// Post-lesson celebration: lesson complete → streak → level up → daily goal → quests → badges → back to the path.
struct LessonCompleteFlow: View {
    let result: LessonResult
    let summary: RewardSummary
    let lesson: Lesson
    let course: Course
    var onDone: () -> Void

    enum Step: Hashable { case complete, streak, level(Int), dailyGoal, quests, badges }

    @State private var index: Int
    @State private var finished = false

    init(result: LessonResult, summary: RewardSummary, lesson: Lesson, course: Course, startIndex: Int = 0, onDone: @escaping () -> Void) {
        self.result = result
        self.summary = summary
        self.lesson = lesson
        self.course = course
        self.onDone = onDone
        _index = State(initialValue: startIndex)
    }

    private var steps: [Step] {
        var s: [Step] = [.complete]
        if summary.streakExtended { s.append(.streak) }
        if let level = summary.leveledUpTo { s.append(.level(level)) }
        if summary.dailyGoalJustMet { s.append(.dailyGoal) }
        if !summary.questsCompleted.isEmpty { s.append(.quests) }
        if !summary.newBadges.isEmpty { s.append(.badges) }
        return s
    }

    var body: some View {
        let current = min(index, steps.count - 1)
        let advance = { self.next(from: current) }
        ZStack {
            Palette.canvas.ignoresSafeArea()
            Group {
                switch steps[current] {
                case .complete:
                    CompleteScreen(result: result, summary: summary, lesson: lesson, onContinue: advance)
                case .streak:
                    StreakScreen(streak: summary.newStreak, onContinue: advance)
                case .level(let level):
                    LevelUpScreen(level: level, onContinue: advance)
                case .dailyGoal:
                    DailyGoalScreen(onContinue: advance)
                case .quests:
                    QuestsScreen(quests: summary.questsCompleted, onContinue: advance)
                case .badges:
                    BadgesScreen(badges: summary.newBadges, onContinue: advance)
                }
            }
            .id(index)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: index)
    }

    /// `from` is the screen whose button was tapped: a double tap (the old screen stays tappable while it slides out)
    /// must not skip a screen or call `onDone` twice.
    private func next(from step: Int) {
        guard step == min(index, steps.count - 1), !finished else { return }
        if index + 1 < steps.count {
            SoundFX.shared.play(.whoosh)
            index += 1
        } else {
            finished = true
            onDone()
        }
    }
}

// MARK: - Shared

/// Rotating victory sunburst behind hero elements.
struct VictorySunburst: View {
    var color: Color = Palette.victory
    var rays = 14

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { gc, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let r = max(size.width, size.height)
                let spin = t * 0.12
                for i in 0..<rays {
                    let a = spin + Double(i) / Double(rays) * .pi * 2
                    let w = .pi / Double(rays) * 0.55
                    var p = Path()
                    p.move(to: c)
                    p.addLine(to: CGPoint(x: c.x + cos(a - w) * r, y: c.y + sin(a - w) * r))
                    p.addLine(to: CGPoint(x: c.x + cos(a + w) * r, y: c.y + sin(a + w) * r))
                    p.closeSubpath()
                    gc.fill(p, with: .color(color.opacity(0.09)))
                }
            }
            .mask(RadialGradient(colors: [.white, .white.opacity(0)], center: .center, startRadius: 10, endRadius: 220))
        }
        .allowsHitTesting(false)
    }
}

/// Bloub jumping for joy on a loop.
struct CelebrationBloub: View {
    var expression: BloubExpression
    var size: CGFloat = 150
    var color: BloubColor = .ink

    private struct Jump { var y: CGFloat = 0; var sx: CGFloat = 1; var sy: CGFloat = 1; var r: Double = 0 }

    var body: some View {
        BloubView(shape: .circle, color: color, expression: expression)
            .frame(width: size, height: size)
            .keyframeAnimator(initialValue: Jump(), repeating: true) { content, v in
                content
                    .scaleEffect(x: v.sx, y: v.sy, anchor: .bottom)
                    .rotationEffect(.degrees(v.r))
                    .offset(y: v.y)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    LinearKeyframe(0, duration: 0.14)
                    SpringKeyframe(-size * 0.32, duration: 0.3, spring: .snappy)
                    CubicKeyframe(0, duration: 0.26)
                    LinearKeyframe(0, duration: 0.5)
                }
                KeyframeTrack(\.sy) {
                    SpringKeyframe(0.8, duration: 0.14)
                    SpringKeyframe(1.12, duration: 0.2)
                    CubicKeyframe(1, duration: 0.36)
                    SpringKeyframe(0.86, duration: 0.1)
                    SpringKeyframe(1, duration: 0.4)
                }
                KeyframeTrack(\.sx) {
                    SpringKeyframe(1.16, duration: 0.14)
                    SpringKeyframe(0.9, duration: 0.2)
                    CubicKeyframe(1, duration: 0.36)
                    SpringKeyframe(1.12, duration: 0.1)
                    SpringKeyframe(1, duration: 0.4)
                }
                KeyframeTrack(\.r) {
                    LinearKeyframe(0, duration: 0.2)
                    CubicKeyframe(-8, duration: 0.2)
                    CubicKeyframe(6, duration: 0.2)
                    CubicKeyframe(0, duration: 0.6)
                }
            }
    }
}

private struct ContinueButton: View {
    var title = "Continue"
    var kind: PillKind = .victory
    var action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.pill(kind))
            .accessibilityIdentifier("celebration-continue")
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 8)
    }
}

// MARK: - Lesson complete

private struct CompleteScreen: View {
    let result: LessonResult
    let summary: RewardSummary
    let lesson: Lesson
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var confetti = 0
    @State private var mood: BloubExpression = .excited

    private var accuracyPercent: Int { Int((result.accuracy * 100).rounded()) }
    private var timeText: String {
        let s = Int(result.seconds.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
    private var subtitle: String {
        if result.isPerfect { return "Flawless. Not a single mistake!" }
        if result.accuracy >= 0.85 { return "Great work — that stuck." }
        if result.accuracy >= 0.6 { return "Solid! Practice makes it permanent." }
        return "You pushed through. That's how it sticks."
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        CelebrationBloub(expression: mood, size: 140)
                            .scaleEffect(appeared ? 1 : 0.2)
                            .opacity(appeared ? 1 : 0)
                            .frame(maxWidth: .infinity)
                            .frame(height: 230)
                            .background {
                                VictorySunburst()
                                    .frame(width: 440, height: 340)
                                    .opacity(appeared ? 1 : 0)
                                    .scaleEffect(appeared ? 1 : 0.4)
                            }
                        .animation(.spring(response: 0.6, dampingFraction: 0.55), value: appeared)

                        VStack(spacing: 8) {
                            Text(result.isPerfect ? "Perfect lesson!" : "Lesson complete!")
                                .font(.display(36, weight: .heavy))
                                .foregroundStyle(Palette.victory)
                                .appear(appeared, delay: 0.15)
                            Text(subtitle)
                                .font(.body(17, weight: .medium))
                                .foregroundStyle(Palette.muted)
                                .multilineTextAlignment(.center)
                                .appear(appeared, delay: 0.22)
                        }

                        HStack(spacing: 10) {
                            StatTile(title: "TOTAL XP", color: Palette.victory, symbol: "bolt.fill", visible: appeared, delay: 0.35) {
                                CountUpText(value: appeared ? summary.xp : 0, font: .display(26, weight: .heavy))
                            }
                            StatTile(title: accuracyPercent >= 90 ? "AMAZING" : "ACCURACY", color: Palette.success, symbol: "target", visible: appeared, delay: 0.45) {
                                CountUpText(value: appeared ? accuracyPercent : 0, font: .display(26, weight: .heavy), suffix: "%")
                            }
                            StatTile(title: "TIME", color: Palette.orange, symbol: "stopwatch.fill", visible: appeared, delay: 0.55) {
                                Text(timeText).font(.display(26, weight: .heavy))
                            }
                        }

                        if result.bonusXP > 0 || result.bestCombo >= 3 {
                            HStack(spacing: 8) {
                                if result.bestCombo >= 3 {
                                    Chip(text: "Best combo x\(result.bestCombo)", systemImage: "flame.fill", fill: Palette.peach)
                                }
                                if result.bonusXP > 0 {
                                    Chip(text: "+\(result.bonusXP) bonus XP", systemImage: "sparkles", fill: Palette.victory.opacity(0.14), foreground: Palette.victoryDeep)
                                }
                                Chip(text: "+\(summary.gems)", systemImage: "diamond.fill", fill: Palette.sky, foreground: Palette.gem)
                            }
                            .appear(appeared, delay: 0.65)
                        }

                        if !lesson.takeaways.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Saved to your deck", systemImage: "bookmark.fill")
                                        .font(.display(17, weight: .bold))
                                        .foregroundStyle(Palette.ink)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Palette.success)
                                        .symbolEffect(.bounce, value: appeared)
                                }
                                ForEach(Array(lesson.takeaways.prefix(3).enumerated()), id: \.offset) { i, text in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(i + 1)")
                                            .font(.display(13, weight: .heavy))
                                            .foregroundStyle(ModulePastels.deep(i))
                                            .frame(width: 24, height: 24)
                                            .background(ModulePastels.fill(i), in: .circle)
                                        Text(text)
                                            .font(.body(15, weight: .medium))
                                            .foregroundStyle(Palette.ink2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .appear(appeared, delay: 0.85 + Double(i) * 0.08)
                                }
                            }
                            .card(radius: 28, padding: 18)
                            .appear(appeared, delay: 0.75)
                        }
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                ContinueButton(action: onContinue)
                    .appear(appeared, delay: 0.6)
            }
            ConfettiView(trigger: confetti)
                .ignoresSafeArea()
        }
        .onAppear {
            appeared = true
            Haptics.shared.celebrate()
            SoundFX.shared.play(.complete)
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                confetti += 1
                try? await Task.sleep(for: .seconds(2.4))
                mood = .proud
            }
        }
    }
}

/// Duolingo-style stat tile: coloured header band + white body.
private struct StatTile<Value: View>: View {
    var title: String
    var color: Color
    var symbol: String
    var visible: Bool
    var delay: Double
    @ViewBuilder var value: Value

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.body(11, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .bold))
                value
            }
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(.white, in: .rect(cornerRadius: 16, style: .continuous))
            .padding(3)
        }
        .background(color, in: .rect(cornerRadius: 19, style: .continuous))
        .scaleEffect(visible ? 1 : 0.4)
        .rotationEffect(.degrees(visible ? 0 : -8))
        .opacity(visible ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: visible)
        .onChange(of: visible) { _, v in
            guard v else { return }
            Task {
                try? await Task.sleep(for: .seconds(delay))
                Haptics.shared.tap()
                SoundFX.shared.play(.pop)
            }
        }
    }
}

// MARK: - Streak

private struct StreakScreen: View {
    let streak: Int
    var onContinue: () -> Void

    @Environment(AppModel.self) private var model
    @State private var appeared = false
    @State private var lit = false
    @State private var todayFilled = false

    private var weekDays: [Date] {
        let start = Calendar.current.startOfWeek(for: .now)
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Palette.flame.opacity(0.18 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: 180 + CGFloat(i) * 60)
                        .scaleEffect(lit ? 1 : 0.5)
                        .opacity(lit ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1 + Double(i) * 0.08), value: lit)
                }
                Circle()
                    .fill(RadialGradient(colors: [Palette.gold.opacity(0.55), Palette.flame.opacity(0)], center: .center, startRadius: 10, endRadius: 140))
                    .frame(width: 280, height: 280)
                    .scaleEffect(lit ? 1 : 0.2)
                    .animation(.easeOut(duration: 0.8), value: lit)
                Image(systemName: "flame.fill")
                    .font(.system(size: 130, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [Palette.gold, Palette.flame, Color(hex: 0xF0554B)], startPoint: .top, endPoint: .bottom))
                    .symbolEffect(.bounce, options: .repeat(2), value: lit)
                    .scaleEffect(lit ? 1 : 0.1, anchor: .bottom)
                    .animation(.spring(response: 0.55, dampingFraction: 0.5), value: lit)
                    .shadow(color: Palette.flame.opacity(0.45), radius: 24, y: 8)
            }
            .frame(height: 300)

            CountUpText(value: appeared ? streak : max(streak - 1, 0), font: .display(96, weight: .black))
                .foregroundStyle(Palette.flame)
                .padding(.top, -10)
            Text(streak == 1 ? "day streak!" : "day streak!")
                .font(.display(28, weight: .heavy))
                .foregroundStyle(Palette.flame)
                .appear(appeared, delay: 0.3)

            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { i, day in
                    let isToday = Calendar.current.isDateInToday(day)
                    let active = model.player.activeDays.contains(Calendar.current.startOfDay(for: day)) && (!isToday || todayFilled)
                    VStack(spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.body(13, weight: .bold))
                            .foregroundStyle(isToday ? Palette.flame : Palette.muted)
                        ZStack {
                            Circle().fill(active ? Palette.flame : Palette.canvasDeep)
                            if active {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(width: 34, height: 34)
                        .scaleEffect(isToday && todayFilled ? 1.12 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: todayFilled)
                    }
                    .frame(maxWidth: .infinity)
                    .appear(appeared, delay: 0.4 + Double(i) * 0.04)
                }
            }
            .padding(16)
            .background(.white, in: .rect(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 26)

            Text("Learn tomorrow to keep your flame alive.")
                .font(.body(16, weight: .medium))
                .foregroundStyle(Palette.muted)
                .padding(.top, 16)
                .appear(appeared, delay: 0.6)
            Spacer()
            ContinueButton(action: onContinue)
                .appear(appeared, delay: 0.7)
        }
        .onAppear {
            appeared = true
            lit = true
            Haptics.shared.ignite()
            SoundFX.shared.play(.streak)
            Task {
                try? await Task.sleep(for: .seconds(1.1))
                todayFilled = true
                Haptics.shared.thud()
                SoundFX.shared.play(.pop)
            }
        }
    }
}

// MARK: - Level up

private struct LevelUpScreen: View {
    let level: Int
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var confetti = 0

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    TickRing(progress: appeared ? 1 : 0, tint: Palette.victory, ticks: 80)
                        .frame(width: 220, height: 220)
                    Circle()
                        .fill(LinearGradient(colors: [Palette.victory, Palette.victoryDeep], startPoint: .top, endPoint: .bottom))
                        .frame(width: 150, height: 150)
                        .shadow(color: Palette.victory.opacity(0.4), radius: 20, y: 10)
                        .overlay {
                            VStack(spacing: -4) {
                                Text("LEVEL").font(.body(13, weight: .heavy)).tracking(1.5)
                                CountUpText(value: appeared ? level : max(level - 1, 1), font: .display(64, weight: .black))
                            }
                            .foregroundStyle(.white)
                        }
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appeared)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background {
                    VictorySunburst(color: Palette.victory, rays: 18)
                        .frame(width: 440, height: 440)
                }
                Text("Level up!")
                    .font(.display(40, weight: .heavy))
                    .foregroundStyle(Palette.victory)
                    .appear(appeared, delay: 0.2)
                Text("You reached level \(level). ilo is seriously impressed.")
                    .font(.body(17, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .appear(appeared, delay: 0.3)
                Spacer()
                ContinueButton(action: onContinue)
                    .appear(appeared, delay: 0.5)
            }
            ConfettiView(trigger: confetti).ignoresSafeArea()
        }
        .onAppear {
            appeared = true
            Haptics.shared.levelUp()
            SoundFX.shared.play(.levelUp)
            confetti += 1
        }
    }
}

// MARK: - Daily goal

private struct DailyGoalScreen: View {
    var onContinue: () -> Void

    @Environment(AppModel.self) private var model
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                TickRing(progress: appeared ? 1 : 0.35, tint: Palette.success, ticks: 90)
                    .frame(width: 240, height: 240)
                VStack(spacing: 2) {
                    Image(systemName: "target")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Palette.success)
                        .symbolEffect(.bounce, value: appeared)
                    Text("\(model.player.todayXP)/\(model.player.dailyGoalXP)")
                        .font(.display(30, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text("XP today").font(.body(14, weight: .semibold)).foregroundStyle(Palette.muted)
                }
            }
            Text("Daily goal reached!")
                .font(.display(34, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .appear(appeared, delay: 0.2)
            HStack(spacing: 10) {
                BloubView(shape: model.player.bloubShape, color: model.player.bloubColor, expression: .proud)
                    .frame(width: 54, height: 54)
                IloSpeechBubble(text: "That's how habits are built. See you tomorrow?")
            }
            .padding(.horizontal, Metrics.gutter)
            .appear(appeared, delay: 0.35)
            Spacer()
            ContinueButton(kind: .success, action: onContinue)
                .appear(appeared, delay: 0.5)
        }
        .onAppear {
            appeared = true
            Haptics.shared.celebrate()
            SoundFX.shared.play(.complete)
        }
    }
}

// MARK: - Quests

private struct QuestsScreen: View {
    let quests: [Quest]
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var filled = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Palette.periwinkleDeep)
                .symbolEffect(.bounce, value: appeared)
                .appear(appeared)
            Text(quests.count == 1 ? "Quest complete!" : "\(quests.count) quests complete!")
                .font(.display(34, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .appear(appeared, delay: 0.1)
            VStack(spacing: 12) {
                ForEach(Array(quests.enumerated()), id: \.element.id) { i, quest in
                    HStack(spacing: 14) {
                        Image(systemName: quest.symbol)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(quest.tint.deep)
                            .frame(width: 48, height: 48)
                            .background(quest.tint.soft, in: .circle)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(quest.title)
                                .font(.display(16, weight: .bold))
                                .foregroundStyle(Palette.ink)
                            GlossyProgressBar(progress: filled ? 1 : 0.5, tint: Palette.gold, height: 12)
                        }
                        Label("\(quest.reward)", systemImage: "diamond.fill")
                            .font(.display(15, weight: .bold))
                            .foregroundStyle(Palette.gem)
                    }
                    .card(radius: 24, padding: 14)
                    .appear(appeared, delay: 0.2 + Double(i) * 0.1)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            Text("Claim your gems from the Quests tab.")
                .font(.body(15, weight: .medium))
                .foregroundStyle(Palette.muted)
                .appear(appeared, delay: 0.5)
            Spacer()
            ContinueButton(action: onContinue)
                .appear(appeared, delay: 0.55)
        }
        .onAppear {
            appeared = true
            Haptics.shared.celebrate()
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation { filled = true }
                for _ in quests {
                    SoundFX.shared.play(.coin)
                    try? await Task.sleep(for: .milliseconds(160))
                }
            }
        }
    }
}

// MARK: - Badges

private struct BadgesScreen: View {
    let badges: [Badge]
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var confetti = 0

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                Spacer()
                Text(badges.count == 1 ? "New badge!" : "\(badges.count) new badges!")
                    .font(.display(36, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .appear(appeared)
                // Scrolls when a lesson unlocks many badges at once, so Continue never gets pushed off screen.
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 14)], spacing: 14) {
                        ForEach(Array(badges.enumerated()), id: \.element) { i, badge in
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [ModulePastels.fill(i), ModulePastels.deep(i)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    Circle().strokeBorder(.white.opacity(0.7), lineWidth: 4).padding(6)
                                    Image(systemName: badge.symbol)
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 96, height: 96)
                                .shadow(color: ModulePastels.deep(i).opacity(0.35), radius: 14, y: 8)
                                .rotation3DEffect(.degrees(appeared ? 0 : 180), axis: (0, 1, 0))
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2 + Double(i) * 0.15), value: appeared)
                                Text(badge.title)
                                    .font(.display(17, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                                Text(badge.detail)
                                    .font(.body(13, weight: .medium))
                                    .foregroundStyle(Palette.muted)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .card(radius: 28, padding: 16)
                            .appear(appeared, delay: 0.15 + Double(i) * 0.12)
                        }
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.vertical, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .fixedSize(horizontal: false, vertical: badges.count <= 2)
                Spacer()
                ContinueButton(action: onContinue)
                    .appear(appeared, delay: 0.5)
            }
            ConfettiView(trigger: confetti).ignoresSafeArea()
        }
        .onAppear {
            appeared = true
            Haptics.shared.levelUp()
            SoundFX.shared.play(.levelUp)
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                confetti += 1
            }
        }
    }
}
