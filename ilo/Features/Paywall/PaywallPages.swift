import SwiftUI

// MARK: - Page 1: your path + benefits

struct PaywallHeroPage: View {
    var course: Course?
    var player: Player
    var visible: Bool

    private var tint: CourseTint { course?.tint ?? .periwinkle }

    private struct Benefit: Identifiable {
        var id: String { title }
        var title: String
        var detail: String
        var symbol: String
        var tint: CourseTint
    }

    private let benefits: [Benefit] = [
        .init(title: "Unlimited AI courses", detail: "Anything you want to learn, researched for you", symbol: "sparkles", tint: .periwinkle),
        .init(title: "Lessons that adapt", detail: "ilo remembers your mistakes and fixes them", symbol: "brain.head.profile", tint: .orchid),
        .init(title: "Live calls & roleplay", detail: "Talk it through with ilo, out loud", symbol: "phone.bubble.fill", tint: .sky),
        .init(title: "Real-world missions", detail: "Camera coach, code labs and practice timers", symbol: "flag.checkered", tint: .mint),
        .init(title: "Streak freezes & leagues", detail: "Stay motivated, never lose your progress", symbol: "flame.fill", tint: .orange),
    ]

    @State private var iconPulse = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                    .appear(visible)
                pathCard
                    .appear(visible, delay: 0.1)
                VStack(spacing: 0) {
                    ForEach(Array(benefits.enumerated()), id: \.element.id) { i, b in
                        benefitRow(b, index: i)
                            .appear(visible, delay: 0.18 + Double(i) * 0.06)
                        if i < benefits.count - 1 { Divider().opacity(0.4).padding(.leading, 58) }
                    }
                }
                .card(.white, radius: Metrics.cardRadius, padding: 14)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 6)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.2))
                iconPulse += 1
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [tint.base.opacity(0.45), .clear], center: .center, startRadius: 5, endRadius: 125))
                    .frame(width: 250, height: 250)
                HStack(alignment: .bottom, spacing: -8) {
                    BloubView(shape: .circle, color: .ink, expression: .happy)
                        .frame(width: 104, height: 104)
                        .phaseAnimator([0.0, -8.0]) { v, y in v.offset(y: y) } animation: { _ in .easeInOut(duration: 0.9) }
                    BloubView(shape: player.bloubShape, color: player.bloubColor, expression: .excited)
                        .frame(width: 80, height: 80)
                        .phaseAnimator([-6.0, 0.0]) { v, y in v.offset(y: y) } animation: { _ in .easeInOut(duration: 0.9) }
                }
                Image(systemName: course?.symbol ?? "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(tint.deep, in: .circle)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 3) }
                    .offset(x: 88, y: -52)
                    .symbolEffect(.bounce, value: iconPulse)
            }
            .frame(height: 150)

            Group {
                if let course {
                    Text("Your \(Text(course.title).foregroundStyle(tint.deep)) path is ready")
                } else {
                    Text("Your path is ready")
                }
            }
            .font(.display(32, weight: .heavy))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            Text(player.name.isEmpty ? "Unlock it and start today." : "\(player.name.capitalized), unlock it and start today.")
                .font(.body(16, weight: .medium))
                .foregroundStyle(Palette.muted)
        }
    }

    @ViewBuilder private var pathCard: some View {
        if let course {
            let nodes = Array(course.allNodes.prefix(6))
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(course.units.count) \(course.units.count == 1 ? "unit" : "units") · \(course.lessonCount) lessons", systemImage: "map.fill")
                        .font(.display(15, weight: .bold))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Chip(text: "Made for you", systemImage: "wand.and.stars", fill: .white)
                }
                HStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                        ZStack {
                            Circle()
                                .fill(i == 0 ? tint.deep : .white)
                                .frame(width: 44, height: 44)
                            Image(systemName: i == 0 ? (node.symbol.isEmpty ? node.kind.defaultSymbol : node.symbol) : "lock.fill")
                                .font(.system(size: i == 0 ? 17 : 13, weight: .bold))
                                .foregroundStyle(i == 0 ? .white : Palette.faint)
                        }
                        .offset(y: i % 2 == 0 ? -5 : 5)
                        if i < nodes.count - 1 {
                            Capsule().fill(.white.opacity(0.8)).frame(height: 4).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .card(tint.soft, radius: Metrics.cardRadius, padding: 16)
        }
    }

    private func benefitRow(_ b: Benefit, index: Int) -> some View {
        HStack(spacing: 14) {
            Image(systemName: b.symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(b.tint.deep)
                .frame(width: 44, height: 44)
                .background(b.tint.soft, in: .rect(cornerRadius: 14, style: .continuous))
                .symbolEffect(.bounce, value: iconPulse % benefits.count == index ? iconPulse : 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(b.title).font(.display(16, weight: .bold)).foregroundStyle(Palette.ink)
                Text(b.detail).font(.body(13)).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Palette.success)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Page 2: timeline + plans

struct PaywallPlansPage: View {
    @Environment(PurchaseService.self) private var store
    @Binding var selectedID: String?
    var heartbeat: Int
    @State private var visible = false

    private var selected: PaywallPackage? { store.packages.first { $0.id == selectedID } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(selected?.hasTrial == true ? "How your free week works" : "Choose your plan")
                    .font(.display(28, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.opacity)
                    .appear(visible)

                PaywallTrialTimeline(package: selected)
                    .appear(visible, delay: 0.08)

                VStack(spacing: 10) {
                    if store.packages.isEmpty {
                        ProgressView().frame(height: 120)
                    }
                    ForEach(store.packages) { package in
                        PaywallPlanCard(package: package,
                                        isSelected: package.id == selectedID,
                                        savings: package.kind == .annual ? store.annualSavingsPercent : nil) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selectedID = package.id }
                            SoundFX.shared.play(.pop)
                        }
                    }
                }
                .appear(visible, delay: 0.16)

                socialProof
                    .appear(visible, delay: 0.24)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .onAppear { visible = true }
    }

    private var socialProof: some View {
        let crew: [(BloubShape, BloubColor)] = [(.pebble, .violet), (.circle, .green), (.squircle, .orange), (.cloud, .pink), (.droplet, .blue)]
        return HStack(spacing: 12) {
            HStack(spacing: -10) {
                ForEach(Array(crew.enumerated()), id: \.offset) { _, b in
                    BloubView(shape: b.0, color: b.1, expression: .happy, alive: false)
                        .frame(width: 26, height: 26)
                        .frame(width: 36, height: 36)
                        .background(.white, in: .circle)
                        .overlay { Circle().strokeBorder(Palette.canvas, lineWidth: 2) }
                }
            }
            Text("Join curious people learning a little every day.")
                .font(.body(13.5, weight: .medium))
                .foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .card(.white.opacity(0.7), radius: 22, padding: 12)
    }
}

/// Today → Day 5 → Day 7 trial timeline.
struct PaywallTrialTimeline: View {
    var package: PaywallPackage?
    @State private var fill: Double = 0

    private struct Item: Identifiable {
        var id: String { title }
        var title: String
        var detail: String
        var symbol: String
        var color: Color
    }

    private var items: [Item] {
        guard let package else { return [] }
        if package.hasTrial, let days = package.trialDays {
            let remindDay = max(days - 2, 1)
            let billDate = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
            return [
                Item(title: "Today", detail: "Full access to everything. Start your path right now.", symbol: "lock.open.fill", color: Palette.victory),
                Item(title: "Day \(remindDay)", detail: "We'll remind you that your trial is ending soon.", symbol: "bell.fill", color: Palette.periwinkleDeep),
                Item(title: "Day \(days)", detail: "You're billed \(package.price) on \(billDate.formatted(.dateTime.month(.abbreviated).day())). Cancel anytime before.", symbol: "crown.fill", color: Palette.ink),
            ]
        }
        return [
            Item(title: "Today", detail: "Full access to everything, billed \(package.price) per \(package.periodWord).", symbol: "lock.open.fill", color: Palette.victory),
            Item(title: "Anytime", detail: "Cancel in a couple of taps from Settings. No questions asked.", symbol: "hand.thumbsup.fill", color: Palette.ink),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(item.color, in: .circle)
                            .symbolEffect(.bounce, value: fill > Double(i) / Double(max(items.count - 1, 1)))
                        if i < items.count - 1 {
                            GeometryReader { geo in
                                let segment = 1 / Double(max(items.count - 1, 1))
                                let local = min(max((fill - Double(i) * segment) / segment, 0), 1)
                                ZStack(alignment: .top) {
                                    Capsule().fill(Palette.canvasDeep)
                                    Capsule()
                                        .fill(LinearGradient(colors: [item.color, items[i + 1].color], startPoint: .top, endPoint: .bottom))
                                        .frame(height: geo.size.height * local)
                                }
                            }
                            .frame(width: 6)
                            .frame(minHeight: 30)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(.display(17, weight: .heavy)).foregroundStyle(Palette.ink)
                        Text(item.detail).font(.body(14)).foregroundStyle(Palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, i < items.count - 1 ? 14 : 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(.white, radius: Metrics.cardRadius, padding: 18)
        .task(id: package?.id) {
            fill = 0
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeInOut(duration: 1.3)) { fill = 1 }
            for _ in items.indices {
                Haptics.shared.tick()
                try? await Task.sleep(for: .milliseconds(1300 / max(items.count, 1)))
            }
        }
    }
}

/// Liquid Glass plan card.
struct PaywallPlanCard: View {
    var package: PaywallPackage
    var isSelected: Bool
    var savings: Int?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().strokeBorder(isSelected ? Palette.ink : Palette.faint, lineWidth: 2)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Palette.ink, in: .circle)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(package.title).font(.display(19, weight: .heavy)).foregroundStyle(Palette.ink)
                        if let savings {
                            Text("Save \(savings)%")
                                .font(.display(11.5, weight: .heavy))
                                .foregroundStyle(Palette.success)
                                .padding(.horizontal, 7)
                                .frame(height: 20)
                                .background(Palette.successSoft, in: .capsule)
                        }
                    }
                    Text(package.hasTrial ? "\(package.trialDays ?? 7) days free, then \(package.price)/\(package.periodWord)"
                                          : (package.kind == .weekly ? "Flexible, cancel anytime" : "\(package.price) per \(package.periodWord)"))
                        .font(.body(13.5, weight: .medium))
                        .foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(package.pricePerWeek).font(.display(19, weight: .heavy)).foregroundStyle(Palette.ink)
                    Text("per week").font(.body(12, weight: .medium)).foregroundStyle(Palette.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, package.kind == .annual ? 20 : 16)
            .glassEffect(isSelected ? .regular.tint(Palette.periwinkle.opacity(0.28)).interactive() : .regular.interactive(),
                         in: .rect(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(isSelected ? Palette.ink : .white.opacity(0.6), lineWidth: isSelected ? 2.5 : 1)
            }
            .overlay(alignment: .topTrailing) {
                if package.kind == .annual {
                    Text(package.hasTrial ? "BEST VALUE · \(package.trialDays ?? 7) DAYS FREE" : "BEST VALUE")
                        .font(.display(11, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 24)
                        .background(Palette.victory, in: .capsule)
                        .offset(x: -18, y: -12)
                }
            }
            .scaleEffect(isSelected ? 1 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.squish(0.97))
        .padding(.top, package.kind == .annual ? 10 : 0)
    }
}

// MARK: - Success

struct PaywallSuccessOverlay: View {
    var player: Player
    var trialDays: Int?
    @State private var shown = false

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Palette.victory.opacity(0.4), .clear], center: .center, startRadius: 10, endRadius: 140))
                        .frame(width: 280, height: 280)
                        .scaleEffect(shown ? 1 : 0.4)
                    HStack(alignment: .bottom, spacing: -6) {
                        BloubView(shape: .circle, color: .ink, expression: .laughing).frame(width: 110, height: 110)
                        BloubView(shape: player.bloubShape, color: player.bloubColor, expression: .excited).frame(width: 90, height: 90)
                    }
                    Image(systemName: "crown.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Palette.gold)
                        .offset(x: -30, y: -78)
                        .rotationEffect(.degrees(shown ? -8 : -40))
                        .symbolEffect(.bounce, value: shown)
                }
                .frame(height: 220)
                Text("Welcome to ilo Pro")
                    .font(.display(34, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text(trialDays.map { "Your \($0)-day free trial has started. Let's play!" } ?? "Everything is unlocked. Let's play!")
                    .font(.body(17, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(Metrics.gutter)
            .scaleEffect(shown ? 1 : 0.7)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) { shown = true }
        }
    }
}
