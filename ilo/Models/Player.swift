import Foundation

/// The learner: identity, bloub avatar and all game stats.
struct Player: Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var bloubShape: BloubShape = .circle
    var bloubColor: BloubColor = .blue
    var totalXP: Int = 0
    var gems: Int = 50
    var streak: Int = 0
    var longestStreak: Int = 0
    var streakFreezes: Int = 1
    /// Days (start-of-day) where the daily goal was met.
    var activeDays: Set<Date> = []
    var lastActiveDay: Date? = nil
    var dailyGoalXP: Int = 30
    var streakGoal: Int = 14
    /// XP earned per day (start-of-day → xp).
    var xpByDay: [Date: Int] = [:]
    var weeklyXP: Int = 0
    var weekStart: Date = Calendar.current.startOfWeek(for: .now)
    var league: LeagueTier = .pebble
    var lessonsCompleted: Int = 0
    var perfectLessons: Int = 0
    var missionsCompleted: Int = 0
    var minutesLearned: Double = 0
    var unlockedBadges: Set<Badge> = []
    var savedTakeaways: [Takeaway] = []
    var friends: [Friend] = []
    var reminderHour: Int = 19
    var joinedAt: Date = .now

    var level: Int { PlayerLevel.level(for: totalXP) }

    func xp(on day: Date) -> Int { xpByDay[Calendar.current.startOfDay(for: day)] ?? 0 }
    var todayXP: Int { xp(on: .now) }
    var dailyGoalMet: Bool { todayXP >= dailyGoalXP }
    var isStreakActiveToday: Bool { activeDays.contains(Calendar.current.startOfDay(for: .now)) }
}

enum PlayerLevel {
    /// XP needed to reach `level` (level 1 = 0 XP). Gentle quadratic curve.
    static func xpNeeded(for level: Int) -> Int { level <= 1 ? 0 : 60 * (level - 1) * (level - 1) + 40 * (level - 1) }

    static func level(for xp: Int) -> Int {
        var level = 1
        while xpNeeded(for: level + 1) <= xp { level += 1 }
        return level
    }

    /// 0...1 progress inside the current level.
    static func progress(for xp: Int) -> Double {
        let level = level(for: xp)
        let lo = xpNeeded(for: level), hi = xpNeeded(for: level + 1)
        return Double(xp - lo) / Double(max(hi - lo, 1))
    }
}

/// Weekly leagues — one tier per bloub silhouette.
enum LeagueTier: Int, Codable, CaseIterable, Sendable, Comparable {
    case pebble, bubble, squircle, capsule, droplet, cloud, hexagon, apex

    static func < (lhs: LeagueTier, rhs: LeagueTier) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .pebble: "Pebble"
        case .bubble: "Bubble"
        case .squircle: "Squircle"
        case .capsule: "Capsule"
        case .droplet: "Droplet"
        case .cloud: "Cloud"
        case .hexagon: "Hexagon"
        case .apex: "Apex"
        }
    }

    var shape: BloubShape {
        switch self {
        case .pebble: .pebble
        case .bubble: .circle
        case .squircle: .squircle
        case .capsule: .capsule
        case .droplet: .droplet
        case .cloud: .cloud
        case .hexagon: .hexagon
        case .apex: .triangle
        }
    }

    var color: BloubColor {
        switch self {
        case .pebble: .brown
        case .bubble: .turquoise
        case .squircle: .orange
        case .capsule: .pink
        case .droplet: .blue
        case .cloud: .violet
        case .hexagon: .amber
        case .apex: .ink
        }
    }

    var next: LeagueTier? { LeagueTier(rawValue: rawValue + 1) }
    var previous: LeagueTier? { LeagueTier(rawValue: rawValue - 1) }

    /// How many players get promoted / demoted in a cohort of `size`.
    func promotionSlots(cohort size: Int) -> Int { self == .apex ? 0 : max(1, size / 5) }
    func demotionSlots(cohort size: Int) -> Int { self == .pebble ? 0 : max(1, size / 6) }
}

enum Badge: String, Codable, CaseIterable, Sendable, Identifiable {
    case firstLesson, perfectionist, streak7, streak30, missionAccomplished, nightOwl, earlyBird
    case polymath, bossSlayer, chatterbox, leagueClimber, apexPredator, coder, dancer, bookworm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstLesson: "First Steps"
        case .perfectionist: "Flawless"
        case .streak7: "On Fire"
        case .streak30: "Unstoppable"
        case .missionAccomplished: "Out There"
        case .nightOwl: "Night Owl"
        case .earlyBird: "Early Bird"
        case .polymath: "Polymath"
        case .bossSlayer: "Boss Slayer"
        case .chatterbox: "Chatterbox"
        case .leagueClimber: "Climber"
        case .apexPredator: "Apex"
        case .coder: "Hello, World"
        case .dancer: "Light Feet"
        case .bookworm: "Bookworm"
        }
    }

    var detail: String {
        switch self {
        case .firstLesson: "Finish your first lesson"
        case .perfectionist: "Finish a lesson with zero mistakes"
        case .streak7: "Reach a 7-day streak"
        case .streak30: "Reach a 30-day streak"
        case .missionAccomplished: "Complete a real-world mission"
        case .nightOwl: "Learn after 10 pm"
        case .earlyBird: "Learn before 8 am"
        case .polymath: "Learn 3 different topics"
        case .bossSlayer: "Beat a boss battle"
        case .chatterbox: "Have a live call with ilo"
        case .leagueClimber: "Get promoted to a new league"
        case .apexPredator: "Reach the Apex league"
        case .coder: "Pass a code lab"
        case .dancer: "Finish a practice session"
        case .bookworm: "Finish a book course unit"
        }
    }

    var symbol: String {
        switch self {
        case .firstLesson: "shoeprints.fill"
        case .perfectionist: "sparkles"
        case .streak7: "flame.fill"
        case .streak30: "flame.circle.fill"
        case .missionAccomplished: "flag.checkered"
        case .nightOwl: "moon.stars.fill"
        case .earlyBird: "sunrise.fill"
        case .polymath: "brain.head.profile"
        case .bossSlayer: "crown.fill"
        case .chatterbox: "phone.bubble.fill"
        case .leagueClimber: "arrow.up.forward.circle.fill"
        case .apexPredator: "triangle.fill"
        case .coder: "chevron.left.forwardslash.chevron.right"
        case .dancer: "figure.dance"
        case .bookworm: "books.vertical.fill"
        }
    }

    var tint: CourseTint {
        switch self {
        case .firstLesson, .polymath, .leagueClimber: .periwinkle
        case .perfectionist, .earlyBird: .butter
        case .streak7, .streak30: .orange
        case .missionAccomplished, .dancer: .mint
        case .nightOwl, .apexPredator: .lavender
        case .bossSlayer: .peach
        case .chatterbox, .coder: .sky
        case .bookworm: .orchid
        }
    }
}

/// A key idea saved from a lesson ("My deck").
struct Takeaway: Codable, Hashable, Sendable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var courseTitle: String
    var savedAt: Date = .now
}

struct Friend: Codable, Hashable, Sendable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var shape: BloubShape
    var color: BloubColor
    var weeklyXP: Int
    var streak: Int
}

/// Per-course progress (which nodes are done, cached lessons).
struct CourseProgress: Codable, Hashable, Sendable {
    var completed: Set<UUID> = []
    /// Stars/crowns per node: 1 = done, 2 = perfect.
    var stars: [UUID: Int] = [:]
    var openedChests: Set<UUID> = []

    func isCompleted(_ id: UUID) -> Bool { completed.contains(id) }
}

enum NodeState: Equatable {
    case locked, current, completed
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        var cal = self
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date)
    }
}
