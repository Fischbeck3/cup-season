-- round_to_board() oid=18064
CREATE OR REPLACE FUNCTION public.round_to_board()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_n int; v_body text;
begin
  select firstname(coalesce(p.display_name, 'A member'))
         || ' posted ' || new.gross
         || case when new.holes_played = 9 then ' for nine' else '' end
         || case when coalesce(new.course_label,'') <> ''
                 then ' at ' || new.course_label else '' end
         || '.'
    into v_body
    from profiles p where p.id = new.profile_id;

  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'round', new.id, lm.id, v_body
  from league_members lm
  join seasons s on s.league_id = lm.league_id
                and s.status in ('active','cup_final')
                and new.played_on between s.starts_on and s.ends_on
  where lm.profile_id = new.profile_id;

  get diagnostics v_n = row_count;

  -- D238 · the rail. A round that landed in NO season window used to reach no
  -- board at all; it is now homed on the golfer who played it. Only on zero —
  -- a golfer in one live season gets exactly the post they get today, and
  -- nothing anywhere writes both.
  if v_n = 0 and v_body is not null then
    insert into posts (profile_id, kind, round_id, body)
    values (new.profile_id, 'round', new.id, v_body);
  end if;

  return new;
end $function$

