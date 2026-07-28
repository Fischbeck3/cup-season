-- ============================================================================
-- Cup Season — D88: the visitor gets a doorbell and a door
--
-- A golfer who HAS the app but is not in your league rides the tee sheet as a
-- guest row (start_live_round rejects a member_id from another league). D87
-- gave them a pencil via their claim link; this gives them what a member has:
--
--   1. THE APP KNOWS WHO THEY ARE. The tee-off client already knows the
--      profile it searched up (#rosterFind stores pid) but DROPPED it when
--      building p_players — the server only ever saw a name. live_round_players
--      gains guest_profile_id, so a guest can be a known golfer rather than a
--      string.
--   2. A DOORBELL. The push_nudges fan-out (D86) now includes them. Nothing to
--      deploy: push_nudges already delivers one row to one profile, and the
--      service worker opens the app on tap.
--   3. A DOOR. RLS on live_rounds is is_league_member(league_id), so a visitor
--      literally cannot SELECT the round — the claim link was their only way
--      in, and a push that leads nowhere is worse than no push. my_visitor_rounds()
--      is a definer read that hands back exactly the rounds where they are a
--      known guest, in the shape the client's own resume query returns.
--   4. IDENTITY, NOT A TOKEN. _live_member_can accepts a guest_profile_id
--      match, so a signed-in visitor scores through the ordinary live_* RPCs.
--      The token stays valid (D87's path still works, and an account-less
--      guest still has nothing else) — but a link is no longer REQUIRED for
--      someone the app can recognise.
--
-- Deliberately unchanged: finish_live_round still admits only the starter or a
-- MEMBER player. A visitor scores the round; they do not end it, and their card
-- still posts to their own profile through the claim (which is what makes it
-- count in THEIR league — rounds belong to profiles, leagues are lenses).
-- ============================================================================

alter table public.live_round_players
  add column if not exists guest_profile_id uuid references public.profiles(id);

-- a visitor's round lookup is by profile; the finish/claim paths still scan by
-- token and by round, so this is the one index the new read needs
create index if not exists live_round_players_guest_profile_idx
  on public.live_round_players (guest_profile_id) where guest_profile_id is not null;

-- ---- start_live_round: remember WHO the guest is, and ring them -------------
-- Body = 20260728180000 (D86) + guest_profile passthrough + a wider nudge fan.
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

  -- D86/D88 · the invitation. Members by member_id, visitors by
  -- guest_profile_id; never the starter, never an account-less guest (there is
  -- no one to notify — they have a name and nothing else).
  select split_part(coalesce(playerlabel(v), 'Someone'), ' ', 1) into v_who;
  v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');
  v_title := v_who || ' put you on the tee sheet';
  v_body  := 'Live round at ' || v_where || ' — open the app to score it with them';
  insert into push_nudges (profile_id, title, body)
  select distinct pr, v_title, v_body from (
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
end $$;
revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) to authenticated;

-- ---- the pencil guard learns the visitor ------------------------------------
-- Identity, not a token: a known guest scores through the ordinary live_* RPCs.
create or replace function public._live_member_can(p_live_round uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from live_rounds lr
     where lr.id = p_live_round
       and ( exists (select 1 from live_round_players p
                       join league_members m on m.id = p.member_id
                      where p.live_round_id = lr.id and m.profile_id = auth.uid())
             or exists (select 1 from live_round_players p          -- D88: the visitor
                         where p.live_round_id = lr.id and p.guest_profile_id = auth.uid())
             or exists (select 1 from league_members m
                         where m.id = lr.started_by and m.profile_id = auth.uid()) ));
$$;
revoke all on function public._live_member_can(uuid) from public, anon, authenticated;

-- ---- the door: rounds I am a KNOWN GUEST in ---------------------------------
-- RLS on live_rounds is is_league_member(league_id), so a visitor cannot see
-- the row through the client's own resume query. This definer read hands back
-- exactly their rounds, in the shape applyServerRound already consumes.
create or replace function public.my_visitor_rounds()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(r order by r->>'started_at' desc), '[]'::jsonb) from (
    select jsonb_build_object(
      'id', lr.id, 'league_id', lr.league_id, 'game', lr.game,
      'game_config', lr.game_config, 'join_code', lr.join_code,
      'started_by', lr.started_by, 'course_snapshot', lr.course_snapshot,
      'course_label', lr.course_label, 'started_at', lr.started_at,
      'visitor', true,
      'live_round_players', (
        select coalesce(jsonb_agg(jsonb_build_object(
            'id', p.id, 'member_id', p.member_id, 'guest_name', p.guest_name,
            'guest_index', p.guest_index, 'index_source', p.index_source,
            'position', p.position, 'guest_profile_id', p.guest_profile_id,
            'member', case when p.member_id is null then null else jsonb_build_object(
              'profile_id', m.profile_id,
              'profile', jsonb_build_object('display_name', pr.display_name,
                                            'index_current', pr.index_current)) end
          ) order by p.position), '[]'::jsonb)
          from live_round_players p
          left join league_members m on m.id = p.member_id
          left join profiles pr on pr.id = m.profile_id
         where p.live_round_id = lr.id)
    ) as r
    from live_rounds lr
    where lr.status = 'live'
      and exists (select 1 from live_round_players p
                   where p.live_round_id = lr.id and p.guest_profile_id = auth.uid())
    order by lr.started_at desc
  ) x;
$$;
revoke all on function public.my_visitor_rounds() from public, anon;
grant execute on function public.my_visitor_rounds() to authenticated;
