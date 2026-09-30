import SwiftUI

/// Duolingo word bank: bricks fly between the bank and the answer line (matchedGeometryEffect).
struct WordBricksModule: View {
    let session: ModuleSession

    private struct Brick: Identifiable, Hashable {
        let id: Int
        let text: String
    }

    @Namespace private var ns
    @State private var bank: [Brick] = []
    @State private var answer: [Brick] = []
    @State private var appeared = false
    @State private var shakes = 0

    private var tokens: [String] { session.module.answerTokens ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .bottom, spacing: 10) {
                    ModulePrompt(title: session.module.title, prompt: session.module.prompt ?? "Build the sentence")
                }
                .appear(appeared)

                // Answer line
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 58) {
                        ForEach(0..<2, id: \.self) { _ in
                            Rectangle().fill(Palette.ink.opacity(0.1)).frame(height: 2)
                        }
                    }
                    .padding(.top, 56)

                    ModuleFlowLayout(spacing: 8, lineSpacing: 12) {
                        ForEach(answer) { brick in
                            Button {
                                remove(brick)
                            } label: {
                                brickLabel(brick.text)
                            }
                            .buttonStyle(.answerTile(answerState, radius: 14))
                            .matchedGeometryEffect(id: brick.id, in: ns)
                            .disabled(session.isResolved)
                        }
                    }
                    .padding(.top, 4)
                    .modifier(ModuleShakeEffect(shakes: CGFloat(shakes)))
                }
                .frame(minHeight: 130, alignment: .top)
                .appear(appeared, delay: 0.06)

                // Bank (keeps a grey hole where a brick left)
                ModuleFlowLayout(spacing: 8, lineSpacing: 12, alignment: .center) {
                    ForEach(bank) { brick in
                        if answer.contains(brick) {
                            brickLabel(brick.text)
                                .hidden()
                                .background(Palette.canvasDeep, in: .rect(cornerRadius: 14, style: .continuous))
                                .padding(.bottom, 4)
                        } else {
                            Button {
                                add(brick)
                            } label: {
                                brickLabel(brick.text)
                            }
                            .buttonStyle(.answerTile(session.isResolved ? .dimmed : .idle, radius: 14))
                            .matchedGeometryEffect(id: brick.id, in: ns)
                            .disabled(session.isResolved)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .appear(appeared, delay: 0.12)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            if bank.isEmpty {
                let all = tokens + (session.module.distractors ?? [])
                bank = all.enumerated().map { Brick(id: $0.offset, text: $0.element) }.shuffled()
            }
            appeared = true
            session.onCheck = check
        }
    }

    private var answerState: AnswerTileState {
        switch session.phase {
        case .answering: .idle
        case .correct: .correct
        case .wrong: .wrong
        }
    }

    private func brickLabel(_ text: String) -> some View {
        Text(text)
            .font(.body(18, weight: .semibold))
            .padding(.horizontal, 14)
            .frame(height: 44)
    }

    private func add(_ brick: Brick) {
        Haptics.shared.tick()
        SoundFX.shared.play(.pop)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { answer.append(brick) }
        session.canCheck = true
        session.mood = .curious
    }

    private func remove(_ brick: Brick) {
        Haptics.shared.softTap()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) { answer.removeAll { $0 == brick } }
        session.canCheck = !answer.isEmpty
    }

    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
    }

    private func check() {
        let given = answer.map { normalize($0.text) }
        let expected = tokens.map { normalize($0) }
        let correct = given == expected
        if !correct { withAnimation(.linear(duration: 0.4)) { shakes += 1 } }
        session.resolve(correct: correct, correctAnswer: tokens.joined(separator: " "))
    }
}
