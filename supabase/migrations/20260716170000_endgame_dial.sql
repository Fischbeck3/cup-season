-- ============================================================================
-- Migration 008 — the ENDGAME DIAL + the real crowning (spec §14.3–.4,
-- gameplay-modes decision #3, decision-log D4)
--
-- THE BUG THIS FIXES: close_season() crowned the champion from FULL-SEASON
-- standings even when a Cup Final ran — the fresh-slate final never decided
-- anything. And §14.3's tiebreak ladder was never implemented.
--
-- THE DIAL (decision #3): `finish = points_table | cup_final` is a bylaw.
-- A season may crown the points champion outright, or build to the final-4-
-- weeks Cup Final. Default cup_final — it's the product's name — and the tick
-- only opens the Final window for leagues that dialed it.
--
-- THE CROWNING (close_season, rewritten):
--   cup_final  → finalists race on FINAL-WINDOW counting points only
--                (+ head_start for 2-squad leagues), seeds locked by
--                enter_cup_final. Non-finalists' full-season numbers stand
--                for Points King etc. (§14.3: they keep playing).
--   points_table (or no finalists recorded) → full-season standings.
--   TIEBREAK LADDER (§14.3): months won h2h → best single month → fewest
--   rounds used → coin flip, LOGGED to the board. Implemented as sort keys,
--   with the deciding rung named in the crowning post.
--   Solo leagues crown a member (new seasons.champion_member_id).
--   Trophies mint (the 20260713200000 promise): Champion / Runner-up /
--   Points King. The pot line posts with the payout split — tracked, never
--   held.
-- ============================================================================

alter table public.league_settings
  add column if not exists finish text not null default 'cup_final';
alter table public.league_settings drop constraint if exists league_settings_finish_check;
alter table public.league_settings add constraint league_settings_finish_check
  check (finish in ('points_table','cup_final'));

alter table public.seasons
  add column if not exists champion_member_id uuid references public.league_members(id),
  add column if not exists runnerup_squad_id  uuid references public.squads(id),
  add column if not exists runnerup_member_id uuid references public.league_members(id);

-- ---- the Pro's dial ----------------------------------------------------------
create or replace function public.set_league_finish(p_league uuid, p_finish text)
returns void language plpgsql security definer set search_path = public as $$
declare se record;
begin
  if p_finish not in ('points_table','cup_final') then raise exception 'finish must be points_table or cup_final'; end if;
  if not is_commissioner(p_league) then raise exception 'Only the Pro sets the finish'; end if;
  select * into se from seasons where league_id = p_league and status in ('active','cup_final')
   order by number desc limit 1;
  -- once the Final window is open (or entered) the finish is settled — no
  -- retroactive rewrites of a live endgame (spec principle 4: argue never)
  if se.id is not null and (se.status = 'cup_final' or current_date >= se.ends_on - 27) then
    raise exception 'The finish is locked once the final window opens';
  end if;

  update league_settings set finish = p_finish where league_id = p_league;
  insert into posts (league_id, kind, member_id, body)
  values (p_league, 'system', my_member_id(p_league),
          case when p_finish = 'cup_final'
            then 'THE PRO SET THE FINISH: THE CUP FINAL — FINAL 4 WEEKS, SCORED FRESH, TOP SEEDS ONLY'
            else 'THE PRO SET THE FINISH: THE POINTS TABLE CROWNS THE CHAMPION OUTRIGHT' end);
end $$;
grant execute on function public.set_league_finish(uuid, text) to authenticated;

-- ---- the tick honors the dial -------------------------------------------------
create or replace function public.daily_season_tick() returns void
language plpgsql security definer set search_path = public as $$
declare se record; v_finish text;
begin
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
  end loop;
end $$;

-- ---- the crowning --------------------------------------------------------------
create or replace function public.close_season(p_season uuid) returns void
language plpgsql security definer set search_path = public as $$
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

  -- contenders, uniformly as member sets:
  --   cup_final → the locked finalists, scored on the FINAL WINDOW only
  --   points_table → everyone, scored on the whole season
  -- the tick may close several seasons in ONE transaction — drop first
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

  -- score + §14.3 ladder metrics per contender:
  --   score → months won → best single month → fewest rounds → coin flip
  -- (window points for cup finish; full season otherwise. Ladder metrics are
  --  always full-season — the ladder is about the season's body of work.)
  -- NOTE: INSERT…SELECT, never CREATE TABLE AS — plpgsql does not substitute
  -- variables into utility statements.
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
  months_won as (            -- months where this contender out-scored ALL others
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

  -- points-table finish: the score IS the standings table the league watched
  -- all season (rounds + the adjustments ledger) — never a re-derivation that
  -- could crown a different number than the one on screen (§16)
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

  -- which rung decided? (for the receipts — §16 extends to the crown itself)
  if c2.cid is not null and c1.score = c2.score then
    if c1.months_won <> c2.months_won then v_rung := 'MONTHS WON';
    elsif c1.best_month <> c2.best_month then v_rung := 'BEST SINGLE MONTH';
    elsif c1.rounds_used <> c2.rounds_used then v_rung := 'FEWEST ROUNDS USED';
    else v_rung := 'COIN FLIP'; end if;
  end if;

  select member_id into king from v_individual_standings
   where season_id = p_season order by points desc nulls last limit 1;

  update seasons set status = 'complete',
    champion_squad_id  = case when not v_solo then c1.cid end,
    champion_member_id = case when v_solo then c1.cid end,
    runnerup_squad_id  = case when not v_solo then c2.cid end,
    runnerup_member_id = case when v_solo then c2.cid end,
    points_king_member_id = king
    where id = p_season;
  update leagues set phase = 'complete' where id = se.league_id;

  -- names for the story
  if v_solo then
    select coalesce(p.display_name,'THE CHAMPION') into v_champname
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

  v_story := 'SEASON COMPLETE: ' || upper(coalesce(v_champname,'THE CHAMPION'))
    || case when v_cup then ' TAKE THE CUP FINAL' else ' TAKE THE CUP' end
    || case when v_score2 is not null then ' ' || v_score1 || '–' || v_score2 else '' end
    || case when v_rung is not null then ' · TIEBREAK: ' || v_rung else '' end
    || case when v_kname <> '' then ' · POINTS KING: ' || upper(v_kname) else '' end;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_story);

  -- the pot line: tracked, never held (§14.4 — the settlement is a post)
  select count(*) into n_members from league_members where league_id = se.league_id;
  pot := (coalesce(st.buyin_cents,0) / 100.0) * n_members;
  if pot > 0 then
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system',
      'THE POT: $' || round(pot)
      || ' — CHAMPS $' || round(pot * st.payout_champ / 100.0)
      || ' · RUNNER-UP $' || round(pot * st.payout_runnerup / 100.0)
      || ' · POINTS KING $' || round(pot * st.payout_king / 100.0)
      || ' · SETTLE ON VENMO');
  end if;

  perform award_season_trophies(p_season);
end $$;

-- ---- trophies: the 20260713200000 promise, kept --------------------------------
create or replace function public.award_season_trophies(p_season uuid)
returns void language plpgsql security definer set search_path = public as $$
declare se record; lg_name text; yr int;
begin
  select * into se from seasons where id = p_season and status = 'complete';
  if not found then return; end if;
  select name into lg_name from leagues where id = se.league_id;
  yr := extract(year from se.ends_on)::int;

  -- champion(s)
  if se.champion_squad_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Champion', 'winner', se.league_id, yr
        from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.champion_squad_id
      on conflict do nothing;
  elsif se.champion_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Champion', 'winner', se.league_id, yr
        from league_members lm where lm.id = se.champion_member_id
      on conflict do nothing;
  end if;

  -- runner(s)-up
  if se.runnerup_squad_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Runner-up', 'runner_up', se.league_id, yr
        from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.runnerup_squad_id
      on conflict do nothing;
  elsif se.runnerup_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Runner-up', 'runner_up', se.league_id, yr
        from league_members lm where lm.id = se.runnerup_member_id
      on conflict do nothing;
  end if;

  -- the Points King
  if se.points_king_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Points King', 'points_king', se.league_id, yr
        from league_members lm where lm.id = se.points_king_member_id
      on conflict do nothing;
  end if;
end $$;
