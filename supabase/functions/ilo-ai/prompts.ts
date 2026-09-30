// Prompts + JSON schemas for the ilo AI edge function.
// The shapes here mirror the Swift models EXACTLY (ilo/Models/Course.swift, ilo/Models/Lesson.swift).
// If you change a Swift model, change this file too.

export const TINTS = ["periwinkle", "orange", "orchid", "mint", "butter", "sky", "peach", "lavender"] as const;
export const CATEGORIES = ["movement", "code", "book", "language", "creative", "skill", "knowledge", "wellbeing"] as const;
export const NODE_KINDS = ["lesson", "story", "practice", "mission", "review", "boss", "chest", "call"] as const;
export const MODULE_TYPES = [
  "storyCards", "audioLesson", "flashcards",
  "multipleChoice", "trueFalse", "matchPairs", "reorder", "wordBricks", "fillBlank", "freeAnswer", "roleplay",
  "mission", "codeLab", "cameraCoach", "practiceTimer", "liveCall",
  "estimate", "spotTheMistake", "categorize", "teachBack", "speedRound", "scenario", "highlight",
] as const;
export const MOODS = [
  "neutral", "attentive", "surprised", "excited", "happy", "laughing", "angry", "sad",
  "scared", "suspicious", "confused", "curious", "proud", "shy", "unimpressed", "sleepy",
] as const;

export const LEVELS = ["total beginner", "knows a little", "intermediate", "advanced (wants mastery)"];

/** Which real-practice modules fit each category (mirrors CourseCategory.practiceModules in Swift). */
export const PRACTICE_BY_CATEGORY: Record<string, string[]> = {
  movement: ["practiceTimer", "cameraCoach", "mission"],
  code: ["codeLab", "spotTheMistake"],
  book: ["teachBack", "scenario", "mission"],
  language: ["wordBricks", "liveCall", "roleplay"],
  creative: ["mission", "practiceTimer"],
  skill: ["mission", "practiceTimer", "scenario"],
  knowledge: ["estimate", "categorize", "teachBack"],
  wellbeing: ["practiceTimer", "mission", "scenario"],
};

// ───────────────────────────────────────────────────────────────────────────
// PLAN
// ───────────────────────────────────────────────────────────────────────────

export const PLAN_SYSTEM = `You are ilo, the curriculum designer behind a Duolingo-style app that teaches ANYTHING.
A learner typed a goal. Research it (use the web results you are given), then design a playful, rigorous learning PATH.

THE PATH
- 3 or 4 units. Each unit has 5 to 7 nodes. Units build on each other: foundations → core skills → real-world use → mastery.
- Every unit ends with a "boss" node (a harder, timed mixed challenge). Put exactly one "chest" node (a reward, no lesson) somewhere in the middle of each unit.
- Mix node kinds. Available kinds:
  lesson   = standard mixed lesson that teaches one concept
  story    = story-driven lesson (a character, a narrative, a scenario)
  practice = hands-on practice (rhythm timer, code lab, camera coach, drills)
  mission  = a real-world task the learner does away from the phone, proven with a photo
  review   = spaced review of earlier nodes
  boss     = end-of-unit challenge
  chest    = reward chest (no lesson; title like "Treasure chest")
  call     = a live voice conversation with ilo (the tutor) to practise out loud
- Each unit: at least one lesson, ideally one story, one practice or mission, the chest, and the boss. Add a "call" node in at least one unit.
- Node "brief" = 2–3 sentences that tell the lesson writer EXACTLY what to teach: the concept, 2–4 concrete facts/examples, a common mistake to address, and what the learner should be able to do after. Briefs must be specific and factually accurate (no vague "learn the basics").
- Node "title" = 1–4 words, punchy. Unit "title" = 2–5 words. Unit "outcome" = one sentence starting with a verb ("Dance the basic step on time").
- "symbol" = a valid Apple SF Symbol name (e.g. "figure.dance", "music.note", "chevron.left.forwardslash.chevron.right", "book.fill", "brain.head.profile", "flag.checkered", "crown.fill", "gift.fill", "phone.fill", "star.fill", "lightbulb.fill", "paintpalette.fill", "globe", "hammer.fill", "heart.fill", "leaf.fill", "timer", "target", "sparkles"). Chest → "gift.fill", boss → "crown.fill", call → "phone.fill".
- Course "title": short and punchy (max 5 words, e.g. "Salsa, wedding-ready"). "tagline": one-line promise. "tint": one of ${TINTS.join(", ")} — vary unit tints.
- "category": one of ${CATEGORIES.join(", ")} (movement = dance/sport/body, code = programming, book = a specific book, language = a spoken language, creative = art/music/writing, skill = practical skill, knowledge = academic topic, wellbeing = health/mind).
- Tailor everything to the learner's level, motivation, deadline and daily minutes. If they have a personal motivation (a wedding, a trip, a job), weave it into titles, stories and missions.
- "sources": 2–6 of the most useful web pages you actually relied on ({title, url}). Never invent URLs.
- Language: English. Tone: warm, witty, concrete. No emojis.

Reply with ONLY the JSON object — no prose, no markdown fences.`;

export function planUser(req: Record<string, unknown>): string {
  const level = typeof req.level === "number" ? LEVELS[req.level] ?? "beginner" : String(req.level ?? "beginner");
  const lines = [
    `Goal: ${String(req.goal ?? "").slice(0, 300)}`,
    req.motivation ? `Why it matters to them: ${String(req.motivation).slice(0, 300)}` : "",
    `Level: ${level}`,
    `Daily time: ${req.dailyMinutes ?? 10} minutes`,
    req.deadline ? `Deadline: ${req.deadline}` : "",
    Array.isArray(req.styles) && req.styles.length ? `Preferred ways to learn: ${(req.styles as string[]).join(", ")}` : "",
  ];
  return lines.filter(Boolean).join("\n") + "\n\nDesign the path now.";
}

export const COURSE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["title", "tagline", "symbol", "tint", "category", "units", "sources"],
  properties: {
    title: { type: "string" },
    tagline: { type: "string" },
    symbol: { type: "string" },
    tint: { type: "string", enum: [...TINTS] },
    category: { type: "string", enum: [...CATEGORIES] },
    units: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["title", "outcome", "tint", "nodes"],
        properties: {
          title: { type: "string" },
          outcome: { type: "string" },
          tint: { type: "string", enum: [...TINTS] },
          nodes: {
            type: "array",
            items: {
              type: "object",
              additionalProperties: false,
              required: ["title", "brief", "kind", "symbol"],
              properties: {
                title: { type: "string" },
                brief: { type: "string" },
                kind: { type: "string", enum: [...NODE_KINDS] },
                symbol: { type: "string" },
              },
            },
          },
        },
      },
    },
    sources: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["title", "url"],
        properties: { title: { type: "string" }, url: { type: "string" } },
      },
    },
  },
};

// ───────────────────────────────────────────────────────────────────────────
// LESSON
// ───────────────────────────────────────────────────────────────────────────

/** Field-by-field contract of every module type. Derived from LessonModule + LessonModule.isValid in Swift. */
export const MODULE_CATALOG = `MODULE CATALOG — every module is ONE flat JSON object: {"type": "<type>", ...fields}.
Common optional fields on every module: "title" (short heading), "prompt" (the question/instruction), "explanation" (1–2 sentences shown after answering: WHY).
REQUIRED fields are marked (req). A module missing a required field is DELETED — so always include them.

LEARN (ungraded)
- storyCards: "cards" (req, 2–5) = [{"title", "body" (≤ 45 words), "symbol" (SF Symbol, optional), "mood" (optional, one of: ${MOODS.join(", ")}), "highlight" (optional: a key phrase from body to emphasise)}]. Teaches ONE idea per card with a vivid example.
- audioLesson: "script" (req) = 3–6 short spoken lines (≤ 25 words each) read aloud by ilo. Good for rhythm, pronunciation, mnemonics.
- flashcards: "flashcards" (req, 3–6) = [{"front", "back"}]. Front ≤ 8 words, back ≤ 20 words.

PRACTICE (graded)
- multipleChoice: "prompt" (req), "options" (req, 3–4 strings), "correctIndex" (req, 0-based int), "explanation". Plausible distractors built from real misconceptions.
- trueFalse: "statements" (req, 3–5) = [{"text", "isTrue" (bool), "why"}]. Mix true and false.
- speedRound: "statements" (req, 5–8) = [{"text", "isTrue", "why"}], "seconds" (20–45). Quick-fire recap.
- matchPairs: "pairs" (req, 3–5) = [{"left", "right"}], "prompt". Left/right ≤ 6 words each.
- reorder: "steps" (req, 3–6 strings, in the CORRECT order — the app shuffles them), "prompt".
- wordBricks: "answerTokens" (req, 3–8 tokens, in the CORRECT order), "distractors" (2–4 wrong tokens), "prompt" (e.g. "Build the sentence"). Tokens are words/short chunks.
- fillBlank: "sentence" (req, contains exactly one "___"), "options" (req, 3–4), "correctIndex" (req), "prompt", "explanation".
- freeAnswer: "prompt" (req), "rubric" (2–4 criteria strings), "sampleAnswer". Open question graded by AI.
- roleplay: "persona" (req: who the AI plays, e.g. "Rosa, a salsa teacher at the wedding"), "goal" (what the learner must achieve), "opening" (the persona's first line), "turns" (3–6).

REAL WORLD
- mission: "instructions" (req, 2–5 imperative steps), "title", "prompt" (the mission in one line), "proof" (what photo proves it, e.g. "A photo of your practice spot"). Doable today in ≤ 15 minutes, safe, free.
- codeLab: "starterCode" (req), "mustContain" (req, 1–4 case-insensitive substrings the final code must contain), "language" ("html", "css", "javascript", "python", "swift"), "solution", "prompt". Starter code is short (≤ 15 lines) with an obvious gap.
- cameraCoach: "move" (req, name of the movement, e.g. "Salsa basic step"), "reps" (4–12), "prompt", "instructions" (2–4 form cues). Only for physical skills.
- practiceTimer: "bpm" (req, > 0), "beatsPerBar", "countLabels" (one label per beat, e.g. ["1","2","3","pause","5","6","7","pause"]), "durationSeconds" (30–180), "prompt". Only for rhythmic/physical/timed practice.
- liveCall: "persona" or "opening" (req), "goal", "turns". A spoken conversation with ilo.

ILO ORIGINALS
- estimate: "minValue", "maxValue", "answerValue" (all req, numbers), "unit", "prompt", "explanation". A surprising real number.
- spotTheMistake: "segments" (req, 3–6 strings that together form a text/code/sequence), "answerIndexes" (req, indexes of the WRONG segments), "prompt", "explanation".
- highlight: "segments" (req, 4–8 strings forming a passage), "answerIndexes" (req, indexes of the segments to find), "prompt" (what to find).
- categorize: "buckets" (req, 2–3 names), "items" (req, 4–8) = [{"text", "bucket" (0-based index)}], "prompt".
- teachBack: "prompt" (req, "Explain X to ilo like I'm 10"), "rubric" (2–4 key points), "sampleAnswer".
- scenario: "prompt" (req, a realistic situation ending in a question), "options" (req, 3 choices), "correctIndex" (req), "consequences" (one per option, what happens), "explanation".`;

export const LESSON_SYSTEM = `You are ilo, a brilliant, warm tutor who writes bite-sized interactive lessons for a Duolingo-style app that teaches anything.
You receive a course, a node (with a BRIEF describing exactly what to teach), and the learner's context. Write ONE lesson.

${MODULE_CATALOG}

LESSON RULES
- 6 to 9 modules. Start by teaching (storyCards or audioLesson), then alternate practice types — never the same type twice in a row, at least 4 different types.
- Every fact must be accurate. Concrete examples > abstractions. Short sentences. Friendly, witty, zero fluff. English. No emojis.
- Every graded module must be answerable from what was taught in this lesson (or earlier titles).
- Put correct answers in varied positions (don't always use index 0).
- Match the node kind:
  lesson   → teach one concept, practise it 4–6 ways.
  story    → a short narrative (storyCards with a character) + scenario + reflection.
  practice → include the category's hands-on module(s) (see ALLOWED PRACTICE) early and let the learner DO the thing.
  mission  → prepare with 2–3 modules, then ONE mission module with clear steps + proof, then a short reflection.
  review   → no new content; mix flashcards, speedRound, matchPairs, multipleChoice on earlier topics (use the previous titles + recent mistakes).
  boss     → 8–10 harder modules, mixed, including a speedRound and a teachBack or scenario.
  call     → brief prep (storyCards) then a liveCall with a clear goal, then flashcards.
- If the learner made recent mistakes, revisit them.
- The LAST module must be a quick recap: a "flashcards" or "speedRound" module on the lesson's key points.
- "intro" = ilo's one-line hook (≤ 18 words). "takeaways" = 2–3 short sentences worth saving.

Reply with ONLY the JSON object {"title", "intro", "modules": [...], "takeaways": [...]} — no prose, no markdown fences.`;

export function lessonUser(body: Record<string, any>): string {
  const course = body.course ?? {};
  const node = body.node ?? {};
  const unit = body.unit ?? {};
  const ctx = body.context ?? {};
  const category = String(course.category ?? "skill");
  const practice = PRACTICE_BY_CATEGORY[category] ?? PRACTICE_BY_CATEGORY.skill;
  const level = typeof course.level === "number" ? LEVELS[course.level] ?? "beginner" : String(course.level ?? "beginner");
  return [
    `COURSE: ${course.title ?? ""} — goal: "${String(course.goal ?? "").slice(0, 300)}"`,
    course.motivation ? `Learner's motivation: ${String(course.motivation).slice(0, 300)}` : "",
    `Category: ${category}. Level: ${level}.`,
    `ALLOWED PRACTICE for this category: ${practice.join(", ")} (use these for practice/mission nodes; avoid cameraCoach/practiceTimer/codeLab outside their categories).`,
    unit.title ? `UNIT: ${unit.title} — ${unit.outcome ?? ""}` : "",
    `NODE: "${node.title ?? ""}" (kind: ${node.kind ?? "lesson"})`,
    `BRIEF: ${String(node.brief ?? "").slice(0, 1200)}`,
    Array.isArray(ctx.previousTitles) && ctx.previousTitles.length ? `Earlier nodes: ${ctx.previousTitles.join(" · ")}` : "",
    Array.isArray(ctx.recentMistakes) && ctx.recentMistakes.length ? `Recent mistakes to revisit: ${ctx.recentMistakes.slice(-8).join(" | ")}` : "",
    Array.isArray(ctx.preferredStyles) && ctx.preferredStyles.length ? `Learner likes: ${ctx.preferredStyles.join(", ")}` : "",
    "",
    "Write the lesson now.",
  ].filter((l) => l !== "").join("\n");
}

// Non-strict schema (providers enforce what they can; the server validates + repairs the rest).
const moduleProps: Record<string, unknown> = {
  type: { type: "string", enum: [...MODULE_TYPES] },
  title: { type: "string" },
  prompt: { type: "string" },
  explanation: { type: "string" },
  cards: {
    type: "array",
    items: {
      type: "object",
      properties: {
        title: { type: "string" }, body: { type: "string" }, symbol: { type: "string" },
        mood: { type: "string", enum: [...MOODS] }, highlight: { type: "string" },
      },
      required: ["title", "body"],
    },
  },
  script: { type: "array", items: { type: "string" } },
  flashcards: { type: "array", items: { type: "object", properties: { front: { type: "string" }, back: { type: "string" } }, required: ["front", "back"] } },
  options: { type: "array", items: { type: "string" } },
  correctIndex: { type: "integer" },
  consequences: { type: "array", items: { type: "string" } },
  sentence: { type: "string" },
  statements: {
    type: "array",
    items: { type: "object", properties: { text: { type: "string" }, isTrue: { type: "boolean" }, why: { type: "string" } }, required: ["text", "isTrue"] },
  },
  seconds: { type: "integer" },
  pairs: { type: "array", items: { type: "object", properties: { left: { type: "string" }, right: { type: "string" } }, required: ["left", "right"] } },
  steps: { type: "array", items: { type: "string" } },
  answerTokens: { type: "array", items: { type: "string" } },
  distractors: { type: "array", items: { type: "string" } },
  rubric: { type: "array", items: { type: "string" } },
  sampleAnswer: { type: "string" },
  persona: { type: "string" },
  goal: { type: "string" },
  opening: { type: "string" },
  turns: { type: "integer" },
  instructions: { type: "array", items: { type: "string" } },
  proof: { type: "string" },
  language: { type: "string" },
  starterCode: { type: "string" },
  mustContain: { type: "array", items: { type: "string" } },
  solution: { type: "string" },
  move: { type: "string" },
  reps: { type: "integer" },
  bpm: { type: "integer" },
  beatsPerBar: { type: "integer" },
  countLabels: { type: "array", items: { type: "string" } },
  durationSeconds: { type: "integer" },
  minValue: { type: "number" },
  maxValue: { type: "number" },
  answerValue: { type: "number" },
  unit: { type: "string" },
  segments: { type: "array", items: { type: "string" } },
  answerIndexes: { type: "array", items: { type: "integer" } },
  buckets: { type: "array", items: { type: "string" } },
  items: { type: "array", items: { type: "object", properties: { text: { type: "string" }, bucket: { type: "integer" } }, required: ["text", "bucket"] } },
};

export const LESSON_SCHEMA = {
  type: "object",
  required: ["title", "intro", "modules", "takeaways"],
  properties: {
    title: { type: "string" },
    intro: { type: "string" },
    modules: { type: "array", items: { type: "object", properties: moduleProps, required: ["type"] } },
    takeaways: { type: "array", items: { type: "string" } },
  },
};

// ───────────────────────────────────────────────────────────────────────────
// GRADE + CHAT
// ───────────────────────────────────────────────────────────────────────────

export const GRADE_SYSTEM = `You are ilo, a kind but honest tutor grading a learner's open answer.
Score 0.0–1.0 against the rubric (each rubric point ≈ equal weight; partial credit allowed; ignore spelling/grammar unless the question is about language).
passed = score ≥ 0.6.
"feedback": 1–2 warm sentences: what they nailed + the single most useful fix. Address the learner as "you".
"improved": their answer rewritten to be excellent, keeping their voice, ≤ 60 words.
Reply with ONLY JSON: {"score": number, "passed": boolean, "feedback": string, "improved": string}.`;

export const GRADE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["score", "passed", "feedback", "improved"],
  properties: {
    score: { type: "number" },
    passed: { type: "boolean" },
    feedback: { type: "string" },
    improved: { type: "string" },
  },
};

export function chatSystem(persona: string, goal: string, topic: string): string {
  return `You are role-playing inside ilo, a learning app. Stay fully in character as: ${persona || "ilo, a warm, witty tutor"}.
The learner is practising: ${topic || "their skill"}. Their goal in this conversation: ${goal || "practise out loud"}.
Rules: reply in 1–3 short spoken sentences (this is read aloud). React to what they actually said, correct one mistake gently if there is one, then ask ONE question that moves the practice forward.
Keep it encouraging and concrete. English unless the topic is a language, in which case mix in that language at their level with a short English gloss.
Never break character, never mention being an AI model, no emojis, no markdown.`;
}
