import SwiftUI

/// Streak / gems / level shown in a single floating Liquid Glass capsule at the top of Home, Path and Quests.
struct StatsCluster: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router
    @State private var showStreak = false
    @State private var gemsFrame: CGRect = .zero

    var body: some View {
        let p = model.player
        HStack(spacing: 14) {
            Button { Haptics.shared.tap(); showStreak = true } label: {
                stat("flame.fill", value: p.streak, tint: p.isStreakActiveToday ? Palette.flame : Palette.faint)
            }
            .popover(isPresented: $showStreak) {
                StreakPopover().presentationCompactAdaptation(.popover)
            }
            Button { Haptics.shared.tap(); router.showShop = true } label: {
                stat("diamond.fill", value: p.gems, tint: Palette.gem)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { gemsFrame = $0; router.gemsTarget = $0 }
            }
            Button { Haptics.shared.tap(); router.tab = .profile } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.gold)
                    Text("Lv \(p.level)")
                        .font(.display(15, weight: .bold))
                        .contentTransition(.numericText(value: Double(p.level)))
                }
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
        .padding(.horizontal, 6)
        .onAppear { if gemsFrame != .zero { router.gemsTarget = gemsFrame } }
        .foregroundStyle(Palette.ink)
    }

    private func stat(_ symbol: String, value: Int, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: value)
            Text("\(value)")
                .font(.display(15, weight: .bold))
                .contentTransition(.numericText(value: Double(value)))
                .animation(.spring, value: value)
        }
    }
}

/// Tap on the flame: this week's streak at a glance.
struct StreakPopover: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let p = model.player
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Palette.flame.gradient)
                    .symbolEffect(.bounce, options: .repeat(2))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(p.streak) day streak").font(.display(20, weight: .heavy))
                    Text(p.isStreakActiveToday ? "You're on fire today." : "Do a lesson to keep it alive.")
                        .font(.body(13)).foregroundStyle(Palette.muted)
                }
            }
            WeekStrip(compact: true)
            HStack(spacing: 6) {
                Image(systemName: "snowflake").foregroundStyle(Palette.victory)
                Text("\(p.streakFreezes) streak freeze\(p.streakFreezes == 1 ? "" : "s") equipped")
                    .font(.body(13, weight: .medium)).foregroundStyle(Palette.ink2)
            }
        }
        .padding(18)
        .frame(width: 300)
    }
}

/// Mon–Sun day selector like ref 3: filled flame circles for active days, outlined today.
struct WeekStrip: View {
    @Environment(AppModel.self) private var model
    var compact = false
    @State private var shown = false

    var body: some View {
        let cal = Calendar.current
        let start = cal.startOfWeek(for: .now)
        let today = cal.startOfDay(for: .now)
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let day = cal.date(byAdding: .day, value: i, to: start) ?? start
                let active = model.player.activeDays.contains(day) || model.player.xp(on: day) > 0
                let isToday = day == today
                let future = day > today
                VStack(spacing: 6) {
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.body(12, weight: .semibold))
                        .foregroundStyle(isToday ? Palette.ink : Palette.muted)
                    ZStack {
                        Circle()
                            .fill(active ? AnyShapeStyle(Palette.flame.gradient) : AnyShapeStyle(future ? Color.clear : Palette.canvasDeep))
                        Circle()
                            .strokeBorder(isToday && !active ? Palette.ink : (future ? Palette.hairline.opacity(3) : .clear),
                                          style: StrokeStyle(lineWidth: isToday ? 2 : 1.2, dash: future ? [3, 3] : []))
                        if active {
                            Image(systemName: "flame.fill")
                                .font(.system(size: compact ? 12 : 15, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text(day.formatted(.dateTime.day()))
                                .font(.display(compact ? 12 : 14, weight: .bold))
                                .foregroundStyle(future ? Palette.faint : Palette.muted)
                        }
                    }
                    .frame(width: compact ? 30 : 38, height: compact ? 30 : 38)
                    .scaleEffect(shown ? 1 : 0.4)
                    .opacity(shown ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.6).delay(Double(i) * 0.05), value: shown)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { shown = true }
    }
}

/// Player's own bloub with a level ring (avatar).
struct PlayerAvatar: View {
    @Environment(AppModel.self) private var model
    var size: CGFloat = 54
    var expression: BloubExpression = .happy
    var showsLevel = true

    var body: some View {
        let p = model.player
        ZStack {
            Circle().stroke(Palette.periwinkle.opacity(0.18), lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: max(0.03, PlayerLevel.progress(for: p.totalXP)))
                .stroke(Palette.periwinkleDeep, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 1), value: p.totalXP)
            BloubView(shape: p.bloubShape, color: p.bloubColor, expression: expression)
                .padding(size * 0.14)
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottomTrailing) {
            if showsLevel {
                Text("\(p.level)")
                    .font(.display(11, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Palette.ink, in: .circle)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: 3, y: 3)
            }
        }
    }
}
