-- Pilot instrumentation (D33): passive QA tracking while PIGL actually plays.
-- The pre-launch QA gates (spec/prelaunch-qa-2026-07-13.md) were written for a
-- stopwatch walkthrough; the pilot converts them into funnels measured from
-- data. Two pieces:
--
--   1. client_events — a skinny breadcrumb table the client fires into:
--      post_open / post_submit / post_mode_switch / post_even_par_confirmed.
--      Insert-only for the golfer, unreadable through the API. Gate 3 (the
--      60-second post) and the D32 mode-mix question live here.
--   2. v_pilot_gates + v_post_timings — the gates computed per member from
--      rows that already exist (gate 1: signup → golfer card; gate 2: card →
--      first league; plus days-to-first-round). Operator-only: both views are
--      REVOKED from the API roles because v_pilot_gates joins auth.users.
--      Query them from the SQL editor (service role).
--
-- Gates 4 and 5 (standings comprehension, zero-tutorial) stay HUMAN — no
-- event log can see understanding. Ride-alongs + pilot_feedback cover those.

create table if not exists public.client_events (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null default auth.uid()
             references public.profiles(id) on delete cascade,
  event      text not null check (char_length(event) <= 64),
  props      jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists client_events_event_idx
  on public.client_events (event, created_at);

alter table public.client_events enable row level security;

-- The golfer writes their own breadcrumbs; nobody reads them via the API.
-- (QA queries run in the SQL editor, which bypasses RLS.)
create policy ce_insert_own on public.client_events
  for insert to authenticated
  with check (profile_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Gate funnel per member. Gate 1's clock starts at auth signup and stops when
-- the golfer card is saved (handle_set_at — the card save stamps the handle,
-- so a NULL here means they stalled ON the card, which is itself the finding).
-- otp_seconds isolates the Brevo/entry lag inside gate 1.
-- ---------------------------------------------------------------------------
create or replace view public.v_pilot_gates as
select
  p.id                                    as profile_id,
  p.display_name,
  u.created_at                            as signed_up_at,
  round(extract(epoch from (u.email_confirmed_at - u.confirmation_sent_at)))::int
                                          as otp_seconds,
  p.handle_set_at                         as card_saved_at,
  round(extract(epoch from (p.handle_set_at - u.created_at)))::int
                                          as gate1_seconds,          -- target < 120
  lm.first_joined_at,
  round(extract(epoch from (lm.first_joined_at - p.handle_set_at)))::int
                                          as gate2_seconds,          -- target < 30
  r.first_round_at,
  round((extract(epoch from (r.first_round_at - lm.first_joined_at)) / 86400.0)::numeric, 1)
                                          as days_to_first_round,
  r.rounds_posted
from public.profiles p
join auth.users u on u.id = p.id
left join lateral (
  select min(m.joined_at) as first_joined_at
  from public.league_members m where m.profile_id = p.id
) lm on true
left join lateral (
  select min(x.created_at) as first_round_at, count(*) as rounds_posted
  from public.rounds x where x.profile_id = p.id and not x.voided
) r on true
where p.deleted_at is null;

revoke all on public.v_pilot_gates from anon, authenticated;

-- Gate 3, one row per posted round: how long the composer was open, which
-- mode posted (the D32 validation), what landed.
create or replace view public.v_post_timings as
select
  e.created_at,
  e.profile_id,
  e.props->>'mode'          as mode,      -- 'total' (front & back) | 'holes'
  (e.props->>'secs')::int   as secs,      -- target < 60
  (e.props->>'gross')::int  as gross,
  (e.props->>'holes')::int  as holes
from public.client_events e
where e.event = 'post_submit';

revoke all on public.v_post_timings from anon, authenticated;
