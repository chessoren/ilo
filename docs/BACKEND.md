# ilo backend — Supabase + OpenRouter

ilo works **fully offline** out of the box (flagship courses, on-device model, template composer, simulated leagues).
Adding the backend turns on: web-researched courses for any goal, cloud-written lessons, AI grading, live-call chat,
real weekly leagues and friends.

```
iOS app ──(anon JWT)──▶ Supabase Edge Function `ilo-ai` ──▶ OpenRouter (Claude / Gemini / GPT …)
   │                         ├─ verifies the JWT (auth.getUser)
   │                         ├─ per-user daily rate limits (table ai_usage)
   │                         ├─ shared caches (courses_shared, lessons_shared)
   │                         └─ validates + repairs every lesson (mirror of LessonModule.isValid)
   └──(PostgREST RPC)──▶ Postgres: profiles, league cohorts, weekly XP, friends (RLS)
```

The OpenRouter key lives **only** in the function's secrets — never in the app.

## 1. Create the project

1. Create a project at <https://supabase.com/dashboard> (free tier is fine).
2. **Enable anonymous sign-ins**: Dashboard → Authentication → Sign In / Providers → *Allow anonymous sign-ins* → Save.
   (ilo signs every learner in anonymously, so there's no account wall.)
3. Install the CLI: `brew install supabase/tap/supabase`.

## 2. Link, migrate, deploy

From the repo root:

```bash
supabase login
supabase link --project-ref <your-project-ref>          # the ref is in the dashboard URL
supabase db push                                         # applies supabase/migrations/0001_init.sql
supabase secrets set OPENROUTER_API_KEY=sk-or-v1-...     # https://openrouter.ai/keys
supabase functions deploy ilo-ai                         # verify_jwt=false in config.toml — the function verifies tokens itself
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected into edge functions automatically.

### Optional secrets

| Secret | Default | What it does |
|---|---|---|
| `MODEL_PLAN` | `anthropic/claude-opus-5.5` | Research + course design (runs with OpenRouter's `web` plugin) |
| `MODEL_LESSON` | `anthropic/claude-sonnet-5.5` | Lesson writing (structured JSON output) |
| `MODEL_GRADE` | `anthropic/claude-haiku-4.5` | Grading open answers |
| `MODEL_CHAT` | `anthropic/claude-haiku-4.5` | Roleplay / live-call turns |
| `PLAN_WEB_RESULTS` | `5` | Web results injected into the plan call |
| `LIMIT_PLAN_DAY` / `LIMIT_LESSON_DAY` / `LIMIT_GRADE_DAY` / `LIMIT_CHAT_DAY` | `6` / `120` / `250` / `400` | Requests per user per rolling 24 h |
| `REVENUECAT_SECRET_KEY` | — | If set, users with an active entitlement get `PRO_MULTIPLIER`× the limits (the app must call `Purchases.logIn(<supabase user id>)`) |
| `REVENUECAT_ENTITLEMENT` | `pro` | Entitlement id checked above |
| `PRO_MULTIPLIER` | `3` | Limit multiplier for Pro users |
| `OPENROUTER_REFERER` | GitHub URL | Sent as `HTTP-Referer` for OpenRouter attribution |

Any OpenRouter model slug works (`google/gemini-3.8-flash`, `openai/gpt-5.5`, …). Models that reject
`response_format: json_schema` automatically fall back to `json_object`, then plain JSON-in-text.

### Weekly league rollover (optional)

Promotion/demotion runs in SQL. Schedule it with pg_cron (Dashboard → Database → Extensions → enable `pg_cron`, then SQL editor):

```sql
select cron.schedule('ilo-roll-leagues', '5 0 * * 1', $$ select public.roll_leagues(); $$);
```

## 3. Point the app at it

Copy `ilo/Config.example.plist` to `ilo/Config.plist` (git-ignored) and fill in:

| Key | Where to find it |
|---|---|
| `SUPABASE_URL` | Dashboard → Project Settings → API → Project URL (`https://<ref>.supabase.co`) |
| `SUPABASE_ANON_KEY` | Same page → `anon` public key (or the new `sb_publishable_…` key) |
| `REVENUECAT_API_KEY` | RevenueCat → Project → API keys → public SDK key |
| `REVENUECAT_ENTITLEMENT` | Your entitlement identifier (default `pro`) |

That's it — `AppConfig.hasBackend` becomes true and `AIRouter` switches to `FallbackAI(primary: RemoteAI(), fallback: LocalAI())`:
if the network, quota or model fails, the offline brain answers instead, so the app never dead-ends.

## 4. Test it

```bash
# 1. anonymous session
curl -s -X POST "$SUPABASE_URL/auth/v1/signup" -H "apikey: $ANON" -H "Content-Type: application/json" -d '{}' | jq -r .access_token > /tmp/jwt

# 2. plan with live progress (SSE)
curl -N -X POST "$SUPABASE_URL/functions/v1/ilo-ai" \
  -H "Authorization: Bearer $(cat /tmp/jwt)" -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d '{"action":"plan","stream":true,"request":{"goal":"Learn to play chess","level":0,"dailyMinutes":10,"styles":[]}}'

# 3. one lesson
curl -s -X POST "$SUPABASE_URL/functions/v1/ilo-ai" \
  -H "Authorization: Bearer $(cat /tmp/jwt)" -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d '{"action":"lesson","course":{"goal":"chess","title":"Chess from zero","category":"skill","level":0},
       "node":{"title":"How pieces move","brief":"Rook, bishop, queen, knight, king, pawn: how each moves, with one example each.","kind":"lesson"},
       "context":{"level":0,"previousTitles":[],"recentMistakes":[],"preferredStyles":[]}}' | jq '.modules | map(.type)'
```

Logs: `supabase functions logs ilo-ai` (or Dashboard → Edge Functions → ilo-ai → Logs).

## API contract (what the app sends / receives)

| Action | Request | Response |
|---|---|---|
| `plan` | `{action, stream, request: {goal, motivation?, level 0-3, dailyMinutes, deadline? (ISO-8601), styles[]}}` | SSE: `event: step` `{phase, text, detail?}` … `event: course` `{title, tagline, symbol, tint, category, units[{title, outcome, tint, nodes[{title, brief, kind, symbol}]}], sources[{title,url}]}` (or `event: error`). Without `stream`: `{course, steps}` |
| `lesson` | `{action, course: {goal, title, category, level, motivation?}, unit?: {title, outcome}, node: {title, brief, kind}, context: LessonContext}` | `{title, intro, modules: [flat LessonModule], takeaways[]}` |
| `grade` | `{action, question, answer, rubric[], sample?}` | `{score 0-1, passed, feedback, improved}` |
| `chat` | `{action, persona, goal, topic, history: [{role: "user"|"ilo", text}]}` | `{reply}` |

Every module type's required fields are documented in `supabase/functions/ilo-ai/prompts.ts` (`MODULE_CATALOG`) and
enforced by `validate.ts`, which mirrors `LessonModule.isValid` in `ilo/Models/Lesson.swift`.

## Database (0001_init.sql)

- `profiles` — one row per learner (anonymous auth user): name, bloub shape/colour, league tier, total XP, streak, 6-letter `friend_code`.
- `league_cohorts` + `weekly_xp` — each week learners are placed in a cohort of ≤ 30 for their tier; `leaderboard()` returns it ranked.
- `friendships` + `add_friend(code)` + `friends_board()`.
- `add_xp(p_xp, p_streak)` — clamps each call to 200 XP, updates weekly + total XP.
- `upsert_profile(...)` — creates/updates the caller's profile, returns it (incl. friend code).
- `roll_leagues()` — weekly promotion/demotion (service role only).
- `courses_shared` / `lessons_shared` — cache of generated courses/lessons for non-personalised goals (service role only).
- `ai_usage` — per-user request log for rate limiting and cost tracking (service role only).

All tables have RLS on. Clients can read public profile/league data and write only through the RPCs.
