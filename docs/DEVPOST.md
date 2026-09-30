# Devpost: everything to fill in for the Shipaton (Next Gen Award)

Deadline: **Sep 30, 2026, 11:45 pm PDT = Oct 1, 08:45 Paris.** Register and submit with your **student email**
(the email domain is checked against JetBrains/swot). If you're under 18, a parent or guardian must complete the consent
form (https://forms.gle/Gx2Cr4X8WPk9V1q77) before the deadline.

---

## Project name
```
ilo
```

## Elevator pitch (max 200 characters)
```
Duolingo for anything. Type any goal, Claude researches it and builds your path, and every lesson is written the moment you tap it. 23 kinds of exercises, streaks and leagues.
```

## Project story (the "About the project" markdown)
Paste the whole of `docs/ESSAY.md`. It uses Devpost's section headings: Inspiration, What it does, How I built it,
How it makes money (RevenueCat), Challenges, Accomplishments, What I learned, What's next.

## Built with (tags)
```
swift, swiftui, ios, liquid-glass, revenuecat, storekit, claude, anthropic, core-haptics, avfoundation, speech, vision, webkit, foundation-models, supabase, postgresql, deno, xcuitest
```

## "Try it out" links
- Code repository: https://github.com/chessoren/ilo
- Demo video: *your YouTube link*

## Video demo link
Upload `docs/assets/ilo-demo.mp4` (with captions, under 2 minutes) to YouTube as **Public**, then paste the link.
- Title: `ilo: Learn anything, like it's a game (RevenueCat Shipaton 2026)`
- Description: the elevator pitch + `Code: https://github.com/chessoren/ilo`
- No music was added; the video has no copyrighted material.

## Image gallery (3:2, PNG/JPG, max 5 MB each)
Upload in order: `docs/deck/slide-01.png` … `docs/deck/slide-14.png`.
The first image is the thumbnail, so slide 01 goes first.

## Required files
| Field | File |
|---|---|
| App icon 1024×1024 | `docs/deck/logo-1024.png` (or `docs/assets/icon-1024.png`) |
| Screenshot 1179×2556, no device frame | `docs/assets/screenshot-05-home.png` (and any others from `docs/assets/`) |

## Category / prize questions
- **Category:** Next Gen Award (student).
- **Published app URL:** not required for Next Gen. Give the repository URL instead.
- **Repository:** https://github.com/chessoren/ilo. It's public, with the MIT license visible in the About section.
- **Free trial / promo code for judges:** not required for Next Gen. You can still write:
  "Clone the repo and run the `ilo` scheme. Purchases use RevenueCat's Test Store in Debug, so anyone can buy in the
  simulator without an Apple account."

## Testing instructions (if asked)
```
1. git clone https://github.com/chessoren/ilo && open ilo.xcodeproj
2. Run the "ilo" scheme on an iOS 26+ simulator (Xcode 26 or newer).
3. Onboarding: type any goal. On "Connect your Claude" either paste an Anthropic API key (live web research + lessons
   written by Claude Opus 5.5) or tap "Skip for now" to use ilo's offline brain (salsa, website and Atomic Habits
   flagships + any other goal).
4. Paywall: purchases go through RevenueCat's Test Store. Tap "Start my free week".
5. Optional DEBUG launch arguments: -seedDemo (demo profile), -demoLesson -demoModule codeLab (jump to a module).
UI tests: xcodebuild test -scheme ilo -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## How does the project use RevenueCat? (if asked separately)
```
The RevenueCat SDK powers ilo's subscription:
- The hard paywall comes right after the learner watches their personalized path being built.
- Plans: annual $79.99 with a 7-day free trial (shown as a timeline, with the real billing date), and weekly $7.99 as the anchor.
- One `pro` entitlement and a `default` offering with $rc_annual / $rc_weekly packages, so plans change from the dashboard without an app update.
- customerInfoStream drives access live (renewals, expiries, refunds, restores), and trial eligibility is checked before promising a free week.
- A local reminder fires two days before the trial converts.
- When the backend is on, the RevenueCat app user ID is the Supabase user ID, so the server can check `pro` before spending AI credits.
- The Test Store in Debug lets anyone who clones the repo buy in the simulator.
- Learners bring their own Anthropic key, so the subscription pays for the product rather than subsidizing tokens, which keeps the margin healthy.
```

## Team
Solo. You.
