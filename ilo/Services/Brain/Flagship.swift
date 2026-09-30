import Foundation

/// A hand-crafted course that ships in the app (demo topics that must be perfect offline).
struct Flagship: Sendable {
    enum Content: Sendable {
        /// A fully hand-written lesson.
        case lesson(intro: String, modules: [LessonModule], takeaways: [String])
        /// Hand-written material, arranged by the composer for the node kind.
        case seed(KnowledgeSeed)
        /// Review / boss built from the earlier nodes' material.
        case review(intro: String)
        /// Chest nodes have no lesson.
        case none
    }

    struct Node: Sendable {
        var title: String
        var brief: String
        var kind: NodeKind
        var symbol: String
        var content: Content
    }

    struct Unit: Sendable {
        var title: String
        var outcome: String
        var tint: CourseTint
        var nodes: [Node]
    }

    var id: String
    var title: String
    var tagline: String
    var symbol: String
    var tint: CourseTint
    var category: CourseCategory
    /// Words that strongly suggest this course (+6 each).
    var strong: [String]
    /// Words that suggest it (+3 each).
    var keywords: [String]
    /// Words that point elsewhere (−5 each), e.g. "python" for the HTML course.
    var excludes: [String] = []
    /// Phrases that match on their own (e.g. "atomic habits").
    var phrases: [String]
    var units: [Unit]
    var sources: [CourseSource]
    /// Extra "understanding / researching" lines for the building screen.
    var researchNotes: [String]
    /// `{placeholder}` values derived from the goal (e.g. {event} → "the wedding").
    var placeholders: @Sendable (String) -> [String: String] = { _ in [:] }

    func personalize(_ text: String, goal: String) -> String {
        let values = placeholders(goal)
        guard !values.isEmpty, text.contains("{") else { return text }
        var out = text
        for (key, value) in values { out = out.replacingOccurrences(of: "{\(key)}", with: value) }
        return out
    }

    /// Applies placeholders to every string in a lesson (via its JSON form).
    func personalize(_ lesson: Lesson, goal: String) -> Lesson {
        guard !placeholders(goal).isEmpty,
              let data = try? JSONEncoder().encode(lesson),
              let json = String(data: data, encoding: .utf8) else { return lesson }
        let replaced = personalize(json, goal: goal)
        return (try? JSONDecoder().decode(Lesson.self, from: Data(replaced.utf8))) ?? lesson
    }

    var allNodes: [Node] { units.flatMap(\.nodes) }

    /// A fresh course (new ids) personalised with the learner's request.
    func course(for request: CourseRequest) -> Course {
        let p = { (text: String) in personalize(text, goal: request.goal) }
        return Course(goal: request.goal, title: p(title), tagline: p(tagline), symbol: symbol, tint: tint, category: category,
                      level: request.level, motivation: request.motivation, deadline: request.deadline,
                      dailyMinutes: request.dailyMinutes,
                      units: units.map { unit in
                          CourseUnit(title: p(unit.title), outcome: p(unit.outcome), tint: unit.tint,
                                     nodes: unit.nodes.map { PathNode(title: p($0.title), brief: p($0.brief), kind: $0.kind, symbol: $0.symbol) })
                      },
                      sources: sources)
    }

    /// Builds the lesson for a node of a course created from this flagship.
    func lesson(for node: PathNode, goal: String) -> Lesson? {
        rawLesson(for: node, goal: goal).map { personalize($0, goal: goal) }
    }

    private func rawLesson(for node: PathNode, goal: String) -> Lesson? {
        let nodes = allNodes
        guard let index = nodes.firstIndex(where: { personalize($0.title, goal: goal) == node.title }) else { return nil }
        let earlier = nodes[..<index].compactMap(\.harvest)
        switch nodes[index].content {
        case .lesson(let intro, let modules, let takeaways):
            return Lesson(nodeID: node.id, title: node.title, intro: intro,
                          modules: modules.map { var m = $0; m.id = UUID(); return m },
                          takeaways: takeaways, generatedBy: "ilo · handcrafted")
        case .seed(let seed):
            return Composer.compose(title: node.title, kind: node.kind, seed: seed, earlier: earlier, nodeID: node.id,
                                    author: "ilo · handcrafted")
        case .review(let intro):
            var seed = KnowledgeSeed(intro: intro)
            seed.takeaways = earlier.last?.takeaways ?? []
            return Composer.compose(title: node.title, kind: node.kind, seed: seed, earlier: earlier, nodeID: node.id,
                                    author: "ilo · handcrafted")
        case .none:
            return nil
        }
    }

    /// 0…n match score for a goal.
    func score(_ goal: String) -> Int {
        let text = " " + goal.lowercased().folding(options: .diacriticInsensitive, locale: .current) + " "
        var score = phrases.contains { text.contains($0) } ? 10 : 0
        let words = Set(text.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        func has(_ word: String) -> Bool { words.contains(word) || (word.count > 5 && text.contains(word)) }
        score += strong.filter(has).count * 6
        score += keywords.filter(has).count * 3
        score -= excludes.filter(has).count * 5
        return score
    }
}

extension Flagship.Node {
    /// Material this node contributes to later reviews and boss battles.
    var harvest: KnowledgeSeed? {
        switch content {
        case .lesson(let intro, let modules, let takeaways): KnowledgeSeed(harvesting: modules, intro: intro, takeaways: takeaways)
        case .seed(let seed): seed
        case .review, .none: nil
        }
    }
}

extension KnowledgeSeed {
    /// Pulls reusable material (questions, statements, pairs…) out of a written lesson.
    init(harvesting modules: [LessonModule], intro: String = "", takeaways: [String] = []) {
        self.init(intro: intro, takeaways: takeaways)
        for m in modules {
            switch m.type {
            case .multipleChoice:
                if let prompt = m.prompt, let options = m.options, let correct = m.correctIndex {
                    questions.append(.init(prompt: prompt, options: options, correct: correct, why: m.explanation))
                }
            case .trueFalse, .speedRound: statements += m.statements ?? []
            case .matchPairs: pairs += m.pairs ?? []
            case .flashcards: flashcards += m.flashcards ?? []
            case .fillBlank:
                if let sentence = m.sentence, let options = m.options, let correct = m.correctIndex {
                    blanks.append(.init(sentence: sentence, options: options, correct: correct, why: m.explanation))
                }
            case .reorder:
                if sequence.isEmpty { sequence = m.steps ?? []; sequencePrompt = m.prompt }
            case .scenario:
                if scenario == nil { scenario = m }
            case .storyCards: cards += m.cards ?? []
            default: break
            }
        }
    }
}

enum FlagshipCatalog {
    static let all: [Flagship] = [CuratedSalsa.flagship, CuratedWebsite.flagship, CuratedHabits.flagship]

    /// Best flagship for a typed goal, if any matches confidently.
    static func match(_ goal: String) -> Flagship? {
        let scored = all.map { ($0, $0.score(goal)) }.filter { $0.1 >= 3 }
        return scored.max { $0.1 < $1.1 }?.0
    }

    /// The flagship a course was created from.
    static func flagship(for course: Course) -> Flagship? {
        all.first { $0.personalize($0.title, goal: course.goal) == course.title && $0.allNodes.count == course.allNodes.count }
    }
}
