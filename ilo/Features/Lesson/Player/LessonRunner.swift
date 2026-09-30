import Observation
import SwiftUI

/// Drives one lesson: the module queue (with Duolingo-style retry of missed questions), combo, accuracy, timing.
@Observable
@MainActor
final class LessonRunner {
    struct Step: Identifiable, Equatable {
        let id = UUID()
        let module: LessonModule
        /// Id of the original module this step plays (retries share it).
        let originalID: UUID
        let isRetry: Bool
    }

    let lesson: Lesson
    let course: Course
    let node: PathNode
    let ai: LearningAI

    private(set) var steps: [Step]
    private(set) var index = 0
    private(set) var session: ModuleSession
    private(set) var isFinished = false

    // Stats
    private(set) var combo = 0
    private(set) var bestCombo = 0
    private(set) var correctAnswers = 0
    private(set) var gradedAttempts = 0
    private(set) var mistakes = 0
    private(set) var moduleBonusXP = 0
    private(set) var completedOriginals: Set<UUID> = []
    private(set) var retried: Set<UUID> = []
    let startedAt = Date()
    private(set) var finishedAt: Date?

    /// Called with the missed prompt so the app can remember mistakes.
    var onMistake: ((String) -> Void)?
    /// Called when the combo crosses a milestone (3, 5, 10…).
    var onComboMilestone: ((Int) -> Void)?

    init(lesson: Lesson, course: Course, node: PathNode, ai: LearningAI) {
        self.lesson = lesson
        self.course = course
        self.node = node
        self.ai = ai
        let playable = lesson.modules.filter(\.isValid)
        let modules = playable.isEmpty ? lesson.modules : playable
        steps = modules.map { Step(module: $0, originalID: $0.id, isRetry: false) }
        session = ModuleSession(module: modules.first ?? LessonModule(type: .storyCards), course: course, node: node, ai: ai)
        wire(session)
    }

    var originalCount: Int { Set(steps.map(\.originalID)).count }
    var current: Step? { steps.indices.contains(index) ? steps[index] : nil }

    /// Bar progress: modules truly done / all modules (retries don't inflate it).
    var progress: Double {
        guard originalCount > 0 else { return 0 }
        return Double(completedOriginals.count) / Double(originalCount)
    }

    var accuracy: Double {
        gradedAttempts == 0 ? 1 : Double(correctAnswers) / Double(gradedAttempts)
    }

    var elapsed: TimeInterval { (finishedAt ?? .now).timeIntervalSince(startedAt) }

    var bonusXP: Int {
        var bonus = moduleBonusXP
        if mistakes == 0 && gradedAttempts > 0 { bonus += 5 }
        if bestCombo >= 5 { bonus += 3 }
        return bonus
    }

    // MARK: Flow

    /// Core modules that drive their own flow — hide the Check bar from the first frame (no flicker).
    private static let selfDriven: Set<ModuleType> = [.storyCards, .audioLesson, .flashcards, .trueFalse, .matchPairs, .speedRound]

    private func wire(_ session: ModuleSession) {
        if Self.selfDriven.contains(session.module.type) { session.hidesCheckBar = true }
        session.onResolve = { [weak self] correct in self?.record(correct: correct) }
        session.onFinish = { [weak self] in self?.advance() }
    }

    private func record(correct: Bool) {
        guard let step = current else { return }
        gradedAttempts += 1
        if correct {
            correctAnswers += 1
            combo += 1
            bestCombo = max(bestCombo, combo)
            if combo == 3 || combo == 5 || (combo >= 10 && combo % 5 == 0) { onComboMilestone?(combo) }
        } else {
            mistakes += 1
            combo = 0
            onMistake?(step.module.prompt ?? step.module.sentence ?? step.module.title ?? step.module.type.displayName)
        }
    }

    /// Move past the current module (called by `session.finish()`).
    func advance() {
        guard let step = current, !isFinished else { return }
        moduleBonusXP += max(0, session.bonusXP)
        let wasWrong = session.phase == .wrong
        if wasWrong && step.module.type.isGraded && !retried.contains(step.originalID) {
            // Duolingo-style: missed questions come back once at the end.
            retried.insert(step.originalID)
            var copy = step.module
            copy.id = UUID()
            steps.append(Step(module: copy, originalID: step.originalID, isRetry: true))
        } else {
            completedOriginals.insert(step.originalID)
        }

        if index + 1 < steps.count {
            index += 1
            let next = ModuleSession(module: steps[index].module, course: course, node: node, ai: ai)
            wire(next)
            session = next
        } else {
            finishedAt = .now
            isFinished = true
        }
    }

    func makeResult() -> LessonResult {
        LessonResult(nodeID: node.id,
                     courseID: course.id,
                     xpEarned: node.kind.xp == 0 ? 10 : node.kind.xp,
                     bonusXP: bonusXP,
                     accuracy: accuracy,
                     mistakes: mistakes,
                     bestCombo: bestCombo,
                     seconds: elapsed,
                     kind: node.kind,
                     usedModules: Array(Set(steps.map(\.module.type))),
                     takeaways: lesson.takeaways)
    }
}
