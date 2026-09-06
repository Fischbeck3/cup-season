-- ============================================================================
-- Cup Season — the record between two golfers (R4 `head_to_head`,
-- R5 `friends_board`, R17 `my_side_games`)
--
-- Wave 5 of the UX overhaul (docs/ux-overhaul-2026-09-04/, owner-authorised
-- 2026-09-05). D239 (who was out there — the table shipped in wave 2, this is
-- its first read), D245 (friends may be ranked, by form first), IOS-032.
--
-- ---------------------------------------------------------------------------
-- R4 · head_to_head(p_opponent uuid default null) -> jsonb
--
-- The record between me and ONE other golfer, however we played. Today that
-- record is computed three different ways — `my_rivalries`, `rivalry_weeks`
-- and `tour_card.vs_you` — and NONE of them can count two buddies who share no
-- season, because every one of them joins `league_members × seasons`
-- (`20260716210000:76-83`). Two friends who have played eleven rounds together
-- and never run a league have, today, no record at all. This replaces all
-- three with one read.
--
-- ONE ARITHMETIC, NOT TWO. Every meeting is materialised ONCE, into
-- `v_meetings`, and the facets, the summary record, the streak and the last
-- five are all derived from that one array. A function that counted the facets
-- in one pass and the total in another is a function whose own rows can
-- disagree with its own headline, which is the exact defect this build exists
-- to end.
--
-- SIX FACETS, EACH WITH ITS OWN BASIS, AND THE BASIS IS RETURNED (L-01):
--
--   season_weeks    the better round in a week you both posted, inside a
--                   season you share — the allowance figure, `v_rounds_ranked`
--   clashes         the weekly clash the engine actually opened and settled —
--                   `week_clashes`, winner_member
--   played_together the rounds you were both out for — `round_players` (C-2,
--                   born in wave 2's `20260910093000_who_was_out_there.sql`,
--                   which precedes this file in the push order),
--                   confirmed and unconfirmed counted separately, UNION the
--                   same-day/same-course heuristic, which is counted under its
--                   own key and NEVER folded silently into the confirmed count
--   live_games      a live round you both finished — the better card against
--                   your own number that day
--   duels           a Ryder duel, in an event with a field of more than two
--   callouts        the same duel rows in an event whose field is exactly two
--                   — which is what a callout is (§9.1), counted from the
--                   shape of the event rather than from a table that does not
--                   exist yet
--
-- WHAT A "MEETING" IS, said once. `round_players` is the honest capture: the
-- tag is a CLAIM with a state, and until the tagged golfer answers, the facet
-- reports it as unconfirmed rather than asserting a meeting nobody agreed to.
-- Same-day/same-course is the FALLBACK and it is labelled as the heuristic it
-- is on every surface that prints it — 155 of 212 quick rounds in prod carry
-- no course id, so the facet would otherwise be thin for months.
--
-- THE LENS IS NAMED PER FACET, not blended into one number. A season facet is
-- the allowance figure (`v_rounds_ranked.pvi`); a facet that has to work for
-- two golfers with no league between them is the round's own figure against
-- the golfer's own number (`index_at_post - differential`), which is D76's own
-- definition of beating your number. Both are returned with a `basis` string
-- so no surface has to guess which it is holding.
--
-- A MEETING WITH NO VERDICT IS NOT A TIE. `settled` is its own flag: two
-- golfers were out on the same day and one of them never posted a card is a
-- meeting that counts toward "you have played together eleven times" and
-- toward nobody's W-L (L-44).
--
-- THE GATE IS `tour_card`'s, UNCHANGED (L-37 / D150): self, accepted buddy,
-- shared league, shared event, or discoverable = 'everyone'. A caller outside
-- it gets `{"visible": false}` and nothing else.
--
-- ---------------------------------------------------------------------------
-- R5 · friends_board(p_days int default 30) -> table
--
-- D245, ruled narrowly and built the way it was ruled:
--   * one row per ACCEPTED buddy, both directions, plus me
--   * `discoverable` is NOT in this predicate. It is the SEARCH gate (L-37);
--     a golfer who accepted you is not hidden from you by it, and a
--     `discoverable <> 'nobody'` clause here would hide them.
--   * form is the default order: beats first, then rounds, then the average
--   * the index is the SECOND lens, returned as its own rank
--   * NEVER points (L-13, they are season-scoped) and NO attention metric of
--     any kind — no reactions, no followers, no streak leaderboard (L-22).
--     What this function returns is the whole of what may be ranked.
--   * the round COUNT rides beside every figure, so a two-round month never
--     masquerades as a season of form.
--
-- ---------------------------------------------------------------------------
-- R17 · my_side_games(p_limit int default 20) -> table
--
-- DL-19: a side game's result is JSON on `live_rounds.game_result` and the
-- relational `game_results` table is dead (0 rows). No read aggregates it, so
-- the record cannot say a word about the games a golfer actually plays.
--
-- It returns the finished live rounds I was seated in, the game, the other
-- players, and **the game's own settled sentence** (`game_result.story`) —
-- which the server wrote at finish and is the only trustworthy account of who
-- won. It does NOT derive a W-L: `game_result.winner` is a side INDEX and the
-- sides are free-text name strings, so a derived verdict would be a name-match
-- dressed as a fact (L-44). And it returns no money: a side game's stake is
-- units inside the game's own JSON, and the "no money column" rule
-- (`20260724120000:10-13`) is load-bearing for store review.
--
-- ---------------------------------------------------------------------------
-- All three are additive and every argument is defaulted (CLAUDE.md's
-- deploy-skew rule). A client that predates this migration is unaffected; a
-- client that postdates it and cannot find them renders the head-to-head from
-- `my_rivalries` as it does today, and the board and the side games not at all.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- R4 · head_to_head
-- ---------------------------------------------------------------------------
create or replace function public.head_to_head(p_opponent uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $fn$
declare
  v uuid := auth.uid();
  v_prof jsonb;
  v_meetings jsonb := '[]'::jsonb;
  v_facets jsonb := '{}'::jsonb;
  v_last jsonb;
  v_name text;
  v_w int; v_l int; v_t int; v_total int;
  v_since date;
  v_streak_who text; v_streak_n int;
  v_league text;
  v_basis constant jsonb := jsonb_build_object(
    'season_weeks',    jsonb_build_object('basis', 'the better round against your playing HCP in a week you both posted', 'source', 'v_rounds_ranked'),
    'clashes',         jsonb_build_object('basis', 'the weekly clash the season opened and settled',                        'source', 'week_clashes'),
    'played_together', jsonb_build_object('basis', 'the better card against your playing HCP on a day you were both out',    'source', 'round_players'),
    'live_games',      jsonb_build_object('basis', 'the better card against your playing HCP in a round you both scored live','source', 'live_rounds'),
    'duels',           jsonb_build_object('basis', 'a Ryder clash, settled',                                                 'source', 'event_duels'),
    'callouts',        jsonb_build_object('basis', 'a head-to-head with a field of two',                                    'source', 'event_duels'));
begin
  -- the null case answers before the auth check, so a catalogue self-check can
  -- call it without a session and still prove the shape (L-05).
  if p_opponent is null or p_opponent = v then return jsonb_build_object('visible', false); end if;
  if v is null then return jsonb_build_object('visible', false); end if;

  -- the Tour-Card predicate, unchanged (L-37 / D150)
  if not (
    exists (select 1 from friendships f where f.status = 'accepted'
              and ((f.requester = v and f.addressee = p_opponent)
                or (f.addressee = v and f.requester = p_opponent)))
    or exists (select 1 from league_members a join league_members b on b.league_id = a.league_id
                where a.profile_id = v and b.profile_id = p_opponent)
    or exists (select 1 from event_players a join event_players b on b.event_id = a.event_id
                where a.profile_id = v and b.profile_id = p_opponent)
    or coalesce((select discoverable from profiles where id = p_opponent), 'nobody') = 'everyone'
  ) then
    return jsonb_build_object('visible', false);
  end if;

  select jsonb_build_object('id', p.id, 'display_name', p.display_name,
                            'handle', p.handle, 'marker', p.marker)
    into v_prof
    from profiles p where p.id = p_opponent and p.deleted_at is null;
  if v_prof is null then return jsonb_build_object('visible', false); end if;

  select min(l.name) into v_league
    from league_members lm1
    join league_members lm2 on lm2.league_id = lm1.league_id and lm2.profile_id = p_opponent
    join leagues l on l.id = lm1.league_id
   where lm1.profile_id = v;

  -- ------------------------------------------------------------------
  -- EVERY MEETING, ONCE. `won` is true (me), false (them) or null; `settled`
  -- says whether there was a verdict at all, so a halve and a card nobody
  -- posted are never the same row.
  -- ------------------------------------------------------------------
  with shared_seasons as (
    select distinct s.id as season_id
      from league_members lm1
      join league_members lm2 on lm2.league_id = lm1.league_id and lm2.profile_id = p_opponent
      join seasons s on s.league_id = lm1.league_id
     where lm1.profile_id = v
  ),
  -- facet 1 · season weeks (the allowance figure)
  wk_mine as (select rr.season_id, date_trunc('week', rr.played_on)::date wk, max(rr.pvi) pvi
                from v_rounds_ranked rr
               where rr.profile_id = v and rr.season_id in (select season_id from shared_seasons)
               group by 1, 2),
  wk_opp as (select rr.season_id, date_trunc('week', rr.played_on)::date wk, max(rr.pvi) pvi
               from v_rounds_ranked rr
              where rr.profile_id = p_opponent and rr.season_id in (select season_id from shared_seasons)
              group by 1, 2),
  f_season as (
    select m.wk on_day, true settled,
           case when m.pvi > o.pvi then true when m.pvi < o.pvi then false else null end won,
           'season_weeks'::text facet, false heuristic, true confirmed
      from wk_mine m join wk_opp o on o.season_id = m.season_id and o.wk = m.wk
  ),
  -- facet 2 · the clash the engine opened and settled
  mem as (select id, profile_id from league_members where profile_id in (v, p_opponent)),
  f_clash as (
    select c.opened_at::date on_day, true settled,
           case when c.winner_member is null then null
                when c.winner_member in (select id from mem where profile_id = v) then true
                else false end won,
           'clashes'::text facet, false heuristic, true confirmed
      from week_clashes c
      join mem ma on ma.id = c.a_member
      join mem mb on mb.id = c.b_member
     where c.settled_at is not null
       and ((ma.profile_id = v and mb.profile_id = p_opponent)
         or (ma.profile_id = p_opponent and mb.profile_id = v))
  ),
  -- facet 3 · played together (the tag with a state) ∪ the labelled heuristic
  tagged as (
    select r.played_on, bool_or(rp.confirmed_at is not null) confirmed
      from rounds r
      join round_players rp on rp.round_id = r.id and rp.profile_id = p_opponent
     where r.profile_id = v and not r.voided
     group by 1
    union all
    select r.played_on, bool_or(rp.confirmed_at is not null)
      from rounds r
      join round_players rp on rp.round_id = r.id and rp.profile_id = v
     where r.profile_id = p_opponent and not r.voided
     group by 1
  ),
  tagged_days as (select played_on, bool_or(confirmed) confirmed from tagged group by 1),
  heur_days as (
    -- SAME DAY, SAME COURSE, never tagged: the fallback, counted under its own
    -- key so no surface can print it as a confirmed meeting
    select distinct a.played_on
      from rounds a
      join rounds b on b.played_on = a.played_on
                   and course_key(b.api_course_id, b.course_label)
                     = course_key(a.api_course_id, a.course_label)
     where a.profile_id = v and b.profile_id = p_opponent
       and not a.voided and not b.voided
       and course_key(a.api_course_id, a.course_label) is not null
       and not exists (select 1 from tagged_days t where t.played_on = a.played_on)
  ),
  together_days as (
    select played_on, confirmed, false heuristic from tagged_days
    union all
    select played_on, false, true from heur_days
  ),
  day_figs as (
    select d.played_on, d.confirmed, d.heuristic,
           (select max(r.index_at_post - r.differential) from rounds r
             where r.profile_id = v and r.played_on = d.played_on and not r.voided
               and r.differential is not null and r.index_at_post is not null) mine,
           (select max(r.index_at_post - r.differential) from rounds r
             where r.profile_id = p_opponent and r.played_on = d.played_on and not r.voided
               and r.differential is not null and r.index_at_post is not null) theirs
      from together_days d
  ),
  f_together as (
    select played_on on_day, (mine is not null and theirs is not null) settled,
           case when mine is null or theirs is null then null
                when mine > theirs then true when mine < theirs then false else null end won,
           'played_together'::text facet, heuristic, confirmed
      from day_figs
  ),
  -- facet 4 · a live round you both finished
  seats as (
    select lp.live_round_id, coalesce(lp.claimed_profile, lp.guest_profile_id, lm.profile_id) pid
      from live_round_players lp
      left join league_members lm on lm.id = lp.member_id
  ),
  ours as (
    select distinct s.live_round_id
      from seats s
      join live_rounds lr on lr.id = s.live_round_id
     where s.pid = v and lr.status = 'final'
       and exists (select 1 from seats t where t.live_round_id = s.live_round_id and t.pid = p_opponent)
  ),
  f_live as (
    select coalesce((select min(r.played_on) from rounds r where r.live_round_id = o.live_round_id),
                    (select lr.finished_at::date from live_rounds lr where lr.id = o.live_round_id)) on_day,
           (mine is not null and theirs is not null) settled,
           case when mine is null or theirs is null then null
                when mine > theirs then true when mine < theirs then false else null end won,
           'live_games'::text facet, false heuristic, true confirmed
      from (
        select o2.live_round_id,
               (select max(r.index_at_post - r.differential) from rounds r
                 where r.live_round_id = o2.live_round_id and r.profile_id = v and not r.voided
                   and r.differential is not null and r.index_at_post is not null) mine,
               (select max(r.index_at_post - r.differential) from rounds r
                 where r.live_round_id = o2.live_round_id and r.profile_id = p_opponent and not r.voided
                   and r.differential is not null and r.index_at_post is not null) theirs
          from ours o2
      ) o
  ),
  -- facets 5 and 6 · the same duel rows, split by the SHAPE of the field. An
  -- event with a field of exactly two IS a callout (§9.1): one session, two
  -- golfers. That is a fact about rows that already exist, not a table waiting
  -- to be built.
  f_duel as (
    select du.resolved_at::date on_day, true settled,
           case when du.result = 'halve' then null
                when (ea.profile_id = v and du.result = 'a')
                  or (eb.profile_id = v and du.result = 'b') then true
                else false end won,
           case when (select count(*) from event_players ep where ep.event_id = e.id) = 2
                then 'callouts' else 'duels' end::text facet,
           false heuristic, true confirmed
      from event_duels du
      join event_players ea on ea.id = du.a_player
      join event_players eb on eb.id = du.b_player
      join events e on e.id = du.event_id
     where du.result <> 'pending'
       and ((ea.profile_id = v and eb.profile_id = p_opponent)
         or (ea.profile_id = p_opponent and eb.profile_id = v))
  ),
  every_meeting as (
    select * from f_season
    union all select * from f_clash
    union all select * from f_together
    union all select * from f_live
    union all select * from f_duel
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'on', on_day, 'settled', settled, 'won', won,
           'facet', facet, 'heuristic', heuristic, 'confirmed', confirmed)
         order by on_day desc nulls last), '[]'::jsonb)
    into v_meetings
    from every_meeting;

  -- ------------------------------------------------------------------
  -- the six facets, derived from that one array
  -- ------------------------------------------------------------------
  select coalesce(jsonb_object_agg(facet, body), '{}'::jsonb) into v_facets from (
    select m.facet,
           jsonb_build_object(
             'wins',    count(*) filter (where m.settled and m.won is true),
             'losses',  count(*) filter (where m.settled and m.won is false),
             'ties',    count(*) filter (where m.settled and m.won is null),
             'meetings', count(*),
             'unsettled', count(*) filter (where not m.settled),
             'confirmed', count(*) filter (where m.confirmed and not m.heuristic),
             'unconfirmed', count(*) filter (where not m.confirmed and not m.heuristic),
             'heuristic', count(*) filter (where m.heuristic),
             'first_on', min(m.on_day),
             'last_on',  max(m.on_day))
           || coalesce(v_basis->m.facet, '{}'::jsonb) as body
      from (
        select x->>'facet' facet,
               (x->>'settled')::boolean settled,
               case when x->'won' = 'null'::jsonb then null else (x->>'won')::boolean end won,
               (x->>'heuristic')::boolean heuristic,
               (x->>'confirmed')::boolean confirmed,
               (x->>'on')::date on_day
          from jsonb_array_elements(v_meetings) x
      ) m
     group by m.facet
  ) f;

  -- the record is the SUM of the same rows the facets counted
  select count(*) filter (where settled and won is true),
         count(*) filter (where settled and won is false),
         count(*) filter (where settled and won is null),
         count(*),
         min(on_day)
    into v_w, v_l, v_t, v_total, v_since
    from (
      select (x->>'settled')::boolean settled,
             case when x->'won' = 'null'::jsonb then null else (x->>'won')::boolean end won,
             (x->>'on')::date on_day
        from jsonb_array_elements(v_meetings) x
    ) z;

  -- the last five SETTLED meetings, newest first
  select coalesce(jsonb_agg(jsonb_build_object('on', on_day, 'won', won, 'facet', facet)
                            order by on_day desc), '[]'::jsonb)
    into v_last
    from (
      select (x->>'on')::date on_day,
             case when x->'won' = 'null'::jsonb then null else (x->>'won')::boolean end won,
             x->>'facet' facet
        from jsonb_array_elements(v_meetings) x
       where (x->>'settled')::boolean
       order by (x->>'on')::date desc
       limit 5
    ) w;

  -- the streak: how many of the most recent decided meetings one of us took
  select who, n into v_streak_who, v_streak_n from (
    select case when won then 'me' else 'them' end who,
           count(*) n
      from (
        select won, row_number() over (order by on_day desc) rn,
               row_number() over (partition by won order by on_day desc) rn2
          from (
            select (x->>'on')::date on_day,
                   (x->>'won')::boolean won
              from jsonb_array_elements(v_meetings) x
             where (x->>'settled')::boolean and x->'won' <> 'null'::jsonb
          ) a
      ) b
     where rn = rn2
     group by 1
     order by n desc
     limit 1
  ) s;

  select rn.name into v_name from rivalry_names rn
   where rn.pair_low = least(v, p_opponent) and rn.pair_high = greatest(v, p_opponent);

  return jsonb_build_object(
    'visible', true,
    'opponent', v_prof,
    'league', v_league,
    'record', jsonb_build_object('wins', coalesce(v_w, 0), 'losses', coalesce(v_l, 0),
                                 'ties', coalesce(v_t, 0), 'total', coalesce(v_total, 0)),
    'lead', case when coalesce(v_w, 0) > coalesce(v_l, 0) then 'up'
                 when coalesce(v_w, 0) < coalesce(v_l, 0) then 'down' else 'even' end,
    'since', v_since,
    'streak', case when v_streak_n is null or v_streak_n < 2 then null
                   else jsonb_build_object('who', v_streak_who, 'n', v_streak_n) end,
    'last_five', coalesce(v_last, '[]'::jsonb),
    'rivalry_name', v_name,
    'facets', v_facets);
end $fn$;

comment on function public.head_to_head(uuid) is
  'R4 (IOS-032) · the record between me and one golfer, in six facets each carrying its own basis and source. Every meeting is materialised once, so the facets and the headline cannot disagree. Replaces my_rivalries/rivalry_weeks/tour_card.vs_you and counts two buddies who share no season. The same-day/same-course fallback is counted under its own key and is never folded into a confirmed count.';

revoke all on function public.head_to_head(uuid) from public, anon;
grant execute on function public.head_to_head(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- R5 · friends_board (D245 / C-7)
-- ---------------------------------------------------------------------------
create or replace function public.friends_board(p_days integer default 30)
returns table(
  profile_id uuid,
  display_name text,
  handle text,
  marker text,
  index_current numeric,
  rounds_30d integer,
  beats_30d integer,
  avg_vs_number_30d numeric,
  best_vs_number_30d numeric,
  last_round_on date,
  rank_by_form integer,
  rank_by_index integer,
  is_me boolean)
language sql
stable
security definer
set search_path to 'public'
as $fn$
  with circle as (
    -- accepted, both directions. `discoverable` is DELIBERATELY absent: it is
    -- the search gate (L-37), and a golfer who accepted you is not hidden from
    -- you by it (D245 clause 4).
    select case when f.requester = auth.uid() then f.addressee else f.requester end as pid
      from friendships f
     where f.status = 'accepted'
       and (f.requester = auth.uid() or f.addressee = auth.uid())
    union
    select auth.uid()
  ),
  form as (
    select r.profile_id pid,
           count(*)::int n,
           count(*) filter (where r.index_at_post - r.differential >= 1)::int beats,
           round(avg(r.index_at_post - r.differential), 1) avg_fig,
           max(r.index_at_post - r.differential) best_fig
      from rounds r
     where r.profile_id in (select pid from circle)
       and not r.voided
       and coalesce(r.source, 'app') <> 'sim'
       and r.differential is not null and r.index_at_post is not null
       and r.played_on >= (current_date - greatest(coalesce(p_days, 30), 1))
     group by 1
  ),
  last_on as (
    select r.profile_id pid, max(r.played_on) on_day
      from rounds r
     where r.profile_id in (select pid from circle) and not r.voided
       and coalesce(r.source, 'app') <> 'sim'
     group by 1
  ),
  rows_ as (
    select p.id, p.display_name, p.handle, p.marker, p.index_current,
           coalesce(f.n, 0)::int n, coalesce(f.beats, 0)::int beats,
           f.avg_fig, f.best_fig, l.on_day, p.id = auth.uid() as me
      from circle c
      join profiles p on p.id = c.pid and p.deleted_at is null
      left join form f on f.pid = p.id
      left join last_on l on l.pid = p.id
     where auth.uid() is not null
  )
  select id, display_name, handle, marker, index_current,
         n, beats, avg_fig, best_fig, on_day,
         -- FORM is the default lens: beats first, then rounds, then the
         -- average. The count rides beside the figure so a two-round month
         -- never masquerades as a season of form (D245's tradeoff, built).
         rank() over (order by beats desc, n desc, avg_fig desc nulls last, display_name)::int,
         -- the index is the SECOND lens, and it is the only other one:
         -- never points, which are season-scoped (L-13)
         rank() over (order by index_current asc nulls last, display_name)::int,
         me
    from rows_
   order by 11, display_name;
$fn$;

comment on function public.friends_board(integer) is
  'R5 (D245 / C-7) · your buddies ranked by FORM over p_days, with the index as the second lens. Accepted buddies both ways plus you; discoverable is deliberately not in the predicate. No points, no attention metric of any kind (L-13, L-22).';

revoke all on function public.friends_board(integer) from public, anon;
grant execute on function public.friends_board(integer) to authenticated;

-- ---------------------------------------------------------------------------
-- R17 · my_side_games (DL-19)
-- ---------------------------------------------------------------------------
create or replace function public.my_side_games(p_limit integer default 20)
returns table(
  live_round_id uuid,
  played_on date,
  game text,
  course_label text,
  players text[],
  story text,
  status text)
language sql
stable
security definer
set search_path to 'public'
as $fn$
  with seats as (
    select lp.live_round_id,
           coalesce(lp.claimed_profile, lp.guest_profile_id, lm.profile_id) pid,
           coalesce(lp.guest_name, p.display_name) nm
      from live_round_players lp
      left join league_members lm on lm.id = lp.member_id
      left join profiles p on p.id = coalesce(lp.claimed_profile, lp.guest_profile_id, lm.profile_id)
  ),
  mine as (select distinct s.live_round_id from seats s where s.pid = auth.uid())
  select lr.id,
         coalesce(lr.finished_at::date, lr.started_at::date),
         lr.game,
         lr.course_label,
         (select array_agg(distinct s.nm) from seats s
           where s.live_round_id = lr.id and s.nm is not null
             and s.pid is distinct from auth.uid()),
         -- the SERVER's own settled sentence, written at finish. No verdict is
         -- derived here: `game_result.winner` is a side index and the sides are
         -- free text, so a derived W-L would be a name match dressed as a fact.
         nullif(lr.game_result->>'story', ''),
         nullif(lr.game_result->>'status', '')
    from live_rounds lr
   where auth.uid() is not null
     and lr.id in (select live_round_id from mine)
     and lr.status = 'final'
   order by coalesce(lr.finished_at, lr.started_at) desc
   limit greatest(coalesce(p_limit, 20), 1);
$fn$;

comment on function public.my_side_games(integer) is
  'R17 (DL-19) · the finished live rounds I was seated in, with the game, the other players and the game''s OWN settled sentence. No derived verdict and no money: a side game''s stake is units inside its own JSON, and the no-money-column rule stands.';

revoke all on function public.my_side_games(integer) from public, anon;
grant execute on function public.my_side_games(integer) to authenticated;

-- ---------------------------------------------------------------------------
-- self-check — catalogue and read-only calls; no row is written (L-05)
-- ---------------------------------------------------------------------------
do $check$
declare
  v jsonb;
  v_cols text;
begin
  -- L-04, compiler-enforced on the phone: only granted functions get a name
  if has_function_privilege('anon', 'public.head_to_head(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.friends_board(integer)', 'EXECUTE')
     or has_function_privilege('anon', 'public.my_side_games(integer)', 'EXECUTE') then
    raise exception 'wave 5: anon can execute one of these (the anon surface stays at twelve)';
  end if;
  if not has_function_privilege('authenticated', 'public.head_to_head(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.friends_board(integer)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.my_side_games(integer)', 'EXECUTE') then
    raise exception 'wave 5: authenticated cannot execute one of these (silent 403 on the phone)';
  end if;

  -- the gate answers, and it answers with the shape the client decodes
  v := head_to_head(null);
  if coalesce((v->>'visible')::boolean, true) then
    raise exception 'head_to_head: a null opponent must not be visible';
  end if;

  -- D245 clause 5, mechanical: what the board may return is the whole of what
  -- may be ranked. A points column or an attention metric fails the push.
  select pg_get_function_result(p.oid) into v_cols
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public' and p.proname = 'friends_board';
  if v_cols ~* '\m(points|reactions|kudos|followers|streak|views)\M' then
    raise exception 'friends_board: an attention metric or a points column got in (L-13, L-22): %', v_cols;
  end if;

  perform * from friends_board(30);
  perform * from my_side_games(1);
end $check$;
