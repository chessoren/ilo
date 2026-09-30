# Shipaton 2026 — Next Gen submission kit

Deadline: **Sep 30, 2026 11:45 pm PDT = Oct 1, 08:45 Paris**. Submit on Devpost with your student email.

## Checklist
- [ ] Public GitHub repo, MIT `LICENSE` visible in the About section
- [ ] Demo video < 2 min on YouTube (public or unlisted-but-visible → use **Public**), showing the app running on the device
- [ ] 1024×1024 icon → `docs/assets/icon-1024.png`
- [ ] Screenshot 1179×2556, no device frame → `docs/assets/screenshot-*.png`
- [ ] Text description (below)
- [ ] Category: **Next Gen Award**

## Devpost text

**ilo — Learn anything, like it's a game.**

Type any goal — "salsa for my grandma's wedding", "code my first website", "Atomic Habits" — and ilo's AI agent researches it,
designs a Duolingo-style path, and generates each lesson the moment you tap it.

**How it works**
- A research agent turns a goal into a path of units and nodes, each with a brief. Lessons are generated on demand from that
  brief (and the next ones are prefetched, so there's no waiting).
- The AI composes every lesson from 23 module types, choosing the ones that fit the topic:
  - Learn: stories, audio lessons with karaoke captions, flashcards.
  - Practice: quizzes, swipe true/false, match, reorder, word bricks, fill-the-gap, free answers graded by AI, roleplay chats.
  - Real world: photo-proof missions, a live code lab, a camera coach that counts your reps with Vision, a haptic metronome
    ("1-2-3 … 5-6-7" for salsa), and live voice calls with ilo.
  - ilo originals: Guess it, Spot the mistake, Sort it, Teach ilo (Feynman technique), Speed round, What would you do?, Find it.
- Meet ilo, an animated mascot with 16 expressions who reacts to every answer. Every player also gets their own customizable
  mascot as their avatar.
- Game loop: XP, streaks with freezes, 8 weekly leagues named after the mascot's shapes, daily and friend quests, badges,
  chests, gems.
- Design: native iOS 26 Liquid Glass, custom Core Haptics patterns for every moment, synthesized sound design, and
  choreographed animations.

**RevenueCat**
- ilo has a hard paywall after the "aha" moment: the learner sees their own personalized path first, then the paywall
  offers a 7-day free trial on an annual plan, with a weekly plan as the price anchor.
- Purchases, restores, trial eligibility and the `pro` entitlement all run through the RevenueCat SDK (Test Store in
  development).
- AI generation is the main per-user cost, so the backend only serves lesson generation to entitled users. Pricing is set
  from the per-course AI cost.

**Tech**: SwiftUI (iOS 26+), Liquid Glass, Core Haptics, AVFoundation, Speech, Vision, WebKit, and Apple Foundation Models
as an offline fallback. Backend: Supabase (auth, Postgres leaderboards, edge functions) routing to multiple models through
OpenRouter. The app works fully offline with a curated local AI brain, so it can be judged without any keys.

## Video script (≤ 2:00) — captioned screen recording, no narration needed
The captioned cut (1:53, 1080×2348 H.264, no music) is at `docs/assets/ilo-demo.mp4`, with a phone-friendly copy
(720 wide, ~23 MB) at `docs/assets/ilo-demo-small.mp4`. Both are kept out of git because of their size; regenerate by
running `DemoReelTests.testDemoReel` (with `TEST_RUNNER_ILO_REEL=1`) while `xcrun simctl io <id> recordVideo` is capturing,
cutting with the scene markers the test writes, and burning in the captions and cards with AVFoundation
(`AVVideoCompositionCoreAnimationTool`). Timings below match that cut; the captions can double as a voice-over.

| Time | Shot | Caption |
|---|---|---|
| 0:00–0:02 | Title card: ilo icon, "ilo", "Learn anything. Like it's a game." | — |
| 0:02–0:06 | Welcome: "Learn anything. Like it's a game." → How it works | — |
| 0:06–0:11 | Type "Salsa for my grandma's wedding" | "Type any goal" |
| 0:11–0:17 | Why / deadline / level / styles / minutes → name "Sophia" | "Tell ilo why it matters" |
| 0:17–0:20 | Bloub maker (shape + colour) → daily reminder | "Design your own ilo" |
| 0:20–0:22 | Connect your Claude (Anthropic key or skip to the offline brain) | "Connect your own Claude, or go offline" |
| 0:22–0:30 | Building screen: live research steps with sources → path ready | "Claude researches the web and builds your path" |
| 0:30–0:34 | Hold-to-commit (14-day pledge) | "Commit to your streak" |
| 0:34–0:40 | Paywall → trial timeline and plans → Start my free week → Welcome to ilo Pro | "Free week, powered by RevenueCat" |
| 0:40–0:42 | Home | — |
| 0:42–0:46 | Path → node 1 "Meet salsa" → lesson intro | "Lessons are written the moment you tap" |
| 0:46–1:09 | Story cards, quiz, match pairs, swipe true/false, "what would you do?" scenario | "23 kinds of exercises" |
| 1:09–1:14 | Salsa metronome counting 1-2-3 · 5-6-7 | "A haptic metronome for salsa" |
| 1:14–1:22 | Code lab: type HTML → live preview → Run & check → "Great job!" | "A live code lab" |
| 1:22–1:29 | Lesson complete: streak flame, daily goal, quest complete, new badges | "Streaks, XP, badges" |
| 1:29–1:36 | Leagues → Quests (claim) → Profile | "Weekly leagues and quests" |
| 1:38–1:47 | Create tab: "Code my first website" → path building → "Your first website" | "Any goal: Code my first website" |
| 1:47–1:50 | Home: daily goal 100% | "ilo. Learn anything. Like it's a game." |
| 1:50–1:53 | End card: ilo icon, github.com/chessoren/ilo, RevenueCat Shipaton 2026 | — |

Tips: turn on Do Not Disturb, 100% battery icon, clean status bar (`xcrun simctl status_bar <id> override --time 9:41 --batteryLevel 100` if recording on simulator; the rules ask for the device it was built for, so an iPhone recording is best). No copyrighted music: use no music or a royalty-free track you have rights to.
