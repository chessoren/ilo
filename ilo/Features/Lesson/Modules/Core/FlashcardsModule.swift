import SwiftUI

/// 3D-flip flashcards. Swipe right “Got it”, left “Again” (the card goes back into the deck).
struct FlashcardsModule: View {
    let session: ModuleSession

    @State private var deck: [Flashcard] = []
    @State private var learned = 0
    @State private var flipped = false
    @State private var drag: CGSize = .zero
    @State private var flyOut: CGFloat = 0
    @State private var appeared = false
    @State private var total = 0

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                ModulePrompt(title: "Flashcards", prompt: session.module.title ?? "Tap to flip")
                Spacer()
            }
            .padding(.horizontal, Metrics.gutter)
            .appear(appeared)

            HStack(spacing: 10) {
                counter(value: deck.count, label: "to go", color: Palette.orange, symbol: "rectangle.stack.fill")
                counter(value: learned, label: "learned", color: Palette.success, symbol: "checkmark.seal.fill")
                Spacer()
            }
            .padding(.horizontal, Metrics.gutter)
            .appear(appeared, delay: 0.05)

            ZStack {
                if deck.isEmpty && total > 0 {
                    doneView
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                } else {
                    ForEach(Array(deck.prefix(3).enumerated()).reversed(), id: \.element.id) { i, card in
                        FlipCard(card: card, flipped: i == 0 && flipped, tint: ModulePastels.fill(total - deck.count + i), deep: ModulePastels.deep(total - deck.count + i))
                            .overlay { if i == 0 { swipeStamp } }
                            .scaleEffect(1 - CGFloat(i) * 0.05)
                            .offset(y: CGFloat(i) * 16)
                            .offset(x: i == 0 ? drag.width + flyOut : 0, y: i == 0 ? drag.height * 0.2 : 0)
                            .rotationEffect(.degrees(i == 0 ? Double(drag.width + flyOut) / 18 : 0), anchor: .bottom)
                            .zIndex(Double(10 - i))
                            .gesture(dragGesture, including: i == 0 ? .all : .subviews)
                            .onTapGesture { if i == 0 { flip() } }
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter + 8)
            .padding(.bottom, 20)
            .frame(maxHeight: .infinity)
            .appear(appeared, delay: 0.1)

            if !deck.isEmpty {
                HStack(spacing: 14) {
                    Button { swipe(right: false) } label: {
                        Label("Again", systemImage: "arrow.counterclockwise")
                            .font(.display(17, weight: .bold))
                            .frame(maxWidth: .infinity).frame(height: 54)
                    }
                    .buttonStyle(.answerTile(.idle, radius: 27))
                    Button { swipe(right: true) } label: {
                        Label("Got it", systemImage: "checkmark")
                            .font(.display(17, weight: .bold))
                            .frame(maxWidth: .infinity).frame(height: 54)
                    }
                    .buttonStyle(.answerTile(.correct, radius: 27))
                    .accessibilityIdentifier("flash-gotit")
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: deck.count)
        .onAppear {
            if deck.isEmpty && total == 0 {
                deck = session.module.flashcards ?? []
                total = deck.count
            }
            appeared = true
            session.hidesCheckBar = true
            session.mood = .attentive
        }
    }

    private func counter(value: Int, label: String, color: Color, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).foregroundStyle(color)
            Text("\(value)")
                .font(.display(16, weight: .heavy))
                .contentTransition(.numericText(value: Double(value)))
            Text(label).font(.body(14, weight: .semibold)).foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 12).frame(height: 34)
        .background(.white, in: .capsule)
    }

    @ViewBuilder
    private var swipeStamp: some View {
        let x = drag.width + flyOut
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill((x > 0 ? Palette.success : Palette.orange).opacity(min(abs(x) / 260, 0.35)))
            Text(x > 0 ? "GOT IT" : "AGAIN")
                .font(.display(34, weight: .black))
                .foregroundStyle(x > 0 ? Palette.success : Palette.orange)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(x > 0 ? Palette.success : Palette.orange, lineWidth: 4))
                .rotationEffect(.degrees(x > 0 ? -14 : 14))
                .opacity(min(abs(x) / 90, 1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: x > 0 ? .topLeading : .topTrailing)
                .padding(28)
        }
        .allowsHitTesting(false)
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            BloubView(shape: .circle, color: .ink, expression: .proud)
                .frame(width: 110, height: 110)
            Text("Deck mastered!")
                .font(.display(30, weight: .heavy))
                .foregroundStyle(Palette.ink)
            Text("\(total) cards in your head. Nice.")
                .font(.body(16, weight: .medium))
                .foregroundStyle(Palette.muted)
            Button("Continue") {
                session.finish()
            }
            .buttonStyle(.pill(.ink))
            .accessibilityIdentifier("module-done")
            .padding(.top, 10)
        }
        .padding(24)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                let crossed = abs(v.translation.width) > 110
                if crossed != (abs(drag.width) > 110) { Haptics.shared.tick() }
                drag = v.translation
            }
            .onEnded { v in
                if abs(v.translation.width) > 110 || abs(v.predictedEndTranslation.width) > 320 {
                    swipe(right: v.translation.width > 0)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = .zero }
                }
            }
    }

    private func flip() {
        Haptics.shared.softTap()
        SoundFX.shared.play(.whoosh)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { flipped.toggle() }
        session.mood = flipped ? .curious : .attentive
    }

    private func swipe(right: Bool) {
        guard let top = deck.first, flyOut == 0 else { return }
        if right { Haptics.shared.correct(); SoundFX.shared.play(.pop) } else { Haptics.shared.thud(); SoundFX.shared.play(.whoosh) }
        session.mood = right ? .happy : .confused
        withAnimation(.easeIn(duration: 0.22)) { flyOut = right ? 520 : -520 }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                flyOut = 0
                drag = .zero
                flipped = false
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                deck.removeFirst()
                if right { learned += 1 } else { deck.append(Flashcard(front: top.front, back: top.back)) }
            }
            if deck.isEmpty {
                Haptics.shared.celebrate()
                SoundFX.shared.play(.complete)
                session.mood = .proud
            }
        }
    }
}

/// Two-faced card flipping in 3D.
private struct FlipCard: View {
    var card: Flashcard
    var flipped: Bool
    var tint: Color
    var deep: Color

    var body: some View {
        ZStack {
            face(text: card.front, caption: "Tap to reveal", symbol: "questionmark", fill: .white, text: Palette.ink)
                .opacity(flipped ? 0 : 1)
            face(text: card.back, caption: "Swipe → if you knew it", symbol: "lightbulb.fill", fill: tint, text: Palette.ink)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                .opacity(flipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (0, 1, 0), perspective: 0.5)
    }

    private func face(text: String, caption: String, symbol: String, fill: Color, text textColor: Color) -> some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(deep)
                .frame(width: 52, height: 52)
                .background(deep.opacity(0.14), in: .circle)
            Text(text)
                .font(.display(30, weight: .heavy))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(.body(13, weight: .semibold))
                .foregroundStyle(Palette.muted)
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(fill, in: .rect(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(deep.opacity(0.18), lineWidth: 2))
        .compositingGroup()
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.1), radius: 18, y: 8)
    }
}
