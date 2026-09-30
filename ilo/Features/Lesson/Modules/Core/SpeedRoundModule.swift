import SwiftUI

/// Rapid-fire true/false against a countdown ring. Streaks earn bonus XP. Pass at ≥ 70%.
struct SpeedRoundModule: View {
    let session: ModuleSession

    private enum Stage { case ready, running, done }

    @State private var stage: Stage = .ready
    @State private var order: [Statement] = []
    @State private var index = 0
    @State private var score = 0
    @State private var streak = 0
    @State private var bonus = 0
    @State private var startedAt = Date()
    @State private var flash: Bool?
    @State private var bonusPop = 0
    @State private var appeared = false
    @State private var countdown = 3
    @State private var timerTask: Task<Void, Never>?
    @State private var countdownTask: Task<Void, Never>?

    private var duration: Double { Double(max(session.module.seconds ?? 30, 5)) }

    var body: some View {
        VStack(spacing: 0) {
            switch stage {
            case .ready: readyView.transition(.opacity.combined(with: .scale(scale: 0.95)))
            case .running, .done: runningView.transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: stage)
        .onAppear {
            if order.isEmpty { order = (session.module.statements ?? []).shuffled() }
            appeared = true
            session.hidesCheckBar = true
            session.mood = .excited
        }
        .onDisappear {
            countdownTask?.cancel()
            timerTask?.cancel()
        }
    }

    // MARK: Ready

    private var readyView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Palette.butter).frame(width: 170, height: 170)
                Circle().stroke(Palette.gold, style: StrokeStyle(lineWidth: 5, dash: [3, 9])).frame(width: 200, height: 200)
                    .rotationEffect(.degrees(appeared ? 360 : 0))
                    .animation(.linear(duration: 12).repeatForever(autoreverses: false), value: appeared)
                if countdown < 3 {
                    Text("\(max(countdown, 1))")
                        .font(.display(80, weight: .black))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(countsDown: true))
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [Palette.gold, Palette.flame], startPoint: .top, endPoint: .bottom))
                        .symbolEffect(.bounce, options: .repeat(.periodic(delay: 1.2)), value: appeared)
                }
            }
            .appear(appeared)
            Text(session.module.title ?? "Speed round!")
                .font(.display(32, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .appear(appeared, delay: 0.05)
            Text("\(Int(duration)) seconds. \(order.count) statements.\nTrue or false — as fast as you can.")
                .font(.body(17, weight: .medium))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .appear(appeared, delay: 0.1)
            HStack(spacing: 8) {
                Chip(text: "3 in a row = +2 XP", systemImage: "flame.fill", fill: Palette.peach)
                Chip(text: "Pass at 70%", systemImage: "target", fill: Palette.mint)
            }
            .appear(appeared, delay: 0.15)
            Spacer()
            Button {
                startCountdown()
            } label: {
                Label("Start", systemImage: "bolt.fill")
            }
            .buttonStyle(.pill(.ink))
            .disabled(countdown < 3)
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 8)
            .appear(appeared, delay: 0.2)
        }
    }

    // MARK: Running

    private var runningView: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                TimelineView(.animation(minimumInterval: 1 / 30, paused: stage != .running)) { context in
                    let elapsed = stage == .running ? context.date.timeIntervalSince(startedAt) : duration
                    let left = max(0, duration - elapsed)
                    ZStack {
                        Circle().stroke(Palette.canvasDeep, lineWidth: 9)
                        Circle()
                            .trim(from: 0, to: left / duration)
                            .stroke(left < 6 ? Palette.danger : Palette.periwinkleDeep, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(ceil(left)))")
                            .font(.display(26, weight: .heavy))
                            .foregroundStyle(left < 6 ? Palette.danger : Palette.ink)
                            .monospacedDigit()
                    }
                    .frame(width: 78, height: 78)
                    .scaleEffect(left < 6 && Int(left * 2) % 2 == 0 ? 1.06 : 1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.success)
                        Text("\(score)")
                            .contentTransition(.numericText(value: Double(score)))
                    }
                    .font(.display(28, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").foregroundStyle(Palette.flame)
                            .symbolEffect(.bounce, value: streak)
                        Text("\(streak) streak")
                            .contentTransition(.numericText(value: Double(streak)))
                    }
                    .font(.body(14, weight: .bold))
                    .foregroundStyle(Palette.muted)
                }
                .overlay(alignment: .topLeading) {
                    Text("+2 XP")
                        .font(.display(16, weight: .heavy))
                        .foregroundStyle(Palette.victory)
                        .keyframeAnimator(initialValue: 0.0, trigger: bonusPop) { content, t in
                            content.offset(y: -30 * t).opacity(bonusPop == 0 ? 0 : (t > 0 && t < 1 ? 1 : 0))
                        } keyframes: { _ in
                            LinearKeyframe(0.01, duration: 0.01)
                            CubicKeyframe(0.99, duration: 0.8)
                            LinearKeyframe(1, duration: 0.01)
                        }
                        .offset(x: -60)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 12)

            ZStack {
                if stage == .done {
                    doneView.transition(.scale(scale: 0.8).combined(with: .opacity))
                } else if index < order.count {
                    Text(order[index].text)
                        .font(.display(26, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .padding(26)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(flashColor, in: .rect(cornerRadius: 34, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(flashStroke, lineWidth: 3))
                        .compositingGroup()
                        .shadow(color: Color(hex: 0x3A4470, alpha: 0.08), radius: 18, y: 8)
                        .id(index)
                        .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .offset(y: -60).combined(with: .opacity)))
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .frame(maxHeight: 340)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: index)

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                bigButton(false)
                bigButton(true)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 8)
            .opacity(stage == .running ? 1 : 0.3)
            .disabled(stage != .running)
        }
    }

    private var flashColor: Color {
        switch flash {
        case .some(true): Palette.successSoft
        case .some(false): Palette.dangerSoft
        case .none: .white
        }
    }

    private var flashStroke: Color {
        switch flash {
        case .some(true): Palette.success
        case .some(false): Palette.danger
        case .none: .clear
        }
    }

    private var doneView: some View {
        VStack(spacing: 6) {
            Text("\(score)/\(order.count)")
                .font(.display(72, weight: .black))
                .foregroundStyle(passed ? Palette.success : Palette.danger)
            Text(passed ? "Lightning fast!" : "Time's up!")
                .font(.display(22, weight: .bold))
                .foregroundStyle(Palette.ink)
            if bonus > 0 {
                Chip(text: "+\(bonus) bonus XP", systemImage: "bolt.fill", fill: Palette.victory.opacity(0.14), foreground: Palette.victoryDeep)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func bigButton(_ value: Bool) -> some View {
        Button {
            answer(value)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: value ? "checkmark" : "xmark")
                    .font(.system(size: 26, weight: .black))
                Text(value ? "True" : "False")
                    .font(.display(18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
        }
        .buttonStyle(.answerTile(value ? .correct : .wrong, radius: 28, lip: 6))
    }

    private var passed: Bool { Double(score) >= Double(order.count) * 0.7 }

    // MARK: Logic

    private func startCountdown() {
        guard countdownTask == nil else { return }
        Haptics.shared.press()
        countdownTask = Task {
            for n in stride(from: 2, through: 0, by: -1) {
                withAnimation(.spring) { countdown = n }
                SoundFX.shared.play(.tick)
                Haptics.shared.tick()
                try? await Task.sleep(for: .milliseconds(550))
                // Quitting during "3-2-1" must not start the round (and its timer) off screen.
                if Task.isCancelled { return }
            }
            start()
        }
    }

    private func start() {
        startedAt = .now
        stage = .running
        SoundFX.shared.play(.whoosh)
        Haptics.shared.thud()
        session.mood = .attentive
        timerTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            end()
        }
    }

    private func answer(_ value: Bool) {
        guard stage == .running, index < order.count, flash == nil else { return }
        let right = order[index].isTrue == value
        if right {
            score += 1
            streak += 1
            Haptics.shared.tick()
            SoundFX.shared.play(.pop)
            if streak % 3 == 0 {
                bonus += 2
                bonusPop += 1
                SoundFX.shared.play(.coin)
                Haptics.shared.thud()
            }
            session.mood = streak >= 3 ? .excited : .happy
        } else {
            streak = 0
            Haptics.shared.wrong()
            SoundFX.shared.play(.wrong)
            session.mood = .surprised
        }
        flash = right
        Task {
            try? await Task.sleep(for: .milliseconds(160))
            flash = nil
            index += 1
            if index >= order.count { end() }
        }
    }

    private func end() {
        guard stage == .running else { return }
        timerTask?.cancel()
        stage = .done
        session.bonusXP = bonus
        let secs = Int(min(Date.now.timeIntervalSince(startedAt), duration).rounded())
        let feedback = "You got \(score) of \(order.count) in \(secs)s." + (bonus > 0 ? " Streak bonus: +\(bonus) XP." : "") + (passed ? "" : " You need 70% to pass.")
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            session.resolve(correct: passed, feedback: feedback)
        }
    }
}
