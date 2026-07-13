-- The Ryder — standalone event mode (spec/ryder-v1.md).
--
-- Events are first-class and separate from leagues: two teams, N weekly
-- sessions of PvI duels, first to (M/2 + 0.5) takes the cup. Nothing here
-- touches league semantics. Rounds are never mutated — a duel just reads the
-- best round each player posted inside the session window. Writes go through
-- security-definer RPCs; members read their own event via RLS.

-- ========================================================================
-- Tables
-- ========================================================================
create table if not exists public.events (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  created_by     uuid not null references public.profiles(id),
  kind           text not null default 'ryder',
  status         text not null default 'setup' check (status in ('setup','live','complete')),
  starts_on      date not null,
  session_count  integer not null default 3 check (session_count between 1 and 26),
  session_weeks  integer not null default 1 check (session_weeks between 1 and 4),
  draw_rule      text not null default 'team_pvi' check (draw_rule in ('team_pvi','defender','shared')),
  defender_team_id uuid,
  allowance      integer not null default 100,
  winner_team_id uuid,
  created_at     timestamptz not null default now()
);

create table if not exists public.event_teams (
  id                uuid primary key default gen_random_uuid(),
  event_id          uuid not null references public.events(id) on delete cascade,
  slot              integer not null check (slot in (0,1)),
  name              text not null,
  color             integer not null default 0,
  captain_player_id uuid,
  unique (event_id, slot)
);

create table if not exists public.event_players (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid not null references public.events(id) on delete cascade,
  profile_id    uuid not null references public.profiles(id) on delete cascade,
  team_id       uuid references public.event_teams(id) on delete set null,
  role          text not null default 'player' check (role in ('captain','player')),
  seed          integer not null default 0,
  benched_count integer not null default 0,
  created_at    timestamptz not null default now(),
  unique (event_id, profile_id)
);
create index if not exists event_players_event_idx on public.event_players(event_id);

create table if not exists public.event_sessions (
  id         uuid primary key default gen_random_uuid(),
  event_id   uuid not null references public.events(id) on delete cascade,
  session_no integer not null,
  opens_on   date not null,
  closes_on  date not null,
  status     text not null default 'upcoming' check (status in ('upcoming','open','closed')),
  weight     numeric not null default 1,
  unique (event_id, session_no)
);

create table if not exists public.event_duels (
  id          uuid primary key default gen_random_uuid(),
  event_id    uuid not null references public.events(id) on delete cascade,
  session_id  uuid not null references public.event_sessions(id) on delete cascade,
  a_player    uuid not null references public.event_players(id) on delete cascade,
  b_player    uuid not null references public.event_players(id) on delete cascade,
  a_round     uuid references public.rounds(id) on delete set null,
  b_round     uuid references public.rounds(id) on delete set null,
  a_pvi       numeric,
  b_pvi       numeric,
  a_points    numeric not null default 0,
  b_points    numeric not null default 0,
  result      text not null default 'pending' check (result in ('pending','a','b','halve')),
  resolved_at timestamptz
);
create index if not exists event_duels_session_idx on public.event_duels(session_id);

-- ========================================================================
-- Auth helpers
-- ========================================================================
create or replace function public.is_event_member(p_event uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from event_players
                  where event_id = p_event and profile_id = auth.uid());
$$;

create or replace function public.is_event_organizer(p_event uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from events where id = p_event and created_by = auth.uid());
$$;

-- ========================================================================
-- Scoreboard view: team points = its players' duel points, both sides
-- ========================================================================
create or replace view public.v_event_scoreboard as
  select event_id, team_id, sum(pts) as points
  from (
    select d.event_id, pa.team_id, d.a_points as pts
      from event_duels d join event_players pa on pa.id = d.a_player
    union all
    select d.event_id, pb.team_id, d.b_points
      from event_duels d join event_players pb on pb.id = d.b_player
  ) s
  where team_id is not null
  group by event_id, team_id;

-- ========================================================================
-- RLS: members read every row of their event; writes only via RPCs
-- ========================================================================
alter table public.events         enable row level security;
alter table public.event_teams    enable row level security;
alter table public.event_players  enable row level security;
alter table public.event_sessions enable row level security;
alter table public.event_duels    enable row level security;

drop policy if exists events_read on public.events;
create policy events_read on public.events for select to authenticated
  using (is_event_member(id) or created_by = auth.uid());

drop policy if exists event_teams_read on public.event_teams;
create policy event_teams_read on public.event_teams for select to authenticated
  using (is_event_member(event_id));

drop policy if exists event_players_read on public.event_players;
create policy event_players_read on public.event_players for select to authenticated
  using (is_event_member(event_id));

drop policy if exists event_sessions_read on public.event_sessions;
create policy event_sessions_read on public.event_sessions for select to authenticated
  using (is_event_member(event_id));

drop policy if exists event_duels_read on public.event_duels;
create policy event_duels_read on public.event_duels for select to authenticated
  using (is_event_member(event_id));

-- ========================================================================
-- create_event: event + 2 teams + N dated sessions; creator = organizer +
-- Team A captain. Sessions run Sunday→Saturday, weekly or every N weeks.
-- ========================================================================
create or replace function public.create_event(
  p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer,
  p_draw_rule text, p_team_a text, p_team_b text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_event uuid; v_team_a uuid; v_cap uuid; i integer; v_open date;
begin
  insert into events (name, created_by, starts_on, session_count, session_weeks, draw_rule)
  values (p_name, auth.uid(), p_starts_on,
          greatest(1, least(26, coalesce(p_sessions,3))),
          greatest(1, least(4, coalesce(p_session_weeks,1))),
          coalesce(p_draw_rule,'team_pvi'))
  returning id into v_event;

  insert into event_teams (event_id, slot, name, color)
    values (v_event, 0, coalesce(p_team_a,'Team A'), 0) returning id into v_team_a;
  insert into event_teams (event_id, slot, name, color)
    values (v_event, 1, coalesce(p_team_b,'Team B'), 1);

  -- creator joins as Team A captain
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

-- roster + team assignment (organizer only)
create or replace function public.add_event_player(p_event uuid, p_profile uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_seed integer;
begin
  if not is_event_organizer(p_event) then raise exception 'organizer only'; end if;
  select coalesce(max(seed),0)+1 into v_seed from event_players where event_id = p_event;
  insert into event_players (event_id, profile_id, seed)
    values (p_event, p_profile, v_seed)
    on conflict (event_id, profile_id) do nothing
    returning id into v_id;
  return v_id;
end $$;

create or replace function public.set_event_team(p_player uuid, p_team uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_event uuid;
begin
  select event_id into v_event from event_players where id = p_player;
  if not is_event_organizer(v_event) then raise exception 'organizer only'; end if;
  update event_players set team_id = p_team where id = p_player;
end $$;

-- ========================================================================
-- generate_pairings: seed-order singles, up to the smaller roster; the
-- larger team benches its surplus (least-benched play first).
-- ========================================================================
create or replace function public.generate_pairings(p_session uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_team_a uuid; v_team_b uuid; v_pairs integer; i integer;
  a_ids uuid[]; b_ids uuid[];
begin
  select event_id into v_event from event_sessions where id = p_session;
  if not is_event_organizer(v_event) then raise exception 'organizer only'; end if;

  select id into v_team_a from event_teams where event_id = v_event and slot = 0;
  select id into v_team_b from event_teams where event_id = v_event and slot = 1;

  -- least-benched, then seed order → who plays this session
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

  -- bench the surplus on the larger side
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

-- ========================================================================
-- resolve_session: score every duel from the best round each player posted
-- in the window (PvI at the event allowance), close the session, and flip
-- the event to complete when a team passes the clinch number.
-- ========================================================================
create or replace function public.resolve_session(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_open date; v_close date; v_allow integer;
  d record; a_pvi numeric; b_pvi numeric; a_rid uuid; b_rid uuid;
  v_res text; v_ap numeric; v_bp numeric;
  v_pairs integer; m_total numeric; v_max numeric; v_win uuid;
begin
  select s.event_id, s.opens_on, s.closes_on, e.allowance
    into v_event, v_open, v_close, v_allow
    from event_sessions s join events e on e.id = s.event_id
   where s.id = p_session;
  if not is_event_organizer(v_event) then raise exception 'organizer only'; end if;

  for d in select * from event_duels where session_id = p_session loop
    -- best PvI round in the window for each side (100%-scaled by allowance)
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into a_rid, a_pvi
      from rounds r join event_players ep on ep.id = d.a_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into b_rid, b_pvi
      from rounds r join event_players ep on ep.id = d.b_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
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

  -- clinch check: total possible = session_count × smaller roster
  select least(
      (select count(*) from event_players ep join event_teams t on t.id=ep.team_id
        where t.event_id=v_event and t.slot=0),
      (select count(*) from event_players ep join event_teams t on t.id=ep.team_id
        where t.event_id=v_event and t.slot=1))
    into v_pairs;
  m_total := v_pairs * (select session_count from events where id = v_event);

  select points, team_id into v_max, v_win
    from v_event_scoreboard where event_id = v_event
    order by points desc limit 1;

  if v_max is not null and m_total > 0 and v_max > m_total/2.0 then
    update events set status='complete', winner_team_id=v_win where id=v_event;
  elsif not exists (select 1 from event_sessions where event_id=v_event and status <> 'closed') then
    -- all sessions done: winner by points, else draw_rule
    update events set status='complete',
      winner_team_id = (select team_id from v_event_scoreboard where event_id=v_event
                         order by points desc limit 1)
      where id=v_event;
  end if;
end $$;

-- grants
revoke all on function public.create_event(text,date,integer,integer,text,text,text) from public;
grant execute on function public.create_event(text,date,integer,integer,text,text,text) to authenticated;
grant execute on function public.add_event_player(uuid,uuid) to authenticated;
grant execute on function public.set_event_team(uuid,uuid) to authenticated;
grant execute on function public.generate_pairings(uuid) to authenticated;
grant execute on function public.resolve_session(uuid) to authenticated;
grant select on public.v_event_scoreboard to authenticated;
