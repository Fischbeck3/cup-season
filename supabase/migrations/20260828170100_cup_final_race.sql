-- ============================================================================
-- D105 (spec/decision-log.md) · The Cup Final you can see — the window race
-- is a server function, seeds carry the crown's ladder. Spec §14.0 ("the
-- final four weeks, scored fresh") and §14.3 (seeds lock at ends_on − 27;
-- the four-rung tiebreak ladder).
--
--   1. _cup_window_rounds(season)   the ONE expression for "a round that counts
--                                   in the Final": played_on within
--                                   [ends_on−27, ends_on] and month_rank ≤ cap.
--                                   Engine-only. close_season and
--                                   cup_final_race both read it (§16: the
--                                   figure and its receipt are one path).
--   2. cup_final_race(season)       member-gated, authenticated: per finalist
--                                   seed · head start · window points · rounds
--                                   used · last round · total, plus the rounds
--                                   behind the number. Before seeds lock it
--                                   answers {status:'pending'} — the D4
--                                   foreshadow (season_scenarios) stays as is.
--   3. cup_finalists.seed_rung      enter_cup_final now seeds by the §14.3
--                                   ladder (points → months won → best single
--                                   month → fewest rounds used → coin) over
--                                   the regular season to date, and stores the
--                                   rung that decided each seed against the
--                                   next row down (null = points alone). The
--                                   board post names it ("#2 BY MONTHS WON").
--   4. close_season                 re-created from 20260828170000 (D106),
--                                   changed ONLY in the window-score CTE, which
--                                   now reads the helper. Crown ladder, D66
--                                   result columns, D106 money: untouched.
--
-- Also: cup_finalists loses its table-level write grant for authenticated —
-- the engine writes it as definer; RLS already allowed only SELECT.
-- D37: explicit revoke/grant on every function. Self-enforcing at the end.
-- ============================================================================

-- ---- 1. the seed rung, and the table's writes ------------------------------
alter table public.cup_finalists add column if not exists seed_rung text;
revoke insert, update, delete, truncate, references, trigger
  on table public.cup_finalists from authenticated;

-- ---- 2. the one window expression ------------------------------------------
create or replace function public._cup_window_rounds(p_season uuid)
returns table (
  member_id uuid, round_id uuid, profile_id uuid, played_on date,
  points integer, month_rank bigint, pvi numeric, holes_played integer
)
language sql stable security definer set search_path = public as $$
  select rr.member_id, rr.round_id, rr.profile_id, rr.played_on,
         rr.points::integer, rr.month_rank, rr.pvi, rr.holes_played
    from public.v_rounds_ranked rr
    join public.seasons se on se.id = rr.season_id
    join public.league_settings ls on ls.league_id = se.league_id
   where rr.season_id = p_season
     and rr.month_rank <= coalesce(ls.counting_cap, 10000)
     and rr.played_on between se.ends_on - 27 and se.ends_on
$$;
revoke all on function public._cup_window_rounds(uuid) from public, anon, authenticated;
grant execute on function public._cup_window_rounds(uuid) to service_role;

-- ---- 3. the race, for the room ----------------------------------------------
create or replace function public.cup_final_race(p_season uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  se record; st record; cap_n integer; v_solo boolean;
  v_fin jsonb; v_rung text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then return null; end if;
  if not is_league_member(se.league_id) then
    raise exception 'Not a member of this league';
  end if;
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (st.structure = 'solo');
  cap_n  := coalesce(st.counting_cap, 10000);

  if not exists (select 1 from cup_finalists where season_id = p_season) then
    return jsonb_build_object(
      'status', 'pending', 'season_status', se.status, 'solo', v_solo,
      'window_start', se.ends_on - 27, 'window_end', se.ends_on, 'cap_n', cap_n,
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
    'days_left', greatest(0, se.ends_on - current_date),
    'finalists', coalesce(v_fin, '[]'::jsonb), 'seed_rung', v_rung);
end $$;
revoke all on function public.cup_final_race(uuid) from public, anon;
grant execute on function public.cup_final_race(uuid) to authenticated;

-- ---- 4. seeds carry the crown's ladder --------------------------------------
create or replace function public.enter_cup_final(p_season uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  se record; st record; cap_n integer; cf_start date;
  r1 record; r2 record; r3 record; rung1 text; rung2 text; v_post text;
begin
  select * into se from seasons where id = p_season;
  if se.status <> 'active' then return; end if;                 -- idempotent
  if current_date < se.ends_on - 27 then return; end if;        -- window not open

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  cap_n    := coalesce(st.counting_cap, 10000);
  cf_start := se.ends_on - 27;

  -- the contenders: (cid, member, regular-season points from the standings view —
  -- the ledger included, exactly what the table shows the day the seeds lock)
  drop table if exists _sc; drop table if exists _seed;
  create temp table _sc (cid uuid, member_id uuid, score numeric) on commit drop;
  if st.structure = 'solo' then
    insert into _sc
    select i.member_id, i.member_id, coalesce(i.points, 0)
      from v_individual_standings i where i.season_id = p_season;
  else
    insert into _sc
    select vs.squad_id, sm.member_id, coalesce(vs.points, 0)
      from v_squad_standings vs
      left join squad_members sm on sm.squad_id = vs.squad_id
     where vs.season_id = p_season;
  end if;

  -- the §14.3 ladder over the regular season (rounds before the window)
  create temp table _seed (
    cid uuid, score numeric, months_won integer, best_month numeric,
    rounds_used integer, coin double precision, rk integer
  ) on commit drop;
  insert into _seed (cid, score, months_won, best_month, rounds_used, coin)
  with months as (
    select c.cid, date_trunc('month', rr.played_on)::date as mon, sum(rr.points) as mpts
      from _sc c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n and rr.played_on < cf_start
     group by 1, 2
  ),
  months_won as (
    select m.cid, count(*) as won from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.cid <> m.cid), -1)
     group by m.cid
  ),
  best_month as (select cid, max(mpts) as best from months group by cid),
  rounds_used as (
    select c.cid, count(rr.*) as used
      from _sc c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n and rr.played_on < cf_start
     group by c.cid
  )
  select c.cid, max(c.score), coalesce(max(w.won), 0), coalesce(max(b.best), 0),
         coalesce(max(u.used), 0), random()
    from _sc c
    left join months_won  w on w.cid = c.cid
    left join best_month  b on b.cid = c.cid
    left join rounds_used u on u.cid = c.cid
   group by c.cid;
  update _seed s set rk = x.rk
    from (select cid, row_number() over (
            order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc) as rk
            from _seed) x
   where x.cid = s.cid;

  select * into r1 from _seed where rk = 1;
  select * into r2 from _seed where rk = 2;
  select * into r3 from _seed where rk = 3;

  -- the rung that separated a seed from the row below it (null = points did)
  if r2.cid is not null and r1.score = r2.score then
    rung1 := case when r1.months_won <> r2.months_won then 'months won'
                  when r1.best_month <> r2.best_month then 'best single month'
                  when r1.rounds_used <> r2.rounds_used then 'fewest rounds used'
                  else 'coin flip' end;
  end if;
  if r3.cid is not null and r2.cid is not null and r2.score = r3.score then
    rung2 := case when r2.months_won <> r3.months_won then 'months won'
                  when r2.best_month <> r3.best_month then 'best single month'
                  when r2.rounds_used <> r3.rounds_used then 'fewest rounds used'
                  else 'coin flip' end;
  end if;

  if r1.cid is not null then
    if st.structure = 'solo' then
      insert into cup_finalists (season_id, member_id, seed, seed_rung)
      values (p_season, r1.cid, 1, rung1);
    else
      insert into cup_finalists (season_id, squad_id, seed, head_start, seed_rung)
      values (p_season, r1.cid, 1, case when st.structure = 'squads2' then 10 else 0 end, rung1);
    end if;
  end if;
  if r2.cid is not null then
    if st.structure = 'solo' then
      insert into cup_finalists (season_id, member_id, seed, seed_rung)
      values (p_season, r2.cid, 2, rung2);
    else
      insert into cup_finalists (season_id, squad_id, seed, head_start, seed_rung)
      values (p_season, r2.cid, 2, 0, rung2);
    end if;
  end if;

  update seasons set status = 'cup_final' where id = p_season;

  v_post := 'THE CUP FINAL IS LIVE — FRESH SLATE, FOUR WEEKS. SEEDS ARE LOCKED'
    || coalesce(' — #2 BY ' || upper(rung2), '')
    || coalesce(case when rung2 is null then ' — ' else ' · ' end || '#1 BY ' || upper(rung1), '')
    || '.';
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_post);
end $$;
-- the tick calls it; never client-callable (20260718172300 stands)
revoke all on function public.enter_cup_final(uuid) from public, anon, authenticated;
grant execute on function public.enter_cup_final(uuid) to service_role;

-- ---- 5. close_season: the crown reads the same window rows -----------------
create or replace function public.close_season(p_season uuid) returns void
    language plpgsql security definer set search_path = public as $_$
declare
  se record; st record; king uuid;
  v_solo boolean; v_finalists boolean; v_cup boolean;
  cap_n integer; cf_start date;
  c1 record; c2 record;
  v_rung text := null; v_story text; v_score1 text; v_score2 text;
  v_kname text; v_champname text; v_runname text;
  v_money jsonb; v_owed_names text; v_pot_line text;
begin
  select * into se from seasons where id = p_season;
  if se.status = 'complete' then return; end if;              -- idempotent
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (st.structure = 'solo');
  cap_n := coalesce(st.counting_cap, 10000);
  cf_start := se.ends_on - 27;
  v_finalists := exists (select 1 from cup_finalists where season_id = p_season);
  v_cup := coalesce(st.finish,'cup_final') = 'cup_final' and v_finalists;

  drop table if exists _cont; drop table if exists _ranked;
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

  select member_id into king from v_individual_standings
   where season_id = p_season order by points desc nulls last limit 1;

  -- D66: the deciding numbers are STORED, not just narrated
  update seasons set status = 'complete',
    champion_squad_id  = case when not v_solo then c1.cid end,
    champion_member_id = case when v_solo then c1.cid end,
    runnerup_squad_id  = case when not v_solo then c2.cid end,
    runnerup_member_id = case when v_solo then c2.cid end,
    points_king_member_id = king,
    champion_score = c1.score,
    runnerup_score = c2.score,
    tiebreak_rung  = v_rung
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

  -- D66: natural case — proper nouns survive the client's easeCaps intact
  v_story := 'Season complete: ' || coalesce(v_champname,'The champion')
    || case when v_cup then ' take the Cup Final' else ' take the Cup' end
    || case when v_score2 is not null then ' ' || v_score1 || '–' || v_score2 else '' end
    || case when v_rung is not null then ' · tiebreak: ' || v_rung else '' end
    || case when v_kname <> '' then ' · Points king: ' || v_kname else '' end;
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
end $_$;

-- close_season stays engine-only (the tick calls it); never client-callable.
revoke all on function public.close_season(uuid) from public, anon, authenticated;
grant execute on function public.close_season(uuid) to service_role;

-- ---- self-enforcing ---------------------------------------------------------
do $$
begin
  if has_table_privilege('authenticated', 'public.cup_finalists', 'insert')
     or has_table_privilege('authenticated', 'public.cup_finalists', 'update')
     or has_table_privilege('authenticated', 'public.cup_finalists', 'delete') then
    raise exception 'D105: authenticated still holds a write privilege on cup_finalists';
  end if;
  if not has_table_privilege('authenticated', 'public.cup_finalists', 'select') then
    raise exception 'D105: authenticated lost SELECT on cup_finalists';
  end if;
  if not has_function_privilege('authenticated', 'public.cup_final_race(uuid)', 'execute') then
    raise exception 'D105: cup_final_race not granted to authenticated';
  end if;
  if has_function_privilege('anon', 'public.cup_final_race(uuid)', 'execute') then
    raise exception 'D105: cup_final_race must not be anon-callable';
  end if;
  if has_function_privilege('authenticated', 'public._cup_window_rounds(uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.enter_cup_final(uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.close_season(uuid)', 'execute') then
    raise exception 'D105: an engine-only function is client-callable';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'cup_finalists' and column_name = 'seed_rung') then
    raise exception 'D105: cup_finalists.seed_rung missing';
  end if;
end $$;
