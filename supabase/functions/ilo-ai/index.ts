// ilo-ai — the brain behind ilo. One edge function, four actions:
//   plan   → research the goal on the web + design the course path (units / nodes / briefs). SSE progress when `stream: true`.
//   lesson → write one lesson (flat LessonModule list) from a node brief. Validated + repaired server-side.
//   grade  → grade an open answer against a rubric.
//   chat   → one in-character turn for roleplay / live call.
// Models are routed through OpenRouter; the key lives only in this function's secrets.

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { complete, OpenRouterError } from "./openrouter.ts";
import {
  chatSystem, COURSE_SCHEMA, GRADE_SCHEMA, GRADE_SYSTEM, LESSON_SCHEMA, LESSON_SYSTEM, lessonUser, PLAN_SYSTEM, planUser,
} from "./prompts.ts";
import { parseJSON, repairCourse, repairGrade, repairLesson } from "./validate.ts";

// ─── Config ────────────────────────────────────────────────────────────────

const env = (k: string, fallback: string) => Deno.env.get(k) || fallback;
const MODELS = {
  plan: env("MODEL_PLAN", "anthropic/claude-opus-5.5"),
  lesson: env("MODEL_LESSON", "anthropic/claude-sonnet-5.5"),
  grade: env("MODEL_GRADE", "anthropic/claude-haiku-4.5"),
  chat: env("MODEL_CHAT", "anthropic/claude-haiku-4.5"),
};
const WEB_RESULTS = Number(env("PLAN_WEB_RESULTS", "5"));
/** Requests per user per rolling 24h. Pro subscribers (RevenueCat) get PRO_MULTIPLIER×. */
const DAILY_LIMITS: Record<string, number> = {
  plan: Number(env("LIMIT_PLAN_DAY", "6")),
  lesson: Number(env("LIMIT_LESSON_DAY", "120")),
  grade: Number(env("LIMIT_GRADE_DAY", "250")),
  chat: Number(env("LIMIT_CHAT_DAY", "400")),
};
const PRO_MULTIPLIER = Number(env("PRO_MULTIPLIER", "3"));

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, accept",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type J = Record<string, any>;

class HttpError extends Error {
  constructor(public status: number, message: string) { super(message); }
}

// ─── Entry point ───────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  try {
    const { userId, admin } = await authenticate(req);
    const body = await req.json().catch(() => { throw new HttpError(400, "invalid JSON body"); }) as J;
    const action = String(body.action ?? "");
    if (!(action in MODELS)) throw new HttpError(400, `unknown action "${action}"`);

    await enforceRateLimit(admin, userId, action);

    switch (action) {
      case "plan":
        if (body.stream) return sse((emit) => plan(body, admin, userId, emit));
        {
          const steps: J[] = [];
          const course = await plan(body, admin, userId, (event, data) => { if (event === "step") steps.push(data); });
          return json({ course, steps });
        }
      case "lesson": return json(await lesson(body, admin, userId));
      case "grade": return json(await grade(body, admin, userId));
      case "chat": return json(await chat(body, admin, userId));
    }
    throw new HttpError(400, "unreachable");
  } catch (e) {
    const status = e instanceof HttpError ? e.status : e instanceof OpenRouterError ? 502 : 500;
    console.error("[ilo-ai]", status, e instanceof Error ? e.message : e);
    return json({ error: e instanceof Error ? e.message : String(e) }, status);
  }
});

// ─── Auth + rate limits ────────────────────────────────────────────────────

async function authenticate(req: Request): Promise<{ userId: string; admin: SupabaseClient }> {
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) throw new HttpError(401, "missing bearer token");
  const url = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  // Verifies the JWT signature + expiry with GoTrue (works for anonymous and permanent users).
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user) throw new HttpError(401, "invalid or expired session");
  return { userId: data.user.id, admin };
}

async function enforceRateLimit(admin: SupabaseClient, userId: string, action: string) {
  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { count, error } = await admin.from("ai_usage").select("id", { count: "exact", head: true })
    .eq("user_id", userId).eq("action", action).gte("created_at", since);
  if (error) { console.warn("[rate-limit] skipped:", error.message); return; }
  let limit = DAILY_LIMITS[action] ?? 100;
  if ((count ?? 0) >= limit && await isPro(userId)) limit *= PRO_MULTIPLIER;
  if ((count ?? 0) >= limit) throw new HttpError(429, `Daily limit reached for ${action}. Try again tomorrow.`);
}

/** Optional: checks the RevenueCat entitlement (app must call Purchases.logIn(<supabase user id>)). */
async function isPro(userId: string): Promise<boolean> {
  const secret = Deno.env.get("REVENUECAT_SECRET_KEY");
  if (!secret) return false;
  try {
    const res = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`, {
      headers: { Authorization: `Bearer ${secret}` },
    });
    if (!res.ok) return false;
    const data = await res.json();
    const ent = data?.subscriber?.entitlements?.[env("REVENUECAT_ENTITLEMENT", "pro")];
    return !!ent && (!ent.expires_date || new Date(ent.expires_date) > new Date());
  } catch {
    return false;
  }
}

async function recordUsage(admin: SupabaseClient, userId: string, action: string, model: string, tokensIn?: number, tokensOut?: number) {
  const { error } = await admin.from("ai_usage").insert({ user_id: userId, action, model, tokens_in: tokensIn ?? null, tokens_out: tokensOut ?? null });
  if (error) console.warn("[usage]", error.message);
}

// ─── plan ──────────────────────────────────────────────────────────────────

type Emit = (event: "step" | "course" | "error", data: J) => void;

async function plan(body: J, admin: SupabaseClient, userId: string, emit: Emit): Promise<J> {
  const request = (body.request ?? {}) as J;
  const goal = String(request.goal ?? "").trim();
  if (goal.length < 2) throw new HttpError(400, "goal is required");
  const step = (phase: string, text: string, detail?: string) => emit("step", { phase, text, detail });

  step("understanding", "Understanding your goal", `“${goal.slice(0, 80)}”`);
  if (request.motivation) step("understanding", "Noting why it matters to you", String(request.motivation).slice(0, 80));

  // 1. Shared cache — popular goals are designed once, then reused (the biggest cost lever).
  const goalHash = await sha256(`${normalise(goal)}|${request.level ?? 1}`);
  const personal = !!request.motivation || !!request.deadline;
  if (!personal) {
    const { data: cached } = await admin.from("courses_shared").select("course, sources, hits").eq("goal_hash", goalHash).maybeSingle();
    if (cached?.course) {
      step("researching", "Found a proven path for this goal", `${(cached.sources ?? []).length} sources`);
      step("designing", "Personalising it for you");
      await admin.from("courses_shared").update({ hits: (cached.hits ?? 0) + 1 }).eq("goal_hash", goalHash);
      const course = { ...cached.course, sources: cached.sources ?? cached.course.sources ?? [] };
      step("done", "Your path is ready");
      emit("course", course);
      return course;
    }
  }

  // 2. Research + design in one streamed call (web plugin + structured output).
  step("researching", "Searching the web", `How experts teach ${goal.slice(0, 60)}`);
  const heartbeat = [
    ["researching", "Reading expert guides"],
    ["researching", "Collecting common beginner mistakes"],
    ["researching", "Comparing teaching approaches"],
    ["designing", "Mapping the skill tree"],
    ["designing", "Choosing the best order"],
  ];
  let beat = 0, streaming = false;
  const timer = setInterval(() => {
    if (streaming || beat >= heartbeat.length) return;
    const [phase, text] = heartbeat[beat++];
    step(phase, text);
  }, 6000);

  const seenUnits = new Set<string>();
  let briefs = 0;
  let result;
  try {
    result = await complete({
      model: MODELS.plan,
      messages: [{ role: "system", content: PLAN_SYSTEM }, { role: "user", content: planUser(request) }],
      schema: { name: "course", schema: COURSE_SCHEMA, strict: true },
      webSearch: { maxResults: WEB_RESULTS },
      temperature: 0.6,
      maxTokens: 12000,
      reasoningEffort: "low",
      timeoutMs: 170_000,
      onDelta: (text) => {
        streaming = true;
        for (const m of text.matchAll(/"title"\s*:\s*"([^"]{1,80})"\s*,\s*"outcome"/g)) {
          if (!seenUnits.has(m[1])) { seenUnits.add(m[1]); step("designing", `Unit ${seenUnits.size}: ${m[1]}`); }
        }
        const count = (text.match(/"brief"\s*:/g) ?? []).length;
        if (count >= briefs + 6) { briefs = count - (count % 6); step("writing", `Writing lesson briefs`, `${briefs} so far`); }
      },
    });
  } finally {
    clearInterval(timer);
  }

  const course = repairCourse(parseJSON(result.text));
  // Merge citations the web plugin returned with the sources the model listed.
  const byUrl = new Map<string, J>();
  for (const s of [...result.citations, ...course.sources]) if (!byUrl.has(s.url)) byUrl.set(s.url, s);
  course.sources = [...byUrl.values()].slice(0, 6);
  for (const s of course.sources.slice(0, 4)) step("researching", `Read ${s.title}`.slice(0, 70), hostname(s.url));

  const nodeCount = course.units.reduce((n: number, u: J) => n + u.nodes.length, 0);
  step("writing", `Designed ${course.units.length} units · ${nodeCount} steps`);
  step("done", "Your path is ready");

  await recordUsage(admin, userId, "plan", result.model, result.tokensIn, result.tokensOut);
  if (!personal) {
    await admin.from("courses_shared").upsert({ goal_hash: goalHash, goal, course, sources: course.sources, model: result.model });
  }
  emit("course", course);
  return course;
}

// ─── lesson ────────────────────────────────────────────────────────────────

async function lesson(body: J, admin: SupabaseClient, userId: string): Promise<J> {
  const node = body.node ?? {};
  if (!node.title && !node.brief) throw new HttpError(400, "node.title or node.brief is required");
  const personalised = (body.context?.recentMistakes ?? []).length > 0 || !!body.course?.motivation;
  const key = await sha256([normalise(String(body.course?.goal ?? "")), node.title, node.brief, node.kind, body.course?.level].join("|"));

  if (!personalised) {
    const { data: cached } = await admin.from("lessons_shared").select("lesson, hits").eq("lesson_key", key).maybeSingle();
    if (cached?.lesson) {
      await admin.from("lessons_shared").update({ hits: (cached.hits ?? 0) + 1 }).eq("lesson_key", key);
      return cached.lesson;
    }
  }

  const messages = [
    { role: "system" as const, content: LESSON_SYSTEM },
    { role: "user" as const, content: lessonUser(body) },
  ];
  const first = await complete({ model: MODELS.lesson, messages, schema: { name: "lesson", schema: LESSON_SCHEMA }, temperature: 0.7, maxTokens: 9000, reasoningEffort: "low", timeoutMs: 120_000 });
  let best = repairLesson(parseJSON(first.text), String(node.title ?? "Lesson"));
  await recordUsage(admin, userId, "lesson", first.model, first.tokensIn, first.tokensOut);

  // One repair attempt if too many modules were unusable.
  if (best.valid < 6) {
    const retry = await complete({
      model: MODELS.lesson,
      messages: [
        ...messages,
        { role: "assistant", content: first.text.slice(0, 20000) },
        { role: "user", content: `Only ${best.valid} of your modules were valid (${best.dropped} were missing required fields). Rewrite the whole lesson with 7–9 modules, checking every REQUIRED field in the catalog. JSON only.` },
      ],
      schema: { name: "lesson", schema: LESSON_SCHEMA },
      temperature: 0.5, maxTokens: 9000, reasoningEffort: "low", timeoutMs: 120_000,
    }).catch(() => null);
    if (retry) {
      try {
        const second = repairLesson(parseJSON(retry.text), String(node.title ?? "Lesson"));
        if (second.valid > best.valid) best = second;
      } catch { /* keep first */ }
    }
  }
  if (best.valid === 0) throw new HttpError(502, "the model produced no playable modules");
  if (!personalised && best.valid >= 6) {
    await admin.from("lessons_shared").upsert({ lesson_key: key, lesson: best.lesson, model: first.model });
  }
  return best.lesson;
}

// ─── grade ─────────────────────────────────────────────────────────────────

async function grade(body: J, admin: SupabaseClient, userId: string): Promise<J> {
  const answer = String(body.answer ?? "").slice(0, 4000);
  if (!answer.trim()) return { score: 0, passed: false, feedback: "Give it a go — even one sentence helps ilo help you.", improved: body.sample ?? null };
  const user = [
    `Question: ${String(body.question ?? "").slice(0, 1000)}`,
    `Rubric: ${(Array.isArray(body.rubric) ? body.rubric : []).map((r: string, i: number) => `${i + 1}. ${r}`).join("  ") || "Accurate, specific, in their own words."}`,
    body.sample ? `Reference answer: ${String(body.sample).slice(0, 1000)}` : "",
    `Learner's answer: ${answer}`,
  ].filter(Boolean).join("\n");
  const res = await complete({
    model: MODELS.grade,
    messages: [{ role: "system", content: GRADE_SYSTEM }, { role: "user", content: user }],
    schema: { name: "grade", schema: GRADE_SCHEMA, strict: true },
    temperature: 0.2, maxTokens: 600, timeoutMs: 45_000,
  });
  await recordUsage(admin, userId, "grade", res.model, res.tokensIn, res.tokensOut);
  return repairGrade(parseJSON(res.text));
}

// ─── chat ──────────────────────────────────────────────────────────────────

async function chat(body: J, admin: SupabaseClient, userId: string): Promise<J> {
  const history = (Array.isArray(body.history) ? body.history : []).slice(-16)
    .map((m: J) => ({ role: m.role === "user" ? "user" as const : "assistant" as const, content: String(m.text ?? "").slice(0, 1500) }))
    .filter((m: J) => m.content.trim());
  // Providers want the first turn to be the user's and the last one too.
  if (!history.length || history[0].role !== "user") history.unshift({ role: "user", content: "(The conversation begins.)" });
  if (history[history.length - 1].role !== "user") history.push({ role: "user", content: "(The learner is listening — continue.)" });

  const res = await complete({
    model: MODELS.chat,
    messages: [{ role: "system", content: chatSystem(String(body.persona ?? ""), String(body.goal ?? ""), String(body.topic ?? "")) }, ...history],
    temperature: 0.8, maxTokens: 300, timeoutMs: 30_000,
  });
  await recordUsage(admin, userId, "chat", res.model, res.tokensIn, res.tokensOut);
  const reply = res.text.trim().replace(/^["“]|["”]$/g, "");
  if (!reply) throw new HttpError(502, "empty reply");
  return { reply };
}

// ─── Helpers ───────────────────────────────────────────────────────────────

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: { ...CORS, "Content-Type": "application/json" } });
}

/** Server-sent events: `event: step|course|error` with a JSON `data` line. */
function sse(run: (emit: Emit) => Promise<unknown>): Response {
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      let open = true;
      const emit: Emit = (event, data) => {
        if (!open) return;
        try { controller.enqueue(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`)); } catch { open = false; }
      };
      const keepAlive = setInterval(() => { if (open) try { controller.enqueue(encoder.encode(": keep-alive\n\n")); } catch { open = false; } }, 10_000);
      try {
        await run(emit);
      } catch (e) {
        const status = e instanceof HttpError ? e.status : 502;
        emit("error", { status, error: e instanceof Error ? e.message : String(e) });
      } finally {
        clearInterval(keepAlive);
        open = false;
        controller.close();
      }
    },
  });
  return new Response(stream, {
    headers: { ...CORS, "Content-Type": "text/event-stream; charset=utf-8", "Cache-Control": "no-cache", "Connection": "keep-alive" },
  });
}

function normalise(s: string): string {
  return s.toLowerCase().normalize("NFKD").replace(/[^\p{L}\p{N}\s]/gu, " ").replace(/\s+/g, " ").trim();
}

async function sha256(s: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function hostname(url: string): string {
  try { return new URL(url).hostname.replace(/^www\./, ""); } catch { return url; }
}
