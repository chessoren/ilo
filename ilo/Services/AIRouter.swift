import Foundation

/// Picks the best available brain: remote (Supabase → OpenRouter) when configured, with the local brain as fallback.
enum AIRouter {
    static func make() -> LearningAI {
        if AppConfig.hasBackend { return FallbackAI(primary: RemoteAI(), fallback: LocalAI()) }
        return LocalAI()
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
