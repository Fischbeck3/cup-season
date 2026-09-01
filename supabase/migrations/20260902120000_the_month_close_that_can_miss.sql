-- ============================================================================
-- Cup Season — the month close survives a bad league, and can catch up
--
-- OWNER'S RULING, 2026-09-01: isolate per league and add a catch-up.
--
-- `run_month_closes` fires at 07:10 on the 1st and is a bare `for … loop`, so
-- the whole batch is one transaction: one league that raises rolls back the
-- month close for EVERY league. It has no retry and no catch-up, so a single
-- failure permanently loses that month's floor penalties, auto-byes and
-- bonuses across the product — and the ledger behind those is real money.
-- D193 fixed `run_event_sessions` this way and deliberately left this one,
-- because how a money path handles partial failure is a decision, not a patch.
--
-- The decision is safe SPECIFICALLY because `close_month()` is idempotent, and
-- that was verified rather than assumed: its first statement returns early if a
-- `month_closed` sentinel already exists for that season and month with
-- `created_by is null`. So a month that is already closed costs one indexed
-- lookup, and a month that was missed can simply be attempted again.
--
-- That inverts the usual argument. Without idempotency, "skip the bad league
-- and continue" leaves a half-closed month nobody can safely re-run, and
-- refusing the whole month would be the more conservative call. With it,
-- isolation is strictly better: twelve leagues no longer lose their month to
-- one league's bug, and the league that failed is recoverable on the next tick
-- instead of being lost for good.
--
-- CATCH-UP: each season now attempts the last three months rather than only
-- the one that just ended, bounded below by the month the season started. Two
-- consecutive failures — or a month when nobody noticed pg_cron was paused —
-- heal themselves on the next run. Three is chosen so a quarter cannot silently
-- vanish while staying far short of replaying a whole season every month.
--
-- `run_week_snapshots` gets isolation but NOT catch-up: `snapshot_week()` has
-- no equivalent sentinel, so re-running it is not known to be safe, and a
-- missed weekly snapshot costs a chart row rather than a ledger entry.
-- Isolating it is honest; retrying it would be a guess.
-- ============================================================================

create or replace function public.run_month_closes()
returns void language plpgsql security definer set search_path = public as $fn$
declare se record; v_month date; i int; v_state text; v_msg text; v_first date;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    v_first := date_trunc('month', se.starts_on)::date;
    -- the month that just ended, then the two before it (catch-up)
    for i in 1..3 loop
      v_month := (date_trunc('month', current_date) - (i || ' month')::interval)::date;
      exit when v_month < v_first;
      begin
        perform close_month(se.id, v_month);
      exception when others then
        get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
        insert into job_failures (job, subject, sqlstate, message)
        values ('run_month_closes',
                'season ' || se.id::text || ' month ' || v_month::text,
                v_state, v_msg);
        -- and on to the next month / the next league. A league that cannot
        -- close must not close the book on anybody else's.
      end;
    end loop;
  end loop;
end $fn$;

create or replace function public.run_week_snapshots()
returns void language plpgsql security definer set search_path = public as $fn$
declare se record; v_state text; v_msg text;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    begin
      perform snapshot_week(se.id);
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
      insert into job_failures (job, subject, sqlstate, message)
      values ('run_week_snapshots', 'season ' || se.id::text, v_state, v_msg);
    end;
  end loop;
end $fn$;

do $$
declare s text;
begin
  select prosrc into s from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname='public' and p.proname='run_month_closes';
  if s not like '%job_failures%' then
    raise exception '[cron] run_month_closes still takes the whole batch down with one league';
  end if;
  if s not like '%1..3%' then
    raise exception '[cron] run_month_closes has no catch-up window';
  end if;
  select prosrc into s from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname='public' and p.proname='run_week_snapshots';
  if s not like '%job_failures%' then
    raise exception '[cron] run_week_snapshots is still un-isolated';
  end if;
end $$;
