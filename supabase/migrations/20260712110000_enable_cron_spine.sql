-- ============================================================================
-- Cup Season — events engine workstream 1: the cron spine goes live
--
-- Workstream 0 (audit) PASSED 2026-07-12: close_month, snapshot_week,
-- daily_season_tick, enter_cup_final, close_season all exist in prod and
-- consume the 007-updated views (v_rounds_ranked, v_squad_standings,
-- v_individual_standings) — no stale column references in the chain.
--
-- Schedules are m006's design verbatim: Phoenix midnight-ish in UTC.
--   month close    1st @ 00:10 Phoenix (07:10 UTC)
--   week snapshot  Sun @ 00:10 Phoenix (07:10 UTC) -> standings_snapshots
--   daily tick     daily @ 00:20 Phoenix (07:20 UTC) -> cup-final window,
--                  grace-aware season close
--
-- Smoke test after push (run once in SQL editor, safe/idempotent):
--   select public.run_week_snapshots();
--   select * from standings_snapshots order by captured_at desc limit 3;
-- ============================================================================

create extension if not exists pg_cron;

select cron.schedule('cs-month-close',   '10 7 1 * *', $$select public.run_month_closes()$$);
select cron.schedule('cs-week-snapshot', '10 7 * * 0', $$select public.run_week_snapshots()$$);
select cron.schedule('cs-daily-tick',    '20 7 * * *', $$select public.daily_season_tick()$$);
