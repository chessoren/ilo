import SwiftUI

/// Open question answered in the learner's own words (typed or dictated), graded by ilo against a rubric.
struct FreeAnswerModule: View {
    let session: ModuleSession
    @State private var model = RealAnswerModel()
    @State private var visible = false
    @State private var showHints = false
    @FocusState private var focused: Bool

    private var module: LessonModule { session.module }
    private var question: String { module.prompt ?? module.title ?? "Explain it in your own words." }
    private var rubric: [String] { module.rubric ?? [] }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RealHeader(type: module.type, title: module.title == module.prompt ? nil : module.title, tint: session.tint)

                    questionCard
                        .appear(visible, delay: 0.08)

                    RealIloSays(text: iloLine, expression: iloExpression, mode: model.status == .grading ? .thinking : .face, size: 54)
                        .appear(visible, delay: 0.16)

                    RealTextArea(text: $model.text, placeholder: "Type your answer…", minHeight: 140,
                                 disabled: model.isLocked, focus: $focused) {
                        RealMicButton(voice: model.voice, text: $model.text)
                            .disabled(model.isLocked)
                    }
                    .appear(visible, delay: 0.22)
                    .id("editor")

                    switch model.status {
                    case .grading:
                        RealThinkingRow(text: "ilo is reading your answer…")
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    case .graded(let grade):
                        RealGradeCard(grade: grade, sample: module.sampleAnswer, tint: session.tint)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("result")
                    case .failed(let why):
                        RealErrorRow(text: why) { model.resetError(session: session); Task { await check() } }
                    case .writing:
                        EmptyView()
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.status) { _, status in
                if case .graded = status {
                    focused = false
                    withAnimation(.smooth(duration: 0.6)) { proxy.scrollTo("result", anchor: .top) }
                }
            }
        }
        .onAppear(perform: setup)
        .onChange(of: model.text) {
            if !model.isLocked { session.canCheck = model.hasAnswer }
            if session.mood == .attentive, model.hasAnswer { session.mood = .curious }
        }
        .onDisappear { model.voice.stop() }
        .realDemoAuto {
            await realPause(1.2)
            withAnimation { showHints = true }
            for word in "Because improvements compound: each tiny gain builds on the last one, so 1% a day ends up around 37 times better after a year.".split(separator: " ") {
                model.text += (model.text.isEmpty ? "" : " ") + word
                await realPause(0.05)
            }
            await realPause(1.0)
            session.check()
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question)
                .font(.display(22, weight: .bold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !rubric.isEmpty {
                Button {
                    Haptics.shared.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showHints.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .symbolEffect(.bounce, value: showHints)
                        Text(showHints ? "Hide hints" : "What ilo looks for")
                    }
                    .font(.body(13, weight: .bold))
                    .foregroundStyle(session.tint.deep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(session.tint.soft, in: .capsule)
                }
                .buttonStyle(.squish)
                if showHints {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(rubric.enumerated()), id: \.offset) { i, item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(session.tint.deep)
                                Text(item)
                                    .font(.body(14, weight: .medium))
                                    .foregroundStyle(Palette.ink2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity).animation(.spring.delay(Double(i) * 0.05)),
                                                    removal: .opacity))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 30, padding: 22)
    }

    private var iloLine: String {
        switch model.status {
        case .writing: model.voice.isListening ? "I'm listening…" : (model.hasAnswer ? "Looking good — tap Check when you're ready." : "No multiple choice here. Tell me in your own words!")
        case .grading: "Hmm, let me think about that…"
        case .graded(let g): g.passed ? "You really get it!" : "Good try — here's how to make it even better."
        case .failed: "Oops, I lost my train of thought."
        }
    }

    private var iloExpression: BloubExpression {
        switch model.status {
        case .writing: model.voice.isListening ? .attentive : (model.hasAnswer ? .happy : .curious)
        case .grading: .curious
        case .graded(let g): g.passed ? .proud : .confused
        case .failed: .sad
        }
    }

    private func setup() {
        visible = true
        session.hidesCheckBar = false
        session.checkTitle = "Check"
        session.canCheck = model.hasAnswer && !model.isLocked
        session.onCheck = { Task { await check() } }
    }

    private func check() async {
        focused = false
        await model.submit(session: session, question: question, rubric: rubric, sample: module.sampleAnswer)
    }
}
