-- ============================================================================
-- Cup Season — D85: everyone's phone scores the live round (sync v2)
--
-- The tee sheet was one scorekeeper phone (gameplay-modes flag #16, deliberate
-- v1). This gives every player — member or guest — a live pencil:
--
--   live_scores        — durable per-cell strokes DURING the round. Until now
--                        scores lived only in the scorekeeper's localStorage;
--                        multi-phone needs a server truth. LWW by the writer's
--                        clock (client_ts): offline phones flush stale queues,
--                        and the newest edit of a cell must win regardless of
--                        arrival order.
--   live_rounds.join_code  — unguessable name for the round's broadcast
--                        channel (transport is Realtime broadcast, NOT
--                        postgres_changes: anon guests hold zero relation
--                        privileges by design — D37 — so table change feeds
--                        can never reach them; broadcast + RPC reaches both).
--   live_rounds.game_state — wolf declarations by hole ({"h5":{"v":{...},
--                        "cts":...}}). The only game state not derivable from
--                        scores; match/skins/sunningdale all recompute.
--
--   live_set_score / live_set_wolf / live_state          — member pencil+pull
--   guest_live_state / guest_live_set_score / _set_wolf  — the guest pencil,
--     keyed by the claim_token the guest already holds. Same link that claims
--     the round after: one URL, whole lifecycle. Fail-closed like every anon
--     endpoint (D57/D68 family): token or nothing, and a guest can only touch
--     the one round their token names.
--
--   "Anyone edits anything" is the owner's chosen write model (D85): any
--   player in the round writes any cell of that round — flag #16's catch-up
--   rule (a dead phone's card must be enterable by the group) demands it.
--
--   finish_live_round — re-issued with a row LOCK: with several phones live,
--   two could pass the status check together and double-post every card. The
--   `for update` serializes them; the loser sees 'final' and gets already_final.
--
-- No table grants move: live_scores has RLS on and NO policies — RPC-only.
-- ============================================================================

create table if not exists public.live_scores (
  live_round_id uuid not null references public.live_rounds(id) on delete cascade,
  player_id     uuid not null references public.live_round_players(id) on delete cascade,
  hole          smallint not null check (hole between 1 and 18),
  strokes       smallint check (strokes is null or strokes between 1 and 30),
  client_ts     timestamptz not null,
  updated_at    timestamptz not null default now(),
  updated_by    uuid references public.league_members(id),
  primary key (live_round_id, player_id, hole)
);
alter table public.live_scores enable row level security;
-- no policies, no grants: every read/write goes through the RPCs below

alter table public.live_rounds add column if not exists join_code text;
alter table public.live_rounds add column if not exists game_state jsonb;

-- ---- start_live_round: mint + return the channel key ------------------------
-- Body = 20260716130000 (latest); adds join_code. Old clients ignore the extra
-- return key; new clients on an old DB drop nothing (same args) — skew-safe.
create or replace function public.start_live_round(
  p_league uuid, p_course_id uuid, p_tee_id uuid, p_course_label text,
  p_snapshot jsonb, p_game text, p_players jsonb, p_config jsonb default '{}'
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  v_member uuid; v_season uuid; v_lr uuid; v_pos int := 0; v_el jsonb;
  v_code text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
begin
  if v is null then raise exception 'Sign in first'; end if;
  select id into v_member from league_members where league_id = p_league and profile_id = v;
  if v_member is null then raise exception 'You are not in this league'; end if;
  select id into v_season from seasons
   where league_id = p_league and status in ('active','cup_final')
   order by starts_on desc limit 1;
  if v_season is null then raise exception 'No active season to post into'; end if;

  insert into live_rounds (league_id, season_id, course_id, tee_id, course_label,
                           course_snapshot, game, game_config, status, started_by, join_code)
  values (p_league, v_season, p_course_id, p_tee_id,
          coalesce(nullif(trim(p_course_label), ''), 'Course'),
          coalesce(p_snapshot, '{}'::jsonb),
          coalesce(nullif(p_game, ''), 'none'),
          coalesce(p_config, '{}'::jsonb), 'live', v_member, v_code)
  returning id into v_lr;

  for v_el in select * from jsonb_array_elements(coalesce(p_players, '[]'::jsonb)) loop
    if (v_el->>'member_id') is not null and not exists (
      select 1 from league_members
       where id = (v_el->>'member_id')::uuid and league_id = p_league) then
      raise exception 'A tagged player is not in this league';
    end if;
    insert into live_round_players (live_round_id, member_id, guest_name, guest_index, index_source, position)
    values (
      v_lr,
      nullif(v_el->>'member_id','')::uuid,
      nullif(trim(coalesce(v_el->>'guest_name','')), ''),
      nullif(v_el->>'guest_index','')::numeric,
      case when (v_el->>'member_id') is not null then 'member'
           when (v_el->>'guest_index') is not null then 'self' else 'estimated' end,
      v_pos);
    v_pos := v_pos + 1;
  end loop;

  return jsonb_build_object('live_round_id', v_lr, 'join_code', v_code, 'players', (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', id, 'member_id', member_id, 'guest_name', guest_name,
             'claim_token', claim_token, 'position', position) order by position), '[]'::jsonb)
      from live_round_players where live_round_id = v_lr));
end $$;
revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) to authenticated;

-- ---- the shared guards ------------------------------------------------------
-- caller (member) may touch the round: they are a player in it, or its starter
create or replace function public._live_member_can(p_live_round uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from live_rounds lr
     where lr.id = p_live_round
       and ( exists (select 1 from live_round_players p
                       join league_members m on m.id = p.member_id
                      where p.live_round_id = lr.id and m.profile_id = auth.uid())
             or exists (select 1 from league_members m
                         where m.id = lr.started_by and m.profile_id = auth.uid()) ));
$$;
revoke all on function public._live_member_can(uuid) from public, anon, authenticated;
-- helper runs only inside the definer functions below; nobody calls it directly

-- ---- the member pencil ------------------------------------------------------
create or replace function public.live_set_score(
  p_live_round uuid, p_player uuid, p_hole int, p_strokes int, p_client_ts timestamptz
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid(); v_by uuid;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if not _live_member_can(p_live_round) then raise exception 'You are not in this round'; end if;
  if not exists (select 1 from live_rounds where id = p_live_round and status = 'live') then
    raise exception 'Round is not live';
  end if;
  if not exists (select 1 from live_round_players where id = p_player and live_round_id = p_live_round) then
    raise exception 'No such player in this round';
  end if;
  select m.id into v_by
    from live_rounds lr join league_members m on m.league_id = lr.league_id and m.profile_id = v
   where lr.id = p_live_round;
  insert into live_scores (live_round_id, player_id, hole, strokes, client_ts, updated_by)
  values (p_live_round, p_player, p_hole, p_strokes, coalesce(p_client_ts, now()), v_by)
  on conflict (live_round_id, player_id, hole) do update
    set strokes = excluded.strokes, client_ts = excluded.client_ts,
        updated_at = now(), updated_by = excluded.updated_by
    where excluded.client_ts > live_scores.client_ts;   -- LWW: older queue flushes never clobber
end $$;
revoke all on function public.live_set_score(uuid, uuid, int, int, timestamptz) from public, anon;
grant execute on function public.live_set_score(uuid, uuid, int, int, timestamptz) to authenticated;

create or replace function public.live_set_wolf(
  p_live_round uuid, p_hole int, p_wolf jsonb, p_client_ts timestamptz
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid(); k text := 'h' || p_hole; cur jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if not _live_member_can(p_live_round) then raise exception 'You are not in this round'; end if;
  select game_state->k into cur from live_rounds where id = p_live_round and status = 'live';
  if not found then raise exception 'Round is not live'; end if;
  if cur is not null and (cur->>'cts')::timestamptz >= coalesce(p_client_ts, now()) then
    return;   -- LWW: a newer declaration already landed
  end if;
  update live_rounds
     set game_state = jsonb_set(coalesce(game_state, '{}'::jsonb), array[k],
           jsonb_build_object('v', p_wolf, 'cts', coalesce(p_client_ts, now())))
   where id = p_live_round;
end $$;
revoke all on function public.live_set_wolf(uuid, int, jsonb, timestamptz) from public, anon;
grant execute on function public.live_set_wolf(uuid, int, jsonb, timestamptz) to authenticated;

-- ---- the reconcile pull -----------------------------------------------------
-- One payload with everything a rejoining phone needs. Members read the round
-- row itself via RLS already; this exists so reconcile is ONE call and the
-- shape matches the guest pull exactly (one client merge path).
create or replace function public._live_state_of(p_live_round uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'round', (select jsonb_build_object(
        'id', lr.id, 'league_id', lr.league_id, 'status', lr.status,
        'game', lr.game, 'game_config', lr.game_config, 'game_state', lr.game_state,
        'course_snapshot', lr.course_snapshot, 'course_label', lr.course_label,
        'join_code', lr.join_code, 'started_at', lr.started_at)
      from live_rounds lr where lr.id = p_live_round),
    'players', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', p.id, 'member_id', p.member_id, 'guest_name', p.guest_name,
        'guest_index', p.guest_index, 'index_source', p.index_source,
        'position', p.position,
        'display_name', pr.display_name, 'index_current', pr.index_current
      ) order by p.position), '[]'::jsonb)
      from live_round_players p
      left join league_members m on m.id = p.member_id
      left join profiles pr on pr.id = m.profile_id
      where p.live_round_id = p_live_round),
    'scores', (select coalesce(jsonb_agg(jsonb_build_object(
        'player_id', s.player_id, 'hole', s.hole, 'strokes', s.strokes,
        'cts', extract(epoch from s.client_ts) * 1000)), '[]'::jsonb)
      from live_scores s where s.live_round_id = p_live_round));
$$;
-- UNGUARDED by design (its callers guard) — so no API role may ever reach it
revoke all on function public._live_state_of(uuid) from public, anon, authenticated;

create or replace function public.live_state(p_live_round uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if not _live_member_can(p_live_round) then raise exception 'You are not in this round'; end if;
  return _live_state_of(p_live_round);
end $$;
revoke all on function public.live_state(uuid) from public, anon;
grant execute on function public.live_state(uuid) to authenticated;

-- ---- the guest pencil (anon, token-keyed, fail-closed) ----------------------
create or replace function public.guest_live_state(p_token uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_pl live_round_players%rowtype;
begin
  select * into v_pl from live_round_players where claim_token = p_token;
  if v_pl.id is null then raise exception 'No such round'; end if;
  return _live_state_of(v_pl.live_round_id) || jsonb_build_object('me', v_pl.id);
end $$;
revoke all on function public.guest_live_state(uuid) from public;
grant execute on function public.guest_live_state(uuid) to anon, authenticated;

create or replace function public.guest_live_set_score(
  p_token uuid, p_player uuid, p_hole int, p_strokes int, p_client_ts timestamptz
) returns void
language plpgsql security definer set search_path = public as $$
declare v_lr uuid;
begin
  select live_round_id into v_lr from live_round_players where claim_token = p_token;
  if v_lr is null then raise exception 'No such round'; end if;
  if not exists (select 1 from live_rounds where id = v_lr and status = 'live') then
    raise exception 'Round is not live';
  end if;
  if not exists (select 1 from live_round_players where id = p_player and live_round_id = v_lr) then
    raise exception 'No such player in this round';
  end if;
  insert into live_scores (live_round_id, player_id, hole, strokes, client_ts, updated_by)
  values (v_lr, p_player, p_hole, p_strokes, coalesce(p_client_ts, now()), null)
  on conflict (live_round_id, player_id, hole) do update
    set strokes = excluded.strokes, client_ts = excluded.client_ts,
        updated_at = now(), updated_by = null
    where excluded.client_ts > live_scores.client_ts;
end $$;
revoke all on function public.guest_live_set_score(uuid, uuid, int, int, timestamptz) from public;
grant execute on function public.guest_live_set_score(uuid, uuid, int, int, timestamptz) to anon, authenticated;

create or replace function public.guest_live_set_wolf(
  p_token uuid, p_hole int, p_wolf jsonb, p_client_ts timestamptz
) returns void
language plpgsql security definer set search_path = public as $$
declare v_lr uuid; k text := 'h' || p_hole; cur jsonb;
begin
  select live_round_id into v_lr from live_round_players where claim_token = p_token;
  if v_lr is null then raise exception 'No such round'; end if;
  select game_state->k into cur from live_rounds where id = v_lr and status = 'live';
  if not found then raise exception 'Round is not live'; end if;
  if cur is not null and (cur->>'cts')::timestamptz >= coalesce(p_client_ts, now()) then
    return;
  end if;
  update live_rounds
     set game_state = jsonb_set(coalesce(game_state, '{}'::jsonb), array[k],
           jsonb_build_object('v', p_wolf, 'cts', coalesce(p_client_ts, now())))
   where id = v_lr;
end $$;
revoke all on function public.guest_live_set_wolf(uuid, int, jsonb, timestamptz) from public;
grant execute on function public.guest_live_set_wolf(uuid, int, jsonb, timestamptz) to anon, authenticated;

-- ---- finish_live_round: the row lock ---------------------------------------
-- Body = 20260725220000 (latest) with ONE change: `for update` on the round
-- read. Several phones can now finish; the lock makes the race single-file.
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
