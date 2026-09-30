import Foundation
import FoundationModels

/// Apple's on-device model (Apple Intelligence). Free, private, offline — used for goals we don't have a flagship for.
/// It writes the *primitives* (plan skeleton, story cards, questions, statements…); the `Composer` arranges them into modules.
enum OnDeviceBrain {
    static var isAvailable: Bool {
        if ProcessInfo.processInfo.arguments.contains("-noOnDeviceModel") || breaker.isOpen { return false }
        return SystemLanguageModel.default.isAvailable
    }

    /// Circuit breaker: after a timeout or failure the model is skipped for the rest of the session
    /// (on some simulators the model reports "available" but never answers).
    static let breaker = Breaker()

    /// Fires one tiny request at launch; if the model doesn't answer within 12 s, it's skipped for the session.
    static func probeOnce() { _ = probe }
    private static let probe: Void = {
        guard isAvailable else { return }
        Task.detached(priority: .background) {
            let answered = await withTimeout(seconds: 12) { () -> Bool in
                let session = LanguageModelSession(instructions: "Reply with one word.")
                return (try? await session.respond(to: "Say ready.")) != nil
            }
            if answered != true { breaker.recordFailure() }
            #if DEBUG
            print("[BRAIN] on-device model probe: \(answered == true ? "answering" : "not answering — using templates")")
            #endif
        }
    }()

    final class Breaker: @unchecked Sendable {
        private let lock = NSLock()
        private var failures = 0
        var isOpen: Bool { lock.withLock { failures >= 1 } }
        func recordFailure() { lock.withLock { failures += 1 } }
    }

    // MARK: Generable shapes

    @Generable(description: "A learning path for a goal")
    struct PlanDraft {
        @Guide(description: "Short punchy course title, max 5 words")
        var title: String
        @Guide(description: "One-line promise of the course")
        var tagline: String
        @Guide(description: "Three units, from foundations to real-world use", .count(3))
        var units: [UnitDraft]
    }

    @Generable(description: "One unit of the path")
    struct UnitDraft {
        @Guide(description: "Unit title, 2 to 5 words")
        var title: String
        @Guide(description: "What the learner can do after the unit, one sentence starting with a verb")
        var outcome: String
        @Guide(description: "Four steps, in teaching order", .count(4))
        var nodes: [NodeDraft]
    }

    @Generable(description: "One step of the path")
    struct NodeDraft {
        @Guide(description: "Step title, 1 to 4 words")
        var title: String
        @Guide(description: "Two specific sentences: what exactly to teach, with a concrete example")
        var brief: String
        @Guide(description: "The kind of step", .anyOf(["lesson", "story", "practice", "mission"]))
        var kind: String
    }

    @Generable(description: "Teaching material for one short lesson")
    struct SeedDraft {
        @Guide(description: "A friendly one-line hook, max 15 words")
        var intro: String
        @Guide(description: "Three teaching cards that explain the idea with concrete examples", .count(3))
        var cards: [CardDraft]
        @Guide(description: "Three multiple-choice questions answerable from the cards", .count(3))
        var questions: [QuestionDraft]
        @Guide(description: "Four true/false statements about the idea, mixed true and false", .count(4))
        var statements: [StatementDraft]
        @Guide(description: "Four term/meaning pairs", .count(4))
        var pairs: [PairDraft]
        @Guide(description: "Four steps of a process related to the idea, in the correct order", .count(4))
        var steps: [String]
        @Guide(description: "A sentence with the key word replaced by ___")
        var blankSentence: String
        @Guide(description: "The missing word first, then two wrong but plausible words", .count(3))
        var blankOptions: [String]
        @Guide(description: "Two short takeaways worth remembering", .count(2))
        var takeaways: [String]
    }

    @Generable struct CardDraft {
        @Guide(description: "Card title, 2 to 4 words") var title: String
        @Guide(description: "Card body, max 35 words") var body: String
    }

    @Generable struct QuestionDraft {
        var prompt: String
        @Guide(description: "Three answer options", .count(3)) var options: [String]
        @Guide(description: "Index of the correct option", .range(0...2)) var correctIndex: Int
        @Guide(description: "Why the answer is correct, one sentence") var why: String
    }

    @Generable struct StatementDraft {
        var text: String
        var isTrue: Bool
        @Guide(description: "One short sentence explaining why") var why: String
    }

    @Generable struct PairDraft {
        @Guide(description: "A term, max 4 words") var term: String
        @Guide(description: "Its meaning, max 8 words") var meaning: String
    }

    // MARK: Plan

    static func plan(_ request: CourseRequest, topic: Topic) async throws -> Course {
        let session = LanguageModelSession(instructions: """
            You are ilo, an expert curriculum designer for a Duolingo-style app that teaches anything.
            Design accurate, concrete, beginner-friendly learning paths. English. No emojis.
            """)
        var prompt = "Design a learning path for this goal: \(request.goal)."
        if let why = request.motivation?.nilIfBlank { prompt += " The learner's motivation: \(why)." }
        prompt += " Level: \(request.level.title). Daily time: \(request.dailyMinutes) minutes."
        let draft = try await session.respond(to: prompt, generating: PlanDraft.self, options: GenerationOptions(temperature: 0.6)).content

        let tints: [CourseTint] = [.periwinkle, .mint, .orchid, .sky]
        let units = draft.units.enumerated().map { index, unit -> CourseUnit in
            var nodes = unit.nodes.map { node -> PathNode in
                let kind = NodeKind(rawValue: node.kind) ?? .lesson
                return PathNode(title: String(node.title.prefix(32)), brief: node.brief, kind: kind, symbol: symbol(for: kind, index: index))
            }
            nodes.insert(PathNode(title: "Treasure chest", brief: "A reward.", kind: .chest, symbol: "gift.fill"), at: min(3, nodes.count))
            if index == 1 {
                nodes.insert(PathNode(title: "Coach call", brief: "Talk through what you've learned about \(topic.noun) out loud with ilo.",
                                      kind: .call, symbol: "phone.fill"), at: nodes.count)
            }
            if index == 2 {
                nodes.insert(PathNode(title: "Quick review", brief: "Spaced review of the whole path so far.", kind: .review,
                                      symbol: "arrow.triangle.2.circlepath"), at: nodes.count)
            }
            nodes.append(PathNode(title: "\(unit.title.split(separator: " ").first.map(String.init) ?? "Unit") boss",
                                  brief: "Mixed challenge on: \(unit.nodes.map(\.title).joined(separator: ", ")).", kind: .boss, symbol: "crown.fill"))
            return CourseUnit(title: unit.title, outcome: unit.outcome, tint: tints[index % tints.count], nodes: nodes)
        }
        let fallback = GenericBrain.course(for: request, topic: topic)
        return Course(goal: request.goal, title: draft.title.nilIfBlank ?? fallback.title, tagline: draft.tagline.nilIfBlank ?? fallback.tagline,
                      symbol: fallback.symbol, tint: .periwinkle, category: topic.category, level: request.level,
                      motivation: request.motivation, deadline: request.deadline, dailyMinutes: request.dailyMinutes,
                      units: units, sources: fallback.sources)
    }

    private static func symbol(for kind: NodeKind, index: Int) -> String {
        switch kind {
        case .lesson: ["star.fill", "lightbulb.fill", "sparkles"][index % 3]
        case .story: "book.fill"
        case .practice: "dumbbell.fill"
        case .mission: "flag.checkered"
        default: kind.defaultSymbol
        }
    }

    // MARK: Lesson material

    static func seed(course: Course, node: PathNode, topic: Topic) async throws -> KnowledgeSeed {
        let session = LanguageModelSession(instructions: """
            You are ilo, a brilliant, warm tutor. You write accurate, concrete teaching material for short app lessons.
            Every fact must be correct. Use simple words and specific examples. English. No emojis.
            """)
        let prompt = """
            Course goal: \(course.goal). Level: \(course.level.title).
            Lesson: "\(node.title)". What to teach: \(node.brief)
            Write the teaching material for this lesson.
            """
        let draft = try await session.respond(to: prompt, generating: SeedDraft.self, options: GenerationOptions(temperature: 0.5)).content

        var s = KnowledgeSeed(intro: draft.intro)
        let moods: [BloubExpression] = [.curious, .attentive, .excited]
        s.cards = draft.cards.enumerated().map { storyCard($0.element.title, $0.element.body, nil, moods[$0.offset % moods.count]) }
        s.questions = draft.questions.compactMap { q in
            guard q.options.count >= 2 else { return nil }
            return .q(q.prompt, q.options, min(max(q.correctIndex, 0), q.options.count - 1), q.why)
        }
        s.statements = draft.statements.map { .s($0.text, $0.isTrue, $0.why) }
        s.pairs = draft.pairs.map { .p($0.term, $0.meaning) }
        if draft.steps.count >= 3 { s.sequence = draft.steps; s.sequencePrompt = "Put these in the right order" }
        if draft.blankSentence.contains("___"), draft.blankOptions.count >= 2 {
            // The model lists the right answer first — shuffle it into a stable position.
            var options = draft.blankOptions
            let answer = options[0]
            var rng = SeededRNG(seed: Composer.stableHash(node.title))
            options.shuffle(using: &rng)
            s.blanks = [.b(draft.blankSentence, options, options.firstIndex(of: answer) ?? 0)]
        }
        s.flashcards = draft.pairs.map { .f($0.term, $0.meaning) }
        s.takeaways = draft.takeaways
        switch node.kind {
        case .practice: s.practice = GenericBrain.categoryPractice(topic, stage: 1)
        case .mission: s.practice = GenericBrain.fromBrief(node, topic: topic).practice
        case .call: s.practice = GenericBrain.fromBrief(node, topic: topic).practice
        case .story:
            s.practice = [.free("How would you use “\(node.title)” in your own life? Give one example.",
                                rubric: ["Gives a concrete personal example", "Connects it to the lesson's idea"],
                                sample: draft.takeaways.first ?? draft.intro)]
        default:
            s.practice = [.teach("Explain “\(node.title)” to ilo in your own words, with one example.",
                                 rubric: draft.takeaways.isEmpty ? ["Explains the idea clearly", "Gives an example"] : draft.takeaways,
                                 sample: draft.cards.map(\.body).prefix(2).joined(separator: " "))]
        }
        return s
    }
}
