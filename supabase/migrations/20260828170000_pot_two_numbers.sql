-- ============================================================================
-- D106 (spec/decision-log.md) — the pot has two numbers.
--
--   the pot   = buy-in × roster        what the league agreed to (unchanged)
--   collected = sum(buy_ins.paid)      the cash that exists
--
-- Until now every surface, and — decisively — award_season_trophies, split
-- buy-in × ALL members into season_payouts, so a member who never paid still
-- inflated every "You're owed" line in the ceremony (audit 02 §7.6, audit 06
-- §9.3). From here the ceremony PAYS FROM COLLECTED:
--
--   1. recompute_season_payouts(season)  one function owns the arithmetic —
--      pot, collected, the 60/25/15 split of COLLECTED with the exact penny
--      rules of 20260725190000 (champion absorbs the rounding; per-seat pennies
--      to the earliest seats, mirroring csSplitCents), delete + re-insert
--      season_payouts, and seasons.pot_cents / collected_cents stored (§16:
--      the deciding numbers are recorded, never re-derived).
--   2. award_season_trophies  keeps its trophy inserts, hands the money to (1).
--   3. close_season  byte-identical except the settlement post now reads
--      "The pot: $600 · collected $450 · champs … · still owed: $150 (Metz, Ed)"
--      — the old single-number line when collected = pot.
--   4. mark_buy_in  after `complete`, a late payment re-runs (1) and posts the
--      new split — the ceremony re-renders from the ledger, nothing hand-edited.
--
-- $0 leagues (D70): pot = 0, no payout rows, no posts — unchanged.
-- Deploy skew: both clients fall back to the old local math when the two
-- seasons columns are absent; nothing here changes an RPC signature.
-- D37: explicit revoke/grant on every function touched. seasons carries a
-- table-level SELECT for authenticated (no frozen column list — that is a
-- profiles-only condition), so the two new columns are readable at once.
-- ============================================================================

alter table public.seasons
  add column if not exists pot_cents       integer,
  add column if not exists collected_cents integer;

comment on column public.seasons.pot_cents       is 'D106: buy-in × roster at close (what the roster owes); null until the season closes';
comment on column public.seasons.collected_cents is 'D106: sum of paid buy-ins at close, re-stamped by a late mark_buy_in; payouts split THIS';

-- ---- 1. one function owns the money ---------------------------------------
create or replace function public.recompute_season_payouts(p_season uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  se record; st record;
  n_members int; pot_c bigint; col_c bigint;
  c_cents int; r_cents int; k_cents int; n_champ int; n_run int;
  v_owed jsonb;
begin
  select * into se from seasons where id = p_season;
  if not found then return null; end if;
  select * into st from league_settings where league_id = se.league_id;

  select count(*) into n_members from league_members where league_id = se.league_id;
  pot_c := coalesce(st.buyin_cents, 0)::bigint * n_members;
  select coalesce(sum(b.amount_cents), 0) into col_c
    from buy_ins b
    join league_members lm on lm.id = b.member_id and lm.league_id = se.league_id
   where b.season_id = p_season and b.paid;
  col_c := least(col_c, pot_c);            -- a stale amount can't collect more than the roster owes

  -- who still owes: every roster member without a paid buy-in for this season
  select coalesce(jsonb_agg(jsonb_build_object(
           'member_id', lm.id,
           'name', coalesce(p.display_name, 'A golfer'),
           'cents', coalesce(st.buyin_cents, 0)) order by p.display_name), '[]'::jsonb)
    into v_owed
    from league_members lm
    join profiles p on p.id = lm.profile_id
   where lm.league_id = se.league_id
     and coalesce(st.buyin_cents, 0) > 0
     and not exists (select 1 from buy_ins b where b.season_id = p_season and b.member_id = lm.id and b.paid);

  -- the ledger is rewritten from scratch every time: idempotent, and a late
  -- payment simply produces a bigger split (D106 §4)
  delete from season_payouts where season_id = p_season;

  if se.status = 'complete' and col_c > 0 then
    -- champion absorbs the champ/runner/king rounding so the three sum to collected
    r_cents := round(col_c * coalesce(st.payout_runnerup, 25) / 100.0);
    k_cents := round(col_c * coalesce(st.payout_king, 15) / 100.0);
    c_cents := greatest(0, col_c::int - r_cents - k_cents);

    select count(*) into n_champ from (
      select lm.profile_id from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.champion_squad_id
      union all
      select lm.profile_id from league_members lm
       where se.champion_squad_id is null and lm.id = se.champion_member_id) q;
    select count(*) into n_run from (
      select lm.profile_id from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.runnerup_squad_id
      union all
      select lm.profile_id from league_members lm
       where se.runnerup_squad_id is null and lm.id = se.runnerup_member_id) q;

    -- the per-seat split rides the remainder to the earliest seats (row_number
    -- order), exactly like csSplitCents, so the rows sum to c_cents / r_cents
    if n_champ > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, q.profile_id,
             (c_cents / n_champ) + case when q.rn <= (c_cents % n_champ) then 1 else 0 end,
             'Cup champion'
        from (
          select pid as profile_id, row_number() over (order by pid) as rn
            from (select lm.profile_id as pid from squad_members sm join league_members lm on lm.id = sm.member_id
                   where sm.squad_id = se.champion_squad_id
                  union all
                  select lm.profile_id from league_members lm
                   where se.champion_squad_id is null and lm.id = se.champion_member_id) m
        ) q
      on conflict do nothing;
    end if;
    if n_run > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, q.profile_id,
             (r_cents / n_run) + case when q.rn <= (r_cents % n_run) then 1 else 0 end,
             'Runner-up'
        from (
          select pid as profile_id, row_number() over (order by pid) as rn
            from (select lm.profile_id as pid from squad_members sm join league_members lm on lm.id = sm.member_id
                   where sm.squad_id = se.runnerup_squad_id
                  union all
                  select lm.profile_id from league_members lm
                   where se.runnerup_squad_id is null and lm.id = se.runnerup_member_id) m
        ) q
      on conflict do nothing;
    end if;
    if se.points_king_member_id is not null and k_cents > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, lm.profile_id, k_cents, 'Points king'
        from league_members lm where lm.id = se.points_king_member_id
      on conflict do nothing;
    end if;
  end if;

  update seasons set pot_cents = pot_c, collected_cents = col_c where id = p_season;

  return jsonb_build_object(
    'pot_cents', pot_c, 'collected_cents', col_c,
    'champ_cents', coalesce(c_cents, 0), 'runner_cents', coalesce(r_cents, 0), 'king_cents', coalesce(k_cents, 0),
    'still_owed', v_owed);
end $$;

-- engine-only: award_season_trophies and mark_buy_in call it; never a client
revoke all on function public.recompute_season_payouts(uuid) from public, anon, authenticated;
grant execute on function public.recompute_season_payouts(uuid) to service_role;

-- ---- 2. award_season_trophies: trophies here, money in (1) -----------------
create or replace function public.award_season_trophies(p_season uuid)
returns void
language plpgsql security definer set search_path = public as $$
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

  -- D67 → D106: what it paid, recorded once, in cents — from what was COLLECTED
  perform recompute_season_payouts(p_season);
end $$;

revoke all on function public.award_season_trophies(uuid) from public, anon, authenticated;
grant execute on function public.award_season_trophies(uuid) to service_role;

-- ---- 3. close_season: identical to 20260724230000 but for the pot post -----
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

-- ---- 4. mark_buy_in: a late payment re-runs the split ---------------------
create or replace function public.mark_buy_in(p_season uuid, p_member uuid, p_paid boolean)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_league uuid;
  v_status text;
  v_stake  integer;
  v_name   text;
  v_paid_n integer;
  v_total  integer;
  v_money  jsonb;
begin
  select league_id, status into v_league, v_status from seasons where id = p_season;
  if v_league is null then raise exception 'No such season'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro marks buy-ins'; end if;
  if not exists (select 1 from league_members where id = p_member and league_id = v_league) then
    raise exception 'Not a member of this league';
  end if;

  select coalesce(buyin_cents, 0) into v_stake from league_settings where league_id = v_league;

  insert into buy_ins (season_id, member_id, amount_cents, paid, marked_by, marked_at)
  values (p_season, p_member, coalesce(v_stake, 0), p_paid, my_member_id(v_league), now())
  on conflict (season_id, member_id) do update
    set paid = excluded.paid,
        marked_by = excluded.marked_by,
        marked_at = excluded.marked_at;

  select upper(coalesce(p.display_name, 'A MEMBER')) into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  if v_status = 'complete' then
    -- D106 §4: the ledger is rewritten from the new collected total and the
    -- room is told — the ceremony re-renders from season_payouts
    v_money := recompute_season_payouts(p_season);
    if p_paid and coalesce((v_money->>'collected_cents')::bigint, 0) > 0 then
      insert into posts (league_id, season_id, kind, member_id, body)
      values (v_league, p_season, 'system', my_member_id(v_league),
              v_name || '''S BUY-IN IS IN AFTER THE FINAL — PAYOUTS UPDATED: CHAMPS $'
              || round((v_money->>'champ_cents')::numeric / 100.0)
              || ' · RUNNER-UP $'   || round((v_money->>'runner_cents')::numeric / 100.0)
              || ' · POINTS KING $' || round((v_money->>'king_cents')::numeric / 100.0));
    end if;
    return;
  end if;

  if p_paid then
    select count(*) filter (where b.paid) into v_paid_n
      from buy_ins b where b.season_id = p_season;
    select count(*) into v_total from league_members where league_id = v_league;

    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, p_season, 'system', my_member_id(v_league),
            v_name || '''S BUY-IN IS IN — ' || v_paid_n || '/' || v_total || ' COLLECTED');
  end if;
end $$;

revoke all on function public.mark_buy_in(uuid, uuid, boolean) from public, anon;
grant execute on function public.mark_buy_in(uuid, uuid, boolean) to authenticated;

-- ---- self-enforcing: the grants are what this file says they are ----------
do $$
begin
  if has_function_privilege('anon', 'public.recompute_season_payouts(uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.recompute_season_payouts(uuid)', 'execute')
     or has_function_privilege('anon', 'public.close_season(uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.close_season(uuid)', 'execute')
     or has_function_privilege('anon', 'public.award_season_trophies(uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.award_season_trophies(uuid)', 'execute')
     or has_function_privilege('anon', 'public.mark_buy_in(uuid, uuid, boolean)', 'execute')
     or not has_function_privilege('authenticated', 'public.mark_buy_in(uuid, uuid, boolean)', 'execute') then
    raise exception 'D106: function grants are not what this migration declares';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'seasons' and column_name = 'collected_cents') then
    raise exception 'D106: seasons.collected_cents missing';
  end if;
end $$;
