-- ============================================================================
-- Cup Season — a season tells its own story (R6 `season_story`, C-9
-- `leave_season`)
--
-- Wave 4 of the UX overhaul (docs/ux-overhaul-2026-09-04/, owner-authorised
-- 2026-09-05). D223 (no league room — a season is a page), D230 (every league
-- door lands on the season page), D235 (the endgame in two pieces), D244 (a
-- member may leave a season, forward-only), IOS-031.
--
-- ---------------------------------------------------------------------------
-- R6 · season_story(p_season uuid default null, p_league uuid default null)
--
-- The season as a story with a spine, in ONE read: the table, the arc that
-- produced it, and the facts a fixed seven-rung ladder chooses one sentence
-- from (INFORMATION_ARCHITECTURE.md §7.2).
--
-- IT RETURNS FACTS, NOT SENTENCES — with one exception, `posts.body`, which is
-- already a sentence the server wrote. Every rung's words live in ONE producer
-- rendered twice (`SeasonStoryCopy` in the Kit, `csSeasonStory*` on the web),
-- because a ladder written in SQL is a ladder no test can walk. What this
-- function owes them is the arithmetic and its provenance.
--
-- EVERY FACT NAMES ITS READ. Each entry in `history` and `arc` carries a
-- `source` — `standings_snapshots`, `week_clashes`, `my_rivalries`, `posts` —
-- and the client renders nothing whose source it does not recognise. That is
-- R-H's fence made mechanical: the bottom rung may reach further back, and it
-- still may not invent. Nothing here is a projection, a probability or a
-- prediction (D24); every number is a count or a difference over rows that
-- already exist.
--
-- THE SEVEN RUNGS, and the fact each one needs:
--   1 the lead changed this week   facts.lead_flip{ on, week, to, first_time }
--   2 someone has led >= 3 weeks   facts.leader{ name, run_weeks }
--   3 the top gap is <= 2          facts.top_gap, facts.weeks_left
--   4 a rung closed half the gap   facts.closer{ name, taken, weeks }
--   5 the Final opens <= 3 weeks   facts.final{ opens_on, in_weeks, seats, still_live }
--   6 week 1                       facts.week_no = 1, facts.weeks_total
--   7 none of the above            history[] — the reach back (R-H)
--   7b history is empty            facts.week_no / weeks_total / last_snapshot_on
--
-- `still_live` is `season_scenarios`' own elimination arithmetic, called
-- rather than re-derived — two functions answering "who can still make the
-- Final" with two different sums is exactly the drift this build exists to end.
--
-- ---------------------------------------------------------------------------
-- C-9 · leave_season(p_league uuid default null) — FORWARD-ONLY
--
-- D244. There has never been a member exit on either client; the only way out
-- was to ask the Pro to cancel the whole season. This is the exit, and it is
-- the only shape compatible with L-02 (a round is never mutated) and §16 (the
-- record shows its work and is never rewritten):
--
--   * NO round is touched, voided, moved or unscored. Everything already
--     scored stays exactly where it is, so nobody else's standings, receipts
--     or pot math move by one point.
--   * the name stays on the season that was played — the table keeps the
--     history that actually happened.
--   * scoring stops TODAY: `league_members.left_at`, and the same forward-only
--     cut `v_rounds_ranked` already applies to a suspension
--     (`r.created_at < lm.left_at`). A live membership filter would erase a
--     leaver's past rounds from everyone else's standings the moment they
--     tapped, which is the exact thing §16 forbids.
--   * a leaver is not announced as a defection, not shamed and not counted
--     anywhere. The Pro is told once, plainly, on the board.
--
-- The Pro cannot leave their own season — `transfer_pro` first, or the room
-- has nobody who can mark a payment or close the roster. That refusal is a
-- sentence, not a silence.
--
-- Both functions are additive. A client that predates this migration is
-- unaffected; a client that postdates it and cannot find them renders the
-- season page WITHOUT the story spine (the table, the pot and the doors are
-- all read the way they were) and hides the leave door. Every argument is
-- defaulted, per CLAUDE.md's deploy-skew rule.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- C-9 · the column, its grant, its index
-- ---------------------------------------------------------------------------
alter table public.league_members add column if not exists left_at timestamptz;

-- D37 · a new column on a granted table is still granted explicitly.
grant select (left_at) on public.league_members to authenticated;

create index if not exists league_members_left_idx
  on public.league_members (league_id) where left_at is not null;

-- ---------------------------------------------------------------------------
-- the scoring lens — prod's definition with ONE conjunct appended, beside the
-- suspension's. Same shape, same direction, same reason: forward-only.
-- ---------------------------------------------------------------------------
create or replace view public.v_rounds_ranked as
WITH scored AS (
         SELECT lm.id AS member_id,
            s.id AS season_id,
            r.id AS round_id,
            r.profile_id,
            r.played_on,
            r.holes_played,
            r.source,
            r.attested,
            r.differential,
            r.index_at_post,
            round(r.index_at_post * ls.handicap_allowance::numeric / 100.0, 1) AS playing_index,
            round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1) AS pvi,
                CASE
                    WHEN r.holes_played = 9 THEN ceil(cup_points(round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1))::numeric / 2::numeric)::integer
                    ELSE cup_points(round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1))
                END AS points,
                CASE
                    WHEN r.holes_played = 9 THEN 0.5
                    ELSE 1.0
                END AS floor_credit
           FROM rounds r
             JOIN league_members lm ON lm.profile_id = r.profile_id
             JOIN league_settings ls ON ls.league_id = lm.league_id
             JOIN seasons s ON s.league_id = lm.league_id AND (s.status = ANY (ARRAY['active'::text, 'cup_final'::text, 'complete'::text])) AND r.played_on >= s.starts_on AND r.played_on <= s.ends_on
          WHERE NOT r.voided AND (ls.sim_rounds_allowed OR COALESCE(r.source, 'app'::text) <> 'sim'::text) AND (ls.nine_hole_allowed OR r.holes_played = 18)
            AND (lm.suspended_at IS NULL OR r.created_at < lm.suspended_at)
            AND (lm.left_at IS NULL OR r.created_at < lm.left_at)
        )
 SELECT member_id,
    season_id,
    round_id,
    profile_id,
    played_on,
    holes_played,
    source,
    attested,
    differential,
    index_at_post,
    playing_index,
    pvi,
    points,
    floor_credit,
    row_number() OVER (PARTITION BY member_id, season_id, (date_trunc('month'::text, played_on::timestamp with time zone)) ORDER BY points DESC, pvi DESC, played_on DESC) AS month_rank
   FROM scored;

-- ---------------------------------------------------------------------------
-- C-9 · the verb
-- ---------------------------------------------------------------------------
create or replace function public.leave_season(p_league uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $fn$
declare
  v_member  uuid;
  v_role    text;
  v_left    timestamptz;
  v_name    text;
  v_league  text;
  v_season  uuid;
begin
  if p_league is null then raise exception 'leave_season needs a league'; end if;

  select lm.id, lm.role, lm.left_at, coalesce(p.display_name, 'A golfer')
    into v_member, v_role, v_left, v_name
    from league_members lm
    left join profiles p on p.id = lm.profile_id
   where lm.league_id = p_league and lm.profile_id = auth.uid();
  if v_member is null then raise exception 'You are not in this season'; end if;

  -- The Pro hands the season over first. A season whose only Pro walked out
  -- has nobody to mark a payment, close the roster or end it.
  if v_role = 'commissioner' then
    raise exception 'Hand the season to somebody else first — a season needs a Pro';
  end if;

  select name into v_league from leagues where id = p_league;

  -- Idempotent: leaving twice is leaving once. The second call says the same
  -- thing the first did and writes nothing (no second board line, L-20).
  if v_left is not null then
    return jsonb_build_object('left_at', v_left, 'league_id', p_league,
                              'league', v_league, 'already', true);
  end if;

  update league_members set left_at = now() where id = v_member
  returning left_at into v_left;

  select id into v_season from seasons where league_id = p_league
   order by (status in ('active', 'cup_final')) desc, starts_on desc limit 1;

  -- The Pro is told once, plainly. No verb, no count of defections, no name
  -- called out twice: what happened, and what did not.
  insert into posts (league_id, season_id, kind, body)
  values (p_league, v_season, 'system',
          v_name || ' stepped out of the season. Their rounds stay where they are; '
                 || 'they stop scoring from today.');

  return jsonb_build_object('left_at', v_left, 'league_id', p_league,
                            'league', v_league, 'already', false);
end $fn$;

revoke all on function public.leave_season(uuid) from public, anon;
grant execute on function public.leave_season(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- R6 · the story
-- ---------------------------------------------------------------------------
create or replace function public.season_story(p_season uuid default null,
                                               p_league uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $fn$
declare
  se        record;
  ls        record;
  v_league  text;
  v_solo    boolean;
  v_finish  text;
  v_today   date;
  v_week    int;
  v_weeks   int;
  v_ends    date;
  v_opens   date;
  v_me      uuid;
  v_now     jsonb  := '[]'::jsonb;      -- the table, now
  v_snaps   jsonb  := '[]'::jsonb;      -- every weekly snapshot, ranked
  v_facts   jsonb;
  v_hist    jsonb  := '[]'::jsonb;
  v_arc     jsonb  := '[]'::jsonb;
  v_arch    jsonb  := '[]'::jsonb;
  v_lead    jsonb;
  v_run     int    := 0;
  v_flip    jsonb;
  v_closer  jsonb;
  v_live    int;
  v_scen    jsonb;
  v_riv     record;
  v_opp     uuid;
  v_since   date;
  v_mine    jsonb;
  v_streak  int    := 0;
  v_best    jsonb;
  i         int;
  j         int;
  w         jsonb;
  wprev     jsonb;
  r         jsonb;
begin
  if p_season is not null then
    select * into se from seasons where id = p_season;
  elsif p_league is not null then
    select * into se from seasons where league_id = p_league
     order by (status in ('active', 'cup_final')) desc, starts_on desc limit 1;
  end if;
  if se.id is null then return null; end if;
  if not is_league_member(se.league_id) then raise exception 'not a league member'; end if;

  select * into ls from league_settings where league_id = se.league_id;
  select name into v_league from leagues where id = se.league_id;
  v_solo   := coalesce(ls.structure, 'squads2') = 'solo';
  v_finish := coalesce(ls.finish, 'cup_final');
  v_today  := (now() at time zone coalesce(se.timezone, 'UTC'))::date;
  v_weeks  := greatest(1, ceil((se.ends_on - se.starts_on)::numeric / 7)::int);
  v_week   := greatest(1, least(v_weeks, floor((v_today - se.starts_on)::numeric / 7)::int + 1));
  v_ends   := se.starts_on + (greatest(0, v_today - se.starts_on) / 7) * 7 + 6;
  v_opens  := case when v_finish = 'cup_final' then se.ends_on - 27 else null::date end;
  v_me     := my_member_id(se.league_id);

  -- =========================================================================
  -- THE TABLE, now. One row per rung, with the clause of WHY beside the
  -- number (§7.3): its rank, its run at that rank, its best week, and — for a
  -- solo season — how many of this month's rounds are counting against the cap
  -- (from v_rounds_ranked's own month_rank, never from the participation
  -- floor's credit count, which knows nothing about the cap).
  -- =========================================================================
  if v_solo then
    select coalesce(jsonb_agg(z.r order by (z.r->>'rank')::int), '[]'::jsonb) into v_now from (
      select jsonb_build_object(
               'id',      lm.id,
               'name',    coalesce(p.display_name, 'A golfer'),
               'points',  coalesce(vi.points, 0),
               'rank',    row_number() over (order by coalesce(vi.points, 0) desc, lm.id),
               'rounds',  coalesce(vi.rounds_posted, 0),
               'counted', (select count(*) from v_rounds_ranked rr
                            where rr.member_id = lm.id and rr.season_id = se.id
                              and date_trunc('month', rr.played_on) = date_trunc('month', v_today)
                              and rr.month_rank <= coalesce(ls.counting_cap, 2147483647)),
               'left',    (lm.left_at is not null),
               'is_me',   (lm.id = v_me)) as r
        from v_individual_standings vi
        join league_members lm on lm.id = vi.member_id
        left join profiles p on p.id = lm.profile_id
       where vi.season_id = se.id) z;
  else
    select coalesce(jsonb_agg(z.r order by (z.r->>'rank')::int), '[]'::jsonb) into v_now from (
      select jsonb_build_object(
               'id',      q.id,
               'name',    q.name,
               'points',  coalesce(ss.points, 0),
               'rank',    row_number() over (order by coalesce(ss.points, 0) desc, q.id),
               'rounds',  null::int,
               'counted', null::int,
               'left',    false,
               'is_me',   exists (select 1 from squad_members sm where sm.squad_id = q.id and sm.member_id = v_me)) as r
        from squads q
        left join v_squad_standings ss on ss.squad_id = q.id and ss.season_id = q.season_id
       where q.season_id = se.id) z;
  end if;

  -- =========================================================================
  -- EVERY WEEKLY SNAPSHOT, ranked. This is the season's own history and the
  -- read four of the seven rungs count over. `captured_at` rides along so a
  -- movement clause can name the day it is measured FROM (A-4) — a bare arrow
  -- over a Sunday snapshot lies about time on a Tuesday.
  -- =========================================================================
  select coalesce(jsonb_agg(z.w order by (z.w->>'week')::int), '[]'::jsonb) into v_snaps from (
    select jsonb_build_object(
             'week', ss.week_no,
             'at',   ss.captured_at,
             'rows', (select coalesce(jsonb_agg(jsonb_build_object('id', y.cid, 'points', y.pts, 'rank', y.rk)
                                                order by y.rk), '[]'::jsonb)
                        from (select coalesce(x->>'squad_id', x->>'member_id')::uuid as cid,
                                     coalesce((x->>'points')::numeric, 0) as pts,
                                     row_number() over (order by coalesce((x->>'points')::numeric, 0) desc,
                                                                 coalesce(x->>'squad_id', x->>'member_id')) as rk
                                from jsonb_array_elements(
                                       case when v_solo then coalesce(ss.standings->'individuals', '[]'::jsonb)
                                            else coalesce(ss.standings->'squads', '[]'::jsonb) end) x) y)) as w
      from standings_snapshots ss
     where ss.season_id = se.id) z;

  -- =========================================================================
  -- THE FACTS the ladder reads. Every one is a count or a difference over the
  -- two arrays above, or over a named table. Nothing is a guess ahead.
  -- =========================================================================
  v_lead := v_now->0;

  -- rung 2 · the leader's run: consecutive most-recent snapshot weeks whose
  -- top row is the leader now. `season_lead.since` is the same fact for a
  -- squads season and is carried beside it rather than instead of it.
  if v_lead is not null and jsonb_array_length(v_snaps) > 0 then
    i := jsonb_array_length(v_snaps) - 1;
    while i >= 0 loop
      w := v_snaps->i;
      exit when coalesce(w->'rows'->0->>'id', '') <> coalesce(v_lead->>'id', '-');
      v_run := v_run + 1;
      i := i - 1;
    end loop;
  end if;

  -- rung 1 · the most recent week whose top row changed hands, and whether
  -- the new leader had ever led before it.
  for i in reverse coalesce(jsonb_array_length(v_snaps), 0) - 1 .. 1 loop
    w     := v_snaps->i;
    wprev := v_snaps->(i - 1);
    if coalesce(w->'rows'->0->>'id', '') <> coalesce(wprev->'rows'->0->>'id', '')
       and coalesce(w->'rows'->0->>'id', '') <> '' then
      v_flip := jsonb_build_object(
        'week', (w->>'week')::int,
        'on',   (w->>'at')::timestamptz,
        'to',   (select x->>'name' from jsonb_array_elements(v_now) x
                  where x->>'id' = w->'rows'->0->>'id'),
        'to_id', w->'rows'->0->>'id',
        'from', (select x->>'name' from jsonb_array_elements(v_now) x
                  where x->>'id' = wprev->'rows'->0->>'id'),
        'first_time', not exists (
          select 1 from jsonb_array_elements(v_snaps) s2
           where (s2->>'week')::int < (w->>'week')::int
             and s2->'rows'->0->>'id' = w->'rows'->0->>'id'),
        'source', 'standings_snapshots');
      exit;
    end if;
  end loop;

  -- rung 4 · a rung that has closed at least half its gap to the lead in the
  -- last two snapshot weeks. The figure is the difference of two differences —
  -- both from the same read.
  if jsonb_array_length(v_snaps) >= 3 and v_lead is not null then
    declare
      s_now  jsonb := v_snaps->(jsonb_array_length(v_snaps) - 1);
      s_then jsonb := v_snaps->(jsonb_array_length(v_snaps) - 3);
      lead_now numeric;
      lead_then numeric;
      gap_now numeric;
      gap_then numeric;
      best numeric := 0;
    begin
      lead_now  := coalesce((s_now ->'rows'->0->>'points')::numeric, 0);
      lead_then := coalesce((s_then->'rows'->0->>'points')::numeric, 0);
      for j in 1 .. coalesce(jsonb_array_length(s_now->'rows'), 1) - 1 loop
        r := s_now->'rows'->j;
        gap_now  := lead_now - coalesce((r->>'points')::numeric, 0);
        gap_then := lead_then - coalesce((select (x->>'points')::numeric
                                            from jsonb_array_elements(s_then->'rows') x
                                           where x->>'id' = r->>'id'), 0);
        if gap_then > 0 and gap_now <= gap_then / 2 and (gap_then - gap_now) > best then
          best := gap_then - gap_now;
          v_closer := jsonb_build_object(
            'name',  (select x->>'name' from jsonb_array_elements(v_now) x where x->>'id' = r->>'id'),
            'taken', gap_then - gap_now,
            'weeks', 2,
            'source', 'standings_snapshots');
        end if;
      end loop;
    end;
  end if;

  -- rung 5 · who can still reach the Final. `season_scenarios` owns that
  -- arithmetic; calling it is the difference between one answer and two.
  if v_opens is not null then
    begin
      v_scen := season_scenarios(se.id);
      select count(*) into v_live
        from jsonb_array_elements(coalesce(v_scen->'rows', '[]'::jsonb)) x
       where coalesce((x->>'eliminated')::boolean, false) = false;
    exception when others then
      v_live := null;
    end;
  end if;

  v_facts := jsonb_build_object(
    'week_no',      v_week,
    'weeks_total',  v_weeks,
    'weeks_left',   greatest(0, v_weeks - v_week),
    'week_ends_on', v_ends,
    'field',        coalesce(jsonb_array_length(v_now), 0),
    'leader',       case when v_lead is null then null else jsonb_build_object(
                      'id',        v_lead->>'id',
                      'name',      v_lead->>'name',
                      'points',    (v_lead->>'points')::numeric,
                      'run_weeks', v_run,
                      'since',     (select sl.since from season_lead sl where sl.season_id = se.id),
                      'is_me',     coalesce((v_lead->>'is_me')::boolean, false),
                      'source',    'standings_snapshots') end,
    'runner_up',    case when jsonb_array_length(v_now) < 2 then null else jsonb_build_object(
                      'name',   v_now->1->>'name',
                      'points', (v_now->1->>'points')::numeric) end,
    'top_gap',      case when jsonb_array_length(v_now) < 2 then null
                         else (v_now->0->>'points')::numeric - (v_now->1->>'points')::numeric end,
    'lead_flip',    v_flip,
    'closer',       v_closer,
    'final',        case when v_opens is null then null else jsonb_build_object(
                      'opens_on',   v_opens,
                      'in_weeks',   case when v_opens < v_today then null
                                         else ceil((v_opens - v_today)::numeric / 7)::int end,
                      'seats',      2,
                      'still_live', v_live,
                      'source',     'season_scenarios') end,
    'last_snapshot_on', case when jsonb_array_length(v_snaps) = 0 then null
                             else (v_snaps->(jsonb_array_length(v_snaps) - 1)->>'at')::timestamptz end);

  -- =========================================================================
  -- RUNG 7 · THE REACH BACK (R-H). When nothing has moved this week the
  -- ladder is allowed to look FURTHER BACK — and not one inch further into
  -- invention. Every candidate below is a count over a read named in its own
  -- `source`, the client renders nothing whose source it does not recognise,
  -- and no candidate manufactures a stake: a rivalry that exists is described,
  -- a rivalry that does not is left alone.
  -- =========================================================================
  select x into v_mine from jsonb_array_elements(v_now) x
   where coalesce((x->>'is_me')::boolean, false) limit 1;

  -- 7a · the unsettled week — `week_clashes` for WHEN, `my_rivalries` for the
  -- all-time record. Both are existing reads; neither is re-derived here.
  if v_me is not null then
    begin
      select mr.opponent, mr.display_name, mr.wins, mr.losses, mr.ties, mr.meetings
        into v_riv
        from my_rivalries() mr
        join league_members lm2 on lm2.profile_id = mr.opponent and lm2.league_id = se.league_id
       order by mr.meetings desc, mr.display_name
       limit 1;
      if v_riv.opponent is not null then
        select lm2.id into v_opp from league_members lm2
         where lm2.profile_id = v_riv.opponent and lm2.league_id = se.league_id;
        select max(wc.settled_at)::date into v_since
          from week_clashes wc
          join seasons s2 on s2.id = wc.season_id and s2.league_id = se.league_id
         where wc.settled_at is not null
           and ((wc.a_member = v_me and wc.b_member = v_opp)
             or (wc.b_member = v_me and wc.a_member = v_opp));
        if v_since is not null then
          v_hist := v_hist || jsonb_build_array(jsonb_build_object(
            'kind',     'unsettled_week',
            'source',   'week_clashes',
            'record_source', 'my_rivalries',
            'opponent', v_riv.display_name,
            'since',    v_since,
            'days',     (v_today - v_since),
            'wins',     coalesce(v_riv.wins, 0),
            'losses',   coalesce(v_riv.losses, 0),
            'ties',     coalesce(v_riv.ties, 0)));
        end if;
      end if;
    exception when others then
      null;   -- my_rivalries is not there yet: the rung simply has one fewer candidate
    end;
  end if;

  -- 7b · my own run at my own place, from the same snapshots the table reads.
  if v_mine is not null and jsonb_array_length(v_snaps) >= 2 then
    declare
      my_rank int;
    begin
      select (x->>'rank')::int into my_rank
        from jsonb_array_elements(v_snaps->(jsonb_array_length(v_snaps) - 1)->'rows') x
       where x->>'id' = v_mine->>'id';
      if my_rank is not null then
        i := jsonb_array_length(v_snaps) - 1;
        while i >= 0 loop
          exit when (select (x->>'rank')::int from jsonb_array_elements(v_snaps->i->'rows') x
                      where x->>'id' = v_mine->>'id') is distinct from my_rank;
          v_streak := v_streak + 1;
          i := i - 1;
        end loop;
        if v_streak >= 2 then
          v_hist := v_hist || jsonb_build_array(jsonb_build_object(
            'kind',   'my_run',
            'source', 'standings_snapshots',
            'rank',   my_rank,
            'weeks',  v_streak));
        end if;
      end if;
    end;
  end if;

  -- 7c · my best week of the season — the largest week-over-week gain in the
  -- snapshots. A difference between two rows that exist.
  if v_mine is not null and jsonb_array_length(v_snaps) >= 2 then
    declare
      gain numeric;
      best numeric := 0;
      bw   int;
      prev numeric;
      cur  numeric;
    begin
      for i in 1 .. jsonb_array_length(v_snaps) - 1 loop
        select (x->>'points')::numeric into cur
          from jsonb_array_elements(v_snaps->i->'rows') x where x->>'id' = v_mine->>'id';
        select (x->>'points')::numeric into prev
          from jsonb_array_elements(v_snaps->(i - 1)->'rows') x where x->>'id' = v_mine->>'id';
        gain := coalesce(cur, 0) - coalesce(prev, 0);
        if gain > best then best := gain; bw := (v_snaps->i->>'week')::int; end if;
      end loop;
      if best > 0 then
        v_best := jsonb_build_object('kind', 'my_best_week', 'source', 'standings_snapshots',
                                     'week', bw, 'points', best);
        v_hist := v_hist || jsonb_build_array(v_best);
      end if;
    end;
  end if;

  -- =========================================================================
  -- THE ARC — the season week by week, newest first. Three reads, each row
  -- carrying its own. `posts.body` is the one sentence this function returns
  -- rather than the facts behind it, because the server already wrote it.
  -- =========================================================================
  -- lead changes, from the snapshots
  select coalesce(v_arc || jsonb_agg(z.a order by (z.a->>'week')::int desc), v_arc) into v_arc from (
    select jsonb_build_object(
             'kind',   'lead_change',
             'source', 'standings_snapshots',
             'week',   (s2->>'week')::int,
             'on',     (s2->>'at')::timestamptz,
             'subject', (select x->>'name' from jsonb_array_elements(v_now) x
                          where x->>'id' = s2->'rows'->0->>'id'),
             'other',  (select x->>'name' from jsonb_array_elements(v_now) x
                          where x->>'id' = sp->'rows'->0->>'id')) as a
      from jsonb_array_elements(v_snaps) with ordinality t(s2, o)
      join lateral (select v_snaps->(o::int - 2) as sp) l on true
     where o > 1
       and coalesce(s2->'rows'->0->>'id', '') <> coalesce(l.sp->'rows'->0->>'id', '')
       and coalesce(s2->'rows'->0->>'id', '') <> '') z;

  -- the weeks that were settled, mine among them
  if v_me is not null then
    select coalesce(v_arc || jsonb_agg(z.a order by z.wk desc), v_arc) into v_arc from (
      select wc.week_no as wk, jsonb_build_object(
               'kind',   'clash',
               'source', 'week_clashes',
               'week',   wc.week_no,
               'on',     wc.settled_at,
               'subject', case when wc.winner_member = v_me then 'you'
                               else coalesce((select p.display_name from league_members lm3
                                               join profiles p on p.id = lm3.profile_id
                                              where lm3.id = wc.winner_member), null) end,
               'other',  coalesce((select p.display_name from league_members lm4
                                    join profiles p on p.id = lm4.profile_id
                                   where lm4.id = case when wc.a_member = v_me then wc.b_member else wc.a_member end), 'a league mate'),
               'mine',   true) as a
        from week_clashes wc
       where wc.season_id = se.id and wc.settled_at is not null
         and (wc.a_member = v_me or wc.b_member = v_me)) z;
  end if;

  -- what the season said about itself
  select coalesce(v_arc || jsonb_agg(z.a order by z.at desc), v_arc) into v_arc from (
    select po.created_at as at, jsonb_build_object(
             'kind',   'post',
             'source', 'posts',
             'week',   greatest(1, least(v_weeks, floor((po.created_at::date - se.starts_on)::numeric / 7)::int + 1)),
             'on',     po.created_at,
             'text',   po.body,
             'post_kind', po.kind) as a
      from posts po
     where po.league_id = se.league_id
       and po.kind in ('moment', 'system')
       and po.created_at::date between se.starts_on and se.ends_on
     order by po.created_at desc
     limit 40) z;

  -- one order, newest first
  select coalesce(jsonb_agg(x order by (x->>'on') desc nulls last), '[]'::jsonb) into v_arc
    from jsonb_array_elements(v_arc) x;

  -- =========================================================================
  -- THE ARCHIVE — every season this league has played, browsable. The web
  -- leans on it (R-C: the archive is a thing a desk does and a phone does
  -- not); the phone carries it behind the story page.
  -- =========================================================================
  select coalesce(jsonb_agg(z.a order by z.n desc), '[]'::jsonb) into v_arch from (
    select s3.number as n, jsonb_build_object(
             'season_id',  s3.id,
             'number',     s3.number,
             'starts_on',  s3.starts_on,
             'ends_on',    s3.ends_on,
             'status',     s3.status,
             'champion',   coalesce(
                             (select q.name from squads q where q.id = s3.champion_squad_id),
                             (select p.display_name from league_members lm5
                               join profiles p on p.id = lm5.profile_id
                              where lm5.id = s3.champion_member_id)),
             'is_current', (s3.id = se.id)) as a
      from seasons s3 where s3.league_id = se.league_id) z;

  return jsonb_build_object(
    'season', jsonb_build_object(
      'id',           se.id,
      'league_id',    se.league_id,
      'league',       v_league,
      'number',       se.number,
      'starts_on',    se.starts_on,
      'ends_on',      se.ends_on,
      'status',       se.status,
      'finish',       v_finish,
      'structure',    coalesce(ls.structure, 'squads2'),
      'solo',         v_solo,
      'today',        v_today,
      'my_member_id', v_me,
      'i_left',       (select lm6.left_at is not null from league_members lm6 where lm6.id = v_me)),
    'facts',        v_facts,
    'history',      v_hist,
    'arc',          v_arc,
    'table',        v_now,
    'archive',      v_arch,
    'generated_at', now());
end $fn$;

revoke all on function public.season_story(uuid, uuid) from public, anon;
grant execute on function public.season_story(uuid, uuid) to authenticated;

-- ---- self-check: reads the catalog only, never mutates a row ---------------
do $chk$
declare
  s text := pg_get_functiondef('public.season_story(uuid, uuid)'::regprocedure);
  l text := pg_get_functiondef('public.leave_season(uuid)'::regprocedure);
begin
  -- R-H's fence, as a property of the payload rather than a promise: every
  -- history candidate names the read it was counted over.
  if s not like '%''source'', ''week_clashes''%'
     or s not like '%''source'', ''standings_snapshots''%' then
    raise exception 'season_story: a history candidate does not name its read (R-H''s fence)';
  end if;
  -- D24 · nothing here guesses at an outcome
  if s ilike '%probability%' or s ilike '%likely%' or s ilike '%projected%' or s ilike '%odds%' then
    raise exception 'season_story: a fact is a guess at an outcome (D24)';
  end if;
  -- G7's shame gate, restated for this surface
  if s ilike '%you haven''t%' or s ilike '%days since you%' then
    raise exception 'season_story: a sentence names the golfer''s absence';
  end if;
  -- L-44 · the counted figure is the CAP's, never the participation floor's
  if s like '%pulse.credits%' then
    raise exception 'season_story: counted rounds must come from month_rank, never pulse.credits';
  end if;
  -- D244 · forward-only, and it says so in the only place that can enforce it
  if pg_get_viewdef('public.v_rounds_ranked'::regclass, true) not like '%left_at%' then
    raise exception 'leave_season: the scoring view does not honour a leaver';
  end if;
  if l like '%delete from%' or l like '%update rounds%' then
    raise exception 'leave_season: a round is mutated (L-02)';
  end if;
  if l not like '%commissioner%' then
    raise exception 'leave_season: the Pro can walk out of their own season';
  end if;
  -- every argument defaulted, per the deploy-skew rule
  if (select pronargdefaults from pg_proc where oid = 'public.season_story(uuid, uuid)'::regprocedure) < 2 then
    raise exception 'season_story: both arguments must be defaulted (deploy skew)';
  end if;
  if (select pronargdefaults from pg_proc where oid = 'public.leave_season(uuid)'::regprocedure) < 1 then
    raise exception 'leave_season: p_league must be defaulted (deploy skew)';
  end if;
  -- D37 grant discipline
  if exists (select 1 from pg_proc p
              where p.oid in ('public.season_story(uuid, uuid)'::regprocedure,
                              'public.leave_season(uuid)'::regprocedure)
                and (p.proacl is null
                     or exists (select 1 from aclexplode(p.proacl) a
                                 where a.grantee in (0, 'anon'::regrole::oid)))) then
    raise exception 'season_story / leave_season: public or anon may still execute';
  end if;
  -- and the new column is granted, not assumed (D37)
  if not exists (
    select 1 from information_schema.column_privileges
     where table_schema = 'public' and table_name = 'league_members'
       and column_name = 'left_at' and grantee = 'authenticated' and privilege_type = 'SELECT') then
    raise exception 'league_members.left_at is not granted to authenticated';
  end if;
end $chk$;
