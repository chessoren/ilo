import Foundation

/// Flagship: "Salsa for my grandma's wedding". Placeholders adapt it to the learner's goal:
/// {event} "the wedding", {Event}, {who} "grandma", {Who}, {occasion} "wedding".
enum CuratedSalsa {
    static let flagship = Flagship(
        id: "salsa",
        title: "Salsa, {occasion}-ready",
        tagline: "From two left feet to owning the dance floor at {event}.",
        symbol: "figure.dance",
        tint: .orange,
        category: .movement,
        strong: ["salsa"],
        keywords: ["dance", "dancing", "latin", "mambo", "bachata", "casino"],
        excludes: ["ballet", "hiphop", "breakdance", "breakdancing", "tap", "contemporary", "kpop", "tiktok", "tango", "waltz"],
        phrases: ["salsa", "latin dance"],
        units: [
            Flagship.Unit(title: "Find the beat", outcome: "Hear the 1 and dance the basic step on time", tint: .orange, nodes: [
                .init(title: "Meet salsa", brief: "What salsa is, where it comes from (Cuban son + New York), the 8-count, and why it's the perfect party dance for {event}.",
                      kind: .story, symbol: "music.note", content: meetSalsa),
                .init(title: "Count to eight", brief: "Salsa counts 1-2-3, pause, 5-6-7, pause. Steps on 1,2,3 and 5,6,7; pauses on 4 and 8. Count out loud with a slow beat.",
                      kind: .lesson, symbol: "metronome.fill", content: countToEight),
                .init(title: "The basic step", brief: "The forward-and-back basic: left forward on 1, rock on 2, back to centre on 3, pause; right back on 5, rock on 6, centre on 7, pause. Small steps, soft knees.",
                      kind: .practice, symbol: "shoeprints.fill", content: basicStep),
                .init(title: "Treasure chest", brief: "A reward for your first steps.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Kitchen dance floor", brief: "Mission: dance the basic step for 2 minutes in your kitchen to a real salsa song. Proof: a photo of your dance floor.",
                      kind: .mission, symbol: "flag.checkered", content: kitchenMission),
                .init(title: "Find the 1", brief: "How to hear the 1 in real salsa music: 8-count phrases, the strong downbeat, counting from the singer's phrases, and tempo.",
                      kind: .lesson, symbol: "ear.fill", content: findTheOne),
                .init(title: "Beat boss", brief: "Boss battle on counting, the basic step and finding the 1.", kind: .boss, symbol: "crown.fill", content: beatBoss),
            ]),
            Flagship.Unit(title: "Move with style", outcome: "Add a side step, a clean turn and relaxed styling", tint: .orchid, nodes: [
                .init(title: "Side to side", brief: "The side basic: step to the side on 1 and 5 instead of forward/back, same 1-2-3, 5-6-7 timing. Great for crowded floors.",
                      kind: .lesson, symbol: "arrow.left.and.right", content: .seed(sideBasic)),
                .init(title: "Your first turn", brief: "A solo right turn: prep on 1-2-3, turn on 5-6-7 on the balls of your feet, spot a point with your eyes, pause on 8.",
                      kind: .practice, symbol: "arrow.clockwise", content: .seed(firstTurn)),
                .init(title: "Tía Rosa's secret", brief: "Story: a dizzy beginner learns spotting and small steps from Tía Rosa, the family's best dancer.",
                      kind: .story, symbol: "book.fill", content: .seed(tiaRosa)),
                .init(title: "Treasure chest", brief: "A reward for your style.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Arms and shine", brief: "Styling: relaxed arms that follow the body, Cuban motion from the knees, and simple 'shines' (solo footwork).",
                      kind: .lesson, symbol: "sparkles", content: .seed(armsAndShine)),
                .init(title: "Count with ilo", brief: "Live call: count the basic out loud with ilo and explain when you pause.",
                      kind: .call, symbol: "phone.fill", content: .seed(countWithIlo)),
                .init(title: "Style boss", brief: "Boss battle on side basic, turns, spotting and styling.", kind: .boss, symbol: "crown.fill",
                      content: .review(intro: "Style boss! Turns, spotting, styling — show ilo what you've got.")),
            ]),
            Flagship.Unit(title: "Dance with a partner", outcome: "Lead or follow a simple pattern with a relaxed, clear connection", tint: .mint, nodes: [
                .init(title: "Hold, don't grab", brief: "Partner connection: closed and open hold, toned (not stiff) arms, leader palms up, follower's fingers resting in them, no thumb grip.",
                      kind: .lesson, symbol: "hand.raised.fill", content: .seed(holdDontGrab)),
                .init(title: "Cross-body lead", brief: "The signature pattern: the leader opens a lane on 1-2-3, the follower walks through on 5-6-7, and you swap places.",
                      kind: .practice, symbol: "arrow.triangle.swap", content: .seed(crossBody)),
                .init(title: "Asking {who} to dance", brief: "Story + roleplay: how to invite someone to dance, adapt to their level, and say thank you. Floor etiquette at {event}.",
                      kind: .story, symbol: "heart.fill", content: .seed(askingToDance)),
                .init(title: "Quick review", brief: "Spaced review of everything so far.", kind: .review, symbol: "arrow.triangle.2.circlepath",
                      content: .review(intro: "Quick review — let's make the first two units stick.")),
                .init(title: "Treasure chest", brief: "A reward for dancing together.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Partner mission", brief: "Mission: dance one full song with a partner (friend, family, flatmate) using the basic and one turn.",
                      kind: .mission, symbol: "person.2.fill", content: .seed(partnerMission)),
                .init(title: "Partner boss", brief: "Boss battle on connection, the cross-body lead and floor etiquette.", kind: .boss, symbol: "crown.fill",
                      content: .review(intro: "Partner boss! Connection, cross-body lead, etiquette. Let's dance.")),
            ]),
            Flagship.Unit(title: "{Occasion}-ready", outcome: "Put together a one-minute routine and own the dance floor", tint: .butter, nodes: [
                .init(title: "Build a routine", brief: "Chain moves in 8-count blocks: 2× basic, 2× side basic, a right turn, a cross-body lead. Always return to the basic when lost.",
                      kind: .lesson, symbol: "list.number", content: .seed(buildRoutine)),
                .init(title: "Dress rehearsal", brief: "Dance the full routine at real song tempo with the timer, then check your form with the camera coach.",
                      kind: .practice, symbol: "music.mic", content: .seed(dressRehearsal)),
                .init(title: "Nerves on the dance floor", brief: "Story: handling nerves, recovering from mistakes with a smile and the basic step, and enjoying the moment at {event}.",
                      kind: .story, symbol: "bolt.heart.fill", content: .seed(nerves)),
                .init(title: "Treasure chest", brief: "A reward for being {occasion}-ready.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Showtime", brief: "Mission: record your one-minute routine to a real salsa song and watch it back once.",
                      kind: .mission, symbol: "video.fill", content: .seed(showtime)),
                .init(title: "{Occasion} boss", brief: "The final boss: everything from counting to partner work.", kind: .boss, symbol: "crown.fill",
                      content: .review(intro: "Final boss! Everything you've learned — then you're {occasion}-ready.")),
            ]),
        ],
        sources: [
            CourseSource(title: "Salsa (dance) — Wikipedia", url: "https://en.wikipedia.org/wiki/Salsa_(dance)"),
            CourseSource(title: "Salsa music — Wikipedia", url: "https://en.wikipedia.org/wiki/Salsa_music"),
            CourseSource(title: "Clave (rhythm) — Wikipedia", url: "https://en.wikipedia.org/wiki/Clave_(rhythm)"),
            CourseSource(title: "Spotting (dance technique) — Wikipedia", url: "https://en.wikipedia.org/wiki/Spotting_(dance_technique)"),
        ],
        researchNotes: ["Picking a style that works at parties", "Comparing On1 and Cuban-style basics", "Collecting beginner timing mistakes"],
        placeholders: { goal in
            let g = goal.lowercased()
            let occasion = g.contains("wedding") ? "wedding" : (g.contains("party") || g.contains("birthday")) ? "party" : "dance-floor"
            let event = g.contains("wedding") ? "the wedding" : g.contains("birthday") ? "the birthday party" : g.contains("party") ? "the party" : "the dance floor"
            let who = ["grandma", "grandmother", "granny", "nana"].contains { g.contains($0) } ? "grandma"
                : ["grandpa", "grandfather"].contains { g.contains($0) } ? "grandpa"
                : ["wife", "husband", "partner", "girlfriend", "boyfriend", "fiancé", "fiance"].contains { g.contains($0) } ? "your partner"
                : "someone special"
            return ["occasion": occasion, "Occasion": occasion.prefix(1).uppercased() + occasion.dropFirst(),
                    "event": event, "Event": event.prefix(1).uppercased() + event.dropFirst(),
                    "who": who, "Who": who.prefix(1).uppercased() + who.dropFirst()]
        }
    )

    // MARK: - Unit 1 (hand-written)

    static var meetSalsa: Flagship.Content {
        .lesson(intro: "Salsa means 'sauce' — and by the end of this path, you'll bring the spice to {event}.", modules: [
            .story("Meet salsa", [
                storyCard("A spicy mix", "Salsa is Spanish for 'sauce'. The music is a mix too: Cuban son and mambo, remixed by Cuban and Puerto Rican musicians in 1960s–70s New York.", "flame.fill", .excited, highlight: "Spanish for 'sauce'"),
                storyCard("A dance for everyone", "It's danced at parties from Havana to Tokyo — and at weddings, it's the song that fills the floor. Grandparents included.", "globe.americas.fill", .happy),
                storyCard("It's all in eight", "Salsa is counted in eights: you step on 1-2-3, pause on 4, step on 5-6-7, pause on 8. That's it. That's the secret.", "8.circle.fill", .curious, highlight: "1-2-3, pause on 4"),
                storyCard("Your mission", "In a few short lessons you'll hear the beat, dance the basic step, turn, and dance with a partner at {event}.", "flag.checkered", .proud),
            ]),
            .mcq("What does the word 'salsa' mean in Spanish?", ["Party", "Sauce", "Step", "Rhythm"], 1,
                 why: "Salsa means 'sauce' — a spicy mix of musical styles."),
            .match("Match the salsa basics", [("Salsa", "Spanish for 'sauce'"), ("Cuban son", "One of salsa's musical roots"),
                                             ("New York", "Where the name 'salsa' took off"), ("8", "Counts in one salsa phrase")],
                   why: "Salsa grew out of Cuban music and was popularised under the name 'salsa' in New York."),
            .tf("True or false?", [
                ("Salsa has roots in Cuban music.", true, "Cuban son and mambo are its main ancestors."),
                ("Salsa dancers step on every single beat.", false, "You pause on 4 and 8 — that's what gives salsa its bounce."),
                ("You need a partner to start learning salsa.", false, "The basic step, turns and 'shines' can all be practised solo."),
            ]),
            .scenario("The DJ at {event} plays a salsa song and {who} waves you onto the floor. You've never danced salsa. What do you do?",
                      ["Hide by the cake table", "Join in, keep it simple: small steps on the beat and a big smile", "Try a triple spin you saw on YouTube"], 1,
                      consequences: ["You'll watch everyone else have the moment you came for.",
                                     "Simple + on time + smiling beats fancy every time. {Who} will love it.",
                                     "Bold! But without the basics, spins turn into stumbles."],
                      why: "Simple steps on time look great. That's exactly what this path will give you."),
            .flash("Recap", [("Salsa means…", "'Sauce' in Spanish"), ("Roots", "Cuban son + mambo, named in New York"),
                             ("The count", "1-2-3 (pause) 5-6-7 (pause)"), ("Pauses", "On 4 and 8")]),
        ], takeaways: ["Salsa means 'sauce': a mix of Cuban and New York sounds.", "You step 1-2-3, pause, 5-6-7, pause.", "Simple steps on time look great."])
    }

    static var countToEight: Flagship.Content {
        .lesson(intro: "Every salsa dancer's superpower: counting to eight. Let's get it into your body.", modules: [
            .story("The salsa count", [
                storyCard("Eight beats, six steps", "A salsa phrase has 8 beats. You take 6 steps: on 1, 2, 3 and on 5, 6, 7.", "8.circle.fill", .attentive, highlight: "6 steps"),
                storyCard("The pauses", "On 4 and 8 you don't step — you hold. The pause is what makes salsa look smooth instead of rushed.", "pause.circle.fill", .curious, highlight: "you hold"),
                storyCard("Quick-quick-slow", "Because of the pause, step 3 lasts twice as long as steps 1 and 2. Dancers say: quick, quick, slow.", "hare.fill", .happy, highlight: "quick, quick, slow"),
            ]),
            .listen("Count along", [
                "Listen and count with me out loud.",
                "One, two, three… pause. Five, six, seven… pause.",
                "Again: one, two, three… hold. Five, six, seven… hold.",
                "Quick, quick, slow. Quick, quick, slow.",
                "Feel it? The pause is part of the dance.",
            ], prompt: "Say the count out loud with ilo"),
            .bricks("Build one salsa phrase", ["1", "2", "3", "pause", "5", "6", "7", "pause"], distractors: ["4", "8"],
                    why: "You step on 1-2-3 and 5-6-7. Beats 4 and 8 are pauses."),
            .blank("In salsa you pause on beats 4 and ___.", ["6", "8", "1", "5"], 1, why: "The two pauses are on 4 and 8."),
            .timer("Clap on 1-2-3 and 5-6-7, stay still on the pauses. Start slow — this is 120 beats per minute.", bpm: 120,
                   labels: ["1", "2", "3", "·", "5", "6", "7", "·"], seconds: 60, title: "Clap the count"),
            .mcq("Why do salsa dancers pause on 4 and 8?", ["To rest their legs", "It gives the step its quick-quick-slow rhythm", "Because the music stops", "To wait for their partner"], 1,
                 why: "The pause makes step 3 (and 7) longer: quick, quick, slow."),
            .speed("Count check — fast!", seconds: 25, [
                ("You step on beat 4.", false, "4 is a pause."),
                ("You step on beat 5.", true, "5 starts the second half."),
                ("You step on beat 8.", false, "8 is a pause."),
                ("A salsa phrase has 8 beats.", true, "Two groups of four."),
                ("Steps 1 and 2 are quick, step 3 is slow.", true, "Quick, quick, slow."),
            ]),
        ], takeaways: ["Step 1-2-3, pause, 5-6-7, pause.", "The pause makes it quick-quick-slow.", "Count out loud until it's automatic."])
    }

    static var basicStep: Flagship.Content {
        .lesson(intro: "Time to move your feet. Six small steps and you're dancing salsa.", modules: [
            .story("The basic step (forward & back)", [
                storyCard("Home base", "Stand with feet together, knees soft, weight on the balls of your feet. This is 'home'.", "house.fill", .attentive),
                storyCard("1-2-3: forward half", "1: step forward with your left foot. 2: rock your weight back onto your right (it stays in place). 3: bring the left foot back home.", "arrow.up", .curious, highlight: "forward with your left foot"),
                storyCard("5-6-7: back half", "5: step back with your right foot. 6: rock your weight forward onto your left. 7: bring the right foot back home. Pause on 4 and 8.", "arrow.down", .happy, highlight: "back with your right foot"),
                storyCard("Followers mirror it", "Partners mirror each other: the follower starts back with the right foot on 1 and forward with the left on 5.", "arrow.left.arrow.right", .proud),
                storyCard("Small is smooth", "Steps no longer than your foot. Big steps make you late — and the pause disappears.", "shoeprints.fill", .suspicious, highlight: "no longer than your foot"),
            ]),
            .order("Put the leader's basic in order", ["1 — left foot forward", "2 — rock onto the right", "3 — left foot back home",
                                                      "5 — right foot back", "6 — rock onto the left", "7 — right foot back home"],
                   why: "Forward half on 1-2-3, back half on 5-6-7, pauses on 4 and 8."),
            .timer("Dance the basic at slow-motion speed. Say the count out loud.", bpm: 110,
                   labels: ["1", "2", "3", "·", "5", "6", "7", "·"], seconds: 90, title: "Slow-motion basic"),
            .spot("Spot the mistakes in Leo's basic step", ["1: left foot forward", "2: rock onto the right", "3: left foot home",
                                                            "4: step with the right foot", "5: right foot back", "6: take a giant step back"],
                  wrong: [3, 5], why: "Beat 4 is a pause, and steps should stay small — no giant steps."),
            .camera("Salsa basic step", reps: 6, prompt: "Show ilo six clean basics. Stand where your whole body is in frame.",
                    cues: ["Small steps — no longer than your foot", "Soft knees, tall posture", "Hold still on 4 and 8"]),
            .mcq("Your steps keep drifting behind the music. The most likely fix?", ["Take bigger steps", "Take smaller steps", "Skip the pauses", "Look at your feet"], 1,
                 why: "Small steps are faster to finish, so you stay on time."),
            .flash("Recap", [("Beat 1 (leader)", "Left foot forward"), ("Beat 5 (leader)", "Right foot back"),
                             ("Beats 2 and 6", "Rock in place"), ("Step size", "No longer than your foot")]),
        ], takeaways: ["Leader: forward on 1, back on 5 — follower mirrors.", "Rock-steps on 2 and 6, home on 3 and 7.", "Small steps keep you on time."])
    }

    static var kitchenMission: Flagship.Content {
        .lesson(intro: "Your kitchen is now a dance floor. Two minutes, one song, zero audience.", modules: [
            .story("Why the kitchen?", [
                storyCard("Low stakes, high reps", "Practising somewhere boring and familiar takes the pressure off. Nobody's watching — except maybe the fridge.", "refrigerator.fill", .laughing),
                storyCard("Real music changes everything", "Counting to a metronome is one thing. Real songs have trumpets, voices and drums competing for your ears.", "music.note", .curious),
                storyCard("Two minutes is enough", "Short, daily and fun beats long and rare. Two minutes is about one chorus and a half.", "timer", .happy, highlight: "Short, daily and fun"),
            ]),
            .order("Plan your kitchen session", ["Clear a small space", "Put on a salsa song", "Find the beat and count out loud", "Dance the basic for 2 minutes", "Snap a photo of your dance floor"]),
            .mcq("Which song search will get you a real salsa track?", ["'Classic salsa songs'", "'Slow piano music'", "'Techno workout mix'"], 0,
                 why: "Search for salsa classics — many beginners like 'Oye Como Va' (Tito Puente) or 'Vivir Mi Vida' (Marc Anthony)."),
            .mission("Kitchen dance floor", "Dance the basic step for two minutes in your kitchen to a real salsa song.",
                     steps: ["Clear a small space and put your phone somewhere safe", "Play a salsa song you like",
                             "Count 1-2-3, 5-6-7 out loud for one phrase before moving", "Dance the basic for 2 minutes — small steps, soft knees",
                             "Take a photo of your kitchen dance floor"],
                     proof: "A photo of your kitchen dance floor"),
            .free("How did it go? What was easiest, and what was hardest?", rubric: ["Describes what they did", "Names something hard", "Names one thing to improve next time"],
                  sample: "Counting out loud helped a lot. Keeping the pause on 4 and 8 was the hardest — I kept stepping through it. Next time I'll practise with a slower song first.",
                  title: "Debrief"),
            .tf("True or false?", [
                ("Short daily practice beats one long session a week.", true, "Frequent reps build the habit and the muscle memory."),
                ("You should wait until you're good before dancing to real music.", false, "Real music is where you learn to hear the beat."),
            ]),
            .flash("Recap", [("Where to practise", "Somewhere low-stakes, like your kitchen"), ("How long", "2 minutes, daily"),
                             ("Before moving", "Count one phrase out loud")]),
        ], takeaways: ["Practise somewhere low-stakes.", "Two minutes a day builds the dance.", "Count one phrase before you move."])
    }

    static var findTheOne: Flagship.Content {
        .lesson(intro: "The hardest part of salsa isn't your feet. It's your ears. Let's find the 1.", modules: [
            .story("Finding the 1", [
                storyCard("What is 'the 1'?", "Salsa music comes in phrases of 8 beats. 'The 1' is the first beat of a phrase — the moment you start your basic.", "1.circle.fill", .attentive),
                storyCard("Listen for the big moments", "New sections, the start of a vocal line, or a big horn hit usually land on a 1.", "speaker.wave.3.fill", .curious, highlight: "usually land on a 1"),
                storyCard("Tap it first", "Before dancing, tap your leg on every beat and count to 8. When a new section starts on your '1', you've found it.", "hand.tap.fill", .happy),
                storyCard("The clave", "Salsa is built on the clave, a 5-note rhythm over two bars (3-2 or 2-3). You don't need to master it — just know it's the heartbeat.", "waveform.path", .proud, highlight: "5-note rhythm"),
            ]),
            .estimate("How many beats per minute does a typical salsa song have?", min: 60, max: 300, answer: 180, unit: "BPM",
                      why: "Most salsa songs sit roughly between 150 and 220 BPM — fast! That's why small steps matter."),
            .highlight("Tap the moments that are good clues for 'the 1'", ["A new verse starts", "The trumpets hit a big accent", "Someone coughs in the crowd",
                                                                           "The singer starts a new line", "The song fades out", "The chorus kicks in"],
                       find: [0, 1, 3, 5], why: "Section changes, big accents and the start of vocal lines usually land on the 1."),
            .mcq("You started dancing and you're off the beat. The best move?", ["Keep going and hope", "Stop, listen for the next phrase, restart on 1", "Speed up", "Switch to a turn"], 1,
                 why: "Pros do it too: pause, find the next 1, and restart the basic."),
            .timer("Tap your leg on every beat and say '1' at the start of each phrase. 160 BPM — closer to real songs.", bpm: 160,
                   labels: ["1", "2", "3", "4", "5", "6", "7", "8"], seconds: 60, title: "Tap the phrase"),
            .match("Match the music words", [("The 1", "First beat of a phrase"), ("Phrase", "8 beats of music"), ("Clave", "Salsa's heartbeat rhythm"), ("BPM", "Beats per minute")]),
            .speed("Ears on!", seconds: 30, [
                ("A salsa phrase is 8 beats long.", true, "Count 1 to 8."),
                ("The 1 is always the loudest instrument.", false, "It's about phrase starts, not volume."),
                ("New song sections usually start on a 1.", true, "A great clue."),
                ("If you lose the beat, you should stop and restart on the next 1.", true, "That's what good dancers do."),
                ("The clave is a type of salsa shoe.", false, "It's the 5-note rhythm pattern — and the wooden sticks that play it."),
            ]),
        ], takeaways: ["The 1 is the first beat of an 8-count phrase.", "Section changes and vocal lines are clues.", "Lost? Pause and restart on the next 1."])
    }

    static var beatBoss: Flagship.Content {
        .lesson(intro: "Boss battle! Counting, the basic step and finding the 1 — a little faster.", modules: [
            .speed("Warm-up round", seconds: 30, [
                ("You pause on 4 and 8.", true, "Steps on 1-2-3 and 5-6-7."),
                ("The leader starts forward with the right foot.", false, "The leader starts forward with the left on 1."),
                ("Salsa means 'sauce'.", true, "A spicy mix of styles."),
                ("Steps should be about shoulder-width long.", false, "Keep them no longer than your foot."),
                ("A salsa phrase has 8 beats.", true, "Two groups of four."),
                ("Most salsa songs are slower than 100 BPM.", false, "Most are roughly 150–220 BPM."),
            ]),
            .mcq("The follower's first step on 1 is…", ["Left foot forward", "Right foot back", "A turn", "A pause"], 1,
                 why: "The follower mirrors the leader: right foot back on 1."),
            .bricks("Build the back half of the basic", ["5", "6", "7", "pause"], distractors: ["4", "8", "3"], why: "5-6-7, then pause on 8."),
            .match("Match the beat to the move (leader)", [("1", "Left forward"), ("2", "Rock onto right"), ("5", "Right back"), ("8", "Pause")]),
            .sort("Helps you stay on time, or throws you off?", buckets: ["Keeps you on time", "Throws you off"],
                  [("Small steps", 0), ("Counting out loud", 0), ("Giant steps", 1), ("Skipping the pauses", 1), ("Restarting on the next 1", 0), ("Staring at your feet", 1)],
                  why: "Small steps, counting and restarting on 1 keep you in time."),
            .blank("If you get lost, pause and restart on the next ___.", ["1", "4", "turn", "song"], 0),
            .timer("Final drill: the basic at real party speed. You've got this.", bpm: 170, labels: ["1", "2", "3", "·", "5", "6", "7", "·"], seconds: 60, title: "Party speed"),
            .teach("Teach ilo the salsa basic step like I've never danced before.", rubric: ["Mentions stepping on 1-2-3 and 5-6-7", "Mentions pausing on 4 and 8", "Mentions small steps or rocking in place"],
                   sample: "Count to eight. Step forward on 1, rock back on 2, come home on 3, pause on 4. Then step back on 5, rock forward on 6, home on 7, pause on 8. Keep the steps small."),
            .speed("Final round", seconds: 25, [
                ("Beat 3 lasts longer than beats 1 and 2 because of the pause.", true, "Quick, quick, slow."),
                ("The clave is salsa's rhythmic heartbeat.", true, "A 5-note pattern over two bars."),
                ("Section changes are a clue for finding the 1.", true, "Listen for them."),
                ("You should step on 8.", false, "8 is a pause."),
            ]),
        ], takeaways: ["You own the count and the basic.", "Small steps, pauses on 4 and 8.", "Lost? Restart on the next 1."])
    }

    // MARK: - Unit 2 (seeds, composed)

    static let sideBasic = KnowledgeSeed(
        intro: "Crowded floor at {event}? The side basic is your best friend.",
        cards: [
            storyCard("Same count, new direction", "The side basic keeps 1-2-3, 5-6-7 — but on 1 you step to the side instead of forward.", "arrow.left.and.right", .curious, highlight: "step to the side"),
            storyCard("Left on 1, right on 5", "1: left foot steps left. 2: rock onto the right. 3: left comes home. 5: right steps right. 6: rock left. 7: home.", "shoeprints.fill", .attentive),
            storyCard("Perfect for tight spaces", "It barely travels, so it's ideal next to a buffet table — or {who}.", "person.2.fill", .happy),
        ],
        questions: [
            .q("In the side basic, what does the leader's left foot do on 1?", ["Steps forward", "Steps to the left", "Steps back", "Stays still"], 1, "Side basic: left foot steps left on 1."),
            .q("When is the side basic most useful?", ["On a crowded floor", "Only on stage", "When you want to travel far"], 0, "It barely travels."),
        ],
        statements: [.s("The side basic uses a different count from the basic.", false, "Same 1-2-3, 5-6-7 count."),
                     .s("On 5 the right foot steps to the right.", true), .s("You still pause on 4 and 8.", true)],
        pairs: [.p("Beat 1", "Left foot steps left"), .p("Beat 5", "Right foot steps right"), .p("Beats 2 and 6", "Rock in place"), .p("Beats 4 and 8", "Pause")],
        blanks: [.b("In the side basic you step to the ___ on 1.", ["side", "front", "back"], 0)],
        practice: [.timer("Side basic, slow and small. Count out loud.", bpm: 120, labels: ["1", "2", "3", "·", "5", "6", "7", "·"], seconds: 75, title: "Side basic")],
        takeaways: ["Side basic: same count, step to the side.", "Perfect for crowded floors."]
    )

    static let firstTurn = KnowledgeSeed(
        intro: "Let's add your first turn. Spoiler: it's just walking in a tiny circle, on time.",
        cards: [
            storyCard("Prep, then turn", "Dance the forward half on 1-2-3 as a prep. Then on 5-6-7 walk a small circle to your right, and pause on 8.", "arrow.clockwise", .excited, highlight: "on 5-6-7"),
            storyCard("Balls of your feet", "Turn on the balls of your feet with your feet close together. Flat feet stick to the floor.", "shoeprints.fill", .attentive),
            storyCard("Spot it", "Pick a point at eye level. Keep your eyes on it as long as you can, then whip your head round to find it again.", "eye.fill", .curious, highlight: "whip your head round"),
        ],
        questions: [
            .q("What does 'spotting' prevent?", ["Stepping on toes", "Dizziness", "Losing the count"], 1, "Fixing your eyes on a point keeps you from getting dizzy."),
            .q("On which counts do you turn in this course?", ["1-2-3", "5-6-7", "4 and 8"], 1, "Prep on 1-2-3, turn on 5-6-7."),
        ],
        statements: [.s("Turning on flat feet is easiest.", false, "Use the balls of your feet."), .s("Your head turns last and arrives first when spotting.", true),
                     .s("A turn still follows the salsa count.", true)],
        pairs: [.p("Prep", "1-2-3"), .p("Turn", "5-6-7"), .p("Spotting", "Eyes fixed on a point"), .p("Balls of feet", "Where you turn")],
        sequencePrompt: "Order the solo right turn",
        sequence: ["Dance the forward half on 1-2-3", "Pause on 4", "Turn right on 5-6-7, spotting", "Pause on 8, facing front"],
        blanks: [.b("To avoid dizziness, dancers use ___.", ["spotting", "squinting", "stomping"], 0)],
        practice: [
            .camera("Solo right turn", reps: 4, prompt: "Show ilo four right turns. Keep your whole body in frame.",
                    cues: ["Feet close together", "Turn on the balls of your feet", "Spot a point at eye level"]),
            .timer("Basic, basic, turn. Repeat. Slow and controlled.", bpm: 120, labels: ["1", "2", "3", "·", "5", "6", "7", "·"], seconds: 90, title: "Turn drill"),
        ],
        takeaways: ["Prep on 1-2-3, turn on 5-6-7.", "Turn on the balls of your feet.", "Spot to stay un-dizzy."]
    )

    static let tiaRosa = KnowledgeSeed(
        intro: "Story time: the dizzy nephew and Tía Rosa's secret.",
        cards: [
            storyCard("Dizzy Dani", "At a family party, Dani tried three spins in a row. The room kept spinning after he stopped. So did the cake.", "tornado", .scared),
            storyCard("Enter Tía Rosa", "Tía Rosa, 72, the family's best dancer, laughed: 'Mijo, you're looking everywhere. Look at one thing.'", "figure.dance", .laughing),
            storyCard("The secret", "'Pick the clock on the wall. Eyes on it, head turns last, finds it first. And small steps — you're not running.'", "clock.fill", .proud, highlight: "head turns last, finds it first"),
            storyCard("One clean turn", "Dani did one slow turn, spotting the clock. No dizziness. Tía Rosa nodded: 'One clean turn beats three messy ones.'", "checkmark.seal.fill", .happy, highlight: "One clean turn beats three messy ones"),
        ],
        questions: [
            .q("What was Tía Rosa's advice?", ["Spin faster", "Spot one point and keep steps small", "Close your eyes"], 1),
            .q("Why did Dani get dizzy?", ["His eyes weren't fixed on anything", "The music was too loud", "He paused on 4"], 0),
        ],
        statements: [.s("One clean turn beats three messy ones.", true), .s("Closing your eyes helps you turn.", false, "Spotting needs your eyes on a point.")],
        sequencePrompt: "Order Tía Rosa's turn recipe",
        sequence: ["Pick a point on the wall", "Keep your eyes on it", "Let your head turn last", "Find the point again first"],
        blanks: [.b("When spotting, your head turns ___ and arrives first.", ["last", "first", "never"], 0)],
        scenario: .scenario("Mid-song at {event}, you feel dizzy after a turn. What now?", ["Do another turn to shake it off", "Go back to the basic step and find your spot", "Stop dancing for the night"], 1,
                            consequences: ["The room spins even more.", "The basic is your safe home — you're back on the beat in 8 counts.", "You'd miss the best songs!"],
                            why: "The basic step is always your safe home."),
        practice: [.free("What's one thing you'd tell a friend who gets dizzy when turning?", rubric: ["Mentions spotting / fixing the eyes", "Mentions small or slow steps"],
                         sample: "Pick one point at eye level and keep your eyes on it — your head turns last and finds it first. And keep the steps small.")],
        takeaways: ["Spot one point: head turns last, arrives first.", "One clean turn beats three messy ones."]
    )

    static let armsAndShine = KnowledgeSeed(
        intro: "Now let's make it look good — relaxed, not robotic.",
        cards: [
            storyCard("Relaxed arms", "Elbows soft and slightly bent, hands around waist height. Let your arms swing gently with your steps.", "figure.arms.open", .happy),
            storyCard("Motion from the knees", "Bend the knee as you step and straighten it as weight arrives. Your hips move by themselves — that's 'Cuban motion'.", "figure.walk", .excited, highlight: "Cuban motion"),
            storyCard("Shines", "Shines are footwork patterns you dance on your own, facing your partner. The basic itself is your first shine.", "sparkles", .proud),
        ],
        questions: [
            .q("Where does hip motion in salsa mainly come from?", ["Pushing the hips side to side", "Bending and straightening the knees as you step", "Swinging the arms"], 1, "Hips follow the knees and the weight transfer."),
            .q("What is a 'shine'?", ["A spin", "Solo footwork danced apart from your partner", "A shiny outfit"], 1),
        ],
        statements: [.s("Stiff straight arms look most elegant.", false, "Relaxed, slightly bent arms look natural."), .s("The basic step counts as a shine.", true),
                     .s("Hip motion comes from the knees and weight transfer.", true)],
        pairs: [.p("Shine", "Solo footwork"), .p("Cuban motion", "Hips from the knees"), .p("Soft elbows", "Relaxed arms"), .p("Weight transfer", "Moving onto the new foot")],
        blanks: [.b("Hip motion comes from bending and straightening the ___.", ["knees", "elbows", "wrists"], 0)],
        practice: [.camera("Basic with relaxed arms", reps: 8, prompt: "Show ilo eight basics with relaxed arms and soft knees.",
                           cues: ["Elbows soft, hands at waist height", "Bend the knee as you step", "Let the hips follow"])],
        takeaways: ["Relax the arms; let them follow your steps.", "Hips move from the knees.", "Shines = solo footwork."]
    )

    static let countWithIlo = KnowledgeSeed(
        intro: "Call time! Count the basic out loud with ilo — no dancing required.",
        cards: [
            storyCard("Why say it out loud?", "Counting out loud links your ears, voice and feet. Teachers do it all the time.", "waveform", .curious),
            storyCard("What ilo will ask", "Count one phrase, tell ilo where the pauses are, and explain how you'd find the 1 in a song.", "questionmark.bubble.fill", .attentive),
        ],
        questions: [.q("Where are the pauses in a salsa phrase?", ["2 and 6", "4 and 8", "1 and 5"], 1)],
        statements: [.s("Counting out loud helps your feet follow the music.", true), .s("You should count silently only.", false)],
        pairs: [.p("1-2-3", "Quick, quick, slow"), .p("4", "Pause"), .p("5-6-7", "Quick, quick, slow"), .p("8", "Pause")],
        practice: [.call("ilo, your salsa coach", goal: "Count one salsa phrase out loud and explain where the pauses go",
                         opening: "¡Hola! Ready to count with me? Give me one full phrase of the basic — out loud!", turns: 4)],
        takeaways: ["Say the count out loud.", "Pauses on 4 and 8."]
    )

    // MARK: - Unit 3

    static let holdDontGrab = KnowledgeSeed(
        intro: "Partner time! The secret of a great partner: a light, clear connection.",
        cards: [
            storyCard("Open hold", "Face each other, arms relaxed at waist height. Leader's palms up, follower's fingers resting in them.", "hand.raised.fill", .happy, highlight: "palms up"),
            storyCard("No thumbs!", "Never squeeze or hook with your thumbs — the follower must be able to turn freely.", "hand.thumbsdown.fill", .suspicious, highlight: "Never squeeze"),
            storyCard("Tone, not tension", "Arms should feel like a firm handshake: toned enough to feel a lead, soft enough not to push.", "figure.2.arms.open", .attentive, highlight: "firm handshake"),
            storyCard("Closed hold", "Leader's right hand on the follower's shoulder blade, follower's left hand on the leader's shoulder. Other hands joined at eye level.", "figure.2", .proud),
        ],
        questions: [
            .q("How should the leader hold the follower's hand in open hold?", ["Tight grip with thumbs", "Palms up, fingers resting — no thumb grip", "Only by the wrist"], 1),
            .q("What should partner arms feel like?", ["Limp noodles", "A firm, friendly handshake", "Steel bars"], 1, "Tone, not tension."),
        ],
        statements: [.s("Gripping with your thumbs makes turns safer.", false, "It blocks the turn and can hurt wrists."),
                     .s("In closed hold the leader's right hand rests on the follower's shoulder blade.", true), .s("Good connection feels light but clear.", true)],
        pairs: [.p("Open hold", "Facing, hands at waist height"), .p("Closed hold", "Hand on the shoulder blade"), .p("Tone", "Firm but soft arms"), .p("Thumbs", "Never grip with them")],
        blanks: [.b("Connection should feel like a firm ___.", ["handshake", "hug", "push"], 0)],
        practice: [.sort("Good connection or bad connection?", buckets: ["Good", "Bad"],
                         [("Palms up, fingers resting", 0), ("Squeezing with thumbs", 1), ("Toned arms", 0), ("Pushing your partner", 1), ("Elbows soft and down", 0), ("Limp arms", 1)])],
        takeaways: ["Palms up, no thumbs.", "Tone, not tension — like a firm handshake."]
    )

    static let crossBody = KnowledgeSeed(
        intro: "The cross-body lead: the move that makes people say 'oh, they can dance'.",
        cards: [
            storyCard("Swap places", "In the cross-body lead, partners swap places across an imaginary line called the slot.", "arrow.triangle.swap", .excited),
            storyCard("Leader opens the lane", "On 1-2-3 the leader steps forward, rocks, then steps out of the slot, turning a quarter to the left — opening a lane.", "arrow.turn.up.left", .attentive, highlight: "opening a lane"),
            storyCard("Follower walks through", "On 5-6-7 the follower walks forward through the lane and turns to face the leader. Swap complete!", "figure.walk", .happy, highlight: "walks forward through the lane"),
        ],
        questions: [
            .q("What does the leader do on 1-2-3 of a cross-body lead?", ["Spins the follower", "Opens a lane by stepping out of the slot", "Pauses"], 1),
            .q("What does the follower do on 5-6-7?", ["Walks through the lane and turns to face the leader", "Steps back", "Stops"], 0),
        ],
        statements: [.s("In a cross-body lead partners swap places.", true), .s("The follower crosses on 1-2-3.", false, "The follower crosses on 5-6-7."),
                     .s("The 'slot' is the imaginary line you dance along.", true)],
        pairs: [.p("Slot", "The imaginary line"), .p("Lane", "Space the leader opens"), .p("1-2-3", "Leader opens"), .p("5-6-7", "Follower crosses")],
        sequencePrompt: "Order the cross-body lead",
        sequence: ["Leader steps forward on 1", "Leader rocks on 2", "Leader steps out of the slot on 3", "Follower walks through on 5-6", "Follower turns to face the leader on 7"],
        blanks: [.b("The follower crosses the slot on ___.", ["5-6-7", "1-2-3", "4 and 8"], 0)],
        practice: [
            .timer("Walk the cross-body lead slowly — solo or with a partner. Count out loud.", bpm: 110, labels: ["1", "2", "3", "·", "5", "6", "7", "·"], seconds: 90, title: "Cross-body drill"),
            .camera("Cross-body lead footwork", reps: 4, prompt: "Show ilo four slow cross-body leads (solo is fine).", cues: ["Open the lane on 1-2-3", "Quarter turn, not a full spin", "Stay on the count"]),
        ],
        takeaways: ["Leader opens the lane on 1-2-3.", "Follower crosses on 5-6-7.", "You swap places along the slot."]
    )

    static let askingToDance = KnowledgeSeed(
        intro: "The bravest move in salsa isn't a spin. It's asking someone to dance.",
        cards: [
            storyCard("The ask", "Smile, make eye contact, offer an open hand: 'Would you like to dance?' Simple is perfect.", "hand.wave.fill", .shy),
            storyCard("Match their level", "Start with the basic. If your partner is new, keep it simple and make them look good.", "person.2.fill", .happy, highlight: "make them look good"),
            storyCard("Floor manners", "Keep steps small, watch out for other couples, and never lead a move into someone else's space.", "exclamationmark.triangle.fill", .attentive),
            storyCard("The thank-you", "When the song ends, say thank you and walk your partner back. Every time.", "heart.fill", .proud, highlight: "say thank you"),
        ],
        questions: [
            .q("Your partner at {event} is a total beginner. What do you do?", ["Show off your turns", "Keep to the basic and make them look good", "Leave after one bar"], 1),
            .q("What should you do when the song ends?", ["Walk off", "Say thank you and walk your partner back", "Ask for feedback"], 1),
        ],
        statements: [.s("A simple 'Would you like to dance?' is perfect.", true), .s("On a busy floor, big moves are fine if you're confident.", false, "Keep it small and safe."),
                     .s("You should thank your partner after every dance.", true)],
        sequencePrompt: "Order the perfect dance invitation",
        sequence: ["Smile and make eye contact", "Offer an open hand", "Ask: 'Would you like to dance?'", "Start with the basic", "Say thank you at the end"],
        practice: [.roleplay("{Who}, at {event}, a little shy about dancing", goal: "Invite {who} to dance kindly and reassure them it's just the basic",
                             opening: "Oh, I haven't danced salsa in years… I'm not sure my feet remember!", turns: 4,
                             prompt: "Invite {who} to dance")],
        takeaways: ["Smile, open hand, 'Would you like to dance?'", "Dance to your partner's level.", "Always say thank you."]
    )

    static let partnerMission = KnowledgeSeed(
        intro: "Mission time: one song, one partner, your basic and one turn.",
        cards: [
            storyCard("Any partner counts", "A friend, a parent, a flatmate, {who} — anyone willing to laugh with you.", "person.2.fill", .happy),
            storyCard("Keep it simple", "Basic, side basic, one turn. Repeat. When lost, go back to the basic.", "repeat", .attentive),
        ],
        questions: [.q("You lose the beat halfway through the song. Best move?", ["Stop the song", "Go back to the basic and restart on the next 1", "Improvise a spin"], 1)],
        statements: [.s("Going back to the basic is a sign of failure.", false, "It's what every good dancer does.")],
        sequencePrompt: "Order your mission",
        sequence: ["Find a partner", "Pick a salsa song", "Dance basic, side basic and one turn", "Take a photo together"],
        practice: [.mission("Partner mission", "Dance one full salsa song with a partner.",
                            steps: ["Find a partner — anyone who'll laugh with you", "Pick a salsa song you both like", "Dance the basic, the side basic and one turn",
                                    "When lost, go back to the basic", "Take a photo together"],
                            proof: "A photo of you and your dance partner")],
        takeaways: ["Anyone can be your practice partner.", "When lost, go back to the basic."]
    )

    // MARK: - Unit 4

    static let buildRoutine = KnowledgeSeed(
        intro: "Let's turn your moves into a routine you can dance on autopilot at {event}.",
        cards: [
            storyCard("Think in 8s", "Every move lasts one or two 8-count phrases. Chain them like building blocks.", "square.stack.3d.up.fill", .curious, highlight: "building blocks"),
            storyCard("Your routine", "2× basic → 2× side basic → right turn → basic → cross-body lead → basic. About 30 seconds. Repeat.", "list.number", .excited),
            storyCard("The golden rule", "Between every move, come home to the basic. It resets the count and your nerves.", "house.fill", .proud, highlight: "come home to the basic"),
        ],
        questions: [
            .q("What should you dance between moves?", ["A spin", "The basic step", "Nothing"], 1, "The basic resets the count."),
            .q("How long does most beginner move last?", ["One or two 8-count phrases", "Half a beat", "A whole song"], 0),
        ],
        statements: [.s("A routine is a chain of moves in 8-count blocks.", true), .s("You must never repeat a move.", false, "Repetition is what makes a routine feel easy.")],
        pairs: [.p("Basic", "Home base"), .p("Side basic", "Crowded-floor move"), .p("Right turn", "Prep 1-2-3, turn 5-6-7"), .p("Cross-body lead", "Swap places")],
        sequencePrompt: "Order your routine",
        sequence: ["2× basic", "2× side basic", "Right turn", "Basic", "Cross-body lead", "Basic"],
        blanks: [.b("Between every move, come home to the ___.", ["basic", "bar", "door"], 0)],
        practice: [.teach("Explain your routine to ilo, move by move, with the counts.", rubric: ["Lists the moves in order", "Mentions counts or 8-count phrases", "Mentions returning to the basic"],
                          sample: "Two basics, two side basics, a right turn with the prep on 1-2-3 and the turn on 5-6-7, a basic, a cross-body lead, then back to the basic.")],
        takeaways: ["Build routines from 8-count blocks.", "Always come home to the basic."]
    )

    static let dressRehearsal = KnowledgeSeed(
        intro: "Dress rehearsal! Real tempo, full routine, one camera check.",
        cards: [
            storyCard("Real tempo", "Salsa songs often run at 150–220 BPM. Today you practise at 180 — party speed.", "speedometer", .excited, highlight: "180"),
            storyCard("Rehearse like it's real", "Shoes you'll wear, a song you love, and a smile. Rehearsing the vibe matters too.", "shoe.fill", .happy),
        ],
        questions: [.q("Why rehearse in the shoes you'll wear at {event}?", ["They change how you turn and step", "For the photos", "No reason"], 0)],
        statements: [.s("Rehearsing at the real tempo prepares you for the real song.", true), .s("Smiling while dancing is a waste of focus.", false, "It relaxes you and your partner.")],
        pairs: [.p("180 BPM", "Party speed"), .p("Real shoes", "Real conditions"), .p("Camera", "Honest feedback"), .p("Smile", "Relaxes everyone")],
        blanks: [.b("Rehearse at the ___ tempo of real songs.", ["real", "slowest", "silent"], 0)],
        practice: [
            .timer("Full routine at party speed. Keep coming home to the basic.", bpm: 180, labels: ["1", "2", "3", "·", "5", "6", "7", "·"], seconds: 120, title: "Party-speed routine"),
            .camera("Your full routine", reps: 2, prompt: "Show ilo your routine twice through.", cues: ["Small steps at speed", "Relaxed arms", "Smile!"]),
        ],
        takeaways: ["Rehearse at real tempo.", "Rehearse the vibe: shoes, song, smile."]
    )

    static let nerves = KnowledgeSeed(
        intro: "A story about nerves, a missed step, and the best dance of the night.",
        cards: [
            storyCard("Heart racing", "Ana had practised for weeks. When her song came on at the reception, her hands went cold.", "heart.fill", .scared),
            storyCard("The stumble", "Four bars in, she missed a turn. She froze for a second… then laughed, found the 1, and went back to the basic.", "arrow.uturn.backward", .surprised),
            storyCard("Nobody noticed", "Everyone saw a smiling dancer. Her abuela danced right next to her the whole song.", "sparkles", .happy, highlight: "Everyone saw a smiling dancer"),
            storyCard("The lesson", "Mistakes last one second. Smiles last the whole song. The basic step is always there to catch you.", "checkmark.seal.fill", .proud, highlight: "Mistakes last one second"),
        ],
        questions: [
            .q("What did Ana do after missing the turn?", ["Left the floor", "Laughed, found the 1 and went back to the basic", "Tried the turn again immediately"], 1),
            .q("What's a good way to calm nerves before dancing?", ["Slow breaths and counting one phrase before moving", "Running laps", "Skipping the warm-up"], 0),
        ],
        statements: [.s("Most people notice every small mistake you make.", false, "People mostly see your smile and energy."), .s("The basic step can rescue any dance.", true)],
        sequencePrompt: "Order Ana's recovery",
        sequence: ["Missed the turn", "Laughed it off", "Found the next 1", "Went back to the basic", "Finished the song smiling"],
        blanks: [.b("Mistakes last one second; ___ last the whole song.", ["smiles", "steps", "shoes"], 0)],
        scenario: .scenario("You step on your partner's foot at {event}. What do you do?", ["Stop and apologise for a full minute", "Quick 'sorry!', smile, back to the basic", "Pretend it didn't happen"], 1,
                            consequences: ["The moment gets awkward and you lose the song.", "Perfect — it happens to everyone, and you keep dancing.", "Your partner may think you didn't notice."],
                            why: "A quick sorry and a smile keeps the joy going."),
        practice: [.free("What will you tell yourself if you make a mistake at {event}?", rubric: ["A kind, calm self-message", "A concrete recovery step (e.g. go back to the basic)"],
                         sample: "Mistakes last one second. Smile, find the next 1, and go back to the basic.")],
        takeaways: ["Mistakes last one second; smiles last the song.", "Recover with the basic step."]
    )

    static let showtime = KnowledgeSeed(
        intro: "Showtime. Record your routine — future you will love this video.",
        cards: [
            storyCard("Why record?", "Video shows what you can't feel: step size, posture, timing. It's also a great memory.", "video.fill", .curious),
            storyCard("Watch it once, kindly", "Name one thing you nailed and one thing to polish. That's it.", "eye.fill", .happy),
        ],
        questions: [.q("After watching your video, what should you note?", ["Everything that's wrong", "One thing you nailed and one to polish", "Nothing"], 1)],
        statements: [.s("Video feedback shows things you can't feel while dancing.", true)],
        sequencePrompt: "Order your showtime",
        sequence: ["Set up your phone to film", "Play a salsa song", "Dance your one-minute routine", "Watch it back once", "Note one win and one fix"],
        practice: [.mission("Showtime", "Record your one-minute routine to a real salsa song.",
                            steps: ["Prop your phone up so your whole body is in frame", "Play a salsa song and count one phrase", "Dance your routine for one minute",
                                    "Watch it back once — one win, one fix", "Save a screenshot of your favourite moment"],
                            proof: "A screenshot from your routine video")],
        takeaways: ["Video is honest, fast feedback.", "One win, one fix — every time."]
    )
}
