# ilo — shared brief for every builder

ilo is "Duolingo for learning anything". The learner types a goal ("salsa for my grandma's wedding", "code my first website",
"Atomic Habits"), an AI agent researches it and builds a Duolingo-style path of nodes. Each node has a `brief`; its lesson is
generated on demand (and prefetched) as a list of `LessonModule`s the AI picks and arranges.

Contest: RevenueCat Shipaton 2026 — Next Gen award. Judged on a <2 min demo video + open-source repo. Judges: idea, working core,
thoughtful RevenueCat use, technical care. **Everything must look stunning and actually work.** App language: **English**.

## Stack
- SwiftUI, iOS 26+ (Xcode 27, iOS 27 SDK). Native Liquid Glass. Swift 6 (default isolation = nonisolated; views are MainActor).
- Project uses **file-system synchronized folders**: just create `.swift` files under `ilo/` — no pbxproj edits needed.
- Build: `xcodebuild -project ilo.xcodeproj -scheme ilo -destination 'platform=iOS Simulator,id=<YOUR_SIM_ID>' -derivedDataPath build/dd build`
- Run: `xcrun simctl boot <id>; xcrun simctl install <id> build/dd/Build/Products/Debug-iphonesimulator/ilo.app; xcrun simctl launch <id> app.ilo.learn`
- Screenshot: `xcrun simctl io <id> screenshot /path.png` then Read the png to look at it. **Iterate visually.**
- Never use the simulator 5E60E821-C9EF-4F6E-96D8-E1317BD50F75 (it has another app's overlay).

## Design language (copy these references)
Three Dribbble shots the founder loves:
1. Off-white canvas (#F3F4F8), white rounded cards (radius 28–40, soft shadow), **periwinkle** (#8FA8F7) as brand colour,
   **black pill** CTAs and black pill tab bar, pastel cards (peach/orange, pink/orchid, lavender, mint), "Hello, Sophia" greeting,
   big radial ticked progress ring with "42%", chips like "2 lessons for today", avatar stack rows, stat cards ("Hours 32 / Lessons 16").
2. "My Progress" with two pastel stat tiles (Completed 56%, Lessons 21/23), badge row of circles, dark activity bar chart card
   with a striped highlighted bar and a tooltip pill, "Welcome to RoboLearn" onboarding with big bold type and a highlighted word block,
   bottom "Skip / → Next" slider pill.
3. Periwinkle full-bleed screen "Check your learning roadmap" with a line-art illustration, week day selector with circle states,
   black list rows with white circle icons and chevron pills, category chips (Logic / Visual / Focus), colourful course cards with
   "1/3" ring counters, AI assistant card with glowing orb + mic/camera buttons, a Gantt-like roadmap.

Palette is **hybrid**: periwinkle UI; vivid Duolingo blue (`Palette.victory`) ONLY for wins (XP, streak, lesson complete).
Liquid Glass (`.glassEffect`, `GlassEffectContainer`, `glassEffectID` morphs, `.buttonStyle(.glass)`) on **floating chrome**:
top stat pills, close/back buttons, bottom Check bar, sheets, tab bar, floating overlays. Solid, tactile surfaces for path nodes & answer tiles.
Never stack glass on glass. Keep text legible.

## Mascot: bloub
`BloubView(shape:color:expression:mode:lookAt:alive:tint:)` — animated blob with 16 expressions (`BloubExpression`),
8 shapes (`BloubShape`), 12 colours (`BloubColor`), modes `.face / .thinking (3 pulsing dots — use for AI loading) / .sleeping`.
**ilo** (the AI teacher) = ink circle bloub. Each player has their own bloub (`player.bloubShape/bloubColor`) used as avatar everywhere.
Make ilo react to everything (correct → happy/proud/excited, wrong → sad/confused, waiting → thinking, idle → attentive).
Change expression with SwiftUI state; the view morphs smoothly. Add bounce/squash with keyframeAnimator around it.

## Motion & feel (non-negotiable)
Every screen must have exceptional animation + haptics:
- `Haptics.shared` : tap, softTap, press, thud, tick, correct, wrong, celebrate, ignite, heartbeat, charge(p), beat(accent:), levelUp, warning.
- `SoundFX.shared.play(.tap/.pop/.bubble/.correct/.wrong/.complete/.coin/.streak/.whoosh/.tick/.levelUp)`.
- Staggered entrances (`.appear(visible, delay:)`), springy presses (`.buttonStyle(.squish)`, `.pill(kind)`), `contentTransition(.numericText())`,
  `symbolEffect`, `matchedGeometryEffect`, `PhaseAnimator/KeyframeAnimator`, `ConfettiView(trigger:)`, `CountUpText`, `TickRing`, `GlossyProgressBar`.
- Respect Reduce Motion where cheap.

## Shared code you can use (do NOT modify these files; add extensions in your own folder if needed)
- `DesignSystem/` Theme (Palette, CourseTint, Font.display/.body, Metrics, IloBackground), Components (PillButtonStyle, SquishButtonStyle,
  GlassIconButton, .card(), .glassCard(), .appear(), Chip, StatPill, TickRing, GlossyProgressBar, ConfettiView, CountUpText, SectionHeader),
  Haptics, SoundFX.
- `Bloub/` BloubView etc.
- `Models/` Course, CourseUnit, PathNode, NodeKind, CourseCategory, LearnerLevel, Lesson, LessonModule (flat payload), ModuleType,
  Player, PlayerLevel, LeagueTier, Badge, Takeaway, Friend, CourseProgress, NodeState, Quest, FriendQuest, LeaderboardEntry, LessonResult.
- `App/AppModel.swift` (@Observable, in environment): player, courses, progress, lessons cache, quests, `lesson(for:in:)` async (generates + caches),
  `prefetch`, `complete(_ LessonResult) -> RewardSummary`, `state(of:in:)`, `currentNode(in:)`, `completion(of:)`, `openChest`, `claim`, `buy`, `recordMistake`, `reset`.
- `Services/AIContract.swift` LearningAI protocol (planCourse w/ streamed PlanStep, generateLesson, grade, chat), CourseRequest, Grade, ChatMessage.
- `Features/Lesson/ModuleSession.swift` — THE module contract (read it).
- `PurchaseService` (@Observable, in environment) — `isPro`.

If you truly must change a shared file, keep the change minimal and additive, and list it in your final report.

## Quality bar
- Every button works. No dead ends. No placeholder text like "Lorem" or "TODO" on screen.
- Handle empty/loading/error states with bloub (thinking / sad + retry).
- Build must succeed with zero errors before you finish. Screenshot your screens and fix what looks off.
- Commit your work in your worktree with clear messages when done.
