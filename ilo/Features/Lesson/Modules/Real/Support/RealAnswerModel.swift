import SwiftUI

/// Shared state for AI-graded open answers (freeAnswer, teachBack).
@Observable
@MainActor
final class RealAnswerModel {
    enum Status: Equatable {
        case writing
        case grading
        case graded(Grade)
        case failed(String)
    }

    var text = ""
    private(set) var status: Status = .writing
    let voice = RealVoiceInput()

    var grade: Grade? {
        if case .graded(let g) = status { return g }
        return nil
    }

    var isLocked: Bool {
        switch status {
        case .grading, .graded: true
        default: false
        }
    }

    var hasAnswer: Bool { text.realTrimmed.count >= 3 }

    /// Grades with the AI and resolves the session. `decorate` lets a module tweak the grade (e.g. kid-friendly feedback).
    func submit(session: ModuleSession, question: String, rubric: [String], sample: String?,
                onGraded: ((Grade) -> Void)? = nil) async {
        guard hasAnswer, !isLocked else { return }
        voice.stop()
        session.canCheck = false
        session.mood = .curious
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { status = .grading }
        Haptics.shared.softTap()
        SoundFX.shared.play(.whoosh)

        let answer = text.realTrimmed
        do {
            let started = Date()
            let grade = try await session.ai.grade(question: question, answer: answer, rubric: rubric, sample: sample)
            // Keep the thinking beat visible long enough to feel considered.
            let elapsed = Date().timeIntervalSince(started)
            if elapsed < 1.1 { try? await Task.sleep(for: .seconds(1.1 - elapsed)) }
            let clamped = Grade(score: min(1, max(0, grade.score)), passed: grade.passed, feedback: grade.feedback, improved: grade.improved)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { status = .graded(clamped) }
            onGraded?(clamped)
            let better = clamped.improved?.realTrimmed.isEmpty == false ? clamped.improved : sample
            session.resolve(correct: clamped.passed, feedback: clamped.feedback, correctAnswer: clamped.passed ? nil : better)
        } catch {
            withAnimation(.spring) { status = .failed((error as? LocalizedError)?.errorDescription ?? "ilo couldn't read that right now.") }
            session.mood = .sad
            session.canCheck = hasAnswer
            Haptics.shared.warning()
        }
    }

    func resetError(session: ModuleSession) {
        withAnimation(.spring) { status = .writing }
        session.mood = .attentive
        session.canCheck = hasAnswer
    }
}
