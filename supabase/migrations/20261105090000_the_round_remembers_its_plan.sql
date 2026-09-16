-- Cup Season — the round remembers its plan (D367 / F10 / F12 · Codex R4, R6).
--
-- WRITTEN, VALIDATED IN ISOLATION, AND NOT PUSHED. The owner pushes it.
--
-- Inbox 28 said it plainly: `rounds` carried no pointer to the plan it was
-- played on, and D345 declined to add the column "because a column nothing
-- writes is not a fix". This is the wave that writes it.
--
--   1 · ONE live round per booking. `live_rounds.scheduled_round_id`, and a
--       partial unique index on the BOOKING alone while the round is live.
--       Codex R4: the first draft keyed it per starter, which let two golfers
--       open two rounds for one tee time. The approved behaviour is that
--       eligible golfers JOIN the same round — so the discriminator is the
--       booking, and a second caller gets the existing round back.
--   2 · START-OR-JOIN is a NEW, fully specified function —
--       `start_live_round_from_plan` — rather than a patch of
--       `start_live_round`, whose signature is left exactly as deployed
--       (Codex R6: the typed contract keeps its nine-argument row). It checks
--       the booking and the caller BEFORE anything is written: the booking
--       must exist (a cancelled plan is a deleted row), and the caller must
--       be its host or a tagged golfer who has not declined. A concurrent
--       second starter loses the index race and is handed the winner's round.
--   3 · a POSTED round remembers the booking it fulfilled —
--       `rounds.scheduled_round_id`, copied from the live round at finish.
--       Per golfer by construction, because a round belongs to one profile.
--   4 · `finish_live_round` says WHICH round it posted for WHOM — `round_id`
--       and `profile_id` on every posted card, and `profile_id` on every
--       skipped one (Codex R3: a name is not an identity).
--   5 · `home_dispatch`: "Open the plan" becomes "View round", and a plan the
--       viewer has a LINKED round for stops being offered as upcoming.
--   6 · `round_tally(p_round)`: the receipt's factual tally — eagles and
--       birdies from the round's own holes against the pars its live round
--       recorded, and only when the round names a course (F13). Nothing else
--       is scored, posted or notified.
--
-- HOW THE PATCHES ARE MADE. `finish_live_round` and `home_dispatch` are
-- patched in place from `pg_get_functiondef` (precedent 20261102090000).
-- EVERY anchor's occurrence count is asserted before the replace, and the
-- deployed body is read back afterwards: a drifted body RAISES rather than
-- silently deploying a function this header no longer describes.

-- ── 1 · the columns and the one-live-round-per-booking rule ──────────────────
alter table public.live_rounds
  add column if not exists scheduled_round_id uuid references public.scheduled_rounds(id) on delete set null;
alter table public.rounds
  add column if not exists scheduled_round_id uuid references public.scheduled_rounds(id) on delete set null;

drop index if exists public.live_rounds_one_per_plan_and_starter;
create unique index if not exists live_rounds_one_live_per_booking
  on public.live_rounds (scheduled_round_id)
  where status = 'live' and scheduled_round_id is not null;

create index if not exists rounds_scheduled_round_idx
  on public.rounds (scheduled_round_id) where scheduled_round_id is not null;

-- ── 2 · start-or-join, fully specified ───────────────────────────────────────
-- Does this golfer hold a seat in that live round? A member seat is matched
-- through league_members.profile_id; a known-golfer seat through
-- guest_profile_id; a claimed guest seat through claimed_profile.
create or replace function public.seated_in(p_live_round uuid, p_profile uuid)
returns boolean language sql stable security definer set search_path to 'public' as $fn$
  select exists (
    select 1 from live_round_players p
      left join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round
       and (p.guest_profile_id = p_profile or p.claimed_profile = p_profile or m.profile_id = p_profile))
$fn$;
revoke all on function public.seated_in(uuid, uuid) from public, anon, authenticated;

create or replace function public.start_live_round_from_plan(
  p_scheduled_round uuid,
  p_league uuid default null,
  p_course_label text default null,
  p_snapshot jsonb default null,
  p_game text default null,
  p_players jsonb default null,
  p_config jsonb default '{}'::jsonb,
  p_api_course_id text default null)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
  v uuid := auth.uid();
  sr scheduled_rounds%rowtype;
  v_existing live_rounds%rowtype;
  v_out jsonb;
  v_lr uuid;
begin
  if v is null then raise exception 'Sign in to start a round'; end if;
  if p_scheduled_round is null then raise exception 'No booking named'; end if;

  -- the booking must exist — a cancelled plan is a deleted row
  select * into sr from scheduled_rounds where id = p_scheduled_round;
  if not found then raise exception 'That booking is gone'; end if;

  -- and the caller must be its host, or a tagged golfer who has not declined
  if sr.profile_id <> v and not (v = any(coalesce(sr.tagged, '{}'::uuid[]))) then
    raise exception 'Only the host and the tagged golfers can tee this booking up';
  end if;
  if exists (select 1 from round_rsvp r where r.round_id = sr.id and r.profile_id = v and r.status = 'out') then
    raise exception 'You said you could not make this one';
  end if;

  -- JOIN: a live round already stands for this booking — hand it back, but
  -- ONLY to a golfer who holds a seat in it (Codex S2). Being tagged on the
  -- booking is not a seat: the host seats the group at tee-off, and a golfer
  -- who was pending then is told so rather than dropped into a round whose
  -- roster does not contain them.
  select * into v_existing from live_rounds
   where scheduled_round_id = sr.id and status = 'live'
   limit 1;
  if found then
    if not seated_in(v_existing.id, v) then
      raise exception 'The group teed off without a seat for you — ask the host to add you';
    end if;
    return jsonb_build_object('live_round_id', v_existing.id, 'join_code', v_existing.join_code, 'joined', true);
  end if;

  -- START: the ordinary start, then the link. A concurrent second starter
  -- loses the index race here and is handed the winner's round instead.
  begin
    v_out := start_live_round(p_league, null, null, p_course_label, p_snapshot, p_game, p_players, p_config, p_api_course_id);
    v_lr := (v_out->>'live_round_id')::uuid;
    update live_rounds set scheduled_round_id = sr.id where id = v_lr;
  exception when unique_violation then
    -- the round we just opened must not stand as a second one for the booking
    if v_lr is not null then
      update live_rounds set status = 'abandoned' where id = v_lr and status = 'live';
    end if;
    select * into v_existing from live_rounds where scheduled_round_id = sr.id and status = 'live' limit 1;
    if not found then raise; end if;
    if not seated_in(v_existing.id, v) then
      raise exception 'The group teed off without a seat for you — ask the host to add you';
    end if;
    return jsonb_build_object('live_round_id', v_existing.id, 'join_code', v_existing.join_code, 'joined', true);
  end;
  return v_out || jsonb_build_object('joined', false);
end
$fn$;
revoke all on function public.start_live_round_from_plan(uuid, uuid, text, jsonb, text, jsonb, jsonb, text) from public, anon;
grant execute on function public.start_live_round_from_plan(uuid, uuid, text, jsonb, text, jsonb, jsonb, text) to authenticated;

-- a counter for the anchors below; dropped at the end of this file
create or replace function pg_temp.count_of(hay text, needle text) returns int language sql immutable as
  'select (length($1) - length(replace($1, $2, ''''))) / length($2)';

-- ── 3 + 4 · finish_live_round links the round and names it ───────────────────
do $patch$
declare
  v_def text;
  v_old_cols text := 'source, attested, index_source_at_post, api_course_id, posted_by)';
  v_new_cols text := 'source, attested, index_source_at_post, api_course_id, posted_by, scheduled_round_id)';
  v_old_tail text := 'lr.api_course_id, v)';
  v_new_tail text := 'lr.api_course_id, v, lr.scheduled_round_id)';
  v_old_guest text := '''gross'', v_gross, ''holes'', v_holes);
      else';
  v_new_guest text := '''gross'', v_gross, ''holes'', v_holes,
          ''round_id'', v_round, ''profile_id'', v_pl.guest_profile_id);
      else';
  v_old_mine text := 'v_posted := v_posted || jsonb_build_object(''name'', playerlabel(v_pid), ''gross'', v_gross, ''holes'', v_holes);';
  v_new_mine text := 'v_posted := v_posted || jsonb_build_object(''name'', playerlabel(v_pid), ''gross'', v_gross, ''holes'', v_holes, ''round_id'', v_round, ''profile_id'', v_pid);';
  v_old_skip text := 'v_skipped := v_skipped || jsonb_build_object(''name'', playerlabel(v_pid), ''reason'',';
  v_new_skip text := 'v_skipped := v_skipped || jsonb_build_object(''name'', playerlabel(v_pid), ''profile_id'', v_pid, ''reason'',';
begin
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'finish_live_round';
  if v_def is null then raise exception 'finish_live_round is missing'; end if;
  if pg_temp.count_of(v_def, v_old_cols)  <> 2 then raise exception 'finish_live_round: expected 2 round inserts, found %', pg_temp.count_of(v_def, v_old_cols); end if;
  if pg_temp.count_of(v_def, v_old_tail)  <> 2 then raise exception 'finish_live_round: expected 2 values lists, found %', pg_temp.count_of(v_def, v_old_tail); end if;
  if pg_temp.count_of(v_def, v_old_guest) <> 1 then raise exception 'finish_live_round: guest payload anchor count %', pg_temp.count_of(v_def, v_old_guest); end if;
  if pg_temp.count_of(v_def, v_old_mine)  <> 1 then raise exception 'finish_live_round: member payload anchor count %', pg_temp.count_of(v_def, v_old_mine); end if;
  if pg_temp.count_of(v_def, v_old_skip)  <> 4 then raise exception 'finish_live_round: expected 4 skipped lines, found %', pg_temp.count_of(v_def, v_old_skip); end if;
  v_def := replace(v_def, v_old_cols, v_new_cols);
  v_def := replace(v_def, v_old_tail, v_new_tail);
  v_def := replace(v_def, v_old_guest, v_new_guest);
  v_def := replace(v_def, v_old_mine, v_new_mine);
  v_def := replace(v_def, v_old_skip, v_new_skip);
  execute v_def;
end
$patch$;

-- ── 5 · home_dispatch: "View round", and a linked plan is not upcoming ────────
do $patch$
declare
  v_def text;
  v_old_copy text := 'else ''Open the plan'' end,';
  v_new_copy text := 'else ''View round'' end,';
  v_old_gate text := 'and (e->>''play_on'')::date between v_today and v_today + 8 then';
  v_new_gate text := 'and (e->>''play_on'')::date between v_today and v_today + 8
       -- D367 · a plan the viewer has a LINKED round for is played, not upcoming
       and not exists (select 1 from rounds rd
                        where rd.profile_id = v
                          and rd.scheduled_round_id = nullif(e->>''id'', '''')::uuid
                          and not coalesce(rd.voided, false)) then';
begin
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'home_dispatch';
  if v_def is null then raise exception 'home_dispatch is missing'; end if;
  if pg_temp.count_of(v_def, v_old_copy) <> 1 then raise exception 'home_dispatch: "Open the plan" anchor count %', pg_temp.count_of(v_def, v_old_copy); end if;
  if pg_temp.count_of(v_def, v_old_gate) <> 1 then raise exception 'home_dispatch: plan gate anchor count %', pg_temp.count_of(v_def, v_old_gate); end if;
  v_def := replace(v_def, v_old_copy, v_new_copy);
  v_def := replace(v_def, v_old_gate, v_new_gate);
  execute v_def;
end
$patch$;

-- ── 6 · the receipt's factual tally ──────────────────────────────────────────
-- SECURITY INVOKER on purpose: whoever may read the round and its holes under
-- RLS may read this; nobody else learns anything. Pars are the ones the live
-- round recorded, and only when that snapshot says they were VERIFIED — a
-- template card is a guess, and a guess cannot declare an eagle (D368).
create or replace function public.round_tally(p_round uuid)
returns jsonb
language sql
stable
security invoker
set search_path to 'public'
as $fn$
  with r as (
    -- Codex S3 · a course id and a populated array are NOT proof of par: the
    -- client installs a par-72 template the moment a course is picked and
    -- replaces it only when the card read lands. `pars_verified` is written
    -- by the client ONLY when the pars came from the course's own card or the
    -- golfer wrote them; a snapshot without it (every historical round) is
    -- unknown, and unknown claims nothing.
    select rd.id, lr.course_snapshot->'pars' as pars,
           coalesce((lr.course_snapshot->>'pars_verified')::boolean, false) as verified
      from rounds rd
      join live_rounds lr on lr.id = rd.live_round_id
     where rd.id = p_round
  ),
  h as (
    select h.hole_number, h.strokes,
           (r.pars->>(h.hole_number - 1))::int as par
      from round_holes h
      join r on true
     where h.round_id = p_round
       and r.verified
       and jsonb_typeof(r.pars) = 'array'
       and jsonb_array_length(r.pars) >= h.hole_number
  )
  select jsonb_build_object(
    'known',   exists (select 1 from r where r.verified and jsonb_typeof(r.pars) = 'array'),
    'eagles',  (select count(*) from h where h.strokes > 0 and h.par - h.strokes >= 2),
    'birdies', (select count(*) from h where h.strokes > 0 and h.par - h.strokes = 1))
$fn$;
revoke all on function public.round_tally(uuid) from public, anon;
grant execute on function public.round_tally(uuid) to authenticated;

-- ── 7 · the self-check: read the deployed bodies back ────────────────────────
do $chk$
declare a text; b text; c text;
begin
  select pg_get_functiondef(p.oid) into a from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'finish_live_round';
  select pg_get_functiondef(p.oid) into b from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'home_dispatch';
  select pg_get_functiondef(p.oid) into c from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'start_live_round_from_plan';
  if position('''round_id'', v_round' in a) = 0 then raise exception 'check: finish_live_round does not name the round'; end if;
  if position('lr.scheduled_round_id' in a) = 0 then raise exception 'check: finish_live_round does not link the round'; end if;
  if position('''profile_id'', v_pid, ''reason''' in a) = 0 then raise exception 'check: skipped cards carry no identity'; end if;
  if position('View round' in b) = 0 or position('Open the plan' in b) > 0 then raise exception 'check: home_dispatch still says Open the plan'; end if;
  if position('rd.scheduled_round_id = nullif(e->>''id''' in b) = 0 then raise exception 'check: home_dispatch does not suppress a linked plan'; end if;
  if c is null then raise exception 'check: start_live_round_from_plan is missing'; end if;
  if position('seated_in(v_existing.id, v)' in c) = 0 then raise exception 'check: the join path does not require a seat'; end if;
  if not exists (select 1 from pg_proc where proname = 'seated_in') then raise exception 'check: seated_in is missing'; end if;
  if (select count(*) from pg_proc where proname = 'start_live_round') <> 1 then raise exception 'check: start_live_round overload count changed'; end if;
  if not exists (select 1 from pg_indexes where indexname = 'live_rounds_one_live_per_booking') then
    raise exception 'check: the one-live-round-per-booking index is missing'; end if;
  if exists (select 1 from pg_indexes where indexname = 'live_rounds_one_per_plan_and_starter') then
    raise exception 'check: the per-starter index must be gone'; end if;
end
$chk$;

drop function if exists pg_temp.count_of(text, text);
