import Foundation

/// Offline grading + conversation. Heuristic, but specific: it reads the learner's words and responds to them.
enum OfflineTutor {
    // MARK: - Grading

    static func grade(question: String, answer: String, rubric: [String], sample: String?) -> Grade {
        let text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = tokens(text)
        guard words.count >= 2 else {
            return Grade(score: 0.1, passed: false,
                         feedback: "Give it one full sentence — even a rough idea is something ilo can work with.",
                         improved: sample)
        }

        // Rubric coverage: a point counts if the answer shares a meaningful word (or stem) with it.
        let answerStems = Set(words.map(stem))
        let points = rubric.isEmpty ? [sample ?? question] : rubric
        let hits = points.map { point -> Bool in
            let stems = Set(tokens(point).map(stem))
            // Criteria about form ("gives an example") have no content words: reward a developed answer.
            if stems.isEmpty { return words.count >= 8 }
            let overlap = stems.intersection(answerStems).count
            return overlap >= min(2, max(1, stems.count / 3))
        }
        let coverage = Double(hits.filter { $0 }.count) / Double(max(points.count, 1))

        // Overlap with the sample answer (vocabulary of a good answer).
        let sampleStems = Set(tokens(sample ?? "").map(stem))
        let sampleOverlap = sampleStems.isEmpty ? coverage : min(1, Double(sampleStems.intersection(answerStems).count) / Double(max(4, sampleStems.count / 3)))

        // Effort: longer, more specific answers (numbers, examples) score higher, capped.
        let length = min(1, Double(words.count) / 18)
        let specificity: Double = (text.contains { $0.isNumber } || text.lowercased().contains("for example") || text.lowercased().contains("like ")) ? 0.1 : 0

        var score = 0.45 * coverage + 0.25 * sampleOverlap + 0.3 * length + specificity
        // Rubric criteria are often about *how* to answer ("uses an example") — reward effort generously.
        if words.count >= 12 { score = max(score, 0.6) }
        score = min(max(score, 0.05), 1)
        let passed = score >= 0.6

        let covered = zip(points, hits).filter { $0.1 }.map { criterion($0.0) }
        let missing = zip(points, hits).filter { !$0.1 }.map { criterion($0.0) }
        var feedback: String
        if passed {
            feedback = covered.first.map { "Nice — you covered \(lowercasedFirst($0))." } ?? "Nice — that's a clear, thoughtful answer."
            if let gap = missing.first { feedback += " To make it even stronger, add \(lowercasedFirst(gap))." }
        } else {
            feedback = words.count < 8 ? "Good start! Add a bit more detail." : "You're on the right track."
            if let gap = missing.first { feedback += " Make sure you include \(lowercasedFirst(gap))." }
        }
        return Grade(score: score, passed: passed, feedback: feedback, improved: improved(answer: text, sample: sample, passed: passed))
    }

    /// "Mentions pausing on 4 and 8" → "pausing on 4 and 8".
    private static func criterion(_ text: String) -> String {
        let verbs = ["Mentions ", "Names ", "Describes ", "Explains ", "Gives ", "Uses ", "Includes ", "States ", "Connects ", "Says ", "Lists "]
        for verb in verbs where text.hasPrefix(verb) { return String(text.dropFirst(verb.count)) }
        return text
    }

    private static func improved(answer: String, sample: String?, passed: Bool) -> String? {
        guard let sample = sample?.nilIfBlank else { return nil }
        if passed && answer.count > sample.count { return nil }
        return sample
    }

    // MARK: - Chat

    /// One in-character turn. Uses the persona, the practice goal, the topic and what the learner just said.
    static func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) -> String {
        let name = persona.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? "ilo"
        let userTurns = history.filter { $0.role == .user }
        let turn = userTurns.count
        let t = Topic(topic.isEmpty ? goal : topic)
        guard let last = userTurns.last?.text.trimmingCharacters(in: .whitespacesAndNewlines), !last.isEmpty else {
            return "Hi, I'm \(name)! Today we're practising \(t.noun). \(goal.isEmpty ? "Tell me: what do you already know about it?" : "Your goal: \(lowercasedFirst(goal)). Ready? Go ahead!")"
        }
        var rng = SeededRNG(seed: Composer.stableHash(last + "\(turn)"))

        // Language practice: gentle reply with a phrase from the phrasebook.
        if let key = t.spokenLanguage, let book = Topic.phrasebooks[key] {
            let phrase = book.phrases[(turn + 1) % book.phrases.count]
            let praise = ["Muy bien", "Très bien", "Molto bene", "Sehr gut", "Muito bem", "Sugoi"][["spanish", "french", "italian", "german", "portuguese", "japanese"].firstIndex(of: key) ?? 0]
            return "\(praise)! \(echo(last)) Now try this one: “\(phrase.1)” — it means “\(phrase.0)”. Can you use it in a sentence?"
        }

        let reactions = last.hasSuffix("?")
            ? ["Great question.", "Ooh, good one.", "I love that you asked that."]
            : ["Nice.", "Got it.", "Love that.", "That makes sense.", "Interesting!"]
        let reaction = reactions.randomElement(using: &rng) ?? "Nice."

        let answerToQuestion = last.hasSuffix("?")
            ? " Short answer: start small, practise it slowly, and check yourself against a good example — then build from there."
            : ""

        let followUps = [
            "What's the one part of \(t.short) that feels hardest for you right now?",
            "If you practised for just five minutes today, what exactly would you do?",
            "How will you know you're getting better — what would you notice?",
            "Can you give me a concrete example of that?",
            "What would you do differently if you had to teach this to a friend?",
            "When this week will you practise? Pick a moment right after something you already do daily.",
        ]
        let isLast = turn >= 4
        if isLast {
            return "\(reaction) \(echo(last)) You explained that really well — that's exactly how skills stick. Let's lock it in: practise once today, and tell me how it went next time!"
        }
        let followUp = followUps[(turn + Int(Composer.stableHash(goal) % 3)) % followUps.count]
        return "\(reaction) \(echo(last))\(answerToQuestion) \(followUp)"
    }

    /// Reflects a short piece of what the learner said so the reply feels heard.
    private static func echo(_ text: String) -> String {
        let meaningful = tokens(text).filter { $0.count > 3 }
        guard let word = meaningful.max(by: { $0.count < $1.count }) else { return "" }
        let templates = ["You mentioned “\(word)” — that's a smart thing to focus on.",
                         "“\(word.prefix(1).uppercased() + word.dropFirst())” is a great anchor for this.",
                         "I like how you brought up “\(word)”."]
        return templates[Int(Composer.stableHash(text) % UInt32(templates.count))]
    }

    // MARK: - Text helpers

    static let stopwords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "to", "of", "in", "on", "at", "for", "with", "is", "are", "was", "were", "be", "it", "its",
        "this", "that", "these", "those", "i", "you", "he", "she", "we", "they", "my", "your", "our", "their", "me", "so", "if", "then",
        "as", "by", "from", "about", "into", "than", "too", "very", "just", "can", "will", "would", "should", "could", "do", "does", "did",
        "have", "has", "had", "not", "no", "yes", "what", "when", "how", "why", "who", "which", "one", "all", "some", "more", "most", "also",
        "like", "really", "get", "got", "make", "makes", "thing", "things", "uses", "use", "names", "gives", "explains", "clear", "clearly",
        "mentions", "mention", "mentioning", "includes", "include", "describes", "describe", "states", "state", "explain", "concrete",
        "example", "answer", "idea", "ideas", "specific", "own", "words",
    ]

    static func tokens(_ text: String) -> [String] {
        text.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 2 && !stopwords.contains($0) }
    }

    static func stem(_ word: String) -> String {
        for suffix in ["ing", "ed", "es", "s", "ly"] where word.count > suffix.count + 3 && word.hasSuffix(suffix) {
            var base = String(word.dropLast(suffix.count))
            // "stepping" → "stepp" → "step"
            if base.count > 3, let last = base.last, base.dropLast().last == last, !"aeiou".contains(last) { base.removeLast() }
            return base.hasSuffix("e") && base.count > 3 ? String(base.dropLast()) : base
        }
        // "pause" ~ "pausing"
        return word.hasSuffix("e") && word.count > 4 ? String(word.dropLast()) : word
    }

    static func lowercasedFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        let trimmed = text.hasSuffix(".") ? String(text.dropLast()) : text
        // Keep acronyms / proper nouns ("HTML", "I") intact.
        if trimmed.count > 1, trimmed.dropFirst().first?.isUppercase == true { return trimmed }
        return first.lowercased() + trimmed.dropFirst()
    }
}
