-- ============================================================================
-- D147 · two Ryder dials were advertised but not wired
--
-- 1. `draw_rule = 'defender'` is UNREACHABLE. The branch in resolve_session is
--    `if v_rule = 'defender' and v_def is not null`, and events.defender_team_id
--    is never written by any RPC, trigger or client — grep finds only reads.
--    A league picking "the holder keeps the cup on a draw" silently got the
--    team_pvi rule instead. The client cannot even offer it: it hardcodes
--    p_draw_rule:'team_pvi' (index.html). Spec R8 describes the defender
--    carrying over between rematches; nothing implements it.
--
--    The value is removed from the CHECK rather than wired. Wiring it means
--    deciding which of a NEW event's two teams inherits the old winner, and the
--    only available match is by team name — fragile, and nobody has asked for
--    the rule. Leaving a CHECK value that cannot fire is the same class as the
--    +10 head start D137 removed: a rule offered that the engine does not have.
--    'shared' STAYS: it is implemented and it works (verified by simulation).
--
-- 2. `events.allowance` was frozen at 100. No RPC ever set it, so every
--    `* allowance / 100.0` in the engine was an identity — and a Ryder attached
--    to a 95% league scored at FULL handicap while the league scored at 95.
--    An attached event now inherits its league's allowance at creation. A
--    standalone event keeps 100; there is no league to inherit from.
--
-- Existing events are left alone: the one live event carries team_pvi and 100,
-- which is what it played under.
-- ============================================================================

alter table public.events drop constraint if exists events_draw_rule_check;
alter table public.events
  add constraint events_draw_rule_check
  check (draw_rule = any (array['team_pvi'::text, 'shared'::text]));

create or replace function public.create_event(
  p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer,
  p_draw_rule text, p_team_a text, p_team_b text, p_league uuid default null,
  p_tz text default null, p_lineage uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_event uuid; v_team_a uuid; v_cap uuid; i integer; v_open date; v_tz text; v_root uuid; v_allow integer;
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

  -- D147 · an ATTACHED event scores at its league's allowance. events.allowance
  -- was never written by anything and sat at its default of 100, so a Ryder run
  -- inside a 95% league valued the same round differently from the league that
  -- borrowed it out — with nothing on any surface saying so. A standalone event
  -- keeps the 100 default, because there is no league to inherit from.
  if p_league is not null then
    select handicap_allowance into v_allow from league_settings where league_id = p_league;
  end if;

  insert into events (name, created_by, league_id, starts_on, session_count,
                      session_weeks, draw_rule, tz, lineage_id, allowance)
  values (p_name, auth.uid(), p_league, p_starts_on,
          greatest(1, least(26, coalesce(p_sessions,3))),
          greatest(1, least(4, coalesce(p_session_weeks,1))),
          coalesce(p_draw_rule,'team_pvi'), v_tz, v_root, coalesce(v_allow, 100))
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

revoke all on function public.create_event(text,date,integer,integer,text,text,text,uuid,text,uuid) from public, anon;
grant execute on function public.create_event(text,date,integer,integer,text,text,text,uuid,text,uuid) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'create_event' and pronamespace = 'public'::regnamespace;
  if position('handicap_allowance into v_allow' in v_src) = 0 then
    raise exception 'D147: create_event does not inherit the league allowance';
  end if;
  if exists (select 1 from pg_constraint
              where conname = 'events_draw_rule_check'
                and pg_get_constraintdef(oid) like '%defender%') then
    raise exception 'D147: draw_rule still offers the unreachable defender rule';
  end if;
  if exists (select 1 from events where draw_rule not in ('team_pvi','shared')) then
    raise exception 'D147: an existing event holds a draw_rule the CHECK no longer allows';
  end if;
end $chk$;
