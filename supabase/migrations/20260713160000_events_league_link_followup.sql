-- Decision B follow-up: ensure events.league_id + the 8-arg create_event exist
-- on databases that applied 20260713120000 BEFORE the league link was folded in.
-- Fully idempotent — a no-op where they already exist, and it retires the pre-B
-- 7-arg create_event overload so PostgREST can't resolve to a stale signature.

alter table public.events
  add column if not exists league_id uuid references public.leagues(id) on delete set null;

drop function if exists public.create_event(text,date,integer,integer,text,text,text);

create or replace function public.create_event(
  p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer,
  p_draw_rule text, p_team_a text, p_team_b text, p_league uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_event uuid; v_team_a uuid; v_cap uuid; i integer; v_open date;
begin
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'you must be in the league to run an event with it';
  end if;
  insert into events (name, created_by, league_id, starts_on, session_count, session_weeks, draw_rule)
  values (p_name, auth.uid(), p_league, p_starts_on,
          greatest(1, least(26, coalesce(p_sessions,3))),
          greatest(1, least(4, coalesce(p_session_weeks,1))),
          coalesce(p_draw_rule,'team_pvi'))
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

revoke all on function public.create_event(text,date,integer,integer,text,text,text,uuid) from public;
grant execute on function public.create_event(text,date,integer,integer,text,text,text,uuid) to authenticated;
