import Foundation

/// Daily quest (3 per day) — resets at midnight.
struct Quest: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var kind: QuestKind
    var target: Int
    var progress: Int = 0
    var reward: Int
    var claimed = false

    var isDone: Bool { progress >= target }
    var fraction: Double { min(Double(progress) / Double(max(target, 1)), 1) }

    var title: String {
        switch kind {
        case .earnXP: "Earn \(target) XP"
        case .finishLessons: target == 1 ? "Finish a lesson" : "Finish \(target) lessons"
        case .perfectLesson: "Finish a lesson with no mistakes"
        case .comboStreak: "Get \(target) right in a row"
        case .practiceMinutes: "Learn for \(target) minutes"
        case .completeMission: "Complete a real-world mission"
        case .talkToIlo: "Have a live call with ilo"
        }
    }

    var symbol: String {
        switch kind {
        case .earnXP: "bolt.fill"
        case .finishLessons: "checkmark.seal.fill"
        case .perfectLesson: "sparkles"
        case .comboStreak: "flame.fill"
        case .practiceMinutes: "timer"
        case .completeMission: "flag.checkered"
        case .talkToIlo: "phone.fill"
        }
    }

    var tint: CourseTint {
        switch kind {
        case .earnXP: .butter
        case .finishLessons: .mint
        case .perfectLesson: .lavender
        case .comboStreak: .orange
        case .practiceMinutes: .sky
        case .completeMission: .peach
        case .talkToIlo: .orchid
        }
    }
}

enum QuestKind: String, Codable, CaseIterable, Sendable {
    case earnXP, finishLessons, perfectLesson, comboStreak, practiceMinutes, completeMission, talkToIlo
}

/// Monthly/weekly "friend quest" style challenge shared with a friend.
struct FriendQuest: Codable, Hashable, Sendable {
    var friendName: String
    var target: Int
    var mine: Int
    var theirs: Int
    var endsAt: Date
    var fraction: Double { min(Double(mine + theirs) / Double(max(target, 1)), 1) }
}

/// One row of a leaderboard.
struct LeaderboardEntry: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var shape: BloubShape
    var color: BloubColor
    var xp: Int
    var streak: Int
    var isMe: Bool
}

/// Result of a lesson, used by the completion screen and to update stats.
struct LessonResult: Sendable, Hashable {
    var nodeID: UUID
    var courseID: UUID
    var xpEarned: Int
    var bonusXP: Int
    var accuracy: Double
    var mistakes: Int
    var bestCombo: Int
    var seconds: Double
    var kind: NodeKind
    var usedModules: [ModuleType]
    var takeaways: [String]

    var isPerfect: Bool { mistakes == 0 && accuracy >= 0.999 }
    var totalXP: Int { xpEarned + bonusXP }
}
