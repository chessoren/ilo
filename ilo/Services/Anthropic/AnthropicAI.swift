import Foundation

/// ilo's brain running on the learner's own Claude (their Anthropic API key).
/// Planning = a web-research call, then a structured-output call that designs the path
/// (citations and structured outputs can't share one request).
struct AnthropicAI: LearningAI {
    let client: AnthropicClient

    init(apiKey: String) { client = AnthropicClient(apiKey: apiKey) }

    // MARK: Plan

    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        onStep(PlanStep(phase: .understanding, text: "Understanding your goal", detail: String(request.goal.prefix(70))))
        onStep(PlanStep(phase: .researching, text: "Claude is researching the web", detail: "live search"))

        let research = try await client.send(
            system: AnthropicPrompts.researchSystem,
            messages: [["role": "user", "content": AnthropicPrompts.planUser(request)]],
            effort: "high", maxTokens: 12000, webSearch: 5)
        for source in research.sources.prefix(6) {
            onStep(PlanStep(phase: .researching, text: "Read \(source.title)", detail: URL(string: source.url)?.host()))
        }

        onStep(PlanStep(phase: .designing, text: "Designing your path", detail: "units, nodes and briefs"))
        let design = try await client.send(
            system: AnthropicPrompts.planSystem,
            messages: [["role": "user", "content": AnthropicPrompts.planUser(request)
                        + "\n\nRESEARCH NOTES (from live web search):\n\(research.text.prefix(12000))"]],
            effort: "medium", maxTokens: 16000, schema: AnthropicPrompts.courseSchema)
        guard let data = design.text.jsonObjectSlice else { throw AnthropicClient.Failure.malformed }
        let dto = try JSONDecoder().decode(Wire.CourseDTO.self, from: data)
        var course = dto.course(for: request)
        // Prefer the pages the search actually returned over anything restated in the design.
        if !research.sources.isEmpty { course.sources = Array(research.sources.prefix(6)) }
        guard course.allNodes.count >= 4 else { throw AnthropicClient.Failure.malformed }
        for (i, unit) in course.units.enumerated() {
            onStep(PlanStep(phase: .designing, text: "Unit \(i + 1): \(unit.title)", detail: unit.outcome))
        }
        onStep(PlanStep(phase: .writing, text: "Writing lesson briefs", detail: "\(course.lessonCount) steps"))
        onStep(PlanStep(phase: .done, text: "Your path is ready"))
        return course
    }

    // MARK: Lesson

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        let reply = try await client.send(
            system: AnthropicPrompts.lessonSystem,
            messages: [["role": "user", "content": AnthropicPrompts.lessonUser(course: course, node: node, context: context)]],
            effort: "medium", maxTokens: 16000)
        guard let data = reply.text.jsonObjectSlice else { throw AnthropicClient.Failure.malformed }
        let dto = try JSONDecoder().decode(Wire.LessonDTO.self, from: data)
        return try dto.lesson(for: node, by: "Claude")
    }

    // MARK: Grade

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        let user = """
        QUESTION: \(question)
        RUBRIC: \(rubric.isEmpty ? "accuracy, clarity, a concrete example" : rubric.joined(separator: " | "))
        \(sample.map { "REFERENCE ANSWER: \($0)" } ?? "")
        LEARNER'S ANSWER: \(answer.prefix(3000))
        """
        let reply = try await client.send(system: AnthropicPrompts.gradeSystem,
                                          messages: [["role": "user", "content": user]],
                                          effort: "low", maxTokens: 4000, schema: AnthropicPrompts.gradeSchema, timeout: 60)
        guard let data = reply.text.jsonObjectSlice else { throw AnthropicClient.Failure.malformed }
        let dto = try JSONDecoder().decode(Wire.GradeDTO.self, from: data)
        let score = min(max(dto.score, 0), 1)
        return Grade(score: score, passed: dto.passed ?? (score >= 0.6),
                     feedback: dto.feedback ?? "Nice effort!", improved: dto.improved)
    }

    // MARK: Chat

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        // The API needs a user turn first and alternating roles: merge consecutive turns from the same side.
        var messages: [[String: Any]] = []
        for turn in history.suffix(16) {
            let role = turn.role == .user ? "user" : "assistant"
            if let last = messages.last, last["role"] as? String == role, let text = last["content"] as? String {
                messages[messages.count - 1]["content"] = text + "\n" + turn.text
            } else {
                messages.append(["role": role, "content": turn.text])
            }
        }
        if messages.first?["role"] as? String != "user" {
            messages.insert(["role": "user", "content": "(The learner joined the conversation.)"], at: 0)
        }
        if messages.last?["role"] as? String != "user" {
            messages.append(["role": "user", "content": "(The learner is listening. Continue.)"])
        }
        let reply = try await client.send(system: AnthropicPrompts.chatSystem(persona: persona, goal: goal, topic: topic),
                                          messages: messages, effort: "low", maxTokens: 2000, timeout: 45)
        guard let text = reply.text.nilIfBlank else { throw AnthropicClient.Failure.malformed }
        return text
    }
}
