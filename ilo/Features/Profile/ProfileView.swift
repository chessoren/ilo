import SwiftUI

/// "My Progress": big bloub, level, stat tiles, badges, activity chart, deck and links.
struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var shown = false
    @State private var expressionIndex = 0
    @State private var squash = 0
    @State private var badge: Badge?
    @State private var showAllBadges = false

    private let cycle: [BloubExpression] = [.happy, .excited, .laughing, .proud, .curious, .surprised, .shy, .suspicious, .confused, .sleepy]

    var body: some View {
        let p = model.player
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero(p).appear(shown)
                tiles(p).appear(shown, delay: 0.08)
                badgesRow(p).appear(shown, delay: 0.14)
                ActivityChartCard().appear(shown, delay: 0.2)
                DeckPreview().appear(shown, delay: 0.26)
                links.appear(shown, delay: 0.32)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .demoScrollable()
        .background(IloBackground(tint: Palette.lavender))
        .navigationTitle("My progress")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: { Image(systemName: "gearshape.fill") }
            }
        }
        .sheet(item: $badge) { BadgeDetailSheet(badge: $0).presentationDetents([.height(420)]) }
        .sheet(isPresented: $showAllBadges) {
            AllBadgesSheet { b in
                showAllBadges = false
                // Present the detail once the grid sheet is gone (two sheets can't swap in one update).
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    badge = b
                }
            }
        }
        .onAppear { shown = true }
        #if DEBUG
        .sheet(isPresented: Binding(get: { debugDest != nil }, set: { if !$0 { debugDest = nil } })) {
            NavigationStack {
                switch debugDest {
                case "studio": BloubStudioView()
                case "shop": ShopView()
                default: SettingsView()
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            for name in ["studio", "shop", "settings"] where DebugSeed.action(name) { debugDest = name }
            if DebugSeed.action("badge") { badge = .streak7 }
        }
        #endif
    }

    #if DEBUG
    @State private var debugDest: String?
    #endif

    // MARK: Hero

    private func hero(_ p: Player) -> some View {
        VStack(spacing: 10) {
            Button {
                expressionIndex = (expressionIndex + 1) % cycle.count
                squash += 1
                Haptics.shared.softTap()
                SoundFX.shared.play(.bubble)
            } label: {
                ZStack {
                    Circle().fill(p.bloubColor.color.opacity(0.16)).frame(width: 190).blur(radius: 20)
                    BloubView(shape: p.bloubShape, color: p.bloubColor, expression: cycle[expressionIndex])
                        .frame(width: 150, height: 150)
                        .keyframeAnimator(initialValue: CGFloat(1), trigger: squash) { v, s in
                            v.scaleEffect(x: 2 - s, y: s, anchor: .bottom)
                        } keyframes: { _ in
                            SpringKeyframe(0.82, duration: 0.1)
                            SpringKeyframe(1.12, duration: 0.18)
                            SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                        }
                }
            }
            .buttonStyle(.plain)
            Text(p.name.isEmpty ? "Learner" : p.name).font(.display(30, weight: .heavy))
            Text("Joined \(p.joinedAt.formatted(.dateTime.month(.wide).year()))")
                .font(.body(14, weight: .medium)).foregroundStyle(Palette.muted)
            VStack(spacing: 6) {
                HStack {
                    Text("Level \(p.level)").font(.display(15, weight: .bold))
                    Spacer()
                    let next = PlayerLevel.xpNeeded(for: p.level + 1)
                    Text("\(p.totalXP) / \(next) XP").font(.body(13, weight: .semibold)).foregroundStyle(Palette.muted)
                        .contentTransition(.numericText())
                }
                GlossyProgressBar(progress: PlayerLevel.progress(for: p.totalXP), tint: Palette.periwinkleDeep, height: 14)
            }
            .card(radius: 22, padding: 14)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Tiles

    private func tiles(_ p: Player) -> some View {
        let total = model.courses.reduce(0) { $0 + $1.lessonCount }
        let doneAll = model.courses.reduce(0) { acc, c in acc + (model.progress[c.id]?.completed.count ?? 0) }
        let completedPct = total == 0 ? 0 : Int(Double(doneAll) / Double(max(model.courses.reduce(0) { $0 + $1.allNodes.count }, 1)) * 100)
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                bigTile("Completed", value: "\(completedPct)%", sub: "of your paths", fill: Palette.peach, symbol: "chart.pie.fill")
                bigTile("Lessons", value: "\(p.lessonsCompleted)", sub: "\(p.perfectLessons) perfect", fill: Palette.pink, symbol: "book.fill")
            }
            HStack(spacing: 10) {
                smallTile("flame.fill", Palette.flame, "\(p.streak)", "Streak")
                smallTile("bolt.fill", Palette.gold, "\(p.totalXP)", "Total XP")
                smallTile("trophy.fill", p.league.color.color, p.league.title, "League")
                smallTile("clock.fill", Palette.periwinkleDeep, "\(Int(p.minutesLearned))", "Minutes")
            }
        }
    }

    private func bigTile(_ title: String, value: String, sub: String, fill: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.body(14, weight: .semibold)).foregroundStyle(Palette.ink2)
                Spacer()
                Image(systemName: symbol).font(.system(size: 13, weight: .bold))
                    .frame(width: 30, height: 30).background(.white.opacity(0.7), in: .circle)
            }
            Text(value).font(.display(38, weight: .heavy)).contentTransition(.numericText())
            Text(sub).font(.body(12, weight: .medium)).foregroundStyle(Palette.ink2.opacity(0.7))
        }
        .foregroundStyle(Palette.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(fill, in: .rect(cornerRadius: 28, style: .continuous))
    }

    private func smallTile(_ symbol: String, _ tint: Color, _ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 16, weight: .bold)).foregroundStyle(tint)
            Text(value).font(.display(15, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.body(11, weight: .medium)).foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white, in: .rect(cornerRadius: 20, style: .continuous))
    }

    // MARK: Badges

    private func badgesRow(_ p: Player) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Badges · \(p.unlockedBadges.count)/\(Badge.allCases.count)",
                          action: ("See all", { showAllBadges = true }))
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    let sorted = Badge.allCases.sorted { a, b in
                        p.unlockedBadges.contains(a) && !p.unlockedBadges.contains(b)
                    }
                    ForEach(sorted) { b in
                        Button { badge = b } label: {
                            BadgeCircle(badge: b, unlocked: p.unlockedBadges.contains(b), size: 64)
                        }
                        .buttonStyle(.squish)
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -Metrics.gutter)
        }
    }

    // MARK: Links

    private var links: some View {
        VStack(spacing: 10) {
            NavigationLink { BloubStudioView() } label: {
                LinkRow(symbol: "paintpalette.fill", title: "Customize my bloub", subtitle: "Shapes & colours")
            }
            NavigationLink { ShopView() } label: {
                LinkRow(symbol: "bag.fill", title: "Shop", subtitle: "\(model.player.gems) gems to spend")
            }
            NavigationLink { SettingsView() } label: {
                LinkRow(symbol: "gearshape.fill", title: "Settings", subtitle: "Goal, reminders, sound")
            }
        }
        .buttonStyle(.squish(0.98))
    }
}

/// Black list row with white circle icon + chevron pill (ref 3).
struct LinkRow: View {
    var symbol: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
                .background(.white, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.display(16, weight: .bold))
                Text(subtitle).font(.body(12)).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .frame(width: 42, height: 30)
                .background(Palette.periwinkle, in: .capsule)
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(Palette.ink, in: .rect(cornerRadius: 26, style: .continuous))
    }
}

// MARK: - Badges

struct BadgeCircle: View {
    let badge: Badge
    let unlocked: Bool
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle().fill(unlocked ? badge.tint.soft : Palette.canvasDeep)
            Circle().strokeBorder(unlocked ? badge.tint.base : .clear, lineWidth: 3)
            Image(systemName: badge.symbol)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(unlocked ? badge.tint.deep : Palette.faint)
            if !unlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: size * 0.32, height: size * 0.32)
                    .background(Palette.faint, in: .circle)
                    .offset(x: size * 0.33, y: size * 0.33)
            }
        }
        .frame(width: size, height: size)
    }
}

struct BadgeDetailSheet: View {
    @Environment(AppModel.self) private var model
    let badge: Badge
    @State private var pop = false

    var body: some View {
        let unlocked = model.player.unlockedBadges.contains(badge)
        VStack(spacing: 16) {
            BadgeCircle(badge: badge, unlocked: unlocked, size: 130)
                .scaleEffect(pop ? 1 : 0.5)
                .rotationEffect(.degrees(pop ? 0 : -20))
            Text(badge.title).font(.display(28, weight: .heavy))
            Text(badge.detail).font(.body(16)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            Chip(text: unlocked ? "Unlocked" : "Locked", systemImage: unlocked ? "checkmark.seal.fill" : "lock.fill",
                 fill: unlocked ? Palette.mint : Palette.canvasDeep)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { pop = true }
            if unlocked { Haptics.shared.levelUp() } else { Haptics.shared.softTap() }
        }
    }
}

private struct AllBadgesSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var onPick: (Badge) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 20) {
                    ForEach(Badge.allCases) { b in
                        Button { onPick(b) } label: {
                            VStack(spacing: 8) {
                                BadgeCircle(badge: b, unlocked: model.player.unlockedBadges.contains(b), size: 76)
                                Text(b.title).font(.body(13, weight: .semibold)).foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.squish)
                    }
                }
                .padding(Metrics.gutter)
            }
            .background(Palette.canvas)
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark") } }
            }
        }
    }
}

// MARK: - Deck

struct DeckPreview: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let deck = model.player.savedTakeaways
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My deck").font(.display(20, weight: .bold))
                Spacer()
                if deck.count > 3 {
                    NavigationLink("See all \(deck.count)") { DeckView() }
                        .font(.body(14, weight: .semibold))
                        .foregroundStyle(Palette.periwinkleDeep)
                }
            }
            if deck.isEmpty {
                HStack(spacing: 12) {
                    BloubView(shape: .circle, color: .ink, expression: .curious, alive: false).frame(width: 44)
                    Text("Key ideas from your lessons will land here.")
                        .font(.body(14)).foregroundStyle(Palette.muted)
                }
                .card(radius: 24, padding: 16)
            } else {
                ForEach(Array(deck.prefix(3).enumerated()), id: \.element.id) { i, t in
                    TakeawayCard(takeaway: t, tint: CourseTint.allCases[i % CourseTint.allCases.count])
                }
            }
        }
    }
}

struct TakeawayCard: View {
    let takeaway: Takeaway
    let tint: CourseTint

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(tint.base).frame(width: 5)
            VStack(alignment: .leading, spacing: 6) {
                Text(takeaway.text).font(.body(15, weight: .medium)).foregroundStyle(Palette.ink)
                Text(takeaway.courseTitle.uppercased()).font(.body(11, weight: .bold)).foregroundStyle(tint.deep)
            }
            Spacer(minLength: 0)
        }
        .card(radius: 22, padding: 14)
    }
}

struct DeckView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(model.player.savedTakeaways.enumerated()), id: \.element.id) { i, t in
                    TakeawayCard(takeaway: t, tint: CourseTint.allCases[i % CourseTint.allCases.count])
                        .scrollTransition { v, phase in v.opacity(phase.isIdentity ? 1 : 0.4).scaleEffect(phase.isIdentity ? 1 : 0.95) }
                }
            }
            .padding(Metrics.gutter)
        }
        .background(Palette.canvas)
        .navigationTitle("My deck")
    }
}
