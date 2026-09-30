import SwiftUI

/// Guess a number with a big slider. Correct within 15% of the range; the true value drops in on reveal.
struct EstimateModule: View {
    let session: ModuleSession

    @State private var value: Double = 0
    @State private var touched = false
    @State private var dragging = false
    @State private var appeared = false
    @State private var lastTick = 0

    private var module: LessonModule { session.module }
    private var minV: Double { module.minValue ?? 0 }
    private var maxV: Double { max(module.maxValue ?? 100, minV + 1) }
    private var answer: Double { min(max(module.answerValue ?? (minV + maxV) / 2, minV), maxV) }
    private var range: Double { maxV - minV }
    private var tolerance: Double { range * 0.15 }
    private var step: Double {
        let raw = pow(10, floor(log10(range)) - 2)
        return raw >= 1 ? raw : raw * 10 >= 1 ? 1 : raw * 10
    }
    private var unit: String { module.unit ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ModulePrompt(title: module.title ?? "Guess it", prompt: module.prompt)
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 16)
                .appear(appeared)

            Spacer(minLength: 16)

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(ModuleNumberFormat.format(value, step: step))
                        .font(.display(76, weight: .black))
                        .foregroundStyle(numberColor)
                        .contentTransition(.numericText(value: value))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.display(28, weight: .bold))
                            .foregroundStyle(Palette.muted)
                    }
                }
                .scaleEffect(dragging ? 1.06 : 1)
                Text(session.isResolved ? "Actual answer: \(ModuleNumberFormat.format(answer, step: step))\(unit.isEmpty ? "" : " \(unit)")" : (touched ? "Your guess" : "Drag to guess"))
                    .font(.body(15, weight: .bold))
                    .foregroundStyle(session.isResolved ? Palette.ink : Palette.muted)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .appear(appeared, delay: 0.06)

            Spacer(minLength: 16)

            slider
                .padding(.horizontal, Metrics.gutter + 6)
                .appear(appeared, delay: 0.12)

            HStack {
                Text(ModuleNumberFormat.format(minV, step: step))
                Spacer()
                Text(ModuleNumberFormat.format(maxV, step: step))
            }
            .font(.display(15, weight: .bold))
            .foregroundStyle(Palette.muted)
            .padding(.horizontal, Metrics.gutter + 6)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragging)
        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: session.phase)
        .onAppear {
            if !touched { value = snap(minV + range / 2) }
            appeared = true
            session.onCheck = check
            session.mood = .curious
        }
    }

    private var numberColor: Color {
        switch session.phase {
        case .answering: touched ? Palette.ink : Palette.faint
        case .correct: Palette.success
        case .wrong: Palette.danger
        }
    }

    private var slider: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x = CGFloat((value - minV) / range) * w
            let ax = CGFloat((answer - minV) / range) * w
            let tw = CGFloat(tolerance / range) * w
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Palette.canvasDeep)
                    .frame(height: 22)
                Capsule()
                    .fill(LinearGradient(colors: [session.tint.base, session.tint.deep], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(22, x), height: 22)
                // Ticks
                HStack(spacing: 0) {
                    ForEach(0..<11) { i in
                        Capsule().fill(.white.opacity(0.7)).frame(width: 2, height: i % 5 == 0 ? 12 : 6)
                        if i < 10 { Spacer(minLength: 0) }
                    }
                }
                .padding(.horizontal, 11)
                .allowsHitTesting(false)

                // Reveal: tolerance band + true value marker
                if session.isResolved {
                    Capsule()
                        .fill(Palette.success.opacity(0.25))
                        .overlay(Capsule().strokeBorder(Palette.success, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
                        .frame(width: max(tw * 2, 24), height: 34)
                        .offset(x: max(0, min(ax - tw, w - tw * 2)))
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                    VStack(spacing: 2) {
                        Text("\(ModuleNumberFormat.format(answer, step: step))")
                            .font(.display(14, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Palette.success, in: .capsule)
                            .fixedSize()
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.success)
                        Capsule().fill(Palette.success).frame(width: 4, height: 40)
                    }
                    .offset(x: ax - 20, y: -34)
                    .frame(width: 40)
                    .transition(.offset(y: -80).combined(with: .opacity))
                }

                // Thumb
                Circle()
                    .fill(.white)
                    .overlay(Circle().strokeBorder(session.tint.deep, lineWidth: 5))
                    .overlay(Circle().fill(session.tint.deep).frame(width: 10))
                    .frame(width: dragging ? 50 : 44, height: dragging ? 50 : 44)
                    .shadow(color: session.tint.deep.opacity(0.35), radius: dragging ? 14 : 8, y: 4)
                    .offset(x: x - (dragging ? 25 : 22))
                    .allowsHitTesting(false)
            }
            .frame(height: 60)
            .contentShape(.rect)
            .accessibilityElement()
            .accessibilityIdentifier("estimate-track")
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        guard !session.isResolved else { return }
                        if !dragging { dragging = true; Haptics.shared.softTap() }
                        let f = min(max(g.location.x / w, 0), 1)
                        value = snap(minV + Double(f) * range)
                        touched = true
                        session.canCheck = true
                        let tick = Int(f * 20)
                        if tick != lastTick { lastTick = tick; Haptics.shared.tick() }
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .frame(height: 60)
    }

    private func snap(_ v: Double) -> Double {
        (v / step).rounded() * step
    }

    private func check() {
        let correct = abs(value - answer) <= tolerance
        let diff = abs(value - answer)
        let note = correct
            ? "Within \(withUnit(diff)) of the real answer."
            : "You were \(withUnit(diff)) off."
        session.resolve(correct: correct,
                        feedback: [note, module.explanation].compactMap { $0 }.joined(separator: " "),
                        correctAnswer: withUnit(answer))
    }

    /// "13x", "40%", "12 km" — symbol-like units attach without a space.
    private func withUnit(_ v: Double) -> String {
        let number = ModuleNumberFormat.format(v, step: step)
        if unit.isEmpty { return number }
        return ["x", "×", "%", "°"].contains(unit) ? number + unit : "\(number) \(unit)"
    }
}
