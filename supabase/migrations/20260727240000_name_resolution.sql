-- ============================================================================
-- Cup Season — D77: the two places the app could not tell a name from a name
--
-- Both leftovers from the outbound-copy sweep have the same shape: the code
-- holds a string that is EITHER a squad name or a person's name, and no way to
-- know which — so it could not shorten either without risking "Mudshark".
--
-- 1 · season_email_payload returns `solo`. The flag already existed: v_solo is
--     computed on the first lines of that function and drives whether the
--     champion is read from squads or from profiles. It was simply never
--     returned, so the recap email printed a full legal name for a solo
--     champion. Now: solo -> "The Cup goes to Jerecho by 24", squads ->
--     "The Cup goes to Mudsharks by 24". One key, no new query, no new join.
--     This is live, not theoretical — the only active league (Fellas) has zero
--     squads and crowns a person in January.
--
-- 2 · posts.push_title. A settlement's board row deliberately keeps FULL names
--     (D77: the feed has the app's context around it), but push derives its
--     headline from that row's first sentence — so a 2v2 lock screen read
--     "Jerecho Fischbeck & Jade Smith beat Will Ferrell & Isaak Cole 3&2",
--     inside the character budget but long enough that iOS may cut before the
--     score. The short form already exists: the client composes `share` and
--     finish_live_round already receives it inside p_result. It is now carried
--     onto the post so push can prefer it, and the feed row is unchanged.
--
--     Nullable and capped at 80. Any post without one — every kind except a
--     settlement — falls through to the existing first-sentence split, which
--     is correct for them. Skew-safe: an older client sends no `share`, nullif
--     stores NULL, push falls through exactly as it does today.
--
-- Both function bodies below are the LIVE definitions pulled with supabase db
-- dump and patched by script, each replacement asserted to match exactly once.
-- Grants restated per D37.
-- ============================================================================

-- the column first: finish_live_round below writes to it
alter table public.posts add column if not exists push_title text;

-- ---- season_email_payload ------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."season_email_payload"("p_season" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se seasons%rowtype; v_league text; v_champ text; v_run text; v_king text;
        v_rows jsonb; v_to jsonb; v_solo boolean; st league_settings%rowtype;
begin
  select * into se from seasons where id = p_season and status = 'complete';
  if se.id is null then return null; end if;
  select name into v_league from leagues where id = se.league_id;
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (coalesce(st.structure,'') = 'solo');

  -- #1: ensure a persisted prefs row (hence a real token) for every member
  -- BEFORE building the list. Idempotent; default recap=true keeps everyone
  -- opted in unless they've turned it off.
  insert into email_prefs (profile_id)
    select lm.profile_id from league_members lm where lm.league_id = se.league_id
  on conflict (profile_id) do nothing;

  if v_solo then
    select p.display_name into v_champ from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.champion_member_id;
    select p.display_name into v_run from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.runnerup_member_id;
  else
    select name into v_champ from squads where id = se.champion_squad_id;
    select name into v_run   from squads where id = se.runnerup_squad_id;
  end if;
  select p.display_name into v_king from league_members lm
    join profiles p on p.id = lm.profile_id where lm.id = se.points_king_member_id;

  if v_solo then
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select p.display_name as name, vi.points from v_individual_standings vi
              join league_members lm on lm.id = vi.member_id
              join profiles p on p.id = lm.profile_id
             where vi.season_id = p_season order by vi.points desc limit 5) q;
  else
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select s.name, vs.points from v_squad_standings vs
              join squads s on s.id = vs.squad_id
             where vs.season_id = p_season order by vs.points desc limit 5) q;
  end if;

  -- recipients: real addresses only, still opted in, with their own money line
  select coalesce(jsonb_agg(jsonb_build_object(
           'email', t.email, 'name', t.display_name,
           'token', t.token, 'cents', t.cents)), '[]'::jsonb)
    into v_to
    from (
      select p.email, p.display_name,
             ep.token,
             coalesce((select sum(sp.cents) from season_payouts sp
                        where sp.season_id = p_season and sp.profile_id = p.id), 0) as cents
        from league_members lm
        join profiles p on p.id = lm.profile_id
        left join email_prefs ep on ep.profile_id = p.id
       where lm.league_id = se.league_id
         and p.email is not null
         and p.email <> ''
         and p.email not like '%@cupseason.invalid'
         and p.email not like '%@sandbox.cupseason.test'
         and coalesce(ep.recap, true)
    ) t;

  return jsonb_build_object(
    'season_id', p_season, 'league', v_league,
    'champion', coalesce(v_champ,'The champion'), 'runner_up', v_run,
    'points_king', v_king,
    'champion_score', se.champion_score, 'runnerup_score', se.runnerup_score,
    'tiebreak', se.tiebreak_rung,
    'starts_on', to_char(se.starts_on,'YYYY-MM-DD'),
    'ends_on',   to_char(se.ends_on,'YYYY-MM-DD'),
    'rows', v_rows, 'recipients', v_to,
    -- D77: v_solo has been computed at the top of this function all along (it
    -- picks squad names vs golfer names above) and was never returned, so the
    -- email could not tell a squad from a person and had to print full legal
    -- names to stay safe. One key, no new query.
    'solo', coalesce(v_solo, false));
end $$;
revoke all on function public.season_email_payload(uuid) from public, anon;
grant execute on function public.season_email_payload(uuid) to authenticated;

-- ---- finish_live_round ---------------------------------------------------
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
      if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        -- D75: a match variant (round robin) composes its own story client-side
        v_story := left(p_result->>'story', 200);
      elsif (p_result->>'winner') is null then
        v_story := 'All square — ' || coalesce(p_result->>'side_a','side A')
                || ', ' || coalesce(p_result->>'side_b','side B') || '.'
                || case when v_stake > 0 then ' Nobody pays.' else '' end;
      else
        v_story := coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'The winners')
                || ' beat '
                || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
                || ' ' || coalesce(p_result->>'status','')
                || case when v_stake > 0 then '. That''s $' || v_stake || '.' else '.' end;
      end if;
      insert into posts (league_id, kind, member_id, body, push_title)
      values (lr.league_id, 'system', my_member_id(lr.league_id), v_story,
              nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body, push_title)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                left(p_result->>'story', 200),    -- story ships natural-case (casing policy)
                nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $_$;
revoke all on function public.finish_live_round(uuid, jsonb, boolean, jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;
