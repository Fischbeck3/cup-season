-- clash_last_call(p_season uuid) oid=27501
CREATE OR REPLACE FUNCTION public.clash_last_call(p_season uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se       record;
  wc       record;
  v_local  date;
  v_ws     date;
  v_we     date;
  v_a_pts  numeric;
  v_b_pts  numeric;
  v_a_pvi  numeric;
  v_b_pvi  numeric;
  v_a_name text;
  v_b_name text;
  v_body   text;
  v_id     uuid;
begin
  select * into se from seasons where id = p_season;
  if se.id is null or se.status not in ('active','cup_final') then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;

  -- the open, unsettled clash whose window ENDS today
  select * into wc from week_clashes
   where season_id = p_season and settled_at is null
     and (se.starts_on + 7 * (week_no - 1) + 6) = v_local
   order by week_no desc limit 1;
  if wc.id is null then
    return null;
  end if;

  v_ws := se.starts_on + 7 * (wc.week_no - 1);
  v_we := v_ws + 6;

  -- already said it today
  select id into v_id from posts
   where league_id = se.league_id and season_id = p_season and kind = 'system'
     and body like 'The clash closes today%'
     and (created_at at time zone se.timezone)::date = v_local
   limit 1;
  if v_id is not null then
    return v_id;
  end if;

  -- each side's best so far — the settle's own pick, so the nudge and the
  -- result can never disagree (D207: every round in the window, not only
  -- the ones the calendar cap will keep)
  select rr.points, rr.pvi into v_a_pts, v_a_pvi
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select rr.points, rr.pvi into v_b_pts, v_b_pvi
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  -- D207 · nobody has played: nothing to call. Quiet, like the settle.
  if v_a_pts is null and v_b_pts is null then
    return null;
  end if;

  select p.display_name into v_a_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.a_member;
  select p.display_name into v_b_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.b_member;

  v_body := case
    when v_b_pts is null then
      'The clash closes today. ' || firstname(v_a_name) || ' has answered. '
        || firstname(v_b_name) || ' has not.'
    when v_a_pts is null then
      'The clash closes today. ' || firstname(v_b_name) || ' has answered. '
        || firstname(v_a_name) || ' has not.'
    when v_a_pts > v_b_pts then
      'The clash closes today. ' || firstname(v_a_name)
        || ' leads it. One round to change that.'
    when v_b_pts > v_a_pts then
      'The clash closes today. ' || firstname(v_b_name)
        || ' leads it. One round to change that.'
    else
      'The clash closes today. ' || firstname(v_a_name) || ' and '
        || firstname(v_b_name) || ' are level.' end;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_body)
  returning id into v_id;
  return v_id;
end $function$

