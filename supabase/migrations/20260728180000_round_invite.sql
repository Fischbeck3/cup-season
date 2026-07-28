-- ============================================================================
-- Cup Season — D86: the tee sheet calls you to it
--
-- D85 gave every player a pencil and no doorbell. start_live_round wrote its
-- two tables and returned, so a phone already open when the group teed off
-- received nothing at all, and the "Continue your round" banner only appeared
-- on a cold boot (rehydrateLiveRound has exactly one call site: enterLeague).
--
-- Server half of the fix — the POCKET signal:
--   start_live_round inserts one push_nudges row per MEMBER player except the
--   starter. push_nudges is the existing per-recipient push path (the Ryder
--   taunt, 20260716160000): one row = one push to one profile, via the second
--   Database Webhook. A `posts` row was REJECTED for this job — posts fan push
--   league-wide, so eight people who aren't playing would be woken to hear
--   that four people teed off ("only meaningful ones, no spam").
--   The in-app half is client-side (a broadcast on the league channel) and
--   needs no schema.
--
-- Also here, both found by tracing the D85 join path on 2026-07-28:
--
--   1. GUEST RPC TOKEN GUARD. The D85 guest functions key on claim_token
--      ALONE, while the older claim funnel (20260716140000) keys on
--      `claim_token and member_id is null` — and the baseline DEFAULTS a
--      claim_token onto every live_round_players row, members included. No
--      member token reaches any surface today (the tee-off client stores
--      tokens only for rows carrying a guest_name, and the finish receipt
--      lists guests only), so nothing was exposed — but a member's row must
--      never be openable as a guest pencil. Guard added; the guest functions
--      now describe exactly what they are for.
--
--   2. A dead round's token stays usable for its intended job. Unrelated to
--      grants: see the client fix in the same commit (claimPendingRound used
--      to DELETE cs_claim when claim_round refused a still-live round, which
--      permanently orphaned the card of a guest who signed up mid-round).
--      Recorded here so the two halves are findable together.
-- ============================================================================

-- ---- start_live_round: + the roster's invitations ---------------------------
-- Body = 20260728120000 (D85, join_code) with the push_nudges fan-out appended.
create or replace function public.start_live_round(
  p_league uuid, p_course_id uuid, p_tee_id uuid, p_course_label text,
  p_snapshot jsonb, p_game text, p_players jsonb, p_config jsonb default '{}'
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  v_member uuid; v_season uuid; v_lr uuid; v_pos int := 0; v_el jsonb;
  v_code text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  v_who text; v_where text; v_title text; v_body text;
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

  -- D86 · the invitation. One row per member player except the starter; the
  -- push webhook on push_nudges turns each into exactly one notification.
  -- First name only (a lock screen is short, and the group knows each other).
  select split_part(coalesce(playerlabel(v), 'Someone'), ' ', 1) into v_who;
  v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');
  v_title := v_who || ' put you on the tee sheet';
  v_body  := 'Live round at ' || v_where || ' — open the app to score it with them';
  insert into push_nudges (profile_id, title, body)
  select m.profile_id, v_title, v_body
    from live_round_players p
    join league_members m on m.id = p.member_id
   where p.live_round_id = v_lr
     and p.member_id is not null
     and m.profile_id is distinct from v;   -- never ping the starter

  return jsonb_build_object('live_round_id', v_lr, 'join_code', v_code, 'players', (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', id, 'member_id', member_id, 'guest_name', guest_name,
             'claim_token', claim_token, 'position', position) order by position), '[]'::jsonb)
      from live_round_players where live_round_id = v_lr));
end $$;
revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) to authenticated;

-- ---- the guest pencil: a GUEST row's token, never a member's ----------------
-- `and member_id is null` matches the older funnel (20260716140000) exactly.
-- A member joins by identity (live_* RPCs, _live_member_can); a token is the
-- guest's whole authorization, so it must only ever name a guest.
create or replace function public.guest_live_state(p_token uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_pl live_round_players%rowtype;
begin
  select * into v_pl from live_round_players
   where claim_token = p_token and member_id is null;
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
  select live_round_id into v_lr from live_round_players
   where claim_token = p_token and member_id is null;
  if v_lr is null then raise exception 'No such round'; end if;
  if not exists (select 1 from live_rounds where id = v_lr and status = 'live') then
    raise exception 'Round is not live';
  end if;
  if not exists (select 1 from live_round_players where id = p_player and live_round_id = v_lr) then
    raise exception 'No such player in this round';
  end if;
  if p_strokes is null then
    delete from live_scores
     where player_id = p_player and hole_number = p_hole
       and (client_ts is null or client_ts < coalesce(p_client_ts, now()));
    return;
  end if;
  insert into live_scores (live_round_id, player_id, hole_number, strokes, client_ts, updated_by)
  values (v_lr, p_player, p_hole,
          least(greatest(p_strokes, 1), 15),
          coalesce(p_client_ts, now()), null)
  on conflict (player_id, hole_number) do update
    set strokes = excluded.strokes, client_ts = excluded.client_ts,
        updated_at = now(), updated_by = null
    where live_scores.client_ts is null
       or excluded.client_ts > live_scores.client_ts;
end $$;
revoke all on function public.guest_live_set_score(uuid, uuid, int, int, timestamptz) from public;
grant execute on function public.guest_live_set_score(uuid, uuid, int, int, timestamptz) to anon, authenticated;

create or replace function public.guest_live_set_wolf(
  p_token uuid, p_hole int, p_wolf jsonb, p_client_ts timestamptz
) returns void
language plpgsql security definer set search_path = public as $$
declare v_lr uuid; k text := 'h' || p_hole; cur jsonb;
begin
  select live_round_id into v_lr from live_round_players
   where claim_token = p_token and member_id is null;
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
