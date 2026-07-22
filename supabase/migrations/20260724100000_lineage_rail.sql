-- ============================================================================
-- The lineage rail — D61 (the annual Major) + D62 (the Ryder series).
--
--   • events.lineage_id — an EXPLICIT chain link, set only when an event is
--     created via the rematch tap ("Run it back — {name}"). Never inferred
--     from matching names (D61: lineage is chosen, not guessed). Every link
--     points at the chain's ROOT event (flat chain, no walking).
--   • event_lineage(event) — the one read both rooms use: the chain in
--     chronological order with each edition's champion (major: the jug's
--     name; ryder: the winning bench + slot so the client can compute the
--     series tally "BLUE LEADS THE SERIES 2–1").
--   • create_major / create_event grow p_lineage (default null). The old
--     signatures are DROPPED — an overload prefix with defaults would leave
--     PostgREST ambiguous — and the D37 grants re-bind to the new ones.
--     Deploy skew: old client (no arg) matches the default; new client on an
--     old DB gets the schema-cache error and retries without the arg.
--   • The Major's announce learns the chain: "THE 4TH ANNUAL {NAME} — MARCUS
--     DEFENDS". The Ryder's holder line renders in the room header (v1 trim,
--     logged in D62).
--   • The champion's earned marker stays parked (§9). No new nudge class
--     (D23 fence). No adopt-into-lineage tool (D61 resolution: rematch-only).
-- ============================================================================

alter table public.events
  add column if not exists lineage_id uuid references public.events(id) on delete set null;
create index if not exists events_lineage_idx on public.events(lineage_id);

-- ---- voice helper: 1ST / 2ND / 3RD / 4TH … (11–13 stay TH) ------------------
create or replace function public.nth_up(n integer) returns text
language sql immutable as $$
  select n::text || case
    when n % 100 in (11,12,13) then 'TH'
    when n % 10 = 1 then 'ST'
    when n % 10 = 2 then 'ND'
    when n % 10 = 3 then 'RD'
    else 'TH' end;
$$;

-- ---- the chain, resolved (internal) -----------------------------------------
-- Root of any event's chain: its link target, or itself.
create or replace function public.lineage_root(p_event uuid) returns uuid
language sql stable security definer set search_path = public as $$
  select coalesce(e.lineage_id, e.id) from events e where e.id = p_event;
$$;

-- ---- the client read --------------------------------------------------------
-- Chronological chain for the room: champion per edition. Majors carry the
-- jug's name; Ryders carry the winning bench (slot for the tally, name for
-- the voice; both null on a shared cup — the client reads winner_shared).
create or replace function public.event_lineage(p_event uuid)
returns table(event_id uuid, name text, kind text, status text, starts_on date,
              year integer, is_current boolean,
              champion text, champ_gross integer, champ_pvi numeric,
              winner_slot integer, winner_team text, winner_shared boolean)
language sql stable security definer set search_path = public as $$
  with me as (select lineage_root(p_event) as root)
  select e.id, e.name, e.kind, e.status, e.starts_on,
         extract(year from e.starts_on)::int,
         e.id = p_event,
         mc.display_name, mc.gross, mc.pvi,
         wt.slot, wt.name,
         (e.kind is distinct from 'major' and e.status = 'complete'
          and e.winner_team_id is null)
    from events e
    cross join me
    left join lateral (
      select pr.display_name, c.gross, c.pvi
        from event_major_cards c
        join event_players ep on ep.id = c.player_id
        join profiles pr on pr.id = ep.profile_id
       where c.event_id = e.id and c.rank = 1
       limit 1
    ) mc on e.kind = 'major'
    left join event_teams wt on wt.id = e.winner_team_id
   where (e.id = me.root or e.lineage_id = me.root)
     and (is_event_member(p_event) or is_event_league_member(p_event))
   order by e.starts_on, e.created_at;
$$;

-- ---- create_major grows the chain -------------------------------------------
drop function if exists public.create_major(text,date,integer,numeric,text,uuid,text);
create or replace function public.create_major(
  p_name text, p_final_on date, p_days integer default 4,
  p_buy_in numeric default 0, p_pot_split text default 'places',
  p_league uuid default null, p_tz text default null,
  p_lineage uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_name text; v_days integer; v_split text; v_buy numeric;
  v_open date; v_tz text; v_root uuid; v_nth integer; v_def text; v_annual text := '';
begin
  v_name := nullif(trim(coalesce(p_name,'')), '');
  if v_name is null then raise exception 'Name the jug — a Major needs a name'; end if;
  if p_final_on is null or p_final_on < current_date then
    raise exception 'The final day has to be ahead of you';
  end if;
  if p_final_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  v_days  := greatest(2, least(4, coalesce(p_days, 4)));
  v_buy   := coalesce(p_buy_in, 0);
  if v_buy < 0 or v_buy > 100000 then raise exception 'buy-in out of range'; end if;
  v_split := coalesce(p_pot_split, 'places');
  if v_split not in ('places','wta') then raise exception 'pot split must be places or wta'; end if;
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'you must be in the league to run a Major with it';
  end if;

  -- the chain link: rematch-only, your own history only, majors to majors
  if p_lineage is not null then
    if not exists (select 1 from events e
                    where e.id = p_lineage and e.kind = 'major'
                      and (e.created_by = auth.uid() or is_event_member(e.id))) then
      raise exception 'You can only run back a Major you were part of';
    end if;
    v_root := lineage_root(p_lineage);
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

  v_open := p_final_on - v_days + 1;

  insert into events (name, created_by, league_id, kind, starts_on,
                      session_count, session_weeks, draw_rule, tz,
                      buy_in, pot_split, lineage_id)
  values (v_name, auth.uid(), p_league, 'major', v_open,
          1, 1, 'team_pvi', v_tz, v_buy, v_split, v_root)
  returning id into v_event;

  insert into event_sessions (event_id, session_no, opens_on, closes_on)
  values (v_event, 1, v_open, p_final_on);

  -- the organizer enters the field like anyone (role-blind)
  insert into event_players (event_id, profile_id, role, seed, exhibition)
  values (v_event, auth.uid(), 'player', 0, not major_contender(auth.uid()));

  -- the annual voice: count the chain, name the defender (D61)
  if v_root is not null then
    select count(*) into v_nth from events e
     where e.id = v_root or e.lineage_id = v_root;   -- includes the new one
    select pr.display_name into v_def
      from events e
      join event_major_cards c on c.event_id = e.id and c.rank = 1
      join event_players ep on ep.id = c.player_id
      join profiles pr on pr.id = ep.profile_id
     where (e.id = v_root or e.lineage_id = v_root)
       and e.status = 'complete' and e.id <> v_event
     order by e.starts_on desc limit 1;
    v_annual := 'THE ' || nth_up(v_nth) || ' ANNUAL — '
      || coalesce(upper(v_def) || ' DEFENDS · ', '');
  end if;

  perform major_post(v_event,
    v_annual
    || upper((select display_name from profiles where id = auth.uid()))
    || ' SET ' || upper(v_name) || ' — '
    || upper(to_char(v_open, 'Dy Mon DD')) || ' → ' || upper(to_char(p_final_on, 'Dy Mon DD'))
    || ' · BEST CARD TAKES THE JUG'
    || case when v_buy > 0 then ' · BUY-IN ' || mj_money(v_buy) else ' · BRAGGING RIGHTS' end);

  return v_event;
end $$;

-- ---- create_event (the Ryder) grows the chain -------------------------------
-- Extends the LIVE 9-arg signature (20260716150000: p_tz, Sunday enforcement,
-- league-season tz inherit) — body carried verbatim, lineage added.
drop function if exists public.create_event(text,date,integer,integer,text,text,text,uuid,text);
create or replace function public.create_event(
  p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer,
  p_draw_rule text, p_team_a text, p_team_b text, p_league uuid default null,
  p_tz text default null, p_lineage uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_event uuid; v_team_a uuid; v_cap uuid; i integer; v_open date; v_tz text; v_root uuid;
begin
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'you must be in the league to run an event with it';
  end if;
  if extract(dow from p_starts_on) <> 0 then
    raise exception 'The Ryder starts on a Sunday — sessions run Sun to Sat';
  end if;

  -- the chain link (D62): rematch-only, your own history only, like to like
  if p_lineage is not null then
    if not exists (select 1 from events e
                    where e.id = p_lineage and e.kind is distinct from 'major'
                      and (e.created_by = auth.uid() or is_event_member(e.id))) then
      raise exception 'You can only run back an event you were part of';
    end if;
    v_root := lineage_root(p_lineage);
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
                      session_weeks, draw_rule, tz, lineage_id)
  values (p_name, auth.uid(), p_league, p_starts_on,
          greatest(1, least(26, coalesce(p_sessions,3))),
          greatest(1, least(4, coalesce(p_session_weeks,1))),
          coalesce(p_draw_rule,'team_pvi'), v_tz, v_root)
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

-- ---- grants (D37: explicit or it 403s; signatures changed, grants re-bind) --
revoke all on function public.create_major(text,date,integer,numeric,text,uuid,text,uuid) from public, anon, authenticated;
grant execute on function public.create_major(text,date,integer,numeric,text,uuid,text,uuid) to authenticated;

revoke all on function public.create_event(text,date,integer,integer,text,text,text,uuid,text,uuid) from public, anon, authenticated;
grant execute on function public.create_event(text,date,integer,integer,text,text,text,uuid,text,uuid) to authenticated;

revoke all on function public.event_lineage(uuid) from public, anon, authenticated;
grant execute on function public.event_lineage(uuid) to authenticated;

-- engine-internal: never client-callable
revoke all on function public.lineage_root(uuid) from public, anon, authenticated;
revoke all on function public.nth_up(integer)    from public, anon, authenticated;
