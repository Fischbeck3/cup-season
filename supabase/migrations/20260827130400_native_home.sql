-- ============================================================================
-- IOS-009 batch 1 (docs/ios/DECISIONS.md) · item 8 — native_home()
--
-- The phone's one-round-trip bootstrap (audit 07 G4). The web assembles Home
-- from ~10 reads; a cold start on a phone should not replay that fan-out.
-- This function does not re-derive a single rule — every number comes from
-- the function or view that already owns it:
--
--   profile ........ profiles (+ handicap_index() for the engine's number)
--   memberships .... league_members × leagues × league_settings × seasons ×
--                    squads/squad_members; standing from v_squad_standings
--                    (solo: v_individual_standings); prev_rank from the latest
--                    standings_snapshots row (shape written by snapshot_week:
--                    {"squads":[{season_id,squad_id,points}…],
--                     "individuals":[{member_id,season_id,points,rounds_posted}…]});
--                    pulse = the caller's own league_pulse() row
--   invites ........ my_invites()
--   live_round ..... live_rounds where the caller is seated (league_members)
--                    or started it, ∪ my_visitor_rounds(); most recent wins
--   upcoming_rounds  my_schedule(today, today + 14)
--   events ......... events (setup|live) the caller plays in or organizes
--   open_duels ..... event_duels pending in an OPEN session, with the number
--                    to beat from event_session_targets()
--   flags .......... app_flags 'ios' (20260827130100) and 'scan'
--
-- Shape (every key always present; arrays may be empty; nulls where noted):
--   { profile: null | {...}, memberships: [...], invites: [...],
--     live_round: null | {...}, upcoming_rounds: [...], events: [...],
--     open_duels: [...], flags: { ios, scan }, generated_at }
--
-- Rules the caller can rely on:
--   * auth.uid() null → raises 'Sign in first' (the only exception).
--   * No profiles row yet → profile: null, every array empty, flags still
--     populated (the build gate must work before the card gate). Never
--     raises: the card gate handles it.
--   * Zero memberships → profile only. Fine.
--   * Each optional sub-read is wrapped so a missing row (or a table this
--     snapshot doesn't know about) yields null / [] rather than an error.
--   * One pass per membership (a golfer has 1–3 leagues); no per-round loops.
--   * The "current" season per membership: an active/cup_final one first,
--     else the latest by starts_on (so a completed league still carries its
--     result for the Trophy Room). null when the league has no season yet.
--   * Standing rank = points desc, then squad name (member display_name for
--     solo). prev_rank uses the same ordering over the snapshot's array.
--   * Solo leagues: squad null, standing keyed by member,
--     leader_member_id set and leader_squad_id null. Squad leagues: the
--     reverse. Both keys are always present.
--   * Memberships are ordered: phase 'season' first, then draft, setup,
--     complete; ties by joined_at desc.
--
-- Additive: no web caller. D37 grant discipline at the bottom.
-- ============================================================================

create or replace function public.native_home()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v            uuid := auth.uid();
  v_today      date := current_date;
  v_profile    jsonb;
  v_members    jsonb := '[]'::jsonb;
  v_invites    jsonb := '[]'::jsonb;
  v_live       jsonb;
  v_live_vis   jsonb;
  v_sched      jsonb := '[]'::jsonb;
  v_events     jsonb := '[]'::jsonb;
  v_duels      jsonb := '[]'::jsonb;
  v_flag_ios   jsonb;
  v_flag_scan  jsonb;
  m            record;      -- one membership per loop
  v_season     jsonb;
  v_season_id  uuid;
  v_solo       boolean;
  v_squad      jsonb;
  v_squad_id   uuid;
  v_standing   jsonb;
  v_prev_rank  integer;
  v_pulse      jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;

  -- ---- flags first: the build gate must answer even before the card gate --
  begin
    select value into v_flag_ios  from app_flags where key = 'ios';
    select value into v_flag_scan from app_flags where key = 'scan';
  exception when others then
    v_flag_ios := null; v_flag_scan := null;
  end;

  -- ---- profile ------------------------------------------------------------
  begin
    select jsonb_build_object(
      'id',            p.id,
      'display_name',  p.display_name,
      'handle',        p.handle,
      'marker',        p.marker,
      'city',          p.city,
      'home_course',   p.home_course,
      'index_current', p.index_current,
      'index_engine',  handicap_index(p.id),
      'index_source',  p.index_source,
      'photo_path',    p.photo_path,
      'rounds_count',  (select count(*)::int from rounds r
                         where r.profile_id = p.id and not r.voided),
      'member_since',  p.created_at,
      'is_founder',    p.is_founder
    ) into v_profile
    from profiles p where p.id = v;
  exception when others then
    v_profile := null;
  end;

  if v_profile is null then
    return jsonb_build_object(
      'profile',         null,
      'memberships',     '[]'::jsonb,
      'invites',         '[]'::jsonb,
      'live_round',      null,
      'upcoming_rounds', '[]'::jsonb,
      'events',          '[]'::jsonb,
      'open_duels',      '[]'::jsonb,
      'flags',           jsonb_build_object('ios', v_flag_ios, 'scan', v_flag_scan),
      'generated_at',    now());
  end if;

  -- ---- memberships: one pass each ----------------------------------------
  for m in
    select lm.id            as member_id,
           lm.role,
           lm.joined_at,
           coalesce(lm.marker, (select marker from profiles where id = v)) as marker,
           l.id             as league_id,
           l.name,
           l.code,
           l.phase,
           l.sandbox,
           (select display_name from profiles where id = l.commissioner_id) as commissioner_name,
           ls.structure, ls.preset, ls.counting_cap, ls.participation_floor,
           ls.floor_penalty, ls.handicap_allowance, ls.buyin_cents,
           ls.payout_champ, ls.payout_runnerup, ls.payout_king, ls.finish, ls.locked_at
      from league_members lm
      join leagues l on l.id = lm.league_id
      left join league_settings ls on ls.league_id = l.id
     where lm.profile_id = v
     order by case l.phase when 'season' then 0 when 'draft' then 1 when 'setup' then 2 else 3 end,
              lm.joined_at desc
  loop
    v_season := null; v_season_id := null; v_squad := null; v_squad_id := null;
    v_standing := null; v_prev_rank := null; v_pulse := null;
    v_solo := (m.structure = 'solo');

    -- the current season: active/cup_final first, else the latest
    begin
      select s.id, jsonb_build_object(
        'id',                    s.id,
        'number',                s.number,
        'starts_on',             s.starts_on,
        'ends_on',               s.ends_on,
        'status',                s.status,
        'timezone',              s.timezone,
        'grace_hours',           s.grace_hours,
        'champion_squad_id',     s.champion_squad_id,
        'champion_member_id',    s.champion_member_id,
        'points_king_member_id', s.points_king_member_id,
        'tiebreak_rung',         s.tiebreak_rung)
      into v_season_id, v_season
      from seasons s
      where s.league_id = m.league_id
      order by (s.status in ('active', 'cup_final')) desc, s.starts_on desc
      limit 1;
    exception when others then
      v_season := null; v_season_id := null;
    end;

    if v_season_id is not null then
      -- the caller's seat
      if not v_solo then
        begin
          select sq.id, jsonb_build_object('id', sq.id, 'name', sq.name, 'color', sq.color)
            into v_squad_id, v_squad
            from squad_members sm
            join squads sq on sq.id = sm.squad_id
           where sm.member_id = m.member_id and sq.season_id = v_season_id
           limit 1;
        exception when others then
          v_squad := null; v_squad_id := null;
        end;
      end if;

      -- standing: squads from v_squad_standings, solo from v_individual_standings
      begin
        if not v_solo and v_squad_id is not null then
          with st as (
            select vs.squad_id, vs.points,
                   rank()       over w as rk,
                   count(*)     over ()  as of_n,
                   first_value(vs.squad_id) over w as leader_id,
                   first_value(vs.points)   over w as leader_pts,
                   lag(vs.points)           over w as next_pts
              from v_squad_standings vs
              join squads sq on sq.id = vs.squad_id
             where vs.season_id = v_season_id
            window w as (order by vs.points desc, sq.name)
          )
          select jsonb_build_object(
            'rank',             st.rk,
            'of',               st.of_n,
            'points',           st.points,
            'leader_squad_id',  st.leader_id,
            'leader_member_id', null,
            'leader_points',    st.leader_pts,
            'gap_to_leader',    st.leader_pts - st.points,
            'gap_to_next',      case when st.next_pts is null then null else st.next_pts - st.points end)
          into v_standing
          from st where st.squad_id = v_squad_id;
        elsif v_solo then
          with st as (
            select vi.member_id, vi.points,
                   rank()       over w as rk,
                   count(*)     over ()  as of_n,
                   first_value(vi.member_id) over w as leader_id,
                   first_value(vi.points)    over w as leader_pts,
                   lag(vi.points)            over w as next_pts
              from v_individual_standings vi
              join league_members lm2 on lm2.id = vi.member_id
              join profiles p2 on p2.id = lm2.profile_id
             where vi.season_id = v_season_id
            window w as (order by vi.points desc, p2.display_name)
          )
          select jsonb_build_object(
            'rank',             st.rk,
            'of',               st.of_n,
            'points',           st.points,
            'leader_squad_id',  null,
            'leader_member_id', st.leader_id,
            'leader_points',    st.leader_pts,
            'gap_to_leader',    st.leader_pts - st.points,
            'gap_to_next',      case when st.next_pts is null then null else st.next_pts - st.points end)
          into v_standing
          from st where st.member_id = m.member_id;
        end if;
      exception when others then
        v_standing := null;
      end;

      -- prev_rank from the latest snapshot (snapshot_week's shape)
      if v_standing is not null then
        begin
          if not v_solo then
            select pr.rk into v_prev_rank from (
              select (e->>'squad_id')::uuid as sid,
                     rank() over (order by (e->>'points')::numeric desc, coalesce(sq.name, '')) as rk
                from standings_snapshots ss
                cross join lateral jsonb_array_elements(ss.standings->'squads') e
                left join squads sq on sq.id = (e->>'squad_id')::uuid
               where ss.id = (select id from standings_snapshots
                               where season_id = v_season_id
                               order by week_no desc, captured_at desc limit 1)
            ) pr where pr.sid = v_squad_id;
          else
            select pr.rk into v_prev_rank from (
              select (e->>'member_id')::uuid as mid,
                     rank() over (order by (e->>'points')::numeric desc, coalesce(p3.display_name, '')) as rk
                from standings_snapshots ss
                cross join lateral jsonb_array_elements(ss.standings->'individuals') e
                left join league_members lm3 on lm3.id = (e->>'member_id')::uuid
                left join profiles p3 on p3.id = lm3.profile_id
               where ss.id = (select id from standings_snapshots
                               where season_id = v_season_id
                               order by week_no desc, captured_at desc limit 1)
            ) pr where pr.mid = m.member_id;
          end if;
        exception when others then
          v_prev_rank := null;
        end;
        v_standing := v_standing || jsonb_build_object('prev_rank', v_prev_rank);
      end if;

      -- the caller's own floor gauge
      begin
        select jsonb_build_object(
          'credits',  lp.credits,
          'floor',    lp.floor,
          'at_floor', lp.at_floor,
          'partial',  lp.partial)
        into v_pulse
        from league_pulse(m.league_id) lp
        where lp.is_me
        limit 1;
      exception when others then
        v_pulse := null;
      end;
    end if;

    v_members := v_members || jsonb_build_object(
      'league_id',         m.league_id,
      'name',              m.name,
      'code',              m.code,
      'phase',             m.phase,
      'sandbox',           m.sandbox,
      'role',              m.role,
      'member_id',         m.member_id,
      'marker',            m.marker,
      'commissioner_name', m.commissioner_name,
      'settings', jsonb_build_object(
        'structure',           m.structure,
        'preset',              m.preset,
        'counting_cap',        m.counting_cap,
        'participation_floor', m.participation_floor,
        'floor_penalty',       m.floor_penalty,
        'handicap_allowance',  m.handicap_allowance,
        'buyin_cents',         m.buyin_cents,
        'payout_champ',        m.payout_champ,
        'payout_runnerup',     m.payout_runnerup,
        'payout_king',         m.payout_king,
        'finish',              m.finish,
        'locked_at',           m.locked_at),
      'season',   v_season,
      'squad',    v_squad,
      'standing', v_standing,
      'pulse',    v_pulse);
  end loop;

  -- ---- invites -------------------------------------------------------------
  begin
    select coalesce(jsonb_agg(to_jsonb(i)), '[]'::jsonb) into v_invites
      from my_invites() i;
  exception when others then
    v_invites := '[]'::jsonb;
  end;

  -- ---- live round to resume: seated as a member (or started it) ----------
  begin
    select jsonb_build_object(
      'id',           lr.id,
      'league_id',    lr.league_id,
      'league_name',  l.name,
      'status',       lr.status,
      'started_at',   lr.started_at,
      'course_label', lr.course_label,
      'game',         lr.game,
      'join_code',    lr.join_code,
      'mine',         exists (select 1 from league_members sm
                               where sm.id = lr.started_by and sm.profile_id = v),
      'visitor',      false)
    into v_live
    from live_rounds lr
    join leagues l on l.id = lr.league_id
    where lr.status in ('setup', 'live')
      and (exists (select 1 from live_round_players lp
                     join league_members mm on mm.id = lp.member_id
                    where lp.live_round_id = lr.id and mm.profile_id = v)
        or exists (select 1 from league_members sm
                    where sm.id = lr.started_by and sm.profile_id = v))
    order by lr.started_at desc
    limit 1;
  exception when others then
    v_live := null;
  end;

  -- ... or as a known visitor (my_visitor_rounds: status 'live' only)
  begin
    select jsonb_build_object(
      'id',           (e->>'id')::uuid,
      'league_id',    (e->>'league_id')::uuid,
      'league_name',  l.name,
      'status',       'live',
      'started_at',   (e->>'started_at')::timestamptz,
      'course_label', e->>'course_label',
      'game',         e->>'game',
      'join_code',    e->>'join_code',
      'mine',         false,
      'visitor',      true)
    into v_live_vis
    from jsonb_array_elements(my_visitor_rounds()) e
    left join leagues l on l.id = (e->>'league_id')::uuid
    order by (e->>'started_at')::timestamptz desc nulls last
    limit 1;
  exception when others then
    v_live_vis := null;
  end;

  if v_live is null then
    v_live := v_live_vis;
  elsif v_live_vis is not null
    and (v_live_vis->>'started_at')::timestamptz > (v_live->>'started_at')::timestamptz then
    v_live := v_live_vis;
  end if;

  -- ---- the tee sheet, two weeks out -----------------------------------------
  begin
    select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb) into v_sched
      from my_schedule(v_today, v_today + 14) s;
  exception when others then
    v_sched := '[]'::jsonb;
  end;

  -- ---- events the caller plays in or organizes (setup | live) ------------
  begin
    select coalesce(jsonb_agg(jsonb_build_object(
        'id',           e.id,
        'name',         e.name,
        'kind',         e.kind,
        'status',       e.status,
        'starts_on',    e.starts_on,
        'league_id',    e.league_id,
        'my_team_slot', (select et.slot
                           from event_players ep
                           join event_teams et on et.id = ep.team_id
                          where ep.event_id = e.id and ep.profile_id = v
                          limit 1),
        'is_organizer', is_event_organizer(e.id)
      ) order by e.starts_on, e.name), '[]'::jsonb)
    into v_events
    from events e
    where e.status in ('setup', 'live')
      and (e.created_by = v
        or exists (select 1 from event_players ep
                    where ep.event_id = e.id and ep.profile_id = v));
  exception when others then
    v_events := '[]'::jsonb;
  end;

  -- ---- open duels: pending, in an open session, with the number to beat ---
  begin
    select coalesce(jsonb_agg(q.x order by (q.x->>'closes_on')::date, q.x->>'event_name'), '[]'::jsonb)
    into v_duels
    from (
      select jsonb_build_object(
        'event_id',   e.id,
        'event_name', e.name,
        'session_id', s.id,
        'session_no', s.session_no,
        'opens_on',   s.opens_on,
        'closes_on',  s.closes_on,
        'opponent',   jsonb_build_object(
                        'profile_id',   op.id,
                        'display_name', op.display_name,
                        'marker',       op.marker),
        'my_pvi',     case when me.id = d.a_player then t.a_pvi else t.b_pvi end,
        'their_pvi',  case when me.id = d.a_player then t.b_pvi else t.a_pvi end) as x
      from event_duels d
      join event_sessions s on s.id = d.session_id and s.status = 'open'
      join events e on e.id = d.event_id
      join event_players me on me.id in (d.a_player, d.b_player) and me.profile_id = v
      join event_players them on them.id = case when me.id = d.a_player then d.b_player else d.a_player end
      join profiles op on op.id = them.profile_id
      left join lateral (
        select t0.a_pvi, t0.b_pvi
          from event_session_targets(s.id) t0
         where t0.duel_id = d.id) t on true
      where d.result = 'pending'
    ) q;
  exception when others then
    v_duels := '[]'::jsonb;
  end;

  return jsonb_build_object(
    'profile',         v_profile,
    'memberships',     v_members,
    'invites',         v_invites,
    'live_round',      v_live,
    'upcoming_rounds', v_sched,
    'events',          v_events,
    'open_duels',      v_duels,
    'flags',           jsonb_build_object('ios', v_flag_ios, 'scan', v_flag_scan),
    'generated_at',    now());
end $$;

revoke all on function public.native_home() from public, anon;
grant execute on function public.native_home() to authenticated;
