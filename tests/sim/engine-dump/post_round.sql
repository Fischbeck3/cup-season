-- post_round(p_gross integer, p_rating numeric, p_slope integer, p_holes_played integer, p_nine_rating numeric, p_course_id text, p_course_label text, p_played_on date, p_photo_path text, p_played_with uuid[]) oid=34866
CREATE OR REPLACE FUNCTION public.post_round(p_gross integer, p_rating numeric, p_slope integer, p_holes_played integer DEFAULT 18, p_nine_rating numeric DEFAULT NULL::numeric, p_course_id text DEFAULT NULL::text, p_course_label text DEFAULT NULL::text, p_played_on date DEFAULT CURRENT_DATE, p_photo_path text DEFAULT NULL::text, p_played_with uuid[] DEFAULT '{}'::uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_me      uuid := auth.uid();
  v_played  date := coalesce(p_played_on, current_date);
  v_holes   int  := case when p_holes_played = 9 then 9 else 18 end;
  v_label   text := nullif(btrim(coalesce(p_course_label, '')), '');
  v_course  text := nullif(btrim(coalesce(p_course_id, '')), '');
  v_photo   text := nullif(btrim(coalesce(p_photo_path, '')), '');
  v_season  uuid;
  v_league  uuid;
  v_lname   text;
  v_squad   text;
  v_round   uuid;
  v_tagged  int := 0;
begin
  if v_me is null then
    raise exception 'Sign in to post a round.' using errcode = '42501';
  end if;
  if p_gross is null or p_gross < 18 or p_gross > 200 then
    raise exception 'That score is not a round — check the gross.' using errcode = '22023';
  end if;
  if p_rating is null or p_rating < 25 or p_rating > 90 then
    raise exception 'Type the rating off the scorecard — it is on the back of the card.' using errcode = '22023';
  end if;
  if p_slope is null or p_slope < 55 or p_slope > 155 then
    raise exception 'Type the slope off the scorecard — it is on the back of the card.' using errcode = '22023';
  end if;
  if v_label is null then
    raise exception 'Type the course you played — it goes on the card.' using errcode = '22023';
  end if;
  if v_played > current_date then
    raise exception 'That round has not been played yet.' using errcode = '22023';
  end if;

  -- garnish never costs a golfer their score: an api course id that names no
  -- cached course, and a photo path that is not the caller's own, are dropped
  -- and the round posts. (These are the two client-side skew retries, moved in.)
  if v_course is not null and not exists (select 1 from api_courses c where c.id = v_course) then
    v_course := null;
  end if;
  if v_photo is not null and v_photo not like (v_me::text || '/%') then
    v_photo := null;
  end if;

  -- D229 · the season is DERIVED, never chosen by the client. An active season
  -- first, then the one that closes soonest; a round outside every window
  -- posts with no stamp and still builds the golfer's number (L-13).
  select s.id, s.league_id, l.name
    into v_season, v_league, v_lname
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final', 'complete')
                  and v_played between s.starts_on and s.ends_on
    join leagues l on l.id = s.league_id
   where lm.profile_id = v_me
     and lm.suspended_at is null
   order by (s.status = 'active') desc, s.ends_on asc, s.id
   limit 1;

  if v_season is not null then
    select q.name into v_squad
      from squad_members sm
      join squads q on q.id = sm.squad_id
      join league_members lm on lm.id = sm.member_id
     where lm.profile_id = v_me and q.season_id = v_season
     limit 1;
  end if;

  insert into rounds (profile_id, gross, rating, nine_rating, slope, holes_played,
                      source, played_on, course_label, api_course_id, season_id, photo_path)
  values (v_me, p_gross, p_rating,
          case when v_holes = 9 then p_nine_rating else null end,
          p_slope, v_holes, 'quick', v_played, v_label, v_course, v_season, v_photo)
  returning id into v_round;

  -- C-2 · who was out there. Bounded by `home_feed`'s own circle (buddies ∪
  -- league mates ∪ event co-players) and capped at seven, so a tag is a claim
  -- about somebody you actually play with (D239 rule 3). No confirmation is
  -- written: `confirmed_at` stays null until the other golfer answers.
  if to_regclass('public.round_players') is not null
     and p_played_with is not null and array_length(p_played_with, 1) is not null then
    execute $q$
      with circle as (
        select case when requester = $1 then addressee else requester end as pid
          from friendships
         where status = 'accepted' and (requester = $1 or addressee = $1)
        union
        select lm2.profile_id
          from league_members lm1 join league_members lm2 on lm2.league_id = lm1.league_id
         where lm1.profile_id = $1
        union
        select ep2.profile_id
          from event_players ep1 join event_players ep2 on ep2.event_id = ep1.event_id
         where ep1.profile_id = $1
      ),
      want as (select distinct unnest($3::uuid[]) as pid)
      insert into round_players (round_id, profile_id)
      select $2, w.pid
        from want w
       where w.pid <> $1
         and w.pid in (select pid from circle)
       limit 7
      on conflict do nothing
    $q$ using v_me, v_round, p_played_with;
    get diagnostics v_tagged = row_count;
  end if;

  return jsonb_build_object(
    'round', jsonb_build_object(
      'id', v_round,
      'season_id', v_season,
      'league_id', v_league,
      'league_name', v_lname,
      'squad', v_squad,
      'played_on', v_played,
      'gross', p_gross,
      'holes_played', v_holes,
      'course_label', v_label,
      'api_course_id', v_course,
      'photo_path', v_photo,
      'counts', v_season is not null,
      'tagged', v_tagged),
    'epilogue', round_epilogue(v_round)
  );
end $function$

