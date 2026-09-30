import Foundation

/// Offline brain: hand-crafted flagship courses for demo topics, Apple's on-device model for anything else,
/// and a template composer when neither applies. Never needs a network connection.
struct LocalAI: LearningAI {
    /// Speeds up the building-screen choreography (tests / self-test).
    var pace: Double = 1
    /// Use Apple's on-device model for non-flagship goals when available.
    var allowOnDevice = true

    init(pace: Double = 1, allowOnDevice: Bool = true) {
        self.pace = pace
        self.allowOnDevice = allowOnDevice
        if allowOnDevice { OnDeviceBrain.probeOnce() }
        #if DEBUG
        BrainSelfTest.startIfRequested()
        #endif
    }

    private var onDevice: Bool { allowOnDevice && OnDeviceBrain.isAvailable }

    // MARK: Plan

    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        let goal = request.goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goal.isEmpty else { throw AIError.badResponse("Tell ilo what you want to learn first.") }

        let step: @Sendable (PlanStep.Phase, String, String?, Double) async -> Void = { phase, text, detail, seconds in
            onStep(PlanStep(phase: phase, text: text, detail: detail))
            try? await Task.sleep(for: .seconds(seconds * pace))
        }

        await step(.understanding, "Understanding your goal", "“\(goal.prefix(70))”", 0.9)
        if let why = request.motivation?.nilIfBlank {
            await step(.understanding, "Noting why it matters to you", String(why.prefix(70)), 0.6)
        }

        if let flagship = FlagshipCatalog.match(goal) {
            for note in flagship.researchNotes.prefix(1) { await step(.understanding, note, nil, 0.5) }
            await step(.researching, "Opening ilo's expert library", "curated, offline", 0.7)
            for source in flagship.sources.prefix(4) {
                await step(.researching, "Drawing on \(source.title)", host(source.url), 0.55)
            }
            for note in flagship.researchNotes.dropFirst().prefix(2) { await step(.researching, note, nil, 0.5) }
            await step(.designing, "Mapping the skill tree", "\(flagship.units.count) units", 0.6)
            for (i, unit) in flagship.units.enumerated() {
                await step(.designing, "Unit \(i + 1): \(unit.title)", unit.outcome, 0.45)
            }
            let steps = flagship.allNodes.filter { $0.kind != .chest }.count
            await step(.writing, "Writing lesson briefs", "\(steps) steps", 0.6)
            await step(.writing, "Hand-crafting your first lessons", nil, 0.6)
            onStep(PlanStep(phase: .done, text: "Your path is ready"))
            return flagship.course(for: request)
        }

        // Generic goal: let the on-device model design the path while the building screen plays.
        let topic = Topic(goal)
        let draft: Task<Course?, Never>? = onDevice
            ? Task { try? await OnDeviceBrain.plan(request, topic: topic) }
            : nil

        await step(.researching, "Searching for the best way in", topic.shortTitle, 0.7)
        await step(.researching, "Recalling the fundamentals", topic.shortTitle, 0.6)
        await step(.researching, "Checking the learning science", "deliberate practice · spacing · retrieval", 0.7)
        await step(.researching, "Collecting beginner mistakes to avoid", nil, 0.6)
        await step(.designing, "Mapping the skill tree", "\(topic.category.rawValue) · \(request.level.title.lowercased())", 0.7)

        var course: Course?
        if let draft {
            await step(.designing, "Designing with on-device intelligence", "private · runs on your iPhone", 0.3)
            // Keep the building screen alive while the on-device model works (up to ~25 s).
            let heartbeat = Task {
                let beats = ["Sequencing the skills", "Writing clear briefs", "Balancing lessons and practice", "Adding real-world missions", "Double-checking the path"]
                for beat in beats {
                    try await Task.sleep(for: .seconds(4))
                    onStep(PlanStep(phase: .designing, text: beat))
                }
            }
            course = await withTimeout(seconds: 25) { await draft.value } ?? nil
            heartbeat.cancel()
            if course == nil { draft.cancel(); OnDeviceBrain.breaker.recordFailure() }
        }
        let final = course ?? GenericBrain.course(for: request, topic: topic)
        for (i, unit) in final.units.enumerated() {
            await step(.designing, "Unit \(i + 1): \(unit.title)", unit.outcome, 0.45)
        }
        await step(.writing, "Writing lesson briefs", "\(final.allNodes.filter { $0.kind != .chest }.count) steps", 0.6)
        onStep(PlanStep(phase: .done, text: "Your path is ready"))
        return final
    }

    // MARK: Lessons

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        if node.kind == .chest { throw AIError.badResponse("Chests don't have lessons.") }

        if let flagship = FlagshipCatalog.flagship(for: course), let lesson = flagship.lesson(for: node, goal: course.goal) {
            return lesson
        }

        let topic = Topic(course.goal)
        let isTemplated = GenericBrain.isTemplateNode(node.title)
        if !isTemplated, node.kind != .review, node.kind != .boss, onDevice {
            let seed = await withTimeout(seconds: 40) { try? await OnDeviceBrain.seed(course: course, node: node, topic: topic) } ?? nil
            if seed == nil { OnDeviceBrain.breaker.recordFailure() }
            if let seed {
                let nodes = course.allNodes
                let index = nodes.firstIndex { $0.id == node.id } ?? 0
                let earlier = nodes[..<index].filter { $0.kind != .chest }.suffix(3).map { GenericBrain.seed(for: $0, course: course, topic: topic) }
                let lesson = Composer.compose(title: node.title, kind: node.kind, seed: seed, earlier: Array(earlier), nodeID: node.id,
                                              author: "ilo · on-device")
                if lesson.modules.count >= 4 { return lesson }
            }
        }
        return GenericBrain.lesson(course: course, node: node)
    }

    // MARK: Grade + chat

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        try? await Task.sleep(for: .milliseconds(Int(700 * pace)))
        return OfflineTutor.grade(question: question, answer: answer, rubric: rubric, sample: sample)
    }

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        try? await Task.sleep(for: .milliseconds(Int(900 * pace)))
        return OfflineTutor.chat(persona: persona, goal: goal, topic: topic, history: history)
    }

    private func host(_ url: String) -> String? {
        URL(string: url)?.host()?.replacingOccurrences(of: "www.", with: "")
    }
}

extension GenericBrain {
    static let templateTitles: Set<String> = [
        "Your why", "Picture the pro", "The first tiny win", "Set up your space", "Deliberate practice", "Feedback loops",
        "Remember it for good", "Practice sprint", "Coach call", "Beat the plateau", "Teach it to own it", "Real-world mission",
    ]
    static func isTemplateNode(_ title: String) -> Bool { templateTitles.contains(title) }
}

/// Runs `work`, returning nil if it takes longer than `seconds` (without waiting for `work` to notice cancellation).
func withTimeout<T: Sendable>(seconds: Double, _ work: @escaping @Sendable () async -> T) async -> T? {
    let race = Race<T>()
    return await withCheckedContinuation { continuation in
        race.arm(continuation)
        let worker = Task { race.finish(await work()) }
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            if race.finish(nil) { worker.cancel() }
        }
    }
}

/// First caller wins; later results are dropped.
private final class Race<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T?, Never>?

    func arm(_ continuation: CheckedContinuation<T?, Never>) {
        lock.withLock { self.continuation = continuation }
    }

    @discardableResult
    func finish(_ value: T?) -> Bool {
        let pending = lock.withLock { () -> CheckedContinuation<T?, Never>? in
            defer { continuation = nil }
            return continuation
        }
        pending?.resume(returning: value)
        return pending != nil
    }
}
