import Foundation

/// Calls the Supabase edge function `ilo-ai`, which routes to OpenRouter models server-side.
/// The OpenRouter key never ships in the app.
struct RemoteAI: LearningAI {
    var client: SupabaseClient = .shared
    private static let function = "ilo-ai"

    // MARK: Payloads

    private struct PlanBody: Encodable, Sendable {
        struct Request: Encodable, Sendable {
            var goal: String
            var motivation: String?
            var level: Int
            var dailyMinutes: Int
            var deadline: Date?
            var styles: [String]
        }
        var action = "plan"
        var stream = true
        var request: Request
    }

    private struct LessonBody: Encodable, Sendable {
        struct CourseInfo: Encodable, Sendable {
            var goal, title, category: String
            var level: Int
            var motivation: String?
        }
        struct UnitInfo: Encodable, Sendable { var title, outcome: String }
        struct NodeInfo: Encodable, Sendable { var title, brief, kind: String }
        var action = "lesson"
        var course: CourseInfo
        var unit: UnitInfo?
        var node: NodeInfo
        var context: LessonContext
    }

    private struct GradeBody: Encodable, Sendable {
        var action = "grade"
        var question, answer: String
        var rubric: [String]
        var sample: String?
    }

    private struct ChatBody: Encodable, Sendable {
        struct Turn: Encodable, Sendable { var role, text: String }
        var action = "chat"
        var persona, goal, topic: String
        var history: [Turn]
    }

    // MARK: LearningAI

    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        let body = PlanBody(request: .init(goal: request.goal, motivation: request.motivation, level: request.level.rawValue,
                                           dailyMinutes: request.dailyMinutes, deadline: request.deadline, styles: request.styles))
        let result = CourseBox()
        try await client.stream(function: Self.function, body: body) { event in
            switch event.name {
            case "step":
                if let step = try? JSONDecoder().decode(Wire.StepDTO.self, from: event.data) {
                    onStep(PlanStep(phase: PlanStep.Phase(rawValue: step.phase) ?? .researching, text: step.text, detail: step.detail))
                }
            case "course":
                await result.set(try JSONDecoder().decode(Wire.CourseDTO.self, from: event.data))
            case "error":
                let message = (try? JSONDecoder().decode(Wire.ErrorDTO.self, from: event.data))?.error ?? "planning failed"
                throw AIError.badResponse(message)
            default:
                break
            }
        }
        guard let dto = await result.value else { throw AIError.badResponse("the stream ended without a course") }
        let course = dto.course(for: request)
        guard course.allNodes.count >= 4 else { throw AIError.badResponse("the path was too short") }
        return course
    }

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        let unit = course.unit(containing: node.id)
        let body = LessonBody(course: .init(goal: course.goal, title: course.title, category: course.category.rawValue,
                                            level: course.level.rawValue, motivation: course.motivation),
                              unit: unit.map { .init(title: $0.title, outcome: $0.outcome) },
                              node: .init(title: node.title, brief: node.brief, kind: node.kind.rawValue),
                              context: context)
        let data = try await client.invoke(function: Self.function, body: body, timeout: 150)
        let dto = try JSONDecoder().decode(Wire.LessonDTO.self, from: data)
        return try dto.lesson(for: node, by: "ilo · cloud")
    }

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        let data = try await client.invoke(function: Self.function,
                                           body: GradeBody(question: question, answer: answer, rubric: rubric, sample: sample),
                                           timeout: 45)
        let dto = try JSONDecoder().decode(Wire.GradeDTO.self, from: data)
        let score = min(max(dto.score, 0), 1)
        return Grade(score: score, passed: dto.passed ?? (score >= 0.6),
                     feedback: dto.feedback ?? "Nice effort!", improved: dto.improved)
    }

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        let turns = history.suffix(16).map { ChatBody.Turn(role: $0.role.rawValue, text: $0.text) }
        let data = try await client.invoke(function: Self.function,
                                           body: ChatBody(persona: persona, goal: goal, topic: topic, history: Array(turns)),
                                           timeout: 30)
        let reply = try JSONDecoder().decode(Wire.ChatDTO.self, from: data).reply
        guard let text = reply.nilIfBlank else { throw AIError.badResponse("empty reply") }
        return text
    }
}

/// Collects the course event from the SSE callback.
private actor CourseBox {
    var value: Wire.CourseDTO?
    func set(_ dto: Wire.CourseDTO) { value = dto }
}
