import SwiftUI
import UserNotifications

// MARK: - Layout

/// Wrapping row layout for chips.
struct OBFlowLayout: Layout {
    var spacing: CGFloat = 10
    var lineSpacing: CGFloat = 10
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, width: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * lineSpacing
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, width: bounds.width) {
            var x = alignment == .center ? bounds.minX + (bounds.width - row.width) / 2 : bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += isFirst ? size.width : size.width + spacing
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}

// MARK: - Choice rows

/// Tall tappable option card with an icon tile — solid, tactile, with a pressable lip when selected.
struct OBChoiceCard<Accessory: View>: View {
    var title: String
    var detail: String? = nil
    var symbol: String
    var tint: CourseTint = .periwinkle
    var variable: Double? = nil
    var selected: Bool
    var action: () -> Void
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol, variableValue: variable)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(selected ? .white : tint.deep)
                    .frame(width: 46, height: 46)
                    .background(selected ? tint.deep : tint.soft, in: .rect(cornerRadius: 15, style: .continuous))
                    .symbolEffect(.bounce, value: selected)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.display(17, weight: .bold)).foregroundStyle(Palette.ink)
                    if let detail {
                        Text(detail).font(.body(13.5)).foregroundStyle(Palette.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                accessory()
                ZStack {
                    Circle().strokeBorder(selected ? Palette.ink : Palette.hairline, lineWidth: 2)
                    if selected {
                        Circle().fill(Palette.ink).padding(5)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white, in: .rect(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(selected ? Palette.ink : .clear, lineWidth: 2)
            }
            .shadow(color: Color(hex: 0x3A4470, alpha: selected ? 0.12 : 0.05), radius: selected ? 16 : 10, y: selected ? 8 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        }
        .buttonStyle(.squish(0.97))
        .accessibilityIdentifier("choice")
    }
}

extension OBChoiceCard where Accessory == EmptyView {
    init(title: String, detail: String? = nil, symbol: String, tint: CourseTint = .periwinkle, variable: Double? = nil,
         selected: Bool, action: @escaping () -> Void) {
        self.init(title: title, detail: detail, symbol: symbol, tint: tint, variable: variable, selected: selected, action: action) { EmptyView() }
    }
}

/// Pill chip that can be selected.
struct OBChip: View {
    var title: String
    var symbol: String? = nil
    var selected = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol).font(.system(size: 13, weight: .bold)) }
                Text(title).font(.body(15, weight: .semibold)).lineLimit(1)
            }
            .foregroundStyle(selected ? .white : Palette.ink)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(selected ? Palette.ink : .white, in: .capsule)
            .overlay { Capsule().strokeBorder(Palette.hairline, lineWidth: selected ? 0 : 1) }
            .shadow(color: Color(hex: 0x3A4470, alpha: 0.05), radius: 6, y: 3)
        }
        .buttonStyle(.squish(0.94))
    }
}

// MARK: - ilo speaking

/// ilo's line in a speech bubble, typed out character by character.
struct OBSpeechBubble: View {
    var text: String
    @State private var shown = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Reserve the final size so the bubble doesn't jump while typing.
            Text(text).hidden()
            Text(displayed)
        }
            .font(.body(15.5, weight: .medium))
            .foregroundStyle(Palette.ink2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.white, in: BubbleShape())
            .shadow(color: Color(hex: 0x3A4470, alpha: 0.07), radius: 10, y: 4)
            .task(id: text) {
                shown = 0
                let characters = text.count
                let step = max(1, characters / 40)
                while shown < characters {
                    try? await Task.sleep(for: .milliseconds(16))
                    shown = min(characters, shown + step)
                }
            }
    }

    private var displayed: String {
        let visible = String(text.prefix(shown))
        return visible
    }

    struct BubbleShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path(roundedRect: rect, cornerRadius: 18, style: .continuous)
            path.move(to: CGPoint(x: rect.minX + 1, y: rect.midY - 7))
            path.addLine(to: CGPoint(x: rect.minX - 7, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + 1, y: rect.midY + 7))
            path.closeSubpath()
            return path
        }
    }
}

/// A word set inside a tilted colour block, like the "Welcome to RoboLearn" reference.
struct OBHighlightWord: View {
    var text: String
    var fill: Color = Palette.periwinkle
    var size: CGFloat = 50
    var angle: Double = -2.5
    @State private var revealed = false

    var body: some View {
        Text(text)
            .font(.display(size, weight: .heavy))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 0)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill)
                    .scaleEffect(x: revealed ? 1 : 0.02, y: 1, anchor: .leading)
            }
            .rotationEffect(.degrees(revealed ? angle : 0))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.35)) { revealed = true }
            }
    }
}

/// Bouncing wrapper — squash & stretch whenever `trigger` changes.
struct OBBounce<Content: View>: View {
    var trigger: Int
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .keyframeAnimator(initialValue: CGSize(width: 1, height: 1), trigger: trigger) { view, scale in
                view.scaleEffect(x: scale.width, y: scale.height, anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack(\.width) {
                    SpringKeyframe(1.12, duration: 0.12)
                    SpringKeyframe(0.94, duration: 0.14)
                    SpringKeyframe(1, duration: 0.3)
                }
                KeyframeTrack(\.height) {
                    SpringKeyframe(0.86, duration: 0.12)
                    SpringKeyframe(1.08, duration: 0.14)
                    SpringKeyframe(1, duration: 0.3)
                }
            }
    }
}

extension View {
    /// Soft canvas fade behind a pinned bottom bar so scrolling content never collides with the CTA.
    func obBottomFade() -> some View {
        background {
            LinearGradient(stops: [.init(color: Palette.canvas.opacity(0), location: 0),
                                   .init(color: Palette.canvas, location: 0.2),
                                   .init(color: Palette.canvas, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Reminders

/// Daily streak reminder scheduling (local notifications).
enum OnboardingReminders {
    static let identifier = "ilo.daily.reminder"

    /// Asks for permission; schedules the daily reminder when granted. Returns whether it's allowed.
    @MainActor
    static func requestAndSchedule(hour: Int, name: String, goal: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        schedule(hour: hour, name: name, goal: goal)
        return true
    }

    static func schedule(hour: Int, name: String, goal: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "ilo misses you"
        let topic = goal.isEmpty ? "your path" : goal.lowercased()
        content.body = name.isEmpty
            ? "Your next lesson on \(topic) is ready. Keep the streak alive!"
            : "\(name), your next lesson on \(topic) is ready. Keep the streak alive!"
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
