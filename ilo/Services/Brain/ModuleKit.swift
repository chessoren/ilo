import Foundation

/// Compact builders for hand-written and composed lessons. Every builder produces a module that satisfies `isValid`
/// when given non-empty content (the self-test checks this).
extension LessonModule {
    // MARK: Learn

    static func story(_ title: String? = nil, _ cards: [StoryCard]) -> LessonModule {
        LessonModule(type: .storyCards, title: title, cards: cards)
    }

    static func listen(_ title: String, _ script: [String], prompt: String? = nil) -> LessonModule {
        LessonModule(type: .audioLesson, title: title, prompt: prompt, script: script)
    }

    static func flash(_ title: String = "Recap", _ cards: [(String, String)]) -> LessonModule {
        LessonModule(type: .flashcards, title: title, flashcards: cards.map { Flashcard(front: $0.0, back: $0.1) })
    }

    // MARK: Practice

    static func mcq(_ prompt: String, _ options: [String], _ correct: Int, why: String? = nil, title: String? = nil) -> LessonModule {
        LessonModule(type: .multipleChoice, title: title, prompt: prompt, explanation: why, options: options, correctIndex: correct)
    }

    static func tf(_ prompt: String = "True or false?", _ statements: [(String, Bool, String)]) -> LessonModule {
        LessonModule(type: .trueFalse, prompt: prompt,
                     statements: statements.map { Statement(text: $0.0, isTrue: $0.1, why: $0.2) })
    }

    static func speed(_ prompt: String = "Quick-fire round!", seconds: Int = 30, title: String? = "Speed round",
                      _ statements: [(String, Bool, String)]) -> LessonModule {
        LessonModule(type: .speedRound, title: title, prompt: prompt,
                     statements: statements.map { Statement(text: $0.0, isTrue: $0.1, why: $0.2) }, seconds: seconds)
    }

    static func match(_ prompt: String, _ pairs: [(String, String)], why: String? = nil) -> LessonModule {
        LessonModule(type: .matchPairs, prompt: prompt, explanation: why, pairs: pairs.map { Pair(left: $0.0, right: $0.1) })
    }

    /// Steps in the CORRECT order (the module shuffles them).
    static func order(_ prompt: String, _ steps: [String], why: String? = nil) -> LessonModule {
        LessonModule(type: .reorder, prompt: prompt, explanation: why, steps: steps)
    }

    /// Tokens in the CORRECT order.
    static func bricks(_ prompt: String, _ answer: [String], distractors: [String], why: String? = nil) -> LessonModule {
        LessonModule(type: .wordBricks, prompt: prompt, explanation: why, answerTokens: answer, distractors: distractors)
    }

    /// `sentence` must contain "___".
    static func blank(_ sentence: String, _ options: [String], _ correct: Int, why: String? = nil,
                      prompt: String = "Fill the gap") -> LessonModule {
        LessonModule(type: .fillBlank, prompt: prompt, explanation: why, options: options, correctIndex: correct, sentence: sentence)
    }

    static func free(_ prompt: String, rubric: [String], sample: String, title: String? = nil) -> LessonModule {
        LessonModule(type: .freeAnswer, title: title, prompt: prompt, rubric: rubric, sampleAnswer: sample)
    }

    static func roleplay(_ persona: String, goal: String, opening: String, turns: Int = 4, prompt: String? = nil) -> LessonModule {
        LessonModule(type: .roleplay, prompt: prompt, persona: persona, goal: goal, opening: opening, turns: turns)
    }

    // MARK: Real world

    static func mission(_ title: String, _ prompt: String, steps: [String], proof: String) -> LessonModule {
        LessonModule(type: .mission, title: title, prompt: prompt, instructions: steps, proof: proof)
    }

    static func code(_ prompt: String, language: String = "html", starter: String, mustContain: [String],
                     solution: String, why: String? = nil, title: String? = nil) -> LessonModule {
        LessonModule(type: .codeLab, title: title, prompt: prompt, explanation: why, language: language,
                     starterCode: starter, mustContain: mustContain, solution: solution)
    }

    static func camera(_ move: String, reps: Int, prompt: String, cues: [String]) -> LessonModule {
        LessonModule(type: .cameraCoach, prompt: prompt, instructions: cues, move: move, reps: reps)
    }

    static func timer(_ prompt: String, bpm: Int, labels: [String], seconds: Int, title: String? = nil) -> LessonModule {
        LessonModule(type: .practiceTimer, title: title, prompt: prompt, bpm: bpm, beatsPerBar: labels.count,
                     countLabels: labels, durationSeconds: seconds)
    }

    static func call(_ persona: String, goal: String, opening: String, turns: Int = 4, prompt: String? = nil) -> LessonModule {
        LessonModule(type: .liveCall, prompt: prompt, persona: persona, goal: goal, opening: opening, turns: turns)
    }

    // MARK: ilo originals

    static func estimate(_ prompt: String, min: Double, max: Double, answer: Double, unit: String, why: String) -> LessonModule {
        LessonModule(type: .estimate, prompt: prompt, explanation: why, minValue: min, maxValue: max, answerValue: answer, unit: unit)
    }

    /// `wrong` = indexes of the mistaken segments.
    static func spot(_ prompt: String, _ segments: [String], wrong: [Int], why: String) -> LessonModule {
        LessonModule(type: .spotTheMistake, prompt: prompt, explanation: why, segments: segments, answerIndexes: wrong)
    }

    /// `find` = indexes of the segments to highlight.
    static func highlight(_ prompt: String, _ segments: [String], find: [Int], why: String) -> LessonModule {
        LessonModule(type: .highlight, prompt: prompt, explanation: why, segments: segments, answerIndexes: find)
    }

    static func sort(_ prompt: String, buckets: [String], _ items: [(String, Int)], why: String? = nil) -> LessonModule {
        LessonModule(type: .categorize, prompt: prompt, explanation: why, buckets: buckets,
                     items: items.map { CategorizedItem(text: $0.0, bucket: $0.1) })
    }

    static func teach(_ prompt: String, rubric: [String], sample: String) -> LessonModule {
        LessonModule(type: .teachBack, prompt: prompt, rubric: rubric, sampleAnswer: sample)
    }

    static func scenario(_ prompt: String, _ options: [String], _ correct: Int, consequences: [String], why: String) -> LessonModule {
        LessonModule(type: .scenario, prompt: prompt, explanation: why, options: options, correctIndex: correct, consequences: consequences)
    }
}

/// `storyCard("Title", "Body", "symbol", .happy, highlight: "phrase")`
func storyCard(_ title: String, _ body: String, _ symbol: String? = nil, _ mood: BloubExpression? = nil, highlight: String? = nil) -> StoryCard {
    StoryCard(title: title, body: body, symbol: symbol, mood: mood, highlight: highlight)
}
