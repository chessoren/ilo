import SwiftUI

/// A short chat roleplay with an AI persona. The learner has a goal and a limited number of messages; ilo grades the conversation.
struct RoleplayModule: View {
    let session: ModuleSession
    @State private var model = RoleplayModel()
    @State private var visible = false
    @FocusState private var focused: Bool

    private var module: LessonModule { session.module }

    var body: some View {
        VStack(spacing: 0) {
            personaHeader
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 6)
                .appear(visible)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Conversation with \(model.personaName)")
                            .font(.body(12, weight: .semibold))
                            .foregroundStyle(Palette.faint)
                            .padding(.top, 14)

                        ForEach(model.messages) { message in
                            RealChatBubble(message: message, personaName: model.personaName,
                                           personaColor: model.personaColor, personaShape: model.personaShape)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.6, anchor: message.role == .user ? .bottomTrailing : .bottomLeading)
                                        .combined(with: .opacity),
                                    removal: .opacity))
                        }

                        if model.isTyping {
                            RealTypingBubble(color: model.personaColor, shape: model.personaShape)
                                .id("typing")
                                .transition(.scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity))
                        }

                        switch model.phase {
                        case .grading:
                            RealThinkingRow(text: "ilo is reviewing your conversation…")
                                .padding(.top, 8)
                                .id("end")
                                .transition(.opacity)
                        case .graded(let grade):
                            RealGradeCard(grade: grade, sample: module.sampleAnswer, tint: session.tint,
                                          headline: grade.passed ? "Goal reached!" : "Nice effort")
                                .padding(.top, 8)
                                .id("end")
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        case .failed(let why):
                            RealErrorRow(text: why) { Task { await model.wrapUp(session: session) } }
                                .id("end")
                        case .chatting:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: model.scrollTick) {
                    withAnimation(.smooth(duration: 0.35)) {
                        switch model.phase {
                        case .chatting:
                            if model.isTyping { proxy.scrollTo("typing", anchor: .bottom) }
                            else if let last = model.messages.last?.id { proxy.scrollTo(last, anchor: .bottom) }
                        default: proxy.scrollTo("end", anchor: .top)
                        }
                    }
                }
            }

            if model.phase == .chatting {
                composer
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.messages.count)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.isTyping)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.phase)
        .onAppear {
            visible = true
            session.hidesCheckBar = true
            session.mood = .attentive
            model.configure(module: module, session: session)
        }
        .onDisappear { model.voice.stop() }
        .realDemoAuto {
            await realPause(2)
            for line in ["Hi! Could I have a café con leche, please?", "And a croissant too, thank you!", "Perfect. Can I have the bill, please?"] {
                model.draft = line
                await realPause(0.6)
                await model.send(session: session)
                await realPause(1.0)
            }
        }
    }

    // MARK: Header

    private var personaHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                BloubView(shape: model.personaShape, color: model.personaColor, expression: model.personaMood,
                          mode: model.isTyping ? .thinking : .face)
                    .frame(width: 50, height: 50)
                    .padding(6)
                    .background(model.personaColor.color.opacity(0.14), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.personaName)
                        .font(.display(19, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text(model.personaRole)
                        .font(.body(13, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                Chip(text: module.type.displayName, systemImage: module.type.symbol, fill: session.tint.soft, foreground: session.tint.deep)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Label {
                        Text(model.goal)
                            .font(.body(14, weight: .semibold))
                            .foregroundStyle(Palette.ink2)
                            .lineLimit(2)
                    } icon: {
                        Image(systemName: "target")
                            .foregroundStyle(session.tint.deep)
                    }
                    Spacer()
                    Text("\(model.userTurns)/\(model.maxTurns)")
                        .font(.display(15, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: Double(model.userTurns)))
                }
                GlossyProgressBar(progress: model.progress, tint: session.tint.base, height: 12)
            }
        }
        .card(radius: 28, padding: 16)
    }

    // MARK: Composer

    private var composer: some View {
        VStack(spacing: 8) {
            if model.userTurns > 0 && model.userTurns < model.maxTurns && !model.isTyping {
                Button {
                    Haptics.shared.tap()
                    Task { await model.wrapUp(session: session) }
                } label: {
                    Label("Wrap up conversation", systemImage: "flag.checkered")
                        .font(.body(13, weight: .bold))
                        .foregroundStyle(Palette.ink2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
            if let problem = model.voice.problem {
                Text(problem)
                    .font(.body(12, weight: .semibold))
                    .foregroundStyle(Palette.muted)
            }
            HStack(spacing: 10) {
                Button {
                    Task {
                        if model.voice.isListening { model.voice.stop() } else { Haptics.shared.press(); await model.voice.start(prefix: model.draft) }
                    }
                } label: {
                    Image(systemName: model.voice.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(model.voice.isListening ? .white : Palette.ink)
                        .frame(width: 46, height: 46)
                        .background(model.voice.isListening ? Palette.danger : .clear, in: .circle)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.squish)
                .disabled(model.isTyping)

                ZStack(alignment: .leading) {
                    if model.voice.isListening && model.draft.isEmpty {
                        RealWaveform(levels: model.voice.levels, color: Palette.danger, barWidth: 3, spacing: 2.5)
                    }
                    TextField(model.isTyping ? "\(model.personaName) is typing…" : "Message \(model.personaName)…", text: $model.draft, axis: .vertical)
                        .font(.body(16, weight: .medium))
                        .lineLimit(1...4)
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit { send() }
                }

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(canSend ? Palette.ink : Palette.faint, in: .circle)
                        .scaleEffect(canSend ? 1 : 0.9)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canSend)
                }
                .buttonStyle(.squish)
                .disabled(!canSend)
            }
            .padding(.leading, 4)
            .padding(.trailing, 6)
            .padding(.vertical, 5)
            .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
        }
        .onChange(of: model.voice.transcript) {
            if model.voice.isListening || !model.voice.transcript.isEmpty { model.draft = model.voice.fullText }
        }
    }

    private var canSend: Bool { !model.draft.realTrimmed.isEmpty && !model.isTyping && model.phase == .chatting }

    private func send() {
        guard canSend else { return }
        Task { await model.send(session: session) }
    }
}

// MARK: - Model

@Observable
@MainActor
final class RoleplayModel {
    enum Phase: Equatable { case chatting, grading, graded(Grade), failed(String) }

    var messages: [ChatMessage] = []
    var draft = ""
    private(set) var isTyping = false
    private(set) var phase: Phase = .chatting
    private(set) var scrollTick = 0
    let voice = RealVoiceInput()

    private(set) var persona = "A friendly local"
    private(set) var personaName = "Alex"
    private(set) var personaRole = ""
    private(set) var personaColor: BloubColor = .orange
    private(set) var personaShape: BloubShape = .pebble
    private(set) var personaMood: BloubExpression = .happy
    private(set) var goal = "Keep the conversation going"
    private(set) var maxTurns = 3
    private var topic = ""
    private var rubric: [String] = []
    private var sample: String?
    private var configured = false

    var userTurns: Int { messages.filter { $0.role == .user }.count }
    var progress: Double {
        switch phase {
        case .graded: 1
        default: Double(userTurns) / Double(max(1, maxTurns))
        }
    }

    func configure(module: LessonModule, session: ModuleSession) {
        guard !configured else { return }
        configured = true
        persona = module.persona?.realTrimmed.realNilIfEmpty ?? "A friendly local who loves to chat"
        (personaName, personaRole) = Self.split(persona)
        personaColor = RealHash.bloubColor(for: persona)
        personaShape = RealHash.bloubShape(for: persona)
        goal = module.goal?.realTrimmed.realNilIfEmpty ?? module.prompt ?? "Keep the conversation going"
        maxTurns = min(8, max(1, module.turns ?? 3))
        topic = [session.course.title, session.node.title, module.title].compactMap { $0 }.joined(separator: " — ")
        rubric = module.rubric ?? [goal]
        sample = module.sampleAnswer
        let opening = module.opening?.realTrimmed.realNilIfEmpty ?? "Hi there! What can I do for you?"
        Task {
            isTyping = true
            scrollTick += 1
            try? await Task.sleep(for: .seconds(0.9))
            isTyping = false
            messages.append(ChatMessage(role: .ilo, text: opening))
            Haptics.shared.softTap()
            SoundFX.shared.play(.bubble)
            scrollTick += 1
        }
    }

    func send(session: ModuleSession) async {
        let text = draft.realTrimmed
        guard !text.isEmpty, !isTyping, phase == .chatting else { return }
        voice.stop()
        draft = ""
        messages.append(ChatMessage(role: .user, text: text))
        Haptics.shared.tap()
        SoundFX.shared.play(.pop)
        scrollTick += 1
        session.mood = .curious

        if userTurns >= maxTurns {
            // Let the persona answer one last time, then grade.
            await reply(session: session)
            try? await Task.sleep(for: .seconds(0.6))
            await wrapUp(session: session)
        } else {
            await reply(session: session)
        }
    }

    private func reply(session: ModuleSession) async {
        isTyping = true
        personaMood = .curious
        scrollTick += 1
        let started = Date()
        let text: String
        do {
            text = try await session.ai.chat(persona: persona, goal: goal, topic: topic, history: messages)
        } catch {
            text = "Sorry, could you say that again?"
        }
        let elapsed = Date().timeIntervalSince(started)
        let typingTime = min(2.2, 0.6 + Double(text.count) * 0.018)
        if elapsed < typingTime { try? await Task.sleep(for: .seconds(typingTime - elapsed)) }
        isTyping = false
        personaMood = [.happy, .excited, .attentive, .curious].randomElement()!
        messages.append(ChatMessage(role: .ilo, text: text.realTrimmed.realNilIfEmpty ?? "Tell me more!"))
        Haptics.shared.softTap()
        SoundFX.shared.play(.bubble)
        scrollTick += 1
        session.mood = .attentive
    }

    func wrapUp(session: ModuleSession) async {
        var canWrap = phase == .chatting
        if case .failed = phase { canWrap = true }
        guard canWrap else { return }
        guard !isTyping else { return }
        voice.stop()
        phase = .grading
        session.mood = .curious
        scrollTick += 1
        let transcript = messages.map { ($0.role == .user ? "Learner" : personaName) + ": " + $0.text }.joined(separator: "\n")
        do {
            let started = Date()
            let grade = try await session.ai.grade(question: "Roleplay with \(persona). Goal: \(goal)",
                                                   answer: transcript, rubric: rubric, sample: sample)
            let elapsed = Date().timeIntervalSince(started)
            if elapsed < 1.2 { try? await Task.sleep(for: .seconds(1.2 - elapsed)) }
            let g = Grade(score: min(1, max(0, grade.score)), passed: grade.passed, feedback: grade.feedback, improved: grade.improved)
            phase = .graded(g)
            personaMood = g.passed ? .happy : .confused
            scrollTick += 1
            session.resolve(correct: g.passed, feedback: g.feedback, correctAnswer: g.passed ? nil : (g.improved ?? sample))
        } catch {
            phase = .failed("ilo couldn't review the chat right now.")
            session.mood = .sad
            scrollTick += 1
        }
    }

    private static func split(_ persona: String) -> (String, String) {
        for sep in [", ", " — ", " - ", ": ", " ("] {
            if let r = persona.range(of: sep) {
                let name = String(persona[..<r.lowerBound]).realTrimmed
                var role = String(persona[r.upperBound...]).realTrimmed
                if role.hasSuffix(")") { role.removeLast() }
                if name.split(separator: " ").count <= 4 && !name.isEmpty {
                    return (name.prefix(1).uppercased() + name.dropFirst(), role.prefix(1).uppercased() + role.dropFirst())
                }
            }
        }
        let words = persona.split(separator: " ")
        if words.count <= 3 { return (persona, "Roleplay partner") }
        return (words.prefix(2).joined(separator: " ").capitalized, persona)
    }
}

extension String {
    var realNilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Bubbles

struct RealChatBubble: View {
    var message: ChatMessage
    var personaName: String
    var personaColor: BloubColor
    var personaShape: BloubShape

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 48) }
            if message.role == .ilo {
                BloubView(shape: personaShape, color: personaColor, expression: .happy, alive: false)
                    .frame(width: 40, height: 40)
            }
            Text(message.text)
                .font(.body(16, weight: .medium))
                .foregroundStyle(message.role == .user ? .white : Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .background(RealBubbleShape(tailLeft: message.role == .ilo, radius: 20)
                    .fill(message.role == .user ? AnyShapeStyle(Palette.ink) : AnyShapeStyle(Color.white)))
                .shadow(color: Color(hex: 0x3A4470, alpha: message.role == .user ? 0.12 : 0.06), radius: 10, y: 4)
            if message.role == .ilo { Spacer(minLength: 48) }
        }
    }
}

struct RealTypingBubble: View {
    var color: BloubColor
    var shape: BloubShape

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            BloubView(shape: shape, color: color, expression: .curious, alive: false)
                .frame(width: 40, height: 40)
            BloubView(color: color, mode: .thinking)
                .frame(width: 46, height: 30)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RealBubbleShape(tailLeft: true, radius: 20).fill(.white))
                .shadow(color: Color(hex: 0x3A4470, alpha: 0.06), radius: 10, y: 4)
            Spacer()
        }
    }
}
