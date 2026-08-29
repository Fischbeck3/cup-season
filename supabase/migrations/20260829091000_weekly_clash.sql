-- ============================================================================
-- Cup Season — D108 · The weekly clash (D52's build packet, server half)
--
-- D52 (2026-07-21) decided the mechanic; D108 (2026-08-28) is the build plan.
-- Each season week, ONE spotlighted pairing per league. Best band-of-week takes
-- a headline W; ties are ALL SQUARE (no W); both idle settles quiet (row
-- settled, no post — D52's honesty rule). NEVER cup points — §5 parallel-ledger
-- law intact: nothing here touches points, ledgers, or standings.
--
--   1. week_clashes            the spotlight archive + receipts. a_best/b_best
--                              hold each side's counting round (round_id,
--                              played_on, points, pvi, band) so every figure
--                              taps to the rounds that produced it (§16).
--   2. open_week_clash(s)      engine-only. Pairing per D52's cascade —
--                              named rivalry (D21) → closest table gap →
--                              least-recently-featured (rotation guarantee).
--                              Implementation note on the cascade: the rotation
--                              term is a GUARANTEE, not a mere tiebreak (D52's
--                              own tradeoff line — "a spotlight excludes
--                              everyone not in it that week — rotation rule
--                              mitigates"). A literal last-place tiebreak would
--                              re-feature the same named rivalry every week and
--                              rotate nobody. So: candidate pairs are ranked
--                              first by how recently their MOST-recently-
--                              featured member was in the spotlight (never
--                              featured = most due — every member provably
--                              cycles), and WITHIN that cohort the cascade runs
--                              exactly as written: named rivalry, then closest
--                              table gap (v_individual_standings), then a
--                              deterministic uuid tiebreak. Week 1, everyone
--                              fresh: the named rivalry is picked first —
--                              the cascade's literal behavior.
--   3. settle_week_clash(s,w)  engine-only. Best band-of-week per side from
--                              v_rounds_ranked: highest-points COUNTING round
--                              (month_rank ≤ counting_cap, the season's own
--                              eligibility law) with played_on inside the week
--                              window [starts_on + 7·(w−1), +6] — league-local
--                              by construction (played_on is a date). The BAND
--                              (points) decides the W — rounds speak named
--                              bands, never raw differential (D1/D2), so equal
--                              bands are ALL SQUARE even when the raw pvi
--                              differs. One side idle = a walkover W.
--   4. daily_season_tick       cadence rides the daily tick, NOT the Sunday
--                              cron (§14.0 weeks start on the league's real
--                              first-tee weekday). Body re-created verbatim
--                              from prod (20260722100000) + the clash beat:
--                              per season, settle every opened clash whose
--                              window has fully passed on the league's local
--                              date (the week-rollover detection, generalized
--                              so a missed tick self-heals), then open the
--                              current week's clash — which on the FIRST run
--                              after this migration opens mid-season weeks for
--                              live seasons. run_week_snapshots is untouched
--                              (standings history is its job).
--
-- The two posts a week ride kind='system' — already in posts_kind_check and
-- already curated by the push webhook (per-league notify_system, per-user
-- mutes: D23's fence — board posts are not nudges, push is opt-out-able).
-- Copy voice: first names in caps (D77 firstname()), and the third-person
-- number phrase is always they/them — never guess pronouns from a name (the
-- pilot rule beside theirs() in index.html) — so the packet's example
-- "beat his number by 3.1 Thursday" ships as "beat their number by 3.1
-- Thursday".
--
-- The faceted rivalry record ("weekly clash 3–2", item-18's one-object-per-
-- pair law): the events-engine facet tables were audited and none fits —
-- event_duels is keyed to an event/session (Ryder), forfeits is prose stakes.
-- Per the packet's fallback the clash archives ONLY in week_clashes. No
-- second write is needed for the record itself: my_rivalries()'s first facet
-- already computes the weekly-clash W-L-T from v_rounds_ranked weekly bests —
-- the same rounds this engine spotlights — so the W lands in the rivalry
-- record by construction, and a week_clashes facet join stays open to the
-- clients as a pure read.
--
-- D37: explicit revoke/grant on every function; clients read week_clashes via
-- a member-scoped SELECT policy; all writes through the tick. Self-enforcing
-- RAISE block at the end.
-- ============================================================================

-- ---- 1. the table -----------------------------------------------------------

create table if not exists public.week_clashes (
  id            uuid primary key default gen_random_uuid(),
  season_id     uuid not null references public.seasons(id) on delete cascade,
  week_no       integer not null,
  a_member      uuid not null references public.league_members(id) on delete cascade,
  b_member      uuid not null references public.league_members(id) on delete cascade,
  opened_at     timestamptz not null default now(),
  settled_at    timestamptz,
  winner_member uuid references public.league_members(id) on delete set null,
  a_best        jsonb,
  b_best        jsonb,
  unique (season_id, week_no),
  constraint week_clashes_week_positive check (week_no >= 1),
  constraint week_clashes_distinct_pair check (a_member <> b_member)
);

alter table public.week_clashes enable row level security;

drop policy if exists week_clashes_read on public.week_clashes;
create policy week_clashes_read on public.week_clashes
  for select to authenticated
  using (is_league_member((select league_id from seasons where id = season_id)));
-- no client write policies ON PURPOSE — the tick is the only writer (definer).

-- Grants: the CLAUDE.md landmine is real here — depending on which role runs
-- the migration, default privileges can still hand authenticated a table-level
-- write grant on a fresh table (the dry run proved it; the RAISE block below
-- caught it). Revoke explicitly, then grant exactly what clients get: SELECT.
revoke all on table public.week_clashes from public, anon;
revoke insert, update, delete, truncate, references, trigger
  on table public.week_clashes from authenticated;
grant select on table public.week_clashes to authenticated;

-- ---- 2. open ---------------------------------------------------------------

create or replace function public.open_week_clash(p_season uuid)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  se       record;
  v_local  date;
  v_wk     integer;
  v_total  integer;
  v_a      uuid;   -- league_members.id
  v_b      uuid;
  v_id     uuid;
  v_a_name text;
  v_b_name text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null or se.status not in ('active','cup_final') then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;
  if v_local < se.starts_on or v_local > se.ends_on then
    return null;                                   -- no clash outside the season
  end if;

  v_total := ceil((se.ends_on - se.starts_on + 1) / 7.0);
  v_wk    := floor((v_local - se.starts_on) / 7)::int + 1;
  if v_wk < 1 or v_wk > v_total then
    return null;
  end if;

  -- idempotent: this week's clash already stands
  select id into v_id from week_clashes
   where season_id = p_season and week_no = v_wk;
  if v_id is not null then
    return v_id;
  end if;

  -- the pairing (see header for the cascade + rotation-guarantee reasoning)
  with mem as (            -- active members: on the roster, not tombstoned
    select lm.id, lm.profile_id, p.display_name
      from league_members lm
      join profiles p on p.id = lm.profile_id and p.deleted_at is null
     where lm.league_id = se.league_id
  ),
  feat as (                -- each member's most recent spotlight week
    select m.id, max(wc.week_no) as last_wk
      from mem m
      join week_clashes wc
        on wc.season_id = p_season
       and (wc.a_member = m.id or wc.b_member = m.id)
     group by m.id
  ),
  stand as (
    select member_id, points from v_individual_standings
     where season_id = p_season
  ),
  pairs as (
    select a.id as a_id, b.id as b_id,
           a.display_name as a_name, b.display_name as b_name,
           greatest(coalesce(fa.last_wk, 0), coalesce(fb.last_wk, 0)) as staleness,
           exists (select 1 from rivalry_names rn
                    where rn.pair_low  = least(a.profile_id, b.profile_id)
                      and rn.pair_high = greatest(a.profile_id, b.profile_id)) as named,
           abs(coalesce(sa.points, 0) - coalesce(sb.points, 0)) as gap
      from mem a
      join mem b on a.id < b.id
      left join feat  fa on fa.id = a.id
      left join feat  fb on fb.id = b.id
      left join stand sa on sa.member_id = a.id
      left join stand sb on sb.member_id = b.id
  )
  select a_id, b_id, a_name, b_name
    into v_a, v_b, v_a_name, v_b_name
    from pairs
   order by staleness asc,        -- rotation guarantee: the most-due pair first
            named desc,           -- then D52's cascade: named rivalry (D21)
            gap asc,              -- → closest table gap
            a_id, b_id            -- → deterministic
   limit 1;

  if v_a is null or v_b is null then
    return null;                                   -- solo league (<2 active) — skip
  end if;

  insert into week_clashes (season_id, week_no, a_member, b_member)
  values (p_season, v_wk, v_a, v_b)
  on conflict (season_id, week_no) do nothing
  returning id into v_id;

  if v_id is null then                             -- lost a race — take the standing row
    select id into v_id from week_clashes
     where season_id = p_season and week_no = v_wk;
    return v_id;
  end if;

  -- the open story (only when this call actually opened the week)
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'THIS WEEK: ' || upper(firstname(v_a_name)) || ' v '
                        || upper(firstname(v_b_name)) || ' — THE CLASH');

  return v_id;
end $$;

revoke all on function public.open_week_clash(uuid) from public, anon, authenticated;
grant execute on function public.open_week_clash(uuid) to service_role;

-- ---- 3. settle -------------------------------------------------------------

create or replace function public.settle_week_clash(p_season uuid, p_week integer)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  wc       record;
  se       record;
  v_cap    integer;
  v_ws     date;                                   -- week window start / end
  v_we     date;
  v_a_best jsonb;
  v_b_best jsonb;
  v_winner uuid;
  v_win_b  jsonb;
  v_name   text;
  v_a_name text;
  v_b_name text;
  v_pvi    numeric;
  v_phrase text;
begin
  select * into wc from week_clashes
   where season_id = p_season and week_no = p_week
   for update;
  if wc.id is null or wc.settled_at is not null then
    return null;                                   -- nothing open here — idempotent
  end if;

  select * into se from seasons where id = p_season;
  select counting_cap into v_cap from league_settings where league_id = se.league_id;
  v_ws := se.starts_on + 7 * (p_week - 1);
  v_we := v_ws + 6;

  -- each side's best band-of-week: highest-points COUNTING round in the window
  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case when rr.pvi >= 3  then 'Torched it'
                        when rr.pvi >= 1  then 'Beat your number'
                        when rr.pvi >= -1 then 'Played to it'
                        when rr.pvi >= -3 then 'A little loose'
                        else 'Posted anyway' end)
    into v_a_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case when rr.pvi >= 3  then 'Torched it'
                        when rr.pvi >= 1  then 'Beat your number'
                        when rr.pvi >= -1 then 'Played to it'
                        when rr.pvi >= -3 then 'A little loose'
                        else 'Posted anyway' end)
    into v_b_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  -- the band decides the W; equal bands are ALL SQUARE (D2: named bands, not
  -- raw differential); one side idle is a walkover W; both idle is quiet.
  if v_a_best is null and v_b_best is null then
    v_winner := null;
  elsif v_b_best is null
     or (v_a_best is not null
         and (v_a_best->>'points')::int > (v_b_best->>'points')::int) then
    v_winner := wc.a_member; v_win_b := v_a_best;
  elsif v_a_best is null
     or (v_b_best->>'points')::int > (v_a_best->>'points')::int then
    v_winner := wc.b_member; v_win_b := v_b_best;
  else
    v_winner := null;                              -- both posted, same band
  end if;

  update week_clashes
     set settled_at = now(), winner_member = v_winner,
         a_best = v_a_best, b_best = v_b_best
   where id = wc.id;

  select p.display_name into v_a_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.a_member;
  select p.display_name into v_b_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.b_member;

  if v_winner is not null then
    v_name := case when v_winner = wc.a_member then v_a_name else v_b_name end;
    v_pvi  := (v_win_b->>'pvi')::numeric;
    v_phrase := case
      when v_pvi >= 1  then 'beat their number by ' || to_char(v_pvi, 'FM990.0')
      when v_pvi >= -1 then 'played to their number'
      else to_char(abs(v_pvi), 'FM990.0') || ' over their number' end;
    insert into posts (league_id, season_id, kind, round_id, body)
    values (se.league_id, p_season, 'system', (v_win_b->>'round_id')::uuid,
            upper(firstname(v_name)) || ' TOOK THE WEEK — ' || v_phrase
            || ' ' || to_char((v_win_b->>'played_on')::date, 'FMDay'));
  elsif v_a_best is not null or v_b_best is not null then
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system',
            'ALL SQUARE — ' || upper(firstname(v_a_name)) || ' v '
                            || upper(firstname(v_b_name)) || ' — THE CLASH');
  end if;
  -- both idle: row settled above, no post (D52's honesty rule).

  return jsonb_build_object(
    'week', p_week, 'winner_member', v_winner,
    'a_best', v_a_best, 'b_best', v_b_best);
end $$;

revoke all on function public.settle_week_clash(uuid, integer) from public, anon, authenticated;
grant execute on function public.settle_week_clash(uuid, integer) to service_role;

-- ---- 4. the tick — prod body (20260722100000) + the clash beat -------------

create or replace function public.daily_season_tick() returns void
language plpgsql security definer set search_path = public as $$
declare se record; v_finish text; v_local date; wcr record;
begin
  -- live rounds die on their own now: 24h after start, an unfinished round is
  -- abandoned — resume and join surfaces go dark server-side, not just client.
  update live_rounds
     set status = 'abandoned', finished_at = coalesce(finished_at, now())
   where status in ('setup', 'live')
     and started_at < now() - interval '24 hours';

  for se in select * from seasons where status in ('active','cup_final')
  loop
    select finish into v_finish from league_settings where league_id = se.league_id;
    if se.status = 'active' and coalesce(v_finish,'cup_final') = 'cup_final'
       and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;

    -- D108: the weekly clash rides the tick. On the league's local date,
    -- settle every opened clash whose window has fully passed (the week-
    -- rollover detection — settles week N−1 on the increment, and self-heals
    -- across missed ticks and the season's final week), then open the current
    -- week's clash (which is also the first-run catch-up for live seasons).
    v_local := (now() at time zone se.timezone)::date;
    for wcr in
      select wc.week_no from week_clashes wc
       where wc.season_id = se.id and wc.settled_at is null
         and (se.starts_on + 7 * (wc.week_no - 1) + 6) < v_local
       order by wc.week_no
    loop
      perform settle_week_clash(se.id, wcr.week_no);
    end loop;
    perform open_week_clash(se.id);   -- no-ops outside the season / solo leagues
  end loop;
end $$;

revoke all on function public.daily_season_tick() from public, anon, authenticated;

-- ---- self-enforcing ---------------------------------------------------------

do $$
declare v_tick text;
begin
  if to_regclass('public.week_clashes') is null then
    raise exception 'D108: week_clashes missing';
  end if;
  if not (select relrowsecurity from pg_class where oid = 'public.week_clashes'::regclass) then
    raise exception 'D108: RLS not enabled on week_clashes';
  end if;
  if not has_table_privilege('authenticated', 'public.week_clashes', 'select') then
    raise exception 'D108: authenticated lost SELECT on week_clashes';
  end if;
  if has_table_privilege('authenticated', 'public.week_clashes', 'insert')
     or has_table_privilege('authenticated', 'public.week_clashes', 'update')
     or has_table_privilege('authenticated', 'public.week_clashes', 'delete') then
    raise exception 'D108: authenticated holds a write privilege on week_clashes — all writes go through the tick';
  end if;
  if has_table_privilege('anon', 'public.week_clashes', 'select') then
    raise exception 'D108: anon can read week_clashes — anon holds ZERO relation privileges (D37)';
  end if;
  if has_function_privilege('authenticated', 'public.open_week_clash(uuid)', 'execute')
     or has_function_privilege('anon', 'public.open_week_clash(uuid)', 'execute')
     or has_function_privilege('authenticated', 'public.settle_week_clash(uuid,integer)', 'execute')
     or has_function_privilege('anon', 'public.settle_week_clash(uuid,integer)', 'execute')
     or has_function_privilege('authenticated', 'public.daily_season_tick()', 'execute')
     or has_function_privilege('anon', 'public.daily_season_tick()', 'execute') then
    raise exception 'D108: a clash engine function is client-callable';
  end if;
  if not exists (select 1 from pg_constraint
                  where conrelid = 'public.week_clashes'::regclass and contype = 'u') then
    raise exception 'D108: week_clashes lost unique (season_id, week_no)';
  end if;
  select prosrc into v_tick from pg_proc
   where proname = 'daily_season_tick'
     and pronamespace = 'public'::regnamespace;
  if position('settle_week_clash' in v_tick) = 0
     or position('open_week_clash' in v_tick) = 0 then
    raise exception 'D108: daily_season_tick is not wired to the clash';
  end if;
end $$;
