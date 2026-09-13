-- add_event_player(p_event uuid, p_profile uuid) oid=19072
CREATE OR REPLACE FUNCTION public.add_event_player(p_event uuid, p_profile uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_kind text; v_league uuid; v_exh boolean; v_n int; v_name text;
begin
  if not is_event_organizer(p_event) then
    raise exception 'Only the organizer can do that.';
  end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'Roster locks once a week has been scored';
  end if;

  select kind, league_id into v_kind, v_league from events where id = p_event;

  -- D148: consent. A direct add needs a standing relationship; everyone else
  -- goes through invite_golfer, which asks and can be declined.
  if p_profile <> auth.uid()
     and not (v_league is not null and exists (
                select 1 from league_members lm
                 where lm.league_id = v_league and lm.profile_id = p_profile))
     and not exists (
                select 1 from friendships f
                 where f.status = 'accepted'
                   and ((f.requester = auth.uid() and f.addressee = p_profile)
                     or (f.addressee = auth.uid() and f.requester = p_profile)))
  then
    raise exception 'You can add golfers from this league or your buddies list. For anyone else, send an invite so they can accept.';
  end if;

  v_exh := (v_kind = 'major') and not major_contender(p_profile);

  select coalesce(max(seed), 0) + 1 into v_n from event_players where event_id = p_event;

  insert into event_players (event_id, profile_id, seed, exhibition)
  values (p_event, p_profile, v_n, v_exh)
  on conflict (event_id, profile_id) do nothing
  returning id into v_id;

  if v_id is not null and v_kind = 'major' then
    select display_name into v_name from profiles where id = p_profile;
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event, coalesce(v_name,'A golfer') || ' is in. Field of ' || v_n || '.');
  end if;

  return v_id;
end $function$

