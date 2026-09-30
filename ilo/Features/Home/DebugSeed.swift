import SwiftUI

#if DEBUG
/// Demo data for development & screenshots. Launch with `-seedDemo` (and optionally `-demoTab quests|leagues|profile|create|path`).
@MainActor
enum DebugSeed {
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains("-seedDemo") }

    static var requestedTab: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-demoTab"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func arg(_ name: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// `-demoAction <name>` — lets screenshots reach sheets/popovers without touch input.
    static func action(_ name: String) -> Bool { arg("-demoAction") == name }

    static func apply(to model: AppModel) {
        model.reset()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // Courses
        let salsa = salsaCourse()
        let python = Course(goal: "Code my first website", title: "My first website", tagline: "From zero to a live page you built yourself",
                            symbol: "chevron.left.forwardslash.chevron.right", tint: .sky, category: .code, level: .zero,
                            dailyMinutes: 10, units: [
                                CourseUnit(title: "Hello, HTML", outcome: "Write a page with headings, text and links", tint: .sky, nodes: [
                                    PathNode(title: "What is a web page?", brief: "Explain how a browser turns HTML into a page.", kind: .story, symbol: "globe"),
                                    PathNode(title: "Your first tags", brief: "Headings, paragraphs and links.", kind: .lesson, symbol: "chevron.left.forwardslash.chevron.right"),
                                    PathNode(title: "Code lab: About me", brief: "Build a tiny about-me page.", kind: .practice, symbol: "hammer.fill"),
                                    PathNode(title: "Chest", brief: "", kind: .chest, symbol: "gift.fill"),
                                    PathNode(title: "HTML boss", brief: "Mixed challenge on tags and structure.", kind: .boss, symbol: "crown.fill"),
                                ]),
                            ])
        let habits = Course(goal: "Atomic Habits", title: "Atomic Habits", tagline: "Tiny changes, remarkable results",
                            symbol: "book.fill", tint: .orchid, category: .book, level: .beginner,
                            dailyMinutes: 10, units: [
                                CourseUnit(title: "The surprising power of 1%", outcome: "Explain why small habits compound", tint: .orchid, nodes: [
                                    PathNode(title: "1% better every day", brief: "The maths of compounding habits.", kind: .story, symbol: "chart.line.uptrend.xyaxis"),
                                    PathNode(title: "Systems over goals", brief: "Why goals fail and systems win.", kind: .lesson, symbol: "gearshape.2.fill"),
                                    PathNode(title: "Identity habits", brief: "Become the person, not the result.", kind: .lesson, symbol: "person.fill"),
                                    PathNode(title: "Mission: habit stack", brief: "Stack one new habit on an existing one today.", kind: .mission, symbol: "flag.checkered"),
                                ]),
                            ])
        model.add(habits, activate: false)
        model.add(python, activate: false)
        model.add(salsa, activate: true)

        // Progress on salsa: unit 1 done, 2 nodes of unit 2 done.
        var prog = CourseProgress()
        let unit1 = salsa.units[0].nodes
        for (i, n) in unit1.enumerated() {
            prog.completed.insert(n.id)
            if n.kind == .chest { prog.openedChests.insert(n.id) } else { prog.stars[n.id] = i % 2 == 0 ? 2 : 1 }
        }
        for n in salsa.units[1].nodes.prefix(2) { prog.completed.insert(n.id); prog.stars[n.id] = 1 }
        model.progress[salsa.id] = prog
        var habitsProg = CourseProgress()
        for n in habits.allNodes.prefix(1) { habitsProg.completed.insert(n.id); habitsProg.stars[n.id] = 2 }
        model.progress[habits.id] = habitsProg
        model.prefetch(course: salsa, after: salsa.units[1].nodes[1].id)

        // Player
        var p = model.player
        p.name = "Sophia"
        p.bloubShape = .squircle
        p.bloubColor = .violet
        p.gems = 340
        p.streak = 12
        p.longestStreak = 21
        p.league = .squircle
        p.lessonsCompleted = 23
        p.perfectLessons = 9
        p.minutesLearned = 186
        p.joinedAt = cal.date(byAdding: .day, value: -40, to: today) ?? today
        let history = [0, 45, 30, 60, 15, 50, 35, 40, 25, 55, 30, 45]
        for (i, xp) in history.enumerated() where i > 0 {
            let day = cal.date(byAdding: .day, value: -i, to: today) ?? today
            p.xpByDay[day] = xp
            p.activeDays.insert(day)
        }
        p.xpByDay[today] = 18
        p.activeDays.insert(today)
        p.lastActiveDay = today
        p.totalXP = 640
        p.weeklyXP = (0..<7).reduce(0) { acc, i in
            let d = cal.date(byAdding: .day, value: -i, to: today) ?? today
            return d >= cal.startOfWeek(for: .now) ? acc + (p.xpByDay[d] ?? 0) : acc
        }
        p.unlockedBadges = [.firstLesson, .perfectionist, .streak7, .nightOwl, .bossSlayer, .dancer]
        p.friends = [
            Friend(name: "Maya", shape: .cloud, color: .orange, weeklyXP: 210, streak: 30),
            Friend(name: "Leo", shape: .pebble, color: .green, weeklyXP: 95, streak: 4),
            Friend(name: "Inès", shape: .droplet, color: .pink, weeklyXP: 160, streak: 12),
        ]
        p.savedTakeaways = [
            Takeaway(text: "Salsa basic: quick-quick-slow, break on 1 and 5.", courseTitle: "Salsa, wedding-ready"),
            Takeaway(text: "Lead with your frame, not your arms.", courseTitle: "Salsa, wedding-ready"),
            Takeaway(text: "Habits are the compound interest of self-improvement.", courseTitle: "Atomic Habits"),
            Takeaway(text: "Every action is a vote for the person you want to become.", courseTitle: "Atomic Habits"),
            Takeaway(text: "Count the music: 1-2-3, 5-6-7 with pauses on 4 and 8.", courseTitle: "Salsa, wedding-ready"),
        ]
        model.player = p

        // Quests
        model.refreshDailyState()
        if model.quests.count >= 3 {
            model.quests[0].progress = 18
            model.quests[1].progress = 2
            model.quests[2].progress = 0
        }
        model.friendQuest = FriendQuest(friendName: "Maya", target: 300, mine: 120, theirs: 85,
                                        endsAt: cal.date(byAdding: .day, value: 7, to: cal.startOfWeek(for: .now)) ?? .now)
        model.hasOnboarded = true
        if ProcessInfo.processInfo.arguments.contains("-demoEmpty") {
            for c in model.courses { model.delete(c) }
            model.player.xpByDay[today] = nil
        }
        model.save()
    }

    private static func salsaCourse() -> Course {
        Course(goal: "Salsa for my grandma's wedding", title: "Salsa, wedding-ready",
               tagline: "Dance the basics with confidence in 3 weeks", symbol: "figure.dance", tint: .orange,
               category: .movement, level: .zero, motivation: "Grandma's wedding", dailyMinutes: 10,
               units: [
                CourseUnit(title: "Feel the beat", outcome: "Count salsa music and step on time", tint: .mint, nodes: [
                    PathNode(title: "What makes salsa, salsa", brief: "The story of salsa and its 8-count rhythm. Why the pauses matter.", kind: .story, symbol: "music.note"),
                    PathNode(title: "Counting 1-2-3, 5-6-7", brief: "Learn to hear the count in real songs.", kind: .lesson, symbol: "metronome.fill"),
                    PathNode(title: "Basic step drill", brief: "Practice the forward-back basic with a metronome.", kind: .practice, symbol: "figure.walk"),
                    PathNode(title: "Chest", brief: "", kind: .chest, symbol: "gift.fill"),
                    PathNode(title: "Rhythm review", brief: "Mixed review of timing and counts.", kind: .review, symbol: "arrow.triangle.2.circlepath"),
                    PathNode(title: "Beat boss", brief: "Timed challenge: find the 1 in five songs.", kind: .boss, symbol: "crown.fill"),
                ]),
                CourseUnit(title: "Lead & follow", outcome: "Dance the basic with a partner", tint: .orange, nodes: [
                    PathNode(title: "Frame and connection", brief: "How partners communicate through the frame.", kind: .lesson, symbol: "hands.clap.fill"),
                    PathNode(title: "The right turn", brief: "Your first turn: prep on 1, turn on 5.", kind: .lesson, symbol: "arrow.clockwise"),
                    PathNode(title: "Call ilo: practice the count", brief: "Live call where ilo counts with you.", kind: .call, symbol: "phone.fill"),
                    PathNode(title: "Turn practice", brief: "Camera coach checks your turn.", kind: .practice, symbol: "camera.fill"),
                    PathNode(title: "Chest", brief: "", kind: .chest, symbol: "gift.fill"),
                    PathNode(title: "Mission: dance with someone", brief: "Dance one song with a friend or family member.", kind: .mission, symbol: "flag.checkered"),
                    PathNode(title: "Partner boss", brief: "Mixed challenge on leading, following and turns.", kind: .boss, symbol: "crown.fill"),
                ]),
                CourseUnit(title: "Wedding floor", outcome: "Shine on the dance floor for a full song", tint: .orchid, nodes: [
                    PathNode(title: "Styling basics", brief: "Arms, shoulders and a confident smile.", kind: .lesson, symbol: "sparkles"),
                    PathNode(title: "A story on the dance floor", brief: "A scenario: the DJ plays a fast song.", kind: .story, symbol: "book.fill"),
                    PathNode(title: "Combo practice", brief: "Chain basic, turn and cross-body lead.", kind: .practice, symbol: "figure.dance"),
                    PathNode(title: "Full review", brief: "Spaced review of everything so far.", kind: .review, symbol: "arrow.triangle.2.circlepath"),
                    PathNode(title: "Final boss: the wedding", brief: "Dance a full song, start to finish.", kind: .boss, symbol: "crown.fill"),
                ]),
               ],
               sources: [
                CourseSource(title: "Salsa basics for beginners", url: "https://en.wikipedia.org/wiki/Salsa_(dance)"),
                CourseSource(title: "Clave rhythm explained", url: "https://en.wikipedia.org/wiki/Clave_(rhythm)"),
               ])
    }
}

/// Apply at the root while testing: seeds demo data and bypasses onboarding/paywall when launched with `-seedDemo`.
struct DemoSeedHook: ViewModifier {
    @Environment(AppModel.self) private var model
    @Environment(PurchaseService.self) private var store
    @State private var done = false

    func body(content: Content) -> some View {
        content.task {
            guard !done, DebugSeed.isRequested else { return }
            done = true
            DebugSeed.apply(to: model)
            store.isPro = true
        }
    }
}
#endif

#if DEBUG
/// `-demoScroll <y>` scrolls tagged scroll views after launch (screenshots).
struct DemoScroll: ViewModifier {
    @State private var position = ScrollPosition(edge: .top)

    func body(content: Content) -> some View {
        content
            .scrollPosition($position)
            .task {
                guard let y = DebugSeed.arg("-demoScroll").flatMap(Double.init) else { return }
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation { position.scrollTo(y: y) }
            }
    }
}
#endif

extension View {
    @ViewBuilder func demoScrollable() -> some View {
        #if DEBUG
        modifier(DemoScroll())
        #else
        self
        #endif
    }

    /// DEBUG-only demo hook (no-op in release). Attach to RootView's body to enable `-seedDemo`.
    @ViewBuilder func demoSeedHook() -> some View {
        #if DEBUG
        modifier(DemoSeedHook())
        #else
        self
        #endif
    }
}
