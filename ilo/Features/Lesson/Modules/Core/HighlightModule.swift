import SwiftUI

/// Tap all the key words: each segment toggles a hand-drawn marker highlight. Correct if the exact set is found.
struct HighlightModule: View {
    let session: ModuleSession

    @State private var selected: Set<Int> = []
    @State private var appeared = false

    private var segments: [String] { session.module.segments ?? [] }
    private var answers: Set<Int> { Set(session.module.answerIndexes ?? []) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ModulePrompt(title: session.module.title ?? "Find it", prompt: session.module.prompt ?? "Tap all the key words")
                    .appear(appeared)

                HStack(spacing: 8) {
                    Image(systemName: "highlighter")
                        .foregroundStyle(Palette.orange)
                    Text("\(selected.count) selected")
                        .contentTransition(.numericText(value: Double(selected.count)))
                    if answers.count > 1 {
                        Text("· find \(answers.count)")
                            .foregroundStyle(Palette.muted)
                    }
                }
                .font(.body(14, weight: .bold))
                .foregroundStyle(Palette.ink)
                .appear(appeared, delay: 0.04)

                ModuleFlowLayout(spacing: 4, lineSpacing: 12) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                        Button {
                            toggle(i)
                        } label: {
                            Text(seg)
                                .font(.display(24, weight: .semibold))
                                .foregroundStyle(textColor(i))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(alignment: .leading) {
                                    MarkerStroke()
                                        .fill(markerColor(i))
                                        .scaleEffect(x: isMarked(i) ? 1 : 0.001, anchor: .leading)
                                }
                                .overlay {
                                    if session.isResolved && answers.contains(i) && !selected.contains(i) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Palette.success, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                    }
                                }
                        }
                        .buttonStyle(.squish(0.92))
                        .accessibilityIdentifier("segment-\(i)")
                        .disabled(session.isResolved)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: .rect(cornerRadius: 28, style: .continuous))
                .compositingGroup()
                .shadow(color: Color(hex: 0x3A4470, alpha: 0.06), radius: 18, y: 8)
                .appear(appeared, delay: 0.08)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
        .animation(.smooth, value: session.phase)
        .onAppear {
            appeared = true
            session.onCheck = check
            session.mood = .curious
        }
    }

    private func isMarked(_ i: Int) -> Bool {
        selected.contains(i) || (session.isResolved && answers.contains(i))
    }

    private func markerColor(_ i: Int) -> Color {
        guard session.isResolved else { return Palette.gold.opacity(0.55) }
        if answers.contains(i) { return Palette.success.opacity(selected.contains(i) ? 0.35 : 0.15) }
        return Palette.danger.opacity(0.3)
    }

    private func textColor(_ i: Int) -> Color {
        guard session.isResolved else { return Palette.ink }
        if selected.contains(i) && !answers.contains(i) { return Color(hex: 0xB3322A) }
        if answers.contains(i) { return Color(hex: 0x1C7F4E) }
        return Palette.ink.opacity(0.5)
    }

    private func toggle(_ i: Int) {
        if selected.contains(i) {
            selected.remove(i)
            Haptics.shared.softTap()
        } else {
            selected.insert(i)
            Haptics.shared.tick()
            SoundFX.shared.play(.pop)
        }
        session.canCheck = !selected.isEmpty
    }

    private func check() {
        let correct = selected == answers
        let answer = answers.sorted().compactMap { segments.indices.contains($0) ? segments[$0] : nil }.joined(separator: " · ")
        session.resolve(correct: correct, correctAnswer: answer)
    }
}

/// A slightly wonky highlighter stroke.
private struct MarkerStroke: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.insetBy(dx: -2, dy: rect.height * 0.12)
        p.move(to: CGPoint(x: r.minX + 3, y: r.minY + 4))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 1), control: CGPoint(x: r.midX, y: r.minY - 2))
        p.addLine(to: CGPoint(x: r.maxX - 3, y: r.maxY - 2))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.midX, y: r.maxY + 3))
        p.closeSubpath()
        return p
    }
}
