import Observation
import SwiftUI

/// Contract between the lesson player and every module view.
///
/// Graded modules: set `canCheck` when the learner has an answer, and register `onCheck`.
/// When Check is tapped the player calls `onCheck`, which must call `resolve(correct:…)`.
/// Ungraded / self-driven modules (story, flashcards, timer…) set `hidesCheckBar = true` and call `finish()` when done.
@Observable
@MainActor
final class ModuleSession {
    enum Phase: Equatable { case answering, correct, wrong }

    let module: LessonModule
    let course: Course
    let node: PathNode
    let ai: LearningAI

    /// Enables the Check button.
    var canCheck = false
    /// Label of the Check button ("Check", "Submit", "I did it!").
    var checkTitle = "Check"
    /// The module drives its own flow and calls `finish()`.
    var hidesCheckBar = false
    /// Current grading phase (read-only for modules; use `resolve`).
    private(set) var phase: Phase = .answering
    /// Explanation shown in the feedback sheet.
    private(set) var feedback: String?
    /// Shown in the wrong-answer sheet ("Correct answer: …").
    private(set) var correctAnswer: String?
    /// ilo's mood while this module is on screen (modules can change it — e.g. `.curious` while thinking).
    var mood: BloubExpression = .attentive
    /// Optional bonus XP a module grants (e.g. mission proof, speed round).
    var bonusXP = 0
    /// Set by self-driven modules when the learner opts out ("Skip for now", declining the call) before `finish()`,
    /// so the lesson doesn't award mission / call achievements for it.
    var skipped = false
    /// The Check action registered by the module.
    var onCheck: (() -> Void)?
    /// Set by the player: advance to the next module.
    var onFinish: (() -> Void)?
    /// Set by the player: record the grading outcome.
    var onResolve: ((Bool) -> Void)?
    /// True once the player moved past this module (or the lesson ended). A detached session ignores
    /// late `resolve` / `finish` calls (delayed tasks, double taps during the slide transition).
    private(set) var isDetached = false

    init(module: LessonModule, course: Course, node: PathNode, ai: LearningAI) {
        self.module = module
        self.course = course
        self.node = node
        self.ai = ai
    }

    var tint: CourseTint { course.tint }
    var isResolved: Bool { phase != .answering }

    func check() {
        guard canCheck, phase == .answering, !isDetached else { return }
        onCheck?()
    }

    /// Grade the answer. Plays haptics/sound and shows the feedback sheet.
    func resolve(correct: Bool, feedback: String? = nil, correctAnswer: String? = nil) {
        guard phase == .answering, !isDetached else { return }
        self.feedback = feedback ?? module.explanation
        self.correctAnswer = correctAnswer
        phase = correct ? .correct : .wrong
        mood = correct ? [.happy, .excited, .proud, .laughing].randomElement()! : [.sad, .confused, .surprised].randomElement()!
        if correct { Haptics.shared.correct(); SoundFX.shared.play(.correct) } else { Haptics.shared.wrong(); SoundFX.shared.play(.wrong) }
        onResolve?(correct)
    }

    /// Advance to the next module (ungraded modules, or after the feedback sheet).
    func finish() {
        guard !isDetached else { return }
        onFinish?()
    }

    /// Called by the player when this module is left behind. Idempotent.
    func detach() {
        isDetached = true
        onCheck = nil
    }
}

/// Every module view is built with `init(session:)`.
@MainActor
enum ModuleRouter {
    @ViewBuilder
    static func view(for session: ModuleSession) -> some View {
        switch session.module.type {
        case .storyCards: StoryCardsModule(session: session)
        case .audioLesson: AudioLessonModule(session: session)
        case .flashcards: FlashcardsModule(session: session)
        case .multipleChoice: MultipleChoiceModule(session: session)
        case .trueFalse: TrueFalseModule(session: session)
        case .matchPairs: MatchPairsModule(session: session)
        case .reorder: ReorderModule(session: session)
        case .wordBricks: WordBricksModule(session: session)
        case .fillBlank: FillBlankModule(session: session)
        case .freeAnswer: FreeAnswerModule(session: session)
        case .roleplay: RoleplayModule(session: session)
        case .mission: MissionModule(session: session)
        case .codeLab: CodeLabModule(session: session)
        case .cameraCoach: CameraCoachModule(session: session)
        case .practiceTimer: PracticeTimerModule(session: session)
        case .liveCall: LiveCallModule(session: session)
        case .estimate: EstimateModule(session: session)
        case .spotTheMistake: SpotTheMistakeModule(session: session)
        case .categorize: CategorizeModule(session: session)
        case .teachBack: TeachBackModule(session: session)
        case .speedRound: SpeedRoundModule(session: session)
        case .scenario: ScenarioModule(session: session)
        case .highlight: HighlightModule(session: session)
        }
    }
}
