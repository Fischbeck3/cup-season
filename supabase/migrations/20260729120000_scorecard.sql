-- ============================================================================
-- Cup Season — D92: the settlement post opens the scorecard
--
-- "Match play: Jerecho Fischbeck def. Jade 4&3" was a dead end. §16 says no
-- figure appears without a path to the rounds behind it, and 4&3 is a figure.
-- Two things blocked the path and both are fixed here:
--
--   1. posts.live_round_id — finish_live_round wrote the settlement row with
--      four columns (league_id, kind, member_id, body). round_id was NULL and
--      nothing referenced the live round, so the row could not route anywhere.
--      The referent is the LIVE ROUND, not round_id: a settlement is about the
--      group's round, not any one member's card.
--
--   2. live_round_card() — nothing in the product had ever read round_holes.
--      Strokes were written at post time and never fetched again. This is the
--      read path, and it is the first one.
--
-- WHERE THE CARD LIVES. D85 made live_scores durable and nothing deletes it, so
-- the group's hole-by-hole — members and guests alike — is still keyed by
-- live_round_id after the finish. That is the primary source. Per player we
-- fall back to round_holes (members) and live_round_players.guest_strokes
-- (guests) so rounds finished BEFORE D85 shipped still open.
--
-- WHY SECURITY DEFINER RATHER THAN RLS. The rholes_read policy gates hole
-- detail on the round's season_id resolving to a league you belong to. But
-- rounds.season_id is never set by ANY server-side insert — the live finalize
-- omits the column, as do the scan and sandbox paths — so under RLS the holes
-- of most rounds are unreadable even by the golfer who played them. This
-- function carries its own guard instead. The NULL season_id is REAL DEBT and
-- is logged as such in D92; it is deliberately not fixed here.
-- ============================================================================

alter table public.posts add column if not exists live_round_id uuid
  references public.live_rounds(id) on delete set null;

-- the board reads by league + recency; this index serves the reverse lookup
-- (which post settled this round) that the client uses to avoid duplicates
create index if not exists posts_live_round_idx
  on public.posts (live_round_id) where live_round_id is not null;

-- ---- backfill: the settlements already on the board -------------------------
-- D92 first said no backfill, on the grounds that joining a body string to a
-- round is guesswork. Measured against prod, it is not: the settlement post and
-- `update live_rounds set finished_at = now()` run in ONE transaction, and
-- now() is the transaction timestamp — so created_at is byte-identical to
-- finished_at (verified: delta 0.000000 across every settled round on disk).
--
-- Timestamp equality alone is NOT enough. A handicap-change post fires from a
-- trigger inside the same transaction and carries the same instant exactly, so
-- the body must match the settlement the round actually recorded:
--   · match play — the server composes 'Match play: …'
--   · the ledger games — the body IS left(game_result->>'story', 200)
-- Anything else is left alone. A round with no game_result cannot match.
update posts p
   set live_round_id = lr.id
  from live_rounds lr
 where p.live_round_id is null
   and p.kind = 'system'
   and p.league_id = lr.league_id
   and lr.finished_at is not null
   and p.created_at = lr.finished_at
   and lr.game_result is not null
   and ( p.body like 'Match play: %'
         or p.body = left(lr.game_result->>'story', 200) )
   -- refuse the ambiguous case rather than guess it
   and (select count(*) from live_rounds l2
         where l2.league_id = p.league_id and l2.finished_at = p.created_at) = 1;

-- ---- finish_live_round: stamp the settlement post with its round ------------
-- Body = 20260728120000 (D85, the row lock) with live_round_id added to both
-- board-post inserts. Everything else is byte-identical.
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
  -- D85: multi-phone finish — take the row lock so two finishers serialize;
  -- the second sees status='final' below and returns already_final.
  select * into lr from live_rounds where id = p_live_round for update;
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

  if not p_casual and p_result is not null then
    if (p_result->>'game') = 'match' then
      update live_rounds set game_result = p_result where id = p_live_round;
      v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
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
      -- D92: the row now knows which round it settled
      insert into posts (league_id, kind, member_id, body, live_round_id)
      values (lr.league_id, 'system', my_member_id(lr.league_id), v_story, p_live_round);
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body, live_round_id)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                left(p_result->>'story', 200), p_live_round);
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $_$;

revoke all on function public.finish_live_round(uuid, jsonb, boolean, jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;

-- ---- the read path: the whole sheet, one call ------------------------------
-- Guard: you played in the round, or you are a member of the league it posted
-- to. That second clause is what lets a squad-mate who wasn't there open the
-- card their board is showing them.
create or replace function public.live_round_card(p_live_round uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype;
  v_players jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into lr from live_rounds where id = p_live_round;
  if lr.id is null then raise exception 'No such round'; end if;

  if not exists (select 1 from live_round_players p
                   join league_members m on m.id = p.member_id
                  where p.live_round_id = lr.id and m.profile_id = v)
     and not exists (select 1 from live_round_players p
                      where p.live_round_id = lr.id and p.guest_profile_id = v)
     and not exists (select 1 from league_members m
                      where m.league_id = lr.league_id and m.profile_id = v)
  then raise exception 'That round is not yours to read'; end if;

  select coalesce(jsonb_agg(pl order by pos), '[]'::jsonb) into v_players from (
    select p.position as pos,
      jsonb_build_object(
        'id', p.id,
        'name', coalesce(pr.display_name, p.guest_name, 'A golfer'),
        'guest', (p.member_id is null),
        'index', coalesce(pr.index_current, p.guest_index),
        'position', p.position,
        -- strokes[1..18], nulls preserved: an unscored hole is a FACT about the
        -- round and the sheet shows the gap rather than closing it.
        'strokes', (
          select jsonb_agg(coalesce(
            -- 1. the live sheet (D85 onward) — members and guests alike
            (select s.strokes from live_scores s
              where s.live_round_id = lr.id and s.player_id = p.id and s.hole_number = g.h),
            -- 2. a member's posted card (rounds finished before D85)
            (select rh.strokes from round_holes rh
               join rounds r on r.id = rh.round_id
              where r.live_round_id = lr.id and r.profile_id = m.profile_id
                and rh.hole_number = g.h),
            -- 3. a guest's saved card (kept on the player row at finish).
            -- ->> not ->: it yields TEXT and turns a JSON null into SQL NULL,
            -- where jsonb->int would need a cast jsonb does not offer.
            nullif(p.guest_strokes->>(g.h - 1), '')::int
          ) order by g.h)
          from generate_series(1, 18) as g(h)
        )
      ) as pl
    from live_round_players p
    left join league_members m on m.id = p.member_id
    left join profiles pr on pr.id = m.profile_id
    where p.live_round_id = lr.id
  ) t;

  return jsonb_build_object(
    'round', jsonb_build_object(
      'id', lr.id, 'league_id', lr.league_id, 'status', lr.status,
      'game', lr.game, 'game_config', lr.game_config, 'game_result', lr.game_result,
      'course_label', lr.course_label, 'course_snapshot', lr.course_snapshot,
      'started_at', lr.started_at, 'finished_at', lr.finished_at),
    'players', v_players);
end $$;
revoke all on function public.live_round_card(uuid) from public, anon;
grant execute on function public.live_round_card(uuid) to authenticated;
