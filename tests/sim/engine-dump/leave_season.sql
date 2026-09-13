-- leave_season(p_league uuid) oid=34899
CREATE OR REPLACE FUNCTION public.leave_season(p_league uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_member  uuid;
  v_role    text;
  v_left    timestamptz;
  v_name    text;
  v_league  text;
  v_season  uuid;
begin
  if p_league is null then raise exception 'leave_season needs a league'; end if;

  select lm.id, lm.role, lm.left_at, coalesce(p.display_name, 'A golfer')
    into v_member, v_role, v_left, v_name
    from league_members lm
    left join profiles p on p.id = lm.profile_id
   where lm.league_id = p_league and lm.profile_id = auth.uid();
  if v_member is null then raise exception 'You are not in this season'; end if;

  -- The Pro hands the season over first. A season whose only Pro walked out
  -- has nobody to mark a payment, close the roster or end it.
  if v_role = 'commissioner' then
    raise exception 'Hand the season to somebody else first — a season needs a Pro';
  end if;

  select name into v_league from leagues where id = p_league;

  -- Idempotent: leaving twice is leaving once. The second call says the same
  -- thing the first did and writes nothing (no second board line, L-20).
  if v_left is not null then
    return jsonb_build_object('left_at', v_left, 'league_id', p_league,
                              'league', v_league, 'already', true);
  end if;

  update league_members set left_at = now() where id = v_member
  returning left_at into v_left;

  select id into v_season from seasons where league_id = p_league
   order by (status in ('active', 'cup_final')) desc, starts_on desc limit 1;

  -- The Pro is told once, plainly. No verb, no count of defections, no name
  -- called out twice: what happened, and what did not.
  insert into posts (league_id, season_id, kind, body)
  values (p_league, v_season, 'system',
          v_name || ' stepped out of the season. Their rounds stay where they are; '
                 || 'they stop scoring from today.');

  return jsonb_build_object('left_at', v_left, 'league_id', p_league,
                            'league', v_league, 'already', false);
end $function$

