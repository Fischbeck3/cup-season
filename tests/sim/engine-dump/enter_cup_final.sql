-- enter_cup_final(p_season uuid) oid=18448
CREATE OR REPLACE FUNCTION public.enter_cup_final(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

  v_post := 'The Cup Final is live. Four weeks, scored fresh, and the Final is set.'
    || coalesce(' #1 by ' || rung1 || '.', '')
    || coalesce(' #2 by ' || rung2 || '.', '');
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_post);
end $function$

