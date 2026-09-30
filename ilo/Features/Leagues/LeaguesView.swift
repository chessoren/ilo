import SwiftUI

/// Weekly leagues: tier carousel, countdown, promotion/demotion zones and the leaderboard.
struct LeaguesView: View {
    @Environment(AppModel.self) private var model
    @State private var provider = LeaderboardProvider()
    @State private var board: Board = .league
    @State private var meVisible = true
    @State private var shown = false

    enum Board: String, CaseIterable { case league = "League", friends = "Friends" }

    var body: some View {
        let entries = board == .league ? provider.league : provider.friends
        ScrollView {
            VStack(spacing: 18) {
                TierCarousel(current: model.player.league).appear(shown)
                countdown.appear(shown, delay: 0.08)
                Picker("Board", selection: $board.animation(.snappy)) {
                    ForEach(Board.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Metrics.gutter)
                .appear(shown, delay: 0.12)
                .onChange(of: board) { Haptics.shared.tick() }

                if provider.isLoading {
                    BloubView(shape: .circle, color: .ink, mode: .thinking).frame(width: 90).padding(40)
                } else if board == .friends && entries.count <= 1 {
                    friendsEmpty
                } else {
                    leaderboard(entries)
                }
                inviteCard.appear(shown, delay: 0.2)
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .demoScrollable()
        .background(IloBackground(lines: false))
        .navigationTitle("Leagues")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !meVisible, board == .league, let rank = entries.firstIndex(where: \.isMe) {
                LeaderRow(entry: entries[rank], rank: rank + 1, pinned: true)
                    .padding(.horizontal, Metrics.gutter)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: meVisible)
        .task(id: model.player.weeklyXP) { await provider.refresh(for: model.player) }
        .onAppear { shown = true }
    }

    private var countdown: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let end = Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfWeek(for: ctx.date)) ?? ctx.date
            let left = max(0, Int(end.timeIntervalSince(ctx.date)))
            let d = left / 86_400, h = (left % 86_400) / 3600, m = (left % 3600) / 60, s = left % 60
            HStack(spacing: 8) {
                Image(systemName: "hourglass").symbolEffect(.rotate, options: .repeat(.periodic(delay: 3)))
                Text(d > 0 ? "\(d)d \(h)h \(m)m left" : String(format: "%02d:%02d:%02d left", h, m, s))
                    .contentTransition(.numericText(countsDown: true))
                    .monospacedDigit()
                Text("·").foregroundStyle(Palette.faint)
                Text("\(model.player.weeklyXP) XP this week").foregroundStyle(Palette.periwinkleDeep)
            }
            .font(.body(14, weight: .semibold))
            .foregroundStyle(Palette.ink2)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
        }
    }

    @ViewBuilder
    private func leaderboard(_ entries: [LeaderboardEntry]) -> some View {
        let tier = model.player.league
        let promo = board == .league ? tier.promotionSlots(cohort: entries.count) : 0
        let demo = board == .league ? tier.demotionSlots(cohort: entries.count) : 0
        LazyVStack(spacing: 8) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                if board == .league && i == promo && promo > 0 {
                    ZoneDivider(text: "Promotion zone", symbol: "arrow.up", color: Palette.success)
                }
                if board == .league && demo > 0 && i == entries.count - demo {
                    ZoneDivider(text: "Demotion zone", symbol: "arrow.down", color: Palette.danger)
                }
                LeaderRow(entry: entry, rank: i + 1, pinned: false)
                    .onScrollVisibilityChange(threshold: 0.4) { visible in
                        if entry.isMe { meVisible = visible }
                    }
                    .scrollTransition { v, phase in
                        v.opacity(phase.isIdentity ? 1 : 0.5).scaleEffect(phase.isIdentity ? 1 : 0.96)
                    }
                    .appear(shown, delay: 0.14 + Double(min(i, 12)) * 0.03)
            }
        }
        .padding(.horizontal, Metrics.gutter)
    }

    private var friendsEmpty: some View {
        VStack(spacing: 12) {
            BloubView(shape: .circle, color: .ink, expression: .shy).frame(width: 110)
            Text("Learning is better together").font(.display(20, weight: .bold))
            Text("Invite friends to race them on XP every week.")
                .font(.body(15)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, Metrics.gutter)
    }

    private var inviteCard: some View {
        let name = model.player.name.isEmpty ? "I" : model.player.name
        let text = "\(name) is learning with ilo, the app that turns any goal into a Duolingo-style path. I'm in the \(model.player.league.title) league with a \(model.player.streak)-day streak. Come race me! https://ilo.app"
        return ShareLink(item: text, subject: Text("Learn with me on ilo"), message: Text(text)) {
            HStack(spacing: 14) {
                ZStack {
                    BloubView(shape: .pebble, color: .orange, expression: .happy, alive: false).frame(width: 40).offset(x: -14)
                    BloubView(shape: model.player.bloubShape, color: model.player.bloubColor, expression: .excited, alive: false)
                        .frame(width: 44).offset(x: 14)
                }
                .frame(width: 76)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite friends").font(.display(18, weight: .bold))
                    Text("Race them on XP every week").font(.body(13)).foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 40, height: 40)
                    .background(.white, in: .circle)
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(Palette.ink, in: .rect(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.squish)
        .padding(.horizontal, Metrics.gutter)
    }
}

// MARK: - Tier carousel

private struct TierCarousel: View {
    let current: LeagueTier
    @State private var focus: LeagueTier?

    var body: some View {
        let shownTier = focus ?? current
        VStack(spacing: 6) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(LeagueTier.allCases, id: \.self) { tier in
                        let locked = tier > current
                        let isCurrent = tier == current
                        ZStack {
                            if isCurrent {
                                Circle().fill(tier.color.color.opacity(0.18)).frame(width: 150).blur(radius: 18)
                            }
                            BloubView(shape: tier.shape, color: tier.color,
                                      expression: isCurrent ? .proud : (locked ? .sleepy : .happy),
                                      alive: isCurrent)
                                .frame(width: isCurrent ? 118 : 64, height: isCurrent ? 118 : 64)
                                .saturation(locked ? 0 : 1)
                                .opacity(locked ? 0.35 : 1)
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Palette.muted)
                                    .frame(width: 28, height: 28)
                                    .background(.white, in: .circle)
                                    .offset(x: 24, y: 24)
                            }
                        }
                        .frame(width: 112, height: 150)
                        .scrollTransition(axis: .horizontal) { v, phase in
                            v.scaleEffect(phase.isIdentity ? 1 : 0.88).offset(y: phase.isIdentity ? 0 : 10)
                        }
                        .id(tier)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $focus, anchor: .center)
            .contentMargins(.horizontal, 140, for: .scrollContent)
            .scrollIndicators(.hidden)
            .frame(height: 150)
            .onAppear { focus = current }
            .onChange(of: focus) { Haptics.shared.tick() }

            VStack(spacing: 4) {
                Text("\(shownTier.title) League")
                    .font(.display(28, weight: .heavy))
                    .contentTransition(.interpolate)
                Text(subtitle(for: shownTier))
                    .font(.body(14, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .contentTransition(.interpolate)
            }
            .animation(.snappy, value: shownTier)
        }
    }

    private func subtitle(for tier: LeagueTier) -> String {
        if tier > current { return "Locked · climb to unlock" }
        if tier < current { return "Conquered" }
        if let next = tier.next { return "Top 20% advance to \(next.title)" }
        return "The very top. Defend your place!"
    }
}

// MARK: - Rows

struct LeaderRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    var pinned: Bool

    var body: some View {
        HStack(spacing: 12) {
            rankView.frame(width: 30)
            BloubView(shape: entry.shape, color: entry.color, expression: entry.isMe ? .happy : .neutral, alive: entry.isMe)
                .frame(width: 42, height: 42)
                .padding(3)
                .background(entry.color.color.opacity(0.14), in: .circle)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.isMe ? "\(entry.name) (you)" : entry.name)
                    .font(.display(16, weight: .bold))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill").foregroundStyle(Palette.flame)
                    Text("\(entry.streak)")
                }
                .font(.body(12, weight: .semibold))
                .foregroundStyle(Palette.muted)
            }
            Spacer()
            Text("\(entry.xp) XP")
                .font(.display(16, weight: .heavy))
                .foregroundStyle(entry.isMe ? Palette.periwinkleDeep : Palette.ink2)
                .contentTransition(.numericText(value: Double(entry.xp)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            if pinned {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.clear)
                    .glassEffect(.regular.tint(Palette.periwinkle.opacity(0.3)), in: .rect(cornerRadius: 22, style: .continuous))
            } else if entry.isMe {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.periwinkleSoft)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.periwinkle, lineWidth: 2))
            } else {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white)
            }
        }
    }

    @ViewBuilder private var rankView: some View {
        if rank <= 3 {
            Image(systemName: "medal.fill")
                .font(.system(size: 22))
                .foregroundStyle([Palette.gold, Color(hex: 0xB9C0CF), Color(hex: 0xD99060)][rank - 1])
                .overlay(Text("\(rank)").font(.display(10, weight: .heavy)).foregroundStyle(.white).offset(y: 3))
        } else {
            Text("\(rank)").font(.display(16, weight: .bold)).foregroundStyle(Palette.muted)
        }
    }
}

private struct ZoneDivider: View {
    let text: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(color.opacity(0.5)).frame(height: 1.5)
            Label(text, systemImage: symbol)
                .font(.body(12, weight: .bold))
                .foregroundStyle(color)
                .fixedSize()
            Rectangle().fill(color.opacity(0.5)).frame(height: 1.5)
        }
        .padding(.vertical, 6)
    }
}
