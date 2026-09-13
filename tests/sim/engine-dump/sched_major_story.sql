-- sched_major_story() oid=20240
CREATE OR REPLACE FUNCTION public.sched_major_story()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m record; l record; v_name text; v_line text;
begin
  for m in
    select e.id as ev, ep.id as player_id
      from events e
      join event_sessions s on s.event_id = e.id and s.status in ('upcoming','open')
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status in ('setup','live')
       and new.play_on between s.opens_on and s.closes_on
  loop
    select * into l from major_board(m.ev)
     where not exhibition and pvi is not null
     order by pvi desc, best_posted_at asc limit 1;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := coalesce(v_name,'A golfer') || ' is down for ' || to_char(new.play_on,'FMDay')
      || coalesce(' at ' || new.course_label, '');
    if l.player_id is null then
      v_line := v_line || '. First card takes the lead.';
    elsif l.player_id = m.player_id then
      v_line := v_line || '. Defending the lead at ' || lower(mj_vs(l.pvi)) || '.';
    else
      v_line := v_line || '. Chasing ' || lower(mj_vs(l.pvi)) || '.';
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $function$

