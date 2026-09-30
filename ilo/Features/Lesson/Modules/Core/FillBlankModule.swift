import SwiftUI

/// A sentence with a gap; the chosen option chip flies into the blank.
struct FillBlankModule: View {
    let session: ModuleSession

    @Namespace private var ns
    @State private var chosen: Int?
    @State private var appeared = false
    @State private var shakes = 0

    private var module: LessonModule { session.module }
    private var options: [String] { module.options ?? [] }
    private var correctIndex: Int { module.correctIndex ?? 0 }

    private enum Piece: Hashable { case word(Int, String), blank(Int) }

    private var pieces: [Piece] {
        let sentence = module.sentence ?? "___"
        let parts = sentence.components(separatedBy: "___")
        var out: [Piece] = []
        var n = 0
        for (i, part) in parts.enumerated() {
            for w in part.split(separator: " ") { out.append(.word(n, String(w))); n += 1 }
            if i < parts.count - 1 { out.append(.blank(i)) }
        }
        return out
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ModulePrompt(title: module.title, prompt: module.prompt ?? "Fill the gap")
                    .appear(appeared)

                ModuleFlowLayout(spacing: 7, lineSpacing: 14) {
                    ForEach(pieces, id: \.self) { piece in
                        switch piece {
                        case .word(_, let w):
                            Text(w)
                                .font(.display(24, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                        case .blank(let i):
                            // Only the first gap holds the chip (one matched-geometry source); extra gaps stay as hints.
                            if i == 0 { blank } else { emptyGap }
                        }
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: .rect(cornerRadius: 28, style: .continuous))
                .compositingGroup()
                .shadow(color: Color(hex: 0x3A4470, alpha: 0.06), radius: 18, y: 8)
                .appear(appeared, delay: 0.06)

                ModuleFlowLayout(spacing: 10, lineSpacing: 12, alignment: .center) {
                    ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                        if chosen == i {
                            chipText(option)
                                .opacity(0)
                                .answerTile(.idle, radius: 16)
                                .overlay { RoundedRectangle(cornerRadius: 16).fill(Palette.canvasDeep).padding(.bottom, 4) }
                        } else {
                            Button {
                                choose(i)
                            } label: {
                                chipText(option)
                            }
                            .buttonStyle(.answerTile(session.isResolved ? .dimmed : .idle, radius: 16))
                            .accessibilityIdentifier("answer-\(i)")
                            .matchedGeometryEffect(id: i, in: ns)
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
            appeared = true
            session.onCheck = check
        }
    }

    @ViewBuilder
    private var blank: some View {
        if let chosen, options.indices.contains(chosen) {
            Button {
                unchoose()
            } label: {
                chipText(options[chosen])
            }
            .buttonStyle(.answerTile(blankState, radius: 16))
            .matchedGeometryEffect(id: chosen, in: ns)
            .disabled(session.isResolved)
            .modifier(ModuleShakeEffect(shakes: CGFloat(shakes)))
        } else {
            emptyGap
        }
    }

    private var emptyGap: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(session.tint.soft.opacity(0.6))
            .overlay(alignment: .bottom) {
                Capsule().fill(session.tint.deep).frame(height: 3)
            }
            .frame(width: 96, height: 40)
            .phaseAnimator([0.55, 1]) { v, phase in v.opacity(phase) } animation: { _ in .easeInOut(duration: 0.9) }
    }

    private var blankState: AnswerTileState {
        switch session.phase {
        case .answering: .selected
        case .correct: .correct
        case .wrong: .wrong
        }
    }

    private func chipText(_ text: String) -> some View {
        Text(text)
            .font(.display(19, weight: .semibold))
            .padding(.horizontal, 16)
            .frame(height: 46)
    }

    private func choose(_ i: Int) {
        Haptics.shared.tick()
        SoundFX.shared.play(.pop)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) { chosen = i }
        session.canCheck = true
        session.mood = .curious
    }

    private func unchoose() {
        Haptics.shared.softTap()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) { chosen = nil }
        session.canCheck = false
    }

    private func check() {
        let correct = chosen == correctIndex
        if !correct { withAnimation(.linear(duration: 0.4)) { shakes += 1 } }
        let answer = options.indices.contains(correctIndex) ? (module.sentence ?? "___").replacingOccurrences(of: "___", with: options[correctIndex]) : nil
        session.resolve(correct: correct, correctAnswer: answer)
    }
}
