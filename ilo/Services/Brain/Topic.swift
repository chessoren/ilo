import Foundation

/// Understands a free-text goal well enough to write natural sentences about it.
/// "I want to learn to play the guitar for my dad's birthday" →
///   phrase "play the guitar", noun "playing the guitar", short "guitar", category .creative.
struct Topic: Sendable {
    let raw: String
    /// The goal without filler ("play the guitar", "Spanish for my trip").
    let phrase: String
    /// Works after "about…" / at the start of a sentence ("playing the guitar", "Spanish").
    let noun: String
    /// A 1–3 word handle for titles ("guitar", "Spanish", "public speaking").
    let short: String
    let category: CourseCategory
    let symbol: String
    /// Detected programming language / spoken language, if any.
    let codeLanguage: String?
    let spokenLanguage: String?

    init(_ goal: String) {
        raw = goal
        var text = goal.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let fillers = ["i want to ", "i'd like to ", "i would like to ", "i wanna ", "help me ", "teach me how to ", "teach me ",
                       "how do i ", "how to ", "learn how to ", "learn to ", "learning to ", "learn about ", "learn ", "learning ",
                       "get better at ", "improve my ", "improve at ", "improve ", "master ", "understand ", "get into ",
                       "start ", "finally ", "be able to ", "know how to "]
        var changed = true
        while changed {
            changed = false
            for filler in fillers where text.lowercased().hasPrefix(filler) {
                text = String(text.dropFirst(filler.count)); changed = true
            }
        }
        if text.isEmpty { text = goal }
        phrase = text

        let words = text.split(separator: " ").map(String.init)
        let first = words.first?.lowercased() ?? ""
        if Topic.verbs.contains(first) {
            noun = ([Topic.gerund(first)] + words.dropFirst()).joined(separator: " ")
        } else {
            noun = text
        }

        // Short handle: drop leading verb / articles / possessives, cut at the first preposition.
        var core = words
        if Topic.verbs.contains(first) { core.removeFirst() }
        while let w = core.first?.lowercased(), Topic.leading.contains(w) { core.removeFirst() }
        if let cut = core.firstIndex(where: { Topic.stops.contains($0.lowercased()) }), cut > 0 { core = Array(core[..<cut]) }
        let timeWords: Set<String> = ["every", "each", "daily", "more", "better", "again", "regularly", "often", "properly", "well", "fast", "faster"]
        if Topic.verbs.contains(first), core.isEmpty || timeWords.contains(core[0].lowercased()) {
            // "meditate every day" → "meditating"
            short = Topic.gerund(first)
        } else {
            let handle = core.prefix(3).joined(separator: " ")
            short = handle.isEmpty ? (words.last ?? goal) : handle
        }

        let lower = " " + goal.lowercased() + " "
        let tokens = Set(lower.split { !$0.isLetter && $0 != "+" && $0 != "#" }.map(String.init))
        func any(_ list: [String]) -> Bool { list.contains { tokens.contains($0) || ($0.count > 6 && lower.contains($0)) } }

        codeLanguage = Topic.codeLanguages.first { tokens.contains($0.key) }?.value
        spokenLanguage = Topic.phrasebooks.keys.first { tokens.contains($0) }

        if codeLanguage != nil || any(["code", "coding", "program", "programming", "developer", "app", "apps", "sql", "software"]) {
            category = .code
        } else if spokenLanguage != nil || any(["language", "vocabulary", "fluent", "fluency", "grammar", "accent"]) {
            category = .language
        } else if any(["meditation", "meditate", "sleep", "stress", "anxiety", "mindfulness", "nutrition", "diet", "healthy", "breathing", "journaling", "yoga", "calm"]) {
            category = .wellbeing
        } else if any(["dance", "dancing", "salsa", "tango", "ballet", "run", "running", "swim", "swimming", "surf", "surfing", "climb", "climbing",
                       "skate", "skateboard", "boxing", "tennis", "golf", "football", "soccer", "basketball", "karate", "workout", "fitness",
                       "gym", "stretching", "pushups", "handstand", "juggle", "juggling", "ski", "skiing", "volleyball", "badminton", "cycling"]) {
            category = .movement
        } else if any(["guitar", "piano", "drums", "sing", "singing", "music", "draw", "drawing", "paint", "painting", "photo", "photography",
                       "write", "writing", "poetry", "knit", "knitting", "sew", "sewing", "pottery", "design", "film", "video", "ukulele",
                       "violin", "calligraphy", "sketch", "sketching", "songwriting", "compose"]) {
            category = .creative
        } else if any(["book", "novel", "chapter", "author"]) {
            category = .book
        } else if any(["history", "physics", "chemistry", "biology", "math", "maths", "mathematics", "economics", "philosophy", "psychology",
                       "astronomy", "science", "statistics", "finance", "investing", "geography", "law", "politics", "neuroscience",
                       "calculus", "algebra", "geology", "anatomy", "space", "universe", "art history", "climate"]) {
            category = .knowledge
        } else {
            category = .skill
        }

        symbol = Topic.symbols.first { any($0.words) }?.symbol ?? Topic.categorySymbol[category] ?? "sparkles"
    }

    /// "Guitar", "Public speaking".
    var shortTitle: String { short.prefix(1).uppercased() + short.dropFirst() }
    var nounTitle: String { noun.prefix(1).uppercased() + noun.dropFirst() }

    // MARK: Word lists

    static let verbs: Set<String> = [
        "play", "speak", "cook", "bake", "draw", "paint", "run", "write", "code", "build", "make", "sing", "dance", "swim", "read",
        "pass", "get", "become", "do", "fix", "train", "use", "drive", "knit", "sew", "meditate", "invest", "manage", "lead", "design",
        "edit", "shoot", "film", "take", "grow", "garden", "brew", "juggle", "surf", "ski", "skate", "climb", "box", "negotiate",
        "sell", "start", "create", "program", "develop", "teach", "photograph", "sketch", "compose", "produce", "solve", "study",
        "save", "budget", "plan", "organize", "organise", "stop", "quit", "wake", "sleep", "focus", "remember", "memorize", "type",
        "understand", "win", "beat", "ride", "fly", "sail", "tie", "fold", "repair", "install", "launch", "prepare", "practice", "practise",
    ]

    static func gerund(_ verb: String) -> String {
        let irregular = ["be": "being", "see": "seeing", "tie": "tying", "lie": "lying", "die": "dying", "ski": "skiing",
                         "run": "running", "swim": "swimming", "get": "getting", "shop": "shopping", "plan": "planning",
                         "stop": "stopping", "quit": "quitting", "sit": "sitting", "win": "winning", "begin": "beginning",
                         "box": "boxing", "fix": "fixing", "program": "programming", "set": "setting", "put": "putting"]
        if let special = irregular[verb] { return special }
        if verb.hasSuffix("ie") { return String(verb.dropLast(2)) + "ying" }
        if verb.hasSuffix("e") && !verb.hasSuffix("ee") && verb.count > 2 { return String(verb.dropLast()) + "ing" }
        return verb + "ing"
    }

    static let leading: Set<String> = ["a", "an", "the", "my", "your", "our", "some", "how", "to", "better", "good", "great", "basic", "basics", "of", "about"]
    static let stops: Set<String> = ["for", "to", "so", "because", "before", "by", "in", "at", "with", "on", "when", "until", "like", "and", "from", "without", "while", "within", "as"]

    static let codeLanguages: [String: String] = [
        "python": "python", "javascript": "javascript", "js": "javascript", "typescript": "javascript", "swift": "swift",
        "swiftui": "swift", "html": "html", "css": "css", "sql": "sql", "java": "java", "kotlin": "kotlin", "rust": "rust", "c#": "csharp", "golang": "go",
    ]

    static let categorySymbol: [CourseCategory: String] = [
        .movement: "figure.run", .code: "chevron.left.forwardslash.chevron.right", .book: "book.fill", .language: "character.bubble.fill",
        .creative: "paintpalette.fill", .skill: "sparkles", .knowledge: "brain.head.profile", .wellbeing: "leaf.fill",
    ]

    static let symbols: [(words: [String], symbol: String)] = [
        (["guitar", "ukulele"], "guitars.fill"), (["piano", "keyboard"], "pianokeys"), (["sing", "singing", "music", "song", "songwriting"], "music.note"),
        (["drums", "drum"], "music.quarternote.3"), (["draw", "drawing", "sketch", "sketching", "paint", "painting", "art"], "paintbrush.pointed.fill"),
        (["cook", "cooking", "bake", "baking", "recipe", "chef"], "fork.knife"), (["photo", "photography", "camera"], "camera.fill"),
        (["chess"], "checkerboard.rectangle"), (["run", "running", "marathon"], "figure.run"), (["yoga", "stretching"], "figure.mind.and.body"),
        (["meditation", "meditate", "mindfulness", "calm", "breathing"], "brain.head.profile"), (["swim", "swimming"], "figure.pool.swim"),
        (["speaking", "speech", "presentation", "present", "talk"], "megaphone.fill"), (["invest", "investing", "money", "finance", "budget", "save"], "chart.line.uptrend.xyaxis"),
        (["math", "maths", "mathematics", "calculus", "algebra", "statistics"], "function"), (["physics", "chemistry", "science", "atom"], "atom"),
        (["history", "ancient", "rome", "empire"], "building.columns.fill"), (["garden", "gardening", "plants", "grow"], "leaf.fill"),
        (["write", "writing", "novel", "poetry", "story"], "pencil.and.scribble"), (["drive", "driving"], "car.fill"),
        (["tennis"], "tennis.racket"), (["football", "soccer"], "soccerball"), (["basketball"], "basketball.fill"), (["climb", "climbing"], "figure.climbing"),
        (["film", "video", "youtube"], "video.fill"), (["knit", "knitting", "sew", "sewing"], "scissors"), (["sleep"], "bed.double.fill"),
        (["space", "astronomy", "universe", "stars"], "sparkles"), (["design"], "pencil.and.ruler.fill"), (["dance", "dancing"], "figure.dance"),
    ]

    /// Tiny phrasebooks so language goals get real words offline: (English, target, pronunciation hint).
    static let phrasebooks: [String: (name: String, phrases: [(String, String)])] = [
        "spanish": ("Spanish", [("Hello", "Hola"), ("Thank you", "Gracias"), ("Please", "Por favor"), ("Excuse me", "Perdón"),
                                ("Where is the station?", "¿Dónde está la estación?"), ("How much is it?", "¿Cuánto cuesta?"),
                                ("My name is…", "Me llamo…"), ("Goodbye", "Adiós"), ("I would like a coffee", "Quisiera un café")]),
        "french": ("French", [("Hello", "Bonjour"), ("Thank you", "Merci"), ("Please", "S'il vous plaît"), ("Excuse me", "Excusez-moi"),
                              ("Where is the station?", "Où est la gare ?"), ("How much is it?", "C'est combien ?"),
                              ("My name is…", "Je m'appelle…"), ("Goodbye", "Au revoir"), ("I would like a coffee", "Je voudrais un café")]),
        "italian": ("Italian", [("Hello", "Ciao"), ("Thank you", "Grazie"), ("Please", "Per favore"), ("Excuse me", "Scusi"),
                                ("Where is the station?", "Dov'è la stazione?"), ("How much is it?", "Quanto costa?"),
                                ("My name is…", "Mi chiamo…"), ("Goodbye", "Arrivederci"), ("I would like a coffee", "Vorrei un caffè")]),
        "german": ("German", [("Hello", "Hallo"), ("Thank you", "Danke"), ("Please", "Bitte"), ("Excuse me", "Entschuldigung"),
                              ("Where is the station?", "Wo ist der Bahnhof?"), ("How much is it?", "Wie viel kostet das?"),
                              ("My name is…", "Ich heiße…"), ("Goodbye", "Tschüss"), ("I would like a coffee", "Ich hätte gern einen Kaffee")]),
        "portuguese": ("Portuguese", [("Hello", "Olá"), ("Thank you", "Obrigado / Obrigada"), ("Please", "Por favor"), ("Excuse me", "Com licença"),
                                      ("Where is the station?", "Onde fica a estação?"), ("How much is it?", "Quanto custa?"),
                                      ("My name is…", "Meu nome é…"), ("Goodbye", "Tchau"), ("I would like a coffee", "Eu queria um café")]),
        "japanese": ("Japanese", [("Hello", "Konnichiwa"), ("Thank you", "Arigatou gozaimasu"), ("Please", "Onegaishimasu"), ("Excuse me", "Sumimasen"),
                                  ("Where is the station?", "Eki wa doko desu ka?"), ("How much is it?", "Ikura desu ka?"),
                                  ("My name is…", "Watashi no namae wa … desu"), ("Goodbye", "Sayounara"), ("I would like a coffee", "Koohii o onegaishimasu")]),
    ]
}
