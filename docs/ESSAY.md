## Inspiration

This is the second of my two Shipaton apps. The first one, Stick, is about getting off the scroll. This one is about what I want to do with the time I get back.

When I got my first phone I didn't install a single game. I installed Duolingo and started learning English that same day. I'm on a 301-day streak now. The owl taught me something I didn't expect: the lessons weren't what kept me coming back. The path did. A little circle waiting for me every day, small enough to say yes to.

And then I'd want to learn something that wasn't a language, and the path disappeared. Chess openings, how to code a website, a book everyone keeps quoting. What I got instead was forty open tabs, a three-hour YouTube playlist and a plan I'd abandon by Thursday. The content exists. What doesn't exist is the path.

So the question for ilo was simple. What if Duolingo worked for *anything*?

The first goal I typed into it, before any of it existed, was "salsa for my grandma's wedding". I kept that example the whole way through, because it's the hardest kind of goal to teach. It's physical, it's rhythmic, it has a deadline, and it matters to someone. If an app can turn that into a daily path you can actually follow, it can handle "learn Atomic Habits".

## What it does

You type a goal. ilo asks you five quick questions: why it matters, when you need it, how much you already know, how you like to learn, and how many minutes you have a day. Then you watch it build your path live.

- **Research, then a path.** Claude searches the web for your goal, reads the best sources, and designs a Duolingo-style path of units and nodes. Every node gets a brief: what to teach, 2–4 concrete facts, the common mistake to fix, and what you should be able to do afterwards.
- **Lessons written when you tap.** A lesson doesn't exist until you tap its node. ilo then writes it from the brief, adapted to your level and your last mistakes. The next two lessons are generated in the background while you play, so you never wait.
- **23 kinds of exercises.** The AI picks and arranges them per lesson and per topic:
  - Learn: story cards, audio lessons with karaoke captions, flashcards.
  - Practice: quizzes, swipe true/false, match, reorder, word bricks, fill-the-gap, free answers graded by AI, roleplay chats.
  - Real world: photo-proof missions, a live code lab with a preview, a camera coach that counts your reps with Vision, a haptic metronome that taps "1-2-3 · 5-6-7" into your hand for salsa, and live voice calls with ilo.
  - Ones I invented: *Guess it*, *Spot the mistake*, *Sort it*, *Teach ilo* (explain it like ilo is five), *Speed round*, *What would you do?*, *Find it*.
- **The game around it.** XP and levels, streaks with freezes, daily quests and a friend quest, 15 badges, chests, gems, and eight weekly leagues named after the mascot's shapes, from Pebble to Apex. Real cohorts need the backend. Offline, the league runs on simulated rivals, and the screen says so.
- **ilo, the mascot.** An animated blob with sixteen expressions that reacts to every answer. It looks at what you type, falls asleep when you haven't played today, and turns into three thinking dots while the AI works. Every player also designs their own blob, which becomes their avatar in the leagues.

Two rules I cared about more than any feature:

1. **The learning has to leave the screen.** A salsa course that only asks multiple-choice questions teaches you to pass a quiz about salsa. So there are missions ("dance the basic step in your kitchen for two minutes, send a photo"), a metronome that counts beats in haptics, and a camera coach that counts your steps.
2. **You see what you get before you pay.** The path is built during onboarding, before the paywall, so the price is for something you've already seen.

## How I built it

I built ilo in one day, September 30: 29 commits, about 26,000 lines of Swift, from an empty folder at 1:43 am. I don't write Swift by hand. I built it with Claude Code, and my job was the precision of what I asked for and the shape of the system: what the AI is allowed to decide, what the code decides, and what happens when something fails.

**Five builders at once.** I first wrote the shared foundation myself with Claude: the data models, the design system, the mascot engine, and one contract every lesson module had to follow. Then I ran five agents in parallel, each in its own copy of the repo with its own simulator:

- onboarding and paywall,
- the lesson player and 15 core modules,
- the 8 real-world modules,
- home, path, leagues and profile,
- the AI brain and the backend.

After that I merged everything and spent the rest of the day making it one app.

**The model writes, the code checks.** Every lesson module is one flat JSON object with a type and the fields that type needs. The model can pick any module it wants, but the app validates every one (options present, answer index in range, every sorting item in a real bucket), drops the ones that can't be played, and shuffles answers so the right one isn't always A. A lesson with a broken quiz loses the quiz. The lesson still plays.

**Bring your own Claude.** In onboarding you connect your own Anthropic API key:

- The key is stored in the iPhone's Keychain and sent only to api.anthropic.com.
- Planning is two calls: a research call with live web search, then a design call that returns the path as structured output. They're separate because citations and structured outputs can't share a request.
- Lessons, grading and voice conversations run on Claude Opus 5.5, with server-side refusal fallback.

**Everything has a plan B.** Skip the key, lose the network, or run out of credit, and ilo switches to its offline brain:

- three hand-written flagship courses (salsa, a first website, Atomic Habits) with 18 full lessons,
- a composer that builds a sensible path for any other goal,
- Apple's on-device model when the phone has one.

A 12-second probe and a circuit breaker make sure the on-device model can never hang a lesson.

**The mascot is real code.** ilo started as an open-source SVG animation. I ported its geometry to Swift: 64-point silhouettes that morph between eight shapes, eyes projected on a virtual sphere with yaw, pitch and roll, and a blink schedule from a seeded random generator.

**Feel.** Native iOS 26 Liquid Glass on the floating controls; solid, pressable 3D buttons where your thumb lands, like Duolingo. Custom Core Haptics patterns for correct, wrong, streak, level-up, the hold-to-commit charge and every metronome beat. Every sound effect is synthesized in code, so the app ships with zero audio files.

**Tests that tap.** 22 UI tests drive the real app with real taps:

- the whole onboarding, through the paywall and the purchase;
- a full lesson from the path to the celebration;
- every tab, and one test per core module.

They found ten bugs I would have shipped, including the Create flow landing on a blank screen.

## How it makes money (RevenueCat)

The product is a learning habit, so the main product is a subscription with a real trial.

- **Plans.** Annual at $79.99 with a 7-day free trial, shown as about $1.53 a week, computed from the store price in the user's currency. Weekly at $7.99 as the anchor. The paywall shows the trial as a timeline: today, full access; day 5, we remind you; day 7, you're billed, with the actual date.
- **Hard paywall at the moment of proof.** It comes after you've watched your own path being built and made a promise to yourself, not before. Its headline is your course title: "Your *Salsa, wedding-ready* path is ready."
- **One `pro` entitlement, one `default` offering** with `$rc_annual` and `$rc_weekly` packages, so prices and plans change from the dashboard without an update.
- **Live access.** `customerInfoStream` drives access, so renewals, expiries, refunds and restores unlock or lock ilo without a relaunch. Trial eligibility is checked before the paywall promises a free week.
- **Anyone can test it.** The Test Store in development means anyone who clones the repo can buy in the simulator without an Apple account. When no key is configured, a StoreKit configuration file is the fallback.
- **One identity.** When the backend is on, the RevenueCat app user ID is the Supabase user ID, so the server can check `pro` before spending anything.
- **Bring-your-own-Claude protects the margin.** The expensive part of an AI tutor is tokens, and a heavy learner can cost more than their subscription. With your own key, the subscription pays for the product (the path engine, the 23 modules, the game, the mascot) and the AI is billed at cost by Anthropic. Nobody sits in the middle marking it up.

## Challenges I ran into

**Five agents, one app.** Parallel builders are fast until you merge.

- Tapping Continue twice skipped a module.
- Opening a node while it was prefetching generated the same lesson twice, and paid for it twice.
- "Pass a code lab" unlocked when you failed the code lab.
- Two files had the same name and the build refused to start.

None of these were visible in any one agent's work. I fixed them with a QA pass over every flow, then the UI tests.

**A machine at load 380.** Six simulators booted at once, five compilers and a screen recorder: the Mac's load average hit 387 and the simulators froze mid-screenshot. I shut down every simulator I didn't need and moved all testing to one device.

**The mascot I loved wasn't mine.** The blob I built ilo around is an MIT-licensed recreation of another company's bot avatar. The license let me use it, but I didn't want my app's face to be a copy. So ilo got its own colour, electric blue, and its own name, and the original author is credited in the repo.

**Who pays for the AI.** My first backend routed every lesson through my own server and my own API key. That's fine for ten users and a disaster for a thousand. Letting learners bring their own Claude fixed the economics, and the offline brain means nobody is locked out.

**Honest offline mode.** My first offline brain showed "Reading Wikipedia…" while building a path, and it wasn't reading anything. It now says what it actually does ("Drawing on ilo's expert library, curated, offline"). The live "Claude is researching the web" line appears only when Claude really is.

## Accomplishments that I'm proud of

My favourite moment in ilo is halfway through the salsa lesson, when the quiz stops and your phone starts tapping "one, two, three… five, six, seven" into your hand. That's where it stops being a quiz app.

- A 15-step onboarding that builds your real path before you pay.
- 23 module types, and lessons that survive a bad AI answer instead of crashing on it.
- An app that works fully offline and gets smarter the moment you connect Claude.
- A mascot engine with 16 expressions that reacts to everything you do.
- 22 UI tests that play the app like a person would.

## What I learned

- **The model picks, the code verifies.** The AI can choose any exercise it wants. The app decides whether it's playable.
- **Build the contract before the team.** Five agents could work at once only because every module had the same small interface. The bugs all lived where two agents' work met.
- **The path is the product.** Content is everywhere. A small circle that's waiting for you today is not.
- **Show before you charge.** People can say yes to a price when they're looking at the thing they're paying for.

## What's next for ilo

- Ship it on the App Store, with the backend on for real leagues and friend quests.
- Shared courses: when a hundred people type "learn chess openings", build the path once and let everyone start instantly.
- Camera coach for more than steps: posture, form, and hand positions for instruments.
- A path you can share with a friend, so you can race each other to the wedding.
