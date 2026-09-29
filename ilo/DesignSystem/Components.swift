import SwiftUI

// MARK: - Buttons

enum PillKind {
    case ink, periwinkle, victory, success, danger, white, glass

    var fill: Color {
        switch self {
        case .ink: Palette.ink
        case .periwinkle: Palette.periwinkleDeep
        case .victory: Palette.victory
        case .success: Palette.success
        case .danger: Palette.danger
        case .white: .white
        case .glass: .clear
        }
    }

    var lip: Color {
        switch self {
        case .ink: Color(hex: 0x000000)
        case .periwinkle: Color(hex: 0x4F68CC)
        case .victory: Palette.victoryDeep
        case .success: Color(hex: 0x23995F)
        case .danger: Color(hex: 0xC43A31)
        case .white: Color(hex: 0xD8DCE8)
        case .glass: .clear
        }
    }

    var foreground: Color {
        switch self {
        case .white, .glass: Palette.ink
        default: .white
        }
    }
}

/// The signature ilo button: a pill with a Duolingo-style pressable lip, haptic and click sound.
struct PillButtonStyle: ButtonStyle {
    var kind: PillKind = .ink
    var height: CGFloat = Metrics.pillHeight
    var fullWidth = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let lipDepth: CGFloat = kind == .glass ? 0 : 5
        configuration.label
            .font(.display(18, weight: .bold))
            .foregroundStyle(isEnabled ? kind.foreground : Palette.faint)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, fullWidth ? 0 : 26)
            .background {
                if kind == .glass {
                    Capsule().fill(.clear).glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    Capsule().fill(isEnabled ? kind.fill : Palette.canvasDeep)
                }
            }
            .background {
                Capsule()
                    .fill(isEnabled ? kind.lip : Color(hex: 0xD5D8E3))
                    .offset(y: pressed ? 0 : lipDepth)
            }
            .offset(y: pressed ? lipDepth : 0)
            .padding(.bottom, lipDepth)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
            .onChange(of: pressed) { _, isDown in
                if isDown { Haptics.shared.press(); SoundFX.shared.play(.tap) }
            }
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static func pill(_ kind: PillKind = .ink, height: CGFloat = Metrics.pillHeight, fullWidth: Bool = true) -> PillButtonStyle {
        PillButtonStyle(kind: kind, height: height, fullWidth: fullWidth)
    }
}

/// Springy press feedback for any tappable card.
struct SquishButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var haptic = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isDown in
                if isDown && haptic { Haptics.shared.tap() }
            }
    }
}

extension ButtonStyle where Self == SquishButtonStyle {
    static var squish: SquishButtonStyle { SquishButtonStyle() }
    static func squish(_ scale: CGFloat) -> SquishButtonStyle { SquishButtonStyle(scale: scale) }
}

/// Round Liquid Glass icon button (back, share, settings…).
struct GlassIconButton: View {
    var systemImage: String
    var size: CGFloat = 48
    var tint: Color? = nil
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.tap()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: size, height: size)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(tint.map { .regular.tint($0).interactive() } ?? .regular.interactive(), in: .circle)
    }
}

// MARK: - Surfaces

struct CardModifier: ViewModifier {
    var fill: Color = Palette.card
    var radius: CGFloat = Metrics.cardRadius
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(fill, in: .rect(cornerRadius: radius, style: .continuous))
            .shadow(color: Color(hex: 0x3A4470, alpha: 0.06), radius: 18, y: 8)
    }
}

extension View {
    func card(_ fill: Color = Palette.card, radius: CGFloat = Metrics.cardRadius, padding: CGFloat = 18) -> some View {
        modifier(CardModifier(fill: fill, radius: radius, padding: padding))
    }

    /// Liquid Glass panel with the ilo corner radius.
    func glassCard(radius: CGFloat = Metrics.cardRadius, tint: Color? = nil, padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .glassEffect(tint.map { .regular.tint($0.opacity(0.35)) } ?? .regular, in: .rect(cornerRadius: radius, style: .continuous))
    }

    /// Staggered entrance: fades + rises in after `delay`.
    func appear(_ visible: Bool, delay: Double = 0, y: CGFloat = 18) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : y)
            .blur(radius: visible ? 0 : 6)
            .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(delay), value: visible)
    }
}

/// Small rounded chip (e.g. "2 lessons for today").
struct Chip: View {
    var text: String
    var systemImage: String? = nil
    var fill: Color = Palette.peach
    var foreground: Color = Palette.ink

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 12, weight: .bold)) }
            Text(text).font(.body(13, weight: .semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(fill, in: .capsule)
    }
}

/// Stat pill for the top bar (streak, gems, XP).
struct StatPill: View {
    var systemImage: String
    var value: Int
    var tint: Color
    var active = true

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(active ? tint : Palette.faint)
                .symbolEffect(.bounce, value: value)
            Text("\(value)")
                .font(.display(16, weight: .bold))
                .foregroundStyle(active ? Palette.ink : Palette.faint)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.spring, value: value)
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

// MARK: - Progress

/// Radial ticked ring like the "42%" reference screen.
struct TickRing: View {
    var progress: Double
    var tint: Color = Palette.periwinkle
    var ticks = 90

    var body: some View {
        Canvas { gc, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2
            for i in 0..<ticks {
                let f = Double(i) / Double(ticks)
                let angle = f * .pi * 2 - .pi / 2
                let filled = f <= progress
                let wobble = filled ? 0.13 + 0.07 * sin(Double(i) * 1.7) : 0.08
                let r1 = outer * (1 - wobble - 0.02)
                var p = Path()
                p.move(to: CGPoint(x: c.x + cos(angle) * r1, y: c.y + sin(angle) * r1))
                p.addLine(to: CGPoint(x: c.x + cos(angle) * outer * 0.98, y: c.y + sin(angle) * outer * 0.98))
                gc.stroke(p, with: .color(filled ? tint : tint.opacity(0.16)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
        }
        .animation(.smooth(duration: 1.2), value: progress)
    }
}

/// Lesson progress bar with a glossy highlight and springy fill.
struct GlossyProgressBar: View {
    var progress: Double
    var tint: Color = Palette.victory
    var height: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.canvasDeep)
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, geo.size.width * min(max(progress, 0), 1)))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.35)).frame(height: height * 0.28).padding(.horizontal, height * 0.45).padding(.top, height * 0.2)
                    }
                    .opacity(progress <= 0 ? 0 : 1)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
    }
}

// MARK: - Celebration

/// Canvas confetti burst. Change `trigger` to fire.
struct ConfettiView: View {
    var trigger: Int
    var colors: [Color] = [Palette.periwinkle, Palette.orange, Palette.orchid, Palette.victory, Palette.gold, Palette.green]

    private struct Particle {
        var x: Double, y: Double, vx: Double, vy: Double, spin: Double, size: Double, color: Int, shape: Int
    }

    @State private var particles: [Particle] = []
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(paused: particles.isEmpty)) { timeline in
            Canvas { gc, size in
                let t = timeline.date.timeIntervalSince(start)
                for p in particles {
                    let x = p.x * size.width + p.vx * t * 60
                    let y = p.y * size.height + p.vy * t * 60 + 0.5 * 900 * t * t
                    guard y < size.height + 40 else { continue }
                    let fade = max(0, 1 - t / 3.2)
                    var ctx = gc
                    ctx.opacity = fade
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(p.spin * t))
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / (p.shape == 0 ? 2 : 1))
                    let path = p.shape == 2 ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 2)
                    ctx.fill(path, with: .color(colors[p.color % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { fire() }
    }

    private func fire() {
        start = Date()
        particles = (0..<140).map { _ in
            let fromLeft = Bool.random()
            return Particle(x: fromLeft ? 0.05 : 0.95, y: 0.55,
                            vx: (fromLeft ? 1 : -1) * Double.random(in: 2...9),
                            vy: -Double.random(in: 9...20),
                            spin: Double.random(in: -8...8),
                            size: Double.random(in: 7...13),
                            color: Int.random(in: 0..<colors.count),
                            shape: Int.random(in: 0..<3))
        }
        Task {
            try? await Task.sleep(for: .seconds(3.4))
            particles = []
        }
    }
}

/// Animated count-up number.
struct CountUpText: View {
    var value: Int
    var font: Font = .display(44, weight: .heavy)
    var prefix = ""
    var suffix = ""
    @State private var shown = 0

    var body: some View {
        Text("\(prefix)\(shown)\(suffix)")
            .font(font)
            .contentTransition(.numericText(value: Double(shown)))
            .task(id: value) {
                let steps = min(max(value - shown, 1), 30)
                let from = shown
                for i in 1...steps {
                    try? await Task.sleep(for: .milliseconds(28))
                    withAnimation(.snappy) { shown = from + (value - from) * i / steps }
                    if i % 3 == 0 { SoundFX.shared.play(.tick) }
                }
            }
    }
}

/// Section header "Popular courses" + optional trailing action.
struct SectionHeader: View {
    var title: String
    var action: (label: String, perform: () -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).font(.display(20, weight: .bold)).foregroundStyle(Palette.ink)
            Spacer()
            if let action {
                Button(action.label) { Haptics.shared.tap(); action.perform() }
                    .font(.body(14, weight: .semibold))
                    .foregroundStyle(Palette.periwinkleDeep)
            }
        }
    }
}
