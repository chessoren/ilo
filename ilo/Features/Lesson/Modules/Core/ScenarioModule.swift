import SwiftUI

/// "What would you do?" — a situation card, choice cards, then the consequence of your pick before grading.
struct ScenarioModule: View {
    let session: ModuleSession

    @State private var selected: Int?
    @State private var revealed = false
    @State private var appeared = false

    private var module: LessonModule { session.module }
    private var options: [String] { module.options ?? [] }
    private var correctIndex: Int { module.correctIndex ?? 0 }
    private let icons = ["1.circle.fill", "2.circle.fill", "3.circle.fill", "4.circle.fill", "5.circle.fill"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "signpost.right.and.left.fill")
                            Text((module.title ?? "What would you do?").uppercased())
                                .tracking(1)
                        }
                        .font(.body(12, weight: .heavy))
                        .foregroundStyle(session.tint.deep)
                        Text(module.prompt ?? "")
                            .font(.display(22, weight: .bold))
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: [session.tint.soft, session.tint.soft.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: .rect(cornerRadius: 28, style: .continuous)
                    )
                    .appear(appeared)

                    ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                select(i)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: icons[min(i, icons.count - 1)])
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(tileState(i) == .idle ? Palette.faint : tileState(i).stroke)
                                        .contentTransition(.symbolEffect(.replace))
                                    Text(option)
                                        .font(.body(17, weight: .semibold))
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                .padding(16)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.answerTile(tileState(i), radius: 22))
                            .accessibilityIdentifier("answer-\(i)")
                            .disabled(revealed)

                            if revealed && selected == i, let consequence = consequence(for: i) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "arrow.turn.down.right")
                                        .font(.system(size: 15, weight: .bold))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("What happens")
                                            .font(.body(12, weight: .heavy))
                                            .textCase(.uppercase)
                                            .tracking(0.8)
                                        Text(consequence)
                                            .font(.body(16, weight: .medium))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .foregroundStyle(Palette.ink2)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Palette.butter.opacity(0.8), in: .rect(cornerRadius: 20, style: .continuous))
                                .padding(.top, 8)
                                .padding(.leading, 18)
                                .transition(.asymmetric(insertion: .scale(scale: 0.9, anchor: .top).combined(with: .opacity), removal: .opacity))
                                .id("consequence")
                            }
                        }
                        .appear(appeared, delay: 0.08 + Double(i) * 0.06)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.vertical, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: revealed) { _, r in
                if r { withAnimation(.smooth) { proxy.scrollTo("consequence", anchor: .center) } }
            }
            .onChange(of: session.isResolved) { _, resolved in
                guard resolved else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    withAnimation(.smooth(duration: 0.5)) { proxy.scrollTo("consequence", anchor: .bottom) }
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: revealed)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
        .onAppear {
            appeared = true
            session.onCheck = check
        }
    }

    private func consequence(for i: Int) -> String? {
        guard let c = module.consequences, c.indices.contains(i) else { return nil }
        return c[i]
    }

    private func select(_ i: Int) {
        guard !revealed else { return }
        Haptics.shared.tick()
        selected = i
        session.canCheck = true
        session.mood = .curious
    }

    private func check() {
        guard let selected else { return }
        session.canCheck = false
        session.checkTitle = "…"
        let correct = selected == correctIndex
        guard consequence(for: selected) != nil else {
            session.resolve(correct: correct, correctAnswer: (options.indices.contains(correctIndex) ? options[correctIndex] : nil))
            return
        }
        revealed = true
        SoundFX.shared.play(.bubble)
        Haptics.shared.softTap()
        session.mood = correct ? .happy : .surprised
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            var feedback = module.explanation
            if !correct, let good = consequence(for: correctIndex) {
                feedback = [module.explanation, "Better choice: \(good)"].compactMap { $0 }.joined(separator: "\n\n")
            }
            session.resolve(correct: correct, feedback: feedback, correctAnswer: (options.indices.contains(correctIndex) ? options[correctIndex] : nil))
        }
    }

    private func tileState(_ i: Int) -> AnswerTileState {
        if session.isResolved {
            if i == correctIndex { return selected == i ? .correct : .missed }
            return i == selected ? .wrong : .dimmed
        }
        if revealed { return i == selected ? .selected : .dimmed }
        return selected == i ? .selected : .idle
    }
}
