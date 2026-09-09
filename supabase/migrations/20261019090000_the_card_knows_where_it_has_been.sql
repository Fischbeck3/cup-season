-- Cup Season — THE CARD KNOWS WHERE IT HAS BEEN (D319).
--
-- Two reads that were already being kept and never returned.
--
-- ── 1 · A KEPT COURSE HAD NO ID, SO IT COULD NOT BE OPENED ───────────────────
-- The owner: *"On recent coures played I cant click into them, should take me
-- to the same page where you can edit picture etc."* The rows were not
-- unlinked by choice — `ProfileCoursesBlock`'s own header says why: *"nothing
-- that keys `CourseBookStore`"*. `tour_card` GROUPS BY
-- `course_key(api_course_id, course_label)` and then emits the name, the count
-- and the date, dropping the id it grouped on. It is added here.
--
-- **It is null for a free-typed course, and that is not a bug to paper over.**
-- `course_key` returns NULL for a typed label so a typed round never becomes a
-- claim about where somebody played, and 155 of 212 quick rounds in production
-- carry no `api_course_id` at all. A row without one stays a plain line — the
-- same rule the wire keeps for a sentence with no door. A control that does
-- nothing is worse than a line that never promised to.
--
-- ── 2 · THE NUMBER HAD NO PAST ──────────────────────────────────────────────
-- The owner, on the index in the masthead: *"maybe a trendline as well (are you
-- in form element)."* There is no index history table and none is added:
-- **`rounds.index_at_post` has been snapshotting it on every round since the
-- engine shipped.** `index_prev` is the index as it stood five posted rounds
-- ago — far enough back that one round cannot swing it, near enough to be about
-- now — and NULL until there are five, so a new golfer gets a number and no
-- claim about a trend.
--
-- **A FALLING INDEX IS A GOLFER IMPROVING**, and that is stated in the function
-- because this repo has already shipped the opposite: `SeasonStats.deltaText`
-- printed a "you fell" triangle on an improving index, and LINT-13 deleted the
-- typed arrow that carried it. The direction is the client's to render and the
-- server says which way is up.
--
-- ── HOW THIS FILE WAS BUILT ─────────────────────────────────────────────────
-- Both bodies are `pg_get_functiondef` from PRODUCTION, read 2026-09-08, with
-- one clause added to each. Rule 2: a migration is never edited after it runs,
-- so the live definition is the only honest starting point — re-emitting from
-- an older file would silently revert whatever landed between them.

begin;

CREATE OR REPLACE FUNCTION public.tour_card(p_profile uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_prof jsonb; v_career jsonb; v_trophies jsonb; v_recent jsonb; v_vs jsonb;
  v_courses jsonb; v_shared jsonb; v_case jsonb; v_best jsonb;
begin
  if p_profile is null then return jsonb_build_object('visible', false); end if;

  if not (
    p_profile = v
    or exists (select 1 from friendships f where f.status='accepted'
        and ((f.requester=v and f.addressee=p_profile) or (f.addressee=v and f.requester=p_profile)))
    or exists (select 1 from league_members a join league_members b on b.league_id=a.league_id
        where a.profile_id=v and b.profile_id=p_profile)
    or exists (select 1 from event_players a join event_players b on b.event_id=a.event_id
        where a.profile_id=v and b.profile_id=p_profile)
    or coalesce((select discoverable from profiles where id=p_profile), 'nobody') = 'everyone'
  ) then
    return jsonb_build_object('visible', false);
  end if;

  select jsonb_build_object(
    'id', p.id, 'display_name', p.display_name, 'handle', p.handle,
    'marker', p.marker, 'city', p.city, 'home_course', p.home_course,
    'index_current', p.index_current,
    'member_since', p.created_at, 'is_me', p.id = v
  ) into v_prof
  from profiles p where p.id = p_profile and p.deleted_at is null;

  if v_prof is null then return jsonb_build_object('visible', false); end if;

  -- D209 · ONE lens. `lens` is this golfer's allowance figure — the engine's
  -- own `v_rounds_ranked.pvi`, the number the points were scored against —
  -- collapsed to ONE ROW PER ROUND, because a round played by a member of two
  -- leagues fans into two ranked rows and would otherwise carry double weight.
  -- The lens that wins is the one the round scored best under, the same ladder
  -- `month_rank` already uses on this view. Sim rounds are excluded here for
  -- the same reason every other figure in this block excludes them.
  with lens as (
    select distinct on (rr.round_id) rr.round_id, rr.pvi
      from v_rounds_ranked rr
     where rr.profile_id = p_profile
       and rr.pvi is not null
       and coalesce(rr.source,'app') <> 'sim'
     order by rr.round_id, rr.points desc, rr.pvi desc, rr.season_id
  )
  select jsonb_build_object(
    'rounds', count(*),
    'best', min(differential),
    'avg_vs_index', round(avg(index_at_post - differential) filter (where index_at_post is not null), 1),
    'avg_pvi',  (select round(avg(l.pvi), 1) from lens l),
    'best_pvi', (select max(l.pvi) from lens l)
  ) into v_career
  from rounds
  where profile_id = p_profile and not voided and differential is not null
    and coalesce(source,'app') <> 'sim';

  -- R21 · the best round as a SENTENCE's worth of facts: the lowest gross,
  -- where, and when. Null when this golfer has no counting round with a gross
  -- on it, and the row simply does not render (L-44). Nines are excluded: a 38
  -- for nine is not a lower round than a 74 for eighteen, and the row would
  -- read as though it were.
  select jsonb_build_object('gross', r.gross,
                            'course_label', nullif(r.course_label, ''),
                            'played_on', r.played_on,
                            'differential', r.differential)
    into v_best
    from rounds r
   where r.profile_id = p_profile and not r.voided
     and coalesce(r.source,'app') <> 'sim'
     and r.gross is not null
     and coalesce(r.holes_played, 18) = 18
   order by r.gross asc, r.played_on desc
   limit 1;

  if v_best is not null then
    v_career := coalesce(v_career, '{}'::jsonb) || jsonb_build_object('best_round', v_best);
  end if;

  -- the MILESTONES, under the key they have always had. Renaming a shipped key
  -- blanks the credential on every client that has not been updated.
  select coalesce(jsonb_agg(jsonb_build_object(
           'kind', kind, 'label', label, 'earned_on', earned_on, 'meta', meta)
         order by earned_on desc, kind), '[]'::jsonb) into v_trophies
  from achievements where profile_id = p_profile;

  -- R21 · the CASE — the actual silverware. `trophies` RLS is self-only and
  -- stays self-only; this function is SECURITY DEFINER and has already decided
  -- that this viewer may see this card, so it is the one place the case may be
  -- read from. Nothing here is a count of anything else: a title is a row.
  select coalesce(jsonb_agg(jsonb_build_object(
           'kind', t.kind, 'title', t.title, 'subtitle', t.subtitle,
           'placement', t.placement, 'season_year', t.season_year,
           'earned_on', t.earned_on)
         order by t.earned_on desc nulls last, t.title), '[]'::jsonb) into v_case
  from trophies t where t.profile_id = p_profile;

  select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) into v_recent from (
    select played_on, course_label, gross, differential, holes_played,
           -- D76 FORM: beat the number = pvi >= 1 (nines are 18-equivalized
           -- upstream by score_round; nulls stay null, never a guess)
           case when differential is not null and index_at_post is not null
                then (index_at_post - differential) >= 1
                else null end as beat
      from rounds
     where profile_id = p_profile and not voided and coalesce(source,'app') <> 'sim'
     order by played_on desc, created_at desc
     limit 5
  ) x;

  if p_profile <> v then
    with shared as (
      select distinct s.id season_id
        from league_members lm1
        join league_members lm2 on lm2.league_id=lm1.league_id and lm2.profile_id=p_profile
        join seasons s on s.league_id=lm1.league_id
       where lm1.profile_id = v
    ),
    mine as (select date_trunc('week',rr.played_on)::date wk, max(rr.pvi) pvi
       from v_rounds_ranked rr where rr.profile_id=v and rr.season_id in (select season_id from shared) group by 1),
    opp as (select date_trunc('week',rr.played_on)::date wk, max(rr.pvi) pvi
       from v_rounds_ranked rr where rr.profile_id=p_profile and rr.season_id in (select season_id from shared) group by 1),
    clash as (select m.pvi mp, o.pvi op from mine m join opp o on o.wk=m.wk)
    select jsonb_build_object(
      'wins',   count(*) filter (where mp > op),
      'losses', count(*) filter (where mp < op),
      'ties',   count(*) filter (where mp = op)
    ) into v_vs from clash;
  end if;

  -- D150 · the course history. Only PICKED courses count: course_key returns
  -- NULL for a free-typed round, so a typed label never becomes a claim about
  -- where somebody has played.
  select coalesce(jsonb_agg(jsonb_build_object(
           'name', nm, 'rounds', n, 'last_played', last_on,
           -- D319 · null for a course whose rounds were all free-typed. The
           -- client draws such a row as a plain line, exactly as the wire
           -- draws a sentence with no door — never a control that does nothing.
           'api_course_id', cid) order by n desc, nm), '[]'::jsonb)
    into v_courses
    from (
      select course_key(api_course_id, course_label) k,
             min(course_name_of(api_course_id, course_label)) nm,
             -- D319 · the id the row needs to OPEN the course. It was already
             -- in the group key and simply never emitted, which is why every
             -- kept course was a dead line. `min` is safe: the key is derived
             -- from this column, so within a group it is one value or null.
             min(api_course_id) cid,
             count(*) n, max(played_on) last_on
        from rounds
       where profile_id = p_profile and not voided
         and coalesce(source,'app') <> 'sim'
         and differential is not null
         and course_key(api_course_id, course_label) is not null
       group by 1
    ) c;

  -- the point of the whole exercise: what the two of you have both played
  if p_profile <> v then
    select coalesce(jsonb_agg(jsonb_build_object('name', nm, 'mine', mine, 'theirs', theirs)
                    order by theirs desc, nm), '[]'::jsonb)
      into v_shared
      from (
        select coalesce(t.nm, m.nm) nm, coalesce(m.n,0) mine, coalesce(t.n,0) theirs
          from (select course_key(api_course_id, course_label) k,
                       min(course_name_of(api_course_id, course_label)) nm, count(*) n
                  from rounds where profile_id = v and not voided
                    and coalesce(source,'app') <> 'sim'
                    and course_key(api_course_id, course_label) is not null
                 group by 1) m
          join (select course_key(api_course_id, course_label) k,
                       min(course_name_of(api_course_id, course_label)) nm, count(*) n
                  from rounds where profile_id = p_profile and not voided
                    and coalesce(source,'app') <> 'sim'
                    and course_key(api_course_id, course_label) is not null
                 group by 1) t on t.k = m.k
      ) s;
  end if;

  return jsonb_build_object(
    'visible', true, 'profile', v_prof, 'career', v_career,
    'trophies', v_trophies, 'case', coalesce(v_case, '[]'::jsonb),
    'recent', v_recent, 'vs_you', v_vs,
    'courses', coalesce(v_courses, '[]'::jsonb),
    'shared_courses', coalesce(v_shared, '[]'::jsonb)
  );
end $function$;

CREATE OR REPLACE FUNCTION public.native_home()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  v_pro        text;       -- v3: the Pro's first name, the board's form
  v_last       jsonb;      -- v3: the previous COMPLETE season of this league, or null
  v_clash      jsonb;      -- v3: home_clash(), inlined so Home makes one read
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
      -- **D319 · WHERE THE NUMBER HAS BEEN.** `rounds.index_at_post` snapshots
      -- the index every round was posted at, so a trend needs no new table and
      -- no new write — only a read of history that was already being kept. This
      -- is the index as it stood FIVE POSTED ROUNDS AGO: far enough back that
      -- one round does not swing it, near enough to be about now. NULL until
      -- there are five, and the client then prints the number alone rather than
      -- a delta from nothing.
      --
      -- The DIRECTION is the client's to interpret and the comment is here so
      -- nobody re-derives it wrong: **a falling index is a golfer improving.**
      'index_prev',    (select r.index_at_post from rounds r
                         where r.profile_id = p.id and not r.voided
                           and r.index_at_post is not null
                           and coalesce(r.source,'app') <> 'sim'
                         order by r.played_on desc, r.created_at desc
                         offset 4 limit 1),
      'index_engine',  handicap_index(p.id),
      'index_source',  p.index_source,
      'photo_path',    p.photo_path,
      'rounds_count',  (select count(*)::int from rounds r
                         where r.profile_id = p.id and not r.voided),
      'member_since',  p.created_at,
      'is_founder',    p.is_founder,
      -- v3 · MY last round, so the ME strip stops hunting for its own row in
      -- home_feed (which carries the CIRCLE's rounds and can page past mine).
      -- `days_since_round` is for a RANKER, never for rendering: "N days since"
      -- is the shame line L-22 forbids.
      'last_round_on',     lr.played_on,
      'last_gross',        lr.gross,
      'last_round_id',     lr.id,
      'days_since_round',  case when lr.played_on is null then null::int
                                else (current_date - lr.played_on) end
    ) into v_profile
    from profiles p
    left join lateral (
      select r.id, r.gross, r.played_on
        from rounds r
       where r.profile_id = p.id and not r.voided
       order by r.played_on desc, r.created_at desc
       limit 1) lr on true
    where p.id = v;
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
    v_last := null; v_clash := null;
    v_solo := (m.structure = 'solo');
    -- v3 · D226 · the Pro has a first name, said the way the board says it.
    v_pro := case when m.commissioner_name is null then null
                  else firstname(m.commissioner_name) end;

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
        'tiebreak_rung',         s.tiebreak_rung,
        -- v3 / D246 · THE week producer. "What week is it" was computed in at
        -- least six places on two clients with two different bases; from here
        -- it is answered once, on the season's OWN calendar day (its timezone,
        -- not the device's), and both clients read it. The arithmetic is
        -- LeagueDates.currentWeek / totalWeeks / weekClose, moved here:
        --   week_no     = floor((today - starts_on) / 7) + 1, clamped [1, total]
        --   weeks_total = max(1, ceil((ends_on - starts_on) / 7))
        --   week_ends_on= starts_on + 7*floor(max(0, today - starts_on)/7) + 6
        -- `days_to_first_tee` is null once the season has started, so no client
        -- can print "0 days to first tee"; `days_left` never goes negative.
        'week_no',            greatest(1, least(
                                greatest(1, ceil((s.ends_on - s.starts_on)::numeric / 7)::int),
                                floor((sd.d - s.starts_on)::numeric / 7)::int + 1)),
        'weeks_total',        greatest(1, ceil((s.ends_on - s.starts_on)::numeric / 7)::int),
        'week_ends_on',       s.starts_on + (greatest(0, sd.d - s.starts_on) / 7) * 7 + 6,
        'days_to_first_tee',  case when s.starts_on > sd.d then (s.starts_on - sd.d) else null::int end,
        'days_left',          greatest(0, s.ends_on - sd.d),
        -- the Cup Final's own clock: ends_on - 27 (LeagueDates.cupFinalStart),
        -- and null on a points-table season, which has no Final to open.
        'final_opens_on',     case when coalesce(m.finish, 'cup_final') = 'cup_final'
                                   then s.ends_on - 27 else null::date end)
      into v_season_id, v_season
      from seasons s
      cross join lateral (select (now() at time zone coalesce(s.timezone, 'UTC'))::date as d) sd
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
                   nth_value(vs.points, 2)  over w2 as runner_up_pts,
                   -- v3 · the two rows either side of mine, BY NAME. A gap
                   -- with no name is a number a golfer cannot act on (A-5),
                   -- and at rank >= 3 the server named nobody at all.
                   lag(sq.name)             over w  as up_name,
                   lead(sq.name)            over w  as down_name,
                   lead(vs.points)          over w  as down_pts
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
            'runner_up_points', st.runner_up_pts,
            'next_up',          case when st.next_pts is null then null
                                     else jsonb_build_object('name', st.up_name, 'points', st.next_pts) end,
            'next_down',        case when st.down_pts is null then null
                                     else jsonb_build_object('name', st.down_name, 'points', st.down_pts) end)
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
                   nth_value(vi.points, 2)         over w2 as runner_up_pts,
                   -- v3 · the two rows either side of mine, BY NAME (A-5)
                   lag(p2.display_name)            over w  as up_raw,
                   lead(p2.display_name)           over w  as down_raw,
                   lead(vi.points)                 over w  as down_pts
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
            'runner_up_points', st.runner_up_pts,
            'next_up',          case when st.next_pts is null then null
                                     else jsonb_build_object(
                                       'name',   case when st.up_raw is null then null else firstname(st.up_raw) end,
                                       'points', st.next_pts) end,
            'next_down',        case when st.down_pts is null then null
                                     else jsonb_build_object(
                                       'name',   case when st.down_raw is null then null else firstname(st.down_raw) end,
                                       'points', st.down_pts) end)
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

    -- v3 · the season BEFORE this one, when this league has finished one. It
    -- is what a golfer between seasons has to look at, and the client has no
    -- read that reaches it. Never the current season: `<> v_season_id`.
    begin
      select jsonb_build_object(
        'number',         s2.number,
        'ended_on',       s2.ends_on,
        'champion_name',  case
                            when v_solo then (select firstname(p6.display_name)
                                                from league_members lm7
                                                join profiles p6 on p6.id = lm7.profile_id
                                               where lm7.id = s2.champion_member_id)
                            else (select sq7.name from squads sq7 where sq7.id = s2.champion_squad_id)
                          end,
        -- LV-11 · whether the caller IS the champion. Without it the dispatch
        -- card said "Galen took the last one." to Galen, beside "You finished
        -- 1 of 8." — the golfer's own name in the third person.
        'champion_is_me', case
                            when v_solo then exists (select 1 from league_members lm8
                                                      where lm8.id = s2.champion_member_id
                                                        and lm8.profile_id = v)
                            else exists (select 1 from squads sq8
                                          join league_members lm9 on lm9.squad_id = sq8.id
                                         where sq8.id = s2.champion_squad_id
                                           and lm9.profile_id = v)
                          end,
        'my_rank',        case
                            when v_solo then (select vi2.rk from (
                                   select vi.member_id, rank() over (order by vi.points desc) as rk
                                     from v_individual_standings vi where vi.season_id = s2.id) vi2
                                  where vi2.member_id = m.member_id)
                            else null::bigint
                          end,
        'of',             case
                            when v_solo then (select count(*)::int from v_individual_standings vi
                                               where vi.season_id = s2.id)
                            else null::int
                          end)
      into v_last
      from seasons s2
      where s2.league_id = m.league_id
        and s2.status = 'complete'
        and (v_season_id is null or s2.id <> v_season_id)
      order by s2.ends_on desc
      limit 1;
    exception when others then
      v_last := null;
    end;

    -- v3 · the week's clash, INLINED. Home used to make a second RPC per
    -- league for it (`home_clash`), which is a second read of the same shape
    -- for a fact that belongs to this payload. The function is unchanged and
    -- still returns null unless the caller is IN this week's open clash; it
    -- is only called on a season that is actually running.
    if v_season_id is not null and coalesce(v_season->>'status', '') in ('active', 'cup_final') then
      begin
        select home_clash(m.league_id) into v_clash;
      exception when others then
        v_clash := null;
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
      'pulse',    v_pulse,
      'buy_in',   v_buy_in,
      'roster',   v_roster,
      'members',  v_all,
      -- v3
      'pro_name',    v_pro,
      'last_season', v_last,
      'clash',       v_clash);
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
      -- R-04 · WHO started it. This read returns a round the caller is SEATED
      -- in, which includes one somebody else started and I have never opened;
      -- without the name that state had no subject and the card said "You are
      -- on the card right now", which is false.
      'host',         (select p9.display_name from league_members sm9
                        join profiles p9 on p9.id = sm9.profile_id
                       where sm9.id = lr.started_by),
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
      -- R-04 · the starter, by name. `my_visitor_rounds` carries
      -- `starter_profile_id`; a row with none leaves this null and the card
      -- says the true thing without a subject rather than inventing one.
      'host',         (select p10.display_name from profiles p10
                        where p10.id = nullif(e->>'starter_profile_id', '')::uuid),
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
end $function$;


-- ── self-check ──────────────────────────────────────────────────────────────
-- Each predicate names a string that EXISTS in the object it tests, and none of
-- them is quoted anywhere a comment inside the function body could satisfy it.
do $$
declare v_tc text; v_nh text;
begin
  select prosrc into v_tc from pg_proc where oid = 'public.tour_card(uuid)'::regprocedure;
  select prosrc into v_nh from pg_proc where oid = 'public.native_home()'::regprocedure;

  if v_tc is null or v_nh is null then
    raise exception '[D319] one of the two functions is not there to check';
  end if;

  if v_tc not like '%min(api_course_id) cid%' then
    raise exception '[D319] tour_card does not select the course id';
  end if;
  if v_tc not like '%api_course_id'', cid%' then
    raise exception '[D319] tour_card selects the course id and does not emit it';
  end if;
  -- the shared-courses half is untouched and must stay that way
  if v_tc not like '%theirs%' then
    raise exception '[D319] tour_card lost its shared-courses block';
  end if;

  if v_nh not like '%index_prev%' then
    raise exception '[D319] native_home does not return the previous index';
  end if;
  if v_nh not like '%index_current'', p.index_current%' then
    raise exception '[D319] native_home lost the current index';
  end if;
  -- the trend must read HISTORY, never a second live column that does not exist
  if v_nh not like '%r.index_at_post%' then
    raise exception '[D319] native_home computes the trend from something other than round history';
  end if;
end $$;

commit;
