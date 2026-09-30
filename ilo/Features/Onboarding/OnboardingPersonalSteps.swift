import SwiftUI

// MARK: - Bloub maker

/// Build your own bloub: silhouette + colour, with a live morph. Only level-1 options are unlocked.
struct OBBloubMakerStep: View {
    @Bindable var answers: OnboardingAnswers
    @State private var expression: BloubExpression = .happy
    @State private var bounce = 0
    @State private var lockedMessage: String?
    @State private var shake = 0
    @State private var visible = false
    private let playerLevel = 1

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Make your own bloub")
                        .font(.display(31, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text("This is you. Level up to unlock more shapes and colours.")
                        .font(.body(15))
                        .foregroundStyle(Palette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appear(visible)

                preview
                    .appear(visible, delay: 0.08)

                section("Shape") {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(BloubShape.allCases) { shape in shapeButton(shape) }
                        }
                        .padding(.horizontal, Metrics.gutter)
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                    .padding(.horizontal, -Metrics.gutter)
                }
                .appear(visible, delay: 0.14)

                section("Colour") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                        ForEach(BloubColor.allCases) { color in colorButton(color) }
                    }
                }
                .appear(visible, delay: 0.2)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear { visible = true }
    }

    private var preview: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [answers.color.color.opacity(0.35), .clear], center: .center, startRadius: 10, endRadius: 130))
                .frame(width: 260, height: 260)
                .animation(.smooth(duration: 0.5), value: answers.color)
            OBBounce(trigger: bounce) {
                BloubView(shape: answers.shape, color: answers.color, expression: expression)
                    .frame(width: 170, height: 170)
            }
            .keyframeAnimator(initialValue: 0.0, trigger: shake) { view, x in
                view.offset(x: x)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(-10, duration: 0.06)
                    LinearKeyframe(10, duration: 0.08)
                    LinearKeyframe(-6, duration: 0.08)
                    LinearKeyframe(0, duration: 0.08)
                }
            }
            VStack {
                if let lockedMessage {
                    Label(lockedMessage, systemImage: "lock.fill")
                        .font(.body(14, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .glassEffect(.regular, in: .capsule)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                HStack {
                    Text(answers.displayName.capitalized)
                        .font(.display(22, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Chip(text: "Level 1", systemImage: "star.fill", fill: .white)
                }
            }
            .frame(height: 250)
            .overlay(alignment: .topTrailing) {
                GlassIconButton(systemImage: "dice.fill", size: 46) { randomize() }
                    .padding(.top, 40)
            }
        }
        .frame(height: 250)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: lockedMessage)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.display(17, weight: .bold)).foregroundStyle(Palette.ink)
            content()
        }
    }

    private func shapeButton(_ shape: BloubShape) -> some View {
        let locked = shape.unlockLevel > playerLevel
        let selected = answers.shape == shape
        return Button {
            if locked { deny("\(shape.title) unlocks at level \(shape.unlockLevel)") } else { pick { answers.shape = shape } }
        } label: {
            BloubView(shape: shape, color: locked ? .grey : answers.color, expression: .neutral, alive: false)
                .frame(width: 40, height: 40)
                .opacity(locked ? 0.45 : 1)
                .frame(width: 66, height: 66)
                .background(.white, in: .rect(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(selected ? Palette.ink : Palette.hairline, lineWidth: selected ? 2.5 : 1)
                }
                .overlay(alignment: .bottomTrailing) { if locked { lockBadge(shape.unlockLevel) } }
                .scaleEffect(selected ? 1.06 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
        }
        .buttonStyle(.squish(0.92))
    }

    private func colorButton(_ color: BloubColor) -> some View {
        let locked = color.unlockLevel > playerLevel
        let selected = answers.color == color
        return Button {
            if locked { deny("\(color.rawValue.capitalized) unlocks at level \(color.unlockLevel)") } else { pick { answers.color = color } }
        } label: {
            Circle()
                .fill(color.color)
                .overlay { Circle().strokeBorder(Palette.hairline, lineWidth: 1) }
                .overlay {
                    if locked {
                        Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.9))
                    } else if selected {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy)).foregroundStyle(color.eyeColor)
                    }
                }
                .opacity(locked ? 0.35 : 1)
                .padding(4)
                .overlay { Circle().strokeBorder(selected ? Palette.ink : .clear, lineWidth: 2.5) }
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(selected ? 1.08 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
        }
        .buttonStyle(.squish(0.9))
    }

    private func lockBadge(_ level: Int) -> some View {
        Text("Lv \(level)")
            .font(.display(10, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .frame(height: 18)
            .background(Palette.ink, in: .capsule)
            .offset(x: 4, y: 4)
    }

    private func pick(_ change: () -> Void) {
        change()
        bounce += 1
        Haptics.shared.tick()
        SoundFX.shared.play(.bubble)
        answers.react()
        flash(.excited)
    }

    private func deny(_ message: String) {
        Haptics.shared.warning()
        SoundFX.shared.play(.wrong)
        shake += 1
        lockedMessage = message
        flash(.sad)
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            if lockedMessage == message { lockedMessage = nil }
        }
    }

    private func randomize() {
        let shapes = BloubShape.allCases.filter { $0.unlockLevel <= playerLevel && $0 != answers.shape }
        let colors = BloubColor.allCases.filter { $0.unlockLevel <= playerLevel && $0 != answers.color }
        pick {
            if let s = shapes.randomElement() { answers.shape = s }
            if let c = colors.randomElement() { answers.color = c }
        }
        flash(.laughing)
    }

    private func flash(_ e: BloubExpression) {
        expression = e
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            if expression == e { expression = .happy }
        }
    }
}

// MARK: - Reminders

struct OBRemindersStep: View {
    @Bindable var answers: OnboardingAnswers
    var onNext: () -> Void
    @State private var dropped = false
    @State private var asking = false
    @State private var visible = false

    private struct Slot: Identifiable {
        var id: Int { hour }
        var hour: Int
        var title: String
        var symbol: String
        var color: Color
    }

    private let slots: [Slot] = [
        .init(hour: 8, title: "Morning", symbol: "sunrise.fill", color: Palette.orange),
        .init(hour: 12, title: "Lunch", symbol: "sun.max.fill", color: Palette.gold),
        .init(hour: 19, title: "Evening", symbol: "sunset.fill", color: Palette.flame),
        .init(hour: 21, title: "Night", symbol: "moon.stars.fill", color: Palette.periwinkleDeep),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    notificationMock
                        .offset(y: dropped ? 0 : -80)
                        .opacity(dropped ? 1 : 0)
                        .scaleEffect(dropped ? 1 : 0.9)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("When suits you best?").font(.display(17, weight: .bold)).foregroundStyle(Palette.ink)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(slots) { slot in slotButton(slot) }
                        }
                    }
                    .appear(visible, delay: 0.3)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 20)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 6) {
                Button {
                    Task { await enable() }
                } label: {
                    HStack(spacing: 8) {
                        if asking { ProgressView().tint(.white) }
                        Image(systemName: "bell.badge.fill")
                        Text("Remind me at \(hourLabel(answers.reminderHour))")
                    }
                }
                .buttonStyle(.pill(.ink))
                .disabled(asking)
                Button("Not now") {
                    Haptics.shared.tap()
                    answers.remindersEnabled = false
                    onNext()
                }
                .font(.body(16, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .frame(height: 40)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 4)
        }
        .onAppear { visible = true }
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { dropped = true }
            Haptics.shared.softTap()
            SoundFX.shared.play(.bubble)
        }
    }

    private var notificationMock: some View {
        HStack(alignment: .top, spacing: 12) {
            BloubView(shape: .circle, color: .ink, expression: .happy)
                .frame(width: 28, height: 28)
                .frame(width: 42, height: 42)
                .background(Palette.periwinkle, in: .rect(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("ilo").font(.body(15, weight: .semibold))
                    Spacer()
                    Text(hourLabel(answers.reminderHour))
                        .font(.body(13))
                        .foregroundStyle(Palette.muted)
                        .contentTransition(.numericText())
                }
                Text("\(answers.displayName.capitalized), your \(answers.pace?.minutes ?? 10)-minute lesson is ready. Keep your streak alive!")
                    .font(.body(15))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.white.opacity(0.92), in: .rect(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.14), radius: 24, y: 12)
    }

    private func slotButton(_ slot: Slot) -> some View {
        let selected = answers.reminderHour == slot.hour
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { answers.reminderHour = slot.hour }
            Haptics.shared.tick()
            SoundFX.shared.play(.pop)
            answers.react()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: slot.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(selected ? .white : slot.color)
                    .frame(width: 26)
                    .symbolEffect(.bounce, value: selected)
                VStack(alignment: .leading, spacing: 0) {
                    Text(slot.title).font(.display(16, weight: .bold))
                    Text(hourLabel(slot.hour)).font(.body(13)).foregroundStyle(selected ? .white.opacity(0.7) : Palette.muted)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? .white : Palette.ink)
            .padding(14)
            .background(selected ? Palette.ink : .white, in: .rect(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(hex: 0x3A4470, alpha: 0.05), radius: 8, y: 4)
        }
        .buttonStyle(.squish(0.95))
    }

    private func hourLabel(_ hour: Int) -> String {
        var c = DateComponents(); c.hour = hour; c.minute = 0
        let date = Calendar.current.date(from: c) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func enable() async {
        asking = true
        let granted = await OnboardingReminders.requestAndSchedule(hour: answers.reminderHour, name: answers.trimmedName,
                                                                   goal: answers.trimmedGoal)
        asking = false
        answers.remindersEnabled = granted
        if granted { Haptics.shared.correct(); SoundFX.shared.play(.correct) }
        onNext()
    }
}

// MARK: - Commitment

/// "Hold to commit" — a charging ring with rising haptics, then fireworks.
struct OBCommitStep: View {
    @Bindable var answers: OnboardingAnswers
    var onFinish: () -> Void

    @State private var progress: Double = 0
    @State private var holding = false
    @State private var committed = false
    @State private var confetti = 0
    @State private var chargeTask: Task<Void, Never>?
    @State private var visible = false
    private let holdDuration = 1.8

    private let goals: [(days: Int, title: String)] = [(7, "Committed"), (14, "Serious"), (30, "Unstoppable")]

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack(spacing: 10) {
                    ForEach(Array(goals.enumerated()), id: \.offset) { i, goal in
                        goalButton(goal.days, goal.title, index: i)
                    }
                }
                .appear(visible, delay: 0.05)
                .disabled(committed)

                pledge
                    .appear(visible, delay: 0.12)

                Spacer(minLength: 0)

                holdButton
                    .appear(visible, delay: 0.2)

                Text(committed ? "You're in, \(answers.displayName.capitalized)!" : (holding ? "Keep holding…" : "Press and hold to commit"))
                    .font(.display(17, weight: .bold))
                    .foregroundStyle(committed ? Palette.ink : Palette.muted)
                    .contentTransition(.opacity)
                    .animation(.smooth, value: holding)
                    .animation(.smooth, value: committed)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 20)

            ConfettiView(trigger: confetti)
                .ignoresSafeArea()
        }
        .onAppear { visible = true }
    }

    private func goalButton(_ days: Int, _ title: String, index: Int) -> some View {
        let selected = answers.streakGoal == days
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { answers.streakGoal = days }
            Haptics.shared.tick()
            SoundFX.shared.play(.pop)
            answers.react()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18 + CGFloat(index) * 5, weight: .bold))
                    .foregroundStyle(selected ? Palette.gold : Palette.flame)
                    .symbolEffect(.bounce, value: selected)
                    .frame(height: 34)
                Text("\(days) days").font(.display(18, weight: .heavy))
                Text(title).font(.body(12, weight: .semibold)).opacity(0.7)
            }
            .foregroundStyle(selected ? .white : Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selected ? Palette.ink : .white, in: .rect(cornerRadius: 22, style: .continuous))
            .shadow(color: Color(hex: 0x3A4470, alpha: 0.06), radius: 10, y: 5)
            .scaleEffect(selected ? 1.04 : 1)
        }
        .buttonStyle(.squish(0.94))
    }

    private var pledge: some View {
        let minutes = answers.pace?.minutes ?? 10
        return Text("I, **\(answers.displayName.capitalized)**, will learn **\(answers.goalLabel.lowercased())** for **\(minutes) minutes a day**, \(answers.streakGoal) days in a row.")
            .font(.body(16))
            .foregroundStyle(Palette.ink2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .card(Palette.peach.opacity(0.6), radius: 24, padding: 16)
            .contentTransition(.numericText())
            .animation(.smooth, value: answers.streakGoal)
    }

    private var holdButton: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Palette.flame.opacity(0.35 * progress + (committed ? 0.3 : 0)), .clear],
                                     center: .center, startRadius: 40, endRadius: 170))
                .frame(width: 340, height: 340)
            Circle()
                .fill(.white)
                .frame(width: 200, height: 200)
                .shadow(color: Palette.flame.opacity(0.18 + 0.3 * progress), radius: 20 + 20 * progress, y: 10)
            Circle()
                .stroke(Palette.canvasDeep, lineWidth: 14)
                .frame(width: 224, height: 224)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(colors: [Palette.gold, Palette.flame, Palette.orange, Palette.gold], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 224, height: 224)
            BloubView(shape: answers.shape, color: answers.color,
                      expression: committed ? .proud : (holding ? .excited : .attentive))
                .frame(width: 120, height: 120)
                .scaleEffect(1 + 0.18 * progress + (committed ? 0.08 : 0))
                .rotationEffect(.degrees(holding ? sin(progress * 60) * 3 : 0))
            if committed {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Palette.success, .white)
                    .offset(x: 78, y: -78)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 300)
        .contentShape(.circle)
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 60) {
            commit()
        } onPressingChanged: { pressing in
            guard !committed else { return }
            pressing ? startCharging() : cancelCharging()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Hold to commit")
        .accessibilityIdentifier("commit-hold")
        .accessibilityAction { commit() }
    }

    private func startCharging() {
        holding = true
        withAnimation(.linear(duration: holdDuration)) { progress = 1 }
        chargeTask?.cancel()
        chargeTask = Task {
            let start = Date()
            var n = 0
            while !Task.isCancelled {
                let p = min(Date().timeIntervalSince(start) / holdDuration, 1)
                Haptics.shared.charge(p)
                if n % 2 == 0 { SoundFX.shared.play(.tick) }
                n += 1
                try? await Task.sleep(for: .milliseconds(Int(110 - 60 * p)))
            }
        }
    }

    private func cancelCharging() {
        chargeTask?.cancel()
        holding = false
        guard !committed else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { progress = 0 }
    }

    private func commit() {
        guard !committed else { return }
        chargeTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            committed = true
            holding = false
            progress = 1
        }
        confetti += 1
        Haptics.shared.ignite()
        SoundFX.shared.play(.streak)
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            onFinish()
        }
    }
}
