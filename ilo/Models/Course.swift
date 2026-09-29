import Foundation

/// A full learning journey generated from one goal ("salsa for grandma's wedding").
struct Course: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    /// The raw goal typed by the learner.
    var goal: String
    /// Short, punchy title ("Salsa, wedding-ready").
    var title: String
    /// One-line promise of the course.
    var tagline: String
    /// SF Symbol that represents the topic.
    var symbol: String
    var tint: CourseTint
    var category: CourseCategory
    var level: LearnerLevel
    var motivation: String?
    var deadline: Date?
    var dailyMinutes: Int
    var units: [CourseUnit]
    /// Sources the research agent used.
    var sources: [CourseSource] = []
    var createdAt: Date = .now
    var lastOpenedAt: Date = .now

    var allNodes: [PathNode] { units.flatMap(\.nodes) }
    var lessonCount: Int { allNodes.filter { $0.kind != .chest }.count }

    func node(_ id: UUID) -> PathNode? { allNodes.first { $0.id == id } }

    func unit(containing nodeID: UUID) -> CourseUnit? { units.first { $0.nodes.contains { $0.id == nodeID } } }

    /// The node right after `id` in path order.
    func node(after id: UUID) -> PathNode? {
        let nodes = allNodes
        guard let index = nodes.firstIndex(where: { $0.id == id }), index + 1 < nodes.count else { return nil }
        return nodes[index + 1]
    }
}

struct CourseUnit: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var title: String
    /// What you'll be able to do after this unit.
    var outcome: String
    var tint: CourseTint
    var nodes: [PathNode]
}

/// One circle on the path. Its `brief` is written at plan time; its lesson is generated on demand.
struct PathNode: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var title: String
    /// What this lesson must teach — the AI's instruction for generating it on demand.
    var brief: String
    var kind: NodeKind
    var symbol: String
    var xp: Int { kind.xp }
}

enum NodeKind: String, Codable, CaseIterable, Sendable {
    /// Standard mixed lesson.
    case lesson
    /// Story-driven lesson (narrative, scenario).
    case story
    /// Hands-on practice: timer, code lab, camera coach.
    case practice
    /// Real-world mission with photo proof.
    case mission
    /// Spaced review of what came before.
    case review
    /// Unit boss battle — timed, mixed, harder.
    case boss
    /// Reward chest (gems), no lesson.
    case chest
    /// Live voice/video call with ilo.
    case call

    var xp: Int {
        switch self {
        case .lesson, .story: 15
        case .practice: 20
        case .mission: 30
        case .review: 10
        case .boss: 40
        case .chest: 0
        case .call: 25
        }
    }

    var label: String {
        switch self {
        case .lesson: "Lesson"
        case .story: "Story"
        case .practice: "Practice"
        case .mission: "Mission"
        case .review: "Review"
        case .boss: "Boss battle"
        case .chest: "Chest"
        case .call: "Live call"
        }
    }

    var defaultSymbol: String {
        switch self {
        case .lesson: "star.fill"
        case .story: "book.fill"
        case .practice: "dumbbell.fill"
        case .mission: "flag.checkered"
        case .review: "arrow.triangle.2.circlepath"
        case .boss: "crown.fill"
        case .chest: "gift.fill"
        case .call: "phone.fill"
        }
    }
}

enum CourseCategory: String, Codable, CaseIterable, Sendable {
    case movement, code, book, language, creative, skill, knowledge, wellbeing

    /// Which "real practice" modules make sense for the topic.
    var practiceModules: [ModuleType] {
        switch self {
        case .movement: [.practiceTimer, .cameraCoach, .mission]
        case .code: [.codeLab, .spotTheMistake]
        case .book: [.teachBack, .scenario, .mission]
        case .language: [.wordBricks, .liveCall, .roleplay]
        case .creative: [.mission, .practiceTimer]
        case .skill: [.mission, .practiceTimer, .scenario]
        case .knowledge: [.estimate, .categorize, .teachBack]
        case .wellbeing: [.practiceTimer, .mission, .scenario]
        }
    }
}

enum LearnerLevel: Int, Codable, CaseIterable, Sendable {
    case zero, beginner, intermediate, advanced

    var title: String {
        switch self {
        case .zero: "Total beginner"
        case .beginner: "I know a little"
        case .intermediate: "I'm getting there"
        case .advanced: "I want mastery"
        }
    }

    var detail: String {
        switch self {
        case .zero: "Start from absolute zero"
        case .beginner: "I've tried it once or twice"
        case .intermediate: "I know the basics well"
        case .advanced: "Push me to expert level"
        }
    }
}

struct CourseSource: Codable, Hashable, Sendable, Identifiable {
    var id: String { url }
    var title: String
    var url: String
}
