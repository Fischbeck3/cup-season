-- ============================================================================
-- Cup Season — migration 006
-- Sunday seasons (spec §14.0) server-side + pass-two items
--
--   1. payout_split bylaw          (60/25/15 default, must sum 100)
--   2. close_month() rewrite:
--        a. blanket partial-month floor WAIVER  (§14.0 — edge months)
--        b. FORFEIT penalty implemented          (was a stub in m003)
--        c. month_closed sentinel → true idempotence + "MONTH CLOSED" post (§14.2)
--   3. standings_snapshots + weekly snapshot job  (Week Review browser)
--   4. cup_finalists seed capture + status flip active → cup_final
--        (fresh-slate CROWNING deliberately deferred to migration 007)
--   5. wrappers + pg_cron block (commented — enable pg_cron first)
--
-- Verified against live schema pulls (A23-30 / B23-30):
--   seasons.starts_on/ends_on = date · season_adjustments.month = date
--   league_settings.floor_penalty = text ('none'/'deduct'/'forfeit')
--   v_rounds_ranked exposes member_id, season_id, played_on, points,
--   month_rank, floor_credit — all used below exactly as m003 used them.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1 · PAYOUT SPLIT (spec §7 / §11 pass two)
-- Three integer shares; constraint enforces the spec's "must sum 100".
-- ----------------------------------------------------------------------------
alter table league_settings
  add column if not exists payout_champ    integer not null default 60,
  add column if not exists payout_runnerup integer not null default 25,
  add column if not exists payout_king     integer not null default 15;

do $$ begin
  alter table league_settings
    add constraint payout_sums_100
    check (payout_champ + payout_runnerup + payout_king = 100);
exception when duplicate_object then null; end $$;


-- ----------------------------------------------------------------------------
-- 2 · close_month() — full replacement (functions replace wholesale)
-- m003 logic preserved verbatim except the four marked changes.
-- ----------------------------------------------------------------------------
create or replace function public.close_month(p_season uuid, p_month date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare st record; se record; m record; short numeric; delta int;
        winner uuid; best int;
        is_partial boolean;
        month_last date;
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;

  -- CHANGE 2c · idempotence now keys on a month_closed sentinel, so a month
  -- with zero penalties and no hybrid bonus still closes exactly once.
  if exists (select 1 from season_adjustments
             where season_id = p_season and month = p_month
               and kind = 'month_closed' and created_by is null) then
    return;
  end if;

  -- CHANGE 2a · blanket partial-month detection (spec §14.0):
  -- a month is partial if the season starts after its 1st, or ends before
  -- its last day. Floors are WAIVED for everyone in partial edge months —
  -- the same grace late joiners get.
  month_last := (p_month + interval '1 month' - interval '1 day')::date;
  is_partial := (se.starts_on > p_month) or (se.ends_on < month_last);

  -- 1 · floor penalties — deduct AND forfeit (CHANGE 2b), skipped when waived
  if st.participation_floor > 0
     and st.floor_penalty in ('deduct','forfeit')
     and not is_partial then
    for m in
      select sm.squad_id, sm.member_id,
             coalesce(sum(rr.floor_credit),0) as credits,
             coalesce(sum(rr.points)
               filter (where rr.month_rank <= coalesce(st.counting_cap,999)),0)
               as counting_pts
      from squad_members sm
      join squads s on s.id = sm.squad_id and s.season_id = p_season
      left join v_rounds_ranked rr
        on rr.member_id = sm.member_id
       and rr.season_id = p_season
       and date_trunc('month', rr.played_on) = p_month
      where not exists (select 1 from season_adjustments b
                        where b.season_id = p_season and b.member_id = sm.member_id
                          and b.month = p_month and b.kind = 'bye')
      group by sm.squad_id, sm.member_id
    loop
      short := greatest(0, st.participation_floor - m.credits);
      if short > 0 then
        if st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  'Floor '||st.participation_floor||'/mo — posted '||m.credits);
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  'FLOOR MISSED — '||abs(delta)||' PTS OFF THE BOARD');
        else  -- forfeit: negate the month's counting points (§3.2 Cutthroat)
          if m.counting_pts > 0 then
            insert into season_adjustments
              (season_id, squad_id, member_id, month, kind, points, reason)
            values (p_season, m.squad_id, m.member_id, p_month, 'floor_forfeit',
                    -m.counting_pts,
                    'Floor '||st.participation_floor||'/mo — posted '||m.credits
                    ||' · month forfeited');
            insert into posts (league_id, season_id, kind, body)
            values (se.league_id, p_season, 'system',
                    'MONTH FORFEITED — '||m.counting_pts||' PTS STRUCK');
          end if;
        end if;
      end if;
    end loop;
  end if;

  -- 2 · hybrid matchup bonus (unchanged from m003)
  -- NOTE: still awarded in partial edge months — §14.0 only waives floors.
  -- Flagged as a spec question; revisit in v1.1 / migration 007 if desired.
  if st.season_format = 'hybrid' then
    select s.id into winner
    from squads s
    left join squad_members sm on sm.squad_id = s.id
    left join v_rounds_ranked rr
      on rr.member_id = sm.member_id and rr.season_id = p_season
     and date_trunc('month', rr.played_on) = p_month
     and rr.month_rank <= coalesce(st.counting_cap, 999)
    where s.season_id = p_season
    group by s.id
    order by coalesce(sum(rr.points),0) desc
    limit 1;
    if winner is not null then
      insert into season_adjustments
        (season_id, squad_id, month, kind, points, reason)
      values (p_season, winner, p_month, 'matchup_bonus', 15,
              'Monthly head-to-head winner');
      insert into posts (league_id, season_id, kind, body)
      select se.league_id, p_season, 'system',
             upper(name)||' TAKE THE MONTHLY +15'
      from squads where id = winner;
    end if;
  end if;

  -- 3 · CHANGE 2c · sentinel + the §14.2 "month closed" board event
  insert into season_adjustments
    (season_id, month, kind, points, reason)
  values (p_season, p_month, 'month_closed', 0,
          case when is_partial then 'Partial edge month — floors waived'
               else 'Month closed' end);
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          upper(to_char(p_month,'FMMonth'))||' CLOSED — LEDGER POSTED'
          || case when is_partial then ' · PARTIAL MONTH, FLOORS WAIVED' else '' end);
end $function$;


-- ----------------------------------------------------------------------------
-- 3 · WEEKLY STANDINGS SNAPSHOTS (Week Review browser, §14.0)
-- ----------------------------------------------------------------------------
create table if not exists standings_snapshots (
  id          uuid primary key default gen_random_uuid(),
  season_id   uuid not null references seasons(id) on delete cascade,
  week_no     integer not null,
  captured_at timestamptz not null default now(),
  standings   jsonb not null,
  unique (season_id, week_no)
);

alter table standings_snapshots enable row level security;

-- Read: any member of the season's league. Writes happen only inside
-- security-definer functions, so no insert/update policies are granted.
do $$ begin
  create policy snapshots_member_read on standings_snapshots
    for select using (
      exists (select 1 from seasons se
              where se.id = standings_snapshots.season_id
                and is_league_member(se.league_id))
    );
exception when duplicate_object then null; end $$;

-- Snapshot the most recently COMPLETED week (Sunday-start weeks, §14.0).
-- Run Sunday 00:10 local: (current_date - starts_on) is then a multiple of 7
-- and week_no lands on the week that ended Saturday night. Idempotent via
-- the unique constraint + on conflict.
create or replace function public.snapshot_week(p_season uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare se record; wk integer; total_wk integer; payload jsonb;
begin
  select * into se from seasons where id = p_season;
  if se.status not in ('active','cup_final') then return; end if;
  if current_date <= se.starts_on then return; end if;

  total_wk := ceil((se.ends_on - se.starts_on + 1) / 7.0);
  wk := least(total_wk, floor((current_date - se.starts_on) / 7.0));
  if wk < 1 then return; end if;

  payload := jsonb_build_object(
    'squads', coalesce((
        select jsonb_agg(to_jsonb(t))
        from (select * from v_squad_standings
              where season_id = p_season order by points desc) t), '[]'::jsonb),
    'individuals', coalesce((
        select jsonb_agg(to_jsonb(t))
        from (select * from v_individual_standings
              where season_id = p_season order by points desc nulls last) t), '[]'::jsonb)
  );

  insert into standings_snapshots (season_id, week_no, standings)
  values (p_season, wk, payload)
  on conflict (season_id, week_no) do nothing;
end $function$;


-- ----------------------------------------------------------------------------
-- 4 · CUP FINAL — seed capture + status flip (crowning logic → migration 007)
-- The Final = the last four weeks, scored fresh (§14.0/§14.3). Seeds lock the
-- moment the window opens; close_season still crowns by season total until
-- 007 replaces it (acceptable pre-launch — no live Final exists yet).
-- ----------------------------------------------------------------------------
create table if not exists cup_finalists (
  id         uuid primary key default gen_random_uuid(),
  season_id  uuid not null references seasons(id) on delete cascade,
  squad_id   uuid references squads(id) on delete cascade,
  member_id  uuid references league_members(id) on delete cascade,
  seed       integer not null,
  head_start integer not null default 0,   -- +10 for 2-squad leader (§8)
  locked_at  timestamptz not null default now(),
  unique (season_id, seed),
  check (squad_id is not null or member_id is not null)
);

alter table cup_finalists enable row level security;

do $$ begin
  create policy finalists_member_read on cup_finalists
    for select using (
      exists (select 1 from seasons se
              where se.id = cup_finalists.season_id
                and is_league_member(se.league_id))
    );
exception when duplicate_object then null; end $$;

create or replace function public.enter_cup_final(p_season uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare se record; st record; n integer := 0; r record;
begin
  select * into se from seasons where id = p_season;
  if se.status <> 'active' then return; end if;                 -- idempotent
  if current_date < se.ends_on - 27 then return; end if;        -- window not open

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;

  if st.structure = 'solo' then
    for r in select member_id from v_individual_standings
             where season_id = p_season
             order by points desc nulls last limit 2
    loop
      n := n + 1;
      insert into cup_finalists (season_id, member_id, seed)
      values (p_season, r.member_id, n);
    end loop;
  else
    for r in select squad_id from v_squad_standings
             where season_id = p_season
             order by points desc limit 2
    loop
      n := n + 1;
      insert into cup_finalists (season_id, squad_id, seed, head_start)
      values (p_season, r.squad_id, n,
              case when st.structure = 'squads2' and n = 1 then 10 else 0 end);
    end loop;
  end if;

  update seasons set status = 'cup_final' where id = p_season;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'THE CUP FINAL IS LIVE — FRESH SLATE, FOUR WEEKS. SEEDS ARE LOCKED.');
end $function$;


-- ----------------------------------------------------------------------------
-- 5 · SCHEDULER WRAPPERS + CRON (commented — enable pg_cron extension first)
-- daily_season_tick() also absorbs m003's commented "season close, grace-aware"
-- job; use THIS block when enabling, not m003's.
-- ----------------------------------------------------------------------------
create or replace function public.run_month_closes()
returns void language plpgsql security definer set search_path to 'public'
as $function$
declare se record;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- close the month that just ended (job runs on the 1st, local ~00:10)
    perform close_month(se.id,
      (date_trunc('month', current_date) - interval '1 month')::date);
  end loop;
end $function$;

create or replace function public.run_week_snapshots()
returns void language plpgsql security definer set search_path to 'public'
as $function$
declare se record;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    perform snapshot_week(se.id);
  end loop;
end $function$;

create or replace function public.daily_season_tick()
returns void language plpgsql security definer set search_path to 'public'
as $function$
declare se record;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- open the Cup Final window at ends_on − 27 (a Sunday, seasons end Saturday)
    if se.status = 'active' and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    -- grace-aware season close: final day + 48h (seasons.grace_hours), local tz
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;
  end loop;
end $function$;

-- After: create extension if not exists pg_cron;
-- select cron.schedule('cs-month-close',   '10 7 1 * *', $$select run_month_closes()$$);
-- select cron.schedule('cs-week-snapshot', '10 7 * * 0', $$select run_week_snapshots()$$);
-- select cron.schedule('cs-daily-tick',    '20 7 * * *', $$select daily_season_tick()$$);
-- (07:10 / 07:20 UTC ≈ 00:10 / 00:20 America/Phoenix, no DST)


-- ----------------------------------------------------------------------------
-- VERIFICATION (run after; all should succeed / return sane rows)
-- ----------------------------------------------------------------------------
-- select payout_champ, payout_runnerup, payout_king from league_settings limit 3;
-- select proname from pg_proc where proname in
--   ('close_month','snapshot_week','enter_cup_final','run_month_closes',
--    'run_week_snapshots','daily_season_tick');
-- select * from standings_snapshots limit 1;
-- select * from cup_finalists limit 1;
-- -- dry-run a close on a test season (idempotent — safe to repeat):
-- -- select close_month('<season-uuid>', (date_trunc('month', current_date) - interval '1 month')::date);
