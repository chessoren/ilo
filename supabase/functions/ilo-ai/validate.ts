// Deterministic validation + repair of model output, mirroring LessonModule.isValid in Swift.
import { CATEGORIES, MODULE_TYPES, MOODS, NODE_KINDS, TINTS } from "./prompts.ts";

type J = Record<string, any>;

// ─── Lenient JSON extraction ───────────────────────────────────────────────

/** Parses the first JSON object in a model reply (tolerates code fences / leading prose). */
export function parseJSON(text: string): J {
  const trimmed = text.trim().replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/, "");
  try {
    return JSON.parse(trimmed);
  } catch { /* fall through */ }
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start >= 0 && end > start) return JSON.parse(trimmed.slice(start, end + 1));
  throw new Error("model did not return JSON");
}

// ─── Coercion helpers ──────────────────────────────────────────────────────

const str = (v: unknown): string | undefined => {
  if (typeof v === "string") { const t = v.trim(); return t.length ? t : undefined; }
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  return undefined;
};
const num = (v: unknown): number | undefined => {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim() !== "" && Number.isFinite(Number(v))) return Number(v);
  return undefined;
};
const int = (v: unknown): number | undefined => { const n = num(v); return n === undefined ? undefined : Math.round(n); };
const bool = (v: unknown): boolean | undefined => {
  if (typeof v === "boolean") return v;
  if (typeof v === "string") { const t = v.toLowerCase().trim(); if (t === "true") return true; if (t === "false") return false; }
  return undefined;
};
const strs = (v: unknown): string[] | undefined => {
  if (!Array.isArray(v)) return undefined;
  const out = v.map(str).filter((s): s is string => !!s);
  return out.length ? out : undefined;
};
const ints = (v: unknown): number[] | undefined => {
  if (!Array.isArray(v)) return undefined;
  const out = v.map(int).filter((n): n is number => n !== undefined);
  return out.length ? out : undefined;
};
const pick = <T extends string>(v: unknown, allowed: readonly T[], fallback: T): T =>
  (typeof v === "string" && (allowed as readonly string[]).includes(v) ? v as T : fallback);

// ─── Course ────────────────────────────────────────────────────────────────

export function repairCourse(raw: J): J {
  const units = (Array.isArray(raw.units) ? raw.units : []).map((u: J, ui: number) => {
    const nodes = (Array.isArray(u?.nodes) ? u.nodes : [])
      .map((n: J) => {
        const kind = pick(n?.kind, NODE_KINDS, "lesson");
        const title = str(n?.title);
        if (!title) return null;
        return {
          title: title.slice(0, 40),
          brief: str(n?.brief) ?? `Teach "${title}" with concrete examples and practice.`,
          kind,
          symbol: str(n?.symbol) ?? defaultSymbol(kind),
        };
      })
      .filter(Boolean) as J[];
    // Guarantee a boss at the end of every unit.
    if (nodes.length && nodes[nodes.length - 1].kind !== "boss") {
      nodes.push({ title: "Unit boss", brief: `A harder mixed challenge covering: ${nodes.filter((n) => n.kind !== "chest").map((n) => n.title).join(", ")}.`, kind: "boss", symbol: "crown.fill" });
    }
    return {
      title: str(u?.title) ?? `Unit ${ui + 1}`,
      outcome: str(u?.outcome) ?? "Level up your skills",
      tint: pick(u?.tint, TINTS, TINTS[ui % TINTS.length]),
      nodes,
    };
  }).filter((u: J) => u.nodes.length >= 2);

  if (!units.length) throw new Error("course has no usable units");

  const sources = (Array.isArray(raw.sources) ? raw.sources : [])
    .map((s: J) => ({ title: str(s?.title) ?? "", url: str(s?.url) ?? "" }))
    .filter((s: J) => /^https?:\/\//.test(s.url))
    .slice(0, 8);

  return {
    title: str(raw.title) ?? "Your path",
    tagline: str(raw.tagline) ?? "Built by ilo, just for you",
    symbol: str(raw.symbol) ?? "sparkles",
    tint: pick(raw.tint, TINTS, "periwinkle"),
    category: pick(raw.category, CATEGORIES, "skill"),
    units,
    sources,
  };
}

function defaultSymbol(kind: string): string {
  return ({
    lesson: "star.fill", story: "book.fill", practice: "dumbbell.fill", mission: "flag.checkered",
    review: "arrow.triangle.2.circlepath", boss: "crown.fill", chest: "gift.fill", call: "phone.fill",
  } as Record<string, string>)[kind] ?? "star.fill";
}

// ─── Lesson ────────────────────────────────────────────────────────────────

/** Normalises one module's fields (types, aliases) without judging validity. */
export function normaliseModule(m: J): J | null {
  if (!m || typeof m !== "object") return null;
  const type = str(m.type);
  if (!type || !(MODULE_TYPES as readonly string[]).includes(type)) return null;
  const out: J = { type };
  for (const k of ["title", "prompt", "explanation", "sentence", "sampleAnswer", "persona", "goal", "opening", "proof", "language", "starterCode", "solution", "move", "unit"]) {
    const v = str(m[k]); if (v) out[k] = v;
  }
  for (const k of ["script", "options", "consequences", "steps", "answerTokens", "distractors", "rubric", "instructions", "mustContain", "countLabels", "segments", "buckets"]) {
    const v = strs(m[k]); if (v) out[k] = v;
  }
  for (const k of ["correctIndex", "seconds", "turns", "reps", "bpm", "beatsPerBar", "durationSeconds"]) {
    const v = int(m[k]); if (v !== undefined) out[k] = v;
  }
  for (const k of ["minValue", "maxValue", "answerValue"]) {
    const v = num(m[k]); if (v !== undefined) out[k] = v;
  }
  const idx = ints(m.answerIndexes); if (idx) out.answerIndexes = idx;

  if (Array.isArray(m.cards)) {
    const cards = m.cards.map((c: J) => {
      const title = str(c?.title) ?? "", body = str(c?.body) ?? str(c?.text) ?? "";
      if (!title && !body) return null;
      const card: J = { title, body };
      const symbol = str(c?.symbol); if (symbol) card.symbol = symbol;
      const mood = str(c?.mood); if (mood && (MOODS as readonly string[]).includes(mood)) card.mood = mood;
      const hl = str(c?.highlight); if (hl) card.highlight = hl;
      return card;
    }).filter(Boolean);
    if (cards.length) out.cards = cards;
  }
  if (Array.isArray(m.flashcards)) {
    const fc = m.flashcards.map((f: J) => ({ front: str(f?.front), back: str(f?.back) })).filter((f: J) => f.front && f.back);
    if (fc.length) out.flashcards = fc;
  }
  if (Array.isArray(m.statements)) {
    const st = m.statements.map((s: J) => {
      const text = str(s?.text), isTrue = bool(s?.isTrue ?? s?.true ?? s?.answer);
      if (!text || isTrue === undefined) return null;
      const o: J = { text, isTrue }; const why = str(s?.why); if (why) o.why = why; return o;
    }).filter(Boolean);
    if (st.length) out.statements = st;
  }
  if (Array.isArray(m.pairs)) {
    const p = m.pairs.map((x: J) => ({ left: str(x?.left), right: str(x?.right) })).filter((x: J) => x.left && x.right);
    if (p.length) out.pairs = p;
  }
  if (Array.isArray(m.items)) {
    const it = m.items.map((x: J) => ({ text: str(x?.text), bucket: int(x?.bucket) }))
      .filter((x: J) => x.text && x.bucket !== undefined);
    if (it.length) out.items = it;
  }

  // Repairs
  if (type === "fillBlank" && out.sentence && !out.sentence.includes("___")) {
    out.sentence = out.sentence.replace(/_{2,}|\[blank\]|\(blank\)|\.\.\./i, "___");
  }
  if (type === "categorize" && out.items && out.buckets) {
    out.items = out.items.filter((x: J) => x.bucket >= 0 && x.bucket < out.buckets.length);
  }
  if ((type === "spotTheMistake" || type === "highlight") && out.answerIndexes && out.segments) {
    out.answerIndexes = [...new Set(out.answerIndexes as number[])].filter((i) => i >= 0 && i < out.segments.length);
  }
  if (type === "estimate" && out.minValue !== undefined && out.maxValue !== undefined && out.minValue > out.maxValue) {
    [out.minValue, out.maxValue] = [out.maxValue, out.minValue];
  }
  if (type === "estimate" && out.answerValue !== undefined && out.minValue !== undefined && out.maxValue !== undefined) {
    // Widen the slider range rather than silently changing the answer.
    const span = Math.max(out.maxValue - out.minValue, Math.abs(out.answerValue) * 0.5, 1);
    if (out.answerValue > out.maxValue) out.maxValue = out.answerValue + span * 0.25;
    if (out.answerValue < out.minValue) out.minValue = out.answerValue - span * 0.25;
  }
  if (type === "practiceTimer") {
    if (out.bpm !== undefined) out.bpm = Math.min(Math.max(out.bpm, 30), 260);
    if (!out.beatsPerBar && out.countLabels) out.beatsPerBar = out.countLabels.length;
  }
  if (type === "speedRound" && !out.seconds) out.seconds = 30;
  return out;
}

/** Exact mirror of `LessonModule.isValid` (Swift). */
export function isValidModule(m: J): boolean {
  const len = (a: unknown) => (Array.isArray(a) ? a.length : 0);
  const ci = typeof m.correctIndex === "number" ? m.correctIndex : -1;
  switch (m.type) {
    case "storyCards": return len(m.cards) > 0;
    case "audioLesson": return len(m.script) > 0;
    case "flashcards": return len(m.flashcards) > 0;
    case "multipleChoice":
    case "scenario": return len(m.options) >= 2 && ci >= 0 && ci < len(m.options) && !!m.prompt;
    case "fillBlank": return typeof m.sentence === "string" && m.sentence.includes("___") && len(m.options) >= 2 && ci >= 0 && ci < len(m.options);
    case "trueFalse":
    case "speedRound": return len(m.statements) > 0;
    case "matchPairs": return len(m.pairs) >= 2;
    case "reorder": return len(m.steps) >= 3;
    case "wordBricks": return len(m.answerTokens) >= 2;
    case "freeAnswer":
    case "teachBack": return !!m.prompt;
    case "roleplay":
    case "liveCall": return !!m.persona || !!m.opening;
    case "mission": return len(m.instructions) > 0;
    case "codeLab": return !!m.starterCode && len(m.mustContain) > 0;
    case "cameraCoach": return !!m.move;
    case "practiceTimer": return (m.bpm ?? 0) > 0;
    case "estimate": return m.minValue !== undefined && m.maxValue !== undefined && m.answerValue !== undefined;
    case "spotTheMistake":
    case "highlight": return len(m.segments) >= 2 && len(m.answerIndexes) > 0;
    case "categorize": return len(m.buckets) >= 2 && len(m.items) > 0;
    default: return false;
  }
}

const LEARN = new Set(["storyCards", "audioLesson", "flashcards"]);

export interface LessonReport { lesson: J; dropped: number; valid: number; }

/** Validates + repairs a lesson: drops invalid modules, caps length, fixes order, ensures a recap at the end. */
export function repairLesson(raw: J, nodeTitle: string): LessonReport {
  const input = Array.isArray(raw.modules) ? raw.modules : [];
  let modules = input.map(normaliseModule).filter((m: J | null): m is J => !!m && isValidModule(m));
  const dropped = input.length - modules.length;

  // Start with a teaching module if there is one.
  const firstLearn = modules.findIndex((m) => LEARN.has(m.type));
  if (firstLearn > 0) modules.unshift(...modules.splice(firstLearn, 1));

  // Break up runs of the same type (swap with the next different module).
  for (let i = 1; i < modules.length; i++) {
    if (modules[i].type === modules[i - 1].type) {
      const j = modules.findIndex((m, k) => k > i && m.type !== modules[i].type);
      if (j > 0) [modules[i], modules[j]] = [modules[j], modules[i]];
    }
  }

  // Cap at 10 (keep the last one — it is usually the recap).
  if (modules.length > 10) modules = [...modules.slice(0, 9), modules[modules.length - 1]];

  const takeaways = (strs(raw.takeaways) ?? []).slice(0, 3);

  // Ensure the lesson ends with a recap.
  const last = modules[modules.length - 1];
  const endsWithRecap = last && (last.type === "flashcards" || last.type === "speedRound");
  if (!endsWithRecap && modules.length >= 3 && modules.length < 10) {
    const recap = buildRecap(modules, takeaways);
    if (recap) modules.push(recap);
  }

  return {
    lesson: {
      title: str(raw.title) ?? nodeTitle,
      intro: str(raw.intro) ?? "Let's do this — one small step at a time.",
      modules,
      takeaways,
    },
    dropped,
    valid: modules.length,
  };
}

/** Builds a recap from what the lesson already contains (no model call needed). */
function buildRecap(modules: J[], takeaways: string[]): J | null {
  const statements: J[] = [];
  for (const m of modules) {
    if ((m.type === "trueFalse" || m.type === "speedRound") && Array.isArray(m.statements)) statements.push(...m.statements);
  }
  if (statements.length >= 3) {
    return { type: "speedRound", title: "Recap", prompt: "Quick-fire recap!", seconds: 30, statements: statements.slice(0, 6) };
  }
  const flashcards: J[] = [];
  for (const m of modules) {
    if (m.type === "matchPairs") for (const p of m.pairs) flashcards.push({ front: p.left, back: p.right });
    if (m.type === "multipleChoice" && m.prompt && m.options) flashcards.push({ front: m.prompt, back: m.options[m.correctIndex] });
  }
  if (flashcards.length >= 2) return { type: "flashcards", title: "Recap", flashcards: flashcards.slice(0, 5) };
  if (takeaways.length) {
    return { type: "storyCards", title: "Recap", cards: takeaways.map((t, i) => ({ title: `Key idea ${i + 1}`, body: t, symbol: "checkmark.seal.fill" })) };
  }
  return null;
}

// ─── Grade ─────────────────────────────────────────────────────────────────

export function repairGrade(raw: J): J {
  const score = Math.min(Math.max(num(raw.score) ?? 0, 0), 1);
  return {
    score,
    passed: bool(raw.passed) ?? score >= 0.6,
    feedback: str(raw.feedback) ?? (score >= 0.6 ? "Nice work — that covers the key idea." : "Good start. Add one concrete example to make it land."),
    improved: str(raw.improved) ?? null,
  };
}
