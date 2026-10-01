import Foundation

/// Picks the best available brain: remote (Supabase → OpenRouter) when configured, with the local brain as fallback.
enum AIRouter {
    static func make() -> LearningAI { DynamicAI() }
}

/// Resolves the brain on every call, so connecting or removing a Claude key takes effect immediately:
/// the learner's own Claude (Anthropic key) → the ilo backend (if configured) → the offline brain.
struct DynamicAI: LearningAI {
    private let local = LocalAI()

    private var current: LearningAI {
        if let key = AnthropicKeyStore.key { return FallbackAI(primary: AnthropicAI(apiKey: key), fallback: local) }
        if AppConfig.hasBackend && AppConfig.aiFunctionEnabled { return FallbackAI(primary: RemoteAI(), fallback: local) }
        return local
    }

    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        try await current.planCourse(request, onStep: onStep)
    }

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        try await current.generateLesson(course: course, node: node, context: context)
    }

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        try await current.grade(question: question, answer: answer, rubric: rubric, sample: sample)
    }

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        try await current.chat(persona: persona, goal: goal, topic: topic, history: history)
    }
}

/// Tries the primary brain, falls back to the secondary on any error (offline, quota, bad JSON…).
struct FallbackAI: LearningAI {
    let primary: LearningAI
    let fallback: LearningAI

    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        do { return try await primary.planCourse(request, onStep: onStep) }
        catch { return try await fallback.planCourse(request, onStep: onStep) }
    }

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        do { return try await primary.generateLesson(course: course, node: node, context: context) }
        catch { return try await fallback.generateLesson(course: course, node: node, context: context) }
    }

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        do { return try await primary.grade(question: question, answer: answer, rubric: rubric, sample: sample) }
        catch { return try await fallback.grade(question: question, answer: answer, rubric: rubric, sample: sample) }
    }

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        do { return try await primary.chat(persona: persona, goal: goal, topic: topic, history: history) }
        catch { return try await fallback.chat(persona: persona, goal: goal, topic: topic, history: history) }
    }
}
