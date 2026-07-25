-- ============================================================================
-- Cup Season — D74: Sunningdale joins the tee sheet
--
-- Match play with NO handicaps: the equalizer is positional (enter a hole N
-- down, N>=2, and that side gets N-1 strokes on it), plus the "bank" money
-- layer. The game engine is fully client-side (sunnEngine, TDD:
-- tests/sunningdale.test.mjs); the server needs exactly two things:
--
--   1. live_rounds' game CHECK learns the value 'sunningdale'
--   2. finish_live_round posts its settlement story (same branch wolf/skins
--      use — the client composes the story, the server posts it)
--
-- While inside the generator, the casing policy applies (decision log,
-- 2026-07-24): stories are written NATURAL CASE now — the match branch stops
-- upper()-ing its parts and the wolf/skins/sunningdale story ships as sent.
-- easeCaps passes mixed case straight through, and legacy all-caps posts keep
-- easing as before. Skew-safe: an old client never sends game='sunningdale'
-- (the picker doesn't exist), and a new client on an old DB gets a clean
-- check-violation toast on tee-off until this is pushed.
-- ============================================================================

alter table public.live_rounds drop constraint live_rounds_game_check;
alter table public.live_rounds add constraint live_rounds_game_check
  check (game = any (array['none'::text,'match'::text,'wolf'::text,'skins'::text,'sunningdale'::text]));

CREATE OR REPLACE FUNCTION "public"."finish_live_round"("p_live_round" "uuid", "p_cards" "jsonb", "p_casual" boolean DEFAULT false, "p_result" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype; v_starter uuid;
  v_snap jsonb; v_rating numeric; v_slope int; v_nine numeric;
  v_card jsonb; v_pl live_round_players%rowtype;
  v_pid uuid; v_strokes int[]; v_n int; v_holes int; v_gross int;
  v_round uuid; h int;
  v_posted jsonb := '[]'; v_guests jsonb := '[]'; v_skipped jsonb := '[]';
  v_stake numeric; v_story text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into lr from live_rounds where id = p_live_round;
  if lr.id is null then raise exception 'No such round'; end if;

  select profile_id into v_starter from league_members where id = lr.started_by;
  if v_starter is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;
  if lr.status = 'final' then return jsonb_build_object('already_final', true); end if;

  v_snap := coalesce(lr.course_snapshot, '{}'::jsonb);
  v_rating := nullif(v_snap->>'rating','')::numeric;
  v_slope  := nullif(v_snap->>'slope','')::int;
  v_nine   := nullif(v_snap->>'nine_rating','')::numeric;

  for v_card in select * from jsonb_array_elements(coalesce(p_cards, '[]'::jsonb)) loop
    select * into v_pl from live_round_players
     where id = (v_card->>'player_id')::uuid and live_round_id = p_live_round;
    if v_pl.id is null then continue; end if;

    -- parse the 18-slot card once — members and guests share the shape
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
      -- guests: card saved on the player row (the claim's payload), never rounds
      update live_round_players
         set guest_strokes = coalesce(v_card->'strokes', '[]'::jsonb),
             guest_gross = case when v_holes is not null
               then (select sum(s)::int from unnest(v_strokes[1:v_holes]) s) end
       where id = v_pl.id;
      v_guests := v_guests || jsonb_build_object('name', v_pl.guest_name, 'claim_token', v_pl.claim_token);
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
                        source, attested, index_source_at_post)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            current_date, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live', true, 'app')
    returning id into v_round;

    for h in 1..v_holes loop
      if v_strokes[h] is not null then
        insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
      end if;
    end loop;

    v_posted := v_posted || jsonb_build_object('name', playerlabel(v_pid), 'gross', v_gross, 'holes', v_holes);
  end loop;

  -- the game's outcome: stored + told to the league. Casual = traceless.
  if not p_casual and p_result is not null then
    if (p_result->>'game') = 'match' then
      update live_rounds set game_result = p_result where id = p_live_round;
      v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
      -- natural case (casing policy: de-shout a generator when already inside
      -- it) — easeCaps passes mixed-case through, so names survive intact
      if (p_result->>'winner') is null then
        v_story := 'Match play: ' || coalesce(p_result->>'side_a','side A')
                || ' and ' || coalesce(p_result->>'side_b','side B')
                || ' halved the match' || case when v_stake > 0 then ' — no money moves' else '' end;
      else
        v_story := 'Match play: '
                || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'the winners')
                || ' def. '
                || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
                || ' ' || coalesce(p_result->>'status','')
                || case when v_stake > 0 then ' · $' || v_stake || ' on the line' else '' end;
      end if;
      insert into posts (league_id, kind, member_id, body)
      values (lr.league_id, 'system', my_member_id(lr.league_id), v_story);
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                left(p_result->>'story', 200));   -- story ships natural-case (casing policy)
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $_$;

revoke all on function public.finish_live_round(uuid, jsonb, boolean, jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;
