-- close_season(p_season uuid) oid=18257
CREATE OR REPLACE FUNCTION public.close_season(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    || case when v_rung is not null then '. Tiebreak: '
              || case v_rung when 'months won' then 'months won this season' else v_rung end
            else '' end
    || case when v_kname <> '' then '. Points King: ' || v_kname
              || case when v_king_rung is not null then ' (tiebreak: '
                        || case v_king_rung when 'months won' then 'months won this season' else v_king_rung end
                        || ')'
                      else '' end
            else '' end
    || '.';
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
      || ' — champion $'    || round((v_money->>'champ')::numeric  / 100.0)
      || ' · runner-up $'   || round((v_money->>'runner')::numeric / 100.0)
      || ' · points king $' || round((v_money->>'king')::numeric   / 100.0);
    if (v_money->>'collected_cents')::bigint < (v_money->>'pot_cents')::bigint then
      v_pot_line := v_pot_line || ' · still owed: $'
        || round(((v_money->>'pot_cents')::numeric - (v_money->>'collected_cents')::numeric) / 100.0)
        || coalesce(' (' || v_owed_names || ')', '');
    end if;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system', v_pot_line || '. Cup Season keeps the ledger; the money moves between friends.');
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
                           || ' rounds that counted says they kept showing up.'
                      else '' end);
    end if;
  end if;
end $function$

