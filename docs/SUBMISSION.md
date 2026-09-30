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

## Video script (≤ 2:00) — screen recording + voice-over
A raw, silent 1:52 cut recorded from the simulator is at `docs/assets/demo-raw.mp4` (kept out of git because of its size;
regenerate it by running `DemoReelTests.testDemoReel` while `xcrun simctl io <id> recordVideo` is capturing, then cutting
with the scene markers the test writes). Timings below match that cut, so the narration can be read in sync.

| Time | Shot | Voice-over |
|---|---|---|
| 0:00–0:07 | Splash: ilo mascot morphs through shapes → "ilo" → "Learn anything. Like it's a game." | "What if Duolingo worked for anything you want to learn?" |
| 0:07–0:23 | How it works → type "Salsa for my grandma's wedding" → why / deadline / level / styles / minutes → name "Sophia" → purple bloub → reminders | "Tell ilo your goal. It asks what matters: why, when, how much you already know. Then you make your own mascot." |
| 0:23–0:32 | Building screen: live research steps with sources, path cascading in unit by unit | "An AI agent researches the topic and designs your full path, unit by unit." |
| 0:32–0:43 | Hold-to-commit (14-day pledge) → paywall → trial timeline and plans → Start my free week → Welcome to ilo Pro | "Commit to your streak and start your free week, powered by RevenueCat." |
| 0:43–1:12 | Home → path → node 1 "Meet salsa" → story cards, quiz, match pairs, swipe true/false, "what would you do?" scenario | "Every lesson is generated on the spot and mixes 23 module types: stories, quizzes, matching, swipe true or false, real-life scenarios." |
| 1:12–1:18 | Salsa metronome counting 1-2-3 · 5-6-7 | "For salsa, a haptic metronome counts the basic step with you." |
| 1:18–1:25 | Code lab: type HTML → live preview → Run & check → "Spot on!" | "For code, a real editor with a live preview." |
| 1:25–1:33 | Lesson complete: confetti, XP, streak flame, daily goal, quest complete, new badges | "Streaks, XP, quests, badges…" |
| 1:33–1:42 | Leagues → Quests (claim) → Profile | "…and leagues: all the addictive parts of a game." |
| 1:42–1:49 | Create tab: "Code my first website" → path building → "Your first website" | "Any new goal becomes a full path in seconds." |
| 1:49–1:52 | Home: daily goal 100% (add the logo end card here) | "ilo. Learn anything. Like it's a game." |

Tips: turn on Do Not Disturb, 100% battery icon, clean status bar (`xcrun simctl status_bar <id> override --time 9:41 --batteryLevel 100` if recording on simulator; the rules ask for the device it was built for, so an iPhone recording is best). No copyrighted music: use no music or a royalty-free track you have rights to.
