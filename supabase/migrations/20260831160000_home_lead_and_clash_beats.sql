-- D176 · the lead card's data, and the clash gets its missing beats.
--
-- Three things, one file, because they are one idea: the clash is a duel
-- announced to an empty room. `open_week_clash` names two people and stops —
-- no stakes, no deadline, and the two named are never told they were named.
--
--   1. the OPEN post carries the stakes and the clock
--   2. `clash_last_call` — the final day of the window, on the board
--   3. `home_clash` — the same facts, for the lead card on the two golfers' Home
--
-- The settle side is already good and is left alone but for the all-square
-- line, which stated the pairing again instead of the result.

-- ── 1 · the open post ───────────────────────────────────────────────────────
-- D165 de-shouted this; it still said only who. "Best round of the week takes
-- it" is the whole mechanic in six words, and a named rivalry (D21) earns the
-- name in the headline — it is the one line all season where it belongs.

create or replace function public.open_week_clash(p_season uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  se       record;
  v_local  date;
  v_wk     integer;
  v_total  integer;
  v_a      uuid;   -- league_members.id
  v_b      uuid;
  v_id     uuid;
  v_a_name text;
  v_b_name text;
  v_riv    text;
  v_end    date;
begin
  select * into se from seasons where id = p_season;
  if se.id is null or se.status not in ('active','cup_final') then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;
  if v_local < se.starts_on or v_local > se.ends_on then
    return null;                                   -- no clash outside the season
  end if;

  v_total := ceil((se.ends_on - se.starts_on + 1) / 7.0);
  v_wk    := floor((v_local - se.starts_on) / 7)::int + 1;
  if v_wk < 1 or v_wk > v_total then
    return null;
  end if;

  -- idempotent: this week's clash already stands
  select id into v_id from week_clashes
   where season_id = p_season and week_no = v_wk;
  if v_id is not null then
    return v_id;
  end if;

  -- the pairing (see header for the cascade + rotation-guarantee reasoning)
  with mem as (            -- active members: on the roster, not tombstoned
    select lm.id, lm.profile_id, p.display_name
      from league_members lm
      join profiles p on p.id = lm.profile_id and p.deleted_at is null
     where lm.league_id = se.league_id
  ),
  feat as (                -- each member's most recent spotlight week
    select m.id, max(wc.week_no) as last_wk
      from mem m
      join week_clashes wc
        on wc.season_id = p_season
       and (wc.a_member = m.id or wc.b_member = m.id)
     group by m.id
  ),
  stand as (
    select member_id, points from v_individual_standings
     where season_id = p_season
  ),
  pairs as (
    select a.id as a_id, b.id as b_id,
           a.display_name as a_name, b.display_name as b_name,
           greatest(coalesce(fa.last_wk, 0), coalesce(fb.last_wk, 0)) as staleness,
           exists (select 1 from rivalry_names rn
                    where rn.pair_low  = least(a.profile_id, b.profile_id)
                      and rn.pair_high = greatest(a.profile_id, b.profile_id)) as named,
           abs(coalesce(sa.points, 0) - coalesce(sb.points, 0)) as gap,
           a.profile_id as a_pid, b.profile_id as b_pid
      from mem a
      join mem b on a.id < b.id
      left join feat  fa on fa.id = a.id
      left join feat  fb on fb.id = b.id
      left join stand sa on sa.member_id = a.id
      left join stand sb on sb.member_id = b.id
  ),
  pick as (
    select * from pairs
     order by staleness asc,        -- rotation guarantee: the most-due pair first
              named desc,           -- then D52's cascade: named rivalry (D21)
              gap asc,              -- → closest table gap
              a_id, b_id            -- → deterministic
     limit 1
  )
  select p.a_id, p.b_id, p.a_name, p.b_name,
         (select rn.name from rivalry_names rn
           where rn.pair_low  = least(p.a_pid, p.b_pid)
             and rn.pair_high = greatest(p.a_pid, p.b_pid))
    into v_a, v_b, v_a_name, v_b_name, v_riv
    from pick p;

  if v_a is null or v_b is null then
    return null;                                   -- solo league (<2 active) — skip
  end if;

  insert into week_clashes (season_id, week_no, a_member, b_member)
  values (p_season, v_wk, v_a, v_b)
  on conflict (season_id, week_no) do nothing
  returning id into v_id;

  if v_id is null then                             -- lost a race — take the standing row
    select id into v_id from week_clashes
     where season_id = p_season and week_no = v_wk;
    return v_id;
  end if;

  -- the open story (only when this call actually opened the week)
  v_end := se.starts_on + 7 * v_wk - 1;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          case when v_riv is not null and btrim(v_riv) <> ''
               then '“' || btrim(v_riv) || '” is on again: '
                    || firstname(v_a_name) || ' v ' || firstname(v_b_name) || '.'
               else 'The clash: ' || firstname(v_a_name) || ' v '
                    || firstname(v_b_name) || '.' end
          || ' Best round of the week takes it.');

  return v_id;
end $function$;

revoke execute on function public.open_week_clash(uuid) from public, anon;

-- ── 2 · last call ───────────────────────────────────────────────────────────
-- The owner's own instinct, and the beat the mechanic was missing: a duel with
-- a deadline nobody states is a coin flip nobody entered. Fires on the FINAL
-- day of the window only, once, and says what each side actually has.
--
-- "today", never "tonight" — the window closes at the end of the calendar day
-- and hardly anyone plays golf at night (owner ruling, D176).
--
-- Idempotent on its own post: the guard looks for a last-call already written
-- for this league and season today, so a re-run or a second tick writes
-- nothing. Silent when both sides are idle AND the week is dead anyway? No —
-- both idle is exactly when the nudge is worth the most. Silent only when the
-- clash is already settled or does not exist.

create or replace function public.clash_last_call(p_season uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  se       record;
  wc       record;
  v_local  date;
  v_ws     date;
  v_we     date;
  v_cap    integer;
  v_a_pts  numeric;
  v_b_pts  numeric;
  v_a_pvi  numeric;
  v_b_pvi  numeric;
  v_a_name text;
  v_b_name text;
  v_body   text;
  v_id     uuid;
begin
  select * into se from seasons where id = p_season;
  if se.id is null or se.status not in ('active','cup_final') then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;

  -- the open, unsettled clash whose window ENDS today
  select * into wc from week_clashes
   where season_id = p_season and settled_at is null
     and (se.starts_on + 7 * (week_no - 1) + 6) = v_local
   order by week_no desc limit 1;
  if wc.id is null then
    return null;
  end if;

  v_ws := se.starts_on + 7 * (wc.week_no - 1);
  v_we := v_ws + 6;

  -- already said it today
  select id into v_id from posts
   where league_id = se.league_id and season_id = p_season and kind = 'system'
     and body like 'The clash closes today%'
     and (created_at at time zone se.timezone)::date = v_local
   limit 1;
  if v_id is not null then
    return v_id;
  end if;

  select counting_cap into v_cap from league_settings where league_id = se.league_id;

  -- each side's best so far — the settle's own pick, so the nudge and the
  -- result can never disagree
  select rr.points, rr.pvi into v_a_pts, v_a_pvi
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select rr.points, rr.pvi into v_b_pts, v_b_pvi
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select p.display_name into v_a_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.a_member;
  select p.display_name into v_b_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.b_member;

  v_body := case
    when v_a_pts is null and v_b_pts is null then
      'The clash closes today. Neither of them has posted.'
    when v_b_pts is null then
      'The clash closes today. ' || firstname(v_a_name) || ' has answered. '
        || firstname(v_b_name) || ' has not.'
    when v_a_pts is null then
      'The clash closes today. ' || firstname(v_b_name) || ' has answered. '
        || firstname(v_a_name) || ' has not.'
    when v_a_pts > v_b_pts then
      'The clash closes today. ' || firstname(v_a_name)
        || ' leads it. One round to change that.'
    when v_b_pts > v_a_pts then
      'The clash closes today. ' || firstname(v_b_name)
        || ' leads it. One round to change that.'
    else
      'The clash closes today. ' || firstname(v_a_name) || ' and '
        || firstname(v_b_name) || ' are level.' end;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_body)
  returning id into v_id;
  return v_id;
end $function$;

revoke execute on function public.clash_last_call(uuid) from public, anon;

-- ── 3 · the tick calls it ───────────────────────────────────────────────────

create or replace function public.daily_season_tick()
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare se record; v_finish text; v_local date; wcr record;
begin
  -- live rounds die on their own now: 24h after start, an unfinished round is
  -- abandoned — resume and join surfaces go dark server-side, not just client.
  update live_rounds
     set status = 'abandoned', finished_at = coalesce(finished_at, now())
   where status in ('setup', 'live')
     and started_at < now() - interval '24 hours';

  for se in select * from seasons where status in ('active','cup_final')
  loop
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

revoke execute on function public.daily_season_tick() from public, anon;

-- ── 4 · all square states the RESULT, not the pairing again ─────────────────
-- "All square in the clash — Galen v Jerecho." reads like a second
-- announcement. The week ended; say what happened to it.

create or replace function public.settle_week_clash(p_season uuid, p_week integer)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  wc       record;
  se       record;
  v_cap    integer;
  v_ws     date;                                   -- week window start / end
  v_we     date;
  v_a_best jsonb;
  v_b_best jsonb;
  v_winner uuid;
  v_win_b  jsonb;
  v_name   text;
  v_a_name text;
  v_b_name text;
  v_pvi    numeric;
  v_phrase text;
  v_run    integer;
begin
  select * into wc from week_clashes
   where season_id = p_season and week_no = p_week
   for update;
  if wc.id is null or wc.settled_at is not null then
    return null;                                   -- nothing open here — idempotent
  end if;

  select * into se from seasons where id = p_season;
  select counting_cap into v_cap from league_settings where league_id = se.league_id;
  v_ws := se.starts_on + 7 * (p_week - 1);
  v_we := v_ws + 6;

  -- each side's best band-of-week: highest-points COUNTING round in the window
  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case when rr.pvi >= 3  then 'Torched it'
                        when rr.pvi >= 1  then 'Beat your number'
                        when rr.pvi >= -1 then 'Played to it'
                        when rr.pvi >= -3 then 'A little loose'
                        else 'Posted anyway' end)
    into v_a_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case when rr.pvi >= 3  then 'Torched it'
                        when rr.pvi >= 1  then 'Beat your number'
                        when rr.pvi >= -1 then 'Played to it'
                        when rr.pvi >= -3 then 'A little loose'
                        else 'Posted anyway' end)
    into v_b_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  -- the band decides the W; equal bands are ALL SQUARE (D2: named bands, not
  -- raw differential); one side idle is a walkover W; both idle is quiet.
  if v_a_best is null and v_b_best is null then
    v_winner := null;
  elsif v_b_best is null
     or (v_a_best is not null
         and (v_a_best->>'points')::int > (v_b_best->>'points')::int) then
    v_winner := wc.a_member; v_win_b := v_a_best;
  elsif v_a_best is null
     or (v_b_best->>'points')::int > (v_a_best->>'points')::int then
    v_winner := wc.b_member; v_win_b := v_b_best;
  else
    v_winner := null;                              -- both posted, same band
  end if;

  update week_clashes
     set settled_at = now(), winner_member = v_winner,
         a_best = v_a_best, b_best = v_b_best
   where id = wc.id;

  select p.display_name into v_a_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.a_member;
  select p.display_name into v_b_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.b_member;

  if v_winner is not null then
    v_name := case when v_winner = wc.a_member then v_a_name else v_b_name end;
    v_pvi  := (v_win_b->>'pvi')::numeric;
    v_phrase := case
      when v_pvi >= 1  then 'beat their number by ' || to_char(v_pvi, 'FM990.0')
      when v_pvi >= -1 then 'played to their number'
      else to_char(abs(v_pvi), 'FM990.0') || ' over their number' end;
    insert into posts (league_id, season_id, kind, round_id, body)
    values (se.league_id, p_season, 'system', (v_win_b->>'round_id')::uuid,
            firstname(v_name) || ' took the week — ' || v_phrase
            || ' on ' || to_char((v_win_b->>'played_on')::date, 'FMDay') || '.');

    -- #23 · rivalry heat. The settlement headline above stays furniture; this
    -- is prose, so it is natural case. True run length, so it fires ONCE at
    -- three and once at five — never every week thereafter.
    with hist as (
      select wc2.winner_member,
             row_number() over (order by wc2.week_no desc) as rn
        from week_clashes wc2
       where wc2.season_id = p_season and wc2.settled_at is not null
         and (wc2.a_member = v_winner or wc2.b_member = v_winner)
    )
    select coalesce(min(h.rn) - 1, (select count(*) from hist))
      into v_run
      from hist h
     where h.winner_member is distinct from v_winner;
    if v_run = 3 then
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, p_season, 'moment',
              'Three clashes in a row to ' || firstname(v_name)
              || '. This is becoming a problem.');
    elsif v_run = 5 then
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, p_season, 'moment',
              'Five straight for ' || firstname(v_name) || '. Annoyingly good.');
    end if;
  elsif v_a_best is not null or v_b_best is not null then
    -- D176 · the week ended; say what happened to it, don't re-announce it
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system', 'All square in the clash. Nothing settled.');
  end if;
  -- both idle: row settled above, no post (D52's honesty rule).

  return jsonb_build_object(
    'week', p_week, 'winner_member', v_winner,
    'a_best', v_a_best, 'b_best', v_b_best);
end $function$;

revoke execute on function public.settle_week_clash(uuid, integer) from public, anon;

-- ── 5 · the lead card's clash rung ──────────────────────────────────────────
-- Home does not load `v_rounds_ranked` (the Clubhouse does), so computing
-- "best so far" on the phone would mean a second, heavier read AND a second
-- implementation of the settle's pick. One RPC instead: the card and the
-- settlement agree by construction, and there is no PostgREST embed to
-- disambiguate (`week_clashes` has TWO fk paths to `league_members` — a_member
-- and b_member — which is the D171 trap exactly).
--
-- Returns null unless the caller is IN this week's open clash. A clash you are
-- not in belongs on the board, not on your Home (D176 ruling).

create or replace function public.home_clash(p_league uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me     uuid;
  se       record;
  wc       record;
  v_local  date;
  v_ws     date;
  v_we     date;
  v_cap    integer;
  v_them   uuid;
  v_mine   jsonb;
  v_theirs jsonb;
  v_name   text;
  v_marker text;
begin
  if not is_league_member(p_league) then
    return null;
  end if;
  v_me := my_member_id(p_league);
  if v_me is null then
    return null;
  end if;

  select * into se from seasons
   where league_id = p_league and status in ('active','cup_final')
   order by starts_on desc limit 1;
  if se.id is null then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;

  select * into wc from week_clashes
   where season_id = se.id and settled_at is null
     and (a_member = v_me or b_member = v_me)
     and (se.starts_on + 7 * (week_no - 1)) <= v_local
     and (se.starts_on + 7 * (week_no - 1) + 6) >= v_local
   order by week_no desc limit 1;
  if wc.id is null then
    return null;
  end if;

  v_ws   := se.starts_on + 7 * (wc.week_no - 1);
  v_we   := v_ws + 6;
  v_them := case when wc.a_member = v_me then wc.b_member else wc.a_member end;

  select counting_cap into v_cap from league_settings where league_id = p_league;

  -- `v_rounds_ranked` carries no gross (it is the SCORING lens), so the round
  -- itself supplies the number a golfer recognises on a card.
  select jsonb_build_object('round_id', rr.round_id, 'played_on', rr.played_on,
                            'points', rr.points, 'pvi', rr.pvi, 'gross', r.gross)
    into v_mine
    from v_rounds_ranked rr
    join rounds r on r.id = rr.round_id
   where rr.season_id = se.id and rr.member_id = v_me
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select jsonb_build_object('round_id', rr.round_id, 'played_on', rr.played_on,
                            'points', rr.points, 'pvi', rr.pvi, 'gross', r.gross)
    into v_theirs
    from v_rounds_ranked rr
    join rounds r on r.id = rr.round_id
   where rr.season_id = se.id and rr.member_id = v_them
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select p.display_name, coalesce(lm.marker, p.marker) into v_name, v_marker
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = v_them;

  return jsonb_build_object(
    'week_no',      wc.week_no,
    'ends_on',      v_we,
    'days_left',    (v_we - v_local),
    'closes_today', (v_we = v_local),
    'them_name',    v_name,
    'them_marker',  v_marker,
    'mine',         v_mine,
    'theirs',       v_theirs,
    'rivalry',      (select rn.name from rivalry_names rn
                      join league_members la on la.id = wc.a_member
                      join league_members lb on lb.id = wc.b_member
                     where rn.pair_low  = least(la.profile_id, lb.profile_id)
                       and rn.pair_high = greatest(la.profile_id, lb.profile_id)));
end $function$;

revoke execute on function public.home_clash(uuid) from public, anon;
grant execute on function public.home_clash(uuid) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_n int; v_body text;
begin
  -- the open post must carry the mechanic, not just the names
  if exists (select 1 from pg_proc where proname = 'open_week_clash'
              and pg_get_functiondef(oid) not like '%Best round of the week takes it%') then
    raise exception 'D176: open_week_clash lost its stakes line';
  end if;

  -- "today", never "tonight" (owner ruling)
  if exists (select 1 from pg_proc where proname = 'clash_last_call'
              and pg_get_functiondef(oid) ilike '%tonight%') then
    raise exception 'D176: last call says tonight — golf is played in daylight';
  end if;

  -- the tick must actually call it, or the beat never fires
  if not exists (select 1 from pg_proc where proname = 'daily_season_tick'
                  and pg_get_functiondef(oid) like '%clash_last_call%') then
    raise exception 'D176: daily_season_tick does not call clash_last_call';
  end if;

  -- D37: the one client-called function is granted, the cron-only ones are not
  if not has_function_privilege('authenticated', 'public.home_clash(uuid)', 'execute') then
    raise exception 'D37: home_clash is not executable by authenticated';
  end if;
  if has_function_privilege('anon', 'public.home_clash(uuid)', 'execute')
     or has_function_privilege('anon', 'public.clash_last_call(uuid)', 'execute')
     or has_function_privilege('anon', 'public.open_week_clash(uuid)', 'execute') then
    raise exception 'D37: a clash function is reachable by anon';
  end if;

  -- and the shape holds: a caller with no clash gets NULL, never an error
  select count(*) into v_n from pg_proc where proname in
    ('home_clash','clash_last_call','open_week_clash','settle_week_clash','daily_season_tick');
  if v_n <> 5 then
    raise exception 'D176: expected 5 clash functions, found %', v_n;
  end if;
end $chk$;
