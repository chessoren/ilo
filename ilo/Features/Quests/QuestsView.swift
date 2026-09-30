import SwiftUI

/// Daily quests with chests, friend quest and the monthly badge challenge.
struct QuestsView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router
    @State private var shown = false
    @State private var flights: [GemFlight] = []
    @State private var confetti = 0
    @State private var claiming: Set<UUID> = []

    struct GemFlight: Identifiable { let id = UUID(); var from: CGPoint; var amount: Int }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header.appear(shown)
                VStack(spacing: 12) {
                    ForEach(Array(model.quests.enumerated()), id: \.element.id) { i, quest in
                        QuestRow(quest: quest) { origin in claim(quest, from: origin) }
                            .appear(shown, delay: 0.08 + Double(i) * 0.06)
                    }
                }
                if let fq = model.friendQuest {
                    SectionHeader(title: "Friend quest").appear(shown, delay: 0.26)
                    FriendQuestCard(quest: fq).appear(shown, delay: 0.3)
                }
                SectionHeader(title: "Monthly challenge").appear(shown, delay: 0.34)
                MonthlyChallengeCard().appear(shown, delay: 0.38)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .demoScrollable()
        .background(IloBackground(tint: Palette.orchid, lines: false))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { StatsCluster() }
        }
        .overlay {
            GeometryReader { geo in
                let origin = geo.frame(in: .global).origin
                ZStack {
                    ConfettiView(trigger: confetti)
                    ForEach(flights) { flight in
                        GemFlightView(from: CGPoint(x: flight.from.x - origin.x, y: flight.from.y - origin.y),
                                      to: CGPoint(x: router.gemsTarget.midX - origin.x, y: router.gemsTarget.midY - origin.y),
                                      amount: flight.amount)
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear { shown = true; model.refreshDailyState() }
        #if DEBUG
        .task {
            guard DebugSeed.action("claim") else { return }
            try? await Task.sleep(for: .seconds(1.5))
            if let q = model.quests.first(where: { $0.isDone && !$0.claimed }) { claim(q, from: CGPoint(x: 380, y: 420)) }
        }
        #endif
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily quests").font(.display(32, weight: .heavy))
                TimelineView(.periodic(from: .now, by: 30)) { ctx in
                    let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: ctx.date)) ?? ctx.date
                    let left = max(0, Int(midnight.timeIntervalSince(ctx.date)))
                    Chip(text: "Resets in \(left / 3600)h \((left % 3600) / 60)m", systemImage: "clock.fill", fill: Palette.lavender)
                }
                let done = model.quests.filter(\.isDone).count
                Text("\(done) of \(model.quests.count) complete")
                    .font(.body(14, weight: .medium)).foregroundStyle(Palette.muted)
                    .contentTransition(.numericText())
            }
            Spacer()
            BloubView(shape: .circle, color: .ilo,
                      expression: model.quests.allSatisfy(\.claimed) ? .proud : (model.quests.contains { $0.isDone && !$0.claimed } ? .excited : .attentive))
                .frame(width: 96)
        }
        .padding(.top, 4)
    }

    private func claim(_ quest: Quest, from origin: CGPoint) {
        // `quest` is a snapshot: a second tap within the 750 ms flight must not launch another burst.
        guard quest.isDone, !quest.claimed, !claiming.contains(quest.id) else { return }
        claiming.insert(quest.id)
        Haptics.shared.celebrate()
        SoundFX.shared.play(.coin)
        confetti += 1
        let flight = GemFlight(from: origin, amount: quest.reward)
        flights.append(flight)
        Task {
            try? await Task.sleep(for: .milliseconds(750))
            withAnimation(.spring) { model.claim(quest) }
            claiming.remove(quest.id)
            SoundFX.shared.play(.coin)
            try? await Task.sleep(for: .seconds(1))
            flights.removeAll { $0.id == flight.id }
        }
    }
}

// MARK: - Rows

private struct QuestRow: View {
    let quest: Quest
    var onClaim: (CGPoint) -> Void
    @State private var frame: CGRect = .zero

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: quest.symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(quest.tint.deep)
                .frame(width: 48, height: 48)
                .background(quest.tint.soft, in: .circle)
            VStack(alignment: .leading, spacing: 8) {
                Text(quest.title).font(.display(16, weight: .bold)).foregroundStyle(Palette.ink)
                HStack(spacing: 8) {
                    GlossyProgressBar(progress: quest.fraction, tint: quest.isDone ? Palette.success : quest.tint.base, height: 12)
                    Text("\(min(quest.progress, quest.target))/\(quest.target)")
                        .font(.display(12, weight: .bold))
                        .foregroundStyle(Palette.muted)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            chest
        }
        .card(radius: 26, padding: 14)
    }

    @ViewBuilder private var chest: some View {
        if quest.claimed {
            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(Palette.success)
                Text("+\(quest.reward)").font(.display(11, weight: .bold)).foregroundStyle(Palette.muted)
            }
            .frame(width: 64, height: 56)
            .transition(.scale.combined(with: .opacity))
        } else if quest.isDone {
            Button { onClaim(CGPoint(x: frame.midX, y: frame.midY)) } label: {
                VStack(spacing: 2) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 22, weight: .bold))
                        .symbolEffect(.wiggle, options: .repeat(.periodic(delay: 1)))
                    Text("Claim").font(.display(12, weight: .heavy))
                }
                .foregroundStyle(.white)
                .frame(width: 64, height: 56)
                .background(Palette.gold.gradient, in: .rect(cornerRadius: 18, style: .continuous))
                .shadow(color: Palette.gold.opacity(0.5), radius: 8, y: 4)
            }
            .buttonStyle(.squish(0.9))
            .accessibilityIdentifier("quest-claim")
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
        } else {
            VStack(spacing: 2) {
                Image(systemName: "gift.fill").font(.system(size: 22)).foregroundStyle(Color(hex: 0xD5D8E3))
                HStack(spacing: 2) {
                    Image(systemName: "diamond.fill").font(.system(size: 9))
                    Text("\(quest.reward)").font(.display(11, weight: .bold))
                }
                .foregroundStyle(Palette.faint)
            }
            .frame(width: 64, height: 56)
        }
    }
}

/// Gems flying from a claimed chest into the top gems pill.
private struct GemFlightView: View {
    let from: CGPoint
    let to: CGPoint
    let amount: Int
    @State private var go = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Image(systemName: "diamond.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.gem)
                    .shadow(color: Palette.gem.opacity(0.5), radius: 4)
                    .modifier(ArcMove(progress: go ? 1 : 0, from: from, to: to, lift: 120 + CGFloat(i * 14),
                                      jitter: CGFloat(i - 4) * 9))
                    .scaleEffect(go ? 0.6 : 1.1)
                    .animation(.easeIn(duration: 0.7).delay(Double(i) * 0.04), value: go)
            }
            Text("+\(amount)")
                .font(.display(22, weight: .heavy))
                .foregroundStyle(Palette.gem)
                .position(x: from.x, y: from.y - (go ? 60 : 10))
                .opacity(go ? 0 : 1)
                .animation(.easeOut(duration: 0.9), value: go)
        }
        .onAppear { go = true }
    }
}

private struct ArcMove: GeometryEffect {
    var progress: CGFloat
    var from: CGPoint
    var to: CGPoint
    var lift: CGFloat
    var jitter: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = progress
        let control = CGPoint(x: (from.x + to.x) / 2 + jitter * 4, y: min(from.y, to.y) - lift)
        let x = (1 - t) * (1 - t) * from.x + 2 * (1 - t) * t * control.x + t * t * to.x
        let y = (1 - t) * (1 - t) * from.y + 2 * (1 - t) * t * control.y + t * t * to.y
        let spread = sin(t * .pi) * jitter
        return ProjectionTransform(CGAffineTransform(translationX: x + spread - size.width / 2, y: y - size.height / 2))
    }
}

// MARK: - Friend quest

private struct FriendQuestCard: View {
    @Environment(AppModel.self) private var model
    let quest: FriendQuest

    private var friendShape: BloubShape { BloubShape.allCases[quest.friendName.unicodeScalars.reduce(0) { $0 + Int($1.value) } % BloubShape.allCases.count] }
    private var friendColor: BloubColor { [.orange, .pink, .turquoise, .violet, .green][quest.friendName.count % 5] }

    var body: some View {
        let total = max(quest.target, 1)
        let mineF = min(Double(quest.mine) / Double(total), 1)
        let theirsF = min(Double(quest.theirs) / Double(total), 1 - mineF)
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: -10) {
                BloubView(shape: model.player.bloubShape, color: model.player.bloubColor, expression: .happy)
                    .frame(width: 54)
                    .padding(4).background(.white, in: .circle)
                BloubView(shape: friendShape, color: friendColor, expression: .excited, alive: false)
                    .frame(width: 54)
                    .padding(4).background(.white, in: .circle)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Ends in \(daysLeft)d").font(.body(12, weight: .bold)).foregroundStyle(Palette.ink2)
                    Text("Team up this week").font(.body(12, weight: .semibold)).foregroundStyle(Palette.muted)
                }
            }
            Text("Earn \(quest.target) XP together with \(quest.friendName)")
                .font(.display(19, weight: .bold))
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(Palette.periwinkleDeep).frame(width: geo.size.width * mineF)
                    Rectangle().fill(Palette.orchid).frame(width: geo.size.width * theirsF)
                    Spacer(minLength: 0)
                }
                .background(.white.opacity(0.7))
                .clipShape(.capsule)
            }
            .frame(height: 14)
            HStack(spacing: 14) {
                legend(Palette.periwinkleDeep, "You · \(quest.mine)")
                legend(Palette.orchid, "\(quest.friendName) · \(quest.theirs)")
                Spacer()
                Text("\(min(quest.mine + quest.theirs, quest.target))/\(quest.target)")
                    .font(.display(14, weight: .heavy))
            }
        }
        .card(Palette.pink.opacity(0.55), radius: 30, padding: 20)
    }

    private var daysLeft: Int { max(0, Calendar.current.dateComponents([.day], from: .now, to: quest.endsAt).day ?? 0) }

    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(c).frame(width: 8, height: 8)
            Text(t).font(.body(12, weight: .semibold)).foregroundStyle(Palette.ink2)
        }
    }
}

// MARK: - Monthly challenge

private struct MonthlyChallengeCard: View {
    @Environment(AppModel.self) private var model
    private let target = 20

    var body: some View {
        let cal = Calendar.current
        let month = cal.dateInterval(of: .month, for: .now)
        let days = model.player.xpByDay.filter { $0.value > 0 && (month?.contains($0.key) ?? false) }.count
        let left = max(0, cal.dateComponents([.day], from: .now, to: month?.end ?? .now).day ?? 0)
        let fraction = min(Double(days) / Double(target), 1)
        HStack(spacing: 18) {
            ZStack {
                BloubView(shape: .hexagon, color: .amber, expression: fraction >= 1 ? .proud : .curious, alive: false)
                    .frame(width: 84)
                    .saturation(fraction >= 1 ? 1 : 0.4 + fraction * 0.6)
                Text(Date.now.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.display(11, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Palette.ink, in: .capsule)
                    .offset(y: 42)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Date.now.formatted(.dateTime.month(.wide))) badge")
                    .font(.body(12, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                Text("Learn on \(target) days this month")
                    .font(.display(18, weight: .bold)).foregroundStyle(.white)
                GlossyProgressBar(progress: fraction, tint: Palette.gold, height: 10)
                Text("\(days)/\(target) days · " + (left == 0 ? "last day!" : "\(left) days left"))
                    .font(.body(12, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(Palette.ink, in: .rect(cornerRadius: 30, style: .continuous))
    }
}
