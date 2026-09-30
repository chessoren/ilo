import SwiftUI

/// Tinder-style statements: swipe right = true, left = false. Graded after the last card (≥ 2/3 right).
struct TrueFalseModule: View {
    let session: ModuleSession

    @State private var index = 0
    @State private var answers: [Bool] = []
    @State private var drag: CGSize = .zero
    @State private var flyOut: CGFloat = 0
    @State private var appeared = false

    private var statements: [Statement] { session.module.statements ?? [] }

    var body: some View {
        VStack(spacing: 18) {
            ModulePrompt(title: session.module.title ?? "True or false?", prompt: session.module.prompt ?? "Swipe right if it's true, left if it's false")
                .padding(.horizontal, Metrics.gutter)
                .appear(appeared)

            HStack(spacing: 6) {
                ForEach(statements.indices, id: \.self) { i in
                    Capsule()
                        .fill(dotColor(i))
                        .frame(width: i == index && index < statements.count ? 26 : 10, height: 10)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: answers.count)
            .appear(appeared, delay: 0.05)

            ZStack {
                if index >= statements.count {
                    resultView
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                ForEach(Array(statements.enumerated()).reversed(), id: \.element.id) { i, statement in
                    if i >= index && i <= index + 2 {
                        card(statement, number: i)
                            .scaleEffect(1 - CGFloat(i - index) * 0.05)
                            .offset(y: CGFloat(i - index) * 16)
                            .offset(x: i == index ? drag.width + flyOut : 0, y: i == index ? drag.height * 0.2 : 0)
                            .rotationEffect(.degrees(i == index ? Double(drag.width + flyOut) / 16 : 0), anchor: .bottom)
                            .gesture(swipeGesture, including: i == index ? .all : .subviews)
                            .zIndex(Double(100 - i))
                            .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter + 6)
            .frame(maxHeight: .infinity)
            .appear(appeared, delay: 0.1)

            HStack(spacing: 14) {
                answerButton(false)
                answerButton(true)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 8)
            .opacity(index < statements.count ? 1 : 0)
            .disabled(index >= statements.count)
        }
        .padding(.top, 12)
        .onAppear {
            appeared = true
            session.hidesCheckBar = true
            session.mood = .attentive
        }
    }

    private func dotColor(_ i: Int) -> Color {
        guard i < answers.count else { return i == index ? Palette.ink : Palette.ink.opacity(0.12) }
        return answers[i] == statements[i].isTrue ? Palette.success : Palette.danger
    }

    private func card(_ statement: Statement, number: Int) -> some View {
        let x = number == index ? drag.width + flyOut : 0
        return VStack(spacing: 20) {
            Text("Statement \(number + 1) of \(statements.count)")
                .font(.body(13, weight: .bold))
                .foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
            Text(statement.text)
                .font(.display(27, weight: .bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            HStack {
                Label("False", systemImage: "arrow.left")
                Spacer()
                Label("True", systemImage: "arrow.right").labelStyle(TrailingIconLabel())
            }
            .font(.body(13, weight: .bold))
            .foregroundStyle(Palette.faint)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: 420)
        .background(.white, in: .rect(cornerRadius: 34, style: .continuous))
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill((x > 0 ? Palette.success : Palette.danger).opacity(min(abs(x) / 300, 0.3)))
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder((x > 0 ? Palette.success : Palette.danger).opacity(min(abs(x) / 100, 1)), lineWidth: 4)
                Text(x > 0 ? "TRUE" : "FALSE")
                    .font(.display(36, weight: .black))
                    .foregroundStyle(x > 0 ? Palette.success : Palette.danger)
                    .padding(.horizontal, 14).padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(x > 0 ? Palette.success : Palette.danger, lineWidth: 4))
                    .rotationEffect(.degrees(x > 0 ? -14 : 14))
                    .opacity(min(abs(x) / 80, 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: x > 0 ? .topLeading : .topTrailing)
                    .padding(26)
            }
            .allowsHitTesting(false)
        }
        .compositingGroup()
        .shadow(color: Color(hex: 0x3A4470, alpha: 0.1), radius: 20, y: 10)
    }

    private var resultView: some View {
        let score = zip(answers, statements).filter { $0 == $1.isTrue }.count
        return VStack(spacing: 10) {
            Text("\(score)/\(statements.count)")
                .font(.display(64, weight: .black))
                .foregroundStyle(score * 3 >= statements.count * 2 ? Palette.success : Palette.danger)
            Text("correct")
                .font(.display(20, weight: .bold))
                .foregroundStyle(Palette.muted)
        }
    }

    private func answerButton(_ value: Bool) -> some View {
        Button {
            answer(value)
        } label: {
            Label(value ? "True" : "False", systemImage: value ? "checkmark" : "xmark")
                .font(.display(18, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(.answerTile(value ? .correct : .wrong, radius: 28))
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                if (abs(v.translation.width) > 100) != (abs(drag.width) > 100) { Haptics.shared.tick() }
                drag = v.translation
            }
            .onEnded { v in
                if abs(v.translation.width) > 100 || abs(v.predictedEndTranslation.width) > 300 {
                    answer(v.translation.width > 0)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = .zero }
                }
            }
    }

    private func answer(_ value: Bool) {
        guard index < statements.count, answers.count == index else { return }
        let right = value == statements[index].isTrue
        answers.append(value)
        if right { Haptics.shared.tick(); SoundFX.shared.play(.pop) } else { Haptics.shared.thud(); SoundFX.shared.play(.tap) }
        session.mood = right ? .happy : .confused
        withAnimation(.easeIn(duration: 0.24)) { flyOut = value ? 600 : -600 }
        Task {
            try? await Task.sleep(for: .milliseconds(240))
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { flyOut = 0; drag = .zero }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { index += 1 }
            if index >= statements.count { grade() }
        }
    }

    private func grade() {
        let misses = statements.indices.filter { answers[$0] != statements[$0].isTrue }
        let score = statements.count - misses.count
        let passed = score * 3 >= statements.count * 2
        var feedback = "You got \(score) of \(statements.count) right."
        if !misses.isEmpty {
            let lines = misses.map { i -> String in
                let s = statements[i]
                return "• “\(s.text)” is \(s.isTrue ? "true" : "false")." + (s.why.map { " \($0)" } ?? "")
            }
            feedback += "\n" + lines.joined(separator: "\n")
        } else if let explanation = session.module.explanation {
            feedback += " " + explanation
        }
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            session.resolve(correct: passed, feedback: feedback)
        }
    }
}

private struct TrailingIconLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) { configuration.title; configuration.icon }
    }
}
