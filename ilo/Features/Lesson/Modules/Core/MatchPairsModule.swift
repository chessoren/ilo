import SwiftUI

/// Two columns, tap-to-pair. Matches pop & fade, wrong pairs shake. Correct if ≤ 1 mistake.
struct MatchPairsModule: View {
    let session: ModuleSession

    private struct Item: Identifiable, Hashable {
        let id: String
        let pairID: UUID
        let text: String
        let isLeft: Bool
    }

    @State private var left: [Item] = []
    @State private var right: [Item] = []
    @State private var selectedLeft: Item?
    @State private var selectedRight: Item?
    @State private var matched: Set<UUID> = []
    @State private var justMatched: UUID?
    @State private var wrongIDs: Set<String> = []
    @State private var shakes = 0
    @State private var mistakes = 0
    @State private var appeared = false

    private var pairs: [Pair] { session.module.pairs ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ModulePrompt(title: session.module.title, prompt: session.module.prompt ?? "Tap the matching pairs")
                    .appear(appeared)
                HStack(alignment: .top, spacing: 12) {
                    column(left)
                    column(right)
                }
                if mistakes > 0 {
                    Label(mistakes == 1 ? "1 mistake" : "\(mistakes) mistakes", systemImage: "xmark.circle.fill")
                        .font(.body(14, weight: .bold))
                        .foregroundStyle(Palette.danger)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: mistakes)
        .onAppear {
            if left.isEmpty {
                left = pairs.map { Item(id: "L\($0.id)", pairID: $0.id, text: $0.left, isLeft: true) }
                right = pairs.map { Item(id: "R\($0.id)", pairID: $0.id, text: $0.right, isLeft: false) }.shuffledDifferently(by: \.pairID)
            }
            appeared = true
            session.hidesCheckBar = true
        }
    }

    private func column(_ items: [Item]) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                let isMatched = matched.contains(item.pairID)
                let isWrong = wrongIDs.contains(item.id)
                Button {
                    tap(item)
                } label: {
                    Text(item.text)
                        .font(.body(16, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.answerTile(state(for: item), radius: 18))
                .disabled(isMatched || session.isResolved)
                .scaleEffect(justMatched == item.pairID ? 1.08 : 1)
                .opacity(isMatched && justMatched != item.pairID && !session.isResolved ? 0.4 : 1)
                .modifier(ModuleShakeEffect(shakes: isWrong ? CGFloat(shakes) : 0))
                .appear(appeared, delay: 0.05 + Double(i) * 0.05)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func state(for item: Item) -> AnswerTileState {
        if justMatched == item.pairID || session.isResolved { return .correct }
        if matched.contains(item.pairID) { return .dimmed }
        if wrongIDs.contains(item.id) { return .wrong }
        if selectedLeft == item || selectedRight == item { return .selected }
        return .idle
    }

    private func tap(_ item: Item) {
        Haptics.shared.tick()
        wrongIDs = []
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            if item.isLeft { selectedLeft = selectedLeft == item ? nil : item } else { selectedRight = selectedRight == item ? nil : item }
        }
        guard let l = selectedLeft, let r = selectedRight else { return }
        if l.pairID == r.pairID {
            SoundFX.shared.play(.pop)
            Haptics.shared.correct()
            session.mood = .happy
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                matched.insert(l.pairID)
                justMatched = l.pairID
                selectedLeft = nil
                selectedRight = nil
            }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.easeOut(duration: 0.35)) { if justMatched == l.pairID { justMatched = nil } }
                if matched.count == pairs.count { finish() }
            }
        } else {
            mistakes += 1
            SoundFX.shared.play(.wrong)
            Haptics.shared.wrong()
            session.mood = .confused
            wrongIDs = [l.id, r.id]
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
            Task {
                try? await Task.sleep(for: .milliseconds(550))
                withAnimation(.smooth) {
                    wrongIDs = []
                    selectedLeft = nil
                    selectedRight = nil
                }
            }
        }
    }

    private func finish() {
        let pass = mistakes <= 1
        let summary = mistakes == 0 ? "All pairs matched, zero mistakes!" : "All matched with \(mistakes) mistake\(mistakes == 1 ? "" : "s")."
        let answer = pass ? nil : pairs.map { "\($0.left) → \($0.right)" }.joined(separator: "\n")
        session.resolve(correct: pass, feedback: [summary, session.module.explanation].compactMap { $0 }.joined(separator: " "), correctAnswer: answer)
    }
}
