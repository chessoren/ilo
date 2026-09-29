import Foundation

/// What the learner asked for during onboarding / course creation.
struct CourseRequest: Codable, Hashable, Sendable {
    var goal: String
    var motivation: String?
    var level: LearnerLevel
    var dailyMinutes: Int
    var deadline: Date?
    /// Preferred ways to learn (e.g. "stories", "quizzes", "hands-on", "voice").
    var styles: [String]
}

/// A visible step of the research agent, streamed to the "building your path" screen.
struct PlanStep: Identifiable, Hashable, Sendable {
    enum Phase: String, Sendable { case understanding, researching, designing, writing, done }
    var id = UUID()
    var phase: Phase
    var text: String
    var detail: String? = nil
}

/// Result of an AI-graded open answer.
struct Grade: Codable, Hashable, Sendable {
    /// 0...1
    var score: Double
    var passed: Bool
    var feedback: String
    var improved: String?
}

struct ChatMessage: Codable, Hashable, Sendable, Identifiable {
    enum Role: String, Codable, Sendable { case user, ilo }
    var id = UUID()
    var role: Role
    var text: String
}

/// Context passed to lesson generation so lessons adapt to the learner.
struct LessonContext: Codable, Hashable, Sendable {
    var level: LearnerLevel
    var previousTitles: [String]
    var recentMistakes: [String]
    var preferredStyles: [String]
}

/// The AI brain of ilo. Implemented remotely (Supabase edge function → OpenRouter) and locally (offline fallback).
protocol LearningAI: Sendable {
    /// Researches the goal and designs the full path (units + node briefs). Lessons are NOT generated here.
    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course
    /// Generates one lesson on demand from a node brief.
    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson
    /// Grades a free-form answer against a rubric.
    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade
    /// One conversational turn for roleplay / live call.
    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String
}

enum AIError: LocalizedError {
    case notConfigured
    case badResponse(String)
    case offline

    var errorDescription: String? {
        switch self {
        case .notConfigured: "The AI backend isn't configured yet."
        case .badResponse(let why): "ilo got confused: \(why)"
        case .offline: "You're offline."
        }
    }
}
