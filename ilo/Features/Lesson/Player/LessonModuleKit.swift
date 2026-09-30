import SwiftUI

// Shared building blocks for lesson modules (prompt header, tactile tiles, shake, flow layout…).
// Anyone building a module can use these.

// MARK: - Prompt header

/// Big bold question at the top of a module, with an optional small title above it.
struct ModulePrompt: View {
    var title: String?
    var prompt: String?
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            if let title, !title.isEmpty {
                Text(title.uppercased())
                    .font(.body(12, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Palette.muted)
            }
            if let prompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.display(24, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }
}

// MARK: - Tactile tile

/// Visual state of an answer tile.
enum AnswerTileState: Equatable {
    case idle, selected, correct, wrong, dimmed, missed

    var fill: Color {
        switch self {
        case .idle, .dimmed: .white
        case .selected: Palette.periwinkleMist
        case .correct: Palette.successSoft
        case .wrong: Palette.dangerSoft
        case .missed: Color(hex: 0xEEFBF3)
        }
    }

    var stroke: Color {
        switch self {
        case .idle, .dimmed: Color(hex: 0xE3E6F0)
        case .selected: Palette.periwinkleDeep
        case .correct, .missed: Palette.success
        case .wrong: Palette.danger
        }
    }

    var lip: Color {
        switch self {
        case .idle, .dimmed: Color(hex: 0xDADEEA)
        case .selected: Palette.periwinkleDeep
        case .correct, .missed: Color(hex: 0x23995F)
        case .wrong: Color(hex: 0xC43A31)
        }
    }

    var text: Color {
        switch self {
        case .idle: Palette.ink
        case .dimmed: Palette.faint
        case .selected: Color(hex: 0x3F57C0)
        case .correct, .missed: Color(hex: 0x1C7F4E)
        case .wrong: Color(hex: 0xB3322A)
        }
    }
}

/// Solid, pressable 3D surface (Duolingo-style lip) used for answer tiles, chips and bricks.
struct AnswerTileSurface: ViewModifier {
    var state: AnswerTileState
    var radius: CGFloat = 20
    var lip: CGFloat = 4
    var pressed = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .foregroundStyle(state.text)
            .background(shape.fill(state.fill))
            .overlay(shape.strokeBorder(state.stroke, lineWidth: 2))
            .background(shape.fill(state.lip).offset(y: pressed ? 0 : lip))
            .offset(y: pressed ? lip : 0)
            .padding(.bottom, lip)
            .opacity(state == .dimmed ? 0.55 : 1)
    }
}

extension View {
    func answerTile(_ state: AnswerTileState, radius: CGFloat = 20, lip: CGFloat = 4, pressed: Bool = false) -> some View {
        modifier(AnswerTileSurface(state: state, radius: radius, lip: lip, pressed: pressed))
    }
}

/// Button style that presses the tactile lip down.
struct AnswerTileButtonStyle: ButtonStyle {
    var state: AnswerTileState
    var radius: CGFloat = 20
    var lip: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .answerTile(state, radius: radius, lip: lip, pressed: configuration.isPressed)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, down in
                if down { Haptics.shared.tap(); SoundFX.shared.play(.tap) }
            }
    }
}

extension ButtonStyle where Self == AnswerTileButtonStyle {
    static func answerTile(_ state: AnswerTileState, radius: CGFloat = 20, lip: CGFloat = 4) -> AnswerTileButtonStyle {
        AnswerTileButtonStyle(state: state, radius: radius, lip: lip)
    }
}

// MARK: - Shake

/// Horizontal shake — animate `shakes` by +1 to trigger.
struct ModuleShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var amplitude: CGFloat = 9

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amplitude * sin(shakes * .pi * 4), y: 0))
    }
}

extension View {
    func moduleShake(_ count: Int) -> some View {
        modifier(ModuleShakeEffect(shakes: CGFloat(count))).animation(.linear(duration: 0.4), value: count)
    }
}

// MARK: - Flow layout

/// Wrapping horizontal layout (chips, word bricks, tappable text segments).
struct ModuleFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 10
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * lineSpacing
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x: CGFloat
            switch alignment {
            case .center: x = bounds.minX + (bounds.width - row.width) / 2
            case .trailing: x = bounds.maxX - row.width
            default: x = bounds.minX
            }
            for index in row.indexes {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var indexes: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for (i, sub) in subviews.enumerated() {
            var size = sub.sizeThatFits(.unspecified)
            size.width = min(size.width, width)
            let needed = rows[rows.count - 1].indexes.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indexes.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indexes.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indexes.append(i)
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.indexes.isEmpty }
    }
}

// MARK: - Helpers

extension Array {
    /// Shuffled, but guaranteed different from the original order when possible.
    func shuffledDifferently<T: Equatable>(by key: (Element) -> T) -> [Element] {
        guard count > 1 else { return self }
        // Prefer a derangement: nothing stays in its original slot.
        for _ in 0..<40 {
            let s = shuffled()
            if !zip(s, self).contains(where: { key($0) == key($1) }) { return s }
        }
        return Array(dropFirst()) + [self[0]]
    }
}

/// Pastel card colours cycled through by story cards, flashcards, etc.
enum ModulePastels {
    static let fills: [Color] = [Palette.peach, Palette.lavender, Palette.mint, Palette.pink, Palette.sky, Palette.butter]
    static let deeps: [Color] = [Color(hex: 0xD9731F), Color(hex: 0x7B6BE0), Color(hex: 0x2FAE78), Color(hex: 0xB85FCB), Color(hex: 0x2F8FE0), Color(hex: 0xC99A17)]
    static func fill(_ i: Int) -> Color { fills[((i % fills.count) + fills.count) % fills.count] }
    static func deep(_ i: Int) -> Color { deeps[((i % deeps.count) + deeps.count) % deeps.count] }
}

/// Small letter badge "A", "B"… for answer tiles.
struct AnswerLetterBadge: View {
    var index: Int
    var state: AnswerTileState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(state == .idle || state == .dimmed ? Palette.canvas : state.stroke)
            Group {
                switch state {
                case .correct, .missed: Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy))
                case .wrong: Image(systemName: "xmark").font(.system(size: 14, weight: .heavy))
                default: Text(String(UnicodeScalar(UInt8(65 + min(index, 25)))))
                        .font(.display(15, weight: .bold))
                }
            }
            .foregroundStyle(state == .idle || state == .dimmed ? Palette.muted : .white)
            .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 34, height: 34)
    }
}

/// Formats numbers for sliders / estimates: no trailing zeros, thousands separators.
enum ModuleNumberFormat {
    static func format(_ value: Double, step: Double) -> String {
        let decimals = step >= 1 ? 0 : min(4, Int(ceil(-log10(step))))
        return value.formatted(.number.precision(.fractionLength(decimals)).grouping(.automatic))
    }
}
