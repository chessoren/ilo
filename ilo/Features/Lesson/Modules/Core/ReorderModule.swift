import SwiftUI

/// Drag the cards into the right order (shuffled start). Each row shows green/red after grading.
struct ReorderModule: View {
    let session: ModuleSession

    private struct Row: Identifiable, Hashable {
        let id: Int // index in the correct order
        let text: String
    }

    @State private var rows: [Row] = []
    @State private var appeared = false
    @State private var dragging: Int?
    @State private var dragStart = 0
    @State private var dragOffset: CGFloat = 0

    private let rowHeight: CGFloat = 66
    private let spacing: CGFloat = 12
    private var pitch: CGFloat { rowHeight + 4 + spacing }
    private var steps: [String] { session.module.steps ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    ModulePrompt(title: session.module.title, prompt: session.module.prompt ?? "Put these in the right order")
                    HStack(spacing: 6) {
                        Image(systemName: "hand.draw.fill")
                        Text("Drag the cards to reorder")
                    }
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                }
                .appear(appeared)

                VStack(spacing: spacing) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { position, row in
                        let isDragging = dragging == row.id
                        rowView(row, position: position, lifted: isDragging)
                            .scaleEffect(isDragging ? 1.04 : 1)
                            .offset(y: isDragging ? dragOffset : 0)
                            .zIndex(isDragging ? 10 : 0)
                            .gesture(dragGesture(for: row), including: session.isResolved ? .subviews : .all)
                            .accessibilityIdentifier("reorder-row-\(position)")
                            .appear(appeared, delay: 0.05 + Double(position) * 0.05)
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
            Spacer(minLength: 0)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: session.phase)
        .onAppear {
            if rows.isEmpty {
                rows = steps.enumerated().map { Row(id: $0.offset, text: $0.element) }.shuffledDifferently(by: \.id)
            }
            appeared = true
            session.onCheck = check
            session.mood = .curious
        }
    }

    private func rowView(_ row: Row, position: Int, lifted: Bool) -> some View {
        let state = rowState(row, position: position)
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(state == .idle || state == .selected ? session.tint.soft : state.stroke)
                if session.isResolved {
                    Image(systemName: state == .correct ? "checkmark" : "xmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                } else {
                    Text("\(position + 1)")
                        .font(.display(15, weight: .heavy))
                        .foregroundStyle(session.tint.deep)
                        .contentTransition(.numericText(value: Double(position)))
                }
            }
            .frame(width: 32, height: 32)
            Text(row.text)
                .font(.body(17, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if session.phase == .wrong && state == .wrong {
                Text("#\(row.id + 1)")
                    .font(.display(14, weight: .bold))
                    .foregroundStyle(Palette.danger)
            } else if !session.isResolved {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(lifted ? Palette.periwinkleDeep : Palette.faint)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: rowHeight)
        .contentShape(.rect)
        .answerTile(state, radius: 20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: Palette.periwinkleDeep.opacity(lifted ? 0.3 : 0), radius: 18, y: 10)
        }
    }

    private func rowState(_ row: Row, position: Int) -> AnswerTileState {
        guard session.isResolved else { return dragging == row.id ? .selected : .idle }
        return row.id == position ? .correct : .wrong
    }

    private func dragGesture(for row: Row) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { v in
                guard !session.isResolved else { return }
                if dragging == nil {
                    dragging = row.id
                    dragStart = rows.firstIndex(of: row) ?? 0
                    Haptics.shared.softTap()
                    session.mood = .attentive
                }
                guard let current = rows.firstIndex(of: row) else { return }
                let proposed = min(max(dragStart + Int((v.translation.height / pitch).rounded()), 0), rows.count - 1)
                if proposed != current {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        rows.move(fromOffsets: [current], toOffset: proposed > current ? proposed + 1 : proposed)
                    }
                    Haptics.shared.tick()
                    SoundFX.shared.play(.tick)
                }
                dragOffset = v.translation.height - CGFloat(proposed - dragStart) * pitch
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    dragging = nil
                    dragOffset = 0
                }
                SoundFX.shared.play(.pop)
                session.canCheck = true
            }
    }

    private func check() {
        let correct = rows.enumerated().allSatisfy { $0.offset == $0.element.id }
        session.resolve(correct: correct, correctAnswer: steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
    }
}
