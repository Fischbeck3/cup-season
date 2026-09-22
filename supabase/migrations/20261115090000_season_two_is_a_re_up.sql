-- ============================================================================
-- Cup Season · 20261115090000 · season two is a re-up
--
-- D375 (owner-ruled 2026-09-21, ruling 5-A; "build the season two re-ask now",
-- 2026-09-22). Spec §14.5: the re-up moment is the renewal moment. L-12: every
-- join passes the covenant. D351: nobody owes a stake they did not see. §16: a
-- finished table never moves.
--
-- WHAT CHANGES. A member of a league is no longer a member of its next season
-- by construction (D243). `run_it_back` still mints season N+1 with the terms
-- carried (stake, length and pay note may move by the same arguments as
-- before), but it seats only the Pro and ASKS everybody else: one
-- `member_invites` row per living member, one push, and the board says the
-- invitations are out. A yes is the door the first season used — my_invites →
-- the covenant → respond_invite — or the league code (the covenant →
-- join_league). Both record it in `league_members.agreed_seasons` and post it
-- once. Until a member says yes, their rounds do not score in the new season,
-- the hat does not deal them, the season cannot start on their account, the
-- Final does not seed them and the pot does not count them.
--
-- WHY THE INVITATION DOOR AND NOT THE LOCK DOOR. The decision entry sketched
-- "back to setup; the lock door does the rest". Read against the code, that
-- door is a first-season door: `_join_gate` refuses `setup`, `lock_league`
-- mints season 1 and the wizard scaffolds a new league. The invitation door
-- already carries the covenant (D351) and a recorded answer; riding it is the
-- smaller change with the outcome the ruling asked for — the covenant again, a
-- recorded yes per member per season, the agreed predicate in the lens, the
-- floors and the pot, and a Pro who can count yeses. The entry carries an
-- as-built note; the bylaws still carry LOCKED (D243), which the note names.
--
-- THE RECORD. `agreed_seasons integer[]` on league_members — the season
-- numbers this member said yes to — with `agreed_at` (the latest yes). A
-- BEFORE INSERT trigger gives a fresh seat the league's current season, so
-- every existing writer (join_league, respond_invite, create_league, seeders,
-- the sim) keeps its meaning. The backfill gives every existing member every
-- season the league has had, which is exactly what D243 made true by
-- construction, so no existing round moves (the self-check counts them). A
-- member who stepped out (D244) is asked again — leaving was for the season
-- that ended — and a yes re-seats them: `left_at` clears into `prior_left_at`,
-- and the lens keeps every round posted after that step-out out of the
-- season they stepped out of.
--
-- HOW EVERY FUNCTION HERE IS CHANGED: the 20261102090000 pattern — read the
-- LIVE definition with pg_get_functiondef, assert the exact text, replace,
-- execute; idempotent with a notice when the new text is already present.
-- `run_it_back` and `join_covenant_info` are re-emitted whole (their live
-- text is their latest file text and the change is most of the body);
-- `my_invites` grows two columns, so it is DROP + CREATE as in 20261031090000.
--
-- VERIFY: tests/sim/sandbox/apply.sh on the full chain; the self-check at the
-- foot; db-check 37 after the push. Clients (D234): the desk half ships with
-- this commit; the phone half is listed in the rulings packet §7.
-- ============================================================================

-- the D43-style guard: how many rounds the lens counts BEFORE anything moves
create temp table if not exists _d375_before as
  select count(*)::bigint as n from public.v_rounds_ranked;

-- ── 1 · the record ───────────────────────────────────────────────────────────
alter table public.league_members add column if not exists agreed_seasons integer[] not null default '{}';
alter table public.league_members add column if not exists agreed_at      timestamptz;
alter table public.league_members add column if not exists prior_left_at  timestamptz;
-- D37 · a new column on a granted table is still granted explicitly.
grant select (agreed_seasons, agreed_at, prior_left_at) on public.league_members to authenticated;

-- backfill: every member is in every season the league has had (D243's truth,
-- now written down). Idempotent — only an empty record is filled.
update public.league_members lm
   set agreed_seasons = coalesce((select array_agg(s.number order by s.number)
                                    from public.seasons s where s.league_id = lm.league_id), '{1}'),
       agreed_at      = coalesce(lm.agreed_at, lm.joined_at)
 where lm.agreed_seasons = '{}';

-- a fresh seat is a yes to the season the league is in (or to its first)
create or replace function public._agree_on_join()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.agreed_seasons is null or new.agreed_seasons = '{}' then
    new.agreed_seasons := array[coalesce((select max(number) from seasons where league_id = new.league_id), 1)];
  end if;
  if new.agreed_at is null then new.agreed_at := now(); end if;
  return new;
end $$;
revoke all on function public._agree_on_join() from public, anon, authenticated;
drop trigger if exists league_members_agree_on_join on public.league_members;
create trigger league_members_agree_on_join
  before insert on public.league_members
  for each row execute function public._agree_on_join();

-- ── 2 · the helpers (engine-only; no client calls them) ──────────────────────
-- the seated roster of a season: said yes to it, not suspended, not stepped out
create or replace function public._season_roster(p_season uuid)
returns table(member_id uuid)
language sql stable security definer set search_path = public
as $$
  select lm.id
    from league_members lm
    join seasons s on s.league_id = lm.league_id
   where s.id = p_season
     and s.number = any(lm.agreed_seasons)
     and lm.suspended_at is null
     and lm.left_at is null;
$$;
revoke all on function public._season_roster(uuid) from public, anon, authenticated;

-- the recorded yes to the league's current season: true when it is new, false
-- when it was already on record (so a caller announces it once, L-20)
create or replace function public._agree_to_season(p_league uuid, p_profile uuid)
returns boolean
language plpgsql security definer set search_path = public
as $$
declare v_n integer; v_rows integer;
begin
  select coalesce(max(number), 1) into v_n from seasons where league_id = p_league;
  update league_members
     set agreed_seasons = array_append(agreed_seasons, v_n),
         agreed_at      = now(),
         -- D244 · a step-out is per season. A yes to the next one re-seats the
         -- member; the step-out is remembered so the lens keeps the rounds
         -- posted while away out of the season they left (§16).
         prior_left_at  = coalesce(left_at, prior_left_at),
         left_at        = null
   where league_id = p_league and profile_id = p_profile
     and not (v_n = any(agreed_seasons));
  get diagnostics v_rows = row_count;
  -- a yes by either door answers the invitation that asked for it, so nobody
  -- is shown an invitation to a season they are already in
  if v_rows = 1 then
    update member_invites set status = 'accepted'
     where league_id = p_league and profile_id = p_profile and status = 'pending';
  end if;
  return v_rows = 1;
end $$;
revoke all on function public._agree_to_season(uuid, uuid) from public, anon, authenticated;

-- ── 3 · the lens ─────────────────────────────────────────────────────────────
-- v_rounds_ranked: two conjuncts beside the suspension's and the step-out's.
-- Patched from the LIVE definition (20261013090000 re-set security_invoker on
-- it after a re-emission dropped the option; create or replace view discards
-- reloptions, so it is set again explicitly).
do $patch$
declare v_def text; v_new text; v_anchor text; v_n integer;
begin
  v_def := pg_get_viewdef('public.v_rounds_ranked'::regclass, true);
  if position('agreed_seasons' in v_def) > 0 then
    raise notice '[D375] v_rounds_ranked already reads agreed_seasons';
  else
    v_anchor := '(lm.left_at IS NULL OR r.created_at < lm.left_at)';
    v_n := (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor);
    if v_n <> 1 then
      raise exception '[D375] v_rounds_ranked: the step-out conjunct was found % times; expected once', v_n;
    end if;
    v_new := replace(v_def, v_anchor,
      v_anchor
      || ' AND (s.number = ANY (lm.agreed_seasons))'
      || ' AND (lm.prior_left_at IS NULL OR r.created_at < lm.prior_left_at'
      || ' OR s.starts_on > (lm.prior_left_at AT TIME ZONE s.timezone)::date)');
    execute 'create or replace view public.v_rounds_ranked as ' || rtrim(v_new, E'; \n');
  end if;
  execute 'alter view public.v_rounds_ranked set (security_invoker = true)';
end $patch$;

-- v_individual_standings: 20261113090000's text with the agreed predicate on
-- the seasons join, so a season's table lists the golfers who said yes to it
-- (season 1: everyone, by the backfill).
create or replace view public.v_individual_standings with (security_invoker = 'true') as
 with adj as (
   select a.season_id, a.member_id, coalesce(sum(a.points), 0)::bigint as pts
     from public.season_adjustments a
    where a.member_id is not null and a.kind = 'override'
    group by a.season_id, a.member_id
 )
 select lm.id as member_id,
        s.id  as season_id,
        (coalesce(sum(rr.points) filter (where rr.month_rank <= coalesce(ls.counting_cap, 999)), 0::bigint)
         + coalesce(max(adj.pts), 0::bigint)) as points,
        count(rr.round_id) as rounds_posted
   from public.league_members lm
   join public.seasons s          on s.league_id = lm.league_id
                                 and s.number = any(lm.agreed_seasons)
   join public.league_settings ls on ls.league_id = lm.league_id
   left join public.v_rounds_ranked rr on rr.member_id = lm.id and rr.season_id = s.id
   left join adj on adj.season_id = s.id and adj.member_id = lm.id
  group by lm.id, s.id;

-- ── 4 · run_it_back asks ─────────────────────────────────────────────────────
-- Re-emitted whole: the body is 20261012090000:126–287's (its live text; the
-- 2026-09-21 sandbox read matched it) with the seating replaced by the ask.
create or replace function public.run_it_back(
  p_league        uuid,
  p_starts_on     date    default null,
  p_ends_on       date    default null,
  p_buyin_cents   int     default null,
  p_season_months int     default null,
  p_pay_note      text    default null
) returns json
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_league    leagues%rowtype;
  v_settings  league_settings%rowtype;
  v_last      seasons%rowtype;
  v_open      seasons%rowtype;
  v_new       seasons%rowtype;
  v_starts    date;
  v_ends      date;
  v_months    int;
  v_buyin     int;
  v_note      text := nullif(btrim(coalesce(p_pay_note, '')), '');
  v_stake_moved  boolean;
  v_length_moved boolean;
  v_asked     int := 0;
  v_agreed    int := 0;
  v_phase     text;
  v_changed   text;
begin
  select * into v_league from leagues where id = p_league;
  if not found then raise exception 'That league no longer exists.'; end if;

  -- D243's second half: a member who taps this must never become a founder.
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro can run it back.';
  end if;

  select * into v_settings from league_settings where league_id = p_league;
  if not found then raise exception 'That league never started a season.'; end if;

  -- IDEMPOTENT. A double tap, or a retry after a dropped response, must not
  -- mint a second season — so an already-open season is the answer, not an
  -- error, and the client renders the same screen either way. D375: the
  -- counts are the open season's own — who has said yes, who is still asked.
  select * into v_open from seasons
   where league_id = p_league and status <> 'complete'
   order by number desc limit 1;
  if found then
    select count(*) into v_agreed from league_members lm
     where lm.league_id = p_league and lm.suspended_at is null and lm.left_at is null
       and v_open.number = any(lm.agreed_seasons);
    select count(*) into v_asked from member_invites mi
     where mi.league_id = p_league and mi.status = 'pending';
    return json_build_object(
      'already_running', true,
      'league_id',       p_league,
      'season',          row_to_json(v_open),
      'seated',          v_agreed,
      'agreed',          v_agreed,
      'asked',           v_asked,
      'invited',         v_asked,
      'covenant_refires', true);
  end if;

  select * into v_last from seasons
   where league_id = p_league
   order by number desc limit 1;
  if not found then
    raise exception 'This league has no season to run back yet.';
  end if;

  -- the window (D243, unchanged)
  v_starts := coalesce(p_starts_on, greatest(current_date, v_last.ends_on + 1));
  v_months := greatest(1, least(12, coalesce(p_season_months, v_settings.season_months, 6)));
  v_ends   := coalesce(p_ends_on, v_starts + (v_months * 30.44)::int - 1);
  if v_ends <= v_starts then raise exception 'A season ends after it starts.'; end if;
  -- the stored figure is the one the window actually describes, exactly as
  -- lock_league derives it, so the two cannot disagree about "how long"
  v_months := greatest(1, least(12, round((v_ends - v_starts + 1) / 30.44::numeric)::int));
  v_buyin  := coalesce(p_buyin_cents, v_settings.buyin_cents, 0);

  v_stake_moved  := v_buyin is distinct from coalesce(v_settings.buyin_cents, 0);
  v_length_moved := v_months is distinct from v_settings.season_months;

  update league_settings
     set buyin_cents   = v_buyin,
         season_months = v_months,
         -- coalesce, never clobber: a Pro who sends no note keeps the one
         -- set_buy_in_terms recorded (R18's own rule)
         buy_in_note   = coalesce(v_note, buy_in_note),
         -- a new season opens its roster again; D161's window is per season
         roster_closed_at = null
   where league_id = p_league
  returning * into v_settings;

  insert into seasons (league_id, number, starts_on, ends_on)
  values (p_league, v_last.number + 1, v_starts, v_ends)
  returning * into v_new;

  -- the squads exist and stand empty; the hat deals only those who said yes
  if v_settings.structure <> 'solo' then
    perform form_squads(v_new.id);
  end if;
  v_phase := case when v_settings.structure = 'solo' then 'season' else 'draft' end;
  update leagues set phase = v_phase where id = p_league;

  -- THE PRO'S OWN YES is the tap itself.
  perform _agree_to_season(p_league, auth.uid());

  -- THE ASK (D375). Every living member of the league — a suspension stands; a
  -- step-out (D244) was for the season that ended, so they are asked too —
  -- gets the invitation the first season used: the same door, the same
  -- covenant, the same recorded yes. `member_invites_league_uq` makes both
  -- halves safe: a settled row goes back to pending, a missing one is inserted.
  update member_invites
     set status = 'pending', invited_by = auth.uid(), created_at = now()
   where league_id = p_league
     and status <> 'pending'
     and profile_id in (select lm.profile_id from league_members lm
                         where lm.league_id = p_league and lm.suspended_at is null
                           and lm.profile_id <> auth.uid());

  insert into member_invites (league_id, profile_id, invited_by)
  select p_league, lm.profile_id, auth.uid()
    from league_members lm
   where lm.league_id = p_league
     and lm.suspended_at is null
     and lm.profile_id <> auth.uid()
     and not exists (select 1 from member_invites mi
                      where mi.league_id = p_league and mi.profile_id = lm.profile_id)
  on conflict do nothing;

  select count(*) into v_asked
    from member_invites mi
    join league_members lm on lm.league_id = mi.league_id and lm.profile_id = mi.profile_id
   where mi.league_id = p_league and mi.status = 'pending'
     and lm.suspended_at is null;

  -- the invitation rings (D104's shape: the title is the league, the body is
  -- one line in the tee-sheet voice; the payload routes to the invitation)
  insert into push_nudges (profile_id, kind, title, body, payload)
  select mi.profile_id, 'invite', v_league.name,
         'Season ' || v_new.number || ' — same rules, fresh table. In?',
         jsonb_build_object('invite_id', mi.id, 'league_id', p_league)
    from member_invites mi
    join league_members lm on lm.league_id = mi.league_id and lm.profile_id = mi.profile_id
   where mi.league_id = p_league and mi.status = 'pending'
     and lm.suspended_at is null;

  v_agreed := 1;   -- the Pro

  v_changed := case
    when v_stake_moved and v_length_moved then ' The stake and the length changed.'
    when v_stake_moved  then ' The stake changed.'
    when v_length_moved then ' The length changed.'
    else '' end;

  insert into posts (league_id, season_id, kind, body)
  values (p_league, v_new.id, 'system',
          'Season ' || v_new.number || ' is on. First tee '
          || to_char(v_new.starts_on, 'Dy Mon FMDD') || ' · '
          || case when coalesce(v_settings.counting_cap, 0) > 0
                  then 'best ' || v_settings.counting_cap || ' a month.'
                  else 'every round counts.' end
          || v_changed
          || ' The invitations are out — everyone says yes again before they''re in.');

  return json_build_object(
    'already_running', false,
    'league_id',       p_league,
    'season',          row_to_json(v_new),
    'seated',          v_agreed,
    'agreed',          v_agreed,
    'asked',           v_asked,
    'invited',         v_asked,
    'covenant_refires', true,
    'stake_moved',     v_stake_moved,
    'length_moved',    v_length_moved);
end $fn$;
revoke all on function public.run_it_back(uuid, date, date, integer, integer, text) from public, anon;
grant execute on function public.run_it_back(uuid, date, date, integer, integer, text) to authenticated;

-- ── 5 · the in-place patches ─────────────────────────────────────────────────
-- One temp helper, the 20261102090000 pattern with the anchors as data: read
-- the LIVE definition, return with a notice when the marker is already there,
-- raise when an anchor is not found exactly the expected number of times,
-- otherwise replace every anchor and execute the result. It lives in pg_temp
-- and is gone with the session.
create or replace function pg_temp._d375_patch(
  p_fn text, p_marker text, p_anchors text[], p_news text[], p_expects integer[])
returns void language plpgsql as $$
declare v_oid oid; v_def text; v_n integer; i integer;
begin
  select count(*) into v_n from pg_proc where proname = p_fn and pronamespace = 'public'::regnamespace;
  if v_n <> 1 then raise exception '[D375] % has % definitions; expected one', p_fn, v_n; end if;
  select oid into v_oid from pg_proc where proname = p_fn and pronamespace = 'public'::regnamespace;
  v_def := pg_get_functiondef(v_oid);
  if position(p_marker in v_def) > 0 then
    raise notice '[D375] % already carries the change', p_fn; return;
  end if;
  for i in 1 .. array_length(p_anchors, 1) loop
    v_n := (length(v_def) - length(replace(v_def, p_anchors[i], ''))) / length(p_anchors[i]);
    if v_n <> p_expects[i] then
      raise exception '[D375] %: anchor % was found % times; expected % — the live body has drifted, read it before patching',
        p_fn, i, v_n, p_expects[i];
    end if;
    v_def := replace(v_def, p_anchors[i], p_news[i]);
  end loop;
  execute v_def;
end $$;

-- respond_invite · a yes from a member of the league is the recorded re-up.
-- A fresh seat (v_new) is a yes by the insert trigger and is announced below
-- as before. Once the season is under way a late yes lands on the thinnest
-- squad (§15); before the draw it stays loose for the hat (§14.5, fresh draw).
select pg_temp._d375_patch('respond_invite', '_agree_to_season(mi.league_id',
  array[$a$      if v_new is not null then
        v_squad := _late_squad(mi.league_id, v_new);$a$],
  array[$a$      -- D375 · a member saying yes to the league's next season: the recorded
      -- yes, said once in its own words (L-20). Under way, a late yes lands on
      -- the thinnest squad (§15); before the draw it stays loose for the hat.
      if v_new is null and _agree_to_season(mi.league_id, auth.uid()) then
        if (select phase from leagues where id = mi.league_id) = 'season' then
          v_squad := _late_squad(mi.league_id, (select lm.id from league_members lm
                                                 where lm.league_id = mi.league_id and lm.profile_id = auth.uid()));
        end if;
        insert into posts (league_id, kind, body)
          values (mi.league_id, 'system',
                  coalesce(v_name,'A golfer') || ' is in for season '
                  || (select max(number) from seasons where league_id = mi.league_id) || '.'
                  || case when v_squad is not null
                          then ' The thinnest squad takes them: ' || v_squad || '.'
                          else '' end);
      end if;
      if v_new is not null then
        v_squad := _late_squad(mi.league_id, v_new);$a$],
  array[1]);

-- join_league · a member re-entering by the code while a new season is open
-- has read the covenant for it; the yes is recorded once and said once.
select pg_temp._d375_patch('join_league', '_agree_to_season(v_league',
  array[$a$  -- only announce on a genuine join, not a re-tap of a league you're already in
  if v_new is not null then$a$],
  array[$a$  -- D375 · a member re-entering by the code while a new season is open has
  -- read the covenant for it: the yes is recorded once and said once (L-20).
  if v_new is null and _agree_to_season(v_league, auth.uid()) then
    select display_name into v_name from profiles where id = auth.uid();
    insert into posts (league_id, kind, body)
      values (v_league, 'system', coalesce(v_name,'A golfer') || ' is in for season '
              || (select max(number) from seasons where league_id = v_league) || '.');
  end if;
  -- only announce on a genuine join, not a re-tap of a league you're already in
  if v_new is not null then$a$],
  array[1]);

-- randomize_squads · the hat deals the season's roster: those who said yes,
-- not suspended, not stepped out. Three reads of the league's members, all
-- three the season's.
select pg_temp._d375_patch('randomize_squads', '_season_roster(',
  array['lm.league_id = se.league_id'],
  array['lm.league_id = se.league_id and lm.id in (select member_id from _season_roster(p_season))'],
  array[3]);

-- start_season · "minimum four" and "everyone on a squad" count the same roster
select pg_temp._d375_patch('start_season', '_season_roster(',
  array['lm.league_id = se.league_id'],
  array['lm.league_id = se.league_id and lm.id in (select member_id from _season_roster(p_season))'],
  array[2]);

-- recompute_season_payouts · the pot is stake × the golfers who said yes to
-- THIS season; a step-out or a suspension does not un-owe a stake (unchanged)
select pg_temp._d375_patch('recompute_season_payouts', 'agreed_seasons',
  array[$a$  select count(*) into n_members from league_members where league_id = se.league_id;$a$,
        $a$   where lm.league_id = se.league_id
     and coalesce(st.buyin_cents, 0) > 0$a$],
  array[$a$  select count(*) into n_members from league_members lm
   where lm.league_id = se.league_id and se.number = any(lm.agreed_seasons);$a$,
        $a$   where lm.league_id = se.league_id
     and se.number = any(lm.agreed_seasons)
     and coalesce(st.buyin_cents, 0) > 0$a$],
  array[1, 1]);

-- league_pulse · the month's floor table lists the season's roster
select pg_temp._d375_patch('league_pulse', 'agreed_seasons',
  array[$a$     and is_league_member(p_league)$a$],
  array[$a$     and is_league_member(p_league)
     and exists (select 1 from seasons sx
                  where sx.id = (select season_id from info)
                    and sx.number = any(lm.agreed_seasons))$a$],
  array[1]);

-- career_record · "seasons played" are the complete seasons this golfer said yes to
select pg_temp._d375_patch('career_record', 'agreed_seasons',
  array[$a$where lm.profile_id = v and s.status = 'complete'$a$],
  array[$a$where lm.profile_id = v and s.status = 'complete'
                          and s.number = any(lm.agreed_seasons)$a$],
  array[1]);

-- invite_golfer · the Pro may ask a member again while their yes to the
-- current season is not on record (the re-up nudge): a still-pending
-- invitation is re-dated and rings again (D104's no-re-ping rule guards the
-- picker's double tap, not this explicit tap), and the ring says what it is.
select pg_temp._d375_patch('invite_golfer', 'same rules, fresh table',
  array[$a$if p_league is not null and exists (select 1 from league_members where league_id=p_league and profile_id=p_profile) then$a$,
        $a$  -- D104 · the invitation rings.$a$,
        $a$values (p_profile, 'invite', v_title, v_who || ' invited you',$a$],
  array[$a$if p_league is not null and exists (select 1 from league_members lm
                                        where lm.league_id=p_league and lm.profile_id=p_profile
                                          and (select coalesce(max(number), 1) from seasons where league_id=p_league) = any(lm.agreed_seasons)) then$a$,
        $a$  -- D375 · a member asked again for a season they have not answered: the
  -- pending invitation is re-dated so it rings again
  if v_id is null and p_league is not null
     and exists (select 1 from league_members x where x.league_id=p_league and x.profile_id=p_profile) then
    update member_invites set invited_by=auth.uid(), created_at=now()
      where league_id=p_league and profile_id=p_profile and status='pending'
      returning id into v_id;
  end if;
  -- D104 · the invitation rings.$a$,
        $a$values (p_profile, 'invite', v_title,
            case when p_league is not null
                  and exists (select 1 from league_members x where x.league_id=p_league and x.profile_id=p_profile)
                 then 'Season ' || (select coalesce(max(number), 1) from seasons where league_id=p_league)
                      || ' — same rules, fresh table. In?'
                 else v_who || ' invited you' end,$a$],
  array[1, 1, 1]);

-- home_dispatch · the invitation item says what it is when it is a re-up
select pg_temp._d375_patch('home_dispatch', $m$e->>'reup'$m$,
  array[$a$coalesce(firstname(e->>'inviter'), 'A golfer') || ' put you on '$a$,
        $a$|| coalesce(nullif(e->>'container_name', ''), 'a season') || '.',$a$],
  array[$a$case when coalesce((e->>'reup')::boolean, false)
                         then 'Season ' || coalesce(e->>'season_number', '') || ' of '
                              || coalesce(nullif(e->>'container_name', ''), 'your league')
                              || ' is on. Same rules, fresh table.'
                         else coalesce(firstname(e->>'inviter'), 'A golfer') || ' put you on '$a$,
        $a$|| coalesce(nullif(e->>'container_name', ''), 'a season') || '.' end,$a$],
  array[1, 1]);

drop function pg_temp._d375_patch(text, text, text[], text[], integer[]);

-- ── 6 · my_invites says which season, and whether it is a re-up ──────────────
-- Two columns appended (D356's own rule: every existing column, its order and
-- its meaning unchanged; DROP + CREATE because a returns-table function cannot
-- grow a column under create or replace; the ACL restated). `native_home`
-- embeds to_jsonb(i) of these rows, so the Home item carries both keys with
-- no change of its own.
drop function if exists public.my_invites();

create function public.my_invites()
returns table(id uuid, kind text, container_id uuid, container_name text,
              inviter text, starts_on date, created_at timestamptz,
              event_kind text, buy_in numeric,
              season_number integer, reup boolean)
language sql stable security definer set search_path = public as $$
  select mi.id,
    case when mi.league_id is not null then 'league' else 'event' end,
    coalesce(mi.league_id, mi.event_id),
    coalesce(l.name, e.name),
    p.display_name,
    e.starts_on,
    mi.created_at,
    e.kind,
    e.buy_in,
    -- D375 · the season the invitation is for, and whether the invitee is
    -- already a member of the league (a re-up, never a first join)
    (select max(s.number) from seasons s where s.league_id = mi.league_id),
    (mi.league_id is not null and exists (select 1 from league_members lm
                                            where lm.league_id = mi.league_id and lm.profile_id = mi.profile_id))
  from member_invites mi
  left join leagues  l on l.id = mi.league_id
  left join events   e on e.id = mi.event_id
  left join profiles p on p.id = mi.invited_by
  where mi.profile_id = auth.uid() and mi.status = 'pending'
  order by mi.created_at desc;
$$;
revoke all on function public.my_invites() from public, anon;
grant execute on function public.my_invites() to authenticated;

-- ── 7 · the covenant carries the season ──────────────────────────────────────
-- 20261029090000's text (the allowance, D353's two booleans, R9's six) with:
-- the roster limited to the golfers who said yes to the season being joined
-- (season 1: everyone), `season_number`, `reup` (the caller is already a
-- member), `agreed` (the caller's yes to this season is already on record) and
-- `last_season` — the caller's own finish in the season before, null when it
-- cannot be computed (L-44). Signed-out callers get the same nine keys as before.
create or replace function public.join_covenant_info(p_code text)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'name',        l.name,
    'buyin_cents', coalesce(ls.buyin_cents, 0),
    'preset',      ls.preset,
    'floor',       ls.participation_floor,
    'finish',      coalesce(ls.finish, 'cup_final'),
    'structure',   ls.structure,
    -- D129, fail-closed: a boolean and a date, never the note itself
    'has_pay_note', (ls.buy_in_note is not null),
    'buy_in_due_on', ls.buy_in_due_on,
    -- D161/D112 · so the door can say where the league stands before the OTP
    'phase',       l.phase)
  || case when auth.uid() is null then '{}'::jsonb else jsonb_build_object(
    -- R9 · the six, for a SIGNED-IN caller only. D375: the crew named is the
    -- crew that said yes to this season.
    'roster', (
      select jsonb_build_object(
        'count',    (select count(*)::int from league_members m
                      where m.league_id = l.id and m.left_at is null
                        and (s.number is null or s.number = any(m.agreed_seasons))),
        'pro_name', (select p.display_name from league_members m2
                       join profiles p on p.id = m2.profile_id
                      where m2.league_id = l.id and m2.role = 'commissioner' and m2.left_at is null limit 1),
        'names',    coalesce((select jsonb_agg(x.display_name order by x.ord) from (
                      select p.display_name, m3.joined_at as ord
                        from league_members m3 join profiles p on p.id = m3.profile_id
                       where m3.league_id = l.id and m3.role <> 'commissioner' and m3.left_at is null
                         and (s.number is null or s.number = any(m3.agreed_seasons))
                       order by m3.joined_at limit 6) x), '[]'::jsonb),
        'markers',  coalesce((select jsonb_agg(x.marker order by x.ord) from (
                      select p.marker, m4.joined_at as ord
                        from league_members m4 join profiles p on p.id = m4.profile_id
                       where m4.league_id = l.id and m4.role <> 'commissioner' and m4.left_at is null
                         and (s.number is null or s.number = any(m4.agreed_seasons))
                       order by m4.joined_at limit 6) x), '[]'::jsonb))),
    'starts_on',     s.starts_on,
    'ends_on',       s.ends_on,
    'weeks',         case when s.starts_on is null or s.ends_on is null then null
                          else greatest(1, round((s.ends_on - s.starts_on + 1) / 7.0)::int) end,
    'counting_cap',  ls.counting_cap,
    -- D353 · the two facts that were missing. `every_round_counts` is a real
    -- boolean so a client can tell Unlimited from "not in the payload".
    'every_round_counts', (ls.counting_cap is null),
    'handicap_allowance', ls.handicap_allowance,
    'split', case when coalesce(ls.buyin_cents, 0) > 0
                  then jsonb_build_object('champion',   ls.payout_champ,
                                          'runner_up',  ls.payout_runnerup,
                                          'points_king', ls.payout_king)
                  else null end,
    'pay', jsonb_build_object('has_note', (ls.buy_in_note is not null),
                              'due_on',   ls.buy_in_due_on),
    -- D375 · which season this yes is for, and whether it is a re-up
    'season_number', s.number,
    'reup',   exists (select 1 from league_members me
                       where me.league_id = l.id and me.profile_id = auth.uid()),
    'agreed', exists (select 1 from league_members me
                       where me.league_id = l.id and me.profile_id = auth.uid()
                         and s.number is not null and s.number = any(me.agreed_seasons)),
    'last_season', (
      select jsonb_build_object('number', ps.number, 'my_rank', r.rk, 'of', r.n, 'my_points', r.pts)
        from seasons ps
        cross join lateral (
          select x.rk, x.n, x.pts
            from (select vi.member_id, vi.points as pts,
                         rank() over (order by vi.points desc) as rk,
                         count(*) over () as n
                    from v_individual_standings vi
                   where vi.season_id = ps.id) x
            join league_members me on me.id = x.member_id and me.profile_id = auth.uid()) r
       where ps.league_id = l.id
         and ps.number = s.number - 1
         and ps.status = 'complete'
       limit 1))
  end
  from leagues l
  join league_settings ls on ls.league_id = l.id
  left join lateral (select sn.id, sn.number, sn.starts_on, sn.ends_on from seasons sn
                      where sn.league_id = l.id order by sn.number desc limit 1) s on true
  where upper(l.code) = upper(p_code)
  limit 1;
$function$;
revoke all on function public.join_covenant_info(text) from public;
grant execute on function public.join_covenant_info(text) to anon, authenticated;

-- ── self-check (read-only; mutates no row) ───────────────────────────────────
do $chk$
declare v_src text; v_n integer; v_before bigint; v_after bigint; fn text;
begin
  -- the record
  if (select count(*) from information_schema.columns
       where table_schema = 'public' and table_name = 'league_members'
         and column_name in ('agreed_seasons', 'agreed_at', 'prior_left_at')) <> 3 then
    raise exception '[D375] league_members is missing a record column';
  end if;
  select count(*) into v_n from league_members where agreed_seasons = '{}' or agreed_seasons is null;
  if v_n <> 0 then raise exception '[D375] % member(s) carry no season on record after the backfill', v_n; end if;
  if not exists (select 1 from pg_trigger where tgname = 'league_members_agree_on_join'
                    and tgrelid = 'public.league_members'::regclass and not tgisinternal) then
    raise exception '[D375] the insert trigger is missing';
  end if;
  foreach fn in array array['agreed_seasons', 'agreed_at', 'prior_left_at'] loop
    if not has_column_privilege('authenticated', 'public.league_members', fn, 'SELECT') then
      raise exception '[D375] authenticated cannot read league_members.%', fn;
    end if;
  end loop;

  -- the helpers are the engine's, not a client's
  foreach fn in array array['public._season_roster(uuid)', 'public._agree_to_season(uuid, uuid)', 'public._agree_on_join()'] loop
    if has_function_privilege('anon', fn, 'execute') or has_function_privilege('authenticated', fn, 'execute') then
      raise exception '[D375] % is reachable by a client role', fn;
    end if;
  end loop;

  -- the lens: both conjuncts, still invoker-secured, and no existing round moved
  select pg_get_viewdef('public.v_rounds_ranked'::regclass) into v_src;
  if v_src not like '%agreed_seasons%' or v_src not like '%prior_left_at%' then
    raise exception '[D375] v_rounds_ranked does not read the record';
  end if;
  if not exists (select 1 from pg_class c where c.oid = 'public.v_rounds_ranked'::regclass
                    and 'security_invoker=true' = any(c.reloptions)) then
    raise exception '[D375] v_rounds_ranked lost security_invoker';
  end if;
  select pg_get_viewdef('public.v_individual_standings'::regclass) into v_src;
  if v_src not like '%agreed_seasons%' then raise exception '[D375] v_individual_standings does not read the record'; end if;
  if not exists (select 1 from pg_class c where c.oid = 'public.v_individual_standings'::regclass
                    and 'security_invoker=true' = any(c.reloptions)) then
    raise exception '[D375] v_individual_standings lost security_invoker';
  end if;
  select n into v_before from _d375_before;
  select count(*) into v_after from public.v_rounds_ranked;
  if v_before <> v_after then
    raise exception '[D375] the lens counted % rounds before and % after — an existing round moved', v_before, v_after;
  end if;

  -- every producer carries its change
  foreach fn in array array['respond_invite', 'join_league'] loop
    select prosrc into v_src from pg_proc where proname = fn and pronamespace = 'public'::regnamespace;
    if v_src not like '%_agree_to_season(%' or v_src not like '%is in for season%' then
      raise exception '[D375] % does not record and say the yes', fn;
    end if;
  end loop;
  foreach fn in array array['randomize_squads', 'start_season'] loop
    select prosrc into v_src from pg_proc where proname = fn and pronamespace = 'public'::regnamespace;
    if v_src not like '%_season_roster(p_season)%' then raise exception '[D375] % does not read the season roster', fn; end if;
    if v_src like '%lm.league_id = se.league_id;%' or v_src like '%lm.league_id = se.league_id' || E'\n' || '%' then
      raise exception '[D375] % still reads the whole league somewhere', fn;
    end if;
  end loop;
  foreach fn in array array['recompute_season_payouts', 'league_pulse', 'career_record'] loop
    select prosrc into v_src from pg_proc where proname = fn and pronamespace = 'public'::regnamespace;
    if v_src not like '%agreed_seasons%' then raise exception '[D375] % does not read the record', fn; end if;
  end loop;
  select prosrc into v_src from pg_proc where proname = 'run_it_back' and pronamespace = 'public'::regnamespace;
  if v_src not like '%_agree_to_season(p_league, auth.uid())%' or v_src not like '%insert into push_nudges%'
     or v_src not like '%The invitations are out%' then
    raise exception '[D375] run_it_back does not ask';
  end if;
  select prosrc into v_src from pg_proc where proname = 'invite_golfer' and pronamespace = 'public'::regnamespace;
  if v_src not like '%same rules, fresh table%' then raise exception '[D375] invite_golfer cannot ask again'; end if;
  select prosrc into v_src from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_src not like $m$%e->>'reup'%$m$ then raise exception '[D375] home_dispatch does not say a re-up'; end if;
  select pg_get_function_result(oid) into v_src from pg_proc
   where proname = 'my_invites' and pronamespace = 'public'::regnamespace;
  if position('season_number integer, reup boolean' in v_src) = 0
     or position('kind text, container_id uuid, container_name text, inviter text, starts_on date, created_at timestamp' in v_src) = 0 then
    raise exception '[D375] my_invites lost or reordered a column: %', v_src;
  end if;
  if has_function_privilege('anon', 'public.my_invites()', 'execute')
     or not has_function_privilege('authenticated', 'public.my_invites()', 'execute') then
    raise exception '[D375] my_invites is wrongly granted after the drop';
  end if;
  select prosrc into v_src from pg_proc where proname = 'join_covenant_info' and pronamespace = 'public'::regnamespace;
  if v_src not like '%last_season%' or v_src not like '%season_number%' then
    raise exception '[D375] join_covenant_info does not carry the season';
  end if;
  if not has_function_privilege('anon', 'public.join_covenant_info(text)', 'execute')
     or not has_function_privilege('authenticated', 'public.join_covenant_info(text)', 'execute') then
    raise exception '[D375] join_covenant_info lost a grant (it is one of the twelve anon endpoints)';
  end if;
  if not has_function_privilege('authenticated', 'public.run_it_back(uuid, date, date, integer, integer, text)', 'execute')
     or has_function_privilege('anon', 'public.run_it_back(uuid, date, date, integer, integer, text)', 'execute') then
    raise exception '[D375] run_it_back is wrongly granted';
  end if;
end $chk$;

drop table if exists _d375_before;
