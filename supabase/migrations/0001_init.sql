-- ilo — initial schema
-- Profiles, weekly leagues (cohorts of ~30 learners per tier), friends, shared course/lesson cache, AI usage (rate limits).
-- Everything the client touches is protected by RLS; the edge function uses the service role for caches + usage.

create extension if not exists pgcrypto;

-- ─────────────────────────────────────────────────────────────────────────────
-- Profiles
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  name         text not null default '',
  bloub_shape  text not null default 'circle',
  bloub_color  text not null default 'blue',
  league       int  not null default 0 check (league between 0 and 7),   -- LeagueTier.rawValue (pebble … apex)
  total_xp     int  not null default 0 check (total_xp >= 0),
  streak       int  not null default 0 check (streak >= 0),
  friend_code  text not null unique default upper(substr(md5(gen_random_uuid()::text), 1, 6)),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Everyone signed in can read public profile fields (needed for leaderboards).
drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles insert own" on public.profiles;
create policy "profiles insert own" on public.profiles
  for insert to authenticated with check (id = auth.uid());

drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- Leagues: one cohort per (tier, week), max 30 learners
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.league_cohorts (
  id          uuid primary key default gen_random_uuid(),
  tier        int  not null check (tier between 0 and 7),
  week_start  date not null,
  size        int  not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists league_cohorts_open_idx on public.league_cohorts (tier, week_start, size);

create table if not exists public.weekly_xp (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  week_start  date not null,
  xp          int  not null default 0 check (xp >= 0),
  cohort_id   uuid references public.league_cohorts (id) on delete set null,
  updated_at  timestamptz not null default now(),
  primary key (user_id, week_start)
);
create index if not exists weekly_xp_cohort_idx on public.weekly_xp (cohort_id, xp desc);

alter table public.league_cohorts enable row level security;
alter table public.weekly_xp enable row level security;

drop policy if exists "cohorts readable" on public.league_cohorts;
create policy "cohorts readable" on public.league_cohorts for select to authenticated using (true);

drop policy if exists "weekly xp readable" on public.weekly_xp;
create policy "weekly xp readable" on public.weekly_xp for select to authenticated using (true);
-- No insert/update policies: writes only go through the security-definer RPCs below.

-- ─────────────────────────────────────────────────────────────────────────────
-- Friends
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.friendships (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  friend_id  uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);
alter table public.friendships enable row level security;
drop policy if exists "friendships own" on public.friendships;
create policy "friendships own" on public.friendships for select to authenticated using (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared AI caches (service role only — no policies = no client access)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.courses_shared (
  goal_hash   text primary key,           -- sha256(normalised goal | level)
  goal        text not null,
  course      jsonb not null,             -- exact Course JSON returned to the app (units/nodes/briefs)
  sources     jsonb not null default '[]',
  model       text,
  hits        int  not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.lessons_shared (
  lesson_key  text primary key,           -- sha256(goal_hash | node title | brief | level)
  lesson      jsonb not null,
  model       text,
  hits        int not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.ai_usage (
  id          bigint generated always as identity primary key,
  user_id     uuid not null,
  action      text not null,
  model       text,
  tokens_in   int,
  tokens_out  int,
  created_at  timestamptz not null default now()
);
create index if not exists ai_usage_user_time_idx on public.ai_usage (user_id, action, created_at desc);

alter table public.courses_shared enable row level security;
alter table public.lessons_shared enable row level security;
alter table public.ai_usage enable row level security;

-- ─────────────────────────────────────────────────────────────────────────────
-- RPCs
-- ─────────────────────────────────────────────────────────────────────────────

-- Current league week (Monday, UTC) — matches the app's Calendar.startOfWeek (firstWeekday = Monday).
create or replace function public.current_week() returns date
language sql stable as $$ select date_trunc('week', now())::date $$;

-- Creates/updates the caller's profile. Returns it (incl. friend_code).
create or replace function public.upsert_profile(
  p_name text, p_shape text, p_color text, p_league int default null, p_total_xp int default null, p_streak int default null
) returns public.profiles
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  row public.profiles;
begin
  if me is null then raise exception 'not authenticated'; end if;
  insert into public.profiles (id, name, bloub_shape, bloub_color, league, total_xp, streak)
  values (me, left(coalesce(p_name, ''), 40), coalesce(p_shape, 'circle'), coalesce(p_color, 'blue'),
          least(greatest(coalesce(p_league, 0), 0), 7), greatest(coalesce(p_total_xp, 0), 0), greatest(coalesce(p_streak, 0), 0))
  on conflict (id) do update set
    name        = left(coalesce(excluded.name, profiles.name), 40),
    bloub_shape = excluded.bloub_shape,
    bloub_color = excluded.bloub_color,
    league      = coalesce(p_league, profiles.league),
    total_xp    = greatest(profiles.total_xp, coalesce(p_total_xp, profiles.total_xp)),
    streak      = coalesce(p_streak, profiles.streak),
    updated_at  = now()
  returning * into row;
  return row;
end $$;

-- Puts the caller into an open cohort for their tier this week (creates one if needed). Returns cohort id.
create or replace function public.ensure_cohort() returns uuid
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  wk date := public.current_week();
  v_tier int;
  cid uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  select cohort_id into cid from public.weekly_xp where user_id = me and week_start = wk;
  if cid is not null then return cid; end if;

  select league into v_tier from public.profiles where id = me;
  if v_tier is null then
    insert into public.profiles (id) values (me) on conflict do nothing;
    v_tier := 0;
  end if;

  select id into cid from public.league_cohorts
   where league_cohorts.tier = v_tier and week_start = wk and size < 30
   order by size desc limit 1
   for update skip locked;
  if cid is null then
    insert into public.league_cohorts (tier, week_start, size) values (v_tier, wk, 0) returning id into cid;
  end if;
  update public.league_cohorts set size = size + 1 where id = cid;

  insert into public.weekly_xp (user_id, week_start, xp, cohort_id) values (me, wk, 0, cid)
  on conflict (user_id, week_start) do update set cohort_id = coalesce(weekly_xp.cohort_id, excluded.cohort_id);
  return cid;
end $$;

-- Adds XP for the caller (clamped per call to stop abuse). Returns new weekly XP.
create or replace function public.add_xp(p_xp int, p_streak int default null) returns int
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  wk date := public.current_week();
  delta int := least(greatest(coalesce(p_xp, 0), 0), 200);
  total int;
begin
  if me is null then raise exception 'not authenticated'; end if;
  perform public.ensure_cohort();
  update public.weekly_xp set xp = xp + delta, updated_at = now()
   where user_id = me and week_start = wk
   returning xp into total;
  update public.profiles set total_xp = total_xp + delta, streak = coalesce(p_streak, streak), updated_at = now()
   where id = me;
  return total;
end $$;

-- The caller's league cohort for this week, ranked.
create or replace function public.leaderboard()
returns table (user_id uuid, name text, bloub_shape text, bloub_color text, xp int, streak int, is_me boolean, tier int)
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  cid uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  cid := public.ensure_cohort();
  return query
    select p.id, p.name, p.bloub_shape, p.bloub_color, w.xp, p.streak, p.id = me, c.tier
      from public.weekly_xp w
      join public.profiles p on p.id = w.user_id
      join public.league_cohorts c on c.id = w.cohort_id
     where w.cohort_id = cid
     order by w.xp desc, p.name asc;
end $$;

-- Friends (and me), ranked by this week's XP.
create or replace function public.friends_board()
returns table (user_id uuid, name text, bloub_shape text, bloub_color text, xp int, streak int, is_me boolean)
language sql security definer set search_path = public as $$
  select p.id, p.name, p.bloub_shape, p.bloub_color, coalesce(w.xp, 0), p.streak, p.id = auth.uid()
    from public.profiles p
    left join public.weekly_xp w on w.user_id = p.id and w.week_start = public.current_week()
   where p.id = auth.uid()
      or p.id in (select friend_id from public.friendships where user_id = auth.uid())
   order by coalesce(w.xp, 0) desc;
$$;

-- Adds a friend by their 6-letter code (mutual). Returns the friend's name.
create or replace function public.add_friend(p_code text) returns text
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  other public.profiles;
begin
  if me is null then raise exception 'not authenticated'; end if;
  select * into other from public.profiles where friend_code = upper(trim(p_code));
  if other.id is null or other.id = me then raise exception 'unknown code'; end if;
  insert into public.friendships (user_id, friend_id) values (me, other.id), (other.id, me) on conflict do nothing;
  return other.name;
end $$;

-- Weekly promotion/demotion (run from pg_cron every Monday 00:05 UTC, see docs/BACKEND.md).
create or replace function public.roll_leagues() returns void
language plpgsql security definer set search_path = public as $$
declare
  last_week date := public.current_week() - 7;
begin
  with ranked as (
    select w.user_id, c.tier,
           row_number() over (partition by w.cohort_id order by w.xp desc) as rnk,
           count(*)    over (partition by w.cohort_id) as n,
           w.xp
      from public.weekly_xp w join public.league_cohorts c on c.id = w.cohort_id
     where w.week_start = last_week
  )
  update public.profiles p set league =
    case
      when r.tier < 7 and r.rnk <= greatest(1, r.n / 5) and r.xp > 0 then r.tier + 1
      when r.tier > 0 and r.rnk > r.n - greatest(1, r.n / 6) and r.xp < 50 then r.tier - 1
      else r.tier
    end
  from ranked r where r.user_id = p.id;
end $$;

revoke all on function public.roll_leagues() from public, anon, authenticated;
grant execute on function public.upsert_profile(text, text, text, int, int, int) to authenticated;
grant execute on function public.ensure_cohort() to authenticated;
grant execute on function public.add_xp(int, int) to authenticated;
grant execute on function public.leaderboard() to authenticated;
grant execute on function public.friends_board() to authenticated;
grant execute on function public.add_friend(text) to authenticated;
