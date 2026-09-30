import SwiftUI

/// Instagram-style stacked story cards: progress ticks, tap right/left or swipe, ilo reacting to each card.
struct StoryCardsModule: View {
    let session: ModuleSession

    @State private var index = 0
    @State private var drag: CGSize = .zero
    @State private var appeared = false

    private var cards: [StoryCard] { session.module.cards ?? [] }
    private var isLast: Bool { index >= cards.count - 1 }

    var body: some View {
        VStack(spacing: 16) {
            ticks
                .padding(.horizontal, Metrics.gutter)

            GeometryReader { geo in
                ZStack {
                    ForEach(Array(cards.enumerated()).reversed(), id: \.element.id) { i, card in
                        if i >= index && i <= index + 2 {
                            cardView(card, index: i)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .modifier(StackPosition(depth: i - index, drag: i == index ? drag : .zero))
                                .zIndex(Double(cards.count - i))
                                .transition(.asymmetric(insertion: .opacity,
                                                        removal: .offset(x: -geo.size.width * 1.3, y: 40).combined(with: .opacity)))
                        }
                    }
                }
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { v in drag = v.translation }
                        .onEnded { v in
                            if v.translation.width < -80 || v.predictedEndTranslation.width < -200 { next() }
                            else if v.translation.width > 80, index > 0 { back() }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { drag = .zero }
                        }
                )
                .onTapGesture(coordinateSpace: .local) { location in
                    if location.x < geo.size.width * 0.3 { back() } else { next() }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Next card")
                .accessibilityAction { next() }
                .accessibilityIdentifier("story-cards")
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 26)
            .appear(appeared)

            ZStack {
                if isLast {
                    Button {
                        Haptics.shared.thud()
                        session.finish()
                    } label: {
                        Label("Got it", systemImage: "checkmark")
                    }
                    .buttonStyle(.pill(.ink))
                    .accessibilityIdentifier("module-done")
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                        Text("Tap or swipe to continue")
                    }
                    .font(.body(14, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .frame(height: Metrics.pillHeight + 5)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 8)
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: index)
        .onAppear {
            appeared = true
            session.hidesCheckBar = true
            session.mood = cards.first?.mood ?? .happy
        }
    }

    // MARK: Pieces

    private var ticks: some View {
        HStack(spacing: 5) {
            ForEach(cards.indices, id: \.self) { i in
                GeometryReader { g in
                    Capsule().fill(Palette.ink.opacity(0.1))
                        .overlay(alignment: .leading) {
                            Capsule().fill(Palette.ink)
                                .frame(width: i <= index ? g.size.width : 0)
                        }
                }
                .frame(height: 5)
            }
        }
    }

    private func cardView(_ card: StoryCard, index i: Int) -> some View {
        let fill = ModulePastels.fill(i)
        let deep = ModulePastels.deep(i)
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("\(i + 1)/\(cards.count)")
                    .font(.display(14, weight: .bold))
                    .foregroundStyle(deep)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.white.opacity(0.7), in: .capsule)
                Spacer()
            }
            Spacer(minLength: 0)
            Image(systemName: card.symbol ?? session.module.type.symbol)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(deep)
                .frame(width: 92, height: 92)
                .background(.white, in: .rect(cornerRadius: 30, style: .continuous))
                .compositingGroup()
                .shadow(color: deep.opacity(0.2), radius: 14, y: 8)
                .symbolEffect(.bounce, value: index == i)
            Text(card.title)
                .font(.display(32, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(highlighted(card.body, phrase: card.highlight, color: deep))
                .font(.body(19, weight: .medium))
                .foregroundStyle(Palette.ink2)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(alignment: .bottom) {
                Spacer()
                BloubView(shape: .circle, color: .ilo, expression: card.mood ?? .happy, alive: i == index)
                    .frame(width: 58, height: 58)
                    .offset(y: 6)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous).fill(fill)
                Circle().fill(.white.opacity(0.35)).frame(width: 260).offset(x: 140, y: -200).blur(radius: 2)
                Circle().stroke(.white.opacity(0.5), lineWidth: 1.5).frame(width: 360).offset(x: -170, y: 260)
            }
            .clipShape(.rect(cornerRadius: 36, style: .continuous))
        }
        .compositingGroup()
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.12), radius: 20, y: 10)
    }

    private func highlighted(_ text: String, phrase: String?, color: Color) -> AttributedString {
        var attr = AttributedString(text)
        if let phrase, !phrase.isEmpty, let range = attr.range(of: phrase, options: .caseInsensitive) {
            attr[range].backgroundColor = .white.opacity(0.85)
            attr[range].foregroundColor = color
            attr[range].font = .body(19, weight: .bold)
        }
        return attr
    }

    // MARK: Actions

    private func next() {
        guard index < cards.count - 1 else {
            Haptics.shared.softTap()
            return
        }
        Haptics.shared.tap()
        SoundFX.shared.play(.whoosh)
        index += 1
        session.mood = cards[index].mood ?? .attentive
    }

    private func back() {
        guard index > 0 else { return }
        Haptics.shared.softTap()
        index -= 1
        session.mood = cards[index].mood ?? .attentive
    }
}

/// Stacked-deck placement: cards behind peek out, the top card follows the finger.
private struct StackPosition: ViewModifier {
    var depth: Int
    var drag: CGSize

    func body(content: Content) -> some View {
        content
            .scaleEffect(1 - CGFloat(depth) * 0.06, anchor: .top)
            .offset(y: CGFloat(depth) * 58)
            .offset(x: drag.width, y: drag.height * 0.15)
            .rotationEffect(.degrees(Double(drag.width) / 22), anchor: .bottom)
            .opacity(depth > 1 ? 0.6 : 1)
    }
}
