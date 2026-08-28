-- ============================================================================
-- Cup Season — two logged engine bugs (docs/ios/DECISIONS.md:159–166; launch
-- review 2026-08-28, item #10).
--
-- 1. transfer_pro() never moved leagues.commissioner_id. It swapped
--    league_members.role (which is what is_commissioner() reads, so the new
--    Pro could operate the league) but left the column the rest of the system
--    reads pointing at the old Pro: the phone's League room decides who the
--    Pro is from leagues.commissioner_id (LeagueRoomModel.swift:253), the
--    leagues_create policy binds it, and — the stranding — delete_account
--    hard-deletes every league WHERE commissioner_id = the caller, so an old
--    Pro who handed over the shop and later closed their account would take
--    the league (posts, live rounds, everything) with them. Fix: move the
--    column in the same transaction. Body otherwise identical to prod.
--
-- 2. finish_live_round() stamped rounds.played_on = current_date, which is
--    UTC on the server. A Saturday-evening finish in Phoenix (after 17:00
--    MST) was recorded as Sunday — outside the Ryder session window and, at
--    a month edge, in the wrong cap/floor month. Fix: the league's own
--    calendar day, `(now() at time zone seasons.timezone)::date`, defaulting
--    to America/Phoenix per CLAUDE.md. Body otherwise identical to prod
--    (20260729120000 + the D85/D92 layers), only that one expression moves.
--    Guest cards never insert a round (they carry guest_strokes on the seat
--    until claim_round, which stamps its own date), so the guest trio is
--    untouched.
--
-- Not a mechanic change: neither function's rule changes, both now record
-- what they already claimed to. D37: explicit grants restated (CREATE OR
-- REPLACE preserves ACLs, but the discipline is per-file).
-- ============================================================================

-- ---- 1 · transfer_pro moves commissioner_id --------------------------------
create or replace function public.transfer_pro(p_member uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_league uuid; v_name text; v_me uuid; v_new_profile uuid;
begin
  select league_id, profile_id into v_league, v_new_profile
    from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro hands over the shop'; end if;
  v_me := my_member_id(v_league);
  if p_member = v_me then raise exception 'You already run the shop'; end if;
  if v_new_profile is null then raise exception 'That member has no golfer profile'; end if;

  update league_members set role = 'commissioner' where id = p_member;
  update league_members set role = 'player' where id = v_me;
  -- the column the phone, the create policy and delete_account all read
  update leagues set commissioner_id = v_new_profile where id = v_league;

  select upper(coalesce(p.display_name, 'A MEMBER')) into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, p_member, 'transfer_pro', jsonb_build_object('from', v_me, 'to', p_member));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', v_me, 'THE PRO ROLE PASSES TO ' || v_name);
end $$;
revoke all on function public.transfer_pro(uuid) from public, anon;
grant execute on function public.transfer_pro(uuid) to authenticated;

-- ---- 2 · finish_live_round stamps the league's calendar day ---------------
create or replace function public.finish_live_round(
  p_live_round uuid, p_cards jsonb, p_casual boolean default false, p_result jsonb default null)
returns jsonb
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
  v_tz text; v_today date;
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

  -- the league's own calendar day, not the server's UTC one
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
end $$;
revoke all on function public.finish_live_round(uuid, jsonb, boolean, jsonb) from public, anon;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;
