import SwiftUI

// DEBUG-only demo content + a launch-argument hook to open the lesson player without the rest of the app.
//
// Attach `.demoLessonHook()` to any root view (no-op in Release). Launch arguments:
//   -demoLesson                  open the player full screen with a sample lesson containing every core module
//   -demoModule <type>           only play modules of that type (e.g. matchPairs); comma-separated list allowed
//   -demoDelay <seconds>         fake generation time (default 1.2) — use 8+ to see the warm-up
//   -demoFail                    make generation fail (error state)
//   -demoSkipIntro               jump straight into the first module
//   -demoCelebration [step]      open the celebration sequence directly (optional start step index)

extension View {
    /// DEBUG: opens the lesson player / celebration when launched with `-demoLesson` / `-demoCelebration`.
    func demoLessonHook() -> some View {
        #if DEBUG
        modifier(DemoLessonHook())
        #else
        self
        #endif
    }
}

#if DEBUG

enum LessonDemoArgs {
    static var args: [String] { ProcessInfo.processInfo.arguments }
    static func has(_ flag: String) -> Bool { args.contains(flag) }
    static func value(_ flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count, !args[i + 1].hasPrefix("-") else { return nil }
        return args[i + 1]
    }
}

private struct DemoLessonHook: ViewModifier {
    @State private var showLesson = LessonDemoArgs.has("-demoLesson")
    @State private var showCelebration = LessonDemoArgs.has("-demoCelebration")
    @State private var demoModel = AppModel(ai: DemoLessonAI(
        delay: Double(LessonDemoArgs.value("-demoDelay") ?? "") ?? 1.2,
        fail: LessonDemoArgs.has("-demoFail"),
        only: LessonDemoArgs.value("-demoModule").map { $0.split(separator: ",").compactMap { ModuleType(rawValue: String($0)) } }
    ))

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showLesson) {
                LessonPlayerView(course: SampleLesson.course, node: SampleLesson.node) { showLesson = false }
                    .environment(demoModel)
            }
            .fullScreenCover(isPresented: $showCelebration) {
                LessonCompleteFlow(result: SampleLesson.result, summary: SampleLesson.summary, lesson: SampleLesson.lesson(),
                                   course: SampleLesson.course, startIndex: Int(LessonDemoArgs.value("-demoCelebration") ?? "") ?? 0) {
                    showCelebration = false
                }
                .environment(demoModel)
            }
    }
}

/// Serves the sample lesson with a fake delay (or failure).
struct DemoLessonAI: LearningAI {
    var delay: Double
    var fail: Bool
    var only: [ModuleType]?

    func planCourse(_ request: CourseRequest, onStep: @escaping @Sendable (PlanStep) -> Void) async throws -> Course {
        SampleLesson.course
    }

    func generateLesson(course: Course, node: PathNode, context: LessonContext) async throws -> Lesson {
        try await Task.sleep(for: .seconds(delay))
        if fail { throw AIError.offline }
        return SampleLesson.lesson(nodeID: node.id, only: only)
    }

    func grade(question: String, answer: String, rubric: [String], sample: String?) async throws -> Grade {
        Grade(score: 1, passed: true, feedback: "Nice!", improved: nil)
    }

    func chat(persona: String, goal: String, topic: String, history: [ChatMessage]) async throws -> String {
        "Tell me more!"
    }
}

enum SampleLesson {
    static let node = PathNode(title: "The habit loop", brief: "Cue, craving, response, reward.", kind: .lesson, symbol: "arrow.triangle.2.circlepath")

    static let course = Course(
        goal: "Actually apply Atomic Habits",
        title: "Atomic Habits",
        tagline: "Tiny changes, remarkable results.",
        symbol: "book.fill",
        tint: .periwinkle,
        category: .book,
        level: .beginner,
        dailyMinutes: 10,
        units: [CourseUnit(title: "The fundamentals", outcome: "Understand why small habits compound", tint: .periwinkle, nodes: [node])]
    )

    static func lesson(nodeID: UUID = node.id, only: [ModuleType]? = nil) -> Lesson {
        var modules = allModules
        if let only, !only.isEmpty { modules = modules.filter { only.contains($0.type) } }
        return Lesson(nodeID: nodeID, title: "The habit loop",
                      intro: "Every habit runs on the same 4-step loop. Learn it once and you can hack any habit — let's go!",
                      modules: modules,
                      takeaways: ["Every habit is a loop: cue → craving → response → reward.",
                                  "Getting 1% better every day makes you ~37x better in a year.",
                                  "Focus on systems, not goals."])
    }

    static var allModules: [LessonModule] {
        [
            LessonModule(type: .storyCards, title: "Why tiny habits win", cards: [
                StoryCard(title: "1% better", body: "Improve by just 1% every day and after a year you're about 37 times better. Small wins compound like interest.",
                          symbol: "chart.line.uptrend.xyaxis", mood: .excited, highlight: "37 times better"),
                StoryCard(title: "Systems beat goals", body: "Winners and losers share the same goals. What sets them apart is the system they follow every day.",
                          symbol: "gearshape.2.fill", mood: .curious, highlight: "the system they follow"),
                StoryCard(title: "The habit loop", body: "Every habit follows 4 steps: a cue, a craving, a response and a reward. Change one step and you change the habit.",
                          symbol: "arrow.triangle.2.circlepath", mood: .happy, highlight: "cue, a craving, a response and a reward"),
                StoryCard(title: "Become the person", body: "The deepest change is identity: not “I want to run” but “I'm a runner”. Every action is a vote for who you become.",
                          symbol: "person.fill.checkmark", mood: .proud, highlight: "a vote for who you become"),
            ]),
            LessonModule(type: .audioLesson, title: "Listen: the loop in real life", script: [
                "Your phone buzzes on the table. That's the cue.",
                "You feel the urge to know who texted you. That's the craving.",
                "You pick up the phone and read the message. That's the response.",
                "You feel relief and a tiny hit of joy. That's the reward — and the loop is now a little stronger.",
            ]),
            LessonModule(type: .flashcards, title: "The four laws", flashcards: [
                Flashcard(front: "Cue", back: "Make it obvious"),
                Flashcard(front: "Craving", back: "Make it attractive"),
                Flashcard(front: "Response", back: "Make it easy"),
                Flashcard(front: "Reward", back: "Make it satisfying"),
            ]),
            LessonModule(type: .multipleChoice, prompt: "According to James Clear, what matters more than your goals?",
                         explanation: "Goals set the direction, but your system — what you do every day — decides the result.",
                         options: ["Your systems", "Your motivation", "Your willpower", "Your talent"], correctIndex: 0),
            LessonModule(type: .trueFalse, prompt: "Swipe right if true, left if false",
                         statements: [
                            Statement(text: "Habits form faster when they're easy to start.", isTrue: true, why: "Reducing friction is the 3rd law."),
                            Statement(text: "Motivation is the key to lasting habits.", isTrue: false, why: "Systems beat motivation."),
                            Statement(text: "The reward is the last step of the loop.", isTrue: true, why: "Cue, craving, response, reward."),
                         ]),
            LessonModule(type: .matchPairs, prompt: "Match each step with its law",
                         explanation: "Each step of the loop has a law you can use to build a habit.",
                         pairs: [
                            Pair(left: "Cue", right: "Obvious"),
                            Pair(left: "Craving", right: "Attractive"),
                            Pair(left: "Response", right: "Easy"),
                            Pair(left: "Reward", right: "Satisfying"),
                         ]),
            LessonModule(type: .reorder, prompt: "Put the habit loop in order",
                         explanation: "Cue → craving → response → reward, then it loops again.",
                         steps: ["Cue", "Craving", "Response", "Reward"]),
            LessonModule(type: .wordBricks, prompt: "Build the famous quote",
                         explanation: "“You do not rise to the level of your goals. You fall to the level of your systems.”",
                         answerTokens: ["You", "fall", "to", "the", "level", "of", "your", "systems"],
                         distractors: ["rise", "goals", "habits"]),
            LessonModule(type: .fillBlank, prompt: "Fill the gap",
                         explanation: "1.01 to the power of 365 is about 37.8.",
                         options: ["1%", "10%", "50%"], correctIndex: 0,
                         sentence: "Getting ___ better every day makes you about 37 times better in a year."),
            LessonModule(type: .estimate, prompt: "How many times better are you after a year of improving 1% a day?",
                         explanation: "1.01³⁶⁵ ≈ 37.8. Tiny gains compound!",
                         minValue: 1, maxValue: 100, answerValue: 37.8, unit: "x"),
            LessonModule(type: .spotTheMistake, prompt: "Tap the part that's wrong",
                         explanation: "The third law is “make it easy” — you want to remove friction, not add it.",
                         segments: ["To build a habit,", "make it obvious,", "make it attractive,", "make it difficult,", "and make it satisfying."],
                         answerIndexes: [3]),
            LessonModule(type: .categorize, prompt: "Sort these tricks",
                         explanation: "Good habits need visible cues; bad habits need invisible ones.",
                         buckets: ["Make it obvious", "Make it invisible"],
                         items: [
                            CategorizedItem(text: "Shoes by the door", bucket: 0),
                            CategorizedItem(text: "Delete social apps", bucket: 1),
                            CategorizedItem(text: "Book on your pillow", bucket: 0),
                            CategorizedItem(text: "Snacks out of sight", bucket: 1),
                            CategorizedItem(text: "Water bottle on desk", bucket: 0),
                         ]),
            LessonModule(type: .speedRound, prompt: "True or false — fast!",
                         statements: [
                            Statement(text: "A cue triggers the habit.", isTrue: true),
                            Statement(text: "Goals are more important than systems.", isTrue: false),
                            Statement(text: "Habit stacking pairs a new habit with an old one.", isTrue: true),
                            Statement(text: "Bad habits should be made easy.", isTrue: false),
                            Statement(text: "Identity-based habits focus on who you want to be.", isTrue: true),
                            Statement(text: "The reward comes before the craving.", isTrue: false),
                            Statement(text: "The 2-minute rule makes habits easy to start.", isTrue: true),
                            Statement(text: "Environment has little effect on habits.", isTrue: false),
                         ], seconds: 30),
            LessonModule(type: .scenario, title: "What would you do?",
                         prompt: "You want to read more, but every evening you end up scrolling your phone in bed.",
                         explanation: "Changing the environment beats relying on willpower.",
                         options: ["Promise yourself to try harder", "Charge your phone in the kitchen and put a book on your pillow", "Read 50 pages every night starting today"],
                         correctIndex: 1,
                         consequences: ["Day 3: you're scrolling again. Willpower runs out when you're tired.",
                                        "The phone is out of reach and the book is right there. You read 10 pages without thinking about it.",
                                        "Great for two nights, then it feels like a chore and you stop."]),
            LessonModule(type: .highlight, prompt: "Tap the words that form the cue (your current habit)",
                         explanation: "In habit stacking, your current habit (“pour my coffee”) is the cue for the new one.",
                         segments: ["After", "I", "pour", "my", "coffee,", "I", "will", "meditate", "for", "one", "minute."],
                         answerIndexes: [2, 3, 4]),
        ]
    }

    static var result: LessonResult {
        LessonResult(nodeID: node.id, courseID: course.id, xpEarned: 15, bonusXP: 8, accuracy: 0.92, mistakes: 1, bestCombo: 6,
                     seconds: 214, kind: .lesson, usedModules: allModules.map(\.type), takeaways: lesson().takeaways)
    }

    static var summary: RewardSummary {
        RewardSummary(xp: 23, gems: 5, streakExtended: true, newStreak: 12, leveledUpTo: 4,
                      newBadges: [.firstLesson, .perfectionist],
                      questsCompleted: [Quest(kind: .earnXP, target: 30, progress: 30, reward: 10),
                                        Quest(kind: .finishLessons, target: 2, progress: 2, reward: 10)],
                      dailyGoalJustMet: true)
    }
}

#endif
