-- ============================================================================
-- v_event_scoreboard reads as its READER — the last definer-style view closed
-- (D37 posture; finishes what 20260724150000 started, 2026-07-24).
--
-- 20260724150000 attacked the GRANT layer: revoke anon's relation privileges,
-- so the anonymous PostgREST read of the scoreboard dies. It deliberately left
-- the view's EXECUTION MODE alone. That leaves the hole half-closed:
--
--   v_event_scoreboard carries no security_invoker, so it runs as its owner
--   (postgres — owner of event_duels and event_players, and no table sets FORCE
--   ROW LEVEL SECURITY, so owner reads skip RLS entirely). It is granted to
--   `authenticated`. Net: ANY signed-in user can read EVERY event's team totals
--   (event_id, team_id, points) cross-league, participant or not, by asking
--   PostgREST directly. Aggregate-only, and event UUIDs are unguessable — but
--   it is a read no policy ever authorized, and it is the odd one out:
--   v_rounds_ranked, v_individual_standings and v_squad_standings have all
--   carried security_invoker='true' since the baseline.
--
-- Fixing it here rather than at the grant layer also makes the fix independent
-- of the ACL layer being correct: under invoker semantics anon has no policy on
-- either base table, so the anonymous read returns zero rows even if an anon
-- grant survives somewhere.
--
-- WHY THE FLIP IS PARITY, NOT A NARROWING
-- Under security_invoker the two base tables are read through their own
-- policies, and both are exactly:
--     is_event_member(event_id) or is_event_league_member(event_id)
-- (20260720193000_the_major widened them from participants-only to include the
-- attached league's members; verified against the live schema, 2026-07-24). The
-- client's only read of this view sits in the SAME Promise.all as its reads of
-- event_duels and event_players (index.html, loadEvent) — so anyone whose duel
-- list renders today already has the row visibility the aggregate needs, and
-- anyone who would now see an empty scoreboard is already looking at an empty
-- duel list. Both event-creation paths (create_event, create_major — the latest
-- of each in 20260724100000) insert the creator into event_players, so no
-- organizer falls outside is_event_member.
--
-- SERVER-SIDE READERS ARE UNAFFECTED
-- The view is read only inside SECURITY DEFINER functions (resolve_session,
-- latest in 20260716160000 — the clinch check and the session-story scoreline).
-- Those run as postgres, which owns the base tables, so owner reads still see
-- every row — including on the cron path (run_event_sessions), where auth.uid()
-- is null and every policy predicate would be false.
--
-- ALTER VIEW, not CREATE OR REPLACE: the flip must not disturb the view's shape
-- or the existing `grant select ... to authenticated` from 20260713120000.
--
-- Client: none. Pure DB change, skew-safe in both directions — an old client
-- against the new view loses only rows it was never authorized to see.
-- ============================================================================

alter view public.v_event_scoreboard set (security_invoker = true);

-- Load-bearing under invoker semantics: `authenticated` needs SELECT on the
-- view AND on both base tables (RLS then filters). Re-assert rather than
-- assume — a missing grant here reads as a blank scoreboard, not an error.
grant select on public.v_event_scoreboard to authenticated;

-- Assert the posture, so a half-applied push fails loudly here instead of
-- shipping either the leak or an unreadable scoreboard.
do $$
declare
  bad text;
begin
  -- 1 · the flip actually took (a boolean reloption can store true/on/1)
  perform 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    left join lateral (
      select lower(split_part(o, '=', 2)) as v
      from unnest(coalesce(c.reloptions, '{}'::text[])) o
      where split_part(o, '=', 1) = 'security_invoker'
    ) so on true
   where n.nspname = 'public' and c.relname = 'v_event_scoreboard'
     and so.v in ('true', 'on', '1', 'yes');
  if not found then
    raise exception 'v_event_scoreboard did not take security_invoker';
  end if;

  -- 2 · authenticated still reaches the view and both base tables, or the
  --     event room's scoreboard blanks for legitimate participants
  select string_agg(r, ' · ') into bad
    from unnest(array['v_event_scoreboard', 'event_duels', 'event_players']) r
   where not has_table_privilege('authenticated', ('public.' || r)::regclass, 'select');
  if bad is not null then
    raise exception 'authenticated lost SELECT on: % — the scoreboard would blank', bad;
  end if;

  -- 3 · retire the whole class: no public view reachable by an API role may
  --     run as its owner. Catches the next view shipped without the option.
  select string_agg(c.relname, ' · ' order by c.relname) into bad
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    left join lateral (
      select lower(split_part(o, '=', 2)) as v
      from unnest(coalesce(c.reloptions, '{}'::text[])) o
      where split_part(o, '=', 1) = 'security_invoker'
    ) so on true
   where n.nspname = 'public' and c.relkind = 'v'
     and coalesce(so.v, 'false') not in ('true', 'on', '1', 'yes')
     and (has_table_privilege('anon', c.oid, 'select')
       or has_table_privilege('authenticated', c.oid, 'select'));
  if bad is not null then
    raise exception 'definer-style view(s) still reachable by an API role: %', bad;
  end if;
end $$;
