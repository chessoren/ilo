import SwiftUI

/// Camera coach: front camera + Vision body pose → skeleton overlay and automatic rep counting.
/// Without a camera (simulator) or permission, it switches to a guided "practice mode" where the learner taps each rep.
struct CameraCoachModule: View {
    let session: ModuleSession

    enum Mode: Equatable { case starting, camera, practice(String?), done }

    @State private var mode: Mode = .starting
    @State private var reps = 0
    @State private var feed = RealCameraFeed()
    @State private var tracker = RealPoseTracker()
    @State private var visible = false
    @State private var confetti = 0
    @State private var repPop = 0
    @State private var cheer = "Let's warm up!"
    @State private var iloMood: BloubExpression = .excited

    private var module: LessonModule { session.module }
    private var move: String { module.move ?? "Squats" }
    private var target: Int { max(1, module.reps ?? 10) }
    private var kind: RealMoveKind { RealMoveKind(move: move) }
    private var progress: Double { min(1, Double(reps) / Double(target)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RealHeader(type: module.type, title: module.title ?? move, tint: session.tint, subtitle: module.prompt)

                switch mode {
                case .starting:
                    RealThinkingRow(text: "Getting the camera ready…")
                case .camera:
                    cameraStage.appear(visible, delay: 0.05)
                    cameraControls
                    cuesCard
                case .practice(let reason):
                    practiceStage(reason: reason).appear(visible, delay: 0.05)
                    practiceControls
                    cuesCard
                case .done:
                    doneCard.transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay { ConfettiView(trigger: confetti).ignoresSafeArea() }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: mode)
        .task { await start() }
        .onDisappear { feed.stop() }
        .realDemoAuto {
            await realPause(2.2)
            for _ in 0..<target {
                guard mode != .done else { return }
                registerRep()
                await realPause(0.55)
            }
        }
    }

    // MARK: Setup

    private func start() async {
        visible = true
        session.hidesCheckBar = true
        session.mood = .excited
        tracker.kind = kind
        guard mode == .starting else { return }
        guard RealCameraFeed.hasFrontCamera else {
            mode = .practice(nil)
            return
        }
        guard await RealCameraFeed.requestAccess() else {
            mode = .practice("Camera access is off, so let's count together instead.")
            return
        }
        // Left the module while the permission prompt was up: don't start a camera nobody will stop.
        guard !Task.isCancelled, !session.isDetached else { return }
        let tracker = tracker
        let skipper = RealFrameSkipper()
        feed.onFrame = { pixels in
            guard skipper.next() else { return }
            let points = RealJoint.detect(in: pixels)
            Task { @MainActor in tracker.ingest(points) }
        }
        tracker.onRep = { registerRep() }
        feed.start(frames: true)
        mode = .camera
    }

    private func registerRep() {
        guard mode != .done, reps < target else { return }
        reps += 1
        repPop += 1
        Haptics.shared.correct()
        SoundFX.shared.play(reps == target ? .levelUp : .pop)
        updateCheer()
        if reps >= target { complete() }
    }

    private func updateCheer() {
        let left = target - reps
        switch left {
        case 0: cheer = "YES! All \(target) done!"
        case 1: cheer = "Last one — make it count!"
        case 2: cheer = "Two more!"
        case _ where reps == target / 2: cheer = "Halfway there!"
        case _ where reps == 1: cheer = "Nice start!"
        default: cheer = ["Great form!", "Keep going!", "You've got this!", "Smooth!", "Strong!"][reps % 5]
        }
        iloMood = [.excited, .happy, .proud, .laughing][reps % 4]
    }

    private func complete() {
        feed.stop()
        Haptics.shared.celebrate()
        SoundFX.shared.play(.complete)
        confetti += 1
        iloMood = .proud
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            mode = .done
            session.resolve(correct: true, feedback: "\(target) \(move.lowercased()) done! Moving your body is part of learning too.")
        }
    }

    // MARK: Camera mode

    private var cameraStage: some View {
        ZStack {
            RealCameraPreview(session: feed.session)
            RealSkeletonOverlay(joints: tracker.joints, color: session.tint.base)
                .animation(.linear(duration: 0.08), value: tracker.joints)

            VStack {
                HStack(alignment: .top) {
                    Label(move, systemImage: "figure.strengthtraining.functional")
                        .font(.body(14, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: .capsule)
                    Spacer()
                    repRing(size: 84, dark: false)
                        .padding(8)
                        .glassEffect(.regular, in: .circle)
                }
                Spacer()
                if !tracker.bodyVisible {
                    Label("Step back so your whole body is in the frame", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.body(13, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: .capsule)
                        .transition(.opacity)
                }
                RealIloSays(text: cheer, expression: iloMood, size: 44)
            }
            .padding(14)
        }
        .frame(height: 480)
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .shadow(color: Color(hex: 0x1A1D2E, alpha: 0.2), radius: 20, y: 10)
        .animation(.smooth, value: tracker.bodyVisible)
    }

    private var cameraControls: some View {
        HStack(spacing: 12) {
            Button {
                registerRep()
            } label: {
                Label("Count a rep", systemImage: "plus")
            }
            .buttonStyle(.pill(.ink, height: 52))
            Button {
                feed.stop()
                mode = .practice(nil)
            } label: {
                Label("Tap mode", systemImage: "hand.tap.fill")
            }
            .buttonStyle(.pill(.white, height: 52, fullWidth: false))
        }
    }

    // MARK: Practice mode

    private func practiceStage(reason: String?) -> some View {
        VStack(spacing: 0) {
            HStack {
                Label("PRACTICE MODE", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("Follow along")
                    .font(.body(12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            ZStack(alignment: .bottomTrailing) {
                RealDemoFigure(kind: kind, period: 1.6, color: .white, paused: mode == .done)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                repRing(size: 92, dark: true)
                    .padding(14)
            }

            Text(reason ?? "No camera here — do the move with ilo and tap the button after every rep.")
                .font(.body(13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
        }
        .background(
            LinearGradient(colors: [Color(hex: 0x1B1E2B), session.tint.deep.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: 34, style: .continuous)
        )
        .shadow(color: session.tint.deep.opacity(0.3), radius: 22, y: 12)
    }

    private var practiceControls: some View {
        VStack(spacing: 16) {
            RealIloSays(text: cheer, expression: iloMood, size: 52)
            Button {
                registerRep()
            } label: {
                VStack(spacing: 2) {
                    Text("REP!")
                        .font(.display(30, weight: .heavy))
                    Text("\(reps) of \(target)")
                        .font(.body(13, weight: .bold))
                        .opacity(0.7)
                        .contentTransition(.numericText(value: Double(reps)))
                }
                .foregroundStyle(.white)
                .frame(width: 150, height: 150)
                .background(Circle().fill(Palette.ink))
                .background(Circle().fill(Color.black).offset(y: 7))
                .overlay(Circle().stroke(session.tint.base.opacity(0.35), lineWidth: 8).scaleEffect(1.12))
            }
            .buttonStyle(RealPressDownStyle())
            .frame(maxWidth: .infinity)
            .keyframeAnimator(initialValue: 1.0, trigger: repPop) { v, s in v.scaleEffect(s) } keyframes: { _ in
                SpringKeyframe(1.1, duration: 0.1)
                SpringKeyframe(1.0, duration: 0.3)
            }
        }
    }

    // MARK: Shared

    /// Form cues written by the brain (`instructions`) — shown so the coaching content isn't lost.
    @ViewBuilder
    private var cuesCard: some View {
        if let cues = module.instructions, !cues.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Form cues", systemImage: "checklist")
                    .font(.body(13, weight: .bold))
                    .foregroundStyle(session.tint.deep)
                ForEach(Array(cues.enumerated()), id: \.offset) { _, cue in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(session.tint.base)
                        Text(cue)
                            .font(.body(15, weight: .medium))
                            .foregroundStyle(Palette.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(radius: 24, padding: 16)
            .appear(visible, delay: 0.12)
        }
    }

    private func repRing(size: CGFloat, dark: Bool) -> some View {
        ZStack {
            Circle().stroke((dark ? Color.white : Palette.ink).opacity(0.15), lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(reps >= target ? Palette.success : session.tint.base, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: reps)
            VStack(spacing: -2) {
                Text("\(reps)")
                    .font(.display(size * 0.36, weight: .heavy))
                    .contentTransition(.numericText(value: Double(reps)))
                    .animation(.snappy, value: reps)
                Text("/ \(target)")
                    .font(.body(size * 0.14, weight: .bold))
                    .opacity(0.6)
            }
            .foregroundStyle(dark ? .white : Palette.ink)
        }
        .frame(width: size, height: size)
        .keyframeAnimator(initialValue: 1.0, trigger: repPop) { v, s in v.scaleEffect(s) } keyframes: { _ in
            SpringKeyframe(1.18, duration: 0.12)
            SpringKeyframe(1.0, duration: 0.35)
        }
    }

    private var doneCard: some View {
        VStack(spacing: 14) {
            BloubView(color: .ink, expression: .proud)
                .frame(width: 110, height: 110)
            Text("\(target) \(move.lowercased()) — done!")
                .font(.display(26, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text("Your brain loves a moving body. Great work.")
                .font(.body(15, weight: .medium))
                .foregroundStyle(Palette.muted)
            repRing(size: 96, dark: false)
        }
        .frame(maxWidth: .infinity)
        .card(radius: 32, padding: 24)
    }
}

/// Deep press for the big REP button.
struct RealPressDownStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 6 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Processes every other camera frame for Vision.
final class RealFrameSkipper: @unchecked Sendable {
    private var n = 0
    private let lock = NSLock()
    func next() -> Bool {
        lock.lock(); defer { lock.unlock() }
        n += 1
        return n % 2 == 0
    }
}
