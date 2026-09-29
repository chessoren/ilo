import Foundation

/// Offline brain: curated courses for demo topics + template composer for anything else.
struct LocalAI: LearningAI {
    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        onStep(PlanStep(phase: .understanding, text: "Understanding your goal"))
        try await Task.sleep(for: .seconds(1))
        let nodes = (1...5).map { PathNode(title: "Step \($0)", brief: "Basics of \(request.goal)", kind: .lesson, symbol: "star.fill") }
        return Course(goal: request.goal, title: request.goal.capitalized, tagline: "Your path", symbol: "sparkles",
                      tint: .periwinkle, category: .skill, level: request.level, motivation: request.motivation,
                      deadline: request.deadline, dailyMinutes: request.dailyMinutes,
                      units: [CourseUnit(title: "Unit 1", outcome: "Get started", tint: .periwinkle, nodes: nodes)])
    }

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        Lesson(nodeID: node.id, title: node.title, intro: "Let's go!", modules: [
            LessonModule(type: .multipleChoice, prompt: "Ready?", options: ["Yes", "No"], correctIndex: 0)
        ])
    }

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        Grade(score: 1, passed: true, feedback: "Nice!", improved: nil)
    }

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        "Tell me more!"
    }
}
