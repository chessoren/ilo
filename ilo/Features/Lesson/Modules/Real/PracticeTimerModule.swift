import SwiftUI

/// Metronome practice coach: big count on every beat, accented downbeat, haptics + clicks, tempo control and a duration ring.
struct PracticeTimerModule: View {
    let session: ModuleSession
    @State private var metro = RealMetronome()
    @State private var visible = false
    @State private var confetti = 0

    private var module: LessonModule { session.module }
    private var labels: [String] {
        let l = module.countLabels ?? []
        return l.isEmpty ? (1...max(1, metro.beatsPerBar)).map(String.init) : l
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RealHeader(type: module.type, title: module.title ?? "Practice", tint: session.tint, subtitle: module.prompt)

                stage.appear(visible, delay: 0.08)

                countStrip.appear(visible, delay: 0.14)

                tempoCard.appear(visible, delay: 0.2)

                controls.appear(visible, delay: 0.26)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay { ConfettiView(trigger: confetti).ignoresSafeArea() }
        .onAppear {
            visible = true
            session.hidesCheckBar = true
            session.mood = .attentive
            metro.configure(bpm: module.bpm ?? 90, beatsPerBar: module.beatsPerBar ?? 4, labels: labels, duration: module.durationSeconds ?? 60)
            metro.onComplete = {
                confetti += 1
                session.mood = .proud
                Haptics.shared.celebrate()
                SoundFX.shared.play(.complete)
            }
        }
        .onChange(of: metro.isRunning) { _, running in session.mood = running ? .excited : (metro.isDone ? .proud : .attentive) }
        .onDisappear { metro.stop() }
        .realDemoAuto {
            await realPause(1)
            metro.toggle()
        }
    }

    // MARK: Stage

    private var stage: some View {
        let label = metro.currentLabel
        let rest = RealMetronome.isRest(label)
        return ZStack {
            TickRing(progress: metro.progress, tint: session.tint.base, ticks: 96)
                .frame(width: 290, height: 290)

            Circle()
                .fill(metro.isAccent && metro.isRunning ? Palette.ink : .white)
                .frame(width: 200, height: 200)
                .shadow(color: session.tint.base.opacity(metro.isRunning ? 0.45 : 0.15), radius: metro.pulse ? 34 : 14)
                .scaleEffect(metro.pulse ? 1.07 : 1)

            VStack(spacing: 2) {
                if metro.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 64, weight: .heavy))
                        .foregroundStyle(Palette.success)
                        .transition(.scale.combined(with: .opacity))
                } else if metro.isRunning || metro.beat > 0 {
                    Text(rest ? "·" : label)
                        .font(.display(rest ? 70 : 84, weight: .heavy))
                        .foregroundStyle(metro.isAccent && metro.isRunning ? .white : (rest ? Palette.faint : Palette.ink))
                        .contentTransition(.numericText())
                        .id(metro.beat)
                        .transition(.scale(scale: 1.5).combined(with: .opacity))
                } else {
                    Image(systemName: "metronome.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .symbolEffect(.bounce, value: visible)
                }
                Text(metro.isDone ? "Done!" : metro.remainingText)
                    .font(.display(15, weight: .bold))
                    .foregroundStyle(metro.isAccent && metro.isRunning && !metro.isDone ? .white.opacity(0.7) : Palette.muted)
                    .contentTransition(.numericText())
            }

            // Beat dots around the bottom
            HStack(spacing: 10) {
                ForEach(0..<metro.beatsPerBar, id: \.self) { i in
                    let on = metro.isRunning && metro.beatInBar == i
                    Circle()
                        .fill(on ? (i == 0 ? Palette.ink : session.tint.base) : Palette.canvasDeep)
                        .frame(width: i == 0 ? 16 : 12, height: i == 0 ? 16 : 12)
                        .scaleEffect(on ? 1.35 : 1)
                        .animation(.spring(response: 0.18, dampingFraction: 0.5), value: on)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .glassEffect(.regular, in: .capsule)
            .offset(y: 160)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 350)
        .animation(.spring(response: 0.16, dampingFraction: 0.55), value: metro.pulse)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: metro.beat)
    }

    private var countStrip: some View {
        HStack(spacing: 6) {
            ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                let current = metro.isRunning && metro.labelIndex == i
                let rest = RealMetronome.isRest(label)
                Text(rest ? "·" : label)
                    .font(.display(20, weight: .heavy))
                    .foregroundStyle(current ? .white : (rest ? Palette.faint : Palette.ink))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(current ? AnyShapeStyle(session.tint.deep) : AnyShapeStyle(Color.white), in: .rect(cornerRadius: 14, style: .continuous))
                    .scaleEffect(current ? 1.08 : 1)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: current)
            }
        }
    }

    private var tempoCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(metro.bpm)")
                    .font(.display(40, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText(value: Double(metro.bpm)))
                    .animation(.snappy, value: metro.bpm)
                Text("BPM")
                    .font(.display(15, weight: .heavy))
                    .foregroundStyle(Palette.muted)
                Spacer()
                Text(metro.tempoName)
                    .font(.body(13, weight: .bold))
                    .foregroundStyle(session.tint.deep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(session.tint.soft, in: .capsule)
            }
            HStack(spacing: 12) {
                stepButton("minus") { metro.setBPM(metro.bpm - 2) }
                Slider(value: Binding(get: { Double(metro.bpm) }, set: { metro.setBPM(Int($0.rounded())) }),
                       in: Double(metro.minBPM)...Double(metro.maxBPM))
                    .tint(session.tint.deep)
                stepButton("plus") { metro.setBPM(metro.bpm + 2) }
            }
        }
        .card(radius: 26, padding: 16)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.tick()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .frame(width: 36, height: 36)
                .background(Palette.canvas, in: .circle)
        }
        .buttonStyle(.squish)
    }

    @ViewBuilder
    private var controls: some View {
        if metro.isDone {
            Button {
                session.finish()
            } label: {
                Label("Continue", systemImage: "arrow.right")
            }
            .buttonStyle(.pill(.victory))
            .transition(.scale.combined(with: .opacity))
        } else {
            VStack(spacing: 10) {
                Button {
                    metro.toggle()
                } label: {
                    Label(metro.isRunning ? "Pause" : (metro.beat > 0 ? "Resume" : "Start practice"),
                          systemImage: metro.isRunning ? "pause.fill" : "play.fill")
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.pill(.ink))

                if metro.progress >= 0.5 {
                    Button("I'm done practising") {
                        Haptics.shared.tap()
                        metro.complete()
                    }
                    .font(.body(15, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - Metronome engine

@Observable
@MainActor
final class RealMetronome {
    private(set) var bpm = 90
    private(set) var beatsPerBar = 4
    private(set) var labels: [String] = []
    private(set) var duration: Double = 60
    private(set) var elapsed: Double = 0
    private(set) var beat = 0
    private(set) var isRunning = false
    private(set) var isDone = false
    private(set) var pulse = false
    var onComplete: (() -> Void)?

    private(set) var minBPM = 40
    private(set) var maxBPM = 200
    private var task: Task<Void, Never>?
    private var configured = false

    var progress: Double { min(1, elapsed / max(1, duration)) }
    /// 0-based index of the beat that just sounded.
    var beatInBar: Int { max(0, beat - 1) % max(1, beatsPerBar) }
    var labelIndex: Int { labels.isEmpty ? 0 : max(0, beat - 1) % labels.count }
    var currentLabel: String { labels.isEmpty ? "\(beatInBar + 1)" : labels[labelIndex] }
    var isAccent: Bool { beat > 0 && beatInBar == 0 }

    var remainingText: String {
        let left = max(0, Int((duration - elapsed).rounded(.up)))
        return String(format: "%d:%02d left", left / 60, left % 60)
    }

    var tempoName: String {
        switch bpm {
        case ..<66: "Slow & steady"
        case ..<96: "Comfortable"
        case ..<126: "Lively"
        case ..<160: "Fast"
        default: "Blazing"
        }
    }

    static func isRest(_ label: String) -> Bool {
        let t = label.trimmingCharacters(in: .whitespaces)
        return t.isEmpty || t == "_" || t == "·" || t == "-" || t == "rest"
    }

    func configure(bpm: Int, beatsPerBar: Int, labels: [String], duration: Int) {
        guard !configured else { return }
        configured = true
        self.bpm = min(240, max(30, bpm))
        self.beatsPerBar = min(12, max(1, beatsPerBar))
        self.labels = labels
        self.duration = Double(max(10, duration))
        minBPM = max(30, self.bpm - 40)
        maxBPM = min(240, self.bpm + 40)
    }

    func setBPM(_ value: Int) {
        bpm = min(maxBPM, max(minBPM, value))
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning, !isDone else { return }
        isRunning = true
        Haptics.shared.press()
        task = Task { [weak self] in
            let clock = ContinuousClock()
            var next = clock.now
            var last = clock.now
            var first = true
            while !Task.isCancelled {
                guard let self else { return }
                let interval = 60.0 / Double(self.bpm)
                let now = clock.now
                if !first {
                    let dt = now - last
                    self.elapsed += Double(dt.components.seconds) + Double(dt.components.attoseconds) / 1e18
                }
                first = false
                last = now
                self.fire(interval: interval)
                if self.isDone { return }
                next = next.advanced(by: .seconds(interval))
                // Never burst to catch up after a hiccup.
                if next < clock.now { next = clock.now.advanced(by: .seconds(interval * 0.5)) }
                do { try await Task.sleep(until: next, clock: clock) } catch { return }
            }
        }
    }

    func pause() {
        task?.cancel()
        task = nil
        isRunning = false
        Haptics.shared.softTap()
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    func complete() {
        stop()
        elapsed = duration
        isDone = true
        onComplete?()
    }

    private func fire(interval: Double) {
        beat += 1
        let label = currentLabel
        let rest = Self.isRest(label)
        if rest {
            Haptics.shared.softTap()
        } else {
            Haptics.shared.beat(accent: isAccent)
            SoundFX.shared.play(.tick)
            if isAccent { SoundFX.shared.play(.tap) }
        }
        pulse = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(min(0.12, interval * 0.35)))
            self?.pulse = false
        }
        if elapsed >= duration { complete() }
    }
}
