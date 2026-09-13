-- enter_major(p_event uuid) oid=20233
CREATE OR REPLACE FUNCTION public.enter_major(p_event uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v record; v_id uuid; v_seed integer; v_exh boolean; v_n integer;
begin
  select e.id, e.kind, e.status, e.league_id into v from events e where e.id = p_event;
  if v.id is null or v.kind <> 'major' then raise exception 'No such Major'; end if;
  if v.status = 'complete' then raise exception 'That one is settled — catch the next Major'; end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'The horn has sounded — catch the next Major';
  end if;
  if v.league_id is null or not is_league_member(v.league_id) then
    raise exception 'Entry is by invite — ask the organizer';
  end if;

  v_exh := not major_contender(auth.uid());
  select coalesce(max(seed),0)+1 into v_seed from event_players where event_id = p_event;
  insert into event_players (event_id, profile_id, seed, exhibition)
    values (p_event, auth.uid(), v_seed, v_exh)
    on conflict (event_id, profile_id) do nothing
    returning id into v_id;
  if v_id is not null then
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event,
      (select display_name from profiles where id = auth.uid())
      || ' is in. Field of ' || v_n || '.'
      || case when v_exh then ' Doesn''t count this year — official by the next one.' else '' end);
  end if;
  return v_id;
end $function$

