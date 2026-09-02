-- ============================================================================
-- Cup Season — the clash stops repeating itself at two, and "idle" means no
-- round (D207) · the Final's small print and a King ranked on the ladder (D212)
--
-- With two members the pairing is the same two names every week, and the
-- open and the last call fired whether or not either had played — an idle
-- two-person league collects ~104 posts a season about nothing. D52's
-- honesty rule ("both idle settles quiet") stopped at the settle. And at the
-- settle, a member counted as idle when none of their rounds in the window
-- sat at `month_rank <= counting_cap`; under Best 3 that is most late-month
-- weeks, so a golfer who played twice could lose by walkover. The band label
-- was a hand copy of cup_points() with a different edge at exactly −1.0.
--
-- D212: the Final receipt says the calendar cap still applies inside the
-- window; the crown post says "months won this season"; the Points King is
-- ranked on the same ladder as the Cup (D126 (5), unbuilt until now) and the
-- rung that decided it is stored like tiebreak_rung.
--
-- Read out of prod on 2026-09-02: week_clashes = 8, both from two-person solo
-- leagues. seasons has no king_rung. score_round(7 args) — the preview — is
-- granted to authenticated and nothing calls it: not the web (comments only),
-- not the phone (a generated struct with no call site), not the database.
--
-- "Idle" everywhere below = no row in v_rounds_ranked for the member inside
-- the window. The view already excludes voided rounds and applies the
-- league's own rules (sim / nine-hole allowances, suspension), so the three
-- clash beats read the same rounds the ledger does.
--
--   1 · open_week_clash — the row always, the post only when it says something
--   2 · clash_last_call — only when at least one of them has played
--   3 · settle_week_clash — no cap filter; the band through cup_points()
--   4 · the unused score_round preview leaves the API surface
--   5 · close_season — the King on the ladder, king_rung stored and printed
--   6 · cup_final_race — the cap line on the receipt
--   7 · self-check
-- ============================================================================

-- ── 1 · the open post ───────────────────────────────────────────────────────
-- Body = prod 2026-09-02 (20260831160000, D176) verbatim through the row
-- insert. The post is then chosen: the first week of a two-member roster
-- says so (a named rivalry keeps its headline); every later week is
-- suppressed when the pairing is unchanged from last week AND both were idle
-- in last week's window. The row is still written — the clash exists; the
-- board does not repeat it.
create or replace function public.open_week_clash(p_season uuid)
returns uuid
language plpgsql
security definer
set search_path = public
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
  v_roster integer;
  v_same   boolean := false;
  v_quiet  boolean := false;
  v_lws    date;
  v_lwe    date;
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

  -- D207 · is there anything to say? The active roster size, whether last
  -- week paired the same two, and whether either of them played last week.
  -- 20260902100000 gave league_members a `suspended_at`; a suspended member
  -- cannot post, so they are not part of the roster this question asks about.
  -- (The pairing CTE above still ignores suspension — a prod gap named in the
  -- header, not closed here.)
  select count(*) into v_roster
    from league_members lm
    join profiles p on p.id = lm.profile_id and p.deleted_at is null
   where lm.league_id = se.league_id
     and lm.suspended_at is null;

  if v_wk > 1 then
    v_lws := se.starts_on + 7 * (v_wk - 2);
    v_lwe := v_lws + 6;
    select true into v_same from week_clashes wc
     where wc.season_id = p_season and wc.week_no = v_wk - 1
       and least(wc.a_member, wc.b_member) = least(v_a, v_b)
       and greatest(wc.a_member, wc.b_member) = greatest(v_a, v_b);
    v_same := coalesce(v_same, false);
    if v_same then
      v_quiet := not exists (
        select 1 from v_rounds_ranked rr
         where rr.season_id = p_season
           and rr.member_id in (v_a, v_b)
           and rr.played_on between v_lws and v_lwe);
    end if;
  end if;

  if v_same and v_quiet then
    return v_id;                                   -- the row stands; the board stays quiet
  end if;

  -- the open story (only when this call actually opened the week)
  v_end := se.starts_on + 7 * v_wk - 1;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          case
            when v_wk = 1 and v_roster = 2 then
              case when v_riv is not null and btrim(v_riv) <> ''
                   then '“' || btrim(v_riv) || '” is on again: '
                        || firstname(v_a_name) || ' v ' || firstname(v_b_name) || '. '
                   else '' end
              || 'It''s the two of you — every week is the clash.'
            when v_riv is not null and btrim(v_riv) <> '' then
              '“' || btrim(v_riv) || '” is on again: '
              || firstname(v_a_name) || ' v ' || firstname(v_b_name) || '.'
              || ' Best round of the week takes it.'
            else
              'The clash: ' || firstname(v_a_name) || ' v '
              || firstname(v_b_name) || '.'
              || ' Best round of the week takes it.'
          end);

  return v_id;
end $function$;

revoke all on function public.open_week_clash(uuid) from public, anon, authenticated;

-- ── 2 · last call ───────────────────────────────────────────────────────────
-- Body = prod verbatim; two changes. The best-so-far picks lose the
-- `month_rank <= cap` filter so they stay the settle's own pick (section 3);
-- and when neither side has a round in the window the function returns
-- without posting — "Neither of them has posted" was the sentence an idle
-- two-person league read every week.
create or replace function public.clash_last_call(p_season uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $function$
declare
  se       record;
  wc       record;
  v_local  date;
  v_ws     date;
  v_we     date;
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

  -- each side's best so far — the settle's own pick, so the nudge and the
  -- result can never disagree (D207: every round in the window, not only
  -- the ones the calendar cap will keep)
  select rr.points, rr.pvi into v_a_pts, v_a_pvi
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select rr.points, rr.pvi into v_b_pts, v_b_pvi
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  -- D207 · nobody has played: nothing to call. Quiet, like the settle.
  if v_a_pts is null and v_b_pts is null then
    return null;
  end if;

  select p.display_name into v_a_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.a_member;
  select p.display_name into v_b_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.b_member;

  v_body := case
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

revoke all on function public.clash_last_call(uuid) from public, anon, authenticated;

-- ── 3 · the settle ──────────────────────────────────────────────────────────
-- Body = prod verbatim minus the `month_rank <= cap` filter (and the cap
-- variable it served); the band label and the winner's phrase read the band
-- through cup_points(), so −1.0 lands where the receipt says it does. No cup
-- points move here (D108 unchanged).
create or replace function public.settle_week_clash(p_season uuid, p_week integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  wc       record;
  se       record;
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
  v_ws := se.starts_on + 7 * (p_week - 1);
  v_we := v_ws + 6;

  -- each side's best band-of-week: highest-points round in the window. D207:
  -- idle means no round in the window, not no COUNTING round — a golfer who
  -- played is never a walkover, whatever the calendar cap later kept.
  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case cup_points(rr.pvi)
                        when 12 then 'Torched it'
                        when 9  then 'Beat your number'
                        when 7  then 'Played to it'
                        when 6  then 'A little loose'
                        else 'Posted anyway' end)
    into v_a_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case cup_points(rr.pvi)
                        when 12 then 'Torched it'
                        when 9  then 'Beat your number'
                        when 7  then 'Played to it'
                        when 6  then 'A little loose'
                        else 'Posted anyway' end)
    into v_b_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
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
    v_phrase := case cup_points(v_pvi)
      when 12 then 'beat their number by ' || to_char(v_pvi, 'FM990.0')
      when 9  then 'beat their number by ' || to_char(v_pvi, 'FM990.0')
      when 7  then 'played to their number'
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

revoke all on function public.settle_week_clash(uuid, integer) from public, anon, authenticated;

-- ── 4 · the preview nobody calls ────────────────────────────────────────────
-- score_round(7 args) is an invoker-rights pure function granted to
-- authenticated; neither client calls it and no database function references
-- it. It leaves the API surface (D37: a grant nobody uses is a door nobody
-- watches). Kept as a function — revoke, not drop — so nothing that might
-- still name it in a stale bundle gets a 404 instead of a 42501.
revoke all on function public.score_round(integer, numeric, integer, numeric, numeric, integer, integer)
  from public, anon, authenticated;

-- ── 5 · the King on the ladder ──────────────────────────────────────────────
alter table public.seasons add column if not exists king_rung text;
comment on column public.seasons.king_rung is
  'D212 / D126 (5) · the tiebreak rung that decided the Points King when the '
  'top two were level on points: months won · best single month · fewest '
  'rounds used · coin flip. Null when points alone decided it. Stored like '
  'tiebreak_rung.';

-- Body = prod 2026-09-02 verbatim, with the King chosen from a `_king` table
-- built on the same ladder as `_ranked` (score · months won · best month ·
-- fewest rounds used · coin), the rung stored, and the crown post printing
-- both rungs with the scope D212 asks for.
create or replace function public.close_season(p_season uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare
  se record; st record; king uuid;
  v_solo boolean; v_finalists boolean; v_cup boolean;
  cap_n integer; cf_start date;
  c1 record; c2 record;
  k1 record; k2 record; v_king_rung text := null;
  v_rung text := null; v_story text; v_score1 text; v_score2 text;
  v_kname text; v_champname text; v_runname text;
  v_money jsonb; v_owed_names text; v_pot_line text;
  v_last record; v_lastname text; v_field integer;
begin
  select * into se from seasons where id = p_season;
  if se.status = 'complete' then return; end if;              -- idempotent
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (st.structure = 'solo');
  cap_n := coalesce(st.counting_cap, 10000);
  cf_start := se.ends_on - 27;
  v_finalists := exists (select 1 from cup_finalists where season_id = p_season);
  v_cup := coalesce(st.finish,'cup_final') = 'cup_final' and v_finalists;

  drop table if exists _cont; drop table if exists _ranked; drop table if exists _king;
  create temp table _cont (
    cid uuid, member_id uuid, head numeric default 0
  ) on commit drop;

  if v_cup then
    if v_solo then
      insert into _cont select cf.member_id, cf.member_id, coalesce(cf.head_start,0)
        from cup_finalists cf where cf.season_id = p_season and cf.member_id is not null;
    else
      insert into _cont select cf.squad_id, sm.member_id, coalesce(cf.head_start,0)
        from cup_finalists cf
        join squad_members sm on sm.squad_id = cf.squad_id
       where cf.season_id = p_season and cf.squad_id is not null;
    end if;
  else
    if v_solo then
      insert into _cont select ist.member_id, ist.member_id, 0
        from v_individual_standings ist where ist.season_id = p_season;
    else
      insert into _cont select sm.squad_id, sm.member_id, 0
        from squads s join squad_members sm on sm.squad_id = s.id
       where s.season_id = p_season;
    end if;
  end if;

  create temp table _ranked (
    cid uuid, score numeric, months_won int, best_month numeric,
    rounds_used int, coin double precision
  ) on commit drop;
  insert into _ranked
  with pts as (
    -- D105: in the Final the window score is the SHARED helper — the same rows
    -- cup_final_race() shows the room, so the crown and the race cannot drift.
    select c.cid, max(c.head) + coalesce(sum(w.points), 0) as score
      from _cont c
      left join _cup_window_rounds(p_season) w on w.member_id = c.member_id
     where v_cup
     group by c.cid
    union all
    select c.cid,
           max(c.head) + coalesce(sum(rr.points) filter (where rr.month_rank <= cap_n), 0) as score
      from _cont c
      left join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
     where not v_cup
     group by c.cid
  ),
  months as (
    select c.cid, date_trunc('month', rr.played_on)::date as mon,
           sum(rr.points) as mpts
      from _cont c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n
     group by 1, 2
  ),
  months_won as (
    select m.cid, count(*) as won
      from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.cid <> m.cid), -1)
     group by m.cid
  ),
  best_month as (
    select cid, max(mpts) as best from months group by cid
  ),
  rounds_used as (
    select c.cid, count(rr.*) as used
      from _cont c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n
     group by c.cid
  )
  select p.cid, p.score,
         coalesce(w.won,0),
         coalesce(b.best,0),
         coalesce(u.used,0),
         random()
    from pts p
    left join months_won w on w.cid = p.cid
    left join best_month b on b.cid = p.cid
    left join rounds_used u on u.cid = p.cid;

  if not v_cup then
    if v_solo then
      update _ranked r set score = coalesce(
        (select i.points from v_individual_standings i
          where i.season_id = p_season and i.member_id = r.cid), 0);
    else
      update _ranked r set score = coalesce(
        (select s.points from v_squad_standings s
          where s.season_id = p_season and s.squad_id = r.cid), 0);
    end if;
  end if;

  select * into c1 from _ranked
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   limit 1;
  select * into c2 from _ranked
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   offset 1 limit 1;

  if c2.cid is not null and c1.score = c2.score then
    if c1.months_won <> c2.months_won then v_rung := 'months won';
    elsif c1.best_month <> c2.best_month then v_rung := 'best single month';
    elsif c1.rounds_used <> c2.rounds_used then v_rung := 'fewest rounds used';
    else v_rung := 'coin flip'; end if;
  end if;

  -- D212 / D126 (5) · the Points King on the same ladder, over every member
  -- of the season: season points (the standings' own number) · months won ·
  -- best single month · fewest rounds used · coin. The rung that decided a
  -- level top two is stored like tiebreak_rung.
  create temp table _king (
    member_id uuid, score numeric, months_won int, best_month numeric,
    rounds_used int, coin double precision
  ) on commit drop;
  insert into _king
  with base as (
    select ist.member_id, coalesce(ist.points, 0)::numeric as score
      from v_individual_standings ist where ist.season_id = p_season
  ),
  months as (
    select rr.member_id, date_trunc('month', rr.played_on)::date as mon,
           sum(rr.points) as mpts
      from v_rounds_ranked rr
     where rr.season_id = p_season and rr.month_rank <= cap_n
     group by 1, 2
  ),
  months_won as (
    select m.member_id, count(*) as won
      from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.member_id <> m.member_id), -1)
     group by m.member_id
  ),
  best_month as (
    select member_id, max(mpts) as best from months group by member_id
  ),
  rounds_used as (
    select rr.member_id, count(*) as used
      from v_rounds_ranked rr
     where rr.season_id = p_season and rr.month_rank <= cap_n
     group by rr.member_id
  )
  select b.member_id, b.score,
         coalesce(w.won,0),
         coalesce(bm.best,0),
         coalesce(u.used,0),
         random()
    from base b
    left join months_won w  on w.member_id  = b.member_id
    left join best_month bm on bm.member_id = b.member_id
    left join rounds_used u on u.member_id  = b.member_id;

  select * into k1 from _king
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   limit 1;
  select * into k2 from _king
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   offset 1 limit 1;
  king := k1.member_id;
  if k2.member_id is not null and k1.score = k2.score then
    if k1.months_won <> k2.months_won then v_king_rung := 'months won';
    elsif k1.best_month <> k2.best_month then v_king_rung := 'best single month';
    elsif k1.rounds_used <> k2.rounds_used then v_king_rung := 'fewest rounds used';
    else v_king_rung := 'coin flip'; end if;
  end if;

  -- D66: the deciding numbers are STORED, not just narrated
  update seasons set status = 'complete',
    champion_squad_id  = case when not v_solo then c1.cid end,
    champion_member_id = case when v_solo then c1.cid end,
    runnerup_squad_id  = case when not v_solo then c2.cid end,
    runnerup_member_id = case when v_solo then c2.cid end,
    points_king_member_id = king,
    champion_score = c1.score,
    runnerup_score = c2.score,
    tiebreak_rung  = v_rung,
    king_rung      = v_king_rung
    where id = p_season;
  update leagues set phase = 'complete' where id = se.league_id;

  if v_solo then
    select coalesce(p.display_name,'The champion') into v_champname
      from league_members lm join profiles p on p.id = lm.profile_id where lm.id = c1.cid;
    select coalesce(p.display_name,'') into v_runname
      from league_members lm join profiles p on p.id = lm.profile_id where lm.id = c2.cid;
  else
    select name into v_champname from squads where id = c1.cid;
    select name into v_runname from squads where id = c2.cid;
  end if;
  select coalesce(p.display_name,'') into v_kname
    from league_members lm join profiles p on p.id = lm.profile_id where lm.id = king;
  -- (never trim(trailing '.0') — it eats real zeros: '210.0' -> '21')
  v_score1 := case when c1.score = floor(c1.score) then c1.score::int::text else round(c1.score,1)::text end;
  v_score2 := case when c2.cid is null then null
                   when c2.score = floor(c2.score) then c2.score::int::text
                   else round(c2.score,1)::text end;

  -- D66: natural case — proper nouns survive the client's easeCaps intact.
  -- D212: "months won" is the whole season, and the post says so; the King's
  -- rung prints the same way.
  v_story := 'Season complete: ' || coalesce(v_champname,'The champion')
    || case when v_solo then ' takes' else ' take' end
    || case when v_cup then ' the Cup Final' else ' the Cup' end
    || case when v_score2 is not null then ' ' || v_score1 || '–' || v_score2 else '' end
    || case when v_rung is not null then ' · tiebreak: '
              || case v_rung when 'months won' then 'months won this season' else v_rung end
            else '' end
    || case when v_kname <> '' then ' · Points king: ' || v_kname
              || case when v_king_rung is not null then ' (tiebreak: '
                        || case v_king_rung when 'months won' then 'months won this season' else v_king_rung end
                        || ')'
                      else '' end
            else '' end;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_story);

  -- the trophies, and the money — split from what was COLLECTED (D106)
  perform award_season_trophies(p_season);

  -- the pot line: tracked, never held (§14.4 — the settlement is a post)
  select jsonb_build_object(
           'pot_cents', s.pot_cents, 'collected_cents', s.collected_cents,
           'champ',  coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Cup champion'), 0),
           'runner', coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Runner-up'), 0),
           'king',   coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Points king'), 0))
    into v_money from seasons s where s.id = p_season;
  if coalesce((v_money->>'pot_cents')::bigint, 0) > 0 then
    select string_agg(coalesce(p.display_name, 'A golfer'), ', ' order by p.display_name)
      into v_owed_names
      from league_members lm join profiles p on p.id = lm.profile_id
     where lm.league_id = se.league_id
       and not exists (select 1 from buy_ins b where b.season_id = p_season and b.member_id = lm.id and b.paid);
    v_pot_line := 'The pot: $' || round((v_money->>'pot_cents')::numeric / 100.0);
    if (v_money->>'collected_cents')::bigint < (v_money->>'pot_cents')::bigint then
      v_pot_line := v_pot_line || ' · collected $' || round((v_money->>'collected_cents')::numeric / 100.0);
    end if;
    v_pot_line := v_pot_line
      || ' — champs $'      || round((v_money->>'champ')::numeric  / 100.0)
      || ' · runner-up $'   || round((v_money->>'runner')::numeric / 100.0)
      || ' · points king $' || round((v_money->>'king')::numeric   / 100.0);
    if (v_money->>'collected_cents')::bigint < (v_money->>'pot_cents')::bigint then
      v_pot_line := v_pot_line || ' · still owed: $'
        || round(((v_money->>'pot_cents')::numeric - (v_money->>'collected_cents')::numeric) / 100.0)
        || coalesce(' (' || v_owed_names || ')', '');
    end if;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system', v_pot_line || ' · settle between yourselves');
  end if;

  -- #23 · the field, completed. SEASON CLOSE ONLY — there is no mid-season
  -- last-place post anywhere, by design. It punches at nothing: the line is
  -- affectionate, and where the ledger shows they kept posting, it says so.
  select count(*) into v_field from _ranked;
  -- CRITIC B4 · in a Cup Final `_ranked` holds ONLY the finalists, so the
  -- bottom row is the FOURTH-BEST TEAM IN THE LEAGUE, not last place. Naming
  -- them would be the exact thing hard rule 4 forbids.
  if v_field >= 4 and not v_cup then
    select * into v_last from _ranked
     order by score asc, months_won asc, best_month asc, rounds_used desc, coin asc
     limit 1;
    if v_last.cid is not null and v_last.cid <> c1.cid
       and (c2.cid is null or v_last.cid <> c2.cid) then
      if v_solo then
        select coalesce(p.display_name, 'A golfer') into v_lastname
          from league_members lm join profiles p on p.id = lm.profile_id
         where lm.id = v_last.cid;
      else
        select name into v_lastname from squads where id = v_last.cid;
      end if;
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, p_season, 'system',
              'Someone had to complete the field. This season, '
              || coalesce(v_lastname, 'someone') || '.'
              || case when coalesce(v_last.rounds_used, 0) >= 4
                      then ' ' || v_last.rounds_used
                           || ' counting rounds says they kept showing up.'
                      else '' end);
    end if;
  end if;
end $function$;

revoke all on function public.close_season(uuid) from public, anon, authenticated;

-- ── 6 · the Final's small print ─────────────────────────────────────────────
-- Body = prod verbatim; both branches carry one more key, `cap_note`: the
-- sentence when a calendar cap is set, null when every round counts. Clients
-- print it under the receipt (index.html showFinalist · CupFinalRaceView).
create or replace function public.cup_final_race(p_season uuid)
returns jsonb
language plpgsql
stable security definer
set search_path = public
as $function$
declare
  se record; st record; cap_n integer; v_solo boolean;
  v_fin jsonb; v_rung text; v_cap_note text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then return null; end if;
  if not is_league_member(se.league_id) then
    raise exception 'Not a member of this league';
  end if;
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (st.structure = 'solo');
  cap_n  := coalesce(st.counting_cap, 10000);
  -- D212 · the calendar cap still applies inside the window
  v_cap_note := case when st.counting_cap is not null
                     then 'Best ' || st.counting_cap
                          || ' per calendar month still applies — a round posted before the window can hold a slot.'
                     else null end;

  if not exists (select 1 from cup_finalists where season_id = p_season) then
    return jsonb_build_object(
      'status', 'pending', 'season_status', se.status, 'solo', v_solo,
      'window_start', se.ends_on - 27, 'window_end', se.ends_on, 'cap_n', cap_n,
      'cap_note', v_cap_note,
      'days_left', greatest(0, se.ends_on - current_date),
      'finalists', '[]'::jsonb, 'seed_rung', null);
  end if;

  select jsonb_agg(to_jsonb(f) order by f.seed) into v_fin
    from (
      select cf.seed, cf.head_start, cf.seed_rung, cf.squad_id, cf.member_id,
             coalesce(sq.name, pf.display_name, 'A golfer') as name,
             sq.color,
             coalesce(sum(w.points), 0)                     as window_points,
             count(w.round_id)                              as rounds_used,
             max(w.played_on)                               as last_round_on,
             cf.head_start + coalesce(sum(w.points), 0)     as total,
             coalesce(jsonb_agg(jsonb_build_object(
               'round_id', w.round_id, 'played_on', w.played_on, 'points', w.points,
               'month_rank', w.month_rank, 'pvi', w.pvi, 'holes_played', w.holes_played,
               'member_id', w.member_id, 'golfer', coalesce(wp.display_name, 'A golfer'))
               order by w.played_on desc) filter (where w.round_id is not null), '[]'::jsonb) as rounds
        from cup_finalists cf
        left join squads sq          on sq.id = cf.squad_id
        left join league_members lm  on lm.id = cf.member_id
        left join profiles pf        on pf.id = lm.profile_id
        left join lateral (
          select w.* from _cup_window_rounds(p_season) w
           where w.member_id = cf.member_id
              or w.member_id in (select sm.member_id from squad_members sm where sm.squad_id = cf.squad_id)
        ) w on true
        left join league_members wlm on wlm.id = w.member_id
        left join profiles wp        on wp.id = wlm.profile_id
       where cf.season_id = p_season
       group by cf.id, cf.seed, cf.head_start, cf.seed_rung, cf.squad_id, cf.member_id,
                sq.name, sq.color, pf.display_name
    ) f;

  -- the rung that decided the cut (seed 2 vs the row below) is the story;
  -- seed 1's rung (the +10 race) rides along in its own row
  select seed_rung into v_rung from cup_finalists
   where season_id = p_season and seed_rung is not null
   order by seed desc limit 1;

  return jsonb_build_object(
    'status', case when se.status = 'complete' then 'complete' else 'live' end,
    'season_status', se.status, 'solo', v_solo,
    'window_start', se.ends_on - 27, 'window_end', se.ends_on, 'cap_n', cap_n,
    'cap_note', v_cap_note,
    'days_left', greatest(0, se.ends_on - current_date),
    'finalists', coalesce(v_fin, '[]'::jsonb), 'seed_rung', v_rung);
end $function$;

revoke all on function public.cup_final_race(uuid) from public, anon;
grant execute on function public.cup_final_race(uuid) to authenticated;

-- ── 7 · self-check ──────────────────────────────────────────────────────────
do $chk$
declare v_src text; v_n integer;
begin
  -- the settle and the last call read every round in the window
  for v_src in
    select p.prosrc from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname in ('settle_week_clash', 'clash_last_call')
  loop
    if v_src like '%month\_rank <= coalesce(v\_cap%' then   -- `_` escaped: LIKE wildcard
      raise exception '[D207] a clash beat still filters on the calendar cap';
    end if;
  end loop;

  -- the band is the engine's, not a hand copy
  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'settle_week_clash';
  if v_src like '%rr.pvi >= -1%' or v_src like '%v_pvi >= -1%' or v_src not like '%cup_points(%' then
    raise exception '[D207] settle_week_clash labels the band by hand';
  end if;
  if cup_points(-1.0) <> 6 or cup_points(-0.9) <> 7 then
    raise exception '[D207] cup_points moved its edge';
  end if;

  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'open_week_clash';
  if v_src not like '%It''''s the two of you — every week is the clash.%'
     or v_src not like '%Best round of the week takes it.%' then
    raise exception '[D207] open_week_clash lost a line';
  end if;

  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'clash_last_call';
  if v_src like '%Neither of them has posted%' then
    raise exception '[D207] clash_last_call still calls an empty week';
  end if;

  -- the preview is off the surface; the three engine functions stay off it
  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname in ('score_round', 'open_week_clash', 'clash_last_call', 'settle_week_clash', 'close_season')
     and p.prorettype <> 'trigger'::regtype
     and (has_function_privilege('authenticated', p.oid, 'execute')
          or has_function_privilege('anon', p.oid, 'execute'));
  if v_n > 0 then
    raise exception '[D207] % engine/preview function(s) still reachable by an API role', v_n;
  end if;

  -- D212 · the King's rung has a home and a ladder
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'seasons' and column_name = 'king_rung') then
    raise exception '[D212] seasons.king_rung missing';
  end if;
  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'close_season';
  if v_src not like '%king_rung      = v_king_rung%' or v_src not like '%months won this season%'
     or v_src like '%order by points desc nulls last limit 1%' then
    raise exception '[D212] close_season does not rank the King on the ladder';
  end if;
  if v_src not like '%award_season_trophies(p_season)%' or v_src not like '%Someone had to complete the field%' then
    raise exception '[D212] close_season lost part of its body';
  end if;

  select p.prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'cup_final_race';
  if v_src not like '%per calendar month still applies%' then
    raise exception '[D212] cup_final_race carries no cap note';
  end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = 'cup_final_race'
                    and has_function_privilege('authenticated', p.oid, 'execute')) then
    raise exception '[D212] cup_final_race lost its grant';
  end if;
end $chk$;
