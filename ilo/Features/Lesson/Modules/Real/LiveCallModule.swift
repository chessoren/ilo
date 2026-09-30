import SwiftUI

/// "Call ilo": a voice call with ilo. ilo speaks (TTS), listens (speech recognition with live captions),
/// replies through the AI, and the learner can mute, type, toggle their camera or hang up.
struct LiveCallModule: View {
    let session: ModuleSession
    @State private var inCall = false
    @State private var call: RealCallModel?
    @State private var ring = 0
    @State private var visible = false
    @State private var ended = false

    private var module: LessonModule { session.module }
    private var persona: String { module.persona ?? "ilo, your friendly tutor" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RealHeader(type: module.type, title: module.title ?? "Call ilo", tint: session.tint,
                           subtitle: "A real conversation, out loud. Speak or type — ilo listens.")

                incomingCard.appear(visible, delay: 0.06)

                if let goal = module.goal {
                    HStack(spacing: 10) {
                        Image(systemName: "target").foregroundStyle(session.tint.deep)
                        Text(goal)
                            .font(.body(15, weight: .semibold))
                            .foregroundStyle(Palette.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .card(radius: 22, padding: 16)
                    .appear(visible, delay: 0.12)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            visible = true
            session.hidesCheckBar = true
            session.mood = .excited
        }
        .task {
            // Ringing: a soft haptic pulse until answered.
            while !Task.isCancelled && !inCall && !ended {
                ring += 1
                Haptics.shared.heartbeat()
                try? await Task.sleep(for: .seconds(1.6))
            }
        }
        .fullScreenCover(isPresented: $inCall, onDismiss: {
            let exchanges = call?.exchanges ?? 0
            session.bonusXP = exchanges >= 2 ? 10 : 0
            ended = true
            session.finish()
        }) {
            if let call {
                RealCallScreen(model: call, tint: session.tint) { inCall = false }
            }
        }
        .realDemoAuto {
            await realPause(1.6)
            accept()
        }
    }

    private var incomingCard: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(session.tint.base.opacity(0.5), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .phaseAnimator([0.0, 1.0]) { v, p in
                            v.scaleEffect(1 + p * 0.9).opacity(1 - p)
                        } animation: { _ in .easeOut(duration: 1.8).delay(Double(i) * 0.6) }
                }
                Circle()
                    .fill(RadialGradient(colors: [session.tint.base.opacity(0.9), session.tint.deep.opacity(0.2)],
                                         center: .center, startRadius: 5, endRadius: 80))
                    .frame(width: 130, height: 130)
                    .blur(radius: 12)
                BloubView(color: .cream, expression: .excited)
                    .frame(width: 104, height: 104)
                    .keyframeAnimator(initialValue: 0.0, trigger: ring) { v, a in v.rotationEffect(.degrees(a)) } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(-7, duration: 0.07)
                            LinearKeyframe(7, duration: 0.07)
                            LinearKeyframe(-5, duration: 0.07)
                            LinearKeyframe(5, duration: 0.07)
                            LinearKeyframe(0, duration: 0.07)
                        }
                    }
            }
            .frame(height: 190)

            VStack(spacing: 4) {
                Text("ilo is calling…")
                    .font(.display(26, weight: .heavy))
                    .foregroundStyle(.white)
                Text(RealCallModel.role(from: persona))
                    .font(.body(14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 56) {
                VStack(spacing: 8) {
                    Button {
                        Haptics.shared.tap()
                        ended = true
                        session.skipped = true
                        session.finish()
                    } label: {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(Palette.danger, in: .circle)
                    }
                    .buttonStyle(.squish)
                    Text("Not now").font(.body(13, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                }
                VStack(spacing: 8) {
                    Button(action: accept) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(Palette.success, in: .circle)
                            .symbolEffect(.wiggle, options: .repeat(.periodic(delay: 1)), isActive: !inCall)
                    }
                    .buttonStyle(.squish)
                    Text("Answer").font(.body(13, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color(hex: 0x12142A), Color(hex: 0x2B2F5C), session.tint.deep], startPoint: .top, endPoint: .bottom),
            in: .rect(cornerRadius: 38, style: .continuous)
        )
        .shadow(color: session.tint.deep.opacity(0.35), radius: 26, y: 14)
    }

    private func accept() {
        guard !inCall else { return }
        Haptics.shared.press()
        SoundFX.shared.play(.bubble)
        call = RealCallModel(session: session)
        inCall = true
    }
}

// MARK: - Call model

@Observable
@MainActor
final class RealCallModel {
    enum State: Equatable { case connecting, speaking, listening, thinking, ended }

    private(set) var state: State = .connecting
    private(set) var messages: [ChatMessage] = []
    private(set) var exchanges = 0
    private(set) var startedAt = Date()
    var muted = false
    var cameraOn = false
    var typing = false
    var draft = ""
    private(set) var notice: String?

    let voiceIn = RealVoiceInput()
    let voiceOut = RealVoiceOutput()
    let feed = RealCameraFeed()

    let persona: String
    let goal: String
    let topic: String
    let opening: String
    let maxExchanges: Int
    private let ai: LearningAI
    private var listenTask: Task<Void, Never>?
    private var started = false

    init(session: ModuleSession) {
        let module = session.module
        persona = module.persona ?? "ilo, a warm and curious tutor"
        goal = module.goal ?? "Have a friendly chat about what you're learning"
        topic = [session.course.title, session.node.title].joined(separator: " — ")
        opening = module.opening?.realTrimmed.realNilIfEmpty ?? "Hey, it's ilo! How's your learning going today?"
        maxExchanges = min(10, max(2, module.turns ?? 5))
        ai = session.ai
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demoAuto") && !args.contains("-demoMic") { muted = true }
        #endif
    }

    static func role(from persona: String) -> String {
        for sep in [", ", " — ", " - "] {
            if let r = persona.range(of: sep) {
                let role = String(persona[r.upperBound...]).realTrimmed
                return role.prefix(1).uppercased() + role.dropFirst()
            }
        }
        return persona
    }

    var lastIloLine: String? { messages.last(where: { $0.role == .ilo })?.text }
    var lastUserLine: String? { messages.last(where: { $0.role == .user })?.text }

    func start() {
        guard !started else { return }
        started = true
        startedAt = Date()
        RealAudioSession.beginVoice()
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            guard state != .ended else { return }
            await say(opening)
            listen()
        }
    }

    private func say(_ text: String) async {
        guard state != .ended else { return }
        stopListening()
        messages.append(ChatMessage(role: .ilo, text: text))
        state = .speaking
        await voiceOut.speak(text)
    }

    func listen() {
        guard state != .ended else { return }
        state = .listening
        guard !muted, !typing else { return }
        listenTask?.cancel()
        listenTask = Task {
            let ok = await voiceIn.start()
            guard ok else {
                notice = voiceIn.problem
                muted = true
                typing = true
                return
            }
            notice = nil
            var idleRestarts = 0
            while !Task.isCancelled && state == .listening {
                try? await Task.sleep(for: .milliseconds(250))
                let text = voiceIn.transcript.realTrimmed
                let silent = Date().timeIntervalSince(voiceIn.lastSpeech)
                if !text.isEmpty && (silent > 1.4 || !voiceIn.isListening) {
                    voiceIn.stop()
                    await userSaid(text)
                    return
                }
                if !voiceIn.isListening && text.isEmpty {
                    // Recognition timed out with nothing heard — quietly restart a few times.
                    idleRestarts += 1
                    guard idleRestarts < 6, !muted, !typing else { return }
                    _ = await voiceIn.start()
                }
            }
        }
    }

    private func stopListening() {
        listenTask?.cancel()
        listenTask = nil
        voiceIn.stop()
    }

    func toggleMute() {
        muted.toggle()
        Haptics.shared.tap()
        if muted { stopListening() } else if state == .listening { listen() }
    }

    func sendTyped() {
        let text = draft.realTrimmed
        guard !text.isEmpty, state == .listening || state == .speaking else { return }
        draft = ""
        voiceOut.stop()
        Task { await userSaid(text) }
    }

    private func userSaid(_ text: String) async {
        guard state != .ended else { return }
        stopListening()
        messages.append(ChatMessage(role: .user, text: text))
        exchanges += 1
        Haptics.shared.softTap()
        SoundFX.shared.play(.pop)
        state = .thinking
        let reply: String
        do {
            reply = try await ai.chat(persona: persona, goal: goal, topic: topic, history: messages)
        } catch {
            reply = "Sorry, the line crackled for a second. Could you say that again?"
        }
        guard state != .ended else { return }
        await say(reply.realTrimmed.realNilIfEmpty ?? "Tell me more!")
        if exchanges >= maxExchanges {
            await say("This was lovely. Let's wrap up here — see you in the next lesson!")
            try? await Task.sleep(for: .seconds(0.4))
            state = .ended
            return
        }
        listen()
    }

    func toggleCamera() {
        guard RealCameraFeed.hasFrontCamera else {
            notice = "No camera on this device — voice only."
            Haptics.shared.warning()
            return
        }
        Task {
            if !cameraOn {
                guard await RealCameraFeed.requestAccess() else {
                    notice = "Camera access is off in Settings."
                    return
                }
                feed.start(frames: false)
                cameraOn = true
            } else {
                feed.stop()
                cameraOn = false
            }
            Haptics.shared.tap()
        }
    }

    func end() {
        guard state != .ended || started else { return }
        state = .ended
        listenTask?.cancel()
        voiceIn.stop()
        voiceOut.stop()
        feed.stop()
        if started { RealAudioSession.endVoice() }
        started = false
    }
}

// MARK: - Call screen

struct RealCallScreen: View {
    @Bindable var model: RealCallModel
    var tint: CourseTint
    var onHangUp: () -> Void
    @State private var lastWord = Date.distantPast
    @FocusState private var typingFocus: Bool

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 10)
                orb
                stateLabel.padding(.top, 18)
                Spacer(minLength: 10)
                captions
                if model.typing { typeBar.transition(.move(edge: .bottom).combined(with: .opacity)) }
                controls
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.typing)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.state)
        .onAppear { model.start() }
        .onDisappear { model.end() }
        .onChange(of: model.voiceOut.wordTick) { lastWord = Date() }
        .onChange(of: model.state) { _, s in
            if s == .ended { hangUp() }
            if s == .speaking { Haptics.shared.softTap() }
        }
        .onChange(of: model.typing) { _, t in typingFocus = t }
        .realDemoAuto {
            await realPause(6)
            if ProcessInfo.processInfo.arguments.contains("-demoMic") { return }
            model.typing = true
            for line in ["I want to read ten pages every night.", "Right after I brush my teeth!"] {
                model.draft = line
                await realPause(0.8)
                model.sendTyped()
                while model.state != .listening { await realPause(0.3) }
                await realPause(1)
            }
        }
    }

    private func hangUp() {
        Haptics.shared.thud()
        SoundFX.shared.play(.whoosh)
        model.end()
        onHangUp()
    }

    // MARK: Pieces

    private var background: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [Float(0.5 + 0.1 * sin(t / 3)), Float(0.45 + 0.08 * cos(t / 4))], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: [
                Color(hex: 0x07080F), Color(hex: 0x10132A), Color(hex: 0x07080F),
                Color(hex: 0x141836), tint.deep.opacity(0.55), Color(hex: 0x141836),
                Color(hex: 0x07080F), Color(hex: 0x1A1F45), Color(hex: 0x07080F),
            ])
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(Palette.success).frame(width: 8, height: 8)
                        .phaseAnimator([0.4, 1.0]) { v, o in v.opacity(o) } animation: { _ in .easeInOut(duration: 0.8) }
                    Text("ilo")
                        .font(.display(24, weight: .heavy))
                        .foregroundStyle(.white)
                }
                TimelineView(.periodic(from: model.startedAt, by: 1)) { tl in
                    let s = max(0, Int(tl.date.timeIntervalSince(model.startedAt)))
                    Text(String(format: "%02d:%02d", s / 60, s % 60))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.6))
                        .contentTransition(.numericText())
                }
                Text(RealCallModel.role(from: model.persona))
                    .font(.body(13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
            Spacer()
            pip
        }
        .padding(.top, 8)
    }

    private var pip: some View {
        ZStack {
            if model.cameraOn {
                RealCameraPreview(session: model.feed.session)
                    .transition(.opacity)
            } else {
                VStack(spacing: 8) {
                    BloubView(shape: .pebble, color: .blue, expression: model.state == .listening ? .attentive : .happy)
                        .frame(width: 46, height: 46)
                    Label("You", systemImage: "video.slash.fill")
                        .font(.body(11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(width: 104, height: 140)
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .glassEffect(.regular, in: .rect(cornerRadius: 22, style: .continuous))
        .animation(.smooth, value: model.cameraOn)
    }

    private var orb: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let level = orbLevel(t: t, now: tl.date)
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(RadialGradient(colors: [tint.base.opacity(0.55 - Double(i) * 0.14), .clear],
                                             center: .center, startRadius: 10, endRadius: 150 + CGFloat(i) * 40))
                        .frame(width: 300 + CGFloat(i) * 60, height: 300 + CGFloat(i) * 60)
                        .scaleEffect(0.8 + level * (0.35 + Double(i) * 0.12))
                        .blur(radius: 10 + CGFloat(i) * 8)
                }
                Circle()
                    .fill(AngularGradient(colors: [tint.base, Palette.orchid, Palette.victory, tint.base],
                                          center: .center, angle: .degrees(t * 40)))
                    .frame(width: 190, height: 190)
                    .blur(radius: 18)
                    .opacity(0.85)
                    .scaleEffect(0.92 + level * 0.18)
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 176, height: 176)
                    .glassEffect(.clear, in: .circle)
                    .scaleEffect(0.96 + level * 0.08)
                BloubView(color: .cream, expression: orbExpression, mode: model.state == .thinking ? .thinking : .face,
                          lookAt: model.state == .listening ? CGPoint(x: 0, y: 0.3) : nil)
                    .frame(width: 170, height: 170)
                    .scaleEffect(1 + level * 0.07)
            }
            .frame(width: 320, height: 320)
            .scaleEffect(model.typing ? 0.62 : 1)
            .frame(height: model.typing ? 210 : 320)
        }
    }

    private func orbLevel(t: Double, now: Date) -> Double {
        switch model.state {
        case .speaking:
            let word = max(0, 1 - now.timeIntervalSince(lastWord) / 0.28)
            return min(1, 0.35 + 0.18 * (sin(t * 11) * 0.5 + 0.5) * (sin(t * 3.7) * 0.5 + 0.5) + 0.45 * word)
        case .listening:
            return model.muted ? 0.08 : min(1, 0.12 + Double(model.voiceIn.level) * 0.9)
        case .thinking:
            return 0.18 + 0.08 * sin(t * 3)
        case .connecting:
            return 0.1 + 0.1 * (sin(t * 5) * 0.5 + 0.5)
        case .ended:
            return 0
        }
    }

    private var orbExpression: BloubExpression {
        switch model.state {
        case .speaking: .happy
        case .listening: .attentive
        case .thinking: .curious
        case .connecting: .excited
        case .ended: .proud
        }
    }

    private var stateLabel: some View {
        let text: String = switch model.state {
        case .connecting: "Connecting…"
        case .speaking: "ilo is speaking"
        case .listening: model.muted ? (model.typing ? "Type your reply" : "You're muted") : "Listening…"
        case .thinking: "ilo is thinking…"
        case .ended: "Call ended"
        }
        return HStack(spacing: 8) {
            if model.state == .listening && !model.muted {
                RealWaveform(levels: model.voiceIn.levels.suffix(12).map { $0 }, color: .white, barWidth: 3, spacing: 2.5)
                    .frame(width: 70)
            }
            Text(text)
                .font(.body(15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .glassEffect(.regular, in: .capsule)
    }

    private var captions: some View {
        VStack(spacing: 10) {
            if let notice = model.notice {
                Text(notice)
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                    .multilineTextAlignment(.center)
            }
            if let line = model.state == .speaking ? model.voiceOut.currentText : model.lastIloLine {
                captionText(line)
                    .font(.display(20, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .id(line)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            let live = model.state == .listening ? model.voiceIn.transcript : ""
            if !live.isEmpty {
                Text("“\(live)”")
                    .font(.body(16, weight: .medium))
                    .italic()
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            } else if let you = model.lastUserLine, model.state == .thinking {
                Text("You: \(you)")
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: model.typing ? 60 : 120, alignment: .bottom)
        .padding(.bottom, 16)
        .animation(.smooth, value: model.messages.count)
    }

    /// ilo's line with the words already spoken in full white and the rest dimmed.
    private func captionText(_ line: String) -> Text {
        guard model.state == .speaking, line == model.voiceOut.currentText, let range = model.voiceOut.spokenRange,
              let r = Range(NSRange(location: 0, length: min((line as NSString).length, range.location + range.length)), in: line) else {
            return Text(line).foregroundStyle(.white)
        }
        let spoken = String(line[r])
        let rest = String(line[r.upperBound...])
        return Text("\(Text(spoken).foregroundStyle(.white))\(Text(rest).foregroundStyle(.white.opacity(0.35)))")
    }

    private var typeBar: some View {
        HStack(spacing: 10) {
            TextField("Type to ilo…", text: $model.draft)
                .font(.body(16, weight: .medium))
                .foregroundStyle(.white)
                .focused($typingFocus)
                .submitLabel(.send)
                .onSubmit { model.sendTyped() }
            Button {
                model.sendTyped()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 38, height: 38)
                    .background(.white, in: .circle)
            }
            .buttonStyle(.squish)
            .disabled(model.draft.realTrimmed.isEmpty)
        }
        .padding(.leading, 18)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
        .padding(.bottom, 14)
    }

    private var controls: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 18) {
                callButton(model.muted ? "mic.slash.fill" : "mic.fill", active: model.muted, label: model.muted ? "Unmute" : "Mute") {
                    model.toggleMute()
                }
                callButton(model.cameraOn ? "video.fill" : "video.slash.fill", active: model.cameraOn, label: "Camera") {
                    model.toggleCamera()
                }
                callButton("keyboard", active: model.typing, label: "Type") {
                    Haptics.shared.tap()
                    model.typing.toggle()
                    if model.typing, !model.muted { model.toggleMute() }
                }
                Button(action: hangUp) {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                        .background(Palette.danger, in: .circle)
                }
                .buttonStyle(.squish)
                .accessibilityLabel("End call")
            }
        }
    }

    private func callButton(_ symbol: String, active: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(active ? Palette.ink : .white)
                .frame(width: 64, height: 64)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .glassEffect(active ? .regular.tint(.white).interactive() : .regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}
