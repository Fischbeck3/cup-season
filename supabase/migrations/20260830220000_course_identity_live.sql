-- ============================================================================
-- D150 (1/3) . the live path finally records WHICH course
--
-- A live round is the highest-signal moment in the product for "where did you
-- play" -- a foursome, at a real place, together -- and it was the ONLY posting
-- path that recorded nothing about the course's identity. Its course_snapshot
-- captures the course's SHAPE (pars, stroke index, rating, slope) and not its
-- name; start_live_round is called from the client with `p_course_id:null`
-- hardcoded even though the setup screen already ran the course picker and is
-- holding the catalogue id in the DOM; and finish_live_round then copies
-- lr.course_id -- a column that is null on all 15 live rounds, because it
-- points at the legacy `courses` table, which has ZERO rows and always has.
--
-- Measured before this migration: 0 of 5 live-sourced rounds carry an
-- api_course_id, against 15 of 206 from the quick post.
--
-- Adds live_rounds.api_course_id, a defaulted trailing p_api_course_id on
-- start_live_round (so a client shipped before this migration simply omits it),
-- and carries it onto every round finish_live_round mints.
--
-- The reference stays SOFT, exactly as 20260714050000 made rounds.api_course_id
-- soft: a tee-off must never fail because the course cache is cold. The legacy
-- course_id/tee_id columns stay and are still written -- harmless nulls, and
-- dropping FK'd columns buys nothing today (D150).
--
-- Both bodies below were taken from the LIVE database, not from a migration
-- file: start_live_round has eight `create or replace` definitions in the tree
-- and finish_live_round thirteen, several in uppercase with quoted identifiers
-- that a lowercase grep misses. The only safe base is the one actually running
-- (D144 was nearly shipped on the wrong body for exactly this reason).
-- ============================================================================

alter table public.live_rounds add column if not exists api_course_id text;

create index if not exists rounds_api_course_idx on public.rounds (api_course_id)
  where api_course_id is not null;

CREATE OR REPLACE FUNCTION public.start_live_round(p_league uuid DEFAULT NULL::uuid, p_course_id uuid DEFAULT NULL::uuid, p_tee_id uuid DEFAULT NULL::uuid, p_course_label text DEFAULT NULL::text, p_snapshot jsonb DEFAULT NULL::jsonb, p_game text DEFAULT NULL::text, p_players jsonb DEFAULT NULL::jsonb, p_config jsonb DEFAULT '{}'::jsonb, p_api_course_id text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_member uuid; v_season uuid; v_lr uuid; v_pos int := 0; v_el jsonb;
  v_code text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  v_who text; v_where text; v_title text; v_body text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_league is not null then
    select id into v_member from league_members where league_id = p_league and profile_id = v;
    if v_member is null then raise exception 'You are not in this league'; end if;
    select id into v_season from seasons
     where league_id = p_league and status in ('active','cup_final')
     order by starts_on desc limit 1;
    if v_season is null then raise exception 'No active season to post into'; end if;
  end if;
  -- D107: without a league, v_member and v_season stay null â the round
  -- belongs to its starter by profile, and there is nothing to post into.

  insert into live_rounds (league_id, season_id, course_id, tee_id, course_label,
                           course_snapshot, game, game_config, status, started_by,
                           starter_profile_id, join_code, api_course_id)
  values (p_league, v_season, p_course_id, p_tee_id,
          coalesce(nullif(trim(p_course_label), ''), 'Course'),
          coalesce(p_snapshot, '{}'::jsonb),
          coalesce(nullif(p_game, ''), 'none'),
          coalesce(p_config, '{}'::jsonb), 'live', v_member, v, v_code,
          nullif(trim(coalesce(p_api_course_id, '')), ''))
  returning id into v_lr;

  for v_el in select * from jsonb_array_elements(coalesce(p_players, '[]'::jsonb)) loop
    if (v_el->>'member_id') is not null then
      if p_league is null then
        raise exception 'No league on this round â seat golfers as guests';
      end if;
      if not exists (
        select 1 from league_members
         where id = (v_el->>'member_id')::uuid and league_id = p_league) then
        raise exception 'A tagged player is not in this league';
      end if;
    end if;
    insert into live_round_players (live_round_id, member_id, guest_name, guest_index,
                                    index_source, position, guest_profile_id)
    values (
      v_lr,
      nullif(v_el->>'member_id','')::uuid,
      nullif(trim(coalesce(v_el->>'guest_name','')), ''),
      nullif(v_el->>'guest_index','')::numeric,
      case when (v_el->>'member_id') is not null then 'member'
           when (v_el->>'guest_index') is not null then 'self' else 'estimated' end,
      v_pos,
      -- D88: only meaningful on a guest row; a member row is already identified
      case when (v_el->>'member_id') is null
           then nullif(v_el->>'guest_profile','')::uuid end);
    v_pos := v_pos + 1;
  end loop;

  -- D86/D88 Â· the invitation. Members by member_id, visitors by
  -- guest_profile_id; never the starter, never an account-less guest (there is
  -- no one to notify â they have a name and nothing else).
  select split_part(coalesce(playerlabel(v), 'Someone'), ' ', 1) into v_who;
  v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');
  v_title := v_who || ' put you on the tee sheet';
  v_body  := 'Live round at ' || v_where || ' â open the app to score it with them';
  -- wave 7 Â· routed: the phone opens THIS live round (contract Â§2, `nudge`)
  insert into push_nudges (profile_id, kind, title, body, payload)
  select distinct pr, 'nudge', v_title, v_body,
         jsonb_build_object('live_round_id', v_lr, 'league_id', p_league)
    from (
    select m.profile_id as pr
      from live_round_players p
      join league_members m on m.id = p.member_id
     where p.live_round_id = v_lr and p.member_id is not null
    union
    select p.guest_profile_id
      from live_round_players p
     where p.live_round_id = v_lr and p.guest_profile_id is not null
  ) t where pr is distinct from v;

  return jsonb_build_object('live_round_id', v_lr, 'join_code', v_code, 'players', (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', id, 'member_id', member_id, 'guest_name', guest_name,
             'claim_token', claim_token, 'position', position) order by position), '[]'::jsonb)
      from live_round_players where live_round_id = v_lr));
end $function$;

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
                        source, attested, index_source_at_post)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live', true, 'app')
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

-- D37: grants are explicit. start_live_round gained a parameter, so the OLD
-- signature still exists as a separate overload — drop it, or PostgREST cannot
-- resolve a call that omits p_config and a stale client hits "not unique".
drop function if exists public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb);

revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb, text) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb, text) to authenticated;
revoke all on function public.finish_live_round(uuid, jsonb, boolean, jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text; v_n int;
begin
  if not exists (select 1 from information_schema.columns
                  where table_schema='public' and table_name='live_rounds'
                    and column_name='api_course_id') then
    raise exception 'D150: live_rounds.api_course_id missing';
  end if;

  select prosrc into v_src from pg_proc
   where proname='start_live_round' and pronamespace='public'::regnamespace;
  if position('api_course_id' in v_src) = 0 then
    raise exception 'D150: start_live_round does not store the course identity';
  end if;

  select prosrc into v_src from pg_proc
   where proname='finish_live_round' and pronamespace='public'::regnamespace;
  if position('lr.api_course_id' in v_src) = 0 then
    raise exception 'D150: finish_live_round does not carry the course identity onto the round';
  end if;
  -- the live path must still mint rounds at all
  if position('insert into rounds' in v_src) = 0 then
    raise exception 'D150: finish_live_round no longer writes rounds — wrong base';
  end if;

  -- exactly one start_live_round overload, or PostgREST cannot resolve a call
  select count(*) into v_n from pg_proc
   where proname='start_live_round' and pronamespace='public'::regnamespace;
  if v_n <> 1 then
    raise exception 'D150: % start_live_round overloads exist — PostgREST will fail to resolve', v_n;
  end if;
end $chk$;
