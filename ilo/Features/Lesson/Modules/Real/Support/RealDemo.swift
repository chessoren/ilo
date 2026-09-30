#if DEBUG
import SwiftUI

/// DEBUG-only sample lesson with one module of every real-world type, plus a tiny player host to try them.
///
/// Easiest: open the #Preview at the bottom of this file.
/// On the simulator: temporarily wrap RootView's body in `if RealDemo.isEnabled { RealModulesDemoHost() } else { … }`
/// (inside `#if DEBUG`), then launch with `-demoReal`. Optional: `-demoIndex N` to start at module N, `-demoAuto` to play
/// a scripted interaction, `-demoShots "2,5"` to write in-app screenshots to Documents.
enum RealDemo {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-demoReal") }
    static var startIndex: Int { UserDefaults.standard.integer(forKey: "demoIndex") }

    static let node = PathNode(title: "Tiny habits, big results", brief: "Why 1% better every day compounds", kind: .lesson, symbol: "leaf.fill")

    static let course = Course(goal: "Read and apply Atomic Habits", title: "Atomic Habits", tagline: "Tiny changes, remarkable results",
                               symbol: "book.fill", tint: .periwinkle, category: .book, level: .beginner, motivation: nil,
                               deadline: nil, dailyMinutes: 10,
                               units: [CourseUnit(title: "Unit 1", outcome: "Build your first habit", tint: .periwinkle, nodes: [node])])

    static let modules: [LessonModule] = [
        LessonModule(type: .freeAnswer, title: "In your own words",
                     prompt: "Why do tiny 1% improvements add up to huge results over a year?",
                     explanation: "Small gains compound: 1% better every day is about 37× better after a year.",
                     rubric: ["Mentions compounding or growth over time", "Gives an example or a number", "Explains why small changes are easy to stick to"],
                     sampleAnswer: "Because improvements compound. Getting 1% better each day multiplies on itself — after a year that's roughly 37 times better — and tiny changes are easy enough to actually keep doing."),
        LessonModule(type: .teachBack, title: "Teach ilo",
                     prompt: "habit stacking",
                     rubric: ["Explains linking a new habit to an existing one"],
                     sampleAnswer: "Habit stacking is like a train: after you do something you already do, like brushing your teeth, you add one tiny new thing, like saying one thing you're thankful for."),
        LessonModule(type: .roleplay, title: "Order at a café",
                     explanation: "Being polite and clear gets you what you want — in any language.",
                     rubric: ["Orders a drink and something to eat", "Asks for the bill", "Stays polite"],
                     persona: "Lucía, the friendly owner of a small café in Madrid",
                     goal: "Order a coffee and a croissant, then ask for the bill",
                     opening: "¡Hola! Welcome to Café Lucía. What can I get you today?",
                     turns: 3),
        LessonModule(type: .liveCall, title: "Call ilo",
                     persona: "ilo, a warm and curious habits coach",
                     goal: "Talk through one habit you want to build this week",
                     opening: "Hey, it's ilo! Tell me — what's one tiny habit you want to start this week?",
                     turns: 4),
        LessonModule(type: .mission, title: "Design your cue",
                     prompt: "Make your new habit obvious by putting its cue where you'll see it.",
                     seconds: 120,
                     instructions: ["Pick one habit you want to start", "Choose where it should happen", "Put a visible cue there (book on pillow, shoes by the door…)", "Snap a photo of your cue"],
                     proof: "A photo of the cue you set up"),
        LessonModule(type: .codeLab, title: "Your first button",
                     prompt: "Add a heading that says Hello and a button with the text Start.",
                     explanation: "HTML tags describe what things are: <h1> is a big heading, <button> is a button.",
                     language: "html",
                     starterCode: "<!-- Write your HTML below -->\n<h1></h1>\n",
                     mustContain: ["<h1>", "hello", "<button", "start"],
                     solution: "<h1>Hello</h1>\n<button>Start</button>\n"),
        LessonModule(type: .cameraCoach, title: "Energy break",
                     prompt: "Movement boosts focus. Let's do a quick set!",
                     move: "Squats", reps: 8),
        LessonModule(type: .practiceTimer, title: "Salsa basic step",
                     prompt: "Step on 1-2-3, pause on 4, step on 5-6-7, pause on 8.",
                     bpm: 92, beatsPerBar: 4, countLabels: ["1", "2", "3", "·", "5", "6", "7", "·"], durationSeconds: 45),
    ]
}

/// Minimal lesson-player stand-in: top bar, module, Check bar and feedback panel.
struct RealModulesDemoHost: View {
    @State private var index = min(max(0, RealDemo.startIndex), RealDemo.modules.count - 1)
    @State private var session: ModuleSession = RealModulesDemoHost.makeSession(RealDemo.startIndex)
    @State private var results: [Bool] = []

    static func makeSession(_ i: Int) -> ModuleSession {
        let clamped = min(max(0, i), RealDemo.modules.count - 1)
        return ModuleSession(module: RealDemo.modules[clamped], course: RealDemo.course, node: RealDemo.node, ai: AIRouter.make())
    }

    var body: some View {
        ZStack {
            IloBackground(tint: session.tint.base)
            VStack(spacing: 0) {
                topBar
                ModuleRouter.view(for: session)
                    .id(session.module.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if !session.hidesCheckBar && !session.isResolved {
                    Button(session.checkTitle) { session.check() }
                        .buttonStyle(.pill(.ink))
                        .disabled(!session.canCheck)
                        .padding(.horizontal, Metrics.gutter)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            if session.isResolved {
                VStack {
                    Spacer()
                    feedback.transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.isResolved)
        .onAppear { wire() }
        .task { await RealDemoShooter.run() }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            GlassIconButton(systemImage: "xmark", size: 42) { go(0) }
            GlossyProgressBar(progress: Double(index + 1) / Double(RealDemo.modules.count), tint: Palette.victory, height: 14)
            Menu {
                ForEach(Array(RealDemo.modules.enumerated()), id: \.offset) { i, m in
                    Button { go(i) } label: { Label(m.type.displayName, systemImage: m.type.symbol) }
                }
            } label: {
                BloubView(color: .ink, expression: session.mood, alive: true)
                    .frame(width: 34, height: 34)
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 6)
    }

    private var feedback: some View {
        let ok = session.phase == .correct
        return VStack(alignment: .leading, spacing: 10) {
            Label(ok ? "Nicely done!" : "Not quite", systemImage: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.display(22, weight: .heavy))
                .foregroundStyle(ok ? Palette.success : Palette.danger)
            if let f = session.feedback { Text(f).font(.body(15, weight: .medium)).foregroundStyle(Palette.ink2) }
            if let c = session.correctAnswer { Text("Answer: \(c)").font(.body(14, weight: .semibold)).foregroundStyle(Palette.ink) }
            if session.bonusXP > 0 { Chip(text: "+\(session.bonusXP) bonus XP", systemImage: "bolt.fill", fill: Palette.butter) }
            Button("Continue") { session.finish() }
                .buttonStyle(.pill(ok ? .success : .danger))
                .padding(.top, 4)
        }
        .padding(Metrics.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ok ? Palette.successSoft : Palette.dangerSoft, in: .rect(cornerRadius: 30, style: .continuous))
    }

    private func wire() {
        session.onResolve = { results.append($0) }
        session.onFinish = { go((index + 1) % RealDemo.modules.count) }
    }

    private func go(_ i: Int) {
        index = i
        session = Self.makeSession(i)
        wire()
    }
}

/// Launch with `-demoShots "2,5.5,9"` to write in-app screenshots (Documents/shot_N.png) at those times after launch.
@MainActor
enum RealDemoShooter {
    static func run() async {
        guard let raw = UserDefaults.standard.string(forKey: "demoShots") else { return }
        let times = raw.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        let start = Date()
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for (i, t) in times.enumerated() {
            let wait = t - Date().timeIntervalSince(start)
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.keyWindow else { continue }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.2
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            try? image.pngData()?.write(to: docs.appendingPathComponent("shot_\(i + 1).png"))
        }
    }
}

#Preview("Real modules") {
    RealModulesDemoHost()
}
#endif
