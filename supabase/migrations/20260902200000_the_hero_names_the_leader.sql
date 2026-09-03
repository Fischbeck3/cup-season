-- ============================================================================
-- Cup Season — the hero names the leader (native_home() v2)
--
-- Home hard-look, owner's ruling 2026-09-02 ("build to your recommendations"):
-- the hero line reads "10 back of Galen · 9 – 19", and the leader's own line
-- reads "22 clear of Jade". Home says the same first name the board says, so
-- the name comes from public.firstname(text) (20260727160000_board_voice.sql).
-- And every member sees the books — "$150 on the books · $0 collected" (D106
-- vocabulary) — while "You still owe $75" stays self-only (D129 / D23). §16:
-- every figure shows its work, so the pot arrives as its parts, never as a
-- manufactured total.
--
-- BASE: supabase/migrations/20260827130400_native_home.sql. That is the only
-- migration that ever CREATED native_home(); 20260901160000 only mentions it
-- in a comment (grep confirms), and prod's pg_get_functiondef body was diffed
-- byte-identical against that file on 2026-09-02 before this was written. The
-- body below is that definition re-created verbatim plus ONLY the additions
-- listed here. Rule 2: the old file stays untouched; this is the fix file.
--
-- ADDITIONS (every existing key keeps its exact shape; all new keys are
-- OPTIONAL on the client — a phone built against this must still render
-- against a payload that lacks them):
--
--   standing gains
--     leader_name       text|null   solo: firstname(leader's display_name)
--                                   squads: the leading squad's name
--     runner_up_name    text|null   the rank-2 row by the SAME window order
--                                   (points desc, display_name / squad name);
--                                   null when fewer than 2 rows
--     runner_up_points  numeric|null  the rank-2 row's points; null likewise
--       (gap_to_next is null for rank 1 — this is how a leader says
--        "22 clear of Jade" without re-deriving the table)
--
--   membership gains
--     buy_in   null when league_settings.buyin_cents is 0 or null (D70: no
--              dollars on a $0 league), else
--       { paid:            the caller's buy_ins.paid for the current season,
--                          false when there is no row (D23: self-only line),
--         note:            league_settings.buy_in_note (members only —
--                          native_home() is already authenticated + a member),
--         due_on:          league_settings.buy_in_due_on,
--         players:         the number of members the pot is owed by. Mirrors
--                          LeagueRoomModel.potPlayers EXACTLY:
--                          max(members.count, 1) where `members` is every
--                          league_members row of the league — suspension is
--                          not a pot filter (20260902100000: suspend touches
--                          nothing in the pot),
--         paid_count:      roster members whose buy_ins row for the current
--                          season is paid (LeagueRoomModel.paidCount),
--         collected_cents: the sum of those paid rows' amount_cents
--                          (LeagueRoomModel.collectedDollars × 100). This
--                          equals paid_count × buyin_cents whenever every
--                          paid row was marked at the current stake, which is
--                          what mark_buy_in writes; when the Pro changed the
--                          stake after someone paid, the ledger — not the
--                          product — is the truth, and the phone already
--                          shows the ledger. }
--       The client derives "on the books" = players × settings.buyin_cents,
--       "still owe" = players − paid_count, and the self-only line from paid.
--
--     roster   integer   the D207 headcount — league_members with a living
--                        profile and no suspension — the SAME count
--                        open_week_clash writes "It's the two of you" under
--                        (20260902170000). On every membership, whatever the
--                        stake; `buy_in.players` stays the pot's count.
--     members  integer   every league_members row — suspended and tombstoned
--                        included — the number the room's "N players", the
--                        Members sheet and the Pot pane all print. On every
--                        membership, whatever the stake, so a Home line that
--                        counts heads says the room's number (D121 row).
--
--   standing gains, ONLY while season.status = 'cup_final' (D138 / §14.3 —
--   the Final is a field of two and the table keeps moving through it, so
--   the hero must never call `rank` a seed):
--     seed        integer|null  the caller's LOCKED cup_finalists.seed (their
--                               squad's, in a squads league); null for a
--                               non-finalist
--     finalists   jsonb|null    a JSON array of the finalists' names in seed
--                               order, in the board's form (firstname /
--                               squads.name). A tombstoned finalist stays,
--                               as "Former" (the board's word for them); a
--                               solo finalist's row actually deleted drops
--                               out (member_id cascades from league_members)
--                               and the client falls back to the Final's
--                               own sentence.
--
-- Not changed: the window ordering, prev_rank, pulse, invites, live_round,
-- upcoming_rounds, events, open_duels, flags, generated_at — byte for byte.
--
-- D37 grant discipline at the bottom; a read-only self-check asserts the new
-- keys are in the stored definition. The function is never CALLED here — it
-- depends on auth.uid() and a migration runs as postgres.
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
  v_buy_in     jsonb;      -- v2: the books, as parts (null on a $0 league)
  v_roster     integer;    -- v2: the D207 headcount
  v_all        integer;    -- v2: every league_members row — the room's "N players"
  v_final      jsonb;      -- v2: the Final's field (seed + finalists), or null
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
           ls.payout_champ, ls.payout_runnerup, ls.payout_king, ls.finish, ls.locked_at,
           ls.buy_in_note, ls.buy_in_due_on
      from league_members lm
      join leagues l on l.id = lm.league_id
      left join league_settings ls on ls.league_id = l.id
     where lm.profile_id = v
     order by case l.phase when 'season' then 0 when 'draft' then 1 when 'setup' then 2 else 3 end,
              lm.joined_at desc
  loop
    v_season := null; v_season_id := null; v_squad := null; v_squad_id := null;
    v_standing := null; v_prev_rank := null; v_pulse := null; v_buy_in := null;
    v_roster := null; v_all := null; v_final := null;
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
                   lag(vs.points)           over w as next_pts,
                   -- v2: the names the hero speaks (same order as the rank)
                   first_value(sq.name)     over w  as leader_name,
                   nth_value(sq.name, 2)    over w2 as runner_up_name,
                   nth_value(vs.points, 2)  over w2 as runner_up_pts
              from v_squad_standings vs
              join squads sq on sq.id = vs.squad_id
             where vs.season_id = v_season_id
            window w  as (order by vs.points desc, sq.name),
                   w2 as (w rows between unbounded preceding and unbounded following)
          )
          select jsonb_build_object(
            'rank',             st.rk,
            'of',               st.of_n,
            'points',           st.points,
            'leader_squad_id',  st.leader_id,
            'leader_member_id', null,
            'leader_points',    st.leader_pts,
            'gap_to_leader',    st.leader_pts - st.points,
            'gap_to_next',      case when st.next_pts is null then null else st.next_pts - st.points end,
            'leader_name',      st.leader_name,
            'runner_up_name',   st.runner_up_name,
            'runner_up_points', st.runner_up_pts)
          into v_standing
          from st where st.squad_id = v_squad_id;
        elsif v_solo then
          with st as (
            select vi.member_id, vi.points,
                   rank()       over w as rk,
                   count(*)     over ()  as of_n,
                   first_value(vi.member_id) over w as leader_id,
                   first_value(vi.points)    over w as leader_pts,
                   lag(vi.points)            over w as next_pts,
                   -- v2: the names the hero speaks (same order as the rank)
                   first_value(p2.display_name)    over w  as leader_raw,
                   nth_value(p2.display_name, 2)   over w2 as runner_up_raw,
                   nth_value(vi.points, 2)         over w2 as runner_up_pts
              from v_individual_standings vi
              join league_members lm2 on lm2.id = vi.member_id
              join profiles p2 on p2.id = lm2.profile_id
             where vi.season_id = v_season_id
            window w  as (order by vi.points desc, p2.display_name),
                   w2 as (w rows between unbounded preceding and unbounded following)
          )
          select jsonb_build_object(
            'rank',             st.rk,
            'of',               st.of_n,
            'points',           st.points,
            'leader_squad_id',  null,
            'leader_member_id', st.leader_id,
            'leader_points',    st.leader_pts,
            'gap_to_leader',    st.leader_pts - st.points,
            'gap_to_next',      case when st.next_pts is null then null else st.next_pts - st.points end,
            -- first names, the board's way: firstname() is what the board
            -- voice uses, so Home says "Galen" exactly like the board does.
            -- firstname(null) is 'Someone', so a missing rank-2 stays null.
            'leader_name',      case when st.leader_raw    is null then null else firstname(st.leader_raw)    end,
            'runner_up_name',   case when st.runner_up_raw is null then null else firstname(st.runner_up_raw) end,
            'runner_up_points', st.runner_up_pts)
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

      -- v2: the Final's field (D138). The seed is the locked row or nothing —
      -- `rank` above is the live table, which keeps moving through the Final.
      if v_standing is not null and (v_season->>'status') = 'cup_final' then
        begin
          if v_solo then
            select jsonb_build_object(
              'seed',      (select cf.seed from cup_finalists cf
                             where cf.season_id = v_season_id and cf.member_id = m.member_id),
              'finalists', (select jsonb_agg(firstname(p4.display_name) order by cf.seed)
                              from cup_finalists cf
                              join league_members lm4 on lm4.id = cf.member_id
                              join profiles p4 on p4.id = lm4.profile_id
                             where cf.season_id = v_season_id))
            into v_final;
          else
            select jsonb_build_object(
              'seed',      (select cf.seed from cup_finalists cf
                             where cf.season_id = v_season_id and cf.squad_id = v_squad_id),
              'finalists', (select jsonb_agg(sq4.name order by cf.seed)
                              from cup_finalists cf
                              join squads sq4 on sq4.id = cf.squad_id
                             where cf.season_id = v_season_id))
            into v_final;
          end if;
        exception when others then
          v_final := null;
        end;
        if v_final is not null then v_standing := v_standing || v_final; end if;
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

    -- v2: the books, as parts (D106). null on a $0 league (D70). The roster
    -- is every league_members row — LeagueRoomModel.potPlayers, exactly.
    if coalesce(m.buyin_cents, 0) > 0 then
      begin
        select jsonb_build_object(
          'paid',            coalesce((select bi.paid from buy_ins bi
                                        where bi.season_id = v_season_id
                                          and bi.member_id = m.member_id), false),
          'note',            m.buy_in_note,
          'due_on',          m.buy_in_due_on,
          'players',         greatest((select count(*)::int from league_members r
                                        where r.league_id = m.league_id), 1),
          'paid_count',      coalesce(pd.n, 0),
          'collected_cents', coalesce(pd.cents, 0))
        into v_buy_in
        from (
          select count(*)::int as n, sum(bi.amount_cents)::int as cents
            from buy_ins bi
            join league_members r on r.id = bi.member_id and r.league_id = m.league_id
           where bi.season_id = v_season_id and bi.paid
        ) pd;
      exception when others then
        v_buy_in := null;
      end;
    end if;

    -- v2: the D207 headcount — the count the week-1 sentence is written under —
    -- and beside it every row, the count the room prints
    begin
      select count(*)::int into v_roster
        from league_members lm5
        join profiles p5 on p5.id = lm5.profile_id and p5.deleted_at is null
       where lm5.league_id = m.league_id and lm5.suspended_at is null;
      select count(*)::int into v_all
        from league_members lm6
       where lm6.league_id = m.league_id;
    exception when others then
      v_roster := null; v_all := null;
    end;

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
      'pulse',    v_pulse,
      'buy_in',   v_buy_in,
      'roster',   v_roster,
      'members',  v_all);
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

-- ---- self-check: reads the catalog only, never calls the function ----------
do $chk$
declare
  d text := pg_get_functiondef('public.native_home()'::regprocedure);
begin
  if d not like '%leader_name%' then
    raise exception 'native_home v2: standing.leader_name missing from the stored definition';
  end if;
  if d not like '%runner_up_points%' then
    raise exception 'native_home v2: standing.runner_up_points missing from the stored definition';
  end if;
  if d not like '%buy_in%' then
    raise exception 'native_home v2: membership.buy_in missing from the stored definition';
  end if;
  if d not like '%cup_finalists%' or d not like '%''finalists''%' then
    raise exception 'native_home v2: standing.seed / finalists (D138) missing from the stored definition';
  end if;
  if d not like '%suspended_at is null%' then
    raise exception 'native_home v2: membership.roster is not the D207 count';
  end if;
  if d not like '%''members''%' then
    raise exception 'native_home v2: membership.members (the room''s count) missing from the stored definition';
  end if;
  if exists (select 1 from pg_proc p
              where p.oid = 'public.native_home()'::regprocedure
                and (p.proacl is null
                     or exists (select 1 from aclexplode(p.proacl) a
                                 where a.grantee in (0, 'anon'::regrole::oid)))) then
    raise exception 'native_home v2: public/anon may still execute native_home()';
  end if;
end $chk$;
