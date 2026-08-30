-- D150 repair · a league member's live round was losing its course identity.
--
-- `finish_live_round` writes rounds on TWO paths. The guest path carries
-- `api_course_id`; the member path did not — so every round a league member
-- finished from the tee sheet landed with a null course id and fell out of the
-- Tour Card's shared-courses block, D150's whole point. 57 of 211 rounds carry
-- an api_course_id today and the member path is why the number is not higher.
--
-- Found while scouting a post-hoc "who did you play with" feature, which the
-- data then refused (7 same-course-same-day groups in all history, every one
-- already the same live round). The feature is not being built; this bug it
-- turned over is, on its own merits — §16, a round should record what it knows.
--
-- Body = the LIVE definition, verbatim, with ONE column added to ONE insert.
-- CLAUDE.md: never edit a migration that has run; a fix is a new file.

CREATE OR REPLACE FUNCTION public.finish_live_round(p_live_round uuid, p_cards jsonb, p_casual boolean DEFAULT false, p_result jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype;
  v_snap jsonb; v_rating numeric; v_slope int; v_nine numeric;
  v_card jsonb; v_pl live_round_players%rowtype;
  v_pid uuid; v_strokes int[]; v_n int; v_holes int; v_gross int;
  v_round uuid; h int;
  v_posted jsonb := '[]'; v_guests jsonb := '[]'; v_skipped jsonb := '[]';
  v_stake numeric; v_story text;
  v_tz text; v_today date;
begin
  if v is null then raise exception 'Sign in first'; end if;
  -- D85: multi-phone finish â take the row lock so two finishers serialize;
  -- the second sees status='final' below and returns already_final.
  select * into lr from live_rounds where id = p_live_round for update;
  if lr.id is null then raise exception 'No such round'; end if;

  -- D107: the starter is known by profile now (started_by may be null on a
  -- league-less round). Member players may still finish; visitors may not.
  if lr.starter_profile_id is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;
  if lr.status = 'final' then return jsonb_build_object('already_final', true); end if;

  -- the league's own calendar day, not the server's UTC one. With no season
  -- (league-less round) the select finds no row and the coalesce falls back
  -- to America/Phoenix (CLAUDE.md default).
  select timezone into v_tz from seasons where id = lr.season_id;
  v_today := (now() at time zone coalesce(nullif(v_tz, ''), 'America/Phoenix'))::date;

  v_snap := coalesce(lr.course_snapshot, '{}'::jsonb);
  v_rating := nullif(v_snap->>'rating','')::numeric;
  v_slope  := nullif(v_snap->>'slope','')::int;
  v_nine   := nullif(v_snap->>'nine_rating','')::numeric;

  for v_card in select * from jsonb_array_elements(coalesce(p_cards, '[]'::jsonb)) loop
    select * into v_pl from live_round_players
     where id = (v_card->>'player_id')::uuid and live_round_id = p_live_round;
    if v_pl.id is null then continue; end if;

    v_strokes := array(select nullif(x,'null')::int from jsonb_array_elements_text(coalesce(v_card->'strokes','[]'::jsonb)) x);
    v_n := coalesce(array_length(v_strokes, 1), 0);
    v_holes := null;
    if v_n >= 18 and (select count(*) from unnest(v_strokes[1:18]) s where s is null) = 0 then
      v_holes := 18;
    elsif v_n >= 9 and (select count(*) from unnest(v_strokes[1:9]) s where s is null) = 0
          and (v_n < 10 or (select count(*) from unnest(v_strokes[10:18]) s where s is not null) = 0) then
      v_holes := 9;
    end if;

    if v_pl.member_id is null then
      update live_round_players
         set guest_strokes = coalesce(v_card->'strokes', '[]'::jsonb),
             guest_gross = case when v_holes is not null
               then (select sum(s)::int from unnest(v_strokes[1:v_holes]) s) end
       where id = v_pl.id;
      -- D107 (closes the D88 gap): a seated visitor is an app golfer â their
      -- COMPLETE, rated, non-casual card posts to THEIR profile right now,
      -- and the seat is stamped claimed so claim_round can never double-post.
      -- Anything less falls back to the claim-link path exactly as before.
      if v_pl.guest_profile_id is not null and v_pl.claimed_profile is null
         and not p_casual and v_holes is not null
         and v_rating is not null and v_slope is not null
         and not (v_holes = 9 and v_nine is null) then
        v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);
        insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                            played_on, holes_played, gross, rating, slope, nine_rating,
                            source, attested, index_source_at_post, api_course_id)
        values (v_pl.guest_profile_id, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
                v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
                'live', true, 'app', lr.api_course_id)
        returning id into v_round;
        for h in 1..v_holes loop
          if v_strokes[h] is not null then
            insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
          end if;
        end loop;
        update live_round_players set claimed_profile = v_pl.guest_profile_id where id = v_pl.id;
        v_posted := v_posted || jsonb_build_object(
          'name', coalesce(playerlabel(v_pl.guest_profile_id), v_pl.guest_name),
          'gross', v_gross, 'holes', v_holes);
      else
        v_guests := v_guests || jsonb_build_object('name', v_pl.guest_name, 'claim_token', v_pl.claim_token);
      end if;
      continue;
    end if;

    select profile_id into v_pid from league_members where id = v_pl.member_id;

    if p_casual then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'casual'); continue;
    end if;
    if v_holes is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'incomplete card'); continue;
    end if;
    if v_rating is null or v_slope is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no course rating'); continue;
    end if;
    if v_holes = 9 and v_nine is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no 9-hole rating'); continue;
    end if;

    v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);

    insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                        played_on, holes_played, gross, rating, slope, nine_rating,
                        source, attested, index_source_at_post, api_course_id)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live', true, 'app', lr.api_course_id)
    returning id into v_round;

    for h in 1..v_holes loop
      if v_strokes[h] is not null then
        insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
      end if;
    end loop;

    v_posted := v_posted || jsonb_build_object('name', playerlabel(v_pid), 'gross', v_gross, 'holes', v_holes);
  end loop;

  if not p_casual and p_result is not null then
    if (p_result->>'game') = 'match' then
      update live_rounds set game_result = p_result where id = p_live_round;
      -- D107: no league â no board (posts.league_id is NOT NULL); the share
      -- card is the story, and each golfer's own round fans via round_to_board.
      if lr.league_id is not null then
        v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
        if (p_result->>'winner') is null then
          v_story := 'Match play: ' || coalesce(p_result->>'side_a','side A')
                  || ' and ' || coalesce(p_result->>'side_b','side B')
                  || ' halved the match' || case when v_stake > 0 then ' â no money moves' else '' end;
        else
          v_story := 'Match play: '
                  || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'the winners')
                  || ' def. '
                  || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
                  || ' ' || coalesce(p_result->>'status','')
                  || case when v_stake > 0 then ' Â· $' || v_stake || ' on the line' else '' end;
        end if;
        -- D92: the row now knows which round it settled
        insert into posts (league_id, kind, member_id, body, live_round_id)
        values (lr.league_id, 'system', my_member_id(lr.league_id), v_story, p_live_round);
      end if;
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if lr.league_id is not null
         and nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body, live_round_id)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                left(p_result->>'story', 200), p_live_round);
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $function$;


-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text; v_api int; v_ins int;
begin
  select prosrc into v_src from pg_proc
   where proname = 'finish_live_round' and pronamespace = 'public'::regnamespace;

  select count(*) into v_ins  from (select regexp_matches(v_src, 'insert into rounds', 'g')) a;
  select count(*) into v_api  from (select regexp_matches(v_src, 'api_course_id', 'g')) b;

  -- two round inserts, and api_course_id must appear on BOTH (a column name and
  -- a value each = 4). At 2 the member path is dropping it again.
  if v_ins <> 2 then
    raise exception 'D150 repair: expected 2 round inserts, found %', v_ins;
  end if;
  if v_api <> 4 then
    raise exception 'D150 repair: api_course_id appears % times, expected 4 (both inserts)', v_api;
  end if;

  -- and the rest of the function must still be the rest of the function
  if position('attested' in v_src) = 0 or position('claim_token' in v_src) = 0
     or position('game_result' in v_src) = 0 then
    raise exception 'D150 repair: built on the wrong body — a block is missing';
  end if;
end $chk$;
