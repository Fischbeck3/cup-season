-- ============================================================================
-- Cup Season — D66: the margin becomes structured truth
--
-- close_season computed the two deciding scores and the tiebreak rung, wrote
-- them into a prose post, and dropped them. The ceremony needs "58–50 · by 8"
-- and "decided on MONTHS WON" as data — three surfaces (the takeover, the
-- recap card, the season-end email) must not each re-parse a sentence, and a
-- re-derivation could disagree with the crown that was actually awarded (§16:
-- the number on screen IS the number that decided it).
--
-- Also fixes the casing at its source for these two posts: bodies were stored
-- upper() so the client's easeCaps had to lowercase them, which destroyed
-- every proper noun ("points king: sandy wedge"). Written natural-case now —
-- easeCaps passes mixed-case straight through, so these read correctly and
-- legacy all-caps posts still ease as before. The scoreboard voice belongs to
-- typography, not to the data.
-- ============================================================================

alter table public.seasons
  add column if not exists champion_score numeric,
  add column if not exists runnerup_score numeric,
  add column if not exists tiebreak_rung  text;

create or replace function public.close_season(p_season uuid) returns void
    language plpgsql security definer set search_path = public as $_$
declare
  se record; st record; king uuid;
  v_solo boolean; v_finalists boolean; v_cup boolean;
  cap_n integer; cf_start date;
  c1 record; c2 record;
  v_rung text := null; v_story text; v_score1 text; v_score2 text;
  n_members integer; pot numeric; v_kname text; v_champname text; v_runname text;
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
    select c.cid,
           max(c.head) + coalesce(sum(rr.points) filter (
             where rr.month_rank <= cap_n
               and (not v_cup or rr.played_on between cf_start and se.ends_on)
           ), 0) as score
      from _cont c
      left join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
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

  -- the pot line: tracked, never held (§14.4 — the settlement is a post)
  select count(*) into n_members from league_members where league_id = se.league_id;
  pot := (coalesce(st.buyin_cents,0) / 100.0) * n_members;
  if pot > 0 then
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system',
      'The pot: $' || round(pot)
      || ' — champs $' || round(pot * st.payout_champ / 100.0)
      || ' · runner-up $' || round(pot * st.payout_runnerup / 100.0)
      || ' · points king $' || round(pot * st.payout_king / 100.0)
      || ' · settle between yourselves');
  end if;

  perform award_season_trophies(p_season);
end $_$;

-- close_season stays engine-only (the tick calls it); never client-callable.
revoke all on function public.close_season(uuid) from public, anon, authenticated;
grant execute on function public.close_season(uuid) to service_role;
-- No column grants needed here: seasons carries a table-level SELECT for
-- authenticated, so the three new columns are covered. The frozen
-- column-grant list is a PROFILES-only condition (the email seal,
-- 20260721214500) — don't cargo-cult it onto other tables.
