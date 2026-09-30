import Foundation

/// Flagship: "Atomic Habits" (James Clear, 2018) — the ideas, applied to the learner's own life.
/// Ideas are paraphrased and taught through original examples; no text from the book is reproduced.
enum CuratedHabits {
    static let flagship = Flagship(
        id: "habits",
        title: "Atomic Habits, applied",
        tagline: "Tiny changes, remarkable results — in your own life.",
        symbol: "atom",
        tint: .butter,
        category: .book,
        strong: ["habit", "habits"],
        keywords: ["routine", "routines", "discipline", "procrastination", "consistency", "clear"],
        phrases: ["atomic habits", "james clear", "atomic habit"],
        units: [
            Flagship.Unit(title: "The power of tiny", outcome: "Explain why 1% changes compound and why systems beat goals", tint: .butter, nodes: [
                .init(title: "1% better", brief: "Habits are the compound interest of self-improvement: 1% better daily ≈ 37× better in a year. British Cycling's marginal gains. The plateau of latent potential.",
                      kind: .story, symbol: "chart.line.uptrend.xyaxis", content: onePercent),
                .init(title: "Systems over goals", brief: "Winners and losers share the same goals; the difference is the system. Goals set direction, systems make progress. Fall in love with the process.",
                      kind: .lesson, symbol: "gearshape.2.fill", content: systems),
                .init(title: "Identity first", brief: "Three layers of change: outcomes, processes, identity. Start with who you want to become; each action is a vote for that identity.",
                      kind: .lesson, symbol: "person.crop.circle.badge.checkmark", content: identity),
                .init(title: "Treasure chest", brief: "A reward for starting.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Habit scorecard", brief: "Mission: list your daily habits from waking up, and mark each + (good), − (bad) or = (neutral) for the person you want to become.",
                      kind: .mission, symbol: "list.clipboard.fill", content: scorecard),
                .init(title: "The habit loop", brief: "Every habit runs on cue → craving → response → reward. The four laws come from this loop: obvious, attractive, easy, satisfying.",
                      kind: .lesson, symbol: "arrow.triangle.2.circlepath", content: habitLoop),
                .init(title: "Tiny boss", brief: "Boss battle on compounding, systems, identity and the habit loop.", kind: .boss, symbol: "crown.fill", content: tinyBoss),
            ]),
            Flagship.Unit(title: "Obvious & attractive", outcome: "Design cues and cravings that pull you toward good habits", tint: .orange, nodes: [
                .init(title: "When and where", brief: "Implementation intentions: 'I will [behaviour] at [time] in [location].' Vague plans fail; specific plans get done.",
                      kind: .lesson, symbol: "calendar.badge.clock", content: .seed(implementation)),
                .init(title: "Habit stacking", brief: "'After [current habit], I will [new habit].' Anchor new habits to ones you already do, with a specific, well-timed cue.",
                      kind: .practice, symbol: "square.stack.fill", content: .seed(stacking)),
                .init(title: "The cafeteria trick", brief: "Story: environment design — making cues visible (water by the register, the guitar in the living room) beats relying on motivation.",
                      kind: .story, symbol: "cup.and.saucer.fill", content: .seed(cafeteria)),
                .init(title: "Treasure chest", brief: "A reward for obvious cues.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Temptation bundling", brief: "Pair something you need to do with something you want to do. Join a culture where your desired behaviour is normal.",
                      kind: .lesson, symbol: "gift.fill", content: .seed(bundling)),
                .init(title: "Habit chat with ilo", brief: "Live call: design one habit stack out loud with ilo.", kind: .call, symbol: "phone.fill", content: .seed(habitCall)),
                .init(title: "Cue boss", brief: "Boss battle on implementation intentions, stacking, environment and bundling.", kind: .boss, symbol: "crown.fill",
                      content: .review(intro: "Cue boss! Make it obvious, make it attractive — prove it.")),
            ]),
            Flagship.Unit(title: "Easy & satisfying", outcome: "Make good habits effortless and rewarding, and bad ones hard", tint: .mint, nodes: [
                .init(title: "The two-minute rule", brief: "Scale any new habit down to a version that takes under two minutes. Master showing up before optimising.",
                      kind: .lesson, symbol: "timer", content: .seed(twoMinutes)),
                .init(title: "Reduce friction", brief: "Law of least effort: remove steps before good habits, add steps before bad ones. Prime the environment; use commitment devices.",
                      kind: .practice, symbol: "slider.horizontal.3", content: .seed(friction)),
                .init(title: "Never miss twice", brief: "Story: habit tracking (the paper-clip strategy), immediate rewards, and bouncing back fast: missing once is an accident, twice is a new habit.",
                      kind: .story, symbol: "checkmark.circle.fill", content: .seed(neverMissTwice)),
                .init(title: "Quick review", brief: "Spaced review of the four laws.", kind: .review, symbol: "arrow.triangle.2.circlepath",
                      content: .review(intro: "Quick review — the four laws, mixed.")),
                .init(title: "Treasure chest", brief: "A reward for consistency.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Your habit plan", brief: "Mission: design one habit with all four laws and do it three days in a row. Proof: a photo of your tracker.",
                      kind: .mission, symbol: "flag.checkered", content: .seed(habitPlan)),
                .init(title: "Habits boss", brief: "The final boss on all four laws.", kind: .boss, symbol: "crown.fill",
                      content: .review(intro: "Final boss! All four laws. Then go build your system.")),
            ]),
        ],
        sources: [
            CourseSource(title: "Atomic Habits — James Clear", url: "https://jamesclear.com/atomic-habits"),
            CourseSource(title: "Habit stacking — James Clear", url: "https://jamesclear.com/habit-stacking"),
            CourseSource(title: "Implementation intention — Wikipedia", url: "https://en.wikipedia.org/wiki/Implementation_intention"),
            CourseSource(title: "Habit — Wikipedia", url: "https://en.wikipedia.org/wiki/Habit"),
        ],
        researchNotes: ["Mapping the book's four laws", "Turning big ideas into daily actions", "Finding real-life examples"]
    )

    // MARK: - Unit 1 (hand-written)

    static var onePercent: Flagship.Content {
        .lesson(intro: "What if getting 1% better every day was the whole secret?", modules: [
            .story("1% better", [
                storyCard("A tiny bet", "Get just 1% better every day for a year and you end up about 37 times better. Get 1% worse and you drop to nearly zero.", "chart.line.uptrend.xyaxis", .excited, highlight: "37 times better"),
                storyCard("The cycling miracle", "British Cycling was mediocre for decades. From 2003, coach Dave Brailsford chased tiny 1% improvements everywhere — pillows, hand-washing, bike seats.", "bicycle", .curious, highlight: "tiny 1% improvements"),
                storyCard("It compounded", "Within a few years British riders dominated the Olympics and the Tour de France. Small gains, stacked, became giant ones.", "trophy.fill", .proud),
                storyCard("The invisible phase", "Early on, results lag behind effort — like an ice cube in a cold room that doesn't melt until the temperature crosses freezing. Keep going.", "snowflake", .attentive, highlight: "results lag behind effort"),
            ]),
            .estimate("If you get 1% better every day for a year (1.01^365), how many times better are you?", min: 1, max: 100, answer: 37.8, unit: "×",
                      why: "1.01^365 ≈ 37.8. Tiny daily gains compound into huge change."),
            .mcq("Why do good habits often feel useless in the first weeks?", ["They don't work", "Results lag behind effort until they compound", "You picked the wrong habit"], 1,
                 why: "Clear calls this the plateau of latent potential: the work is stored up before it shows."),
            .tf("True or false?", [
                ("Habits compound like interest.", true, "Small daily differences add up over time."),
                ("British Cycling improved by searching for one big breakthrough.", false, "They stacked many tiny 1% gains."),
                ("If you see no results after a week, the habit is failing.", false, "Results lag behind effort."),
            ]),
            .scenario("You've been reading 10 pages a day for 3 weeks and feel no smarter. What do you do?",
                      ["Quit — it's not working", "Keep going; the gains are compounding under the surface", "Switch to 100 pages once a week"], 1,
                      consequences: ["You quit right before the compounding shows.", "Months later you've read a dozen books — and it shows.", "Big rare efforts rarely stick."],
                      why: "Early effort is stored, not wasted."),
            .fill1,
            .flash("Recap", [("1% better daily", "≈ 37× better in a year"), ("Marginal gains", "Many tiny improvements, stacked"),
                             ("Plateau of latent potential", "Results lag behind effort"), ("Habits work like…", "Compound interest for self-improvement")]),
        ], takeaways: ["1% better every day compounds to ~37× in a year.", "Results lag behind effort — keep going.", "Stack tiny gains."])
    }

    static var systems: Flagship.Content {
        .lesson(intro: "Goals are nice. Systems are what actually change your life.", modules: [
            .story("Systems over goals", [
                storyCard("Same goal, different result", "Every runner in a race wants to win. The goal can't be what separates winners from losers — everyone has it.", "flag.checkered", .curious),
                storyCard("Goal vs system", "A goal is the result you want ('run a marathon'). A system is the process that gets you there ('run 3 mornings a week, add 10% distance').", "gearshape.2.fill", .attentive, highlight: "A system is the process"),
                storyCard("The goal trap", "Goals make happiness wait for 'someday', and once reached, the motivation often disappears. Systems keep you going.", "hourglass", .sad),
                storyCard("Love the process", "Your results are mostly a product of your systems. Fix the system and the results follow.", "heart.fill", .proud, highlight: "product of your systems"),
            ]),
            .sort("Goal or system?", buckets: ["Goal", "System"],
                  [("Lose 5 kg", 0), ("Cook dinner at home 5 nights a week", 1), ("Write a novel", 0), ("Write 300 words every morning", 1), ("Get fit", 0), ("Walk after lunch daily", 1)],
                  why: "Goals are outcomes; systems are the repeatable actions that produce them."),
            .mcq("What's the main problem with focusing only on goals?", ["Goals are always too small", "Everyone has goals; the system is what makes the difference", "Goals are illegal"], 1),
            .match("Turn each goal into a system", [("Learn Spanish", "10 minutes of practice after breakfast"), ("Read more", "Read 5 pages before bed"),
                                                     ("Save money", "Auto-transfer on payday"), ("Get stronger", "Push-ups while the kettle boils")]),
            .free("Pick one goal you have. Rewrite it as a system — a small action you'll repeat.", rubric: ["States a goal", "Turns it into a repeatable action", "Includes when or how often"],
                  sample: "Goal: run a 10K. System: run for 20 minutes every Monday, Wednesday and Saturday morning before work.", title: "Your system"),
            .blank("Your results are mostly a product of your ___.", ["systems", "goals", "luck", "genes"], 0),
            .flash("Recap", [("Goal", "The result you want"), ("System", "The repeatable process"), ("The goal trap", "Happiness postponed to 'someday'"), ("Focus on", "The system")]),
        ], takeaways: ["Goals set direction; systems make progress.", "Fix the system and results follow."])
    }

    static var identity: Flagship.Content {
        .lesson(intro: "The deepest way to change a habit: change who you believe you are.", modules: [
            .story("Identity-based habits", [
                storyCard("Three layers", "Change can happen at three layers: outcomes (what you get), processes (what you do), identity (what you believe about yourself).", "square.3.layers.3d", .curious, highlight: "outcomes"),
                storyCard("Two smokers", "Offered a cigarette, one says 'No thanks, I'm trying to quit.' The other says 'No thanks, I'm not a smoker.' The second one wins.", "nosign", .attentive, highlight: "I'm not a smoker"),
                storyCard("Every action is a vote", "Each time you write, you cast a vote for 'I am a writer'. You don't need a unanimous vote — just a majority.", "checkmark.square.fill", .happy, highlight: "a vote"),
                storyCard("Two steps", "1) Decide the type of person you want to be. 2) Prove it to yourself with small wins.", "2.circle.fill", .proud),
            ]),
            .order("Order the three layers from outermost to deepest", ["Outcomes — what you get", "Processes — what you do", "Identity — what you believe"]),
            .mcq("Which statement is identity-based?", ["I want to run a marathon", "I'm trying to eat healthier", "I'm the kind of person who moves every day"], 2,
                 why: "It describes who you are, not what you want."),
            .bricks("Build an identity statement", ["I", "am", "the", "kind", "of", "person", "who", "reads", "daily"], distractors: ["want", "try", "someday"]),
            .scenario("You skipped the gym today. How do you think about it?", ["I'm just not a gym person", "One missed vote — the next workout is another vote for who I'm becoming", "I'll restart next month"], 1,
                      consequences: ["You turn a single miss into a fixed identity.", "You keep the identity and bounce back fast.", "A month of lost votes."],
                      why: "Identity is built by the majority of your votes, not by perfection."),
            .teach("Explain to ilo why 'I'm not a smoker' beats 'I'm trying to quit'.", rubric: ["Mentions identity / how you see yourself", "Mentions that the behaviour follows from identity"],
                   sample: "'I'm trying to quit' means you still see yourself as a smoker fighting temptation. 'I'm not a smoker' means the behaviour matches who you are, so there's nothing to fight."),
            .flash("Recap", [("Three layers", "Outcomes, processes, identity"), ("Start with", "Identity"), ("Each action", "A vote for who you're becoming"), ("Proof", "Small wins")]),
        ], takeaways: ["Start with who you want to become.", "Every action is a vote for an identity.", "You only need a majority."])
    }

    static var scorecard: Flagship.Content {
        .lesson(intro: "You can't change a habit you don't notice. Time for your habit scorecard.", modules: [
            .story("The habit scorecard", [
                storyCard("Autopilot", "Much of what you do each day happens automatically. Before changing habits, you need to see them.", "airplane", .sleepy),
                storyCard("Point and call", "Japanese train operators point at signals and say them out loud. It feels silly, but it sharply reduces mistakes by making the automatic conscious.", "hand.point.up.left.fill", .surprised, highlight: "making the automatic conscious"),
                storyCard("Your scorecard", "List your habits from waking up. Mark each: + helps the person you want to be, − hurts, = neutral.", "list.clipboard.fill", .attentive),
            ]),
            .sort("How would a person who wants to be healthier score these?", buckets: ["+ good", "− bad", "= neutral"],
                  [("Drink a glass of water on waking", 0), ("Scroll the phone in bed for 40 minutes", 1), ("Brush teeth", 2), ("Walk to the bus stop", 0), ("Snack from the vending machine", 1), ("Put on shoes", 2)],
                  why: "It's not about good or bad in general — it's about whether the habit helps the person you want to become."),
            .mcq("What's the goal of the habit scorecard?", ["Judge yourself harshly", "Become aware of habits you do on autopilot", "Count calories"], 1),
            .mission("Habit scorecard", "Write your own habit scorecard for today.",
                     steps: ["On paper, list everything you do from waking up until lunch", "Mark each habit +, − or =", "Circle one − habit you'd like to change",
                             "Circle one + habit you want to keep", "Take a photo of your scorecard"],
                     proof: "A photo of your habit scorecard"),
            .free("What surprised you about your scorecard?", rubric: ["Names a specific habit", "Says whether it helps or hurts their desired identity"],
                  sample: "I didn't realise I check my phone before I even get out of bed. That's a minus for someone who wants calm mornings.", title: "Reflect"),
            .tf("True or false?", [
                ("Point-and-call makes automatic actions conscious.", true, "Saying it out loud forces attention."),
                ("A habit is good or bad in itself, no matter your goals.", false, "It depends on who you want to become."),
            ]),
            .flash("Recap", [("Habit scorecard", "List habits, mark + / − / ="), ("Point and call", "Make the automatic conscious"), ("First step of change", "Awareness")]),
        ], takeaways: ["Awareness comes before change.", "Score habits against who you want to become."])
    }

    static var habitLoop: Flagship.Content {
        .lesson(intro: "Every habit — good or bad — runs on the same four-step loop.", modules: [
            .story("The habit loop", [
                storyCard("1. Cue", "Something triggers the habit: a time, a place, a feeling, a notification.", "bell.fill", .attentive, highlight: "triggers"),
                storyCard("2. Craving", "You want the change in state the habit brings — not the habit itself. You don't crave brushing teeth; you crave a clean mouth.", "sparkles", .curious, highlight: "change in state"),
                storyCard("3. Response", "The actual habit you perform — a thought or an action.", "hand.tap.fill", .happy),
                storyCard("4. Reward", "The payoff. It satisfies the craving and teaches your brain to repeat the loop next time.", "gift.fill", .proud),
                storyCard("The four laws", "To build a habit: make the cue obvious, the craving attractive, the response easy, the reward satisfying. To break one: invert them.", "4.circle.fill", .excited, highlight: "obvious"),
            ]),
            .order("Put the habit loop in order", ["Cue", "Craving", "Response", "Reward"], why: "Cue → craving → response → reward, then repeat."),
            .match("Match each law to its step", [("Make it obvious", "Cue"), ("Make it attractive", "Craving"), ("Make it easy", "Response"), ("Make it satisfying", "Reward")]),
            .highlight("Your phone buzzes, you want to know who texted, you check it, you see a funny meme. Tap the CUE and the REWARD.",
                       ["Your phone buzzes", "You want to know who texted", "You check it", "You see a funny meme"], find: [0, 3],
                       why: "The buzz is the cue; the meme is the reward. Wanting to know is the craving; checking is the response."),
            .mcq("To BREAK a habit, the first law becomes…", ["Make it invisible", "Make it louder", "Make it faster"], 0, why: "Inversion: invisible, unattractive, difficult, unsatisfying."),
            .blank("Cue → craving → ___ → reward.", ["response", "result", "rest", "routine"], 0),
            .speed("Loop check", seconds: 25, [
                ("The craving is for the change in state, not the habit itself.", true, "Clean mouth, not brushing."),
                ("The reward comes before the cue.", false, "Cue → craving → response → reward."),
                ("'Make it easy' matches the response.", true, "Less friction, more doing."),
                ("To break a habit, make it satisfying.", false, "Make it unsatisfying."),
            ]),
        ], takeaways: ["Cue → craving → response → reward.", "Build: obvious, attractive, easy, satisfying.", "Break: invert all four."])
    }

    static var tinyBoss: Flagship.Content {
        .lesson(intro: "Tiny boss! Compounding, systems, identity and the loop — go.", modules: [
            .speed("Warm-up round", seconds: 30, [
                ("1% better daily is about 37× better in a year.", true, "1.01^365 ≈ 37.8."),
                ("Winners and losers usually have different goals.", false, "They share goals; systems differ."),
                ("Identity is the deepest layer of change.", true, "Outcomes → processes → identity."),
                ("The habit loop starts with a reward.", false, "It starts with a cue."),
                ("Every action is a vote for an identity.", true, "You just need a majority."),
                ("Results show up immediately if the habit is good.", false, "They lag behind effort."),
            ]),
            .mcq("'I run every Tuesday and Friday at 7 am' is a…", ["Goal", "System", "Identity", "Reward"], 1),
            .match("Match the idea", [("Marginal gains", "Stacking tiny improvements"), ("Plateau of latent potential", "Effort before visible results"),
                                      ("Habit scorecard", "Noticing your habits"), ("Point and call", "Making the automatic conscious")]),
            .sort("Build or break?", buckets: ["Building a habit", "Breaking a habit"],
                  [("Make it obvious", 0), ("Make it invisible", 1), ("Make it easy", 0), ("Make it difficult", 1), ("Make it satisfying", 0), ("Make it unattractive", 1)]),
            .spot("Spot the mistakes in Jo's habit plan", ["Goal: become a runner", "Identity: 'I'm someone who's trying to run'", "System: run 20 minutes, 3 mornings a week",
                                                         "Cue: shoes by the bed", "Reward: none — rewards are for kids"],
                  wrong: [1, 4], why: "'Trying to run' isn't an identity statement, and skipping rewards breaks the loop."),
            .blank("Day to day, your results depend less on your goals than on your ___.", ["systems", "dreams", "friends", "luck"], 0,
                   why: "One of the book's central ideas: systems, not goals, drive progress."),
            .teach("Teach ilo the habit loop, with your own example.", rubric: ["Names cue, craving, response and reward", "Gives a personal example"],
                   sample: "Cue: I finish dinner. Craving: I want to relax. Response: I go for a 10-minute walk. Reward: I feel calm and proud, so I want to do it again."),
            .speed("Final round", seconds: 25, [
                ("Habit stacking and identity both make habits stick.", true, "Different laws, same goal."),
                ("A craving is for the habit itself.", false, "It's for the change in state."),
                ("British Cycling used marginal gains.", true, "From 2003 under Dave Brailsford."),
                ("Systems matter more than goals for daily progress.", true, "Goals set direction; systems make progress."),
            ]),
        ], takeaways: ["You understand the foundations of Atomic Habits.", "Next: make it obvious and attractive."])
    }

    // MARK: - Unit 2

    static let implementation = KnowledgeSeed(
        intro: "'I'll exercise more' fails. 'I'll walk at 7 am in the park' works. Here's why.",
        cards: [
            storyCard("Vague plans fail", "Most people think they lack motivation. Often they lack clarity: when and where exactly will it happen?", "questionmark.circle.fill", .confused, highlight: "they lack clarity"),
            storyCard("The formula", "'I will [behaviour] at [time] in [location].' It's called an implementation intention.", "text.badge.checkmark", .attentive, highlight: "implementation intention"),
            storyCard("Why it works", "Studies of implementation intentions show people who plan when and where are much more likely to follow through.", "chart.bar.fill", .happy),
        ],
        questions: [
            .q("Which plan is an implementation intention?", ["I'll read more this year", "I will read for 10 minutes at 9 pm in bed", "Reading is important"], 1),
            .q("What do vague plans usually lack?", ["Motivation", "Clarity about when and where", "Talent"], 1),
        ],
        statements: [.s("Deciding when and where makes you more likely to act.", true), .s("Motivation alone is the best predictor of doing a habit.", false),
                     .s("An implementation intention names a behaviour, a time and a place.", true)],
        pairs: [.p("Behaviour", "What you'll do"), .p("Time", "When you'll do it"), .p("Location", "Where you'll do it"), .p("Implementation intention", "The full plan")],
        blanks: [.b("I will [behaviour] at [time] in [___].", ["location", "mood", "budget"], 0)],
        practice: [.bricks("Build an implementation intention", ["I", "will", "meditate", "at", "7 am", "in", "my", "bedroom"], distractors: ["maybe", "someday", "try"])],
        takeaways: ["I will [behaviour] at [time] in [location].", "Clarity beats motivation."]
    )

    static let stacking = KnowledgeSeed(
        intro: "The easiest way to build a new habit: glue it to one you already have.",
        cards: [
            storyCard("Habit stacking", "'After [current habit], I will [new habit].' Your existing habit becomes the cue.", "square.stack.fill", .excited, highlight: "After [current habit]"),
            storyCard("Examples", "After I pour my coffee, I'll meditate for one minute. After I take off my shoes, I'll change into workout clothes.", "cup.and.saucer.fill", .happy),
            storyCard("Pick the right anchor", "Match frequency and timing: a daily habit needs a daily anchor that happens at the right moment and place.", "pin.fill", .attentive, highlight: "Match frequency and timing"),
        ],
        questions: [
            .q("Which is a habit stack?", ["I'll floss more", "After I brush my teeth, I will floss one tooth", "Flossing is healthy"], 1),
            .q("What makes a good anchor habit?", ["Something you do rarely", "Something you already do reliably, at the right time and place", "Something new"], 1),
        ],
        statements: [.s("An existing habit can serve as the cue for a new one.", true), .s("Any anchor works, even one you do once a month, for a daily habit.", false)],
        pairs: [.p("Anchor", "Your existing habit"), .p("New habit", "What you add"), .p("Formula", "After X, I will Y"), .p("Timing", "Must match the new habit")],
        sequencePrompt: "Order a morning habit stack",
        sequence: ["Wake up", "Drink a glass of water", "Make coffee", "Meditate for one minute", "Write one line in a journal"],
        blanks: [.b("After I ___, I will do one push-up.", ["make my coffee", "someday", "feel motivated"], 0)],
        practice: [.free("Write your own habit stack: 'After [current habit], I will [new habit].'", rubric: ["Uses the After…I will… formula", "Anchor is something they already do daily", "New habit is small and specific"],
                         sample: "After I pour my morning coffee, I will write down one thing I'm grateful for.", title: "Your stack")],
        takeaways: ["After [current habit], I will [new habit].", "Choose an anchor that matches timing and frequency."]
    )

    static let cafeteria = KnowledgeSeed(
        intro: "Story: how a hospital cafeteria got people to drink more water — without saying a word.",
        cards: [
            storyCard("The experiment", "Doctor Anne Thorndike's team changed only where drinks were placed in a hospital cafeteria. No signs, no lectures.", "cross.case.fill", .curious),
            storyCard("Water everywhere", "They added bottled water next to the food stations and in more fridges. Water became the obvious choice.", "drop.fill", .happy, highlight: "the obvious choice"),
            storyCard("The result", "Over the following months, water sales rose and soda sales dropped. People followed the cues around them.", "chart.line.uptrend.xyaxis", .excited),
            storyCard("Your environment", "Want to practise guitar? Put it on a stand in the living room, not in its case in the closet.", "guitars.fill", .proud, highlight: "not in its case"),
        ],
        questions: [
            .q("What changed in the cafeteria?", ["Prices", "Where the drinks were placed", "The menu"], 1),
            .q("What's the lesson for your habits?", ["Rely on willpower", "Make cues for good habits visible", "Hide your goals"], 1),
        ],
        statements: [.s("Environment often shapes behaviour more than motivation.", true), .s("People in the study were told to drink more water.", false, "Nothing was said — only placement changed.")],
        sequencePrompt: "Order an environment makeover for reading more",
        sequence: ["Pick the habit: reading", "Choose a spot: the armchair", "Put a book on the armchair", "Move the TV remote to a drawer"],
        blanks: [.b("Make the cues of good habits ___.", ["obvious", "hidden", "expensive"], 0)],
        scenario: .scenario("You want to eat more fruit. What's the best move?", ["Promise yourself to try harder", "Put a fruit bowl on the counter where you'll see it", "Buy fruit and keep it in a drawer"], 1,
                            consequences: ["Willpower fades by Wednesday.", "The fruit becomes the obvious snack.", "Out of sight, out of mind."],
                            why: "Visible cues trigger habits."),
        practice: [.mission("Environment makeover", "Redesign one spot at home to make a good habit obvious.",
                            steps: ["Pick one habit you want more of", "Put its cue where you'll see it (book on pillow, guitar on a stand…)",
                                    "Move one temptation out of sight", "Take a photo of the new setup"],
                            proof: "A photo of your redesigned spot")],
        takeaways: ["Environment beats motivation.", "Make good cues visible, bad cues invisible."]
    )

    static let bundling = KnowledgeSeed(
        intro: "Make the habits you need to do irresistible by pairing them with things you love.",
        cards: [
            storyCard("Temptation bundling", "Link an action you want to do with an action you need to do: only watch your favourite show while on the exercise bike.", "gift.fill", .excited, highlight: "want to do"),
            storyCard("The bike hack", "An engineering student wired his exercise bike to his laptop so his show only played while he pedalled fast enough.", "bicycle", .laughing),
            storyCard("Join the right tribe", "We copy the people around us. Join a group where your desired habit is the normal thing to do.", "person.3.fill", .happy, highlight: "desired habit is the normal thing"),
        ],
        questions: [
            .q("Which is temptation bundling?", ["Only listen to your favourite podcast while doing chores", "Reward yourself with cake after the gym", "Do chores faster"], 0),
            .q("Why join a group where your habit is normal?", ["It's cheaper", "We tend to copy the people around us", "Groups do it for you"], 1),
        ],
        statements: [.s("Pairing a 'need to' with a 'want to' makes the habit more attractive.", true), .s("Culture has little effect on our habits.", false)],
        pairs: [.p("Need to", "Exercise"), .p("Want to", "Favourite show"), .p("Bundle", "Show only while exercising"), .p("Tribe", "People who make the habit normal")],
        blanks: [.b("Pair something you need to do with something you ___ to do.", ["want", "have", "forgot"], 0)],
        practice: [.free("Design your own temptation bundle.", rubric: ["Names something they need to do", "Names something they want to do", "Links them with a clear rule"],
                         sample: "I'll only listen to my favourite true-crime podcast while I'm doing the dishes or folding laundry.", title: "Your bundle")],
        takeaways: ["Bundle a need-to with a want-to.", "Join a group where your habit is normal."]
    )

    static let habitCall = KnowledgeSeed(
        intro: "Let's design a habit together, out loud.",
        cards: [
            storyCard("Bring one habit", "Pick one habit you really want. ilo will help you make it obvious and attractive.", "lightbulb.fill", .curious),
            storyCard("The questions", "When exactly? Where? After which existing habit? What will make it enjoyable?", "questionmark.bubble.fill", .attentive),
        ],
        questions: [.q("What makes a habit plan specific?", ["A time, a place and an anchor habit", "A big goal", "A motivational quote"], 0)],
        statements: [.s("Talking a plan through helps find weak spots.", true), .s("A good plan includes when and where.", true)],
        pairs: [.p("When", "A time"), .p("Where", "A place"), .p("Anchor", "An existing habit"), .p("Attractive", "A bundle you enjoy")],
        practice: [.call("ilo, your habits coach", goal: "Design one habit stack with a time, place and a temptation bundle",
                         opening: "Hey! Let's build one habit together. What's the habit you want most right now?", turns: 5)],
        takeaways: ["Time + place + anchor + something enjoyable."]
    )

    // MARK: - Unit 3

    static let twoMinutes = KnowledgeSeed(
        intro: "The secret to starting any habit: make it ridiculously small.",
        cards: [
            storyCard("The two-minute rule", "When you start a new habit, it should take less than two minutes. 'Read before bed' becomes 'read one page'.", "timer", .excited, highlight: "less than two minutes"),
            storyCard("Master showing up", "You have to build a habit before you can improve it. The two-minute version builds the identity of someone who shows up.", "figure.walk.arrival", .attentive, highlight: "build a habit before you can improve it"),
            storyCard("Gateway habits", "Putting on running shoes is the gateway to a run. Opening your notebook is the gateway to writing.", "door.left.hand.open", .happy),
        ],
        questions: [
            .q("What's the two-minute version of 'run 5 km'?", ["Run 2 km", "Put on your running shoes", "Think about running"], 1),
            .q("Why start so small?", ["Small habits are all you need forever", "You have to build a habit before you can improve it", "It burns calories"], 1),
        ],
        statements: [.s("A new habit should start with a version that takes under two minutes.", true), .s("Optimising before the habit exists is the best strategy.", false, "Standardise before you optimise.")],
        pairs: [.p("Read 30 pages", "Read one page"), .p("Do yoga", "Roll out the mat"), .p("Study for class", "Open your notes"), .p("Run 5 km", "Put on running shoes")],
        blanks: [.b("You have to ___ a habit before you can improve it.", ["build", "perfect", "optimise"], 0)],
        practice: [
            .estimate("How many minutes should the starting version of a new habit take, according to the two-minute rule?", min: 0, max: 30, answer: 2, unit: "min",
                      why: "Under two minutes — small enough that you can't say no."),
            .free("Shrink one of your habits to a two-minute version.", rubric: ["Names a habit", "Gives a version under two minutes", "Version is a real first step"],
                  sample: "My habit: practise piano for 30 minutes. Two-minute version: sit down and play one scale."),
        ],
        takeaways: ["Start with a two-minute version.", "Standardise before you optimise."]
    )

    static let friction = KnowledgeSeed(
        intro: "We follow the path of least resistance. So design the path.",
        cards: [
            storyCard("Law of least effort", "Between two similar options, we naturally choose the one that takes less work.", "arrow.down.right.circle.fill", .sleepy),
            storyCard("Remove steps for good habits", "Lay out your gym clothes the night before. Pre-cut vegetables. Keep the guitar tuned and out.", "checkmark.circle.fill", .happy, highlight: "Lay out your gym clothes"),
            storyCard("Add steps for bad habits", "Log out of social apps after every use. Unplug the TV. Leave your phone in another room.", "xmark.octagon.fill", .suspicious, highlight: "Unplug the TV"),
            storyCard("Commitment devices", "A choice now that locks in good behaviour later: an outlet timer that cuts the router at 10 pm, a pre-paid class.", "lock.fill", .proud, highlight: "locks in good behaviour later"),
        ],
        questions: [
            .q("How do you make a bad habit harder?", ["Add steps before it", "Remove steps before it", "Reward it"], 0),
            .q("Which is a commitment device?", ["Deciding to 'try harder'", "Setting a timer that turns off your Wi-Fi at 10 pm", "Buying a notebook"], 1),
        ],
        statements: [.s("People tend to choose the option that takes less effort.", true), .s("Logging out of apps makes scrolling easier.", false, "It adds friction."),
                     .s("Preparing the night before reduces friction for good habits.", true)],
        pairs: [.p("Reduce friction", "Good habits"), .p("Increase friction", "Bad habits"), .p("Commitment device", "Locks in future behaviour"), .p("Prime the space", "Prepare in advance")],
        blanks: [.b("To make a good habit easy, ___ the number of steps.", ["reduce", "increase", "hide"], 0)],
        practice: [.spot("Spot the friction mistakes in Tom's plan to sleep earlier", ["Phone charges on the nightstand", "Lights dim at 10 pm", "TV stays on in the bedroom",
                                                                                      "Book waits on the pillow", "Coffee at 8 pm to 'stay focused'"],
                         wrong: [0, 2, 4], why: "A phone by the bed, the TV on and late coffee all make the bad habit easy and the good one hard.")],
        takeaways: ["Remove friction for good habits.", "Add friction for bad ones.", "Use commitment devices."]
    )

    static let neverMissTwice = KnowledgeSeed(
        intro: "Story: the stockbroker, the paper clips, and the rule that saves streaks.",
        cards: [
            storyCard("Two jars of clips", "A young stockbroker put 120 paper clips in one jar. After each sales call, he moved one clip to the other jar until all had moved.", "paperclip", .curious, highlight: "moved one clip"),
            storyCard("Visible progress", "Seeing progress is satisfying — and what's satisfying gets repeated. That's why habit trackers work.", "checklist", .happy, highlight: "what's satisfying gets repeated"),
            storyCard("Then life happens", "Everyone misses a day. Sick, travelling, busy. The problem isn't the miss.", "cloud.rain.fill", .sad),
            storyCard("Never miss twice", "One miss is just a slip. Two in a row is how a new (bad) pattern begins. So get back on track the very next day.", "arrow.uturn.forward.circle.fill", .proud, highlight: "One miss is just a slip"),
        ],
        questions: [
            .q("Why did moving paper clips help?", ["It made progress visible and satisfying", "Clips are lucky", "It saved time"], 0),
            .q("You missed your workout yesterday. What's the rule?", ["Wait until Monday", "Never miss twice — do it today, even a small version", "Double tomorrow"], 1),
        ],
        statements: [.s("Behaviour that feels good right away tends to be repeated.", true), .s("One missed day ruins a habit.", false, "Missing twice is the danger."),
                     .s("Habit trackers make progress visible.", true)],
        sequencePrompt: "Order the comeback",
        sequence: ["Miss a day", "Don't judge yourself", "Do a tiny version the next day", "Mark it on your tracker"],
        blanks: [.b("The rule: never miss ___ in a row.", ["twice", "once", "a week"], 0)],
        scenario: .scenario("You've tracked 20 days of reading, then miss two days on holiday. Now what?", ["Start a brand-new tracker next month", "Read one page today and keep the tracker going", "Give up on reading"], 1,
                            consequences: ["A month of lost momentum.", "The habit — and your identity as a reader — survives.", "Twenty days of votes thrown away."],
                            why: "Bounce back fast: the next day matters most."),
        practice: [.free("What will you do the next time you miss a day of a habit?", rubric: ["Commits to acting the next day", "Uses a small version of the habit"],
                         sample: "I'll do the two-minute version the very next day so I never miss twice.")],
        takeaways: ["Make progress visible — track it.", "Never miss twice."]
    )

    static let habitPlan = KnowledgeSeed(
        intro: "Final mission: design one habit with all four laws — and live it for three days.",
        cards: [
            storyCard("The four laws, together", "Obvious (cue + time + place), attractive (bundle), easy (two-minute version), satisfying (track it).", "4.circle.fill", .excited),
            storyCard("Three days", "Three days in a row proves the system works. Then keep going — never miss twice.", "calendar", .attentive),
        ],
        questions: [.q("Which part makes the habit satisfying?", ["The time and place", "Tracking it and rewarding yourself", "The two-minute version"], 1)],
        statements: [.s("A complete habit plan uses all four laws.", true)],
        sequencePrompt: "Order your habit plan",
        sequence: ["Pick one habit and identity", "Set time, place and anchor", "Add a bundle", "Shrink it to two minutes", "Track it"],
        practice: [.mission("Your habit plan", "Design one habit using all four laws and do it three days in a row.",
                            steps: ["Write: 'I am the kind of person who…'", "Write: 'After [anchor], I will [habit] at [time] in [place]'",
                                    "Add a temptation bundle", "Shrink it to a two-minute version", "Draw a 3-day tracker and tick each day", "Take a photo of your tracker"],
                            proof: "A photo of your habit tracker")],
        takeaways: ["Obvious, attractive, easy, satisfying.", "Track it and never miss twice."]
    )
}

private extension LessonModule {
    /// A fill-in-the-gap used in "1% better".
    static var fill1: LessonModule {
        .blank("Habits work like compound ___ for self-improvement.", ["interest", "problems", "effort", "luck"], 0,
               why: "Small, repeated improvements multiply over time — like interest.")
    }
}
