-- Cup Season — the pilot keeps its own record (pilot readiness, 2026-09-15).
--
-- WRITTEN AND VALIDATED IN ISOLATION. NOT PUSHED. Nothing here changes a
-- score, a point, a post, or any client-visible behaviour; every client works
-- exactly the same whether or not this is applied.
--
-- Three small things the pilot scorecard cannot honestly do without:
--
--   1 · WHO IS IN WHICH COHORT (`pilot_cohort_members`). A funnel needs a
--       denominator, and "everyone who ever signed up" is not one. The founder
--       names the cohort a golfer belongs to (owner · friends · independent ·
--       competition · founding) and when they entered it. Founder-managed,
--       founder-readable, nobody else. Absent this table the scorecard reports
--       all golfers as one cohort and says so.
--
--   2 · WHEN THE FOUNDER WAS IN THE ROOM (`pilot_sessions`). Telemetry cannot
--       tell an unassisted round from one the founder talked a group through.
--       A session row says: this group, this window, assisted or observed,
--       what was seen. The scorecard subtracts assisted activity rather than
--       pretending. Founder-managed, founder-readable.
--
--   3 · A RETRY IS ONE EVENT (`client_events` attempt key). The phone already
--       de-duplicates in memory; the desk did not, and a reconnect could count
--       one tee-off attempt three times. A partial unique index on the
--       attempt id the client stamps makes the SERVER refuse the duplicate —
--       the insert fails quietly and the client never notices, which is the
--       point: analytics must never block gameplay.
--
-- The founder is `founder_id()` (already deployed, anon-callable, one boolean
-- fact). Policies below use it directly so there is no new role concept.

-- ── 1 · cohorts ──────────────────────────────────────────────────────────
create table if not exists public.pilot_cohort_members (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  cohort     text not null check (cohort in ('owner','friends','independent','competition','founding')),
  group_key  text,                          -- the league, plan or free-text group this golfer came in with
  added_at   timestamptz not null default now(),
  added_by   uuid references public.profiles(id),
  note       text,
  primary key (profile_id, cohort)
);
alter table public.pilot_cohort_members enable row level security;
revoke all on table public.pilot_cohort_members from public, anon;
grant select, insert, update, delete on table public.pilot_cohort_members to authenticated;
drop policy if exists pcm_founder_all on public.pilot_cohort_members;
create policy pcm_founder_all on public.pilot_cohort_members
  for all to authenticated
  using (auth.uid() = public.founder_id())
  with check (auth.uid() = public.founder_id());

-- ── 2 · sessions ─────────────────────────────────────────────────────────
create table if not exists public.pilot_sessions (
  id          uuid primary key default gen_random_uuid(),
  cohort      text not null check (cohort in ('owner','friends','independent','competition','founding')),
  group_key   text not null,                -- league id, plan id, or a free-text group name
  kind        text not null check (kind in ('assisted','observed','support')),
  started_at  timestamptz not null default now(),
  ended_at    timestamptz,
  golfers     uuid[] not null default '{}', -- who was in the room / on the call
  notes       text,
  created_by  uuid not null default auth.uid() references public.profiles(id)
);
alter table public.pilot_sessions enable row level security;
revoke all on table public.pilot_sessions from public, anon;
grant select, insert, update, delete on table public.pilot_sessions to authenticated;
drop policy if exists ps_founder_all on public.pilot_sessions;
create policy ps_founder_all on public.pilot_sessions
  for all to authenticated
  using (auth.uid() = public.founder_id())
  with check (auth.uid() = public.founder_id());

-- ── 3 · a retry is one event ─────────────────────────────────────────────
-- The client stamps `props.attempt_id` on any event it may re-send. Two rows
-- with the same owner, event and attempt id are one attempt; the second insert
-- fails on this index and the client, which fires and forgets, never knows.
create unique index if not exists client_events_one_attempt
  on public.client_events (profile_id, event, ((props->>'attempt_id')))
  where props ? 'attempt_id';

-- ── self-check ───────────────────────────────────────────────────────────
do $chk$
begin
  if not exists (select 1 from pg_policies where tablename='pilot_cohort_members' and policyname='pcm_founder_all') then raise exception 'check: cohort policy missing'; end if;
  if not exists (select 1 from pg_policies where tablename='pilot_sessions' and policyname='ps_founder_all') then raise exception 'check: session policy missing'; end if;
  if not exists (select 1 from pg_indexes where indexname='client_events_one_attempt') then raise exception 'check: attempt index missing'; end if;
  if (select relrowsecurity from pg_class where relname='pilot_sessions') is not true then raise exception 'check: pilot_sessions RLS off'; end if;
end
$chk$;
