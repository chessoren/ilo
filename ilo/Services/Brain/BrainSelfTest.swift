#if DEBUG
import Foundation
import UIKit

/// Offline-brain self-test. Launch with `-brainSelfTest` (add `-exitAfterSelfTest` to quit when done):
///   xcrun simctl launch --console-pty <sim> app.ilo.learn -brainSelfTest -exitAfterSelfTest
/// Plans every flagship + several generic goals, generates every lesson and checks every module.
enum BrainSelfTest {
    private static let once: Void = {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-brainSelfTest") else { return }
        Task.detached(priority: .utility) {
            let failures = await run()
            print("[BRAIN] SELF-TEST DONE — \(failures == 0 ? "ALL PASSED" : "\(failures) FAILURE(S)")")
            if args.contains("-exitAfterSelfTest") { exit(failures == 0 ? 0 : 1) }
        }
    }()

    static func startIfRequested() { _ = once }

    private final class Report: @unchecked Sendable {
        var failures = 0
        var warnings = 0
        var usedTypes = Set<ModuleType>()
        func fail(_ message: String) { failures += 1; print("[BRAIN] ❌ \(message)") }
        func warn(_ message: String) { warnings += 1; print("[BRAIN] ⚠️ \(message)") }
        func ok(_ message: String) { print("[BRAIN] ✅ \(message)") }
    }

    static func run() async -> Int {
        let report = Report()
        let started = Date()
        let brain = LocalAI(pace: 0.01, allowOnDevice: false)

        // 1. Goal matching
        let expectations: [(String, String?)] = [
            ("Salsa for my grandma's wedding", "salsa"), ("I want to dance salsa", "salsa"), ("learn to dance for a party", "salsa"),
            ("Code my first website", "website"), ("learn HTML and CSS", "website"), ("build a portfolio website", "website"),
            ("learn python programming", nil), ("Atomic Habits", "habits"), ("build better habits", "habits"), ("james clear book", "habits"),
            ("learn ballet", nil), ("play the guitar", nil), ("Spanish for my trip to Mexico", nil),
        ]
        for (goal, expected) in expectations {
            let got = FlagshipCatalog.match(goal)?.id
            if got == expected { report.ok("match “\(goal)” → \(got ?? "generic")") }
            else { report.fail("match “\(goal)” → \(got ?? "generic"), expected \(expected ?? "generic")") }
        }

        // 2. Flagships
        let flagshipGoals = ["Salsa for my grandma's wedding", "Code my first website", "Atomic Habits"]
        var flagshipTypes = Set<ModuleType>()
        for goal in flagshipGoals {
            let before = report.usedTypes
            report.usedTypes = []
            await checkCourse(goal: goal, brain: brain, report: report, expectFlagship: true)
            flagshipTypes.formUnion(report.usedTypes)
            report.usedTypes.formUnion(before)
        }
        let missing = Set(ModuleType.allCases).subtracting(flagshipTypes)
        if missing.isEmpty { report.ok("flagships use all \(ModuleType.allCases.count) module types") }
        else { report.fail("flagships never use: \(missing.map(\.rawValue).sorted().joined(separator: ", "))") }

        // 3. Generic goals (template composer)
        for goal in ["Learn to play the guitar", "Spanish for my trip to Mexico", "learn python", "Understand quantum physics",
                     "get better at public speaking", "run my first marathon", "meditate every day", "cook Thai food at home"] {
            await checkCourse(goal: goal, brain: brain, report: report, expectFlagship: false)
        }

        // 4. On-device model (if this device has Apple Intelligence)
        if OnDeviceBrain.isAvailable {
            report.ok("on-device model AVAILABLE — testing one generic goal with it")
            let request = CourseRequest(goal: "Learn to bake sourdough bread", motivation: nil, level: .zero, dailyMinutes: 10, deadline: nil, styles: [])
            let t0 = Date()
            do {
                guard let planned = await withTimeout(seconds: 60, { try? await OnDeviceBrain.plan(request, topic: Topic(request.goal)) }), let course = planned else {
                    throw AIError.badResponse("no answer within 60 s")
                }
                report.ok("on-device plan in \(String(format: "%.1f", Date().timeIntervalSince(t0)))s: \(course.title) — \(course.units.map(\.title).joined(separator: " / "))")
                if let node = course.allNodes.first(where: { $0.kind == .lesson || $0.kind == .story }) {
                    let t1 = Date()
                    guard let drafted = await withTimeout(seconds: 60, { try? await OnDeviceBrain.seed(course: course, node: node, topic: Topic(request.goal)) }), let seed = drafted else {
                        throw AIError.badResponse("no lesson within 60 s")
                    }
                    let lesson = Composer.compose(title: node.title, kind: node.kind, seed: seed, nodeID: node.id, author: "ilo · on-device")
                    report.ok("on-device lesson in \(String(format: "%.1f", Date().timeIntervalSince(t1)))s: “\(node.title)” — \(seed.cards.first?.body ?? "")")
                    check(lesson, node: node, course: course, report: report)
                }
            } catch {
                report.warn("on-device generation failed after \(String(format: "%.1f", Date().timeIntervalSince(t0)))s: \(error)")
            }

        } else {
            report.warn("on-device model unavailable here — template composer used (expected on most simulators)")
        }

        // 5. Grading + chat
        let good = OfflineTutor.grade(question: "Explain the salsa basic", answer: "Count to eight: step forward on 1, rock on 2, home on 3, pause on 4, then back on 5, rock 6, home 7, pause 8. Keep the steps small.",
                                      rubric: ["Mentions stepping on 1-2-3 and 5-6-7", "Mentions pausing on 4 and 8", "Mentions small steps"], sample: nil)
        let bad = OfflineTutor.grade(question: "Explain the salsa basic", answer: "idk", rubric: ["Mentions pausing on 4 and 8"], sample: "Pause on 4 and 8.")
        good.passed ? report.ok("grade: good answer passed (\(String(format: "%.2f", good.score))) — \(good.feedback)") : report.fail("grade: good answer failed (\(good.score))")
        !bad.passed ? report.ok("grade: 'idk' failed — \(bad.feedback)") : report.fail("grade: 'idk' passed")
        let reply = OfflineTutor.chat(persona: "Rosa, a salsa teacher", goal: "Count the basic", topic: "salsa",
                                      history: [ChatMessage(role: .ilo, text: "Hi!"), ChatMessage(role: .user, text: "I keep stepping on the pauses")])
        reply.count > 20 ? report.ok("chat: \(reply)") : report.fail("chat reply too short: \(reply)")

        // 6. Wire decoding (remote lesson with a broken module)
        let json = """
        {"title":"T","intro":"Hi","takeaways":["a"],"modules":[
          {"type":"storyCards","cards":[{"title":"A","body":"B"}]},
          {"type":"multipleChoice","prompt":"Q?","options":["x","y"],"correctIndex":5},
          {"type":"nonsense"},
          {"type":"trueFalse","statements":[{"text":"S","isTrue":true}]}]}
        """
        if let dto = try? JSONDecoder().decode(Wire.LessonDTO.self, from: Data(json.utf8)),
           let lesson = try? dto.lesson(for: PathNode(title: "N", brief: "", kind: .lesson, symbol: "star.fill"), by: "test"),
           lesson.modules.count == 2 {
            report.ok("wire: lenient lesson decode kept 2 valid of 4 modules")
        } else {
            report.fail("wire: lenient lesson decode")
        }

        print("[BRAIN] finished in \(String(format: "%.1f", Date().timeIntervalSince(started)))s — \(report.failures) failures, \(report.warnings) warnings")
        return report.failures
    }

    private static func checkCourse(goal: String, brain: LocalAI, report: Report, expectFlagship: Bool, lessonLimit: Int = .max) async {
        let request = CourseRequest(goal: goal, motivation: expectFlagship ? nil : "for fun", level: .zero, dailyMinutes: 10, deadline: nil, styles: [])
        let steps = StepCounter()
        let course: Course
        do {
            course = try await brain.planCourse(request) { steps.add($0) }
        } catch {
            report.fail("plan “\(goal)” threw \(error)")
            return
        }
        let nodes = course.allNodes
        let isFlagship = FlagshipCatalog.flagship(for: course) != nil
        if isFlagship != expectFlagship { report.fail("“\(goal)” flagship=\(isFlagship)") }
        print("[BRAIN] ── \(course.title) · \(course.category.rawValue) · \(course.units.count) units · \(nodes.count) nodes · \(steps.count) plan steps")
        if steps.count < 6 { report.warn("only \(steps.count) plan steps for “\(goal)”") }
        if !(3...4).contains(course.units.count) { report.warn("\(course.units.count) units") }
        for unit in course.units where !(5...7).contains(unit.nodes.count) { report.warn("unit “\(unit.title)” has \(unit.nodes.count) nodes") }
        let courseText = ([course.title, course.tagline] + course.units.flatMap { [$0.title, $0.outcome] + $0.nodes.flatMap { [$0.title, $0.brief] } }).joined(separator: " ")
        if courseText.range(of: #"\{[A-Za-z]+\}"#, options: .regularExpression) != nil { report.fail("unreplaced placeholder in course “\(course.title)”") }
        for node in nodes where UIImage(systemName: node.symbol) == nil { report.fail("bad SF Symbol “\(node.symbol)” on \(node.title)") }
        if UIImage(systemName: course.symbol) == nil { report.fail("bad course symbol \(course.symbol)") }

        var checked = 0
        for node in nodes where node.kind != .chest {
            guard checked < lessonLimit else { break }
            checked += 1
            let context = LessonContext(level: course.level, previousTitles: [], recentMistakes: [], preferredStyles: [])
            do {
                let lesson = try await brain.generateLesson(course: course, node: node, context: context)
                check(lesson, node: node, course: course, report: report)
            } catch {
                report.fail("\(course.title) / \(node.title): threw \(error)")
            }
        }
    }

    private static func check(_ lesson: Lesson, node: PathNode, course: Course, report: Report) {
        let label = "\(course.title) / \(node.title) [\(node.kind.rawValue)]"
        let modules = lesson.modules
        report.usedTypes.formUnion(modules.map(\.type))
        let invalid = modules.filter { !$0.isValid }
        if !invalid.isEmpty { report.fail("\(label): invalid modules \(invalid.map(\.type.rawValue))") }
        let minimum = node.kind == .call ? 4 : 5
        if modules.count < minimum || modules.count > 10 { report.fail("\(label): \(modules.count) modules") }
        else if modules.count < 6 && node.kind != .call { report.warn("\(label): only \(modules.count) modules") }
        for (a, b) in zip(modules, modules.dropFirst()) where a.type == b.type { report.warn("\(label): two \(a.type.rawValue) in a row") }
        if let last = modules.last, ![.flashcards, .speedRound, .trueFalse, .storyCards].contains(last.type) {
            report.warn("\(label): ends with \(last.type.rawValue), not a recap")
        }
        if Set(modules.map(\.id)).count != modules.count { report.fail("\(label): duplicate module ids") }
        if let data = try? JSONEncoder().encode(lesson), let text = String(data: data, encoding: .utf8), text.contains("{who}") || text.contains("{event}") || text.contains("{occasion}") || text.contains("{Who}") || text.contains("{Event}") || text.contains("{Occasion}") {
            report.fail("\(label): unreplaced placeholder")
        }
        for m in modules {
            for card in m.cards ?? [] {
                if let h = card.highlight, !card.body.contains(h) { report.fail("\(label): highlight “\(h)” not in card “\(card.title)”") }
                if let s = card.symbol, UIImage(systemName: s) == nil { report.fail("\(label): bad card symbol \(s)") }
            }
            if m.type == .codeLab, let starter = m.starterCode, let must = m.mustContain {
                let solution = (m.solution ?? "").lowercased()
                for piece in must where !solution.contains(piece.lowercased()) { report.fail("\(label): solution lacks “\(piece)”") }
                if must.allSatisfy({ starter.lowercased().contains($0.lowercased()) }) { report.fail("\(label): starter already passes") }
            }
            if m.type == .estimate, let lo = m.minValue, let hi = m.maxValue, let answer = m.answerValue, !(lo...hi).contains(answer) {
                report.fail("\(label): estimate answer out of range")
            }
            if m.type == .practiceTimer, let labels = m.countLabels, labels.count != m.beatsPerBar { report.fail("\(label): timer labels ≠ beatsPerBar") }
            if m.type == .categorize, let buckets = m.buckets, (m.items ?? []).contains(where: { $0.bucket >= buckets.count }) { report.fail("\(label): bad bucket index") }
            if [.spotTheMistake, .highlight].contains(m.type), let segs = m.segments, (m.answerIndexes ?? []).contains(where: { $0 >= segs.count }) {
                report.fail("\(label): answer index out of range")
            }
            if m.type == .scenario, let options = m.options, let consequences = m.consequences, options.count != consequences.count {
                report.fail("\(label): scenario consequences ≠ options")
            }
            if m.type == .fillBlank, let sentence = m.sentence, sentence.components(separatedBy: "___").count != 2 { report.fail("\(label): fillBlank needs exactly one ___") }
        }
        if lesson.takeaways.isEmpty { report.warn("\(label): no takeaways") }
        print("[BRAIN]    \(node.title) — \(modules.count) modules: \(modules.map(\.type.rawValue).joined(separator: " → ")) (\(lesson.generatedBy))")
    }

    private final class StepCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var steps = 0
        func add(_ step: PlanStep) { lock.withLock { steps += 1 } }
        var count: Int { lock.withLock { steps } }
    }
}
#endif
