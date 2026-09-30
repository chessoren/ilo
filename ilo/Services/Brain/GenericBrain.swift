import Foundation

/// Offline course + lesson templates for any goal. The content is real learning science
/// (deliberate practice, retrieval, spacing, feedback, plateaus, teaching to learn) applied to the learner's topic,
/// plus category-specific hands-on modules (metronome, code lab, phrasebook, camera coach…).
enum GenericBrain {
    // MARK: - Plan

    static func course(for request: CourseRequest, topic: Topic) -> Course {
        let t = topic
        let beginner = request.level.rawValue <= LearnerLevel.beginner.rawValue
        let title = t.short.count <= 22 ? "\(t.shortTitle), \(beginner ? "from zero" : "next level")" : (beginner ? "Your first steps" : "Your next level")
        let why = request.motivation?.nilIfBlank

        func node(_ title: String, _ kind: NodeKind, _ brief: String, _ symbol: String? = nil) -> PathNode {
            PathNode(title: title, brief: brief, kind: kind, symbol: symbol ?? kind.defaultSymbol)
        }

        let practiceSymbol: String = switch t.category {
        case .movement: "figure.run"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .language: "character.bubble.fill"
        case .creative: "metronome.fill"
        default: "timer"
        }

        let units = [
            CourseUnit(title: "Start strong", outcome: "Know exactly what you're aiming for and take your first real step", tint: .periwinkle, nodes: [
                node("Your why", .story, "Why \(t.noun) is worth it\(why.map { " — \($0)" } ?? ""). A short story about a beginner who kept going because the goal was personal, and how a clear why beats willpower.", "heart.fill"),
                node("Picture the pro", .lesson, "What great \(t.short) looks like, and how to break it into 3–5 sub-skills you can practise separately.", "eye.fill"),
                node("The first tiny win", .practice, "A two-minute starter session for \(t.noun): make it so small you can't fail, then do it right now.", practiceSymbol),
                node("Treasure chest", .chest, "A reward for starting.", "gift.fill"),
                node("Set up your space", .mission, "Prepare one place and the tools for \(t.noun) so starting takes zero effort. Proof: a photo of the spot.", "house.fill"),
                node("Start-strong boss", .boss, "Mixed challenge on why, sub-skills and tiny wins for \(t.noun).", "crown.fill"),
            ]),
            CourseUnit(title: "Practise like a pro", outcome: "Run a practice loop that actually makes you better at \(t.short)", tint: .mint, nodes: [
                node("Deliberate practice", .lesson, "The difference between repetition and deliberate practice: one sub-skill, just beyond your comfort zone, full focus, instant feedback.", "scope"),
                node("Feedback loops", .story, "How to get fast, honest feedback on \(t.noun): recordings, checklists, comparing to an expert example, asking a coach.", "arrow.triangle.2.circlepath"),
                node("Remember it for good", .lesson, "Retrieval practice and spacing: test yourself instead of rereading, review at growing intervals, mix topics.", "brain.head.profile"),
                node("Practice sprint", .practice, "A focused hands-on session for \(t.noun) using everything so far.", practiceSymbol),
                node("Treasure chest", .chest, "A reward for building the loop.", "gift.fill"),
                node("Coach call", .call, "Talk through your practice plan for \(t.noun) out loud with ilo and get one tweak.", "phone.fill"),
                node("Loop boss", .boss, "Mixed challenge on deliberate practice, feedback and memory.", "crown.fill"),
            ]),
            CourseUnit(title: "Level up for real", outcome: "Push through plateaus and use \(t.short) in the real world", tint: .orchid, nodes: [
                node("Beat the plateau", .story, "Why progress in \(t.noun) stalls (the 'OK plateau') and three ways out: raise the difficulty, change the context, get new feedback.", "chart.line.uptrend.xyaxis"),
                node("Teach it to own it", .lesson, "The Feynman technique: explain \(t.short) simply, spot the gaps, go back to the source, simplify again.", "graduationcap.fill"),
                node("Quick review", .review, "Spaced review of the whole path so far.", "arrow.triangle.2.circlepath"),
                node("Real-world mission", .mission, "Use \(t.short) in real life once this week — for someone, in public, or on a real project. Proof: a photo.", "flag.checkered"),
                node("Treasure chest", .chest, "A reward for going public.", "gift.fill"),
                node("Milestone boss", .boss, "The final mixed challenge of the path.", "crown.fill"),
            ]),
        ]

        let query = t.phrase.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? t.short
        let sources = [
            CourseSource(title: "Wikipedia — \(t.shortTitle)", url: "https://en.wikipedia.org/wiki/Special:Search?search=\(query)"),
            CourseSource(title: "Deliberate practice", url: "https://en.wikipedia.org/wiki/Deliberate_practice"),
            CourseSource(title: "Testing effect (retrieval practice)", url: "https://en.wikipedia.org/wiki/Testing_effect"),
            CourseSource(title: "Spacing effect", url: "https://en.wikipedia.org/wiki/Spacing_effect"),
        ]

        return Course(goal: request.goal, title: title, tagline: "Small daily steps toward \(t.noun).",
                      symbol: Sanitize.symbol(t.symbol, fallback: "sparkles"), tint: .periwinkle, category: t.category,
                      level: request.level, motivation: request.motivation, deadline: request.deadline,
                      dailyMinutes: request.dailyMinutes, units: units, sources: sources)
    }

    // MARK: - Lessons

    /// Lesson for any node: template if we wrote the node, brief-driven otherwise.
    static func lesson(course: Course, node: PathNode) -> Lesson {
        let topic = Topic(course.goal)
        let nodes = course.allNodes
        let index = nodes.firstIndex { $0.id == node.id } ?? 0
        let earlier = nodes[..<index].filter { $0.kind != .chest && $0.kind != .boss && $0.kind != .review }
            .map { seed(for: $0, course: course, topic: topic) }
        let seed = seed(for: node, course: course, topic: topic)
        return Composer.compose(title: node.title, kind: node.kind, seed: seed, earlier: earlier, nodeID: node.id)
    }

    static func seed(for node: PathNode, course: Course, topic t: Topic) -> KnowledgeSeed {
        switch node.title {
        case "Your why": return why(t, motivation: course.motivation)
        case "Picture the pro": return picturePro(t)
        case "The first tiny win": return tinyWin(t)
        case "Set up your space": return setup(t)
        case "Deliberate practice": return deliberate(t)
        case "Feedback loops": return feedback(t)
        case "Remember it for good": return memory(t)
        case "Practice sprint": return sprint(t)
        case "Coach call": return coachCall(t)
        case "Beat the plateau": return plateau(t)
        case "Teach it to own it": return feynman(t)
        case "Real-world mission": return realWorld(t)
        default: return fromBrief(node, topic: t)
        }
    }

    // MARK: Unit 1

    static func why(_ t: Topic, motivation: String?) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Before any technique: let's lock in why \(t.noun) matters to you.")
        s.cards = [
            storyCard("Meet Sam", "Sam wanted to get into \(t.noun) for years. Every January: big plans. Every February: nothing. Sound familiar?", "person.fill", .curious),
            storyCard("What changed", motivation.map { "This time Sam had a reason that felt personal — like yours: “\($0)”. A real reason turns 'should' into 'want'." }
                      ?? "This time Sam wrote one sentence: who it was for and by when. A personal reason turns 'should' into 'want'.", "heart.fill", .happy, highlight: "personal"),
            storyCard("Tiny beats heroic", "Sam stopped planning 2-hour sessions and committed to 10 focused minutes a day. Easy days still counted.", "timer", .proud, highlight: "10 focused minutes"),
            storyCard("Three months later", "Sam wasn't a genius. Sam just never stopped — and small daily reps compound into real skill.", "chart.line.uptrend.xyaxis", .excited),
        ]
        s.scenario = .scenario("It's 9 pm, you're tired, and you planned a 30-minute \(t.short) session. What's the smartest move?",
                               ["Skip it — tomorrow you'll do double", "Do a 5-minute version so the chain doesn't break", "Force the full 30 minutes, tired or not"], 1,
                               consequences: ["Tomorrow's 'double' session rarely happens — skipping becomes the habit.",
                                              "You keep your identity as someone who practises, and 5 minutes still moves you forward.",
                                              "You might finish, but you'll start dreading practice. Burnout kills more goals than laziness."],
                               why: "Consistency beats intensity. A tiny session keeps the habit alive on hard days.")
        s.questions = [
            .q("Why does a personal reason help you stick with \(t.noun)?", ["It makes practice feel like a 'want', not a 'should'", "It makes the skill easier", "It replaces the need to practise"], 0,
               "Motivation that's tied to people and moments you care about survives bad days."),
            .q("Which goal is most likely to last?", ["“Get good someday”", "“10 minutes a day, for the next 30 days”", "“Practise 4 hours every Sunday”"], 1,
               "Specific, small and frequent beats vague or heroic."),
        ]
        s.sequencePrompt = "Order Sam's comeback"
        s.sequence = ["Wrote down a personal reason", "Shrunk sessions to 10 minutes", "Practised on easy and hard days", "Noticed real progress"]
        s.blanks = [.b("Consistency beats ___.", ["intensity", "talent", "luck"], 0, "Showing up often matters more than occasional big efforts.")]
        s.statements = [
            .s("Motivation has to come first; then you start.", false, "Often it's the reverse: starting creates motivation."),
            .s("Short daily practice usually beats rare long sessions.", true, "Frequent practice gives your brain more chances to consolidate."),
            .s("A personal reason makes you more likely to keep going.", true, "It gives meaning to the boring reps."),
            .s("If you miss one day, the streak — and the goal — is over.", false, "Missing once is normal. Just don't miss twice."),
        ]
        s.practice = [.free("In one or two sentences: why do you want to get into \(t.noun), and who is it for?",
                            rubric: ["Names a personal reason", "Mentions a person, moment or deadline", "Specific rather than vague"],
                            sample: motivation.map { "I want this because \($0). I'll practise 10 minutes a day so I'm ready in time." }
                                ?? "I want this for myself and my family — I'll practise 10 minutes a day for the next month.", title: "Your why")]
        s.takeaways = ["A personal reason turns 'should' into 'want'.", "Tiny daily sessions beat heroic weekly ones.", "Missed a day? Never miss twice."]
        return s
    }

    static func picturePro(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Let's see what 'good' actually looks like — then break it into bite-size pieces.")
        s.cards = [
            storyCard("Skills are bundles", "\(t.nounTitle) isn't one skill. It's a bundle of smaller sub-skills — and each one can be practised on its own.", "square.stack.3d.up.fill", .curious, highlight: "bundle of smaller sub-skills"),
            storyCard("Watch a pro", "Find one great example of \(t.short) and watch or study it three times: once for fun, once for the big picture, once for the details.", "eye.fill", .attentive),
            storyCard("Name the parts", "Write down 3–5 things the pro does well. Those are your sub-skills — your map for the next weeks.", "list.bullet.rectangle.fill", .happy),
            storyCard("Start with the bottleneck", "Pick the sub-skill that holds everything else back and start there. Fix the weakest link first.", "link", .proud, highlight: "weakest link"),
        ]
        s.questions = [
            .q("What's the smartest way to start learning \(t.short)?", ["Try to do everything at once", "Break it into sub-skills and practise the key one", "Wait until you feel ready"], 1,
               "Deconstructing a skill lets you practise the piece that matters most."),
            .q("You watch a great example of \(t.short). What should you look for on the third viewing?", ["The overall vibe", "Specific details you can copy", "Nothing — once is enough"], 1,
               "Big picture first, then details you can turn into practice."),
        ]
        s.pairs = [.p("Sub-skill", "A small piece of the whole skill"), .p("Model", "A great example to learn from"),
                   .p("Bottleneck", "The weakest part that holds you back"), .p("Deconstruct", "Break a skill into parts")]
        s.blanks = [.b("Fix the ___ link first.", ["weakest", "strongest", "newest"], 0, "Improving the bottleneck lifts everything else.")]
        s.statements = [.s("Every skill can be broken into smaller sub-skills.", true), .s("You should only study experts after you're good.", false, "Models help most at the start."),
                        .s("Practising the hardest bottleneck first speeds up progress.", true)]
        s.practice = [.sort("Sort these: sub-skill of \(t.short), or distraction?", buckets: ["Worth practising", "Distraction"],
                            [("One core technique, done slowly", 0), ("Buying more gear before starting", 1), ("Copying a detail from a great example", 0),
                             ("Watching 3 hours of tips without trying", 1), ("Timing yourself on one small piece", 0), ("Waiting for the perfect moment", 1)])]
        s.flashcards = [.f("Sub-skill", "A small, separately practisable piece of a skill"), .f("Model", "A great example you study closely"),
                        .f("Bottleneck", "The weakest part — fix it first")]
        s.takeaways = ["Every skill is a bundle of sub-skills.", "Study one great example closely.", "Fix the weakest link first."]
        return s
    }

    static func tinyWin(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Two minutes. That's all. Let's get your first real rep of \(t.short) done today.")
        s.cards = [
            storyCard("The two-minute start", "Starting is the hardest part. So make the first step so small it takes two minutes — and do it now.", "timer", .excited, highlight: "two minutes"),
            storyCard("Slow is smooth", "Do it slowly and correctly. Speed comes later; bad habits are hard to unlearn.", "tortoise.fill", .attentive, highlight: "slowly and correctly"),
            storyCard("Count the win", "When you finish, say 'done' out loud. Your brain loves closing loops.", "checkmark.circle.fill", .happy),
        ]
        s.questions = [.q("What makes a great first practice session?", ["Long and exhausting", "Small, slow and correct", "Fast, to see how good you are"], 1,
                          "Small and correct builds the habit and the right technique.")]
        s.blanks = [.b("Slow is smooth, smooth is ___.", ["fast", "boring", "wrong"], 0, "Accuracy first; speed follows.")]
        s.pairs = [.p("Two-minute start", "Makes starting effortless"), .p("Slow reps", "Build correct technique"), .p("Say 'done'", "Closes the loop"),
                   .p("Tiny sessions", "Build the habit")]
        s.practice = categoryPractice(t, stage: 0)
        s.statements = [.s("Your first session should be as long as possible.", false, "Small sessions build the habit."),
                        .s("Practising slowly builds more accurate technique.", true), .s("Two minutes of practice is better than zero.", true)]
        s.takeaways = ["Make the first step take two minutes.", "Slow and correct before fast.", "Celebrate finishing."]
        return s
    }

    static func setup(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Your environment is your secret coach. Let's set it up so starting is effortless.")
        s.cards = [
            storyCard("Friction matters", "Every extra step between you and practice — finding gear, clearing space, logging in — is a reason to skip.", "hand.raised.fill", .suspicious),
            storyCard("Make it obvious", "Leave what you need for \(t.noun) out where you'll see it. Visible cues trigger action.", "eye.fill", .happy, highlight: "Visible cues"),
            storyCard("One spot, one purpose", "A dedicated corner — even a chair — tells your brain: this is where I practise.", "chair.fill", .proud),
        ]
        s.sequencePrompt = "Order your setup"
        s.sequence = ["Pick one spot", "Put your tools within reach", "Remove one distraction", "Take a photo of your spot"]
        s.questions = [.q("Which change makes practising \(t.short) most likely tomorrow?", ["Hide your gear in a cupboard", "Leave everything ready in one visible spot", "Decide to 'try harder'"], 1,
                          "Reducing friction beats relying on willpower.")]
        s.practice = [.mission("Set up your space", "Create a ready-to-go spot for \(t.noun).",
                               steps: ["Pick one spot at home where you'll practise", "Put everything you need for \(t.short) within arm's reach",
                                       "Remove one distraction (phone in another room counts!)", "Take a photo of your ready spot"],
                               proof: "A photo of your practice spot")]
        s.statements = [.s("Willpower is more reliable than a good environment.", false, "Environment works even on low-willpower days."),
                        .s("Visible cues make you more likely to start.", true), .s("Reducing friction makes a habit easier to keep.", true)]
        s.takeaways = ["Reduce friction: make practice one step away.", "Visible cues trigger action.", "One spot, one purpose."]
        return s
    }

    // MARK: Unit 2

    static func deliberate(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Ten hours of mindless reps < one hour of deliberate practice. Here's the difference.")
        s.cards = [
            storyCard("Not all practice is equal", "Psychologist Anders Ericsson found that experts don't just practise more — they practise differently.", "person.fill.questionmark", .curious),
            storyCard("One thing at a time", "Deliberate practice targets ONE sub-skill per session, with a clear goal like 'nail this transition 5 times in a row'.", "scope", .attentive, highlight: "ONE sub-skill"),
            storyCard("The stretch zone", "Aim just beyond what you can do comfortably. Too easy = no growth. Too hard = frustration.", "arrow.up.right", .excited, highlight: "just beyond"),
            storyCard("Full focus, fast feedback", "No autopilot. Notice every mistake, fix it, repeat. That's where the skill is built.", "bolt.fill", .proud),
        ]
        s.questions = [
            .q("Which session is deliberate practice for \(t.short)?", ["Repeating what you already do well", "One tricky sub-skill, just beyond your level, with feedback", "Practising while watching TV"], 1,
               "Specific goal + stretch + focus + feedback."),
            .q("A practice task feels effortless. What should you do?", ["Keep going, it feels great", "Make it slightly harder", "Stop practising"], 1,
               "Growth happens in the stretch zone."),
        ]
        s.pairs = [.p("Comfort zone", "Too easy — little growth"), .p("Stretch zone", "Just beyond your level"), .p("Panic zone", "Too hard — frustration"),
                   .p("Feedback", "Tells you what to fix")]
        s.blanks = [.b("Deliberate practice aims just ___ your current level.", ["beyond", "below", "far above"], 0)]
        s.statements = [.s("More hours always means more skill.", false, "Quality of practice matters as much as quantity."),
                        .s("Deliberate practice has a specific goal for each session.", true), .s("Autopilot reps build new skills fastest.", false),
                        .s("Mistakes are useful information in deliberate practice.", true)]
        s.practice = [.spot("Spot the mistakes in this practice plan for \(t.short)", [
            "Pick one sub-skill to improve today",
            "Practise for three hours straight without breaks",
            "Aim slightly beyond what feels comfortable",
            "Ignore mistakes so you keep momentum",
            "Check your result against a good example",
        ], wrong: [1, 3], why: "Long unfocused marathons and ignoring mistakes are the opposite of deliberate practice.")]
        s.takeaways = ["Practise one sub-skill at a time.", "Stay in the stretch zone.", "Focus + feedback = growth."]
        return s
    }

    static func feedback(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "You can't fix what you can't see. Let's build your feedback loop.")
        s.cards = [
            storyCard("Maya's mirror", "Maya practised \(t.short) for weeks and felt stuck. Then she recorded herself for the first time. Ouch — and wow.", "video.fill", .surprised),
            storyCard("The recording didn't lie", "In one minute of footage she spotted two habits she never felt while practising.", "exclamationmark.magnifyingglass", .confused),
            storyCard("Compare, don't guess", "She put her recording next to a great example and listed three differences. Those became her next three sessions.", "rectangle.split.2x1.fill", .attentive, highlight: "three differences"),
            storyCard("Loop closed", "Record → compare → fix one thing → repeat. Two weeks later, the difference was obvious.", "arrow.triangle.2.circlepath", .proud),
        ]
        s.scenario = .scenario("You've practised \(t.short) all week but can't tell if you're improving. What do you do first?",
                               ["Practise more hours", "Record yourself and compare to a great example", "Switch to a totally different skill"], 1,
                               consequences: ["More of the same gives more of the same.", "Now you can see exactly what to fix next.", "You'd lose all your momentum."],
                               why: "Objective feedback turns vague effort into targeted practice.")
        s.sequencePrompt = "Order the feedback loop"
        s.sequence = ["Record or test yourself", "Compare with a great example", "Pick ONE thing to fix", "Practise that fix", "Record again"]
        s.questions = [.q("What's the most useful feedback for \(t.short)?", ["“Good job!”", "A specific difference between you and an expert example", "Your own feeling"], 1,
                          "Specific and objective beats vague and kind.")]
        s.blanks = [.b("Record → compare → fix ___ thing → repeat.", ["one", "every", "no"], 0, "One fix at a time keeps practice focused.")]
        s.statements = [.s("Feelings are a reliable measure of progress.", false, "Recordings and tests are far more honest."),
                        .s("Comparing to a great example shows you what to fix.", true), .s("Fixing one thing at a time is effective.", true)]
        s.practice = [.highlight("Tap the moments where Maya got real feedback", [
            "Maya practised alone for weeks.", "She recorded one minute of practice.", "She felt tired and went to bed.",
            "She compared the recording with an expert's.", "She scrolled social media.", "A friend pointed out one habit to change.",
        ], find: [1, 3, 5], why: "Recording, comparing and asking someone are all feedback. Practising blind is not.")]
        s.takeaways = ["Record yourself — it doesn't lie.", "Compare with a great example.", "Fix one thing at a time."]
        return s
    }

    static func memory(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Rereading feels productive. It mostly isn't. Here's what actually makes \(t.short) stick.")
        s.cards = [
            storyCard("The forgetting curve", "In the 1880s Hermann Ebbinghaus showed we forget most new material within days — unless we review it.", "chart.line.downtrend.xyaxis", .sad),
            storyCard("Test, don't reread", "Pulling an answer out of memory (retrieval practice) strengthens it far more than reading it again.", "brain.head.profile", .excited, highlight: "retrieval practice"),
            storyCard("Space it out", "Review after a day, then a few days, then a week. Each gap makes the memory stronger.", "calendar", .attentive, highlight: "a day, then a few days, then a week"),
            storyCard("Mix it up", "Shuffle different sub-skills in one session (interleaving). It feels harder — and works better.", "shuffle", .proud),
        ]
        s.questions = [
            .q("Which study habit makes \(t.short) stick best?", ["Rereading notes", "Quizzing yourself from memory", "Highlighting everything"], 1, "Retrieval practice beats rereading."),
            .q("When should you review something you just learned?", ["Never — once is enough", "Right before you need it, once", "After a day, then a few days, then a week"], 2, "Spacing reviews fights the forgetting curve."),
        ]
        s.pairs = [.p("Retrieval", "Recall from memory"), .p("Spacing", "Review with growing gaps"), .p("Interleaving", "Mix topics in one session"),
                   .p("Forgetting curve", "Memory fades without review")]
        s.blanks = [.b("Testing yourself is called ___ practice.", ["retrieval", "passive", "speed"], 0)]
        s.statements = [.s("Rereading is the best way to remember.", false, "It feels familiar but builds weak memories."),
                        .s("Spaced reviews beat cramming for long-term memory.", true), .s("Mixing topics in one session can improve learning.", true),
                        .s("Ebbinghaus studied how quickly we forget.", true)]
        s.practice = [.estimate("Without any review, roughly what share of a new list did Ebbinghaus forget within a day?",
                                min: 0, max: 100, answer: 65, unit: "%",
                                why: "His classic forgetting curve shows most of the material fading within a day — commonly quoted around 50–70%.")]
        s.flashcards = [.f("Retrieval practice", "Pull it from memory instead of rereading"), .f("Spacing", "Review after 1 day, 3 days, 1 week"),
                        .f("Interleaving", "Mix different sub-skills in one session")]
        s.takeaways = ["Test yourself instead of rereading.", "Review at growing intervals.", "Mix sub-skills in a session."]
        return s
    }

    static func sprint(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Sprint time: one focused block of \(t.short), using everything you've learned.")
        s.cards = [
            storyCard("Sprint rules", "One sub-skill. A timer. Phone away. When the timer ends, write one line: what improved?", "stopwatch.fill", .excited, highlight: "One sub-skill"),
            storyCard("Warm up, then stretch", "Start with something easy for a minute, then push into your stretch zone.", "flame.fill", .attentive),
        ]
        s.questions = [.q("During a practice sprint, your phone buzzes. Best move?", ["Check it quickly", "Ignore it — it's in another room anyway", "Reply, then restart"], 1,
                          "Focus is the whole point of a sprint.")]
        s.blanks = [.b("A sprint targets one ___ at a time.", ["sub-skill", "hour", "tool"], 0)]
        s.practice = categoryPractice(t, stage: 1)
        s.statements = [.s("Warming up before pushing hard helps.", true), .s("Multitasking makes practice more efficient.", false, "Switching attention costs focus.")]
        s.pairs = [.p("Timer", "Keeps the sprint short"), .p("Phone away", "Protects focus"), .p("Warm-up", "Easy start"), .p("One line", "Notes what improved")]
        s.takeaways = ["Short, focused sprints beat long distracted sessions.", "Warm up, then stretch.", "Write one line after each sprint."]
        return s
    }

    static func coachCall(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Let's talk it through. Saying your plan out loud makes it real.")
        s.cards = [
            storyCard("Why talk it out?", "Explaining your plan out loud exposes fuzzy parts you'd never notice in your head.", "waveform", .curious),
            storyCard("Bring three things", "Your why, the sub-skill you're working on, and when you'll practise this week.", "list.number", .attentive),
        ]
        s.questions = [.q("What should a good weekly plan for \(t.short) include?", ["Just 'practise more'", "Which sub-skill, when, and how you'll get feedback", "Only your end goal"], 1)]
        s.practice = [.call("ilo, your \(t.short) coach", goal: "Share your practice plan for this week and agree on one improvement",
                            opening: "Hey! Quick check-in on \(t.noun). Which part are you working on this week?", turns: 4)]
        s.statements = [.s("Saying a plan out loud can reveal gaps in it.", true), .s("A plan without a time slot is just a wish.", true)]
        s.pairs = [.p("Why", "Keeps you going"), .p("What", "One sub-skill"), .p("When", "A time slot"), .p("Feedback", "How you'll check")]
        s.takeaways = ["A plan needs what, when and how you'll get feedback.", "Talking it out reveals gaps."]
        return s
    }

    // MARK: Unit 3

    static func plateau(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Stuck? Good news: plateaus are normal — and escapable.")
        s.cards = [
            storyCard("The OK plateau", "Writer Joshua Foer described it: once something feels 'good enough', we stop improving — we go on autopilot.", "equal.circle.fill", .unimpressed, highlight: "autopilot"),
            storyCard("Leo hits the wall", "After two months of \(t.short), Leo stopped getting better. Same routine, same results, every day.", "figure.stand", .sad),
            storyCard("Break the pattern", "Leo made it harder (a new challenge), changed the context (new place, new partner), and got fresh feedback.", "hammer.fill", .excited),
            storyCard("Unstuck", "Within two weeks he felt the progress again. Plateaus aren't walls — they're signals to change the practice.", "arrow.up.forward.circle.fill", .proud),
        ]
        s.scenario = .scenario("You've been practising \(t.short) the same way for a month and progress has stopped. What now?",
                               ["Quit — you've hit your limit", "Change something: harder challenge, new context or new feedback", "Do exactly the same, but longer"], 1,
                               consequences: ["Plateaus are almost never real limits.", "You leave autopilot and start growing again.", "More autopilot keeps you on the plateau."],
                               why: "Plateaus are a signal to change how you practise, not a sign of your ceiling.")
        s.questions = [.q("What causes the 'OK plateau'?", ["Lack of talent", "Practising on autopilot once it feels good enough", "Too much feedback"], 1)]
        s.sequencePrompt = "Order Leo's escape"
        s.sequence = ["Notice progress stalled", "Make the challenge harder", "Change the context", "Get fresh feedback"]
        s.practice = [.free("Think of a time you stopped improving at something. What would you change about how you practised?",
                            rubric: ["Describes a real plateau", "Names a concrete change (harder, new context or feedback)"],
                            sample: "I stopped improving at running because I always ran the same route at the same pace. I'd add one faster interval run a week.")]
        s.statements = [.s("A plateau means you've reached your natural limit.", false), .s("Changing your practice can break a plateau.", true),
                        .s("Autopilot practice keeps you at the same level.", true)]
        s.takeaways = ["Plateaus come from autopilot, not lack of talent.", "Change difficulty, context or feedback to break through."]
        return s
    }

    static func feynman(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "The fastest way to master \(t.short)? Try to teach it.")
        s.cards = [
            storyCard("Feynman's trick", "Physicist Richard Feynman was famous for explaining hard ideas in plain words. The method is named after him.", "graduationcap.fill", .curious),
            storyCard("Step 1: explain it simply", "Pick one idea from \(t.noun) and explain it as if to a 10-year-old. No jargon allowed.", "text.bubble.fill", .attentive, highlight: "a 10-year-old"),
            storyCard("Step 2: find the gaps", "Where you stumble or wave your hands — that's exactly what you don't really understand yet.", "exclamationmark.magnifyingglass", .confused),
            storyCard("Step 3: fix and simplify", "Go back to the source, fill the gap, then explain it again, simpler.", "arrow.clockwise", .proud),
        ]
        s.sequencePrompt = "Order the Feynman technique"
        s.sequence = ["Pick one idea", "Explain it simply, like to a child", "Notice where you get stuck", "Go back to the source", "Explain it again, simpler"]
        s.questions = [.q("You can't explain part of \(t.short) simply. What does that tell you?", ["You're bad at explaining", "That's a gap in your understanding", "It can't be explained simply"], 1)]
        s.blanks = [.b("Where you stumble while explaining shows a ___ in your understanding.", ["gap", "strength", "shortcut"], 0)]
        s.practice = [.teach("Teach ilo the most useful thing you've learned so far about \(t.noun). Keep it simple enough for a 10-year-old.",
                             rubric: ["Explains one clear idea", "Uses plain words, no jargon", "Gives an example"],
                             sample: "The biggest thing I've learned is to practise one small piece at a time, slowly, and check it against a good example — like fixing one wobbly brick before building the next row.")]
        s.statements = [.s("Teaching something helps you learn it.", true), .s("Jargon proves you understand an idea.", false, "Plain words prove it better.")]
        s.pairs = [.p("Simplify", "Explain it like to a child"), .p("Gap", "Where you stumble"), .p("Source", "Where you go to fix a gap"), .p("Repeat", "Explain again, simpler")]
        s.takeaways = ["If you can't explain it simply, find the gap.", "Teaching is a powerful way to learn."]
        return s
    }

    static func realWorld(_ t: Topic) -> KnowledgeSeed {
        var s = KnowledgeSeed(intro: "Time to take \(t.short) out of the app and into your life.")
        s.cards = [
            storyCard("Real stakes, real growth", "Doing it for real — for a person, in public, on a real project — teaches things practice alone can't.", "globe", .excited),
            storyCard("Small and scary is perfect", "Pick something slightly nerve-racking but doable today. Nerves mean it matters.", "bolt.heart.fill", .shy),
        ]
        s.sequencePrompt = "Order your mission"
        s.sequence = ["Pick a small real-world use", "Tell someone you'll do it", "Do it", "Capture proof", "Note one lesson"]
        s.questions = [.q("Which is the best first real-world mission for \(t.short)?", ["Something huge in front of 500 people", "A small real use today, with someone watching", "Nothing until you're perfect"], 1)]
        s.practice = [.mission("Go real", "Use \(t.short) once in the real world this week.",
                               steps: ["Choose a small, real way to use \(t.short) (for a friend, in public, or on a real project)",
                                       "Tell one person you're doing it", "Do it — nerves are welcome", "Capture a photo as proof"],
                               proof: "A photo of you doing it (or what you made)")]
        s.statements = [.s("You should wait until you're perfect before using a skill for real.", false), .s("Real-world use reveals gaps practice can't.", true)]
        s.takeaways = ["Real stakes accelerate learning.", "Small and slightly scary is the sweet spot."]
        return s
    }

    // MARK: Category practice

    /// Hands-on modules that fit the topic's category. `stage` 0 = first tiny win, 1 = sprint.
    static func categoryPractice(_ t: Topic, stage: Int) -> [LessonModule] {
        switch t.category {
        case .movement:
            return [
                .timer("Move to the beat: do your basic \(t.short) movement slowly, one move per beat.", bpm: stage == 0 ? 80 : 100,
                       labels: ["1", "2", "3", "4"], seconds: stage == 0 ? 60 : 120, title: "Beat practice"),
                .camera("Basic \(t.short) movement", reps: stage == 0 ? 5 : 8, prompt: "Show ilo your basic \(t.short) movement.",
                        cues: ["Stand tall, shoulders relaxed", "Move slowly and with control", "Breathe out on the effort"]),
            ]
        case .creative:
            return [
                .timer("Metronome session: practise one small \(t.short) exercise, slowly, in time with the click.", bpm: stage == 0 ? 60 : 80,
                       labels: ["1", "2", "3", "4"], seconds: stage == 0 ? 90 : 180, title: "Slow practice"),
                .mission("Make one small thing", "Create something tiny with \(t.short) today.",
                         steps: ["Set a 10-minute timer", "Make one small piece — rough is fine", "Take a photo of the result"],
                         proof: "A photo of what you made"),
            ]
        case .code:
            return [codeLab(for: t, stage: stage)]
        case .language:
            return languageModules(t, stage: stage)
        case .wellbeing:
            return [
                .timer("Breathe with the beat: in for 4, out for 4. Just notice how you feel.", bpm: 60,
                       labels: ["in", "2", "3", "4", "out", "6", "7", "8"], seconds: stage == 0 ? 60 : 120, title: "Calm practice"),
                .mission("Tiny daily ritual", "Do a 2-minute version of \(t.noun) today.",
                         steps: ["Pick a moment right after something you already do daily", "Do 2 minutes of \(t.noun)", "Snap a photo of where you did it"],
                         proof: "A photo of your ritual spot"),
            ]
        case .knowledge, .book:
            return [
                .estimate("Josh Kaufman argues you can get reasonably good at a new skill with focused practice of about how many hours?",
                          min: 1, max: 100, answer: 20, unit: "hours",
                          why: "His book 'The First 20 Hours' argues ~20 focused hours takes you from clueless to reasonably good — not expert."),
                .teach("Explain one idea about \(t.noun) you know already, in three sentences.",
                       rubric: ["States one clear idea", "Uses a concrete example", "Plain language"],
                       sample: "One idea I already know is … For example, … That matters because …"),
            ]
        case .skill:
            return [
                .timer("Focus sprint: work on one small piece of \(t.short) until the timer ends.", bpm: 60, labels: ["1", "2", "3", "4"],
                       seconds: stage == 0 ? 120 : 300, title: "Focus sprint"),
                .mission("First rep", "Do one small real rep of \(t.noun) today.",
                         steps: ["Pick the smallest useful piece of \(t.short)", "Do it once, slowly", "Take a photo of the result or your setup"],
                         proof: "A photo of your first rep"),
            ]
        }
    }

    static func codeLab(for t: Topic, stage: Int) -> LessonModule {
        switch t.codeLanguage ?? "python" {
        case "javascript":
            return stage == 0
                ? .code("Make the program greet you: log a message with console.log.", language: "javascript",
                        starter: "// Say hello to the world\n", mustContain: ["console.log("], solution: "console.log(\"Hello, world!\");",
                        why: "console.log prints to the console — every JavaScript journey starts here.", title: "Hello, JavaScript")
                : .code("Store your name in a variable and log a greeting with it.", language: "javascript",
                        starter: "const name = \"\";\n// log a greeting that uses name\n", mustContain: ["const name", "console.log("],
                        solution: "const name = \"Sam\";\nconsole.log(\"Hi \" + name);", why: "Variables hold values you can reuse.", title: "Variables")
        case "swift":
            return stage == 0
                ? .code("Print your first line of Swift.", language: "swift", starter: "// Print a greeting\n", mustContain: ["print("],
                        solution: "print(\"Hello, world!\")", why: "print writes text to the console.", title: "Hello, Swift")
                : .code("Create a constant with your name and print a greeting that uses it.", language: "swift",
                        starter: "let name = \"\"\n// print a greeting\n", mustContain: ["let name", "print("],
                        solution: "let name = \"Sam\"\nprint(\"Hi \\(name)\")", why: "let declares a constant; \\( ) inserts values into text.", title: "Constants")
        case "html", "css":
            return .code("Add a heading that says hello.", language: "html", starter: "<body>\n  \n</body>", mustContain: ["<h1>", "</h1>"],
                         solution: "<body>\n  <h1>Hello!</h1>\n</body>", why: "<h1> is the main heading of a page.", title: "First heading")
        default:
            return stage == 0
                ? .code("Make Python say hello with print().", language: "python", starter: "# Say hello\n", mustContain: ["print("],
                        solution: "print(\"Hello, world!\")", why: "print() shows text on the screen.", title: "Hello, Python")
                : .code("Store your name in a variable, then print a greeting that uses it.", language: "python",
                        starter: "name = \"\"\n# print a greeting\n", mustContain: ["name =", "print("],
                        solution: "name = \"Sam\"\nprint(\"Hi \" + name)", why: "Variables let you reuse values.", title: "Variables")
        }
    }

    static func languageModules(_ t: Topic, stage: Int) -> [LessonModule] {
        guard let key = t.spokenLanguage, let book = Topic.phrasebooks[key] else {
            return [.roleplay("A friendly local who speaks only a little English", goal: "Greet them and ask one simple question",
                              opening: "Hi there! You're learning my language? Try saying hello!", turns: 4)]
        }
        let phrases = book.phrases
        if stage == 0 {
            return [
                .listen("Say it out loud", ["Listen, then repeat each phrase out loud."] + phrases.prefix(5).map { "\($0.0): \($0.1)" },
                        prompt: "Repeat after ilo"),
                .mcq("How do you say “\(phrases[1].0)” in \(book.name)?", [phrases[1].1, phrases[7].1, phrases[0].1], 0,
                     why: "“\(phrases[1].1)” means “\(phrases[1].0)”."),
            ]
        }
        let sentence = phrases[8].1.split(separator: " ").map(String.init)
        return [
            .bricks("Build “\(phrases[8].0)” in \(book.name)", sentence, distractors: ["no", "sí", "yes"].filter { !sentence.contains($0) }.prefix(2).map { $0 }),
            .roleplay("A friendly café owner who speaks \(book.name)", goal: "Order a coffee politely in \(book.name)",
                      opening: "\(phrases[0].1)! What can I get you?", turns: 4),
        ]
    }

    // MARK: Brief-driven fallback (nodes we didn't template)

    static func fromBrief(_ node: PathNode, topic t: Topic) -> KnowledgeSeed {
        let sentences = node.brief.split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.count > 8 }
        let title = node.title
        var s = KnowledgeSeed(intro: "Today: \(title). Let's learn it, then use it.")
        s.cards = [storyCard(title, sentences.first.map { $0 + "." } ?? "Today's focus is \(title.lowercased()) — one of the building blocks of \(t.noun).", "sparkles", .curious)]
        if sentences.count > 1 { s.cards.append(storyCard("Why it matters", sentences[1] + ".", "lightbulb.fill", .attentive)) }
        s.cards.append(storyCard("How to practise it", "Break \(title.lowercased()) into one small piece. Do it slowly for two minutes, then compare with a good example and fix one thing.", "scope", .happy, highlight: "one small piece"))
        s.cards.append(storyCard("Make it stick", "Tomorrow, before you look anything up, try to recall today's key idea from memory. That one habit doubles what you keep.", "brain.head.profile", .proud))
        s.questions = [
            .q("What's the best way to start with \(title.lowercased())?", ["Try to master everything at once", "Practise one small piece slowly, then check it", "Read about it for an hour first"], 1,
               "Small, correct reps with feedback beat big vague sessions."),
            .q("How should you review \(title.lowercased()) so it sticks?", ["Reread your notes", "Recall it from memory tomorrow, then again in a few days", "Never review"], 1,
               "Retrieval + spacing = long-term memory."),
        ]
        s.statements = [
            .s("Practising one piece at a time helps you learn \(title.lowercased()).", true),
            .s("Rereading is the most effective way to remember.", false, "Testing yourself works better."),
            .s("Comparing your attempt to a good example gives useful feedback.", true),
            .s("Mistakes mean you should stop.", false, "Mistakes show you exactly what to practise."),
        ]
        s.pairs = [.p(title, "Today's focus"), .p("Small piece", "Where to start"), .p("Good example", "Your feedback source"), .p("Tomorrow", "Recall it from memory")]
        s.blanks = [.b("Recall today's idea from ___ tomorrow.", ["memory", "your notes", "a video"], 0, "Retrieval beats rereading.")]
        s.sequencePrompt = "Order a great practice session"
        s.sequence = ["Pick one small piece", "Do it slowly", "Compare with a good example", "Fix one thing", "Try again"]
        switch node.kind {
        case .practice: s.practice = categoryPractice(t, stage: 1)
        case .mission:
            s.practice = [.mission(title, sentences.first.map { $0 + "." } ?? "Put \(title.lowercased()) into practice today.",
                                   steps: ["Pick a small real situation for \(title.lowercased())", "Do it once", "Take a photo as proof"],
                                   proof: "A photo of you doing it")]
        case .call:
            s.practice = [.call("ilo, your coach", goal: "Explain \(title.lowercased()) in your own words",
                                opening: "Hey! Tell me what you know about \(title.lowercased()) so far.", turns: 4)]
        default:
            s.practice = [.teach("Explain \(title.lowercased()) to ilo in your own words, with one example.",
                                 rubric: ["Explains the idea clearly", "Gives an example", "Uses plain words"],
                                 sample: sentences.prefix(2).joined(separator: ". ") + ".")]
        }
        s.takeaways = [sentences.first.map { $0 + "." } ?? "Practise \(title.lowercased()) one small piece at a time.",
                       "Recall it from memory tomorrow."]
        return s
    }
}
