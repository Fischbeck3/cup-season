-- call_out(p_opponent uuid, p_closes_on date, p_forfeit_terms text) oid=34996
CREATE OR REPLACE FUNCTION public.call_out(p_opponent uuid, p_closes_on date DEFAULT NULL::date, p_forfeit_terms text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_me      uuid := auth.uid();
  v_closes  date;
  v_event   uuid;
  v_ta      uuid;
  v_tb      uuid;
  v_pa      uuid;
  v_pb      uuid;
  v_session uuid;
  v_na      text;
  v_nb      text;
  v_terms   text := nullif(trim(coalesce(p_forfeit_terms,'')), '');
  v_week    date := date_trunc('week', current_date)::date;
begin
  if v_me is null then raise exception 'Sign in first'; end if;
  if p_opponent is null or p_opponent = v_me then
    raise exception 'Call somebody else out';
  end if;

  -- Buddies only, mirroring D69's RSVP consent rule. A callout is not an
  -- invitation to a stranger.
  if not exists (select 1 from friendships f
                  where f.status = 'accepted'
                    and ((f.requester = v_me and f.addressee = p_opponent)
                      or (f.addressee = v_me and f.requester = p_opponent))) then
    raise exception 'Callouts are between buddies. Add them first';
  end if;

  -- Guard 3: they said no this week. Silent to them, honest to me.
  if exists (select 1 from callout_mutes
              where caller = v_me and opponent = p_opponent and week_start = v_week) then
    raise exception 'They passed this week. Try them next week';
  end if;

  v_closes := coalesce(p_closes_on, current_date + 7);
  if v_closes < current_date then raise exception 'Pick a day that has not happened yet'; end if;
  if v_closes > current_date + 60 then raise exception 'Two months is long enough for a callout'; end if;

  -- Guard 1: one open callout per pair at a time.
  if exists (
    select 1 from events e
      join event_players a on a.event_id = e.id and a.profile_id = v_me
      join event_players b on b.event_id = e.id and b.profile_id = p_opponent
     where e.league_id is null and e.session_count = 1
       and e.status in ('setup','live')
       and (select count(*) from event_players ep where ep.event_id = e.id) = 2) then
    raise exception 'You already have one open with them';
  end if;

  select coalesce(display_name, 'You')      into v_na from profiles where id = v_me;
  select coalesce(display_name, 'A golfer') into v_nb from profiles where id = p_opponent;

  -- The event. A FIRST TEE THAT IS NOT SNAPPED TO SUNDAY — the one thing
  -- create_event refuses, and the reason this function exists.
  insert into events (name, created_by, league_id, kind, status, starts_on,
                      session_count, session_weeks, draw_rule, tz, allowance)
  values (firstname(v_na) || ' v ' || firstname(v_nb), v_me, null, 'ryder', 'live',
          current_date, 1, 1, 'team_pvi', 'America/Phoenix', 100)
  returning id into v_event;

  -- The two teams are the two golfers. The room never says "Team A".
  insert into event_teams (event_id, slot, name, color)
    values (v_event, 0, firstname(v_na), 0) returning id into v_ta;
  insert into event_teams (event_id, slot, name, color)
    values (v_event, 1, firstname(v_nb), 1) returning id into v_tb;

  -- Both seated WITH team_id — the clause no shipped RPC can write.
  insert into event_players (event_id, profile_id, team_id, role, seed)
    values (v_event, v_me, v_ta, 'captain', 0) returning id into v_pa;
  insert into event_players (event_id, profile_id, team_id, role, seed)
    values (v_event, p_opponent, v_tb, 'player', 0) returning id into v_pb;
  update event_teams set captain_player_id = v_pa where id = v_ta;

  -- One session, open from today to the day it closes, and one duel in it.
  -- generate_pairings is deliberately NOT used: it writes an event_post, and a
  -- callout's first story belongs to the acceptance, not to the asking.
  insert into event_sessions (event_id, session_no, opens_on, closes_on, status)
    values (v_event, 1, current_date, v_closes, 'open')
  returning id into v_session;
  insert into event_duels (event_id, session_id, a_player, b_player)
    values (v_event, v_session, v_pa, v_pb);

  -- The stake, if there is one, is a FORFEIT (T-02) — never a fourth noun and
  -- never an amount in a column (D242 restates the rule this leans on).
  if v_terms is not null then
    perform create_forfeit(null, left(v_terms, 60), v_terms, 'custom', p_opponent, null, v_event, null);
  end if;

  -- The nudge. One of D23's eight emotions (anticipation), once per condition.
  insert into push_nudges (profile_id, kind, title, body, payload)
  values (p_opponent, 'callout', firstname(v_na) || ' called you out',
          'Best round by ' || trim(to_char(v_closes, 'Dy Mon FMDD')) || ' takes it'
          || coalesce(' — ' || v_terms, '') || '.',
          jsonb_build_object('event_id', v_event, 'profile_id', v_me));

  return v_event;
end $function$

