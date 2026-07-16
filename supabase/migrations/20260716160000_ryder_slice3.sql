-- ============================================================================
-- The Ryder — slice 3: the drama rails (spec/ryder-v1.md §R7 slice 3, §R8)
--
--   1. posts gain event_id (events-engine decision #9): league_id relaxes to
--      nullable, a post belongs to a league OR an event. Event members read
--      their event's board; the push webhook fans event posts to event players
--      (edge function updated alongside).
--   2. The engine tells the story: pairings post at session open, results +
--      running scoreline post at resolve, completion post names the cup AND
--      the MVP (best duel record, tiebreak total PvI — §R8, no pot cut).
--   3. Shared cups mint trophies too (award_event_trophies covered winner-
--      only; a halved Ryder is famous, both teams engrave).
--   4. The opt-in taunt (batch-3 #17): push_nudges + a rounds trigger — when
--      your opponent posts into your open duel, and YOU opted in
--      (notify_target), you get the number to beat. set_event_notify() is the
--      toggle.
--
-- Ops note: requires `supabase functions deploy push` AND a Database Webhook
-- on push_nudges INSERT → the push function (same x-push-secret header as the
-- posts webhook). Secrets never live in migrations.
-- ============================================================================

-- ---- 1. posts belong to a league OR an event --------------------------------
alter table public.posts alter column league_id drop not null;
alter table public.posts
  add column if not exists event_id uuid references public.events(id) on delete cascade;
alter table public.posts drop constraint if exists posts_home_check;
alter table public.posts add constraint posts_home_check
  check (league_id is not null or event_id is not null);
create index if not exists posts_event_created on public.posts(event_id, created_at)
  where event_id is not null;

drop policy if exists posts_read on public.posts;
create policy posts_read on public.posts for select to authenticated
  using ((league_id is not null and is_league_member(league_id))
      or (event_id is not null and is_event_member(event_id)));

-- ---- helpers ----------------------------------------------------------------
create or replace function public.evhalf(n numeric) returns text
language sql immutable as $$
  select case when n - floor(n) >= 0.5
    then floor(n)::int::text || '½' else floor(n)::int::text end;
$$;

create or replace function public.event_post(p_event uuid, p_body text)
returns void language sql security definer set search_path = public as $$
  insert into posts (event_id, kind, body) values (p_event, 'system', left(p_body, 400));
$$;
-- engine-only: not granted to authenticated

-- ---- 2a. pairings post at session open --------------------------------------
create or replace function public.generate_pairings(p_session uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_no int; v_team_a uuid; v_team_b uuid; v_pairs integer; i integer;
  a_ids uuid[]; b_ids uuid[]; v_lines text;
begin
  select event_id, session_no into v_event, v_no from event_sessions where id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'organizer only';
  end if;

  select id into v_team_a from event_teams where event_id = v_event and slot = 0;
  select id into v_team_b from event_teams where event_id = v_event and slot = 1;

  select array_agg(id order by benched_count, seed) into a_ids
    from event_players where event_id = v_event and team_id = v_team_a;
  select array_agg(id order by benched_count, seed) into b_ids
    from event_players where event_id = v_event and team_id = v_team_b;

  v_pairs := least(coalesce(array_length(a_ids,1),0), coalesce(array_length(b_ids,1),0));
  delete from event_duels where session_id = p_session;
  for i in 1..v_pairs loop
    insert into event_duels (event_id, session_id, a_player, b_player)
      values (v_event, p_session, a_ids[i], b_ids[i]);
  end loop;

  for i in (v_pairs+1)..coalesce(array_length(a_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = a_ids[i];
  end loop;
  for i in (v_pairs+1)..coalesce(array_length(b_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = b_ids[i];
  end loop;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = v_event and status = 'setup';

  if v_pairs > 0 then
    select string_agg(upper(pa.display_name) || ' VS ' || upper(pb.display_name), ' · ')
      into v_lines
      from event_duels d
      join event_players ea on ea.id = d.a_player join profiles pa on pa.id = ea.profile_id
      join event_players eb on eb.id = d.b_player join profiles pb on pb.id = eb.profile_id
     where d.session_id = p_session;
    perform event_post(v_event, 'SESSION ' || v_no || ' PAIRINGS: ' || v_lines);
  end if;
  return v_pairs;
end $$;

-- ---- 2b. results + scoreline at resolve, completion post with the MVP -------
create or replace function public.resolve_session(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_no int; v_open date; v_close date; v_allow integer; v_rule text; v_def uuid;
  v_ename text;
  d record; a_pvi numeric; b_pvi numeric; a_rid uuid; b_rid uuid;
  v_res text; v_ap numeric; v_bp numeric;
  v_pairs integer; m_total numeric;
  v_ta uuid; v_tb uuid; v_na text; v_nb text; pa numeric; pb numeric; sa numeric; sb numeric;
  v_lines text; v_score text; v_win uuid; v_was text;
  mvp_name text; mvp_rec text;
begin
  select s.event_id, s.session_no, s.opens_on, s.closes_on, e.allowance, e.draw_rule,
         e.defender_team_id, e.name, e.status
    into v_event, v_no, v_open, v_close, v_allow, v_rule, v_def, v_ename, v_was
    from event_sessions s join events e on e.id = s.event_id
   where s.id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'organizer only';
  end if;

  for d in select * from event_duels where session_id = p_session loop
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into a_rid, a_pvi
      from rounds r join event_players ep on ep.id = d.a_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into b_rid, b_pvi
      from rounds r join event_players ep on ep.id = d.b_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;

    if a_pvi is null and b_pvi is null then
      v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    elsif b_pvi is null then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif a_pvi is null then v_res := 'b'; v_ap := 0; v_bp := 1;
    elsif a_pvi > b_pvi then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif b_pvi > a_pvi then v_res := 'b'; v_ap := 0; v_bp := 1;
    else v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    end if;

    update event_duels
       set a_round = a_rid, b_round = b_rid, a_pvi = a_pvi, b_pvi = b_pvi,
           a_points = v_ap, b_points = v_bp, result = v_res, resolved_at = now()
     where id = d.id;
  end loop;

  update event_sessions set status = 'closed' where id = p_session;

  select id, name into v_ta, v_na from event_teams where event_id = v_event and slot = 0;
  select id, name into v_tb, v_nb from event_teams where event_id = v_event and slot = 1;
  select coalesce(sum(points),0) into pa from v_event_scoreboard where event_id = v_event and team_id = v_ta;
  select coalesce(sum(points),0) into pb from v_event_scoreboard where event_id = v_event and team_id = v_tb;

  -- the session story: every duel line + the running scoreline
  select string_agg(line, ' · ') into v_lines from (
    select case d.result
        when 'a' then upper(pa2.display_name) || ' DEF. ' || upper(pb2.display_name)
              || ' ' || (case when d.a_pvi>=0 then '+' else '' end) || round(d.a_pvi,1)
              || '/' || coalesce((case when d.b_pvi>=0 then '+' else '' end) || round(d.b_pvi,1), 'NO ROUND')
        when 'b' then upper(pb2.display_name) || ' DEF. ' || upper(pa2.display_name)
              || ' ' || (case when d.b_pvi>=0 then '+' else '' end) || round(d.b_pvi,1)
              || '/' || coalesce((case when d.a_pvi>=0 then '+' else '' end) || round(d.a_pvi,1), 'NO ROUND')
        else upper(pa2.display_name) || ' HALVED ' || upper(pb2.display_name)
      end as line
      from event_duels d
      join event_players ea on ea.id = d.a_player join profiles pa2 on pa2.id = ea.profile_id
      join event_players eb on eb.id = d.b_player join profiles pb2 on pb2.id = eb.profile_id
     where d.session_id = p_session
     order by d.id
  ) x;
  v_score := case when pa = pb then 'LEVEL ' || evhalf(pa) || '–' || evhalf(pb)
                  when pa > pb then upper(v_na) || ' LEAD ' || evhalf(pa) || '–' || evhalf(pb)
                  else upper(v_nb) || ' LEAD ' || evhalf(pb) || '–' || evhalf(pa) end;
  if v_lines is not null then
    perform event_post(v_event, 'SESSION ' || v_no || ': ' || v_lines || ' — ' || v_score);
  end if;

  -- clinch / completion (draw rule from 20260716150000, unchanged)
  select least(
      (select count(*) from event_players where event_id = v_event and team_id = v_ta),
      (select count(*) from event_players where event_id = v_event and team_id = v_tb))
    into v_pairs;
  m_total := v_pairs * (select session_count from events where id = v_event);

  if m_total > 0 and greatest(pa, pb) > m_total/2.0 then
    update events set status='complete',
      winner_team_id = case when pa > pb then v_ta else v_tb end
      where id = v_event;
  elsif not exists (select 1 from event_sessions where event_id=v_event and status <> 'closed') then
    if pa <> pb then
      update events set status='complete',
        winner_team_id = case when pa > pb then v_ta else v_tb end
        where id = v_event;
    else
      if v_rule = 'defender' and v_def is not null then
        update events set status='complete', winner_team_id = v_def where id = v_event;
      elsif v_rule = 'shared' then
        update events set status='complete', winner_team_id = null where id = v_event;
      else
        select coalesce(sum(case when ep.team_id = v_ta then x.pvi end),0),
               coalesce(sum(case when ep.team_id = v_tb then x.pvi end),0)
          into sa, sb
          from (
            select a_player as player, a_pvi as pvi from event_duels where event_id = v_event and a_pvi is not null
            union all
            select b_player, b_pvi from event_duels where event_id = v_event and b_pvi is not null
          ) x join event_players ep on ep.id = x.player;
        update events set status='complete',
          winner_team_id = case when sa > sb then v_ta when sb > sa then v_tb else null end
          where id = v_event;
      end if;
    end if;
  end if;

  -- completion story: the cup + the MVP (best record, tiebreak total PvI)
  if v_was <> 'complete' and (select status from events where id = v_event) = 'complete' then
    select upper(pr.display_name), s.w || '-' || s.l || '-' || s.h
      into mvp_name, mvp_rec
      from (
        select ep.profile_id,
          count(*) filter (where (d.a_player=ep.id and d.result='a') or (d.b_player=ep.id and d.result='b')) w,
          count(*) filter (where (d.a_player=ep.id and d.result='b') or (d.b_player=ep.id and d.result='a')) l,
          count(*) filter (where d.result='halve') h,
          coalesce(sum(case when d.a_player=ep.id then d.a_pvi when d.b_player=ep.id then d.b_pvi end),0) tot
        from event_players ep
        join event_duels d on d.event_id = ep.event_id
             and (d.a_player = ep.id or d.b_player = ep.id) and d.result <> 'pending'
        where ep.event_id = v_event
        group by ep.id, ep.profile_id
        order by w desc, tot desc limit 1
      ) s join profiles pr on pr.id = s.profile_id;
    select winner_team_id into v_win from events where id = v_event;
    perform event_post(v_event,
      upper(v_ename) || ': '
      || case when v_win is null then 'THE CUP IS SHARED — ' || upper(v_na) || ' AND ' || upper(v_nb)
              when v_win = v_ta then upper(v_na) || ' TAKE THE CUP ' || evhalf(pa) || '–' || evhalf(pb)
              else upper(v_nb) || ' TAKE THE CUP ' || evhalf(pb) || '–' || evhalf(pa) end
      || coalesce(' · MVP: ' || mvp_name || ' (' || mvp_rec || ')', ''));
  end if;
end $$;

-- ---- 3. shared cups engrave both teams --------------------------------------
create or replace function public.award_event_trophies(p_event uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_win uuid; v_name text;
begin
  select winner_team_id, name into v_win, v_name
    from events where id = p_event and status = 'complete';
  if not found then return; end if;
  if v_win is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v_name, 'The Ryder', 'winner', p_event,
             extract(year from current_date)::int
        from event_players ep where ep.team_id = v_win
      on conflict do nothing;
  else
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v_name, 'The Ryder · shared', 'shared', p_event,
             extract(year from current_date)::int
        from event_players ep where ep.team_id is not null
      on conflict do nothing;
  end if;
end $$;

create or replace function public.trg_event_complete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'complete' and (old.status is distinct from 'complete') then
    perform award_event_trophies(new.id);
  end if;
  return new;
end $$;

-- ---- 4. the opt-in taunt -----------------------------------------------------
create table if not exists public.push_nudges (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title      text not null,
  body       text not null,
  created_at timestamptz not null default now()
);
alter table public.push_nudges enable row level security;
-- no policies: service-role webhook reads, definer triggers write

create or replace function public.set_event_notify(p_event uuid, p_on boolean)
returns void language sql security definer set search_path = public as $$
  update event_players set notify_target = p_on
   where event_id = p_event and profile_id = auth.uid();
$$;
grant execute on function public.set_event_notify(uuid, boolean) to authenticated;

-- ---- 5. the rivalry object's DUELS facet (batch-3 #18: ships WITH v1) -------
-- One rivalry per pair, faceted: weekly clashes + Ryder duels, never blended.
-- Return-type change → DROP first (the 42P13 lesson).
drop function if exists public.my_rivalries();
create or replace function public.my_rivalries()
returns table (
  opponent uuid, display_name text, handle text, marker text,
  wins int, losses int, ties int, meetings int, lead text,
  duel_wins int, duel_losses int, duel_halves int
)
language sql stable security definer set search_path = public as $$
  with shared as (
    select distinct lm2.profile_id as opp, s.id as season_id
      from league_members lm1
      join league_members lm2
        on lm2.league_id = lm1.league_id and lm2.profile_id <> lm1.profile_id
      join seasons s on s.league_id = lm1.league_id
     where lm1.profile_id = auth.uid()
  ),
  mine as (
    select rr.season_id, date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id = auth.uid()
     group by 1, 2
  ),
  opp as (
    select rr.profile_id as opp, rr.season_id,
           date_trunc('week', rr.played_on)::date as wk, max(rr.pvi) as pvi
      from v_rounds_ranked rr
     where rr.profile_id in (select opp from shared)
     group by 1, 2, 3
  ),
  clash as (
    select o.opp, o.wk, max(m.pvi) as my_best, max(o.pvi) as opp_best
      from opp o
      join shared sh on sh.opp = o.opp and sh.season_id = o.season_id
      join mine   m  on m.season_id = o.season_id and m.wk = o.wk
     group by o.opp, o.wk
  ),
  agg as (
    select opp,
           count(*) filter (where my_best > opp_best) as wins,
           count(*) filter (where my_best < opp_best) as losses,
           count(*) filter (where my_best = opp_best) as ties
      from clash group by opp
  ),
  -- the duels facet: resolved Ryder duels between me and each opponent
  duels as (
    select case when ea.profile_id = auth.uid() then eb.profile_id else ea.profile_id end as opp,
           count(*) filter (where (ea.profile_id = auth.uid() and d.result = 'a')
                              or (eb.profile_id = auth.uid() and d.result = 'b')) as dw,
           count(*) filter (where (ea.profile_id = auth.uid() and d.result = 'b')
                              or (eb.profile_id = auth.uid() and d.result = 'a')) as dl,
           count(*) filter (where d.result = 'halve') as dh
      from event_duels d
      join event_players ea on ea.id = d.a_player
      join event_players eb on eb.id = d.b_player
     where d.result <> 'pending'
       and (ea.profile_id = auth.uid() or eb.profile_id = auth.uid())
     group by 1
  )
  select coalesce(a.opp, du.opp), p.display_name, p.handle, p.marker,
         coalesce(a.wins,0)::int, coalesce(a.losses,0)::int, coalesce(a.ties,0)::int,
         (coalesce(a.wins,0) + coalesce(a.losses,0) + coalesce(a.ties,0))::int as meetings,
         case when coalesce(a.wins,0) > coalesce(a.losses,0) then 'up'
              when coalesce(a.wins,0) < coalesce(a.losses,0) then 'down'
              else 'even' end as lead,
         coalesce(du.dw,0)::int, coalesce(du.dl,0)::int, coalesce(du.dh,0)::int
    from agg a
    full outer join duels du on du.opp = a.opp
    join profiles p on p.id = coalesce(a.opp, du.opp)
   where (coalesce(a.wins,0)+coalesce(a.losses,0)+coalesce(a.ties,0)
          + coalesce(du.dw,0)+coalesce(du.dl,0)+coalesce(du.dh,0)) >= 1
     and p.deleted_at is null
   order by (coalesce(a.wins,0)+coalesce(a.losses,0)+coalesce(a.ties,0)
          + coalesce(du.dw,0)+coalesce(du.dl,0)+coalesce(du.dh,0)) desc,
          coalesce(a.wins,0) desc, p.display_name;
$$;
grant execute on function public.my_rivalries() to authenticated;

-- when a round lands in an open duel, the opted-in opponent hears about it
create or replace function public.round_duel_nudge() returns trigger
language plpgsql security definer set search_path = public as $$
declare d record; v_best numeric; v_name text;
begin
  if new.voided or coalesce(new.source,'app') = 'sim'
     or new.index_at_post is null or new.differential is null then
    return new;
  end if;
  for d in
    select du.id, s.opens_on, s.closes_on, s.closes_on - current_date as days_left,
           e.name as ename, e.allowance,
           case when ea.profile_id = new.profile_id then eb.profile_id else ea.profile_id end as opp_profile,
           case when ea.profile_id = new.profile_id then eb.notify_target else ea.notify_target end as opp_wants,
           case when ea.profile_id = new.profile_id then ea.profile_id else eb.profile_id end as me_profile
      from event_duels du
      join event_sessions s on s.id = du.session_id and s.status = 'open'
      join events e on e.id = du.event_id and e.status = 'live'
      join event_players ea on ea.id = du.a_player
      join event_players eb on eb.id = du.b_player
     where du.result = 'pending'
       and new.played_on between s.opens_on and s.closes_on
       and (ea.profile_id = new.profile_id or eb.profile_id = new.profile_id)
  loop
    if not d.opp_wants then continue; end if;
    -- the standing target = the poster's BEST in the window (this round or better)
    select max((r.index_at_post * d.allowance / 100.0) - r.differential) into v_best
      from rounds r
     where r.profile_id = new.profile_id
       and r.played_on between d.opens_on and d.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null;
    select display_name into v_name from profiles where id = new.profile_id;
    insert into push_nudges (profile_id, title, body)
    values (d.opp_profile, d.ename,
      coalesce(v_name,'Your opponent') || ' posted — '
      || (case when v_best >= 0 then '+' else '' end) || round(v_best,1) || ' to beat · '
      || case when d.days_left <= 0 then 'closes tonight'
              else d.days_left || ' day' || case when d.days_left = 1 then '' else 's' end || ' left' end);
  end loop;
  return new;
end $$;
drop trigger if exists round_duel_nudge_trg on public.rounds;
create trigger round_duel_nudge_trg after insert on public.rounds
  for each row execute function public.round_duel_nudge();
