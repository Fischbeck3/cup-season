-- ============================================================================
-- D182 · The round that stops at eleven.
--
-- finish_live_round accepted exactly two card shapes: 18 complete holes, or
-- holes 1-9 with NOTHING scored after them. A 10-to-17 hole walk-off posted
-- nothing at all, while the finish sheet said "a partial card is skipped, not
-- lost". The owner lost a real 10-hole, 46-stroke round at Raven Silver that
-- way (live round a5429048).
--
-- D182 IS AMENDED BY THIS MIGRATION. Its recommendation rests on one wrong
-- sentence: "score_round already falls back to p_rating/2". That is true of the
-- 7-ARGUMENT helper, which is NOT on the posting path. The function that
-- computes rounds.differential is the 0-argument TRIGGER, and it had no such
-- fallback: a nine with a null nine_rating fell through to the FULL 18-hole
-- rating. Building D182 as written would have posted that 46-stroke nine as
-- differential -22.2 paying 6 points, tanking the golfer's index -- worse than
-- the bug it fixes. Demonstrated on Postgres 16 before this was written.
--
-- Scope also grows: claim_round carries the identical pair of guards, so
-- fixing only finish_live_round would move the loss down the guest-claim funnel.
--
-- Three changes, one shape:
--   1. a complete front nine posts as a nine whatever follows it (extras are
--      dropped by construction -- every read is v_strokes[1:v_holes] -- so no
--      net par and no walking-off-while-hot exploit),
--   2. the missing nine rating is DERIVED as half the 18 and STORED, because
--      the trigger reads the column, and
--   3. the trigger itself gets the same coalesce, as the net under everything.
--
-- Bodies for all three were taken VERBATIM from the live database
-- (pg_get_functiondef) and transformed programmatically -- not retyped. The
-- D107/D125/D150 invariants inside finish_live_round live only in a `do` block
-- that already ran, so a hand-rebuild is how a closed bug reopens.
--
-- NOT in this migration, deliberately: D182 rec 2 (a wizard door for
-- nine_hole_allowed) and rec 3 (a post-this-card recovery RPC). Rec 2 is the
-- open question D182 itself flags for the owner; rec 3 is additive and wants
-- its own contract refresh. Until rec 3 exists, a card WITHOUT a complete front
-- nine is still discarded, so the clients must not promise otherwise.
-- ============================================================================

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
  v_nine_use numeric; v_dropped int;   -- D182
begin
  if v is null then raise exception 'Sign in first'; end if;
  -- D85: multi-phone finish — take the row lock so two finishers serialize;
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
    -- D182: a complete front nine posts as a nine REGARDLESS of what was
    -- scored after it. The old `and (v_n < 10 or nothing-after)` clause is
    -- what made a 10-hole walk-off vanish. Holes 10+ are dropped by
    -- construction below (every read is v_strokes[1:v_holes]), so there is
    -- no net-par and no walk-off-while-hot exploit.
    elsif v_n >= 9 and (select count(*) from unnest(v_strokes[1:9]) s where s is null) = 0 then
      v_holes := 9;
    end if;

    -- D182: the missing nine rating stops being a hard stop. Half the 18 is
    -- the engine's own convention (the 7-arg score_round helper already used
    -- coalesce(nine, rating/2)); api_course_tees has no nine rating column at
    -- all, so requiring one skipped every nine ever played. STORED, not just
    -- computed: the rounds trigger reads the column, and without a value it
    -- falls through to the FULL 18-hole rating and writes a differential of
    -- about -22 for a 46-stroke nine. Proven on Postgres 16 before this fix.
    v_nine_use := coalesce(v_nine, round(v_rating / 2, 1));
    v_dropped  := case when v_holes = 9
                  then (select count(*)::int from unnest(v_strokes[10:18]) s where s is not null)
                  else 0 end;

    if v_pl.member_id is null then
      update live_round_players
         set guest_strokes = coalesce(v_card->'strokes', '[]'::jsonb),
             guest_gross = case when v_holes is not null
               then (select sum(s)::int from unnest(v_strokes[1:v_holes]) s) end
       where id = v_pl.id;
      -- D107 (closes the D88 gap): a seated visitor is an app golfer — their
      -- COMPLETE, rated, non-casual card posts to THEIR profile right now,
      -- and the seat is stamped claimed so claim_round can never double-post.
      -- Anything less falls back to the claim-link path exactly as before.
      if v_pl.guest_profile_id is not null and v_pl.claimed_profile is null
         and not p_casual and v_holes is not null
         and v_rating is not null and v_slope is not null
      then
        v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);
        insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                            played_on, holes_played, gross, rating, slope, nine_rating,
                            source, attested, index_source_at_post, api_course_id, posted_by)
        values (v_pl.guest_profile_id, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
                v_today, v_holes, v_gross, v_rating, v_slope, v_nine_use,
                'live',
                -- D125 · attested means a playing partner vouched, and the only
                -- evidence of that is this golfer's OWN device having been in
                -- the session. The finisher's card is attested by construction.
                (v_pl.guest_profile_id = v or v_pl.joined_at is not null),
                'app', lr.api_course_id, v)
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

    v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);

    insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                        played_on, holes_played, gross, rating, slope, nine_rating,
                        source, attested, index_source_at_post, api_course_id, posted_by)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            v_today, v_holes, v_gross, v_rating, v_slope, v_nine_use,
            'live',
            -- D125 · same rule for a member's card. This is the exact shape the
            -- audit caught: one phone seating three members and posting three
            -- rounds all stamped attested, with no way for those golfers to
            -- see it happened.
            (v_pid = v or v_pl.joined_at is not null),
            'app', lr.api_course_id, v)
    returning id into v_round;

    for h in 1..v_holes loop
      if v_strokes[h] is not null then
        insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
      end if;
    end loop;

    -- D182 rec 4: name the holes that did not count, rather than dropping
    -- strokes silently. Additive key; old clients ignore it.
    v_posted := v_posted || jsonb_build_object('name', playerlabel(v_pid), 'gross', v_gross,
                                              'holes', v_holes, 'dropped', v_dropped);
  end loop;

  if not p_casual and p_result is not null then
    if (p_result->>'game') = 'match' then
      update live_rounds set game_result = p_result where id = p_live_round;
      -- D107: no league → no board (posts.league_id is NOT NULL); the share
      -- card is the story, and each golfer's own round fans via round_to_board.
      if lr.league_id is not null then
        v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
        -- D75: a match VARIANT composes its own story client-side (round robin
        -- carries no winner/status, so the copy below would call it 'side A').
        if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
          v_story := left(p_result->>'story', 200);
        elsif (p_result->>'winner') is null then
          v_story := 'Match play: ' || coalesce(p_result->>'side_a','side A')
                  || ' and ' || coalesce(p_result->>'side_b','side B')
                  || ' halved the match' || case when v_stake > 0 then ' — no money moves' else '' end;
        else
          v_story := coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'The winners')
                  || ' beat '
                  || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
                  || case when coalesce(p_result->>'status','') <> '' then ' ' || lower(p_result->>'status') else '' end
                  || case when v_stake > 0 then '. That''s $' || v_stake || '.' else '.' end;
        end if;
        -- D92: the row now knows which round it settled
        insert into posts (league_id, kind, member_id, body, live_round_id, push_title)
        values (lr.league_id, 'system', my_member_id(lr.league_id), v_story, p_live_round,
                nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
      end if;
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if lr.league_id is not null
         and nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body, live_round_id, push_title)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                left(p_result->>'story', 200), p_live_round,
                nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $function$

;

revoke all on function public.finish_live_round(uuid,jsonb,boolean,jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid,jsonb,boolean,jsonb) to authenticated;

CREATE OR REPLACE FUNCTION public.claim_round(p_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_pl live_round_players%rowtype; lr live_rounds%rowtype;
  v_snap jsonb; v_rating numeric; v_slope int; v_nine numeric;
  v_strokes int[]; v_n int; v_holes int; v_round uuid; h int;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into v_pl from live_round_players where claim_token = p_token and member_id is null;
  if v_pl.id is null then raise exception 'No round on that link'; end if;
  if v_pl.claimed_profile is not null then
    if v_pl.claimed_profile = v then return jsonb_build_object('claimed', true, 'posted', false, 'already', true); end if;
    raise exception 'That card was already claimed';
  end if;
  select * into lr from live_rounds where id = v_pl.live_round_id;
  if lr.status <> 'final' then raise exception 'Round is still live — claim after the finish'; end if;

  update live_round_players set claimed_profile = v where id = v_pl.id;

  v_snap := coalesce(lr.course_snapshot, '{}'::jsonb);
  v_rating := nullif(v_snap->>'rating','')::numeric;
  v_slope  := nullif(v_snap->>'slope','')::int;
  v_nine   := nullif(v_snap->>'nine_rating','')::numeric;
  v_strokes := array(select nullif(x,'null')::int from jsonb_array_elements_text(coalesce(v_pl.guest_strokes,'[]'::jsonb)) x);
  v_n := coalesce(array_length(v_strokes,1), 0);
  v_holes := null;
  if v_n >= 18 and (select count(*) from unnest(v_strokes[1:18]) s where s is null) = 0 then v_holes := 18;
  elsif v_n >= 9 and (select count(*) from unnest(v_strokes[1:9]) s where s is null) = 0
        then v_holes := 9;   -- D182: same rule as finish_live_round
  end if;

  -- D182: the dead nine-rating stop goes here too. Fixing only
  -- finish_live_round would move the loss one step down the guest-claim funnel.
  if v_holes is null or v_rating is null or v_slope is null then
    return jsonb_build_object('claimed', true, 'posted', false);
  end if;

  insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                      played_on, holes_played, gross, rating, slope, nine_rating,
                      source, attested, index_source_at_post)
  values (v, v_pl.live_round_id, lr.course_id, lr.tee_id, lr.course_label,
          coalesce(lr.finished_at::date, current_date), v_holes,
          (select sum(s)::int from unnest(v_strokes[1:v_holes]) s),
          v_rating, v_slope, coalesce(v_nine, round(v_rating / 2, 1)), 'live', true, 'app')
  returning id into v_round;

  for h in 1..v_holes loop
    if v_strokes[h] is not null then
      insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
    end if;
  end loop;

  return jsonb_build_object('claimed', true, 'posted', true,
    'gross', (select sum(s)::int from unnest(v_strokes[1:v_holes]) s), 'holes', v_holes);
end $function$

;

revoke all on function public.claim_round(uuid) from public, anon;
grant execute on function public.claim_round(uuid) to authenticated;

CREATE OR REPLACE FUNCTION public.score_round()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.profile_id is null then new.profile_id := auth.uid(); end if;

  -- differential first (index-independent)
  -- D182: the net under every other fix. A nine WITHOUT a stored nine rating
  -- used to fall through to the else-branch and subtract the FULL 18-hole
  -- rating — a 46-stroke nine on a 71.5 course wrote differential -22.2, which
  -- is better than a tour pro's best round, and paid 6 points for it. Proven on
  -- Postgres 16. Half the 18 is the convention the 7-arg score_round helper has
  -- always used; D182 mistook that helper for this trigger, which is the one on
  -- the posting path. This protects scan claims, old clients and any future
  -- caller, not just the two functions fixed alongside it.
  if new.holes_played = 9 then
    new.differential := round(((new.gross - coalesce(new.nine_rating, new.rating / 2)) * 113.0 / new.slope) * 2, 1);
  else
    new.differential := round((new.gross - new.rating) * 113.0 / new.slope, 1);
  end if;

  -- index snapshot: caller-provided > standing index > engine(prior rounds) >
  -- this round's own differential (first-round provisional). NEVER a blind 18.
  if new.index_at_post is null then
    select index_current into new.index_at_post from profiles where id = new.profile_id;
  end if;
  if new.index_at_post is null then
    new.index_at_post := handicap_index_asof(new.profile_id, new.played_on, new.id);
  end if;
  new.index_at_post := coalesce(new.index_at_post, new.differential);

  return new;
end $function$

;

revoke all on function public.score_round() from public, anon;

-- Self-enforcing: these three are the whole fix, and a rebuild-on-top that
-- restores any one of them reopens the data loss.
do $chk$
begin
  if position('v_strokes[10:18]) s where s is not null) = 0'
       in pg_get_functiondef('public.finish_live_round(uuid,jsonb,boolean,jsonb)'::regprocedure)) > 0
  then raise exception 'D182: finish_live_round still refuses a card with holes past 9'; end if;
  if position('no 9-hole rating'
       in pg_get_functiondef('public.finish_live_round(uuid,jsonb,boolean,jsonb)'::regprocedure)) > 0
  then raise exception 'D182: the dead nine-rating stop is back in finish_live_round'; end if;
  if position('v_strokes[10:18]) s where s is not null) = 0'
       in pg_get_functiondef('public.claim_round(uuid)'::regprocedure)) > 0
  then raise exception 'D182: claim_round still refuses a card with holes past 9'; end if;
  if position('coalesce(new.nine_rating' in pg_get_functiondef('public.score_round()'::regprocedure)) = 0
  then raise exception 'D182: score_round lost the derived nine rating -- a nine would post at the 18-hole rating'; end if;
end $chk$;
