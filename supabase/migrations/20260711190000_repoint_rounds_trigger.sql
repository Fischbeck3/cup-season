-- ============================================================================
-- Cup Season — repoint rounds_before_insert to the 007 trigger function
--
-- Every rounds INSERT failed with: record "new" has no field
-- "allowance_at_post". Cause: rounds_before_insert still executed the
-- pre-007 rounds_compute(), which feeds the DROPPED column
-- allowance_at_post into score_round(7 args). Migration 007 shipped the
-- correct replacement — score_round() the 0-arg trigger version
-- (profile_id default, index_at_post snapshot, §2.1 differential incl.
-- 9-hole doubling) — but the trigger was never repointed to it.
--
-- Masked until v23.39: the missing window.sb bridge meant client round
-- posts never actually reached the database, so the broken trigger never
-- fired in the wild.
--
-- NOTE: post_live_round() (live-rounds feature, retired to roadmap) also
-- still inserts allowance_at_post + member_id into rounds and is equally
-- broken. It is unreachable from the current UI and will be rebuilt with
-- the live-rounds arc rather than patched here.
-- ============================================================================

drop trigger if exists rounds_before_insert on public.rounds;
create trigger rounds_before_insert
  before insert on public.rounds
  for each row execute function public.score_round();

-- dead after the repoint, and it references a nonexistent column — remove
-- so it can't mislead anyone again
drop function if exists public.rounds_compute();
