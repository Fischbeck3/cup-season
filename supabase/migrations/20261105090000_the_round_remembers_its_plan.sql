-- Cup Season — the round remembers its plan (D367 / F10 / F12).
--
-- WRITTEN, VALIDATED IN ISOLATION, AND NOT PUSHED. The owner pushes it.
--
-- Inbox 28 said it plainly: `rounds` carried no pointer to the plan it was
-- played on, and D345 declined to add the column "because a column nothing
-- writes is not a fix". This is the wave that writes it. Three facts the
-- clients have had to infer now travel as data:
--
--   1 · a LIVE round started from a booking remembers which booking —
--       `live_rounds.scheduled_round_id`, set by `start_live_round` when the
--       client names one (F10's "Tee it up"), and a partial unique index so
--       one golfer cannot start the same booking twice while one is live.
--       Server-authoritative: the client can retry as hard as it likes.
--   2 · a POSTED round remembers the booking it fulfilled —
--       `rounds.scheduled_round_id`, copied from the live round at finish.
--       Per golfer by construction, because a round belongs to one profile:
--       the host finishing links THEIR round, and nobody else's.
--   3 · `finish_live_round` says WHICH round it posted for whom —
--       `round_id` and `profile_id` on every posted card. Until now the
--       payload was {name, gross, holes}, so no client could open the
--       viewer's own receipt without guessing from a course label.
--
-- HOW THE FUNCTIONS ARE CHANGED. Both bodies are patched in place from
-- `pg_get_functiondef` — the precedent is 20261102090000 — so this file does
-- not retype 280 lines it did not write, and each anchor is asserted before
-- the replace: if the deployed body has drifted, the migration RAISES rather
-- than silently deploying a function that no longer does what this header
-- says. Nothing here changes a score, a point, or a post.

-- ── 1 · the columns ─────────────────────────────────────────────────────────
alter table public.live_rounds
  add column if not exists scheduled_round_id uuid references public.scheduled_rounds(id) on delete set null;
alter table public.rounds
  add column if not exists scheduled_round_id uuid references public.scheduled_rounds(id) on delete set null;

-- one live round per (booking, starter): a second "Tee it up" for the same
-- booking while one is live is refused by the index, not by a client flag
create unique index if not exists live_rounds_one_per_plan_and_starter
  on public.live_rounds (scheduled_round_id, starter_profile_id)
  where status = 'live' and scheduled_round_id is not null;

create index if not exists rounds_scheduled_round_idx
  on public.rounds (scheduled_round_id) where scheduled_round_id is not null;

-- ── 2 · start_live_round learns the booking ─────────────────────────────────
do $patch$
declare
  v_def text;
  v_old_sig text := 'p_config jsonb DEFAULT ''{}''::jsonb, p_api_course_id text DEFAULT NULL::text)';
  v_new_sig text := 'p_config jsonb DEFAULT ''{}''::jsonb, p_api_course_id text DEFAULT NULL::text, p_scheduled_round uuid DEFAULT NULL::uuid)';
  v_old_cols text := 'starter_profile_id, join_code, api_course_id)';
  v_new_cols text := 'starter_profile_id, join_code, api_course_id, scheduled_round_id)';
  v_old_vals text := 'nullif(trim(coalesce(p_api_course_id, '''')), ''''))';
  v_new_vals text := 'nullif(trim(coalesce(p_api_course_id, '''')), ''''), p_scheduled_round)';
begin
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'start_live_round';
  if v_def is null then raise exception 'start_live_round is missing'; end if;
  if position(v_old_sig in v_def) = 0 then raise exception 'start_live_round: signature anchor not found — body has drifted'; end if;
  if position(v_old_cols in v_def) = 0 then raise exception 'start_live_round: insert-columns anchor not found'; end if;
  if position(v_old_vals in v_def) = 0 then raise exception 'start_live_round: insert-values anchor not found'; end if;
  v_def := replace(v_def, v_old_sig, v_new_sig);
  v_def := replace(v_def, v_old_cols, v_new_cols);
  v_def := replace(v_def, v_old_vals, v_new_vals);
  -- the booking must be the caller's own, or one they were tagged on; a
  -- stranger's booking id is silently not linked rather than an error
  v_def := replace(v_def,
    'returning id into v_lr;',
    'returning id into v_lr;
  if p_scheduled_round is not null and not exists (
       select 1 from scheduled_rounds sr where sr.id = p_scheduled_round
          and (sr.profile_id = v or v = any(coalesce(sr.tagged, ''{}''::uuid[])))) then
    update live_rounds set scheduled_round_id = null where id = v_lr;
  end if;');
  execute v_def;
end
$patch$;

-- the OLD signature stays callable during deploy skew: an older client that
-- does not send p_scheduled_round is served by the default
revoke all on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb, text, uuid) from public, anon;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb, text, uuid) to authenticated;
-- the 9-arg overload is now shadowed by the 10-arg default; drop it so the
-- planner never sees an ambiguous call
drop function if exists public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb, text);

-- ── 3 · finish_live_round links the round and names it ──────────────────────
do $patch$
declare
  v_def text;
  -- both round inserts share this column list; the values differ
  v_old_cols text := 'source, attested, index_source_at_post, api_course_id, posted_by)';
  v_new_cols text := 'source, attested, index_source_at_post, api_course_id, posted_by, scheduled_round_id)';
  v_old_guest text := '''gross'', v_gross, ''holes'', v_holes);
      else';
  v_new_guest text := '''gross'', v_gross, ''holes'', v_holes,
          ''round_id'', v_round, ''profile_id'', v_pl.guest_profile_id);
      else';
  v_old_mine text := 'v_posted := v_posted || jsonb_build_object(''name'', playerlabel(v_pid), ''gross'', v_gross, ''holes'', v_holes);';
  v_new_mine text := 'v_posted := v_posted || jsonb_build_object(''name'', playerlabel(v_pid), ''gross'', v_gross, ''holes'', v_holes, ''round_id'', v_round, ''profile_id'', v_pid);';
  n int;
begin
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'finish_live_round';
  if v_def is null then raise exception 'finish_live_round is missing'; end if;
  n := (length(v_def) - length(replace(v_def, v_old_cols, ''))) / length(v_old_cols);
  if n <> 2 then raise exception 'finish_live_round: expected 2 round inserts, found %', n; end if;
  if position(v_old_guest in v_def) = 0 then raise exception 'finish_live_round: guest payload anchor not found'; end if;
  if position(v_old_mine in v_def) = 0 then raise exception 'finish_live_round: member payload anchor not found'; end if;
  v_def := replace(v_def, v_old_cols, v_new_cols);
  -- every values list closes with `lr.api_course_id, <posted_by>)` — append
  -- the live round's booking so the posted round remembers it
  n := (length(v_def) - length(replace(v_def, 'lr.api_course_id, v)', ''))) / length('lr.api_course_id, v)');
  if n <> 2 then raise exception 'finish_live_round: expected 2 values lists ending in posted_by, found %', n; end if;
  v_def := replace(v_def, 'lr.api_course_id, v)', 'lr.api_course_id, v, lr.scheduled_round_id)');
  v_def := replace(v_def, v_old_guest, v_new_guest);
  v_def := replace(v_def, v_old_mine, v_new_mine);
  execute v_def;
end
$patch$;

-- ── 4 · the self-check: read the deployed bodies back ───────────────────────
do $chk$
declare a text; b text;
begin
  select pg_get_functiondef(p.oid) into a from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'start_live_round';
  select pg_get_functiondef(p.oid) into b from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'finish_live_round';
  if position('p_scheduled_round' in a) = 0 then raise exception 'check: start_live_round did not take the booking'; end if;
  if position('''round_id'', v_round' in b) = 0 then raise exception 'check: finish_live_round does not name the round'; end if;
  if position('lr.scheduled_round_id' in b) = 0 then raise exception 'check: finish_live_round does not link the round'; end if;
  if not exists (select 1 from pg_indexes where indexname = 'live_rounds_one_per_plan_and_starter') then
    raise exception 'check: the one-live-per-booking index is missing'; end if;
end
$chk$;
