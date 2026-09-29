import Foundation

/// Calls the Supabase edge function `ilo-ai`, which routes to OpenRouter models server-side.
/// The OpenRouter key never ships in the app.
struct RemoteAI: LearningAI {
    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        throw AIError.notConfigured
    }

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        throw AIError.notConfigured
    }

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        throw AIError.notConfigured
    }

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        throw AIError.notConfigured
    }
}
