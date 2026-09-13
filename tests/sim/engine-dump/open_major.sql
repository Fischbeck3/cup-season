-- open_major(p_session uuid) oid=20234
CREATE OR REPLACE FUNCTION public.open_major(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; v_today date; v_n integer; v_days integer;
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.buy_in, e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if auth.uid() is not null and not is_event_organizer(s.event_id) then
    raise exception 'Only the organizer can do that.';
  end if;
  if s.status <> 'upcoming' then return; end if;
  v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
  if s.opens_on > v_today then
    raise exception 'The window opens %', to_char(s.opens_on, 'Dy Mon DD');
  end if;
  select count(*) into v_n from event_players where event_id = s.event_id;
  if v_n < 2 then raise exception 'A Major needs a field — 2 at least'; end if;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = s.event_id and status = 'setup';

  v_days := s.closes_on - s.opens_on + 1;
  perform major_post(s.event_id,
    s.name || ' is live. ' || v_days || ' days, field of ' || v_n
    || '. Best card by ' || to_char(s.closes_on, 'FMDay') || ' night takes the jug.');
end $function$

