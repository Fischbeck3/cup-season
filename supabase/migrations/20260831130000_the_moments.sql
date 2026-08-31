-- D166 · the moments the product never had.
--
-- The board's entire emotional vocabulary was three lines — a barrier broken, a
-- personal best, a streak — plus one lead-change post. Everything the canon
-- cares about most was silent: the blown lead, the comeback, last place, the
-- bad round, a rivalry running hot, a golfer coming back.
--
-- Each fires from data that already exists. Nothing here invents a table.
--
-- THE GUARDS ARE THE DESIGN. Every one of these can hurt someone if it speaks
-- at the wrong moment, so each carries the reason it cannot:
--   · last place — SEASON CLOSE ONLY, and never inside a Cup Final, where the
--     ranked set holds only finalists and the bottom row is the fourth-best
--     team in the league rather than last place.
--   · the bad round — an established golfer only (5+ rounds), whose number the
--     app DERIVED from their own scores rather than a starter index they
--     guessed, on 18 holes, at most once every 60 days, and outranked by every
--     warmer headline above it.
--   · the comeback — nothing before week 4, silence when a snapshot is missing
--     rather than a guess, and no week numbers (the two week-counters in this
--     schema disagree by one on the same day).
--   · rivalry heat — true run length, so it fires once at three and once at
--     five, never every week thereafter.
--
-- Bodies are the LIVE definitions, patched fragment-by-fragment.


-- D166 · the comeback. `20260716200000_post_round_peak.sql` opens with a comment
-- promising "the comeback/collapse tag (#23)" and no copy was ever written.
--
-- Three guards, all from the review, all load-bearing:
--   · nothing before week 4 — `p_week - 3` would read a snapshot at week <= 0
--   · bail when the PRIOR snapshot is missing (a skipped cron run makes the
--     comparison NULL, and "did not already lead" would then be NULL, so the
--     line could re-fire every week)
--   · NEVER print a week number. `snapshot_week` computes the week as
--     floor((today - starts_on)/7.0); `open_week_clash` computes
--     floor(.../7)+1. On the same day they disagree by one, so "back in week
--     40" would contradict "the clash this week" on the very same board.
--     "three weeks ago" is both safer and better copy.
create or replace function public.post_week_comeback(p_season uuid, p_week integer)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  se       record;
  v_then   integer := p_week - 3;
  v_now    jsonb;
  v_prev   jsonb;
  v_lead   uuid;
  v_prior  uuid;
  v_back   numeric;
  v_name   text;
begin
  if p_week < 4 then return; end if;
  select * into se from seasons where id = p_season;
  if not found then return; end if;

  select standings->'individuals' into v_now
    from standings_snapshots where season_id = p_season and week_no = p_week;
  select standings->'individuals' into v_prev
    from standings_snapshots where season_id = p_season and week_no = v_then;
  -- a missing snapshot is silence, never a guess
  if v_now is null or v_prev is null then return; end if;

  -- who leads now
  select (e->>'member_id')::uuid into v_lead
    from jsonb_array_elements(v_now) e
   order by (e->>'points')::numeric desc limit 1;
  -- who led then, and how far back the current leader was
  select (e->>'member_id')::uuid into v_prior
    from jsonb_array_elements(v_prev) e
   order by (e->>'points')::numeric desc limit 1;
  if v_lead is null or v_prior is null or v_lead = v_prior then return; end if;

  select (select max((e2->>'points')::numeric) from jsonb_array_elements(v_prev) e2)
       - (select (e3->>'points')::numeric from jsonb_array_elements(v_prev) e3
           where (e3->>'member_id')::uuid = v_lead)
    into v_back;
  -- it is only a comeback if there was something to come back from
  if v_back is null or v_back < 15 then return; end if;

  select coalesce(p.display_name, 'A golfer') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = v_lead;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'moment',
          coalesce(v_name, 'A golfer') || ': ' || round(v_back)
          || ' points back three weeks ago. Top of the table now.');
end $fn$;

revoke all on function public.post_week_comeback(uuid, integer) from public, anon;
grant execute on function public.post_week_comeback(uuid, integer) to authenticated;


-- ---- squad_lead_moments --------------------------------------------
CREATE OR REPLACE FUNCTION public.squad_lead_moments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  r            record;
  v_leader     uuid;
  v_leader_pts numeric;
  v_second_pts numeric;
  v_prior      uuid;
  v_lname      text;
  v_pname      text;
  v_moment     text;
  v_since      timestamptz;
  v_days       integer;
  v_peak       numeric;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  for r in
    select s.id as season_id, s.league_id
      from league_members lm
      join seasons s on s.league_id = lm.league_id
                    and s.status in ('active', 'cup_final')
                    and new.played_on between s.starts_on and s.ends_on
     where lm.profile_id = new.profile_id
  loop
    select squad_id, points into v_leader, v_leader_pts
      from v_squad_standings
     where season_id = r.season_id
     order by points desc, squad_id
     limit 1;
    if v_leader is null then continue; end if;

    select points into v_second_pts
      from v_squad_standings
     where season_id = r.season_id and squad_id <> v_leader
     order by points desc
     limit 1;

    -- a real, sole leader (nobody tied at the top)
    if v_second_pts is not null and v_leader_pts <= v_second_pts then
      continue;
    end if;

    select squad_id, since into v_prior, v_since from season_lead where season_id = r.season_id;

    if v_prior is null then
      -- first-ever strict leader: record silently, never announce
      insert into season_lead (season_id, squad_id) values (r.season_id, v_leader)
        on conflict (season_id) do update set squad_id = excluded.squad_id, since = now();
      continue;
    end if;

    if v_leader <> v_prior then
      -- the standing flipped. #23's collapse tag: the squad that just LOST
      -- first place is the other half of the story, and until now got nothing.
      -- Natural case throughout — the push function has no lowercasing pass.
      select name into v_lname from squads where id = v_leader;
      select name into v_pname from squads where id = v_prior;
      v_days := greatest(0, (now()::date - v_since::date));
      -- the biggest lead the deposed squad ever held, read from the weekly
      -- snapshots taken while they were on top
      select max(q.mine - coalesce(q.best_other, q.mine)) into v_peak
        from (
          select (select (e->>'points')::numeric
                    from jsonb_array_elements(ss.standings->'squads') e
                   where (e->>'squad_id')::uuid = v_prior) as mine,
                 (select max((e->>'points')::numeric)
                    from jsonb_array_elements(ss.standings->'squads') e
                   where (e->>'squad_id')::uuid <> v_prior) as best_other
            from standings_snapshots ss
           where ss.season_id = r.season_id and ss.captured_at >= v_since
        ) q
       where q.mine is not null;
      if v_peak is not null and v_peak >= 10 then
        v_moment := coalesce(v_lname, 'A squad') || ' take the lead. '
                 || coalesce(v_pname, 'The field') || ' were ' || round(v_peak)
                 || ' points clear at their best. A commanding lead. Formerly.';
      elsif v_days >= 14 then
        v_moment := coalesce(v_lname, 'A squad') || ' take the lead. '
                 || coalesce(v_pname, 'The field') || ' held first for '
                 || v_days || ' days. Once upon a time.';
      else
        v_moment := coalesce(v_lname, 'A squad') || ' take the lead, and '
                 || coalesce(v_pname, 'the field') || ' give it up. '
                 || 'Well. That didn''t last long.';
      end if;
      v_moment := upper(left(v_moment, 1)) || substr(v_moment, 2);
      insert into posts (league_id, season_id, kind, member_id, body)
      values (r.league_id, r.season_id, 'moment', null, v_moment);
      update season_lead set squad_id = v_leader, since = now()
       where season_id = r.season_id;
    end if;
  end loop;

  return new;
end $function$;


-- ---- close_season --------------------------------------------------
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
    || case when v_solo then ' takes' else ' take' end
    || case when v_cup then ' the Cup Final' else ' the Cup' end
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


-- ---- round_moments -------------------------------------------------
CREATE OR REPLACE FUNCTION public.round_moments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v            uuid := new.profile_id;
  v_name       text;
  v_prior_best numeric;
  v_barrier    int  := null;
  v_streak     int  := 0;
  v_first_week boolean := false;
  v_is_first   boolean := false;
  v_thr        int;
  v_moment     text := null;
  v_prior_n    integer := 0;
  v_last_on    date;
  v_gap        integer;
  v_miss       numeric;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  select firstname(coalesce(display_name, 'A golfer')) into v_name
    from profiles where id = v;

  -- 1) career barrier (18-hole gross): lowest threshold crossed for the headline
  if new.holes_played = 18 and new.gross is not null then
    if new.gross < 80 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 80
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 80;
    elsif new.gross < 90 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 90
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 90;
    elsif new.gross < 100 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 100
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 100;
    end if;
  end if;

  -- 2) personal-best differential (vs every prior round)
  select min(differential) into v_prior_best
    from rounds where profile_id = v and id <> new.id
      and not voided and differential is not null
      and coalesce(source,'app') <> 'sim';

  -- 3) iron-man streak — only when this is the first post of its week
  select count(*) = 0 into v_first_week
    from rounds where profile_id = v and id <> new.id and not voided
      and date_trunc('week', played_on) = date_trunc('week', new.played_on);
  if v_first_week then
    with wks as (
      select distinct date_trunc('week', played_on)::date w
        from rounds
       where profile_id = v and not voided and played_on <= new.played_on
    ), grp as (
      select w, w - (row_number() over (order by w) * interval '7 day') as g
        from wks
    )
    select count(*) into v_streak
      from grp
     where g = (select g from grp order by w desc limit 1);
  end if;

  -- ---- persistent achievements (same detection, permanent home) ----
  v_is_first := not exists (
    select 1 from rounds where profile_id = v and id <> new.id
      and not voided and coalesce(source,'app') <> 'sim');
  if v_is_first then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'first_round', 'First round posted', new.played_on, new.id,
            jsonb_build_object('gross', new.gross))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- barriers for the case: award EVERY threshold newly crossed (not just the headline)
  if new.holes_played = 18 and new.gross is not null then
    foreach v_thr in array array[100, 90, 80] loop
      if new.gross < v_thr and not exists (
        select 1 from rounds where profile_id = v and id <> new.id
          and not voided and holes_played = 18 and gross < v_thr
          and coalesce(source,'app') <> 'sim') then
        insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
        values (v, 'sub_' || v_thr, 'Broke ' || v_thr, new.played_on, new.id,
                jsonb_build_object('gross', new.gross))
        on conflict (profile_id, kind) do nothing;
      end if;
    end loop;
  end if;

  if v_prior_best is not null and new.differential < v_prior_best then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'personal_best', 'Personal best', new.played_on, new.id,
            jsonb_build_object('diff', new.differential))
    on conflict (profile_id, kind) do update
      set earned_on = excluded.earned_on, round_id = excluded.round_id, meta = excluded.meta;
  end if;

  if v_first_week and v_streak in (4, 8, 12) then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'streak_' || v_streak, v_streak || '-week streak', new.played_on, new.id,
            jsonb_build_object('weeks', v_streak))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- ---- the return, and the bad day (D166) ----
  select count(*), max(played_on) into v_prior_n, v_last_on
    from rounds
   where profile_id = v and id <> new.id and not voided
     and coalesce(source,'app') <> 'sim' and played_on <= new.played_on;
  v_gap  := case when v_last_on is null then null else new.played_on - v_last_on end;
  v_miss := new.differential - new.index_at_post;

  -- ---- one ephemeral headline (barrier > PB > return > streak > bad day) ----
  if v_barrier is not null then
    v_moment := v_name || ' broke ' || v_barrier
             || ' for the first time — '
             || case when new.gross between 80 and 89 then 'an ' else 'a ' end
             || new.gross || '. That one goes on the wall.';
  elsif v_prior_best is not null and new.differential < v_prior_best then
    v_moment := v_name || ' set a personal best. New number to chase.';
  elsif v_gap >= 42 and v_prior_n >= 3 then
    -- a return, not a debut: there is history here, and a real gap in it
    v_moment := 'First round since '
             || case when v_gap >= 300 then to_char(v_last_on, 'FMMonth YYYY')
                     else to_char(v_last_on, 'FMMonth') end
             || ' for ' || v_name || '. Welcome back.';
  elsif v_first_week and v_streak >= 4 and v_streak % 4 = 0 then
    v_moment := v_name || ' has posted ' || v_streak
             || ' weeks running. The streak holds.';
  elsif v_miss >= 6 and v_prior_n >= 5 and new.holes_played = 18
        and coalesce(new.index_source_at_post, 'app') = 'app'
        and not exists (
          select 1 from posts p2 join rounds r2 on r2.id = p2.round_id
           where r2.profile_id = v and p2.kind = 'moment'
             and p2.created_at > now() - interval '60 days'
             and p2.body like 'Not the day %') then
    -- the observation, never the verdict. Four guards, and every one of them
    -- exists so this can never land on someone who does not deserve it:
    --   · 5+ prior rounds — a beginner is never the subject
    --   · index_source 'app' — their number is one the app DERIVED from their
    --     own scores, not a starter index they guessed at signup (the critic's
    --     catch: a beginner who typed 12 and shot a 20 differential would trip
    --     this on their first ever posted round)
    --   · 18 holes, so a nine is never judged as a full round
    --   · once per 60 days, so it can never become a drumbeat
    -- Every warmer headline outranks it: a return or a streak wins instead.
    v_moment := 'Not the day ' || v_name || ' had in mind. '
             || 'We''ll leave that one on the scorecard.';
  end if;

  if v_moment is null then return new; end if;

  -- round_id rides the post: delete the round, the headline goes with it
  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'moment', new.id, lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  return new;
end $function$;


-- ---- settle_week_clash ---------------------------------------------
CREATE OR REPLACE FUNCTION public.settle_week_clash(p_season uuid, p_week integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system',
            'All square in the clash — ' || firstname(v_a_name) || ' v '
                                        || firstname(v_b_name) || '.');
  end if;
  -- both idle: row settled above, no post (D52's honesty rule).

  return jsonb_build_object(
    'week', p_week, 'winner_member', v_winner,
    'a_best', v_a_best, 'b_best', v_b_best);
end $function$;


-- ---- snapshot_week -------------------------------------------------
CREATE OR REPLACE FUNCTION public.snapshot_week(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; wk integer; total_wk integer; payload jsonb;
begin
  select * into se from seasons where id = p_season;
  if se.status not in ('active','cup_final') then return; end if;
  if current_date <= se.starts_on then return; end if;

  total_wk := ceil((se.ends_on - se.starts_on + 1) / 7.0);
  wk := least(total_wk, floor((current_date - se.starts_on) / 7.0));
  if wk < 1 then return; end if;

  payload := jsonb_build_object(
    'squads', coalesce((
        select jsonb_agg(to_jsonb(t))
        from (select * from v_squad_standings
              where season_id = p_season order by points desc) t), '[]'::jsonb),
    'individuals', coalesce((
        select jsonb_agg(to_jsonb(t))
        from (select * from v_individual_standings
              where season_id = p_season order by points desc nulls last) t), '[]'::jsonb)
  );

  insert into standings_snapshots (season_id, week_no, standings)
  values (p_season, wk, payload)
  on conflict (season_id, week_no) do nothing;

  -- D166 · the comeback. FOUND is false when the conflict swallowed the
  -- insert, so a re-run of the same week can never re-tell the story.
  if found then
    perform post_week_comeback(p_season, wk);
  end if;
end $function$;

-- ---- self-enforcing ---------------------------------------------------------
-- These are the guards, asserted. A probe table rather than raise-on-failure so
-- every result is visible at once; the do-block below turns any failure into an
-- exception, so a regression cannot ship quietly.
create temp table probe(step text, result text);

-- 1 · the comeback refuses to speak before week 4, and refuses to guess
do $t$
declare v_season uuid; n1 int; n2 int;
begin
  select id into v_season from seasons where status='active' limit 1;
  select count(*) into n1 from posts where kind='moment' and body like '%points back three weeks ago%';
  perform post_week_comeback(v_season, 2);          -- too early
  perform post_week_comeback(v_season, 9999);       -- no snapshot at 9996
  select count(*) into n2 from posts where kind='moment' and body like '%points back three weeks ago%';
  insert into probe values ('comeback stays silent early / with no snapshot',
    case when n1 = n2 then 'silent' else 'SPOKE — BROKEN' end);
end $t$;

-- 2 · the bad-round guard: a beginner with a MANUAL starter index is never the subject
do $t$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname='round_moments' and pronamespace='public'::regnamespace;
  insert into probe values ('bad round requires an app-derived number',
    case when position('index_source_at_post' in v_src) > 0 then 'guarded' else 'UNGUARDED — BROKEN' end);
  insert into probe values ('bad round requires history',
    case when position('v_prior_n >= 5' in v_src) > 0 then 'guarded' else 'UNGUARDED — BROKEN' end);
  insert into probe values ('welcome back outranks the bad day',
    case when position('Welcome back' in v_src) < position('had in mind' in v_src)
         then 'ordered correctly' else 'WRONG ORDER — BROKEN' end);
end $t$;

-- 3 · THE CRITICAL ONE: last place must never fire inside a Cup Final, where
--     the ranked set holds only finalists and the bottom row is the 4th-best
--     team in the league
do $t$
declare v_src text; v_pos int;
begin
  select prosrc into v_src from pg_proc
   where proname='close_season' and pronamespace='public'::regnamespace;
  v_pos := position('Someone had to complete the field' in v_src);
  insert into probe values ('last place exists', case when v_pos > 0 then 'yes' else 'MISSING' end);
  insert into probe values ('last place refuses a Cup Final',
    case when position('v_field >= 4 and not v_cup' in v_src) > 0
         then 'guarded' else 'WOULD NAME A FINALIST — BROKEN' end);
end $t$;

-- 4 · the blown lead now names the deposed side
do $t$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname='squad_lead_moments' and pronamespace='public'::regnamespace;
  insert into probe values ('blown lead speaks',
    case when position('Formerly' in v_src) > 0 or position('Once upon a time' in v_src) > 0
         then 'yes' else 'MISSING' end);
  insert into probe values ('no shouting returned',
    case when v_src ~ 'SNATCHED|JUST SNATCHED' then 'SHOUTING — BROKEN' else 'clean' end);
end $t$;

-- 5 · rivalry heat fires at 3 and 5 only
do $t$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname='settle_week_clash' and pronamespace='public'::regnamespace;
  insert into probe values ('rivalry heat',
    case when position('becoming a problem' in v_src) > 0 and position('v_run = 3' in v_src) > 0
              and position('v_run = 5' in v_src) > 0
         then 'fires at 3 and 5' else 'MISSING' end);
end $t$;

-- 6 · D37 · the new function is not reachable by anon
insert into probe values ('post_week_comeback anon-callable',
  case when has_function_privilege('anon','public.post_week_comeback(uuid, integer)','execute')
       then 'YES — BROKEN' else 'no' end);

do $gate$
declare n int;
begin
  select count(*) into n from probe where result like '%BROKEN%' or result like '%MISSING%';
  if n > 0 then
    raise exception 'D166: % guard(s) failed — see the probe table', n;
  end if;
end $gate$;

drop table probe;
