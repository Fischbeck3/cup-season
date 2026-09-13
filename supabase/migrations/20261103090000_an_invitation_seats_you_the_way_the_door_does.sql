-- D356 · an invitation seats you the way every other door seats you.
--
-- ONE DEFECT, found by reading the four doors into a Major against each other
-- rather than each one alone. A second candidate was investigated and is left
-- alone; the reason is below, because a rejected finding is worth as much as a
-- fixed one.
--
-- ── 1 · a Major invitation seats a full contender, whatever the rule says ──
--
-- `major_contender(profile)` is `handicap_index(profile) is not null`, which is
-- null until three differential-carrying rounds. Both clients print the rule in
-- the room: "An established number (3 posted rounds) plays for the jug."
--
-- Three of the four doors into a Major honour it:
--   `create_major`      sets `exhibition` (20260724100000:141)
--   `enter_major`       sets `exhibition` (20261012090000:2265)
--   `add_event_player`  sets `exhibition` (20260720193000:267)
--   `respond_invite`    inserts (event_id, profile_id, seed) and NOTHING ELSE
--
-- `event_players.exhibition` defaults to false, so a golfer who ACCEPTS an
-- invitation is seated as a full contender no matter how few rounds they have
-- posted — ranked for the jug by `settle_major` and counted into the pot. There
-- is no trigger and no backfill that repairs it afterwards.
--
-- It is LATENT today, not live: production has no Major and no accepted event
-- invitation (checked read-only, 2026-09-13). It is fixed forward rather than
-- backfilled, because there is nothing to backfill.
--
-- Exhibition is a Major idea. A Ryder seat keeps the column's default, because
-- a Ryder has no established-number rule at all — which is its own finding, and
-- a copy question rather than a SQL one.
--
-- A SECOND CANDIDATE WAS INVESTIGATED AND DELIBERATELY NOT CHANGED.
-- `run_it_back` decides whether the terms moved with
--     v_length_moved := v_months is distinct from v_settings.season_months;
-- and `v_months` is always a real number by that line, so a NULL on the right
-- would compare as "distinct from", fire the covenant refire, set every
-- member's invitation back to `pending` and announce "The length changed" when
-- nothing had. It reads like a defect and it was reported as one.
--
-- It is UNREACHABLE. `league_settings.season_months` is `integer DEFAULT 9 NOT
-- NULL` in the initial baseline (`00000000000000_initial_baseline.sql:1083`)
-- and no migration has ever relaxed it, so the column cannot hold a NULL. The
-- comparison is correct for every value the column can take. Proven by trying:
-- `update league_settings set season_months = null` is refused by the
-- constraint (`tests/events-consent-database.py`).
--
-- So `run_it_back` is left alone. Replacing a live function to guard a state
-- its own schema forbids is churn with risk and no benefit.
--
-- `respond_invite` keeps its signature, so this is `create or replace` with no
-- overload and no discarded ACL. The body is read from the deployed
-- definition and patched with ASSERTED replacements — a blob would silently
-- overwrite drift; an assertion that raises cannot. Idempotent: a second run
-- finds the fix already present and does nothing.
--
-- Nothing here changes eligibility, scoring, a pot, a payout or who may enter.
-- It makes one existing door behave the way the other three already do.

-- ── 1 · respond_invite ─────────────────────────────────────────────────────

do $patch$
declare v_def text; v_new text;
begin
  select pg_get_functiondef(oid) into v_def
    from pg_proc where proname = 'respond_invite' and pronamespace = 'public'::regnamespace;
  if v_def is null then raise exception 'respond_invite is not deployed'; end if;

  if position('major_contender' in v_def) > 0 then
    raise notice 'respond_invite already seats a Major invitee by the rule; nothing to patch';
  else
    v_new := replace(v_def,
      '      insert into event_players (event_id, profile_id, seed)
        values (mi.event_id, auth.uid(),
                coalesce((select max(seed)+1 from event_players where event_id=mi.event_id), 0))
        on conflict (event_id, profile_id) do nothing;',
      '      -- D356 · seat them the way every other door does. A Major ranks
      -- only established numbers for the jug, and this door used to let the
      -- column''s default (false) make anyone a contender.
      insert into event_players (event_id, profile_id, seed, exhibition)
        values (mi.event_id, auth.uid(),
                coalesce((select max(seed)+1 from event_players where event_id=mi.event_id), 0),
                (select e.kind = ''major'' and not major_contender(auth.uid())
                   from events e where e.id = mi.event_id))
        on conflict (event_id, profile_id) do nothing;');
    if v_new = v_def then raise exception 'patch 1: the event seat insert was not found in respond_invite'; end if;
    execute v_new;
  end if;
end $patch$;

revoke all on function public.respond_invite(uuid, boolean) from public, anon;
grant execute on function public.respond_invite(uuid, boolean) to authenticated;

-- ── 2 · read-only self-check. Raises rather than reporting success. ────────

do $check$
declare n int; v text;
begin
  select count(*) into n from pg_proc
   where proname = 'respond_invite' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'respond_invite must resolve to exactly one function, found %', n; end if;

  select pg_get_functiondef(oid) into v from pg_proc
   where proname = 'respond_invite' and pronamespace = 'public'::regnamespace;
  if position('major_contender' in v) = 0 then
    raise exception 'respond_invite still seats a Major invitee as a contender by default';
  end if;
  -- the league branch, the decline branch and the acceptance write must survive
  if position('is_league_member' in v) = 0 and position('league_members' in v) = 0 then
    raise exception 'respond_invite lost its league branch';
  end if;
  if position('status=''declined''' in v) = 0 then raise exception 'respond_invite lost its decline'; end if;
  if position('status=''accepted''' in v) = 0 then raise exception 'respond_invite lost its acceptance'; end if;

  if has_function_privilege('anon', 'public.respond_invite(uuid, boolean)', 'execute') then
    raise exception 'anon must not execute respond_invite';
  end if;
  if not has_function_privilege('authenticated', 'public.respond_invite(uuid, boolean)', 'execute') then
    raise exception 'authenticated must execute respond_invite';
  end if;
end $check$;
