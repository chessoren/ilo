import SwiftUI

/// Home — "Hello, Sophia": greeting, daily goal ring, continue hero, my courses, quests, create prompt.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router
    @State private var shown = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                greeting.appear(shown, delay: 0.02)
                if model.courses.isEmpty {
                    EmptyHomeCard().appear(shown, delay: 0.1)
                    DailyGoalCard().appear(shown, delay: 0.18)
                } else {
                    DailyGoalCard().appear(shown, delay: 0.08)
                    if let course = model.activeCourse {
                        ContinueHeroCard(course: course).appear(shown, delay: 0.14)
                    }
                    MyCoursesRow().appear(shown, delay: 0.2)
                    QuestsPreviewCard().appear(shown, delay: 0.26)
                    CreatePromptCard().appear(shown, delay: 0.32)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .demoScrollable()
        .background(IloBackground())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { StatsCluster() }
        }
        .toolbarTitleDisplayMode(.inline)
        .onAppear { shown = true }
    }

    private var greeting: some View {
        let name = model.player.name.isEmpty ? "friend" : model.player.name
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.body(15, weight: .medium))
                    .foregroundStyle(Palette.muted)
                Text("Hello, \(Text(name).foregroundStyle(Palette.periwinkleDeep))")
                    .foregroundStyle(Palette.ink)
                    .font(.display(34, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Chip(text: lessonsChipText, systemImage: model.player.dailyGoalMet ? "checkmark" : "book.closed.fill",
                     fill: model.player.dailyGoalMet ? Palette.mint : Palette.peach)
                    .contentTransition(.numericText())
            }
            Spacer()
            Button { router.tab = .profile } label: { PlayerAvatar(size: 62) }
                .buttonStyle(.squish)
        }
        .padding(.top, 6)
    }

    private var lessonsChipText: String {
        let p = model.player
        if model.courses.isEmpty { return "Your first path awaits" }
        if p.dailyGoalMet { return "Daily goal done" }
        let n = max(1, Int(ceil(Double(p.dailyGoalXP - p.todayXP) / 15)))
        return "\(n) lesson\(n == 1 ? "" : "s") for today"
    }
}

// MARK: - Daily goal

struct DailyGoalCard: View {
    @Environment(AppModel.self) private var model
    @State private var progress: Double = 0
    @State private var bounce = 0

    var body: some View {
        let p = model.player
        let fraction = min(Double(p.todayXP) / Double(max(p.dailyGoalXP, 1)), 1)
        VStack(spacing: 16) {
            HStack(spacing: 18) {
                ZStack {
                    TickRing(progress: progress, tint: p.dailyGoalMet ? Palette.victory : Palette.periwinkleDeep, ticks: 72)
                    VStack(spacing: 0) {
                        Text("\(Int((progress * 100).rounded()))%")
                            .font(.display(38, weight: .heavy))
                            .contentTransition(.numericText(value: progress))
                        Text("daily goal")
                            .font(.body(12, weight: .semibold))
                            .foregroundStyle(Palette.muted)
                    }
                }
                .frame(width: 158, height: 158)

                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        bounce += 1
                        Haptics.shared.softTap()
                        SoundFX.shared.play(.bubble)
                    } label: {
                        BloubView(shape: .circle, color: .ink, expression: iloExpression,
                                  mode: p.todayXP == 0 ? .sleeping : .face)
                            .frame(width: 78, height: 78)
                            .keyframeAnimator(initialValue: CGFloat(1), trigger: bounce) { view, s in
                                view.scaleEffect(x: 2 - s, y: s, anchor: .bottom)
                            } keyframes: { _ in
                                SpringKeyframe(0.8, duration: 0.12)
                                SpringKeyframe(1.12, duration: 0.18)
                                SpringKeyframe(1, duration: 0.3)
                            }
                    }
                    .buttonStyle(.plain)
                    Text(iloLine)
                        .font(.body(14, weight: .semibold))
                        .foregroundStyle(Palette.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                stat("XP today", "\(p.todayXP)/\(p.dailyGoalXP)", Palette.periwinkleSoft)
                stat("Streak", "\(p.streak) d", Palette.peach)
                stat("Lessons", "\(p.lessonsCompleted)", Palette.mint)
            }
            WeekStrip()
        }
        .card(radius: 34, padding: 20)
        .onAppear { withAnimation(.smooth(duration: 1.3).delay(0.2)) { progress = fraction } }
        .onChange(of: fraction) { _, new in withAnimation(.smooth(duration: 1.2)) { progress = new } }
    }

    private var iloExpression: BloubExpression {
        let p = model.player
        if p.dailyGoalMet { return .proud }
        if p.todayXP == 0 { return .sleepy }
        return p.todayXP * 2 >= p.dailyGoalXP ? .excited : .attentive
    }

    private var iloLine: String {
        let p = model.player
        if p.dailyGoalMet { return "Goal smashed. I'm so proud of you!" }
        if p.todayXP == 0 { return "Zzz… wake me up with a lesson?" }
        return "\(p.dailyGoalXP - p.todayXP) XP to go. You've got this!"
    }

    private func stat(_ title: String, _ value: String, _ fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.body(11, weight: .semibold)).foregroundStyle(Palette.ink2.opacity(0.7))
            Text(value).font(.display(18, weight: .heavy)).foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(fill, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Continue hero

struct ContinueHeroCard: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router
    let course: Course
    @State private var pressed = false

    var body: some View {
        let node = model.currentNode(in: course)
        let unit = node.flatMap { course.unit(containing: $0.id) } ?? course.units.last
        let unitIndex = unit.flatMap { u in course.units.firstIndex { $0.id == u.id } } ?? 0
        let done = model.progress[course.id]?.completed ?? []
        let unitDone = unit?.nodes.filter { done.contains($0.id) }.count ?? 0
        let unitTotal = unit?.nodes.count ?? 1
        let tint = unit?.tint ?? course.tint

        Group {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Image(systemName: course.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(tint.deep)
                        .frame(width: 50, height: 50)
                        .background(.white, in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(course.title).font(.display(17, weight: .bold)).foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Text("Unit \(unitIndex + 1) · \(unit?.title ?? "")")
                            .font(.body(13, weight: .medium)).foregroundStyle(Palette.ink2.opacity(0.7))
                            .lineLimit(1)
                    }
                    Spacer()
                    UnitCounterRing(done: unitDone, total: unitTotal, tint: tint)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(node == nil ? "Course complete" : "Up next · \(node!.kind.label)")
                        .font(.body(13, weight: .semibold))
                        .foregroundStyle(tint.deep)
                    Text(node?.title ?? "You finished every lesson!")
                        .font(.display(26, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                HStack {
                    if let node {
                        Button {
                            if node.kind == .chest { router.openPath(course) } else { router.play(node, in: course) }
                        } label: {
                            HStack(spacing: 8) {
                                Text(node.kind == .chest ? "Open chest" : "Continue")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .buttonStyle(.pill(.ink, height: 50, fullWidth: false))
                    }
                    Spacer()
                    if let node, model.generating.contains(node.id) {
                        BloubView(shape: .circle, color: .ink, mode: .thinking).frame(width: 40)
                    } else if let node, model.lessons[node.id] != nil {
                        Label("Ready", systemImage: "sparkles")
                            .font(.body(13, weight: .semibold))
                            .foregroundStyle(tint.deep)
                            .symbolEffect(.pulse)
                    }
                }
            }
            .padding(22)
            .background {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 36, style: .continuous).fill(tint.soft)
                    Image(systemName: course.symbol)
                        .font(.system(size: 150, weight: .black))
                        .foregroundStyle(tint.base.opacity(0.13))
                        .rotationEffect(.degrees(-14))
                        .offset(x: 30, y: 40)
                        .clipped()
                }
                .clipShape(.rect(cornerRadius: 36, style: .continuous))
            }
            .shadow(color: tint.deep.opacity(0.15), radius: 20, y: 10)
        }
        .contentShape(.rect(cornerRadius: 36))
        .scaleEffect(pressed ? 0.98 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: pressed)
        .onTapGesture {
            Haptics.shared.tap()
            router.openPath(course)
        }
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressed = $0 }, perform: { router.openPath(course) })
    }
}

/// "1/3" ring counter like ref 3.
struct UnitCounterRing: View {
    var done: Int
    var total: Int
    var tint: CourseTint
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.8), lineWidth: 5)
            Circle()
                .trim(from: 0, to: Double(done) / Double(max(total, 1)))
                .stroke(tint.deep, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(done)/\(total)")
                .font(.display(13, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
        }
        .frame(width: size, height: size)
        .animation(.smooth(duration: 0.8), value: done)
    }
}

// MARK: - My courses

struct MyCoursesRow: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "My courses", action: ("New", { router.tab = .create }))
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(model.courses) { course in
                        CourseTile(course: course) { router.openPath(course) }
                            .scrollTransition(axis: .horizontal) { view, phase in
                                view.scaleEffect(phase.isIdentity ? 1 : 0.92)
                                    .rotationEffect(.degrees(phase.value * 4))
                            }
                    }
                    Button { router.tab = .create } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .frame(width: 54, height: 54)
                                .background(Palette.ink, in: .circle)
                                .foregroundStyle(.white)
                            Text("New path").font(.display(15, weight: .bold)).foregroundStyle(Palette.ink)
                        }
                        .frame(width: 130, height: 196)
                        .background(RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(Palette.ink.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])))
                    }
                    .buttonStyle(.squish)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -Metrics.gutter)
        }
    }
}

struct CourseTile: View {
    @Environment(AppModel.self) private var model
    let course: Course
    var action: () -> Void

    var body: some View {
        let pct = model.completion(of: course)
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: course.symbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(course.tint.deep)
                        .frame(width: 46, height: 46)
                        .background(.white, in: .circle)
                    Spacer()
                    Text("\(Int(pct * 100))%")
                        .font(.display(13, weight: .heavy))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(.white.opacity(0.7), in: .capsule)
                }
                Spacer()
                Text(course.title)
                    .font(.display(18, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(course.lessonCount) lessons")
                    .font(.body(12, weight: .medium))
                    .foregroundStyle(Palette.ink2.opacity(0.65))
                    .padding(.top, 2)
                GlossyProgressBar(progress: pct, tint: course.tint.deep, height: 8)
                    .padding(.top, 12)
            }
            .padding(16)
            .frame(width: 164, height: 196)
            .background(course.tint.soft, in: .rect(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(.squish)
    }
}

// MARK: - Quests preview

struct QuestsPreviewCard: View {
    @Environment(AppModel.self) private var model
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button { router.tab = .quests } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Today's quests").font(.display(20, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                        .background(Palette.canvas, in: .circle)
                }
                ForEach(model.quests.prefix(3)) { quest in
                    HStack(spacing: 12) {
                        Image(systemName: quest.symbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(quest.tint.deep)
                            .frame(width: 34, height: 34)
                            .background(quest.tint.soft, in: .circle)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(quest.title).font(.body(14, weight: .semibold)).lineLimit(1)
                            GlossyProgressBar(progress: quest.fraction, tint: quest.isDone ? Palette.success : quest.tint.base, height: 8)
                        }
                        Image(systemName: quest.claimed ? "checkmark.circle.fill" : (quest.isDone ? "gift.fill" : "gift"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(quest.isDone ? Palette.gold : Palette.faint)
                            .symbolEffect(.bounce, options: .repeat(.periodic(delay: 1.5)), isActive: quest.isDone && !quest.claimed)
                    }
                }
            }
            .foregroundStyle(Palette.ink)
            .card(radius: 30, padding: 20)
        }
        .buttonStyle(.squish(0.98))
    }
}

// MARK: - Create prompt

struct CreatePromptCard: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button { router.tab = .create } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Palette.periwinkle.gradient).blur(radius: 8).frame(width: 46).opacity(0.8)
                    BloubView(shape: .circle, color: .ink, expression: .curious).frame(width: 46)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Create a new course").font(.display(18, weight: .bold))
                    Text("Salsa, Python, Atomic Habits… anything.")
                        .font(.body(13)).foregroundStyle(Palette.muted)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Palette.ink, in: .circle)
                    .symbolEffect(.breathe)
            }
            .foregroundStyle(Palette.ink)
            .glassCard(radius: 30, tint: Palette.periwinkle, padding: 16)
        }
        .buttonStyle(.squish(0.98))
    }
}

// MARK: - Empty state

struct EmptyHomeCard: View {
    @Environment(AppRouter.self) private var router
    @State private var wave = false

    var body: some View {
        VStack(spacing: 18) {
            BloubView(shape: .circle, color: .ink, expression: wave ? .excited : .happy)
                .frame(width: 130)
                .phaseAnimator([0.0, -10.0]) { v, y in v.offset(y: y) } animation: { _ in .easeInOut(duration: 1.1) }
            Text("What do you want\nto learn?")
                .font(.display(30, weight: .heavy))
                .multilineTextAlignment(.center)
            Text("Tell ilo any goal and it builds a bite-sized path just for you.")
                .font(.body(15)).foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
            Button { router.tab = .create } label: {
                Label("Build my first path", systemImage: "sparkles")
            }
            .buttonStyle(.pill(.ink))
        }
        .padding(.vertical, 8)
        .card(Palette.periwinkleSoft, radius: 36, padding: 24)
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            wave = true
        }
    }
}
