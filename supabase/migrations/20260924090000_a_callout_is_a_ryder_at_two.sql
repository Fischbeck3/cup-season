-- ============================================================================
-- D237 · The callout is a Ryder with a field of two — D21 closed, no new table
--
-- D21 was RULED and never built (zero code hits at tip). Two later proposals
-- answered it with a `callouts` table, which would have duplicated six built
-- things: event_sessions, event_session_targets, event_duels, resolve_session,
-- the taunt push and the rivalry union. It is built here as the OBJECT the
-- engine already has — a Ryder with teams of one and one session — and D250
-- declines the table in writing.
--
-- WHY TWO RPCs AND NOT ZERO. The shipped `create_event` cannot mint a callout,
-- verified three ways against the code:
--   · it raises 'The Ryder starts on a Sunday — sessions run Sun to Sat' for
--     any non-Sunday p_starts_on (20260830190000_ryder_dials.sql:43-45), so a
--     callout raised Thursday for Saturday cannot be created at all;
--   · events_draw_rule_check admits only team_pvi and shared (:29-31);
--   · NO shipped RPC assigns a team_id — not add_event_player
--     (20260830200000:70-74), not respond_invite's event branch
--     (20260830300000:222-226) — so a field of two would have no teams and
--     therefore no clash.
-- D237's "no migration" claim is struck in the entry. Its load-bearing claim —
-- NO NEW TABLE — stands: everything below is over `events`, `event_teams`,
-- `event_players`, `event_sessions`, `event_duels` and `push_nudges`.
--
-- THE THREE GUARDS THAT RIDE WITH IT
--   1. one open callout per pair at a time;
--   2. expiry is silent — resolve_session halves an unposted week and writes
--      no "never showed" line (L-22), which is D21's own recommendation;
--   3. no push on a callout the recipient declined this week — enforced by the
--      WRITER (`callout_mutes`), never by a client remembering.
--
-- Points: zero, always. league_id is null, so nothing here reaches
-- v_rounds_ranked, month_rank or a season table. A callout is bravado with a
-- receipt (D21), and if a future version wants it to score, that is a new
-- level-4 decision.
-- ============================================================================

-- ── 1 · the two CHECK values a callout needs ────────────────────────────────
-- `cancelled` is what a decline leaves behind. native_home already filters
-- `status in ('setup','live')` and run_event_sessions `('setup','live','complete')`,
-- so a cancelled event drops off every surface and every tick with no other
-- change. It is not deleted: the row is the caller's own record that they asked.
alter table public.events drop constraint if exists events_status_check;
alter table public.events add constraint events_status_check
  check (status in ('setup','live','complete','cancelled'));

-- push_nudges learns the callout kind. D248 (wave 8) extends this CHECK again;
-- both files use `drop constraint if exists`, so either order lands the same table.
alter table public.push_nudges drop constraint if exists push_nudges_kind_check;
alter table public.push_nudges add constraint push_nudges_kind_check
  check (kind in ('nudge', 'invite', 'request', 'rsvp', 'callout'));

-- ── 2 · the suppression, as a row rather than a promise ────────────────────
-- CC-52 (D221): pg_default_acl still grants everything on every new table, so
-- a new table is born wide and is sealed here, in the same migration.
create table if not exists public.callout_mutes (
  caller     uuid not null references public.profiles(id) on delete cascade,
  opponent   uuid not null references public.profiles(id) on delete cascade,
  week_start date not null,
  created_at timestamptz not null default now(),
  primary key (caller, opponent, week_start)
);
alter table public.callout_mutes enable row level security;
revoke all on public.callout_mutes from public, anon, authenticated;
-- No read policy and no grant: this table is the WRITER's memory, not a
-- surface. Nothing renders "he muted you" — that is the shame L-22 forbids.

-- ── 3 · R19 · call_out ─────────────────────────────────────────────────────
create or replace function public.call_out(
  p_opponent uuid,
  p_closes_on date default null,
  p_forfeit_terms text default null)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_me      uuid := auth.uid();
  v_closes  date;
  v_event   uuid;
  v_ta      uuid;
  v_tb      uuid;
  v_pa      uuid;
  v_pb      uuid;
  v_session uuid;
  v_na      text;
  v_nb      text;
  v_terms   text := nullif(trim(coalesce(p_forfeit_terms,'')), '');
  v_week    date := date_trunc('week', current_date)::date;
begin
  if v_me is null then raise exception 'Sign in first'; end if;
  if p_opponent is null or p_opponent = v_me then
    raise exception 'Call somebody else out';
  end if;

  -- Buddies only, mirroring D69's RSVP consent rule. A callout is not an
  -- invitation to a stranger.
  if not exists (select 1 from friendships f
                  where f.status = 'accepted'
                    and ((f.requester = v_me and f.addressee = p_opponent)
                      or (f.addressee = v_me and f.requester = p_opponent))) then
    raise exception 'Callouts are between buddies. Add them first';
  end if;

  -- Guard 3: they said no this week. Silent to them, honest to me.
  if exists (select 1 from callout_mutes
              where caller = v_me and opponent = p_opponent and week_start = v_week) then
    raise exception 'They passed this week. Try them next week';
  end if;

  v_closes := coalesce(p_closes_on, current_date + 7);
  if v_closes < current_date then raise exception 'Pick a day that has not happened yet'; end if;
  if v_closes > current_date + 60 then raise exception 'Two months is long enough for a callout'; end if;

  -- Guard 1: one open callout per pair at a time.
  if exists (
    select 1 from events e
      join event_players a on a.event_id = e.id and a.profile_id = v_me
      join event_players b on b.event_id = e.id and b.profile_id = p_opponent
     where e.league_id is null and e.session_count = 1
       and e.status in ('setup','live')
       and (select count(*) from event_players ep where ep.event_id = e.id) = 2) then
    raise exception 'You already have one open with them';
  end if;

  select coalesce(display_name, 'You')      into v_na from profiles where id = v_me;
  select coalesce(display_name, 'A golfer') into v_nb from profiles where id = p_opponent;

  -- The event. A FIRST TEE THAT IS NOT SNAPPED TO SUNDAY — the one thing
  -- create_event refuses, and the reason this function exists.
  insert into events (name, created_by, league_id, kind, status, starts_on,
                      session_count, session_weeks, draw_rule, tz, allowance)
  values (firstname(v_na) || ' v ' || firstname(v_nb), v_me, null, 'ryder', 'live',
          current_date, 1, 1, 'team_pvi', 'America/Phoenix', 100)
  returning id into v_event;

  -- The two teams are the two golfers. The room never says "Team A".
  insert into event_teams (event_id, slot, name, color)
    values (v_event, 0, firstname(v_na), 0) returning id into v_ta;
  insert into event_teams (event_id, slot, name, color)
    values (v_event, 1, firstname(v_nb), 1) returning id into v_tb;

  -- Both seated WITH team_id — the clause no shipped RPC can write.
  insert into event_players (event_id, profile_id, team_id, role, seed)
    values (v_event, v_me, v_ta, 'captain', 0) returning id into v_pa;
  insert into event_players (event_id, profile_id, team_id, role, seed)
    values (v_event, p_opponent, v_tb, 'player', 0) returning id into v_pb;
  update event_teams set captain_player_id = v_pa where id = v_ta;

  -- One session, open from today to the day it closes, and one duel in it.
  -- generate_pairings is deliberately NOT used: it writes an event_post, and a
  -- callout's first story belongs to the acceptance, not to the asking.
  insert into event_sessions (event_id, session_no, opens_on, closes_on, status)
    values (v_event, 1, current_date, v_closes, 'open')
  returning id into v_session;
  insert into event_duels (event_id, session_id, a_player, b_player)
    values (v_event, v_session, v_pa, v_pb);

  -- The stake, if there is one, is a FORFEIT (T-02) — never a fourth noun and
  -- never an amount in a column (D242 restates the rule this leans on).
  if v_terms is not null then
    perform create_forfeit(null, left(v_terms, 60), v_terms, 'custom', p_opponent, null, v_event, null);
  end if;

  -- The nudge. One of D23's eight emotions (anticipation), once per condition.
  insert into push_nudges (profile_id, kind, title, body, payload)
  values (p_opponent, 'callout', firstname(v_na) || ' called you out',
          'Best round by ' || trim(to_char(v_closes, 'Dy Mon FMDD')) || ' takes it'
          || coalesce(' — ' || v_terms, '') || '.',
          jsonb_build_object('event_id', v_event, 'profile_id', v_me));

  return v_event;
end $$;

revoke all on function public.call_out(uuid, date, text) from public, anon;
grant execute on function public.call_out(uuid, date, text) to authenticated;

-- ── 4 · R20 · respond_callout ──────────────────────────────────────────────
create or replace function public.respond_callout(p_event uuid, p_accept boolean default true)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_me     uuid := auth.uid();
  e        record;
  v_caller uuid;
  v_closes date;
  v_na     text;
begin
  if v_me is null then raise exception 'Sign in first'; end if;
  select * into e from events where id = p_event;
  if e.id is null then return 'gone'; end if;
  if e.league_id is not null or e.session_count <> 1 then
    raise exception 'That is not a callout';
  end if;
  if not exists (select 1 from event_players where event_id = p_event and profile_id = v_me) then
    raise exception 'That one is not yours to answer';
  end if;
  if e.created_by = v_me then raise exception 'You made this one'; end if;
  if e.status not in ('setup','live') then return 'closed'; end if;

  v_caller := e.created_by;
  select closes_on into v_closes from event_sessions where event_id = p_event order by session_no limit 1;

  if coalesce(p_accept, true) then
    -- Accept opens play: the session is already open, so the only thing left
    -- is the story, and the story is the acceptance.
    select coalesce(display_name, 'A golfer') into v_na from profiles where id = v_me;
    perform event_post(p_event, firstname(v_na) || ' is in. Best round by '
                       || trim(to_char(v_closes, 'Dy Mon FMDD')) || ' takes it.');
    return 'accepted';
  end if;

  -- A DECLINE CLOSES IT SILENTLY. No story, no post, no push, and no duel —
  -- so it is not a meeting, it does not reach my_rivalries, and head_to_head
  -- never counts it. L-22: saying no leaves no mark on anybody.
  delete from event_duels where event_id = p_event;
  update event_sessions set status = 'closed' where event_id = p_event;
  update events set status = 'cancelled' where id = p_event;
  insert into callout_mutes (caller, opponent, week_start)
  values (v_caller, v_me, date_trunc('week', current_date)::date)
  on conflict do nothing;
  return 'declined';
end $$;

revoke all on function public.respond_callout(uuid, boolean) from public, anon;
grant execute on function public.respond_callout(uuid, boolean) to authenticated;

-- ── 5 · self-check (L-05: read-only, never mutates a real row) ─────────────
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'call_out' and pronamespace = 'public'::regnamespace;
  if v_src is null then raise exception 'D237: call_out is missing'; end if;
  if position('team_id' in v_src) = 0 then
    raise exception 'D237: call_out does not seat the two golfers with teams — a field of two with no teams has no clash';
  end if;
  if position('Callouts are between buddies' in v_src) = 0 then
    raise exception 'D237: call_out lost its buddies-only consent rule (D69)';
  end if;
  if position('callout_mutes' in v_src) = 0 then
    raise exception 'D237: call_out does not honour a decline';
  end if;
  if position('league_id' in v_src) = 0 then
    raise exception 'D237: call_out must mint league_id null — a callout scores nothing';
  end if;

  select prosrc into v_src from pg_proc
   where proname = 'respond_callout' and pronamespace = 'public'::regnamespace;
  if v_src is null then raise exception 'D237: respond_callout is missing'; end if;
  if position('event_post' in v_src) = 0 then
    raise exception 'D237: an accepted callout writes no story';
  end if;
  -- the decline branch writes NOTHING to posts, and that is asserted rather than trusted
  if position('insert into posts' in v_src) > 0 then
    raise exception 'D237: respond_callout writes a board post — a decline is silent';
  end if;

  -- L-04, compiler-enforced: granted to authenticated, revoked from anon
  if has_function_privilege('anon', 'public.call_out(uuid,date,text)', 'execute')
     or has_function_privilege('anon', 'public.respond_callout(uuid,boolean)', 'execute') then
    raise exception 'D237: a callout RPC is reachable by anon';
  end if;
  if not has_function_privilege('authenticated', 'public.call_out(uuid,date,text)', 'execute')
     or not has_function_privilege('authenticated', 'public.respond_callout(uuid,boolean)', 'execute') then
    raise exception 'D237: a callout RPC is not granted to authenticated';
  end if;

  -- CC-52: the one new table is born sealed
  if has_table_privilege('anon', 'public.callout_mutes', 'select')
     or has_table_privilege('authenticated', 'public.callout_mutes', 'select') then
    raise exception 'D237: callout_mutes is readable — it is the writer''s memory, not a surface';
  end if;
end $chk$;
