import SwiftUI

/// Big answer tiles with letter badges. Select → Check → correct / wrong states.
struct MultipleChoiceModule: View {
    let session: ModuleSession

    @State private var selected: Int?
    @State private var shakes = 0
    @State private var appeared = false

    private var module: LessonModule { session.module }
    private var options: [String] { module.options ?? [] }
    private var correctIndex: Int { module.correctIndex ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ModulePrompt(title: module.title, prompt: module.prompt)
                    .appear(appeared)
                VStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                        Button {
                            select(i)
                        } label: {
                            HStack(spacing: 14) {
                                AnswerLetterBadge(index: i, state: state(for: i))
                                Text(option)
                                    .font(.body(17, weight: .semibold))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .frame(minHeight: 64)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.answerTile(state(for: i), radius: 20))
                        .scaleEffect(selected == i && !session.isResolved ? 1.02 : 1)
                        .modifier(ModuleShakeEffect(shakes: session.phase == .wrong && selected == i ? CGFloat(shakes) : 0))
                        .disabled(session.isResolved)
                        .appear(appeared, delay: 0.06 + Double(i) * 0.05)
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: session.phase)
        .onAppear {
            appeared = true
            session.onCheck = check
        }
    }

    private func select(_ i: Int) {
        guard !session.isResolved else { return }
        Haptics.shared.tick()
        selected = i
        session.canCheck = true
        session.mood = .curious
    }

    private func check() {
        guard let selected else { return }
        let correct = selected == correctIndex
        if !correct { withAnimation(.linear(duration: 0.4)) { shakes += 1 } }
        session.resolve(correct: correct, correctAnswer: options.indices.contains(correctIndex) ? options[correctIndex] : nil)
    }

    private func state(for i: Int) -> AnswerTileState {
        switch session.phase {
        case .answering: return selected == i ? .selected : .idle
        case .correct, .wrong:
            if i == correctIndex { return selected == i ? .correct : .missed }
            if i == selected { return .wrong }
            return .dimmed
        }
    }
}
