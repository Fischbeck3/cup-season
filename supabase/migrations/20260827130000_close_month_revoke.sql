-- ============================================================================
-- IOS-009 batch 1 (docs/ios/DECISIONS.md) · item 1 — close_month revoke
--
-- close_month(uuid, date) is a cron engine (run_month_closes → close_month),
-- never a client RPC. 20260718172300 C3 revoked it from the API roles, but
-- 20260727160000:341 (board_voice) re-granted it to authenticated with no
-- body gate, so the prod snapshot (packages/db/contract.psv) shows `auth`
-- again — audit 06 §9.1 / audit 07 G9. The body is idempotent and
-- season-scoped, but its only guard is the `month_closed` sentinel, so any
-- member who knows a season id can close last month EARLY, and that early
-- close permanently blocks the cron's real close for that month.
--
-- Same sweep for the two trophy minters: award_event_trophies(uuid) still
-- carries a vestigial `auth` grant (created before the D37 default-privilege
-- flip; every later `create or replace` preserved the ACL);
-- award_season_trophies(uuid) already reads `none` but is revoked again here
-- so the assertion below covers all three by name.
--
-- Cron runs as postgres (the owner) and trigger functions run as their
-- definer, so nothing that legitimately calls these needs a grant.
-- award_season_trophies keeps its service_role grant (20260725190000).
--
-- Additive-only for the web client: index.html never calls any of the three.
-- ============================================================================

revoke execute on function public.close_month(uuid, date)        from public, anon, authenticated;
revoke execute on function public.award_event_trophies(uuid)     from public, anon, authenticated;
revoke execute on function public.award_season_trophies(uuid)    from public, anon, authenticated;

-- Self-enforcing, like the anon sweep (20260727220000): RAISE rather than
-- report success if any of the three is still reachable by an API role.
do $$
declare bad text;
begin
  select string_agg(p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')', ', ')
    into bad
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname in ('close_month', 'award_event_trophies', 'award_season_trophies')
     and (has_function_privilege('anon', p.oid, 'execute')
       or has_function_privilege('authenticated', p.oid, 'execute'));
  if bad is not null then
    raise exception 'IOS-009 close_month_revoke: still executable by an API role: %', bad;
  end if;
end $$;
