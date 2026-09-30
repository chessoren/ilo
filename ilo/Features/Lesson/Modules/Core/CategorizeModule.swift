import SwiftUI

/// Sort items into 2–3 buckets: drag an item onto a bucket, or tap an item then a bucket.
struct CategorizeModule: View {
    let session: ModuleSession

    @Namespace private var ns
    @State private var pool: [CategorizedItem] = []
    @State private var placed: [UUID: Int] = [:]
    @State private var selected: UUID?
    @State private var targeted: Int?
    @State private var appeared = false
    @State private var dragItem: UUID?
    @State private var dragTranslation: CGSize = .zero
    @State private var bucketFrames: [Int: CGRect] = [:]

    private var items: [CategorizedItem] { session.module.items ?? [] }
    private var buckets: [String] { session.module.buckets ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                ModulePrompt(title: session.module.title, prompt: session.module.prompt ?? "Sort these into the right group")
                    .appear(appeared)

                ZStack {
                    let remaining = pool.filter { placed[$0.id] == nil }
                    if remaining.isEmpty && !session.isResolved {
                        Label("All sorted — hit Check!", systemImage: "checkmark.circle.fill")
                            .font(.body(15, weight: .bold))
                            .foregroundStyle(Palette.success)
                            .transition(.scale.combined(with: .opacity))
                    }
                    ModuleFlowLayout(spacing: 8, lineSpacing: 10, alignment: .center) {
                        ForEach(remaining) { item in
                            let lifted = selected == item.id || dragItem == item.id
                            itemChip(item, state: lifted ? .selected : .idle)
                                .matchedGeometryEffect(id: item.id, in: ns)
                                .scaleEffect(lifted ? 1.08 : 1)
                                .rotationEffect(.degrees(lifted ? -3 : 0))
                                .shadow(color: Palette.periwinkleDeep.opacity(dragItem == item.id ? 0.3 : 0), radius: 12, y: 8)
                                .offset(dragItem == item.id ? dragTranslation : .zero)
                                .zIndex(dragItem == item.id ? 10 : 0)
                                .onTapGesture { select(item) }
                                .accessibilityElement(children: .combine)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("cat-item")
                                .gesture(dragGesture(for: item))
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .zIndex(dragItem != nil ? 10 : 0)
                .appear(appeared, delay: 0.05)

                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(buckets.enumerated()), id: \.offset) { b, title in
                        bucket(b, title: title)
                            .appear(appeared, delay: 0.1 + Double(b) * 0.05)
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
            Spacer(minLength: 0)
        }
        .coordinateSpace(.named("categorize"))
        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: placed)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
        .onAppear {
            if pool.isEmpty { pool = items.shuffled() }
            appeared = true
            session.onCheck = check
            session.mood = .curious
        }
    }

    private func itemChip(_ item: CategorizedItem, state: AnswerTileState, compact: Bool = false) -> some View {
        Text(item.text)
            .font(.body(compact ? 14 : 16, weight: .semibold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 8 : 11)
            .answerTile(state, radius: compact ? 12 : 16, lip: compact ? 3 : 4)
    }

    private func bucket(_ b: Int, title: String) -> some View {
        let fill = ModulePastels.fill(b + 1)
        let deep = ModulePastels.deep(b + 1)
        let inside = pool.filter { placed[$0.id] == b }
        let isTarget = targeted == b || (selected != nil && !session.isResolved)
        return VStack(spacing: 10) {
            Text(title)
                .font(.display(16, weight: .heavy))
                .foregroundStyle(deep)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            VStack(spacing: 8) {
                ForEach(inside) { item in
                    itemChip(item, state: chipState(item), compact: true)
                        .matchedGeometryEffect(id: item.id, in: ns)
                        .onTapGesture { unplace(item) }
                }
            }
            Spacer(minLength: 0)
            if inside.isEmpty {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(deep.opacity(0.45))
                    .padding(.bottom, 8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 230, alignment: .top)
        .background(fill.opacity(targeted == b ? 1 : 0.7), in: .rect(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .strokeBorder(deep.opacity(isTarget ? 0.8 : 0), style: StrokeStyle(lineWidth: 2.5, dash: [7, 5])))
        .scaleEffect(targeted == b ? 1.04 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: targeted)
        .contentShape(.rect)
        .onTapGesture { drop(into: b) }
        .accessibilityIdentifier("cat-bucket-\(b)")
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("categorize")) } action: { bucketFrames[b] = $0 }
    }

    private func dragGesture(for item: CategorizedItem) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("categorize"))
            .onChanged { v in
                guard !session.isResolved else { return }
                if dragItem == nil {
                    dragItem = item.id
                    selected = nil
                    Haptics.shared.softTap()
                }
                dragTranslation = v.translation
                let over = bucketFrames.first { $0.value.contains(v.location) }?.key
                if over != targeted {
                    targeted = over
                    if over != nil { Haptics.shared.tick() }
                }
            }
            .onEnded { v in
                let over = bucketFrames.first { $0.value.contains(v.location) }?.key
                if let over {
                    selected = item.id
                    var t = Transaction(); t.disablesAnimations = true
                    withTransaction(t) { dragTranslation = .zero }
                    drop(into: over)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { dragTranslation = .zero }
                }
                dragItem = nil
                targeted = nil
            }
    }

    private func chipState(_ item: CategorizedItem) -> AnswerTileState {
        guard session.isResolved else { return .idle }
        return placed[item.id] == item.bucket ? .correct : .wrong
    }

    private func select(_ item: CategorizedItem) {
        guard !session.isResolved else { return }
        Haptics.shared.tick()
        selected = selected == item.id ? nil : item.id
    }

    private func drop(into b: Int) {
        guard !session.isResolved, let id = selected else { return }
        Haptics.shared.softTap()
        SoundFX.shared.play(.pop)
        placed[id] = b
        selected = nil
        targeted = nil
        session.canCheck = placed.count == items.count
        if session.canCheck { session.mood = .attentive }
    }

    private func unplace(_ item: CategorizedItem) {
        guard !session.isResolved else { return }
        Haptics.shared.softTap()
        placed[item.id] = nil
        session.canCheck = false
    }

    private func check() {
        let wrong = items.filter { placed[$0.id] != $0.bucket }
        let allowed = items.count >= 6 ? 1 : 0
        let correct = wrong.count <= allowed
        let answer = wrong.map { item in
            "\(item.text) → \(buckets.indices.contains(item.bucket) ? buckets[item.bucket] : "?")"
        }.joined(separator: "\n")
        session.resolve(correct: correct, correctAnswer: wrong.isEmpty ? nil : answer)
    }
}
