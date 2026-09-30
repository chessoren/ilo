import Foundation
import Observation
import SwiftUI

/// Every screen of the onboarding, in order.
enum OnboardingStep: Int, CaseIterable, Comparable {
    case splash, welcome, howItWorks, goal, why, deadline, level, styles, minutes, name, bloub, reminders, claude, building, commit

    static func < (a: OnboardingStep, b: OnboardingStep) -> Bool { a.rawValue < b.rawValue }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }

    /// Steps that show the top progress bar.
    var showsChrome: Bool { self >= .howItWorks }
    var canGoBack: Bool { showsChrome && self != .building && self != .commit }

    /// 0...1 progress for the top bar.
    var progress: Double {
        let first = OnboardingStep.howItWorks.rawValue, last = OnboardingStep.commit.rawValue
        return Double(rawValue - first + 1) / Double(last - first + 1)
    }
}

/// A motivation chip on the "why" screen.
struct OnboardingMotivation: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var symbol: String
    var tint: CourseTint

    static let all: [OnboardingMotivation] = [
        .init(title: "For a big event", symbol: "party.popper.fill", tint: .orchid),
        .init(title: "For my career", symbol: "briefcase.fill", tint: .sky),
        .init(title: "To impress someone", symbol: "heart.fill", tint: .peach),
        .init(title: "For school", symbol: "graduationcap.fill", tint: .lavender),
        .init(title: "Personal growth", symbol: "leaf.fill", tint: .mint),
        .init(title: "Just curious", symbol: "sparkles", tint: .butter),
    ]
}

enum OnboardingDeadline: String, CaseIterable, Identifiable {
    case week, month, quarter, noRush, date
    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "In a week"
        case .month: "In a month"
        case .quarter: "In 3 months"
        case .noRush: "No rush"
        case .date: "On a specific date"
        }
    }

    var detail: String {
        switch self {
        case .week: "Crash course, essentials only"
        case .month: "Solid and steady"
        case .quarter: "Deep and thorough"
        case .noRush: "I'll learn at my own pace"
        case .date: "A wedding, a trip, an exam…"
        }
    }

    var symbol: String {
        switch self {
        case .week: "hare.fill"
        case .month: "calendar"
        case .quarter: "mountain.2.fill"
        case .noRush: "tortoise.fill"
        case .date: "calendar.badge.clock"
        }
    }
}

struct OnboardingStyle: Identifiable, Hashable {
    var id: String
    var title: String
    var symbol: String
    var tint: CourseTint

    static let all: [OnboardingStyle] = [
        .init(id: "stories", title: "Stories", symbol: "book.pages.fill", tint: .orchid),
        .init(id: "quizzes", title: "Quizzes", symbol: "checklist", tint: .periwinkle),
        .init(id: "missions", title: "Hands-on missions", symbol: "flag.checkered", tint: .mint),
        .init(id: "voice", title: "Voice & live calls", symbol: "waveform", tint: .sky),
        .init(id: "code", title: "Code labs", symbol: "chevron.left.forwardslash.chevron.right", tint: .lavender),
        .init(id: "flashcards", title: "Flashcards", symbol: "rectangle.on.rectangle.angled.fill", tint: .butter),
        .init(id: "practice", title: "Timed practice", symbol: "timer", tint: .orange),
        .init(id: "games", title: "Speed games", symbol: "bolt.fill", tint: .peach),
    ]
}

struct OnboardingPace: Identifiable, Hashable {
    var id: Int { minutes }
    var minutes: Int
    var title: String
    var xp: Int

    static let all: [OnboardingPace] = [
        .init(minutes: 5, title: "Casual", xp: 10),
        .init(minutes: 10, title: "Regular", xp: 20),
        .init(minutes: 15, title: "Serious", xp: 30),
        .init(minutes: 20, title: "Intense", xp: 50),
    ]
}

/// Everything the learner answers during onboarding.
@Observable
@MainActor
final class OnboardingAnswers {
    var goal = ""
    var motivation: OnboardingMotivation?
    var deadline: OnboardingDeadline?
    var eventDate: Date = Calendar.current.date(byAdding: .day, value: 28, to: .now) ?? .now
    var level: LearnerLevel?
    var styles: Set<String> = []
    var pace: OnboardingPace?
    var name = ""
    var shape: BloubShape = .circle
    var color: BloubColor = .blue
    var reminderHour = 19
    var remindersEnabled = false
    var streakGoal = 14
    /// Bumped on every meaningful choice so ilo can bounce.
    var reactions = 0
    var course: Course?

    var trimmedGoal: String { goal.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var displayName: String { trimmedName.isEmpty ? "friend" : trimmedName }

    /// Short topic for copy ("salsa for my grandma's wedding" → "Salsa for my grandma's wedding").
    var goalLabel: String {
        let g = trimmedGoal
        guard let first = g.first else { return "it" }
        return first.uppercased() + g.dropFirst()
    }

    var deadlineDate: Date? {
        let cal = Calendar.current
        switch deadline {
        case .week: return cal.date(byAdding: .day, value: 7, to: .now)
        case .month: return cal.date(byAdding: .month, value: 1, to: .now)
        case .quarter: return cal.date(byAdding: .month, value: 3, to: .now)
        case .date: return eventDate
        case .noRush, nil: return nil
        }
    }

    /// When the learner will be "ready" at a given pace.
    func projectedDate(minutes: Int) -> Date {
        let base: Double = switch level ?? .zero {
        case .zero: 420
        case .beginner: 360
        case .intermediate: 330
        case .advanced: 540
        }
        let days = Int((base / Double(max(minutes, 1))).rounded(.up))
        return Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }

    var request: CourseRequest {
        CourseRequest(goal: trimmedGoal.isEmpty ? "Learn something new" : trimmedGoal,
                      motivation: motivation?.title,
                      level: level ?? .zero,
                      dailyMinutes: pace?.minutes ?? 10,
                      deadline: deadlineDate,
                      styles: styles.isEmpty ? ["quizzes", "stories"] : OnboardingStyle.all.map(\.id).filter(styles.contains))
    }

    func react() { reactions += 1 }

    #if DEBUG
    /// Pre-fills sensible answers when jumping straight to a step with `-onboardingStep N`.
    func fillForTesting(upTo step: OnboardingStep) {
        if step > .goal { goal = "Salsa for my grandma's wedding" }
        if step > .why { motivation = OnboardingMotivation.all[0] }
        if step > .deadline { deadline = .month }
        if step > .level { level = .zero }
        if step > .styles { styles = ["stories", "quizzes", "missions"] }
        if step > .minutes { pace = OnboardingPace.all[1] }
        if step > .name { name = "Sophia" }
        if step > .bloub { color = .violet; shape = .pebble }
    }
    #endif
}
