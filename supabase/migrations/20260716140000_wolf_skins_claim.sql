-- ============================================================================
-- Cup Season — tee sheet checkpoint 3: Wolf + Skins persist, guests can CLAIM
--
-- 1. Guest cards get SAVED. Checkpoint 1 skipped guests entirely at finish —
--    which made the claim link a promise with nothing behind it. Now their
--    strokes/gross land on live_round_players (never in rounds: guests have no
--    profile yet — that's the point of the claim).
-- 2. finish_live_round posts the WOLF/SKINS story to the board (client
--    composes it from the ledger it showed all round; capped + upcased here).
--    Match keeps its structured composition from 20260716130000. Casual stays
--    traceless for every game.
-- 3. The claim funnel gets real:
--      claim_round_info(token) — ANON-callable: the guest's own card + the
--        game story, enough to render "your round is waiting" at the door.
--      claim_round(token)      — signed-in: stamps claimed_profile, and if the
--        card is complete + rated, posts a real rounds row to the new profile
--        (source 'live', attested — they played it with the group).
-- ============================================================================

alter table public.live_round_players
  add column if not exists guest_strokes jsonb,
  add column if not exists guest_gross int,
  add column if not exists claimed_profile uuid references public.profiles(id);

-- skins joins the game list (decision-log D9 — pulled forward with Wolf)
alter table public.live_rounds drop constraint if exists live_rounds_game_check;
alter table public.live_rounds add constraint live_rounds_game_check
  check (game = any (array['none','match','wolf','skins']));

-- ---- finish: save guest cards + wolf/skins board story ----------------------
create or replace function public.finish_live_round(
  p_live_round uuid, p_cards jsonb, p_casual boolean default false,
  p_result jsonb default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
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
      if (p_result->>'winner') is null then
        v_story := 'MATCH PLAY: ' || upper(coalesce(p_result->>'side_a','SIDE A'))
                || ' AND ' || upper(coalesce(p_result->>'side_b','SIDE B'))
                || ' HALVED THE MATCH' || case when v_stake > 0 then ' — NO MONEY MOVES' else '' end;
      else
        v_story := 'MATCH PLAY: '
                || upper(coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'WINNERS'))
                || ' DEF. '
                || upper(coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'THE OTHER SIDE'))
                || ' ' || upper(coalesce(p_result->>'status',''))
                || case when v_stake > 0 then ' · $' || v_stake || ' ON THE LINE' else '' end;
      end if;
      insert into posts (league_id, kind, member_id, body)
      values (lr.league_id, 'system', my_member_id(lr.league_id), v_story);
    elsif (p_result->>'game') in ('wolf','skins') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                upper(left(p_result->>'story', 200)));
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $$;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;

-- ---- the claim funnel --------------------------------------------------------
-- Anon-callable: just enough to render "your round is waiting" at the door.
-- The token IS the authorization (unguessable uuid, held by the guest alone).
create or replace function public.claim_round_info(p_token uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_pl live_round_players%rowtype; lr live_rounds%rowtype; v_holes int;
begin
  select * into v_pl from live_round_players where claim_token = p_token and member_id is null;
  if v_pl.id is null then return null; end if;
  select * into lr from live_rounds where id = v_pl.live_round_id;
  if lr.status <> 'final' then return null; end if;
  select count(*)::int into v_holes
    from jsonb_array_elements_text(coalesce(v_pl.guest_strokes,'[]'::jsonb)) x where x <> 'null';
  return jsonb_build_object(
    'guest_name', v_pl.guest_name,
    'gross', v_pl.guest_gross,
    'holes_scored', v_holes,
    'course_label', lr.course_label,
    'played_on', to_char(coalesce(lr.finished_at, now()), 'YYYY-MM-DD'),
    'game', lr.game,
    'game_result', lr.game_result,
    'claimed', v_pl.claimed_profile is not null);
end $$;
grant execute on function public.claim_round_info(uuid) to anon, authenticated;

-- Signed-in: attach the round to the new golfer. Complete + rated card becomes
-- a real rounds row (their first round, attested — they played it with the
-- group); otherwise the claim still links identity for the recap.
create or replace function public.claim_round(p_token uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
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
        and (v_n < 10 or (select count(*) from unnest(v_strokes[10:18]) s where s is not null) = 0) then v_holes := 9;
  end if;

  if v_holes is null or v_rating is null or v_slope is null or (v_holes = 9 and v_nine is null) then
    return jsonb_build_object('claimed', true, 'posted', false);
  end if;

  insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                      played_on, holes_played, gross, rating, slope, nine_rating,
                      source, attested, index_source_at_post)
  values (v, v_pl.live_round_id, lr.course_id, lr.tee_id, lr.course_label,
          coalesce(lr.finished_at::date, current_date), v_holes,
          (select sum(s)::int from unnest(v_strokes[1:v_holes]) s),
          v_rating, v_slope, v_nine, 'live', true, 'app')
  returning id into v_round;

  for h in 1..v_holes loop
    if v_strokes[h] is not null then
      insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
    end if;
  end loop;

  return jsonb_build_object('claimed', true, 'posted', true,
    'gross', (select sum(s)::int from unnest(v_strokes[1:v_holes]) s), 'holes', v_holes);
end $$;
grant execute on function public.claim_round(uuid) to authenticated;
