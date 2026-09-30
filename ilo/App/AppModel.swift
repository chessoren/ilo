import Foundation
import Observation
import SwiftUI

/// Rewards produced by finishing a lesson — drives the celebration sequence.
struct RewardSummary: Hashable, Sendable {
    var xp: Int
    var gems: Int
    var streakExtended: Bool
    var newStreak: Int
    var leveledUpTo: Int?
    var newBadges: [Badge]
    var questsCompleted: [Quest]
    var dailyGoalJustMet: Bool
}

/// Single source of truth for the whole app. Persists to a JSON file.
@Observable
@MainActor
final class AppModel {
    // MARK: Persisted state
    var player = Player()
    var courses: [Course] = []
    var progress: [UUID: CourseProgress] = [:]
    var lessons: [UUID: Lesson] = [:]
    var quests: [Quest] = []
    var questsDay: Date = .distantPast
    var friendQuest: FriendQuest?
    var activeCourseID: UUID?
    var hasOnboarded = false
    /// Last onboarding request, reused to personalise new courses.
    var lastRequest: CourseRequest?
    var recentMistakes: [String] = []

    // MARK: Session state (not persisted)
    var isPro = false
    var generating: Set<UUID> = []
    var generationErrors: [UUID: String] = [:]
    var pendingCelebration: RewardSummary?
    @ObservationIgnored private var inflight: [UUID: Task<Lesson, Error>] = [:]

    let ai: LearningAI

    init(ai: LearningAI? = nil) {
        self.ai = ai ?? AIRouter.make()
        load()
        refreshDailyState()
    }

    var activeCourse: Course? {
        guard let id = activeCourseID else { return courses.first }
        return courses.first { $0.id == id } ?? courses.first
    }

    // MARK: - Courses

    func add(_ course: Course, activate: Bool = true) {
        courses.insert(course, at: 0)
        progress[course.id] = CourseProgress()
        if activate { activeCourseID = course.id }
        if courses.count >= 3 { unlock(.polymath) }
        save()
        prefetch(course: course, after: nil)
    }

    func delete(_ course: Course) {
        courses.removeAll { $0.id == course.id }
        progress[course.id] = nil
        for node in course.allNodes { lessons[node.id] = nil }
        if activeCourseID == course.id { activeCourseID = courses.first?.id }
        save()
    }

    func open(_ course: Course) {
        activeCourseID = course.id
        if let i = courses.firstIndex(where: { $0.id == course.id }) { courses[i].lastOpenedAt = .now }
        save()
    }

    func state(of node: PathNode, in course: Course) -> NodeState {
        let done = progress[course.id]?.completed ?? []
        if done.contains(node.id) { return .completed }
        let nodes = course.allNodes
        guard let index = nodes.firstIndex(where: { $0.id == node.id }) else { return .locked }
        let firstOpen = nodes.firstIndex { !done.contains($0.id) }
        return index == firstOpen ? .current : .locked
    }

    func currentNode(in course: Course) -> PathNode? {
        let done = progress[course.id]?.completed ?? []
        return course.allNodes.first { !done.contains($0.id) }
    }

    func completion(of course: Course) -> Double {
        let total = course.allNodes.count
        guard total > 0 else { return 0 }
        return Double(progress[course.id]?.completed.count ?? 0) / Double(total)
    }

    // MARK: - Lessons (generated on demand + prefetch)

    func lesson(for node: PathNode, in course: Course) async throws -> Lesson {
        if let cached = lessons[node.id] { return cached }
        // Tapping a node while its prefetch is still running joins that generation instead of starting a second one.
        if let running = inflight[node.id] { return try await running.value }
        generating.insert(node.id)
        let context = LessonContext(level: course.level,
                                    previousTitles: previousTitles(before: node, in: course),
                                    recentMistakes: Array(recentMistakes.suffix(8)),
                                    preferredStyles: lastRequest?.styles ?? [])
        let brain = ai
        let task = Task { try await brain.generateLesson(course: course, node: node, context: context) }
        inflight[node.id] = task
        defer {
            if inflight[node.id] == task { inflight[node.id] = nil }
            generating.remove(node.id)
        }
        do {
            let lesson = try await task.value
            // Skip caching if the course was deleted (or everything reset) while generating.
            if courses.contains(where: { $0.id == course.id }) {
                lessons[node.id] = lesson
                generationErrors[node.id] = nil
                save()
            }
            return lesson
        } catch {
            generationErrors[node.id] = error.localizedDescription
            throw error
        }
    }

    /// Pre-generates the next couple of lessons in the background so tapping a node is instant.
    func prefetch(course: Course, after nodeID: UUID?) {
        var targets: [PathNode] = []
        if let nodeID {
            var cursor = course.node(after: nodeID)
            while let next = cursor, targets.count < 2 {
                if next.kind != .chest { targets.append(next) }
                cursor = course.node(after: next.id)
            }
        } else {
            targets = Array(course.allNodes.filter { $0.kind != .chest }.prefix(2))
        }
        for node in targets where lessons[node.id] == nil && !generating.contains(node.id) {
            Task { _ = try? await lesson(for: node, in: course) }
        }
    }

    func regenerate(_ node: PathNode, in course: Course) {
        lessons[node.id] = nil
        generationErrors[node.id] = nil
        Task { _ = try? await lesson(for: node, in: course) }
    }

    private func previousTitles(before node: PathNode, in course: Course) -> [String] {
        let nodes = course.allNodes
        guard let index = nodes.firstIndex(where: { $0.id == node.id }) else { return [] }
        return nodes[..<index].suffix(6).map(\.title)
    }

    // MARK: - Completing things

    func openChest(_ node: PathNode, in course: Course) -> Int {
        let gems = Int.random(in: 15...40)
        player.gems += gems
        progress[course.id, default: CourseProgress()].openedChests.insert(node.id)
        progress[course.id, default: CourseProgress()].completed.insert(node.id)
        save()
        return gems
    }

    @discardableResult
    func complete(_ result: LessonResult) -> RewardSummary {
        // The app may have stayed open past midnight: roll quests / streak freeze before counting this lesson.
        refreshDailyState()
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let levelBefore = player.level
        let goalMetBefore = player.dailyGoalMet
        let badgesBefore = player.unlockedBadges

        // Progress
        var courseProgress = progress[result.courseID] ?? CourseProgress()
        courseProgress.completed.insert(result.nodeID)
        courseProgress.stars[result.nodeID] = max(courseProgress.stars[result.nodeID] ?? 0, result.isPerfect ? 2 : 1)
        progress[result.courseID] = courseProgress

        // XP
        rollWeekIfNeeded()
        player.totalXP += result.totalXP
        player.weeklyXP += result.totalXP
        player.xpByDay[today, default: 0] += result.totalXP
        player.lessonsCompleted += 1
        player.minutesLearned += result.seconds / 60
        if result.isPerfect { player.perfectLessons += 1 }
        if result.didMission { player.missionsCompleted += 1 }

        // Streak (extends on first lesson of the day)
        var extended = false
        if !player.activeDays.contains(today) {
            if let last = player.lastActiveDay, let gap = cal.dateComponents([.day], from: last, to: today).day, gap > 1 {
                player.streak = 1
            } else {
                player.streak += 1
            }
            player.activeDays.insert(today)
            player.lastActiveDay = today
            player.longestStreak = max(player.longestStreak, player.streak)
            extended = true
        }

        // Takeaways
        if let course = courses.first(where: { $0.id == result.courseID }) {
            for text in result.takeaways.prefix(3) {
                player.savedTakeaways.insert(Takeaway(text: text, courseTitle: course.title), at: 0)
            }
            if course.category == .book, let unit = course.unit(containing: result.nodeID),
               unit.nodes.allSatisfy({ courseProgress.completed.contains($0.id) }) { unlock(.bookworm) }
        }

        // Gems
        let gems = result.isPerfect ? 10 : 5
        player.gems += gems

        // Quests
        let questsDone = advanceQuests(with: result)

        // Badges
        unlock(.firstLesson)
        if result.isPerfect { unlock(.perfectionist) }
        if player.streak >= 7 { unlock(.streak7) }
        if player.streak >= 30 { unlock(.streak30) }
        if result.didMission { unlock(.missionAccomplished) }
        if result.kind == .boss { unlock(.bossSlayer) }
        if result.didCall { unlock(.chatterbox) }
        if result.usedModules.contains(.codeLab) { unlock(.coder) }
        if result.usedModules.contains(.practiceTimer) || result.usedModules.contains(.cameraCoach) { unlock(.dancer) }
        let hour = cal.component(.hour, from: .now)
        if hour >= 22 || hour < 4 { unlock(.nightOwl) }
        if hour >= 4 && hour < 8 { unlock(.earlyBird) }

        if let course = courses.first(where: { $0.id == result.courseID }) {
            prefetch(course: course, after: result.nodeID)
        }
        save()
        let snapshot = player
        Task { await LeaderboardService.reportXP(result.totalXP, player: snapshot) }

        let summary = RewardSummary(
            xp: result.totalXP,
            gems: gems,
            streakExtended: extended,
            newStreak: player.streak,
            leveledUpTo: player.level > levelBefore ? player.level : nil,
            newBadges: Array(player.unlockedBadges.subtracting(badgesBefore)),
            questsCompleted: questsDone,
            dailyGoalJustMet: !goalMetBefore && player.dailyGoalMet
        )
        return summary
    }

    func recordMistake(_ text: String) {
        recentMistakes.append(text)
        if recentMistakes.count > 30 { recentMistakes.removeFirst(recentMistakes.count - 30) }
    }

    func unlock(_ badge: Badge) {
        player.unlockedBadges.insert(badge)
    }

    // MARK: - Quests

    func refreshDailyState() {
        let today = Calendar.current.startOfDay(for: .now)
        if questsDay != today {
            questsDay = today
            var pool: [Quest] = [
                Quest(kind: .earnXP, target: player.dailyGoalXP, reward: 10),
                Quest(kind: .finishLessons, target: 2, reward: 10),
            ]
            let extras: [Quest] = [
                Quest(kind: .perfectLesson, target: 1, reward: 15),
                Quest(kind: .comboStreak, target: 8, reward: 15),
                Quest(kind: .practiceMinutes, target: 10, reward: 10),
                Quest(kind: .completeMission, target: 1, reward: 20),
            ]
            pool.append(extras[Calendar.current.component(.day, from: today) % extras.count])
            quests = pool
        }
        if friendQuest == nil || (friendQuest?.endsAt ?? .distantPast) < .now {
            let names = ["Maya", "Leo", "Inès", "Sam", "Noah", "Zoé"]
            friendQuest = FriendQuest(friendName: names.randomElement() ?? "Maya", target: 300, mine: 0,
                                      theirs: Int.random(in: 20...90),
                                      endsAt: Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfWeek(for: .now)) ?? .now)
        }
        rollWeekIfNeeded()
        // Streak breaks if a whole day was missed (a freeze saves it once).
        if let last = player.lastActiveDay,
           let gap = Calendar.current.dateComponents([.day], from: last, to: today).day, gap > 1, player.streak > 0 {
            if player.streakFreezes > 0 && gap == 2 {
                player.streakFreezes -= 1
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
                player.activeDays.insert(yesterday)
                player.lastActiveDay = yesterday
            } else {
                player.streak = 0
            }
        }
    }

    private func advanceQuests(with result: LessonResult) -> [Quest] {
        var completed: [Quest] = []
        for i in quests.indices {
            let wasDone = quests[i].isDone
            switch quests[i].kind {
            case .earnXP: quests[i].progress += result.totalXP
            case .finishLessons: quests[i].progress += 1
            case .perfectLesson: if result.isPerfect { quests[i].progress += 1 }
            case .comboStreak: quests[i].progress = max(quests[i].progress, result.bestCombo)
            case .practiceMinutes: quests[i].progress += max(1, Int(result.seconds / 60))
            case .completeMission: if result.didMission { quests[i].progress += 1 }
            case .talkToIlo: if result.didCall { quests[i].progress += 1 }
            }
            if !wasDone && quests[i].isDone { completed.append(quests[i]) }
        }
        friendQuest?.mine += result.totalXP
        return completed
    }

    func claim(_ quest: Quest) {
        guard let i = quests.firstIndex(where: { $0.id == quest.id }), quests[i].isDone, !quests[i].claimed else { return }
        quests[i].claimed = true
        player.gems += quests[i].reward
        save()
    }

    // MARK: - Leagues

    /// Resets weekly XP on Monday and applies promotion/demotion from last week's standing.
    private func rollWeekIfNeeded() {
        let thisWeek = Calendar.current.startOfWeek(for: .now)
        guard player.weekStart < thisWeek else { return }
        let board = LeagueSimulator.board(for: player, weekStart: player.weekStart, at: Calendar.current.date(byAdding: .day, value: 7, to: player.weekStart) ?? .now)
        if let rank = board.firstIndex(where: \.isMe) {
            let size = board.count
            if rank < player.league.promotionSlots(cohort: size), let next = player.league.next {
                player.league = next
                unlock(.leagueClimber)
                if next == .apex { unlock(.apexPredator) }
            } else if rank >= size - player.league.demotionSlots(cohort: size), let prev = player.league.previous, player.weeklyXP < 50 {
                player.league = prev
            }
        }
        player.weeklyXP = 0
        player.weekStart = thisWeek
    }

    func buy(_ item: ShopItem) -> Bool {
        guard player.gems >= item.price else { return false }
        player.gems -= item.price
        switch item {
        case .streakFreeze: player.streakFreezes += 1
        }
        save()
        return true
    }

    // MARK: - Persistence

    nonisolated private struct Snapshot: Codable, Sendable {
        var player: Player
        var courses: [Course]
        var progress: [UUID: CourseProgress]
        var lessons: [UUID: Lesson]
        var quests: [Quest]
        var questsDay: Date
        var friendQuest: FriendQuest?
        var activeCourseID: UUID?
        var hasOnboarded: Bool
        var lastRequest: CourseRequest?
        var recentMistakes: [String]
    }

    nonisolated private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "ilo-state.json")
    }

    private var saveTask: Task<Void, Never>?

    func save() {
        saveTask?.cancel()
        let snapshot = Snapshot(player: player, courses: courses, progress: progress, lessons: lessons, quests: quests,
                                questsDay: questsDay, friendQuest: friendQuest, activeCourseID: activeCourseID,
                                hasOnboarded: hasOnboarded, lastRequest: lastRequest, recentMistakes: recentMistakes)
        saveTask = Task.detached(priority: .utility) {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: AppModel.fileURL, options: .atomic)
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        player = s.player
        courses = s.courses
        progress = s.progress
        lessons = s.lessons
        quests = s.quests
        questsDay = s.questsDay
        friendQuest = s.friendQuest
        activeCourseID = s.activeCourseID
        hasOnboarded = s.hasOnboarded
        lastRequest = s.lastRequest
        recentMistakes = s.recentMistakes
    }

    /// Wipes everything (Settings → Reset).
    func reset() {
        player = Player()
        courses = []
        progress = [:]
        lessons = [:]
        quests = []
        questsDay = .distantPast
        friendQuest = nil
        activeCourseID = nil
        hasOnboarded = false
        lastRequest = nil
        recentMistakes = []
        for task in inflight.values { task.cancel() }
        inflight = [:]
        generating = []
        generationErrors = [:]
        pendingCelebration = nil
        refreshDailyState()
        save()
    }
}

enum ShopItem: String, CaseIterable, Identifiable {
    case streakFreeze
    var id: String { rawValue }
    var price: Int { 200 }
    var title: String { "Streak Freeze" }
    var detail: String { "Keeps your streak alive if you miss a day." }
    var symbol: String { "snowflake" }
}

extension LessonResult {
    /// A mission node whose mission wasn't skipped (or a mission module done elsewhere).
    var didMission: Bool {
        usedModules.contains(.mission) || (kind == .mission && !skippedModules.contains(.mission))
    }

    /// Actually talked to ilo (a declined call doesn't count).
    var didCall: Bool {
        usedModules.contains(.liveCall) || (kind == .call && !skippedModules.contains(.liveCall))
    }
}
