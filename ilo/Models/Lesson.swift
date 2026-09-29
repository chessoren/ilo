import Foundation

/// A generated lesson: an ordered list of modules the AI picked and arranged for one node.
struct Lesson: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var nodeID: UUID
    var title: String
    /// ilo's one-line intro shown before the first module.
    var intro: String
    var modules: [LessonModule]
    /// Short takeaways saved to the learner's deck at the end.
    var takeaways: [String] = []
    var generatedBy: String = "ilo"
}

/// Every module type ilo can put in a lesson.
enum ModuleType: String, Codable, CaseIterable, Sendable {
    // Learn
    case storyCards, audioLesson, flashcards
    // Practice
    case multipleChoice, trueFalse, matchPairs, reorder, wordBricks, fillBlank, freeAnswer, roleplay
    // Real world
    case mission, codeLab, cameraCoach, practiceTimer, liveCall
    // ilo originals
    case estimate, spotTheMistake, categorize, teachBack, speedRound, scenario, highlight

    /// Modules that are graded (count toward accuracy).
    var isGraded: Bool {
        switch self {
        case .storyCards, .audioLesson, .flashcards, .practiceTimer, .liveCall: false
        default: true
        }
    }

    var displayName: String {
        switch self {
        case .storyCards: "Story"
        case .audioLesson: "Listen"
        case .flashcards: "Flashcards"
        case .multipleChoice: "Quiz"
        case .trueFalse: "True or false"
        case .matchPairs: "Match"
        case .reorder: "Put in order"
        case .wordBricks: "Build it"
        case .fillBlank: "Fill the gap"
        case .freeAnswer: "Your words"
        case .roleplay: "Roleplay"
        case .mission: "Mission"
        case .codeLab: "Code lab"
        case .cameraCoach: "Camera coach"
        case .practiceTimer: "Practice"
        case .liveCall: "Call ilo"
        case .estimate: "Guess it"
        case .spotTheMistake: "Spot the mistake"
        case .categorize: "Sort it"
        case .teachBack: "Teach ilo"
        case .speedRound: "Speed round"
        case .scenario: "What would you do?"
        case .highlight: "Find it"
        }
    }

    var symbol: String {
        switch self {
        case .storyCards: "rectangle.stack.fill"
        case .audioLesson: "waveform"
        case .flashcards: "rectangle.on.rectangle.angled"
        case .multipleChoice: "list.bullet.circle.fill"
        case .trueFalse: "hand.draw.fill"
        case .matchPairs: "link"
        case .reorder: "arrow.up.arrow.down"
        case .wordBricks: "square.grid.3x1.below.line.grid.1x2.fill"
        case .fillBlank: "text.cursor"
        case .freeAnswer: "pencil.line"
        case .roleplay: "bubble.left.and.bubble.right.fill"
        case .mission: "flag.checkered"
        case .codeLab: "chevron.left.forwardslash.chevron.right"
        case .cameraCoach: "figure.dance"
        case .practiceTimer: "metronome.fill"
        case .liveCall: "phone.fill"
        case .estimate: "slider.horizontal.3"
        case .spotTheMistake: "exclamationmark.magnifyingglass"
        case .categorize: "tray.2.fill"
        case .teachBack: "graduationcap.fill"
        case .speedRound: "bolt.fill"
        case .scenario: "signpost.right.and.left.fill"
        case .highlight: "highlighter"
        }
    }
}

/// One step of a lesson. Flat payload so LLMs can emit it easily: `{"type": "multipleChoice", ...fields}`.
struct LessonModule: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var type: ModuleType

    // Shared
    var title: String? = nil
    var prompt: String? = nil
    var explanation: String? = nil

    // storyCards / audioLesson
    var cards: [StoryCard]? = nil
    var script: [String]? = nil

    // flashcards
    var flashcards: [Flashcard]? = nil

    // multipleChoice / fillBlank / scenario
    var options: [String]? = nil
    var correctIndex: Int? = nil
    /// scenario: one consequence per option.
    var consequences: [String]? = nil
    /// fillBlank: sentence with "___" where the answer goes.
    var sentence: String? = nil

    // trueFalse / speedRound
    var statements: [Statement]? = nil
    var seconds: Int? = nil

    // matchPairs
    var pairs: [Pair]? = nil

    // reorder
    var steps: [String]? = nil

    // wordBricks
    var answerTokens: [String]? = nil
    var distractors: [String]? = nil

    // freeAnswer / teachBack
    var rubric: [String]? = nil
    var sampleAnswer: String? = nil

    // roleplay / liveCall
    var persona: String? = nil
    var goal: String? = nil
    var opening: String? = nil
    var turns: Int? = nil

    // mission
    var instructions: [String]? = nil
    var proof: String? = nil

    // codeLab
    var language: String? = nil
    var starterCode: String? = nil
    /// Substrings the final code must contain to pass (case-insensitive).
    var mustContain: [String]? = nil
    var solution: String? = nil

    // cameraCoach
    var move: String? = nil
    var reps: Int? = nil

    // practiceTimer
    var bpm: Int? = nil
    var beatsPerBar: Int? = nil
    var countLabels: [String]? = nil
    var durationSeconds: Int? = nil

    // estimate
    var minValue: Double? = nil
    var maxValue: Double? = nil
    var answerValue: Double? = nil
    var unit: String? = nil

    // spotTheMistake / highlight
    var segments: [String]? = nil
    /// Indexes of the segments that are the answer.
    var answerIndexes: [Int]? = nil

    // categorize
    var buckets: [String]? = nil
    var items: [CategorizedItem]? = nil
}

struct StoryCard: Codable, Hashable, Sendable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var symbol: String? = nil
    /// Optional ilo reaction for the card.
    var mood: BloubExpression? = nil
    var highlight: String? = nil
}

struct Flashcard: Codable, Hashable, Sendable, Identifiable {
    var id: UUID = UUID()
    var front: String
    var back: String
}

struct Statement: Codable, Hashable, Sendable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var isTrue: Bool
    var why: String? = nil
}

struct Pair: Codable, Hashable, Sendable, Identifiable {
    var id: UUID = UUID()
    var left: String
    var right: String
}

struct CategorizedItem: Codable, Hashable, Sendable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var bucket: Int
}

// MARK: - Lenient decoding (LLM output often omits ids)

extension StoryCard {
    enum CodingKeys: String, CodingKey { case id, title, body, symbol, mood, highlight }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try c.decodeIfPresent(String.self, forKey: .body) ?? ""
        symbol = try? c.decodeIfPresent(String.self, forKey: .symbol)
        mood = try? c.decodeIfPresent(BloubExpression.self, forKey: .mood)
        highlight = try? c.decodeIfPresent(String.self, forKey: .highlight)
    }
}

extension Flashcard {
    enum CodingKeys: String, CodingKey { case id, front, back }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        front = try c.decode(String.self, forKey: .front)
        back = try c.decode(String.self, forKey: .back)
    }
}

extension Statement {
    enum CodingKeys: String, CodingKey { case id, text, isTrue, why }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        text = try c.decode(String.self, forKey: .text)
        isTrue = try c.decode(Bool.self, forKey: .isTrue)
        why = try? c.decodeIfPresent(String.self, forKey: .why)
    }
}

extension Pair {
    enum CodingKeys: String, CodingKey { case id, left, right }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        left = try c.decode(String.self, forKey: .left)
        right = try c.decode(String.self, forKey: .right)
    }
}

extension CategorizedItem {
    enum CodingKeys: String, CodingKey { case id, text, bucket }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        text = try c.decode(String.self, forKey: .text)
        bucket = try c.decode(Int.self, forKey: .bucket)
    }
}

extension LessonModule {
    /// A module is only playable if it carries the fields its type needs.
    var isValid: Bool {
        switch type {
        case .storyCards: !(cards ?? []).isEmpty
        case .audioLesson: !(script ?? []).isEmpty
        case .flashcards: !(flashcards ?? []).isEmpty
        case .multipleChoice, .scenario:
            (options?.count ?? 0) >= 2 && (correctIndex ?? -1) >= 0 && (correctIndex ?? 0) < (options?.count ?? 0) && prompt != nil
        case .fillBlank:
            (sentence?.contains("___") ?? false) && (options?.count ?? 0) >= 2 && (correctIndex ?? -1) >= 0 && (correctIndex ?? 0) < (options?.count ?? 0)
        case .trueFalse, .speedRound: !(statements ?? []).isEmpty
        case .matchPairs: (pairs?.count ?? 0) >= 2
        case .reorder: (steps?.count ?? 0) >= 3
        case .wordBricks: (answerTokens?.count ?? 0) >= 2
        case .freeAnswer, .teachBack: prompt != nil
        case .roleplay, .liveCall: persona != nil || opening != nil
        case .mission: !(instructions ?? []).isEmpty
        case .codeLab: starterCode != nil && !(mustContain ?? []).isEmpty
        case .cameraCoach: move != nil
        case .practiceTimer: (bpm ?? 0) > 0
        case .estimate: minValue != nil && maxValue != nil && answerValue != nil
        case .spotTheMistake, .highlight: (segments?.count ?? 0) >= 2 && !(answerIndexes ?? []).isEmpty
        case .categorize: (buckets?.count ?? 0) >= 2 && !(items ?? []).isEmpty
        }
    }
}

extension LessonModule {
    enum CodingKeys: String, CodingKey {
        case id, type, title, prompt, explanation, cards, script, flashcards, options, correctIndex, consequences, sentence
        case statements, seconds, pairs, steps, answerTokens, distractors, rubric, sampleAnswer, persona, goal, opening, turns
        case instructions, proof, language, starterCode, mustContain, solution, move, reps, bpm, beatsPerBar, countLabels
        case durationSeconds, minValue, maxValue, answerValue, unit, segments, answerIndexes, buckets, items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        type = try c.decode(ModuleType.self, forKey: .type)
        title = try? c.decodeIfPresent(String.self, forKey: .title)
        prompt = try? c.decodeIfPresent(String.self, forKey: .prompt)
        explanation = try? c.decodeIfPresent(String.self, forKey: .explanation)
        cards = try? c.decodeIfPresent([StoryCard].self, forKey: .cards)
        script = try? c.decodeIfPresent([String].self, forKey: .script)
        flashcards = try? c.decodeIfPresent([Flashcard].self, forKey: .flashcards)
        options = try? c.decodeIfPresent([String].self, forKey: .options)
        correctIndex = try? c.decodeIfPresent(Int.self, forKey: .correctIndex)
        consequences = try? c.decodeIfPresent([String].self, forKey: .consequences)
        sentence = try? c.decodeIfPresent(String.self, forKey: .sentence)
        statements = try? c.decodeIfPresent([Statement].self, forKey: .statements)
        seconds = try? c.decodeIfPresent(Int.self, forKey: .seconds)
        pairs = try? c.decodeIfPresent([Pair].self, forKey: .pairs)
        steps = try? c.decodeIfPresent([String].self, forKey: .steps)
        answerTokens = try? c.decodeIfPresent([String].self, forKey: .answerTokens)
        distractors = try? c.decodeIfPresent([String].self, forKey: .distractors)
        rubric = try? c.decodeIfPresent([String].self, forKey: .rubric)
        sampleAnswer = try? c.decodeIfPresent(String.self, forKey: .sampleAnswer)
        persona = try? c.decodeIfPresent(String.self, forKey: .persona)
        goal = try? c.decodeIfPresent(String.self, forKey: .goal)
        opening = try? c.decodeIfPresent(String.self, forKey: .opening)
        turns = try? c.decodeIfPresent(Int.self, forKey: .turns)
        instructions = try? c.decodeIfPresent([String].self, forKey: .instructions)
        proof = try? c.decodeIfPresent(String.self, forKey: .proof)
        language = try? c.decodeIfPresent(String.self, forKey: .language)
        starterCode = try? c.decodeIfPresent(String.self, forKey: .starterCode)
        mustContain = try? c.decodeIfPresent([String].self, forKey: .mustContain)
        solution = try? c.decodeIfPresent(String.self, forKey: .solution)
        move = try? c.decodeIfPresent(String.self, forKey: .move)
        reps = try? c.decodeIfPresent(Int.self, forKey: .reps)
        bpm = try? c.decodeIfPresent(Int.self, forKey: .bpm)
        beatsPerBar = try? c.decodeIfPresent(Int.self, forKey: .beatsPerBar)
        countLabels = try? c.decodeIfPresent([String].self, forKey: .countLabels)
        durationSeconds = try? c.decodeIfPresent(Int.self, forKey: .durationSeconds)
        minValue = try? c.decodeIfPresent(Double.self, forKey: .minValue)
        maxValue = try? c.decodeIfPresent(Double.self, forKey: .maxValue)
        answerValue = try? c.decodeIfPresent(Double.self, forKey: .answerValue)
        unit = try? c.decodeIfPresent(String.self, forKey: .unit)
        segments = try? c.decodeIfPresent([String].self, forKey: .segments)
        answerIndexes = try? c.decodeIfPresent([Int].self, forKey: .answerIndexes)
        buckets = try? c.decodeIfPresent([String].self, forKey: .buckets)
        items = try? c.decodeIfPresent([CategorizedItem].self, forKey: .items)
    }
}
