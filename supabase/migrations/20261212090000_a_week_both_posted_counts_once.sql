-- ============================================================================
-- Cup Season — a week both golfers posted is one meeting, however many
-- seasons they share (W7-002, round 2's critique B2-golfers-1, a P0)
--
-- head_to_head(uuid)'s first facet, season_weeks, has the basis "the better
-- round against your playing HCP in a week you both posted" — but its two week
-- CTEs grouped by (season_id, week) and joined on both, so two golfers who
-- share TWO leagues met twice in every week they both posted, and the record,
-- the streak and the last five counted every such week twice. The fixture
-- pair read "Ten meetings … 5–5" where the weeks they both posted are seven.
--
-- The fix is the facet's own stated rule, the one my_rivalries() already
-- applies (20260716210000:96-103): one meeting per calendar week, each golfer's
-- figure their best across the seasons the two share. Nothing else moves: the
-- other five facets, the payload's shape, the visibility predicate, the grants.
-- No mechanic changes, so no decision-log entry: the basis string already says
-- "a week you both posted". Which record a surface shows is still X36 (the
-- owner's), and this does not touch it.
--
-- create or replace restates the WHOLE function from 20260917090000 (which is
-- never edited — CLAUDE.md rule 2) with the two CTEs and the join changed.
-- The payload shape is unchanged, so either deploy order is safe.
--
-- HELD for the owner's `supabase db push`. Proven on a disposable
-- PostgreSQL 17 cluster with the full chain, never against the linked project.
-- ============================================================================

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
  -- W7-002 · A WEEK IS COUNTED ONCE. The basis is "a week you both posted",
  -- so the week is the key, never (season, week): two golfers who share two
  -- leagues met ONCE in a week they both posted, and each golfer's figure is
  -- their best across the seasons they share (`v_rounds_ranked` fans a round
  -- into every league, each at its own allowance) — my_rivalries()'s rule,
  -- one meeting per calendar week (20260716210000:96-103).
  wk_mine as (select date_trunc('week', rr.played_on)::date wk, max(rr.pvi) pvi
                from v_rounds_ranked rr
               where rr.profile_id = v and rr.season_id in (select season_id from shared_seasons)
               group by 1),
  wk_opp as (select date_trunc('week', rr.played_on)::date wk, max(rr.pvi) pvi
               from v_rounds_ranked rr
              where rr.profile_id = p_opponent and rr.season_id in (select season_id from shared_seasons)
              group by 1),
  f_season as (
    select m.wk on_day, true settled,
           case when m.pvi > o.pvi then true when m.pvi < o.pvi then false else null end won,
           'season_weeks'::text facet, false heuristic, true confirmed
      from wk_mine m join wk_opp o on o.wk = m.wk
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
