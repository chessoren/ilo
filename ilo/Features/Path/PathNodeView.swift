import SwiftUI

/// Visual state of one node on the path.
struct NodeLook: Equatable {
    var state: NodeState
    var tint: CourseTint
    var kind: NodeKind
    var stars: Int

    var isBoss: Bool { kind == .boss }
    var diameter: CGFloat { isBoss ? 96 : 78 }
    var lipDepth: CGFloat { isBoss ? 10 : 8 }

    var top: Color {
        switch state {
        case .locked: Color(hex: 0xE3E6EF)
        case .current: tint.base
        case .completed: stars >= 2 || kind == .chest ? Palette.gold : tint.base
        }
    }

    var lip: Color {
        switch state {
        case .locked: Color(hex: 0xC9CEDB)
        case .current: tint.deep
        case .completed: stars >= 2 || kind == .chest ? Color(hex: 0xD99A0B) : tint.deep
        }
    }

    var icon: Color { state == .locked ? Color(hex: 0xAEB3C3) : .white }
}

/// Duolingo-style solid 3D node with a pressable lip.
struct NodeButtonStyle: ButtonStyle {
    var look: NodeLook

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let d = look.diameter
        let h = d * 0.9
        ZStack {
            Ellipse().fill(look.lip)
                .frame(width: d, height: h)
                .offset(y: look.lipDepth)
            Ellipse().fill(look.top)
                .frame(width: d, height: h)
                .overlay {
                    // Glossy highlight.
                    Ellipse()
                        .fill(.white.opacity(look.state == .locked ? 0.35 : 0.28))
                        .frame(width: d * 0.42, height: h * 0.18)
                        .offset(x: -d * 0.14, y: -h * 0.28)
                        .rotationEffect(.degrees(-12))
                }
                .overlay { configuration.label }
                .offset(y: pressed ? look.lipDepth : 0)
        }
        .frame(width: d, height: h + look.lipDepth)
        .animation(.spring(response: 0.16, dampingFraction: 0.65), value: pressed)
        .onChange(of: pressed) { _, down in
            if down { Haptics.shared.press(); SoundFX.shared.play(.pop) }
        }
    }
}

/// A single node: circle + badges (stars, ready sparkle, AI thinking), current-state pulse and tooltip.
struct PathNodeView: View {
    let node: PathNode
    let look: NodeLook
    var isReady: Bool
    var isThinking: Bool
    var selected: Bool
    var action: () -> Void

    var body: some View {
        ZStack {
            if look.state == .current {
                PulseRing(color: look.tint.base, diameter: look.diameter)
            }
            Button(action: action) {
                Image(systemName: iconName)
                    .font(.system(size: look.isBoss ? 36 : 28, weight: .heavy))
                    .foregroundStyle(look.icon)
                    .shadow(color: look.lip.opacity(0.5), radius: 0, y: 2)
                    .symbolEffect(.bounce, value: selected)
            }
            .buttonStyle(NodeButtonStyle(look: look))
            .overlay(alignment: .top) {
                if look.isBoss {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(look.state == .locked ? Color(hex: 0xC9CEDB) : Palette.gold)
                        .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
                        .offset(y: -26)
                        .rotationEffect(.degrees(-8))
                }
            }
            .overlay(alignment: .topTrailing) { badge }
            .overlay(alignment: .bottom) {
                if look.state == .completed && look.kind != .chest { stars.offset(y: 16) }
            }
        }
        .accessibilityLabel("\(node.title), \(look.kind.label)")
    }

    private var iconName: String {
        if look.kind == .chest { return look.state == .completed ? "checkmark" : "gift.fill" }
        if look.state == .locked { return look.kind == .boss ? "crown.fill" : "lock.fill" }
        if look.kind == .lesson || look.kind == .story {
            return UIImage(systemName: node.symbol) != nil ? node.symbol : look.kind.defaultSymbol
        }
        return look.kind.defaultSymbol
    }

    @ViewBuilder private var badge: some View {
        if isThinking {
            BloubView(shape: .circle, color: .ink, mode: .thinking)
                .frame(width: 26, height: 26)
                .padding(4)
                .background(.white, in: .circle)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .offset(x: 8, y: -6)
                .transition(.scale.combined(with: .opacity))
        } else if isReady && look.state != .completed && look.kind != .chest {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(look.tint.deep)
                .frame(width: 24, height: 24)
                .background(.white, in: .circle)
                .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                .symbolEffect(.breathe)
                .offset(x: 6, y: -4)
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var stars: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: i == 1 ? 14 : 11, weight: .black))
                    .foregroundStyle(i < starCount ? Palette.gold : Color(hex: 0xDADDE7))
                    .offset(y: i == 1 ? 2 : 0)
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
    }

    private var starCount: Int { look.stars >= 2 ? 3 : 2 }
}

/// Soft pulsing ring behind the current node.
struct PulseRing: View {
    var color: Color
    var diameter: CGFloat

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(Color(hex: 0xE3E6EF), lineWidth: 7)
                .frame(width: diameter + 22, height: diameter * 0.9 + 22)
                .offset(y: 4)
            Ellipse()
                .stroke(color.opacity(0.9), lineWidth: 7)
                .frame(width: diameter + 22, height: diameter * 0.9 + 22)
                .offset(y: 4)
                .mask {
                    Ellipse().trim(from: 0, to: 0.999).stroke(lineWidth: 10)
                        .frame(width: diameter + 22, height: diameter * 0.9 + 22).offset(y: 4)
                }
                .phaseAnimator([false, true]) { view, on in
                    view.scaleEffect(on ? 1.08 : 1).opacity(on ? 0.35 : 1)
                } animation: { _ in .easeInOut(duration: 1.1) }
        }
        .allowsHitTesting(false)
    }
}

/// Bouncing "START" tooltip above the current node.
struct StartTooltip: View {
    var tint: CourseTint
    var text = "START"

    var body: some View {
        VStack(spacing: -1) {
            Text(text)
                .font(.display(15, weight: .heavy))
                .kerning(0.8)
                .foregroundStyle(tint.deep)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(.white, in: .rect(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(hex: 0xE3E6EF), lineWidth: 2))
            Triangle()
                .fill(.white)
                .frame(width: 16, height: 9)
                .overlay(Triangle().stroke(Color(hex: 0xE3E6EF), lineWidth: 2).mask(Rectangle().offset(y: 2)))
        }
        .phaseAnimator([0.0, -7.0]) { v, y in v.offset(y: y) } animation: { _ in .easeInOut(duration: 0.75) }
        .allowsHitTesting(false)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
