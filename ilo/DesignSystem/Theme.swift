import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

/// ilo palette — periwinkle interface, ink pills, pastel cards, vivid blue reserved for victories.
enum Palette {
    // Surfaces
    static let canvas = Color(hex: 0xF3F4F8)
    static let canvasDeep = Color(hex: 0xE9ECF5)
    static let card = Color.white
    static let hairline = Color(hex: 0x0A0A0C, alpha: 0.06)

    // Ink
    static let ink = Color(hex: 0x0A0A0C)
    static let ink2 = Color(hex: 0x2A2C35)
    static let muted = Color(hex: 0x6E7285)
    static let faint = Color(hex: 0xA6AABB)

    // Brand
    static let periwinkle = Color(hex: 0x8FA8F7)
    static let periwinkleDeep = Color(hex: 0x6C87EE)
    static let periwinkleSoft = Color(hex: 0xDCE3FD)
    static let periwinkleMist = Color(hex: 0xEEF2FF)

    // Victory (used only for wins)
    static let victory = Color(hex: 0x1CB0F6)
    static let victoryDeep = Color(hex: 0x1291D1)

    // Pastels
    static let peach = Color(hex: 0xFFD9B8)
    static let orange = Color(hex: 0xF4913F)
    static let pink = Color(hex: 0xF3B7EC)
    static let orchid = Color(hex: 0xE19BF0)
    static let lavender = Color(hex: 0xDCD7FC)
    static let mint = Color(hex: 0xC7F0DC)
    static let green = Color(hex: 0x3ECF8E)
    static let butter = Color(hex: 0xFFEFB0)
    static let sky = Color(hex: 0xCFE8FF)

    // Feedback
    static let success = Color(hex: 0x33C47D)
    static let successSoft = Color(hex: 0xDDF7E9)
    static let danger = Color(hex: 0xF0554B)
    static let dangerSoft = Color(hex: 0xFFE3E0)
    static let flame = Color(hex: 0xFF8A1F)
    static let gold = Color(hex: 0xFFC233)
    static let gem = Color(hex: 0x4F8CFF)
}

/// A course's theme colour, picked by the AI when it builds the path.
enum CourseTint: String, Codable, CaseIterable, Sendable {
    case periwinkle, orange, orchid, mint, butter, sky, peach, lavender

    var base: Color {
        switch self {
        case .periwinkle: Palette.periwinkle
        case .orange: Palette.orange
        case .orchid: Palette.orchid
        case .mint: Color(hex: 0x5BD6A0)
        case .butter: Color(hex: 0xF5C84C)
        case .sky: Color(hex: 0x62B6FF)
        case .peach: Color(hex: 0xFF9F7A)
        case .lavender: Color(hex: 0xA99CF7)
        }
    }

    var soft: Color {
        switch self {
        case .periwinkle: Palette.periwinkleSoft
        case .orange: Palette.peach
        case .orchid: Palette.pink
        case .mint: Palette.mint
        case .butter: Palette.butter
        case .sky: Palette.sky
        case .peach: Color(hex: 0xFFE0D3)
        case .lavender: Palette.lavender
        }
    }

    var deep: Color {
        switch self {
        case .periwinkle: Palette.periwinkleDeep
        case .orange: Color(hex: 0xD9731F)
        case .orchid: Color(hex: 0xB85FCB)
        case .mint: Color(hex: 0x2FAE78)
        case .butter: Color(hex: 0xC99A17)
        case .sky: Color(hex: 0x2F8FE0)
        case .peach: Color(hex: 0xE0724A)
        case .lavender: Color(hex: 0x7B6BE0)
        }
    }

    var bloubColor: BloubColor {
        switch self {
        case .periwinkle, .sky: .blue
        case .orange, .peach: .orange
        case .orchid: .pink
        case .mint: .green
        case .butter: .amber
        case .lavender: .violet
        }
    }
}

extension Font {
    /// Display type — rounded, heavy, tight. Used for titles and big numbers.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Body type.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

enum Metrics {
    static let gutter: CGFloat = 20
    static let cardRadius: CGFloat = 28
    static let bigRadius: CGFloat = 40
    static let pillHeight: CGFloat = 58
}

/// Signature ilo background: soft off-white with drifting periwinkle light and faint diagonal lines (like the refs).
struct IloBackground: View {
    var tint: Color = Palette.periwinkle
    var lines: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Palette.canvas
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.5], [Float(0.5 + 0.12 * sin(t / 6)), Float(0.45 + 0.1 * cos(t / 7))], [1, 0.5],
                        [0, 1], [0.5, 1], [1, 1]
                    ],
                    colors: [
                        Palette.canvas, tint.opacity(0.22), Palette.canvas,
                        Palette.lavender.opacity(0.35), Palette.canvas, tint.opacity(0.18),
                        Palette.canvas, Palette.periwinkleMist, Palette.canvas
                    ]
                )
                if lines {
                    Canvas { gc, size in
                        var path = Path()
                        let slopes: [(CGFloat, CGFloat)] = [(-0.2, 0.9), (0.35, 1.3), (0.7, -0.1), (1.1, 0.55)]
                        for (a, b) in slopes {
                            path.move(to: CGPoint(x: size.width * a, y: 0))
                            path.addLine(to: CGPoint(x: size.width * b, y: size.height))
                        }
                        gc.stroke(path, with: .color(tint.opacity(0.18)), lineWidth: 1.2)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
