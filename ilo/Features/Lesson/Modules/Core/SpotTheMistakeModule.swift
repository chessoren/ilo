import SwiftUI

/// Tap the wrong segment(s) of a text or code snippet.
struct SpotTheMistakeModule: View {
    let session: ModuleSession

    @State private var selected: Set<Int> = []
    @State private var appeared = false
    @State private var shakes = 0

    private var segments: [String] { session.module.segments ?? [] }
    private var answers: Set<Int> { Set(session.module.answerIndexes ?? []) }
    private var isCode: Bool {
        if session.course.category == .code || session.module.language != nil { return true }
        let joined = segments.joined()
        let symbols = joined.filter { "{}();=<>[]".contains($0) }.count
        return symbols >= 4
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ModulePrompt(title: session.module.title ?? "Spot the mistake",
                             prompt: session.module.prompt ?? (answers.count > 1 ? "Tap the \(answers.count) parts that are wrong" : "Tap the part that's wrong"))
                    .appear(appeared)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: isCode ? "chevron.left.forwardslash.chevron.right" : "magnifyingglass")
                        Text(isCode ? "Find the bug" : "Something's off…")
                    }
                    .font(.body(12, weight: .heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(isCode ? Palette.faint : session.tint.deep)

                    ModuleFlowLayout(spacing: isCode ? 6 : 6, lineSpacing: 10) {
                        ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                            Button {
                                toggle(i)
                            } label: {
                                Text(seg)
                                    .font(isCode ? .system(size: 16, weight: .medium, design: .monospaced) : .body(18, weight: .semibold))
                                    .strikethrough(session.isResolved && answers.contains(i), color: Palette.danger)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(textColor(i))
                                    .background(segmentFill(i), in: .rect(cornerRadius: 10, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(segmentStroke(i), style: StrokeStyle(lineWidth: 2, dash: selected.contains(i) || session.isResolved ? [] : [4, 3])))
                                    .scaleEffect(selected.contains(i) && !session.isResolved ? 1.05 : 1)
                            }
                            .buttonStyle(.squish(0.94))
                            .disabled(session.isResolved)
                            .modifier(ModuleShakeEffect(shakes: session.phase == .wrong && selected.contains(i) && !answers.contains(i) ? CGFloat(shakes) : 0))
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isCode ? Color(hex: 0x16171D) : .white, in: .rect(cornerRadius: 26, style: .continuous))
                .compositingGroup()
                .shadow(color: Color(hex: 0x3A4470, alpha: 0.08), radius: 18, y: 8)
                .appear(appeared, delay: 0.08)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
        .animation(.smooth, value: session.phase)
        .onAppear {
            appeared = true
            session.onCheck = check
            session.mood = .suspicious
        }
    }

    private func textColor(_ i: Int) -> Color {
        if session.isResolved && answers.contains(i) { return selected.contains(i) ? Color(hex: 0x1C7F4E) : Color(hex: 0xB3322A) }
        if session.isResolved && selected.contains(i) { return Color(hex: 0xB3322A) }
        if selected.contains(i) { return isCode ? .white : Color(hex: 0x3F57C0) }
        return isCode ? Color(hex: 0xE6E8F0) : Palette.ink
    }

    private func segmentFill(_ i: Int) -> Color {
        if session.isResolved {
            if answers.contains(i) { return selected.contains(i) ? Palette.successSoft : Palette.dangerSoft }
            if selected.contains(i) { return Palette.dangerSoft }
            return .clear
        }
        if selected.contains(i) { return isCode ? Palette.periwinkleDeep : Palette.periwinkleMist }
        return isCode ? .white.opacity(0.05) : Palette.canvas
    }

    private func segmentStroke(_ i: Int) -> Color {
        if session.isResolved {
            if answers.contains(i) { return selected.contains(i) ? Palette.success : Palette.danger }
            return selected.contains(i) ? Palette.danger : .clear
        }
        if selected.contains(i) { return Palette.periwinkleDeep }
        return isCode ? .white.opacity(0.15) : Palette.ink.opacity(0.12)
    }

    private func toggle(_ i: Int) {
        Haptics.shared.tick()
        SoundFX.shared.play(.tap)
        if selected.contains(i) {
            selected.remove(i)
        } else {
            if answers.count <= 1 { selected = [i] } else { selected.insert(i) }
        }
        session.canCheck = !selected.isEmpty
    }

    private func check() {
        let correct = selected == answers
        if !correct { withAnimation(.linear(duration: 0.4)) { shakes += 1 } }
        let answer = answers.sorted().compactMap { segments.indices.contains($0) ? "“\(segments[$0])”" : nil }.joined(separator: ", ")
        session.resolve(correct: correct, correctAnswer: "The mistake: \(answer)")
    }
}
