-- ============================================================================
-- The Ryder — v2 gap closure (spec/ryder-v1.md v2 + §R12 sign-offs 2026-07-16)
--
-- The 07-13 build shipped schema + create/pair/resolve. This closes the gaps
-- the requirement doc surfaced:
--   1. DUEL ELIGIBILITY BUG: resolve_session read voided and sim rounds.
--      Now: not voided, source <> 'sim' (R12.1 signed off: exclude sim).
--   2. TIMEZONE (R12.2: creator's city): events.tz — attached events inherit
--      the league's active-season tz; standalone takes the creator's device
--      tz (client passes IANA name); fallback America/Phoenix.
--   3. THE TICK (R12.3): run_event_sessions() opens due sessions and resolves
--      past-close ones daily — the event runs itself; organizer buttons stay
--      as manual override. Org check relaxes to "human callers only" so the
--      cron (auth.uid() null) can drive it.
--   4. DRAW RULE ACTUALLY APPLIES: a final-points tie used to pick a winner
--      arbitrarily (order by points desc limit 1). Now: team_pvi = higher
--      summed duel PvI · defender retains · shared = winner stays null.
--   5. Roster guard (§R10): adds lock once any session has been scored.
--   6. Number-to-beat (batch-3 #17): event_session_targets() — live best-PvI
--      per side of each open duel (member-gated; rounds RLS is owner-only so
--      the chip needs a definer read). notify_target column seeds the opt-in
--      push (wiring = slice 3).
-- ============================================================================

alter table public.events
  add column if not exists tz text not null default 'America/Phoenix';
alter table public.event_players
  add column if not exists notify_target boolean not null default false;

-- ---- create_event: +p_tz, Sunday enforcement, league-season tz inherit -----
drop function if exists public.create_event(text,date,integer,integer,text,text,text,uuid);
create or replace function public.create_event(
  p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer,
  p_draw_rule text, p_team_a text, p_team_b text, p_league uuid default null,
  p_tz text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_event uuid; v_team_a uuid; v_cap uuid; i integer; v_open date; v_tz text;
begin
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'you must be in the league to run an event with it';
  end if;
  if extract(dow from p_starts_on) <> 0 then
    raise exception 'The Ryder starts on a Sunday — sessions run Sun to Sat';
  end if;
  -- tz: league's active season > creator's device (validated) > Phoenix
  if p_league is not null then
    select timezone into v_tz from seasons
     where league_id = p_league order by number desc limit 1;
  end if;
  if v_tz is null and p_tz is not null then
    begin perform now() at time zone p_tz; v_tz := p_tz;
    exception when others then v_tz := null; end;
  end if;
  v_tz := coalesce(v_tz, 'America/Phoenix');

  insert into events (name, created_by, league_id, starts_on, session_count,
                      session_weeks, draw_rule, tz)
  values (p_name, auth.uid(), p_league, p_starts_on,
          greatest(1, least(26, coalesce(p_sessions,3))),
          greatest(1, least(4, coalesce(p_session_weeks,1))),
          coalesce(p_draw_rule,'team_pvi'), v_tz)
  returning id into v_event;

  insert into event_teams (event_id, slot, name, color)
    values (v_event, 0, coalesce(p_team_a,'Team A'), 0) returning id into v_team_a;
  insert into event_teams (event_id, slot, name, color)
    values (v_event, 1, coalesce(p_team_b,'Team B'), 1);

  insert into event_players (event_id, profile_id, team_id, role, seed)
    values (v_event, auth.uid(), v_team_a, 'captain', 0) returning id into v_cap;
  update event_teams set captain_player_id = v_cap where id = v_team_a;

  for i in 1..(select session_count from events where id = v_event) loop
    v_open := p_starts_on + ((i-1) * 7 * (select session_weeks from events where id = v_event));
    insert into event_sessions (event_id, session_no, opens_on, closes_on)
      values (v_event, i, v_open, v_open + (7 * (select session_weeks from events where id = v_event)) - 1);
  end loop;

  return v_event;
end $$;
grant execute on function public.create_event(text,date,integer,integer,text,text,text,uuid,text) to authenticated;

-- ---- roster guard: adds lock once a session has been scored (§R10) ---------
create or replace function public.add_event_player(p_event uuid, p_profile uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_seed integer;
begin
  if not is_event_organizer(p_event) then raise exception 'organizer only'; end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'Roster locks once a session has been scored';
  end if;
  select coalesce(max(seed),0)+1 into v_seed from event_players where event_id = p_event;
  insert into event_players (event_id, profile_id, seed)
    values (p_event, p_profile, v_seed)
    on conflict (event_id, profile_id) do nothing
    returning id into v_id;
  return v_id;
end $$;

-- ---- generate_pairings: cron-drivable (human callers still organizer-only) -
create or replace function public.generate_pairings(p_session uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_team_a uuid; v_team_b uuid; v_pairs integer; i integer;
  a_ids uuid[]; b_ids uuid[];
begin
  select event_id into v_event from event_sessions where id = p_session;
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
  return v_pairs;
end $$;

-- ---- resolve_session: eligibility fix + the draw rule + cron-drivable ------
create or replace function public.resolve_session(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_open date; v_close date; v_allow integer; v_rule text; v_def uuid;
  d record; a_pvi numeric; b_pvi numeric; a_rid uuid; b_rid uuid;
  v_res text; v_ap numeric; v_bp numeric;
  v_pairs integer; m_total numeric;
  v_ta uuid; v_tb uuid; pa numeric; pb numeric; sa numeric; sb numeric;
begin
  select s.event_id, s.opens_on, s.closes_on, e.allowance, e.draw_rule, e.defender_team_id
    into v_event, v_open, v_close, v_allow, v_rule, v_def
    from event_sessions s join events e on e.id = s.event_id
   where s.id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'organizer only';
  end if;

  for d in select * from event_duels where session_id = p_session loop
    -- best ELIGIBLE round in the window: never voided, never sim (R12.1)
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
    elsif b_pvi is null then
      v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif a_pvi is null then
      v_res := 'b'; v_ap := 0; v_bp := 1;
    elsif a_pvi > b_pvi then
      v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif b_pvi > a_pvi then
      v_res := 'b'; v_ap := 0; v_bp := 1;
    else
      v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    end if;

    update event_duels
       set a_round = a_rid, b_round = b_rid, a_pvi = a_pvi, b_pvi = b_pvi,
           a_points = v_ap, b_points = v_bp, result = v_res, resolved_at = now()
     where id = d.id;
  end loop;

  update event_sessions set status = 'closed' where id = p_session;

  select id into v_ta from event_teams where event_id = v_event and slot = 0;
  select id into v_tb from event_teams where event_id = v_event and slot = 1;
  select coalesce(sum(points),0) into pa from v_event_scoreboard where event_id = v_event and team_id = v_ta;
  select coalesce(sum(points),0) into pb from v_event_scoreboard where event_id = v_event and team_id = v_tb;

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
      -- a DRAW: the draw rule finally speaks (§R4)
      if v_rule = 'defender' and v_def is not null then
        update events set status='complete', winner_team_id = v_def where id = v_event;
      elsif v_rule = 'shared' then
        update events set status='complete', winner_team_id = null where id = v_event;
      else
        -- team_pvi: higher summed duel PvI across the event takes it (receipts
        -- live on the duels; a dead-even sum shares the cup)
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
end $$;

-- ---- the tick: sessions open and resolve themselves (R12.3) -----------------
create or replace function public.run_event_sessions()
returns void language plpgsql security definer set search_path = public as $$
declare s record; v_today date;
begin
  for s in
    select es.id, es.opens_on, es.closes_on, es.status, e.tz, e.id as ev
      from event_sessions es join events e on e.id = es.event_id
     where e.status in ('setup','live')
     order by es.opens_on
  loop
    v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
    if s.status = 'upcoming' and s.opens_on <= v_today then
      -- only auto-open when both benches have someone to send out
      if exists (select 1 from event_players ep join event_teams t on t.id = ep.team_id
                  where t.event_id = s.ev and t.slot = 0)
         and exists (select 1 from event_players ep join event_teams t on t.id = ep.team_id
                  where t.event_id = s.ev and t.slot = 1) then
        perform generate_pairings(s.id);
      end if;
    elsif s.status = 'open' and s.closes_on < v_today then
      perform resolve_session(s.id);
    end if;
  end loop;
end $$;

-- schedule alongside the other daily jobs (pg_cron; ~00:15 Phoenix = 07:15 UTC)
do $$ begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('run_event_sessions', '15 7 * * *',
                          'select public.run_event_sessions()');
  end if;
end $$;

-- ---- the number to beat (batch-3 #17): live targets for OPEN duels ---------
-- Member-gated definer read: rounds RLS is owner-only, but your opponent's
-- current best inside an open session is the game itself.
create or replace function public.event_session_targets(p_session uuid)
returns table(duel_id uuid, a_pvi numeric, b_pvi numeric)
language sql stable security definer set search_path = public as $$
  select d.id,
    (select (r.index_at_post * e.allowance / 100.0) - r.differential
       from rounds r join event_players ep on ep.id = d.a_player
      where r.profile_id = ep.profile_id and r.played_on between s.opens_on and s.closes_on
        and not r.voided and coalesce(r.source,'app') <> 'sim'
        and r.index_at_post is not null and r.differential is not null
      order by 1 desc nulls last limit 1),
    (select (r.index_at_post * e.allowance / 100.0) - r.differential
       from rounds r join event_players ep on ep.id = d.b_player
      where r.profile_id = ep.profile_id and r.played_on between s.opens_on and s.closes_on
        and not r.voided and coalesce(r.source,'app') <> 'sim'
        and r.index_at_post is not null and r.differential is not null
      order by 1 desc nulls last limit 1)
  from event_duels d
  join event_sessions s on s.id = d.session_id
  join events e on e.id = s.event_id
  where d.session_id = p_session and s.status = 'open'
    and is_event_member(s.event_id);
$$;
grant execute on function public.event_session_targets(uuid) to authenticated;
