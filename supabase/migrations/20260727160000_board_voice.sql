-- ============================================================================
-- Cup Season — D77 on the board: the league feed stops shouting engine output
--
-- D77 ruled that the result outranks the names on every settlement artifact and
-- that engine vocabulary never reaches a reader. The client half shipped in
-- 7363e46. This is the SQL half: eight functions whose posts the whole crew
-- reads, every one of them still emitting upper()'d full legal names and
-- machine words.
--
--   round_to_board   JERECHO FISCHBECK POSTED 92 GROSS · ENCANTO GC · DIFF 18.9
--                 -> Jerecho posted 92 at Encanto GC.
--   round_moments    three headlines REVERTED by 20260722100000 back to
--                    'SET A PERSONAL BEST — DIFF 5.2 (WAS 6.1)'. Restored to the
--                    20260716190000_moment_voice wording. This is the one entry
--                    here that is a regression fix, not a rewrite.
--   close_month      'FLOOR MISSED — 5 PTS OFF THE BOARD' named nobody: the crew
--                    read a penalty and could not tell whose it was. Now it
--                    names the golfer and the month, and carries member_id so
--                    the post is attributable like every other one.
--   create_forfeit   upper() was mangling two display names AND dragging the
--                    user's own terms through easeCaps.
--   finish_live_round the match board row: label first, result last.
--   make_pick        'R2P3' — easeCaps renders that 'R2p3', visible nonsense.
--                    The overall pick number is what people track anyway.
--   resolve_session  the Ryder cup result, with the MVP as an upper()'d full
--                    name trailed by a bare W-L-H triple.
--   settle_major     150 chars and five ' · ' segments — a whole leaderboard
--                    transcribed into one post.
--
-- EVERY BODY BELOW IS THE LIVE DEFINITION, pulled with supabase db dump and
-- patched by script — not retyped. Each replacement was asserted to match
-- exactly once inside its own function before emission, so the only difference
-- from what is running now is the copy. No signature, no logic, no security
-- setting changes.
--
-- POSTED ROWS ARE NOT REWRITTEN. Existing board posts are immutable free text
-- by design (§16); this changes what gets written from here on.
--
-- Grants restated per D37: create-or-replace preserves an existing ACL, but
-- CLAUDE.md's landmine is that a function can pick up PUBLIC execute depending
-- on which role ran the migration. Restating costs nothing and closes it.
-- ============================================================================

-- The one new object: first names leave the app, full names stay in it (D77).
-- IMMUTABLE so it can be used anywhere; never returns empty, because a blank
-- name would silently delete the subject of the sentence.
create or replace function public.firstname(p text)
returns text language sql immutable as $fn$
  select coalesce(nullif(split_part(btrim(coalesce(p, '')), ' ', 1), ''), 'Someone');
$fn$;
revoke all on function public.firstname(text) from public, anon;
grant execute on function public.firstname(text) to authenticated;


-- ---- round_to_board ------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."round_to_board"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'round', new.id, lm.id,
         firstname(coalesce(p.display_name, 'A member'))
         || ' posted ' || new.gross
         || case when new.holes_played = 9 then ' for nine' else '' end
         || case when coalesce(new.course_label,'') <> ''
                 then ' at ' || new.course_label else '' end
         || '.'
  from league_members lm
  join profiles p on p.id = new.profile_id
  join seasons s on s.league_id = lm.league_id
                and s.status in ('active','cup_final')
                and new.played_on between s.starts_on and s.ends_on
  where lm.profile_id = new.profile_id;
  return new;
end $$;

-- ---- round_moments -------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."round_moments"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v            uuid := new.profile_id;
  v_name       text;
  v_prior_best numeric;
  v_barrier    int  := null;
  v_streak     int  := 0;
  v_first_week boolean := false;
  v_is_first   boolean := false;
  v_thr        int;
  v_moment     text := null;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  select firstname(coalesce(display_name, 'A golfer')) into v_name
    from profiles where id = v;

  -- 1) career barrier (18-hole gross): lowest threshold crossed for the headline
  if new.holes_played = 18 and new.gross is not null then
    if new.gross < 80 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 80
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 80;
    elsif new.gross < 90 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 90
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 90;
    elsif new.gross < 100 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 100
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 100;
    end if;
  end if;

  -- 2) personal-best differential (vs every prior round)
  select min(differential) into v_prior_best
    from rounds where profile_id = v and id <> new.id
      and not voided and differential is not null
      and coalesce(source,'app') <> 'sim';

  -- 3) iron-man streak — only when this is the first post of its week
  select count(*) = 0 into v_first_week
    from rounds where profile_id = v and id <> new.id and not voided
      and date_trunc('week', played_on) = date_trunc('week', new.played_on);
  if v_first_week then
    with wks as (
      select distinct date_trunc('week', played_on)::date w
        from rounds
       where profile_id = v and not voided and played_on <= new.played_on
    ), grp as (
      select w, w - (row_number() over (order by w) * interval '7 day') as g
        from wks
    )
    select count(*) into v_streak
      from grp
     where g = (select g from grp order by w desc limit 1);
  end if;

  -- ---- persistent achievements (same detection, permanent home) ----
  v_is_first := not exists (
    select 1 from rounds where profile_id = v and id <> new.id
      and not voided and coalesce(source,'app') <> 'sim');
  if v_is_first then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'first_round', 'First round posted', new.played_on, new.id,
            jsonb_build_object('gross', new.gross))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- barriers for the case: award EVERY threshold newly crossed (not just the headline)
  if new.holes_played = 18 and new.gross is not null then
    foreach v_thr in array array[100, 90, 80] loop
      if new.gross < v_thr and not exists (
        select 1 from rounds where profile_id = v and id <> new.id
          and not voided and holes_played = 18 and gross < v_thr
          and coalesce(source,'app') <> 'sim') then
        insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
        values (v, 'sub_' || v_thr, 'Broke ' || v_thr, new.played_on, new.id,
                jsonb_build_object('gross', new.gross))
        on conflict (profile_id, kind) do nothing;
      end if;
    end loop;
  end if;

  if v_prior_best is not null and new.differential < v_prior_best then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'personal_best', 'Personal best', new.played_on, new.id,
            jsonb_build_object('diff', new.differential))
    on conflict (profile_id, kind) do update
      set earned_on = excluded.earned_on, round_id = excluded.round_id, meta = excluded.meta;
  end if;

  if v_first_week and v_streak in (4, 8, 12) then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'streak_' || v_streak, v_streak || '-week streak', new.played_on, new.id,
            jsonb_build_object('weeks', v_streak))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- ---- one ephemeral headline (barrier > PB > streak) ----
  if v_barrier is not null then
    v_moment := v_name || ' broke ' || v_barrier
             || ' for the first time — a ' || new.gross || '. That one goes on the wall.';
  elsif v_prior_best is not null and new.differential < v_prior_best then
    v_moment := v_name || ' set a personal best. New number to chase.';
  elsif v_first_week and v_streak >= 4 and v_streak % 4 = 0 then
    v_moment := v_name || ' has posted ' || v_streak
             || ' weeks running. Iron man doesn''t take weeks off.';
  end if;

  if v_moment is null then return new; end if;

  -- round_id rides the post: delete the round, the headline goes with it
  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'moment', new.id, lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  return new;
end $$;

-- ---- close_month ---------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."close_month"("p_season" "uuid", "p_month" "date") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare st record; se record; m record; short numeric; delta int;
        winner uuid; is_partial boolean; month_last date; v_name text;
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;

  if exists (select 1 from season_adjustments
             where season_id = p_season and month = p_month
               and kind = 'month_closed' and created_by is null) then
    return;
  end if;

  month_last := (p_month + interval '1 month' - interval '1 day')::date;
  is_partial := (se.starts_on > p_month) or (se.ends_on < month_last);

  -- 1 · floor penalties — now with the auto-bye first-miss forgiveness (D14)
  if st.participation_floor > 0
     and st.floor_penalty in ('deduct','forfeit')
     and not is_partial then
    for m in
      select sm.squad_id, sm.member_id,
             coalesce(sum(rr.floor_credit),0) as credits,
             coalesce(sum(rr.points)
               filter (where rr.month_rank <= coalesce(st.counting_cap,999)),0)
               as counting_pts
      from squad_members sm
      join squads s on s.id = sm.squad_id and s.season_id = p_season
      left join v_rounds_ranked rr
        on rr.member_id = sm.member_id
       and rr.season_id = p_season
       and date_trunc('month', rr.played_on) = p_month
      -- a bye already booked for THIS month (Pro pre-grant) skips the member
      where not exists (select 1 from season_adjustments b
                        where b.season_id = p_season and b.member_id = sm.member_id
                          and b.month = p_month and b.kind = 'bye')
      group by sm.squad_id, sm.member_id
    loop
      short := greatest(0, st.participation_floor - m.credits);
      if short > 0 then
        -- has this member spent their ONE season bye yet (any month)?
        if not exists (select 1 from season_adjustments b
                       where b.season_id = p_season and b.member_id = m.member_id
                         and b.kind = 'bye') then
          -- no → the season's bye auto-covers this first miss. Life happens.
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'bye', 0,
                  'Auto-bye — first missed floor. Life happens; the season''s one bye.');
          select display_name into v_name from profiles p
            join league_members lm on lm.profile_id = p.id where lm.id = m.member_id;
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  upper(coalesce(v_name,'A GOLFER'))||'''S BYE KICKED IN FOR '
                  ||upper(to_char(p_month,'FMMonth'))
                  ||' — LIFE HAPPENS, NO PENALTY. THE FLOOR BITES FROM HERE.');
        elsif st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  'Floor '||st.participation_floor||'/mo — posted '||m.credits||' · bye already used');
          insert into posts (league_id, season_id, kind, member_id, body)
          values (se.league_id, p_season, 'system', m.member_id,
                  coalesce(firstname((select pr.display_name
                              from league_members lm2
                              join profiles pr on pr.id = lm2.profile_id
                             where lm2.id = m.member_id)), 'A golfer')
                  ||' was short on rounds in '||to_char(p_month,'FMMonth')
                  ||'. '||abs(delta)||' points off the squad.');
        else  -- forfeit
          if m.counting_pts > 0 then
            insert into season_adjustments
              (season_id, squad_id, member_id, month, kind, points, reason)
            values (p_season, m.squad_id, m.member_id, p_month, 'floor_forfeit',
                    -m.counting_pts,
                    'Floor '||st.participation_floor||'/mo — posted '||m.credits
                    ||' · month forfeited · bye already used');
            insert into posts (league_id, season_id, kind, member_id, body)
            values (se.league_id, p_season, 'system', m.member_id,
                    coalesce(firstname((select pr.display_name
                              from league_members lm2
                              join profiles pr on pr.id = lm2.profile_id
                             where lm2.id = m.member_id)), 'A golfer')
                    ||' loses '||to_char(p_month,'FMMonth')||' — '||m.counting_pts
                    ||' points, not enough rounds.');
          end if;
        end if;
      end if;
    end loop;
  end if;

  -- 2 · hybrid matchup bonus (unchanged)
  if st.season_format = 'hybrid' then
    select s.id into winner
    from squads s
    left join squad_members sm on sm.squad_id = s.id
    left join v_rounds_ranked rr
      on rr.member_id = sm.member_id and rr.season_id = p_season
     and date_trunc('month', rr.played_on) = p_month
     and rr.month_rank <= coalesce(st.counting_cap, 999)
    where s.season_id = p_season
    group by s.id
    order by coalesce(sum(rr.points),0) desc
    limit 1;
    if winner is not null then
      insert into season_adjustments
        (season_id, squad_id, month, kind, points, reason)
      values (p_season, winner, p_month, 'matchup_bonus', 15,
              'Monthly head-to-head winner');
      insert into posts (league_id, season_id, kind, body)
      select se.league_id, p_season, 'system', upper(name)||' TAKE THE MONTHLY +15'
      from squads where id = winner;
    end if;
  end if;

  -- 3 · sentinel + the §14.2 "month closed" board event (unchanged)
  insert into season_adjustments (season_id, month, kind, points, reason)
  values (p_season, p_month, 'month_closed', 0,
          case when is_partial then 'Partial edge month — floors waived'
               else 'Month closed' end);
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          upper(to_char(p_month,'FMMonth'))||' CLOSED — LEDGER POSTED'
          || case when is_partial then ' · PARTIAL MONTH, FLOORS WAIVED' else '' end);
end $$;
revoke all on function public.close_month(uuid, date) from public, anon;
grant execute on function public.close_month(uuid, date) to authenticated;

-- ---- create_forfeit ------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."create_forfeit"("p_league" "uuid", "p_name" "text", "p_terms" "text", "p_kind" "text" DEFAULT 'custom'::"text", "p_other" "uuid" DEFAULT NULL::"uuid", "p_hangs" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare v_id uuid; v_name text; v_terms text; v_a text; v_b text;
begin
  if not is_league_member(p_league) then raise exception 'crew only'; end if;
  v_name  := nullif(trim(coalesce(p_name,'')),'');
  v_terms := nullif(trim(coalesce(p_terms,'')),'');
  if v_name is null or v_terms is null then
    raise exception 'A stake needs a name and terms';
  end if;
  if coalesce(p_kind,'custom') not in ('hosts','course_pick','strokes','bounty','custom') then
    raise exception 'unknown stake kind';
  end if;
  if p_other is not null then
    if p_other = auth.uid() then raise exception 'You can''t stake against yourself'; end if;
    if not exists (select 1 from league_members
                    where league_id = p_league and profile_id = p_other) then
      raise exception 'The other side has to be in the crew';
    end if;
  end if;

  insert into forfeits (league_id, name, terms, kind, party_a, party_b, hangs_on, created_by)
  values (p_league, left(v_name,60), left(v_terms,200), coalesce(p_kind,'custom'),
          auth.uid(), p_other, nullif(trim(coalesce(p_hangs,'')),''), auth.uid())
  returning id into v_id;

  select firstname(display_name) into v_a from profiles where id = auth.uid();
  select firstname(display_name) into v_b from profiles where id = p_other;
  insert into posts (league_id, kind, body)
  values (p_league, 'system',
    coalesce(v_a, 'Someone')
    || case when v_b is not null then ' v ' || v_b else ' v the field' end
    || ' — ' || v_name || '. ' || v_terms);
  return v_id;
end $$;
revoke all on function public.create_forfeit(uuid, text, text, text, uuid, text) from public, anon;
grant execute on function public.create_forfeit(uuid, text, text, text, uuid, text) to authenticated;

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

-- ---- make_pick -----------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."make_pick"("p_draft" "uuid", "p_member" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare d record; se record; n_sq int; rd int; idx int;
        squad uuid; me uuid; is_c boolean; cap uuid;
begin
  select * into d from drafts where id = p_draft for update;
  if d.status <> 'live' then raise exception 'draft is not live'; end if;
  select * into se from seasons where id = d.season_id;

  me   := my_member_id(se.league_id);
  is_c := is_commissioner(se.league_id);
  if me is null then raise exception 'not a league member'; end if;

  n_sq := array_length(d.order_squads, 1);
  rd   := (d.current_pick / n_sq) + 1;                      -- 1-indexed round
  idx  := d.current_pick % n_sq;
  -- snake: even rounds reverse
  if rd % 2 = 0 then idx := n_sq - 1 - idx; end if;
  squad := d.order_squads[idx + 1];

  select captain_member_id into cap from squads where id = squad;
  if not is_c and cap is distinct from me then
    raise exception 'not your pick';
  end if;

  if d.current_pick >= n_sq * d.rounds_count then
    raise exception 'draft is full';
  end if;

  insert into draft_picks
    (draft_id, pick_number, round_number, squad_id, member_id, picked_by, via_override)
  values (p_draft, d.current_pick, rd, squad, p_member, me, is_c and cap is distinct from me);

  insert into squad_members (squad_id, member_id, drafted_round, pick_number)
  values (squad, p_member, rd, d.current_pick);

  update drafts set current_pick = current_pick + 1 where id = p_draft;

  insert into posts (league_id, season_id, kind, body)
  select se.league_id, d.season_id, 'system',
         s.name || ' take ' || firstname(p.display_name)
         || ' with pick ' || d.current_pick || '.'
  from squads s, league_members lm join profiles p on p.id = lm.profile_id
  where s.id = squad and lm.id = p_member;

  if is_c and cap is distinct from me then
    insert into commissioner_log (league_id, actor_id, action, detail)
    values (se.league_id, me, 'draft_pick_override',
            jsonb_build_object('squad', squad, 'member', p_member));
  end if;

  -- last pick closes the draft and opens the season
  if (select current_pick from drafts where id = p_draft) >= n_sq * d.rounds_count then
    update drafts  set status = 'complete', completed_at = now() where id = p_draft;
    update leagues set phase = 'season' where id = se.league_id;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, d.season_id, 'system', 'ROSTERS LOCKED — THE SEASON IS LIVE');
  end if;
end $$;
revoke all on function public.make_pick(uuid, uuid) from public, anon;
grant execute on function public.make_pick(uuid, uuid) to authenticated;

-- ---- resolve_session -----------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."resolve_session"("p_session" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_event uuid; v_no int; v_open date; v_close date; v_allow integer; v_rule text; v_def uuid;
  v_ename text;
  d record; a_pvi numeric; b_pvi numeric; a_rid uuid; b_rid uuid;
  v_res text; v_ap numeric; v_bp numeric;
  v_pairs integer; m_total numeric;
  v_ta uuid; v_tb uuid; v_na text; v_nb text; pa numeric; pb numeric; sa numeric; sb numeric;
  v_lines text; v_score text; v_win uuid; v_was text;
  mvp_name text; mvp_rec text;
begin
  select s.event_id, s.session_no, s.opens_on, s.closes_on, e.allowance, e.draw_rule,
         e.defender_team_id, e.name, e.status
    into v_event, v_no, v_open, v_close, v_allow, v_rule, v_def, v_ename, v_was
    from event_sessions s join events e on e.id = s.event_id
   where s.id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'organizer only';
  end if;

  for d in select * from event_duels where session_id = p_session loop
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into a_rid, a_pvi
      from rounds r join event_players ep on ep.id = d.a_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into b_rid, b_pvi
      from rounds r join event_players ep on ep.id = d.b_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;

    if a_pvi is null and b_pvi is null then
      v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    elsif b_pvi is null then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif a_pvi is null then v_res := 'b'; v_ap := 0; v_bp := 1;
    elsif a_pvi > b_pvi then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif b_pvi > a_pvi then v_res := 'b'; v_ap := 0; v_bp := 1;
    else v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    end if;

    update event_duels
       set a_round = a_rid, b_round = b_rid, a_pvi = a_pvi, b_pvi = b_pvi,
           a_points = v_ap, b_points = v_bp, result = v_res, resolved_at = now()
     where id = d.id;
  end loop;

  update event_sessions set status = 'closed' where id = p_session;

  select id, name into v_ta, v_na from event_teams where event_id = v_event and slot = 0;
  select id, name into v_tb, v_nb from event_teams where event_id = v_event and slot = 1;
  select coalesce(sum(points),0) into pa from v_event_scoreboard where event_id = v_event and team_id = v_ta;
  select coalesce(sum(points),0) into pb from v_event_scoreboard where event_id = v_event and team_id = v_tb;

  -- the session story: every duel line + the running scoreline
  select string_agg(line, ' · ') into v_lines from (
    select case d.result
        when 'a' then upper(pa2.display_name) || ' DEF. ' || upper(pb2.display_name)
              || ' ' || (case when d.a_pvi>=0 then '+' else '' end) || round(d.a_pvi,1)
              || '/' || coalesce((case when d.b_pvi>=0 then '+' else '' end) || round(d.b_pvi,1), 'NO ROUND')
        when 'b' then upper(pb2.display_name) || ' DEF. ' || upper(pa2.display_name)
              || ' ' || (case when d.b_pvi>=0 then '+' else '' end) || round(d.b_pvi,1)
              || '/' || coalesce((case when d.a_pvi>=0 then '+' else '' end) || round(d.a_pvi,1), 'NO ROUND')
        else upper(pa2.display_name) || ' HALVED ' || upper(pb2.display_name)
      end as line
      from event_duels d
      join event_players ea on ea.id = d.a_player join profiles pa2 on pa2.id = ea.profile_id
      join event_players eb on eb.id = d.b_player join profiles pb2 on pb2.id = eb.profile_id
     where d.session_id = p_session
     order by d.id
  ) x;
  v_score := case when pa = pb then 'LEVEL ' || evhalf(pa) || '–' || evhalf(pb)
                  when pa > pb then upper(v_na) || ' LEAD ' || evhalf(pa) || '–' || evhalf(pb)
                  else upper(v_nb) || ' LEAD ' || evhalf(pb) || '–' || evhalf(pa) end;
  if v_lines is not null then
    perform event_post(v_event, 'SESSION ' || v_no || ': ' || v_lines || ' — ' || v_score);
  end if;

  -- clinch / completion (draw rule from 20260716150000, unchanged)
  select least(
      (select count(*) from event_players where event_id = v_event and team_id = v_ta),
      (select count(*) from event_players where event_id = v_event and team_id = v_tb))
    into v_pairs;
  m_total := v_pairs * (select session_count from events where id = v_event);

  if m_total > 0 and greatest(pa, pb) > m_total/2.0 then
    update events set status='complete',
      winner_team_id = case when pa > pb then v_ta else v_tb end
      where id = v_event;
  elsif not exists (select 1 from event_sessions where event_id=v_event and status <> 'closed') then
    if pa <> pb then
      update events set status='complete',
        winner_team_id = case when pa > pb then v_ta else v_tb end
        where id = v_event;
    else
      if v_rule = 'defender' and v_def is not null then
        update events set status='complete', winner_team_id = v_def where id = v_event;
      elsif v_rule = 'shared' then
        update events set status='complete', winner_team_id = null where id = v_event;
      else
        select coalesce(sum(case when ep.team_id = v_ta then x.pvi end),0),
               coalesce(sum(case when ep.team_id = v_tb then x.pvi end),0)
          into sa, sb
          from (
            select a_player as player, a_pvi as pvi from event_duels where event_id = v_event and a_pvi is not null
            union all
            select b_player, b_pvi from event_duels where event_id = v_event and b_pvi is not null
          ) x join event_players ep on ep.id = x.player;
        update events set status='complete',
          winner_team_id = case when sa > sb then v_ta when sb > sa then v_tb else null end
          where id = v_event;
      end if;
    end if;
  end if;

  -- completion story: the cup + the MVP (best record, tiebreak total PvI)
  if v_was <> 'complete' and (select status from events where id = v_event) = 'complete' then
    select pr.display_name, s.w || '-' || s.l || '-' || s.h
      into mvp_name, mvp_rec
      from (
        select ep.profile_id,
          count(*) filter (where (d.a_player=ep.id and d.result='a') or (d.b_player=ep.id and d.result='b')) w,
          count(*) filter (where (d.a_player=ep.id and d.result='b') or (d.b_player=ep.id and d.result='a')) l,
          count(*) filter (where d.result='halve') h,
          coalesce(sum(case when d.a_player=ep.id then d.a_pvi when d.b_player=ep.id then d.b_pvi end),0) tot
        from event_players ep
        join event_duels d on d.event_id = ep.event_id
             and (d.a_player = ep.id or d.b_player = ep.id) and d.result <> 'pending'
        where ep.event_id = v_event
        group by ep.id, ep.profile_id
        order by w desc, tot desc limit 1
      ) s join profiles pr on pr.id = s.profile_id;
    select winner_team_id into v_win from events where id = v_event;
    perform event_post(v_event,
      case when v_win is null
              then v_na || ' and ' || v_nb || ' share the ' || v_ename
                   || ', ' || evhalf(pa) || '–' || evhalf(pb) || '.'
            when v_win = v_ta
              then v_na || ' take the ' || v_ename || ' ' || evhalf(pa) || '–' || evhalf(pb) || '.'
            else v_nb || ' take the ' || v_ename || ' ' || evhalf(pb) || '–' || evhalf(pa) || '.' end
      || coalesce(' ' || firstname(mvp_name) || ' is MVP at ' || mvp_rec || '.', ''));
  end if;
end $$;
revoke all on function public.resolve_session(uuid) from public, anon;
grant execute on function public.resolve_session(uuid) to authenticated;

-- ---- settle_major --------------------------------------------------------
CREATE OR REPLACE FUNCTION "public"."settle_major"("p_session" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  s record; p record; t record; f record;
  b_pvi numeric[]; b_rid uuid[]; b_gross integer[]; b_at timestamptz[];
  v_cards integer; v_pot numeric; v_entrants integer;
  v_champ record; v_ru record; v_third record;
  v_share numeric; v_paid numeric := 0; v_places integer;
  v_line text; v_flip text := ''; v_tie text := '';
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.allowance, e.buy_in, e.pot_split, e.league_id,
         e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if s.status = 'closed' then return; end if;          -- idempotent
  if auth.uid() is not null then
    if not is_event_organizer(s.event_id) then raise exception 'organizer only'; end if;
    if s.closes_on >= (now() at time zone coalesce(s.tz,'America/Phoenix'))::date then
      raise exception 'The window runs through % — the horn sounds after', to_char(s.closes_on,'Dy Mon DD');
    end if;
  end if;

  -- freeze every player's card: best + second-best eligible in the window
  for p in select ep.id, ep.profile_id, ep.exhibition
             from event_players ep where ep.event_id = s.event_id
  loop
    select array_agg(x.pvi), array_agg(x.rid), array_agg(x.gross), array_agg(x.at)
      into b_pvi, b_rid, b_gross, b_at
      from (
        select round((r.index_at_post * s.allowance / 100.0) - r.differential, 1) as pvi,
               r.id as rid, r.gross, r.created_at as at
          from rounds r
         where r.profile_id = p.profile_id
           and r.played_on between s.opens_on and s.closes_on
           and not r.voided and coalesce(r.source,'app') <> 'sim'
           and r.holes_played = 18
           and r.index_at_post is not null and r.differential is not null
         order by pvi desc, r.created_at asc, r.id
         limit 2
      ) x;
    select count(*) into v_cards
      from rounds r
     where r.profile_id = p.profile_id
       and r.played_on between s.opens_on and s.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;

    insert into event_major_cards
      (event_id, player_id, round_id, gross, pvi, second_pvi, cards,
       best_posted_at, no_card, exhibition)
    values
      (s.event_id, p.id, b_rid[1], b_gross[1], b_pvi[1], b_pvi[2], v_cards,
       b_at[1], b_pvi[1] is null, p.exhibition)
    on conflict (event_id, player_id) do nothing;
  end loop;

  -- rank the contenders: the countback ladder (D45), coin flip last.
  -- Reset first so a rerun after a mid-settle crash can't strand a stale
  -- rank or prize on a row the fresh ranking no longer pays.
  update event_major_cards set rank = null, prize = 0 where event_id = s.event_id;
  with ranked as (
    select id, pvi, second_pvi, best_posted_at,
           row_number() over (order by pvi desc, second_pvi desc nulls last,
                              best_posted_at asc, random()) as rn
      from event_major_cards
     where event_id = s.event_id and not exhibition and not no_card
  )
  update event_major_cards c set rank = r.rn
    from ranked r where c.id = r.id;

  -- name the rungs that decided anything (receipts on the board)
  for t in
    select a.rank as arank, pa.display_name as aname, pb.display_name as bname,
           (a.second_pvi is not distinct from b.second_pvi
            and a.best_posted_at is not distinct from b.best_posted_at) as flipped
      from event_major_cards a
      join event_major_cards b on b.event_id = a.event_id and b.rank = a.rank + 1
      join event_players epa on epa.id = a.player_id join profiles pa on pa.id = epa.profile_id
      join event_players epb on epb.id = b.player_id join profiles pb on pb.id = epb.profile_id
     where a.event_id = s.event_id and a.pvi = b.pvi and a.rank <= 3
  loop
    if t.flipped then
      v_flip := v_flip || ' · COIN FLIP: ' || upper(t.aname) || ' OVER ' || upper(t.bname);
    elsif t.arank = 1 then
      v_tie := ' (ON COUNTBACK)';
    end if;
  end loop;

  -- the pot: contender entrants only (exhibition never buys in, never pays)
  select count(*) into v_entrants
    from event_major_cards where event_id = s.event_id and not exhibition;
  v_pot := s.buy_in * v_entrants;
  select count(*) into v_places
    from event_major_cards where event_id = s.event_id and rank is not null;

  if v_pot > 0 and v_places > 0 then
    if s.pot_split = 'wta' then
      update event_major_cards set prize = v_pot
       where event_id = s.event_id and rank = 1;
    else
      -- 60/25/15; a place the field can't fill rolls up to the champion
      if v_places >= 2 then
        v_share := round(v_pot * 0.25, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 2;
        v_paid := v_paid + v_share;
      end if;
      if v_places >= 3 then
        v_share := round(v_pot * 0.15, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 3;
        v_paid := v_paid + v_share;
      end if;
      update event_major_cards set prize = v_pot - v_paid
       where event_id = s.event_id and rank = 1;
    end if;
  end if;

  update event_sessions set status = 'closed' where id = p_session;

  -- podium reads
  select pr.display_name, c.gross, c.pvi, c.prize into v_champ
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 1;
  select pr.display_name, c.pvi into v_ru
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 2;
  select pr.display_name, c.pvi into v_third
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 3;

  -- completion FIRST (trophy trigger reads the ranked cards), then the story
  update events set status = 'complete' where id = s.event_id;

  if v_champ.display_name is null then
    v_line := upper(s.name) || ': '
      || case when exists (select 1 from event_major_cards
                            where event_id = s.event_id and exhibition and not no_card)
              then 'NO OFFICIAL CARDS — THE JUG STAYS IN THE CASE'
              else 'NO CARDS POSTED — THE JUG STAYS IN THE CASE' end
      || case when s.buy_in > 0 then ' · BUY-INS RETURNED' else '' end;
  else
    v_line := firstname(v_champ.display_name) || ' takes the ' || s.name
      || ', ' || lower(mj_vs(v_champ.pvi)) || '.' || v_tie
      || case when v_pot > 0 and s.pot_split = 'wta' then ' And the ' || mj_money(v_pot) || '.'
              when v_pot > 0 then ' ' || mj_money(v_pot) || ' in the pot.'
              else '' end
      || v_flip;
  end if;
  perform major_post(s.event_id, v_line);

  -- the best exhibition run gets its line (never the jug — D44)
  select pr.display_name, c.gross, c.pvi into f
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.exhibition and not c.no_card
   order by c.pvi desc limit 1;
  if f.display_name is not null then
    perform event_post(s.event_id,
      'EXHIBITION: ' || upper(f.display_name) || ' WENT ' || f.gross || ' (' || mj_vs(f.pvi)
      || ') — OFFICIAL BY THE NEXT ONE');
  end if;
end $$;
revoke all on function public.settle_major(uuid) from public, anon;
grant execute on function public.settle_major(uuid) to authenticated;
