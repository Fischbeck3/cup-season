-- ============================================================================
-- Cup Season — routing payloads for the two older push_nudges inserters
-- (push wave 7 follow-up; contract docs/ios/push-contract.md §1/§2/§5).
--
-- 20260827210000 taught push_nudges to ROUTE (`kind` + `payload`) and gave the
-- new inserters (invite / request / rsvp) their ids. Two older inserters
-- predate it and still write a title and a body only, so their pushes land
-- Home instead of on the screen they are about:
--
--   1. start_live_round (D86/D88 — "put you on the tee sheet"): the phone
--      needs live_round_id + league_id to open the live round.
--   2. round_duel_nudge (Ryder slice 3 — the opt-in taunt): the phone needs
--      event_id to open the event room.
--
-- Each body below is the CURRENT definition copied verbatim (latest migration
-- wins — cited per function) with ONLY the insert extended: kind='nudge' and
-- the payload the contract names. Copy, recipients and every other line are
-- untouched. No scoring or mechanic change. D37: explicit grants, re-stated.
-- ============================================================================

-- ---- 1. start_live_round: the tee-sheet nudge learns where it points -------
-- Body = 20260728220000_visitor_rounds.sql (D88; the latest), verbatim, plus
-- kind + payload on the push_nudges insert.
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
  -- wave 7 · routed: the phone opens THIS live round (contract §2, `nudge`)
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
end $$;
revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) to authenticated;

-- ---- 2. round_duel_nudge: the taunt learns which event it is about ---------
-- Body = 20260716160000_ryder_slice3.sql (the only definition), verbatim, plus
-- `du.event_id` read in the loop's select and kind + payload on the insert.
-- The trigger (round_duel_nudge_trg, after insert on rounds) is unchanged;
-- `create or replace` keeps it bound. A trigger function is never called by a
-- client, so it carried no grant — the revoke below only closes the PUBLIC
-- execute a pre-D37 function may still hold (CLAUDE.md landmines).
create or replace function public.round_duel_nudge() returns trigger
language plpgsql security definer set search_path = public as $$
declare d record; v_best numeric; v_name text;
begin
  if new.voided or coalesce(new.source,'app') = 'sim'
     or new.index_at_post is null or new.differential is null then
    return new;
  end if;
  for d in
    select du.id, du.event_id, s.opens_on, s.closes_on, s.closes_on - current_date as days_left,
           e.name as ename, e.allowance,
           case when ea.profile_id = new.profile_id then eb.profile_id else ea.profile_id end as opp_profile,
           case when ea.profile_id = new.profile_id then eb.notify_target else ea.notify_target end as opp_wants,
           case when ea.profile_id = new.profile_id then ea.profile_id else eb.profile_id end as me_profile
      from event_duels du
      join event_sessions s on s.id = du.session_id and s.status = 'open'
      join events e on e.id = du.event_id and e.status = 'live'
      join event_players ea on ea.id = du.a_player
      join event_players eb on eb.id = du.b_player
     where du.result = 'pending'
       and new.played_on between s.opens_on and s.closes_on
       and (ea.profile_id = new.profile_id or eb.profile_id = new.profile_id)
  loop
    if not d.opp_wants then continue; end if;
    -- the standing target = the poster's BEST in the window (this round or better)
    select max((r.index_at_post * d.allowance / 100.0) - r.differential) into v_best
      from rounds r
     where r.profile_id = new.profile_id
       and r.played_on between d.opens_on and d.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null;
    select display_name into v_name from profiles where id = new.profile_id;
    -- wave 7 · routed: the phone opens the event room (contract §2, `nudge`)
    insert into push_nudges (profile_id, kind, title, body, payload)
    values (d.opp_profile, 'nudge', d.ename,
      coalesce(v_name,'Your opponent') || ' posted — '
      || (case when v_best >= 0 then '+' else '' end) || round(v_best,1) || ' to beat · '
      || case when d.days_left <= 0 then 'closes tonight'
              else d.days_left || ' day' || case when d.days_left = 1 then '' else 's' end || ' left' end,
      jsonb_build_object('event_id', d.event_id));
  end loop;
  return new;
end $$;
revoke all on function public.round_duel_nudge() from public, anon;
