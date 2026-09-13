-- respond_callout(p_event uuid, p_accept boolean) oid=35000
CREATE OR REPLACE FUNCTION public.respond_callout(p_event uuid, p_accept boolean DEFAULT true)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_me     uuid := auth.uid();
  e        record;
  v_caller uuid;
  v_closes date;
  v_na     text;
begin
  if v_me is null then raise exception 'Sign in first'; end if;
  select * into e from events where id = p_event;
  if e.id is null then return 'gone'; end if;
  if e.league_id is not null or e.session_count <> 1 then
    raise exception 'That is not a callout';
  end if;
  if not exists (select 1 from event_players where event_id = p_event and profile_id = v_me) then
    raise exception 'That one is not yours to answer';
  end if;
  if e.created_by = v_me then raise exception 'You made this one'; end if;
  if e.status not in ('setup','live') then return 'closed'; end if;

  v_caller := e.created_by;
  select closes_on into v_closes from event_sessions where event_id = p_event order by session_no limit 1;

  if coalesce(p_accept, true) then
    -- Accept opens play: the session is already open, so the only thing left
    -- is the story, and the story is the acceptance.
    select coalesce(display_name, 'A golfer') into v_na from profiles where id = v_me;
    perform event_post(p_event, firstname(v_na) || ' is in. Best round by '
                       || trim(to_char(v_closes, 'Dy Mon FMDD')) || ' takes it.');
    return 'accepted';
  end if;

  -- A DECLINE CLOSES IT SILENTLY. No story, no post, no push, and no duel —
  -- so it is not a meeting, it does not reach my_rivalries, and head_to_head
  -- never counts it. L-22: saying no leaves no mark on anybody.
  delete from event_duels where event_id = p_event;
  update event_sessions set status = 'closed' where event_id = p_event;
  update events set status = 'cancelled' where id = p_event;
  insert into callout_mutes (caller, opponent, week_start)
  values (v_caller, v_me, date_trunc('week', current_date)::date)
  on conflict do nothing;
  return 'declined';
end $function$

