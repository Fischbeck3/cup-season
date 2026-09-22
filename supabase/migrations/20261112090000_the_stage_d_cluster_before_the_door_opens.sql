-- ============================================================================
-- Cup Season · 20261112090000 · the Stage D cluster, before the door opens
--
-- D378 (owner-ruled 2026-09-21, "address all items"; the entry is reserved in
-- docs/planning/2026-09-21-launch-rulings.md until PR #6 merges). The seven
-- items of the readiness audit's Stage D cluster, dispositioned:
--
--   (i)   the bands STAY for season one — a decision, recorded, nothing here;
--   (ii)  the verification dial is CLOSED as a stated norm — nothing here;
--   (iii) a member who left or is suspended keeps READ and loses the
--         consequential WRITES: `is_active_member(p_league)` on create_major,
--         enter_major and create_event — never inside is_league_member itself
--         (D197 ruling 1 keeps read for the suspended; D244 keeps the leaver's
--         name and rounds);
--   (iv)  a solo lock at one is D205's ruling — struck, nothing here;
--   (v)   `lock_league` refuses snake and live drafts with one sentence. The
--         engine (start_draft / make_pick / undo_pick) and the phone's
--         DraftNightScreen stay dormant for D54; the desk cannot pick, so a
--         league must not be able to land on them;
--   (vi)  the Cup Final keys on the LEAGUE'S date, not the server's UTC day:
--         daily_season_tick, enter_cup_final and cup_final_race.days_left read
--         `(now() at time zone se.timezone)::date` (D344 is the precedent;
--         `seasons.timezone` exists and defaults to America/Phoenix);
--   (vii) the weekly standings snapshot is cut on the league's own week
--         rollover, not on a fixed Sunday: snapshot_week numbers the week from
--         the league-local date and rides the daily tick (on conflict do
--         nothing makes every-tick calls exactly-once per completed week and
--         heals a missed day); the Sunday cron is unscheduled; home_dispatch's
--         hard-coded "since Sunday" becomes "this week".
--
-- HOW EVERY FUNCTION HERE IS CHANGED. Not by re-typing its body — home_dispatch
-- was last patched in place by 20261102090000 and its live text exists in no
-- migration file, so a copied body would silently roll a later change back
-- (the D144 lesson). Each patch below reads the LIVE definition with
-- pg_get_functiondef, asserts the exact text it expects to find, replaces it,
-- and executes the result; a body that has drifted raises instead of being
-- overwritten. Every patch is idempotent: it returns with a notice when the
-- new text is already present (CLAUDE.md, first landmine — a migration that
-- can run twice is cheap insurance).
--
-- VERIFY: `tests/sim/sandbox/apply.sh` on the full chain (never a "dry-run"
-- against the linked project); the self-check at the foot; db-checks 1 and 36
-- after the push. Client halves owed (D234): the phone's HomeFallbackItems
-- and both clients' season-story line still say "since Sunday" — listed in the
-- rulings packet as the copy half of (vii).
-- ============================================================================

-- ── (iii) · the helper ───────────────────────────────────────────────────────
create or replace function public.is_active_member(p_league uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from league_members
     where league_id = p_league
       and profile_id = auth.uid()
       and left_at is null
       and suspended_at is null);
$$;
revoke all on function public.is_active_member(uuid) from public, anon;
grant execute on function public.is_active_member(uuid) to authenticated;

-- ── (iii) · three write doors read the active helper ─────────────────────────
do $patch$
declare v_def text; v_new text; v_oid oid; v_n integer; fn text;
begin
  foreach fn in array array['create_major', 'enter_major', 'create_event'] loop
    select count(*) into v_n from pg_proc where proname = fn and pronamespace = 'public'::regnamespace;
    if v_n <> 1 then raise exception '[D378] % has % definitions; expected one', fn, v_n; end if;
    select oid into v_oid from pg_proc where proname = fn and pronamespace = 'public'::regnamespace;
    v_def := pg_get_functiondef(v_oid);
    if position('is_active_member(' in v_def) > 0 and position('is_league_member(' in v_def) = 0 then
      raise notice '[D378] % already reads is_active_member', fn; continue;
    end if;
    -- exactly one membership check per body, and it is the write gate
    if (length(v_def) - length(replace(v_def, 'is_league_member(', ''))) / length('is_league_member(') <> 1 then
      raise exception '[D378] % does not carry exactly one is_league_member( call', fn;
    end if;
    v_new := replace(v_def, 'is_league_member(', 'is_active_member(');
    execute v_new;
  end loop;
end $patch$;

-- ── (v) · lock_league refuses snake and live ─────────────────────────────────
do $patch$
declare v_def text; v_new text; v_before text; v_oid oid; v_n integer;
begin
  select count(*) into v_n from pg_proc where proname = 'lock_league' and pronamespace = 'public'::regnamespace;
  if v_n <> 1 then raise exception '[D378] lock_league has % definitions; expected one (D347)', v_n; end if;
  select oid into v_oid from pg_proc where proname = 'lock_league' and pronamespace = 'public'::regnamespace;
  v_def := pg_get_functiondef(v_oid);
  if position('Squads are drawn or placed by the Pro this season.' in v_def) > 0 then
    raise notice '[D378] lock_league already refuses snake/live'; return;
  end if;
  v_before := v_def;
  v_new := replace(v_def,
    '  v_starts := coalesce(p_starts_on, current_date);',
    '  -- D378 · snake and live drafts are offered by neither wizard and the desk
  -- cannot pick in them; a stored or hand-sent value is refused here until it
  -- can. The engine stays dormant for D54, not deleted. Placed AFTER the
  -- already-locked return so a re-lock of a legacy row still answers honestly.
  if coalesce(p_draft_type, v_settings.draft_type, ''random'') in (''snake'', ''live'') then
    raise exception ''Squads are drawn or placed by the Pro this season.'';
  end if;

  v_starts := coalesce(p_starts_on, current_date);');
  if v_new = v_before then raise exception '[D378] lock_league: the v_starts line was not found'; end if;
  execute v_new;
end $patch$;

-- ── (vi) + (vii) · the tick keys on the league's date and cuts the week ─────
do $patch$
declare v_def text; v_new text; v_before text;
begin
  v_def := pg_get_functiondef('public.daily_season_tick()'::regprocedure);
  if position('perform snapshot_week(se.id);' in v_def) > 0
     and position('and current_date >= se.ends_on - 27 then' in v_def) = 0 then
    raise notice '[D378] daily_season_tick already patched'; return;
  end if;

  -- (vi) the Final opens on the league's day
  v_before := v_def;
  v_new := replace(v_def,
    'and current_date >= se.ends_on - 27 then',
    'and v_local >= se.ends_on - 27 then');
  if v_new = v_before then raise exception '[D378] daily_season_tick: the Final window test was not found'; end if;

  -- (vii) the week's table rides the tick
  v_before := v_new;
  v_new := replace(v_new,
    '    perform clash_last_call(se.id);',
    '    perform clash_last_call(se.id);
    -- D378 · the week''s table is cut on the league''s own week rollover, not
    -- on a fixed Sunday. snapshot_week numbers the week from the league-local
    -- date and inserts on conflict do nothing, so calling it on every tick
    -- writes exactly one row per completed week — the first tick on or after
    -- the rollover — and heals a missed day the way the clash does.
    perform snapshot_week(se.id);');
  if v_new = v_before then raise exception '[D378] daily_season_tick: clash_last_call was not found'; end if;
  execute v_new;
end $patch$;

-- ── (vi) · enter_cup_final ───────────────────────────────────────────────────
do $patch$
declare v_def text; v_new text;
begin
  v_def := pg_get_functiondef('public.enter_cup_final(uuid)'::regprocedure);
  if position('if current_date < se.ends_on - 27 then return; end if;' in v_def) = 0 then
    if position('at time zone se.timezone)::date < se.ends_on - 27' in v_def) > 0 then
      raise notice '[D378] enter_cup_final already patched'; return;
    end if;
    raise exception '[D378] enter_cup_final: the window test was not found';
  end if;
  v_new := replace(v_def,
    'if current_date < se.ends_on - 27 then return; end if;',
    'if (now() at time zone se.timezone)::date < se.ends_on - 27 then return; end if;');
  execute v_new;
end $patch$;

-- ── (vi) · cup_final_race.days_left ──────────────────────────────────────────
do $patch$
declare v_def text; v_new text;
begin
  v_def := pg_get_functiondef('public.cup_final_race(uuid)'::regprocedure);
  if position('greatest(0, se.ends_on - current_date)' in v_def) = 0 then
    if position('se.ends_on - (now() at time zone se.timezone)::date' in v_def) > 0 then
      raise notice '[D378] cup_final_race already patched'; return;
    end if;
    raise exception '[D378] cup_final_race: days_left was not found';
  end if;
  v_new := replace(v_def,
    'greatest(0, se.ends_on - current_date)',
    'greatest(0, se.ends_on - (now() at time zone se.timezone)::date)');
  if position('current_date' in v_new) > 0 then
    raise exception '[D378] cup_final_race still reads current_date somewhere else';
  end if;
  execute v_new;
end $patch$;

-- ── (vii) · snapshot_week numbers the week from the league's date ────────────
do $patch$
declare v_def text; v_new text; v_before text;
begin
  v_def := pg_get_functiondef('public.snapshot_week(uuid)'::regprocedure);
  if position('v_local := (now() at time zone se.timezone)::date;' in v_def) > 0 then
    raise notice '[D378] snapshot_week already patched'; return;
  end if;
  v_before := v_def;
  v_new := replace(v_def,
    'declare se record; wk integer; total_wk integer; payload jsonb;',
    'declare se record; wk integer; total_wk integer; payload jsonb; v_local date;');
  if v_new = v_before then raise exception '[D378] snapshot_week: the declare line was not found'; end if;
  v_before := v_new;
  v_new := replace(v_new,
    '  if current_date <= se.starts_on then return; end if;',
    '  -- D378 · the league''s own date, so a Monday league''s week ends on Sunday
  -- night in Phoenix, not at 07:10 UTC on a fixed weekday.
  v_local := (now() at time zone se.timezone)::date;
  if v_local <= se.starts_on then return; end if;');
  if v_new = v_before then raise exception '[D378] snapshot_week: the starts_on guard was not found'; end if;
  v_before := v_new;
  v_new := replace(v_new,
    'floor((current_date - se.starts_on) / 7.0)',
    'floor((v_local - se.starts_on) / 7.0)');
  if v_new = v_before then raise exception '[D378] snapshot_week: the week arithmetic was not found'; end if;
  if position('current_date' in v_new) > 0 then
    raise exception '[D378] snapshot_week still reads current_date somewhere else';
  end if;
  execute v_new;
end $patch$;

-- ── (vii) · home_dispatch says "this week" ───────────────────────────────────
do $patch$
declare v_def text; v_new text; v_before text; v_oid oid; v_n integer;
begin
  select count(*) into v_n from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_n <> 1 then raise exception '[D378] home_dispatch has % definitions; expected the one three-argument shape (D345)', v_n; end if;
  select oid into v_oid from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  v_def := pg_get_functiondef(v_oid);
  if position('since Sunday' in v_def) = 0 then
    raise notice '[D378] home_dispatch already says this week'; return;
  end if;
  v_before := v_def;
  v_new := replace(v_def, '|| '' since Sunday.''', '|| '' this week.''');
  if v_new = v_before then raise exception '[D378] home_dispatch: the moved-up sentence was not found'; end if;
  v_before := v_new;
  v_new := replace(v_new, '''You were passed since Sunday.''', '''You were passed this week.''');
  if v_new = v_before then raise exception '[D378] home_dispatch: the passed sentence was not found'; end if;
  v_before := v_new;
  v_new := replace(v_new,
    '-- A-4: `prev_rank` is a SUNDAY snapshot, so the movement is stated',
    '-- A-4: `prev_rank` is the table cut when the league week rolled over (D378), so the movement is stated');
  if v_new = v_before then raise exception '[D378] home_dispatch: the A-4 comment was not found'; end if;
  v_before := v_new;
  v_new := replace(v_new,
    '-- "since Sunday" or it is not stated at all.',
    '-- "this week" or it is not stated at all.');
  if v_new = v_before then raise exception '[D378] home_dispatch: the A-4 second line was not found'; end if;
  if position('since Sunday' in v_new) > 0 then
    raise exception '[D378] home_dispatch still says since Sunday somewhere else';
  end if;
  execute v_new;
end $patch$;

-- ── (vii) · the Sunday cron retires; the tick carries the snapshot ───────────
-- Guarded on the cron.job relation, not on the pg_cron extension row: the
-- sandbox harness stubs cron.* without the extension, and the guard must hold
-- there too or the sandbox keeps a job production has lost.
do $cron$
begin
  if to_regclass('cron.job') is not null
     and exists (select 1 from cron.job where jobname = 'cs-week-snapshot') then
    perform cron.unschedule('cs-week-snapshot');
  end if;
end $cron$;
-- run_week_snapshots() stays defined and engine-only; nothing schedules it.

-- ── self-check (read-only; mutates no row) ───────────────────────────────────
do $chk$
declare v_src text; fn text;
begin
  foreach fn in array array['create_major', 'enter_major', 'create_event'] loop
    select prosrc into v_src from pg_proc where proname = fn and pronamespace = 'public'::regnamespace;
    if v_src like '%is_league_member(%' or v_src not like '%is_active_member(%' then
      raise exception '[D378] % still gates on is_league_member', fn;
    end if;
  end loop;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = 'is_active_member'
                    and has_function_privilege('authenticated', p.oid, 'execute')
                    and not has_function_privilege('anon', p.oid, 'execute')) then
    raise exception '[D378] is_active_member is missing or wrongly granted';
  end if;
  select prosrc into v_src from pg_proc where proname = 'is_league_member' and pronamespace = 'public'::regnamespace;
  if v_src like '%left_at%' or v_src like '%suspended_at%' then
    raise exception '[D378] is_league_member must keep READ for leavers and the suspended (D197 R1, D244)';
  end if;

  select prosrc into v_src from pg_proc where proname = 'lock_league' and pronamespace = 'public'::regnamespace;
  if v_src not like '%Squads are drawn or placed by the Pro this season.%' then
    raise exception '[D378] lock_league does not refuse snake/live';
  end if;
  if position('counting_cap        = p_counting_cap' in v_src) = 0
     or position('participation_floor = coalesce(p_participation_floor' in v_src) = 0 then
    raise exception '[D378] lock_league lost a D347 line while being patched';
  end if;

  select prosrc into v_src from pg_proc where proname = 'daily_season_tick' and pronamespace = 'public'::regnamespace;
  if v_src like '%current_date >= se.ends_on - 27%' or v_src not like '%v_local >= se.ends_on - 27%' then
    raise exception '[D378] the tick still opens the Final on the UTC day';
  end if;
  if v_src not like '%perform snapshot_week(se.id);%' then
    raise exception '[D378] the tick does not cut the week';
  end if;
  if v_src not like '%perform clash_last_call(se.id);%' or v_src not like '%job_failures%' then
    raise exception '[D378] the tick lost a line while being patched';
  end if;

  select prosrc into v_src from pg_proc where proname = 'enter_cup_final' and pronamespace = 'public'::regnamespace;
  if v_src like '%current_date%' then raise exception '[D378] enter_cup_final still reads current_date'; end if;
  select prosrc into v_src from pg_proc where proname = 'cup_final_race' and pronamespace = 'public'::regnamespace;
  if v_src like '%current_date%' then raise exception '[D378] cup_final_race still reads current_date'; end if;
  select prosrc into v_src from pg_proc where proname = 'snapshot_week' and pronamespace = 'public'::regnamespace;
  if v_src like '%current_date%' or v_src not like '%post_week_comeback(p_season, wk)%' then
    raise exception '[D378] snapshot_week is wrong: % current_date, comeback kept: %',
      (v_src like '%current_date%'), (v_src like '%post_week_comeback(p_season, wk)%');
  end if;

  select prosrc into v_src from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace;
  if v_src like '%since Sunday%' or v_src not like '%this week.%' or v_src not like '%afterplan.v1%' then
    raise exception '[D378] home_dispatch: since Sunday remains, or the D345 gate was lost';
  end if;

  if to_regclass('cron.job') is not null
     and exists (select 1 from cron.job where jobname = 'cs-week-snapshot') then
    raise exception '[D378] cs-week-snapshot is still scheduled';
  end if;
  if to_regclass('cron.job') is not null
     and not exists (select 1 from cron.job where jobname = 'cs-daily-tick') then
    raise exception '[D378] cs-daily-tick is gone — the snapshot has no carrier';
  end if;
end $chk$;
