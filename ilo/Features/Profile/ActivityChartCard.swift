import SwiftUI

/// Dark "Your activity" card: last 7 days of XP, today's bar striped with a tooltip pill (ref 2).
struct ActivityChartCard: View {
    @Environment(AppModel.self) private var model
    @State private var grow = false
    @State private var picked: Int?

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let days = (0..<7).reversed().map { cal.date(byAdding: .day, value: -$0, to: today) ?? today }
        let values = days.map { model.player.xp(on: $0) }
        let maxV = max(values.max() ?? 0, model.player.dailyGoalXP, 1)
        let total = values.reduce(0, +)
        let focus = picked ?? 6

        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your activity").font(.display(20, weight: .bold)).foregroundStyle(.white)
                    Text("\(total) XP in the last 7 days")
                        .font(.body(13, weight: .medium)).foregroundStyle(.white.opacity(0.6))
                        .contentTransition(.numericText())
                }
                Spacer()
                Text("Week")
                    .font(.body(12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.white.opacity(0.12), in: .capsule)
            }
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<7, id: \.self) { i in
                    let v = values[i]
                    let h = grow ? max(10, CGFloat(v) / CGFloat(maxV) * 130) : 10
                    VStack(spacing: 8) {
                        ZStack(alignment: .top) {
                            Color.clear.frame(height: 150)
                            VStack(spacing: 6) {
                                Spacer(minLength: 0)
                                if i == focus {
                                    Text("\(v) XP")
                                        .font(.display(12, weight: .heavy))
                                        .foregroundStyle(Palette.ink)
                                        .fixedSize()
                                        .padding(.horizontal, 9).padding(.vertical, 5)
                                        .background(.white, in: .capsule)
                                        .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
                                }
                                bar(highlight: i == focus, active: v > 0)
                                    .frame(height: h)
                            }
                        }
                        Text(days[i].formatted(.dateTime.weekday(.narrow)))
                            .font(.body(12, weight: i == 6 ? .bold : .medium))
                            .foregroundStyle(.white.opacity(i == focus ? 1 : 0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                    .onTapGesture {
                        Haptics.shared.tick()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { picked = i }
                    }
                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(Double(i) * 0.05), value: grow)
                }
            }
        }
        .padding(20)
        .background(Color(hex: 0x15161B), in: .rect(cornerRadius: 32, style: .continuous))
        .onAppear { grow = true }
    }

    @ViewBuilder
    private func bar(highlight: Bool, active: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        if highlight {
            shape.fill(Palette.periwinkle)
                .overlay {
                    StripePattern().stroke(.white.opacity(0.35), lineWidth: 4).clipShape(shape)
                }
        } else {
            shape.fill(active ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
        }
    }
}

/// Diagonal stripes.
struct StripePattern: Shape {
    var spacing: CGFloat = 9

    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x = -rect.height
        while x < rect.width + rect.height {
            p.move(to: CGPoint(x: x, y: rect.maxY))
            p.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += spacing
        }
        return p
    }
}
