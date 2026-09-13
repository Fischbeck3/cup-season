-- create_event(p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer, p_draw_rule text, p_team_a text, p_team_b text, p_league uuid, p_tz text, p_lineage uuid) oid=20409
CREATE OR REPLACE FUNCTION public.create_event(p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer, p_draw_rule text, p_team_a text, p_team_b text, p_league uuid DEFAULT NULL::uuid, p_tz text DEFAULT NULL::text, p_lineage uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_event uuid; v_team_a uuid; v_cap uuid; i integer; v_open date; v_tz text; v_root uuid; v_allow integer;
begin
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'You have to be in that season to run a Ryder with it';
  end if;
  if extract(dow from p_starts_on) <> 0 then
    raise exception 'The Ryder starts on a Sunday — each week runs Sun to Sat';
  end if;

  -- the chain link (D62): rematch-only, your own history only, like to like
  if p_lineage is not null then
    if not exists (select 1 from events e
                    where e.id = p_lineage and e.kind is distinct from 'major'
                      and (e.created_by = auth.uid() or is_event_member(e.id))) then
      raise exception 'You can only run back a Ryder you were part of';
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
end $function$

