-- ============================================================================
-- Cup Season — the first-tee horn, restored (D204)
--
-- 20260712130000 gave seasons a `kicked_off` sentinel and taught the daily
-- tick to flip it on the first day of the season and say so on the board.
-- 20260716170000 rewrote the tick for the endgame dial and did not carry the
-- block; D108 and D176 inherited the omission. No entry logged it. The one
-- beat that says "it has started" has been missing since July, and a lock
-- in a solo league has always been followed by silence.
--
-- Read out of prod on 2026-09-02 before writing: seven seasons. Three seeds
-- are kicked_off already. Of the rest, WTB (first tee 08-03, active) and the
-- seed Winter Circuit (08-30, active) started without a horn — the backfill
-- flips them quietly, no retroactive post. Fellas (first tee 09-30) stays
-- false and gets its horn on the morning of the 30th, league-local. Sandbox
-- is complete and is left alone.
--
--   1 · daily_season_tick — body verbatim (the D176 body) plus the branch
--   2 · backfill kicked_off where the season already started (2 rows in prod)
--   3 · lock_league says one line, in every structure
--   4 · start_season / make_pick — the tense follows the calendar
--   5 · self-check
-- ============================================================================

-- ── 1 · the tick, with its opening beat back ────────────────────────────────
-- Everything below the kickoff branch is the prod body verbatim. The horn
-- runs on the league's LOCAL date (the tick itself already thinks in local
-- days for the clash), fires once by the sentinel, and appends the floor
-- sentence only where a floor can be assessed: participation_floor > 0 and
-- structure <> 'solo' (D140 — a solo floor never assesses).
create or replace function public.daily_season_tick()
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare se record; v_finish text; v_local date; wcr record;
        v_floor integer; v_struct text; v_pen text;
begin
  -- live rounds die on their own now: 24h after start, an unfinished round is
  -- abandoned — resume and join surfaces go dark server-side, not just client.
  update live_rounds
     set status = 'abandoned', finished_at = coalesce(finished_at, now())
   where status in ('setup', 'live')
     and started_at < now() - interval '24 hours';

  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- D204 · the first-tee horn: first tick on/after the first tee, league-
    -- local, once ever (the sentinel is the idempotence, as the original was).
    v_local := (now() at time zone se.timezone)::date;
    if se.status = 'active' and not se.kicked_off and v_local >= se.starts_on then
      update seasons set kicked_off = true where id = se.id;
      select participation_floor, structure, floor_penalty
        into v_floor, v_struct, v_pen
        from league_settings where league_id = se.league_id;
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, se.id, 'system',
              'The season is live. Week 1 — counting rounds start now.'
              || case when coalesce(v_floor, 0) > 0 and coalesce(v_struct, 'solo') <> 'solo'
                      then ' Post ' || v_floor || ' round' || case when v_floor = 1 then '' else 's' end
                           || ' a month'
                           || case when v_pen in ('deduct', 'forfeit')
                                   then ' — miss once and your season bye covers it.'
                                   else '.' end
                      else '' end);
    end if;

    select finish into v_finish from league_settings where league_id = se.league_id;
    if se.status = 'active' and coalesce(v_finish,'cup_final') = 'cup_final'
       and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;

    -- D108: the weekly clash rides the tick. On the league's local date,
    -- settle every opened clash whose window has fully passed (the week-
    -- rollover detection — settles week N−1 on the increment, and self-heals
    -- across missed ticks and the season's final week), then open the current
    -- week's clash (which is also the first-run catch-up for live seasons).
    v_local := (now() at time zone se.timezone)::date;
    for wcr in
      select wc.week_no from week_clashes wc
       where wc.season_id = se.id and wc.settled_at is null
         and (se.starts_on + 7 * (wc.week_no - 1) + 6) < v_local
       order by wc.week_no
    loop
      perform settle_week_clash(se.id, wcr.week_no);
    end loop;
    perform open_week_clash(se.id);   -- no-ops outside the season / solo leagues
    -- D176 · and on the window's last day, say so. Runs AFTER the open so a
    -- one-week season's clash is opened and called on the same tick.
    perform clash_last_call(se.id);
  end loop;
end $function$;

revoke all on function public.daily_season_tick() from public, anon, authenticated;

-- ── 2 · seasons that already started get no retroactive horn ────────────────
do $d204a$
declare v_n integer;
begin
  update public.seasons
     set kicked_off = true
   where status in ('active', 'cup_final')
     and starts_on <= current_date
     and not kicked_off;
  get diagnostics v_n = row_count;
  raise notice '[D204] kicked_off backfilled on % season(s) that had already started', v_n;
end $d204a$;

-- ── 3 · lock_league says one line, in every structure ───────────────────────
-- Body = prod 2026-09-02 (20260830180000, D143) verbatim; one insert added
-- after the phase flips and before the return. It cannot double-post: the
-- already-locked branch above returns before reaching it. The date reads the
-- way both clients print a first tee ("Wed Sep 30"); the preset is its
-- display name; the cap clause is the bylaw as set.
create or replace function public.lock_league(p_league uuid, p_name text default null::text, p_preset text default 'standard'::text, p_handicap_allowance integer default 95, p_verification text default 'attested'::text, p_counting_cap integer default 3, p_participation_floor integer default 2, p_floor_penalty text default 'deduct'::text, p_season_format text default 'points'::text, p_structure text default 'squads2'::text, p_buyin_cents integer default 0, p_season_months integer default 6, p_draft_type text default 'random'::text, p_finish text default 'cup_final'::text, p_payout_champ integer default 60, p_payout_runnerup integer default 25, p_payout_king integer default 15, p_starts_on date default null::date, p_ends_on date default null::date)
returns json
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_league   leagues;
  v_settings league_settings;
  v_season   seasons;
  v_phase    text;
  v_starts   date;
  v_ends     date;
  v_months   int;
begin
  select * into v_league from leagues where id = p_league;
  if not found then raise exception 'That league no longer exists.'; end if;

  -- identity at the database, never by hiding a button (D37)
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro can lock the bylaws.';
  end if;

  -- Already locked? Return the standing truth. This is the whole point of the
  -- function: the client can call it again after any ambiguous failure and
  -- learn what actually happened instead of guessing.
  select * into v_settings from league_settings where league_id = p_league;
  if v_settings.locked_at is not null then
    select * into v_season from seasons where league_id = p_league and number = 1;
    return json_build_object(
      'already_locked', true,
      'phase',  v_league.phase,
      'season', row_to_json(v_season));
  end if;

  -- D143 · the season window is the truth; season_months only DESCRIBES it.
  -- The two used to be independent inputs, so a 2-week season stored "3 months"
  -- (the client clamps to the old 3..12 CHECK) and nothing complained. Now one
  -- of them is authoritative: if the caller gives dates, the months are derived
  -- from them; if it does not, the end date is derived from the months. They can
  -- no longer disagree.
  v_starts := coalesce(p_starts_on, current_date);
  if p_ends_on is not null then
    v_ends := p_ends_on;
  else
    v_ends := v_starts + (coalesce(p_season_months, 6) * 30.44)::int - 1;
  end if;
  v_months := greatest(1, least(12, round((v_ends - v_starts + 1) / 30.44::numeric)::int));

  update league_settings set
    preset              = coalesce(p_preset, preset),
    handicap_allowance  = coalesce(p_handicap_allowance, handicap_allowance),
    verification        = coalesce(p_verification, verification),
    counting_cap        = coalesce(p_counting_cap, counting_cap),
    participation_floor = coalesce(p_participation_floor, participation_floor),
    floor_penalty       = coalesce(p_floor_penalty, floor_penalty),
    season_format       = coalesce(p_season_format, season_format),
    structure           = coalesce(p_structure, structure),
    buyin_cents         = coalesce(p_buyin_cents, buyin_cents),
    season_months       = v_months,
    draft_type          = coalesce(p_draft_type, draft_type),
    finish              = coalesce(p_finish, finish),
    payout_champ        = coalesce(p_payout_champ, payout_champ),
    payout_runnerup     = coalesce(p_payout_runnerup, payout_runnerup),
    payout_king         = coalesce(p_payout_king, payout_king),
    locked_at           = now()
  where league_id = p_league
  returning * into v_settings;

  -- season 1, reusing any row a partial lock already created
  select * into v_season from seasons where league_id = p_league and number = 1;
  if not found then
    insert into seasons (league_id, number, starts_on, ends_on)
    values (p_league, 1, v_starts, v_ends)
    returning * into v_season;
  end if;

  -- squads exist from the lock; members join, then the draw fills them.
  -- form_squads is itself idempotent and returns early for solo.
  if v_settings.structure <> 'solo' then
    perform form_squads(v_season.id);
  end if;

  -- The phase comes from the STORED structure, not from what the caller
  -- claimed: a client that mis-sends the structure cannot put the league in a
  -- phase its squads do not match (the §15 violation that reached prod).
  v_phase := case when v_settings.structure = 'solo' then 'season' else 'draft' end;

  update leagues
     set phase = v_phase,
         name  = coalesce(nullif(btrim(p_name), ''), name)
   where id = p_league
  returning * into v_league;

  -- D204 · the lock is acknowledged in every structure. Solo used to get the
  -- join line and then silence until a clash post.
  insert into posts (league_id, season_id, kind, body)
  values (p_league, v_season.id, 'system',
          'Bylaws locked. First tee ' || to_char(v_season.starts_on, 'Dy Mon FMDD')
          || ' · ' || initcap(v_settings.preset)
          || case when v_settings.counting_cap is not null
                  then ' · best ' || v_settings.counting_cap || ' a month.'
                  else ' · every round counts.' end);

  return json_build_object(
    'already_locked', false,
    'phase',  v_phase,
    'season', row_to_json(v_season));
end $function$;

revoke all on function public.lock_league(uuid, text, text, integer, text, integer, integer, text, text, text, integer, integer, text, text, integer, integer, integer, date, date) from public, anon;
grant execute on function public.lock_league(uuid, text, text, integer, text, integer, integer, text, text, text, integer, integer, text, text, integer, integer, integer, date, date) to authenticated;

-- ── 4 · the roster line follows the calendar ────────────────────────────────
-- "Rosters locked. The season is live. Post a round." was posted whatever the
-- date, so a league drafting three weeks ahead of its first tee was told play
-- had begun. Bodies = prod 2026-09-02 verbatim; only the one string is chosen
-- by the league-local date. The horn (section 1) says "live" on the day.
-- ONE further departure, named: the Pro guard's raise message was
-- 'commissioner only' — the word brand canon §3 bans on anything a golfer
-- reads, and it reaches them as an error toast. It becomes "Only the Pro can
-- start the season.", matching lock_league's own guard in this same file.
-- (`form_squads` in prod still carries the old string; out of scope here.)
create or replace function public.start_season(p_season uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare se record; st record; loose int; total int; empty_sq text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  -- brand canon §3: "The Pro", never "commissioner", on anything a golfer
  -- reads. This string reaches them as an error toast; the same file already
  -- says "Only the Pro can lock the bylaws." for the identical guard.
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can start the season.'; end if;

  if st.structure <> 'solo' then
    select count(*) into total from league_members lm where lm.league_id = se.league_id;
    if total < 4 then
      raise exception 'Minimum four to tee off — % in so far. Share the invite link.', total;
    end if;

    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% golfer(s) still in the pool — everyone needs a squad before the first tee', loose;
    end if;

    select q.name into empty_sq
    from squads q left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id, q.name having count(sm.member_id) = 0 limit 1;
    if empty_sq is not null then
      raise exception '% is empty — draw again or assign somebody before the season starts', empty_sq;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          case when se.starts_on > (now() at time zone se.timezone)::date
               then 'Rosters locked. First tee ' || to_char(se.starts_on, 'Dy Mon FMDD') || '.'
               else 'Rosters locked. The season is live. Post a round.' end);
end $function$;

revoke all on function public.start_season(uuid) from public, anon;
grant execute on function public.start_season(uuid) to authenticated;

create or replace function public.make_pick(p_draft uuid, p_member uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare d record; se record; n_sq int; rd int; idx int;
        squad uuid; me uuid; is_c boolean; cap uuid;
begin
  select * into d from drafts where id = p_draft for update;
  if d.status <> 'live' then raise exception 'draft is not live'; end if;
  select * into se from seasons where id = d.season_id;

  me   := my_member_id(se.league_id);
  is_c := is_commissioner(se.league_id);
  if me is null then raise exception 'not a league member'; end if;

  n_sq := array_length(d.order_squads, 1);
  rd   := (d.current_pick / n_sq) + 1;                      -- 1-indexed round
  idx  := d.current_pick % n_sq;
  -- snake: even rounds reverse
  if rd % 2 = 0 then idx := n_sq - 1 - idx; end if;
  squad := d.order_squads[idx + 1];

  select captain_member_id into cap from squads where id = squad;
  if not is_c and cap is distinct from me then
    raise exception 'not your pick';
  end if;

  if d.current_pick >= n_sq * d.rounds_count then
    raise exception 'draft is full';
  end if;

  insert into draft_picks
    (draft_id, pick_number, round_number, squad_id, member_id, picked_by, via_override)
  values (p_draft, d.current_pick, rd, squad, p_member, me, is_c and cap is distinct from me);

  insert into squad_members (squad_id, member_id, drafted_round, pick_number)
  values (squad, p_member, rd, d.current_pick);

  update drafts set current_pick = current_pick + 1 where id = p_draft;

  insert into posts (league_id, season_id, kind, body)
  select se.league_id, d.season_id, 'system',
         s.name || ' take ' || firstname(p.display_name)
         || ' with pick ' || (d.current_pick + 1) || '.'
  from squads s, league_members lm join profiles p on p.id = lm.profile_id
  where s.id = squad and lm.id = p_member;

  if is_c and cap is distinct from me then
    insert into commissioner_log (league_id, actor_id, action, detail)
    values (se.league_id, me, 'draft_pick_override',
            jsonb_build_object('squad', squad, 'member', p_member));
  end if;

  -- last pick closes the draft and opens the season
  if (select current_pick from drafts where id = p_draft) >= n_sq * d.rounds_count then
    update drafts  set status = 'complete', completed_at = now() where id = p_draft;
    update leagues set phase = 'season' where id = se.league_id;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, d.season_id, 'system',
            case when se.starts_on > (now() at time zone se.timezone)::date
                 then 'Rosters locked. First tee ' || to_char(se.starts_on, 'Dy Mon FMDD') || '.'
                 else 'Rosters locked. The season is live. Post a round.' end);
  end if;
end $function$;

revoke all on function public.make_pick(uuid, uuid) from public, anon;
grant execute on function public.make_pick(uuid, uuid) to authenticated;

-- ── 5 · self-check ──────────────────────────────────────────────────────────
do $chk$
declare v_src text; v_n integer;
begin
  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'daily_season_tick';
  if v_src not like '%not se.kicked_off%' or v_src not like '%The season is live. Week 1 — counting rounds start now.%' then
    raise exception '[D204] daily_season_tick has no first-tee horn';
  end if;
  -- the D176 body survived the rewrite
  if v_src not like '%perform clash_last_call(se.id)%' or v_src not like '%perform enter_cup_final(se.id)%'
     or v_src not like '%perform close_season(se.id)%' or v_src not like '%perform open_week_clash(se.id)%'
     or v_src not like '%set status = ''abandoned''%' then
    raise exception '[D204] daily_season_tick lost part of the D176 body';
  end if;

  -- no season that has started is still waiting for a horn it will never get
  select count(*) into v_n from public.seasons
   where status in ('active', 'cup_final') and starts_on <= current_date and not kicked_off;
  if v_n > 0 then
    raise exception '[D204] % started season(s) still kicked_off = false', v_n;
  end if;

  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'lock_league';
  if v_src not like '%Bylaws locked. First tee %' then
    raise exception '[D204] lock_league posts nothing';
  end if;

  for v_src in
    select p.prosrc from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname in ('start_season', 'make_pick')
  loop
    if v_src not like '%Rosters locked. First tee %' or v_src not like '%Rosters locked. The season is live. Post a round.%' then
      raise exception '[D204] start_season / make_pick do not follow the calendar';
    end if;
  end loop;

  -- the engine stays off the API surface; the three the client calls stay on it
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname = 'daily_season_tick'
                and has_function_privilege('authenticated', p.oid, 'execute')) then
    raise exception '[D204] daily_season_tick is reachable by authenticated';
  end if;
  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname in ('lock_league', 'start_season', 'make_pick')
     and has_function_privilege('authenticated', p.oid, 'execute');
  if v_n <> 3 then
    raise exception '[D204] lock_league / start_season / make_pick grants: % of 3', v_n;
  end if;
end $chk$;
