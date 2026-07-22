-- ============================================================================
-- Seal the anon table baseline — the D37 explicit-grants posture, completed
-- (pre-launch hardening, 2026-07-24).
--
-- The pre-D37 dashboard-era baseline granted ALL on every public relation to
-- anon (66 tables/views in the 2026-07-24 prod dump; profiles still held
-- INSERT/DELETE/TRUNCATE/UPDATE for anon after the email seal), and the
-- standing
--   ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
--     GRANT ALL ON TABLES / SEQUENCES TO anon
-- re-granted it to every NEW table. Inert for tables (RLS on everywhere, no
-- anon policies) — but NOT for definer-style views: v_event_scoreboard has no
-- security_invoker, so it runs as its owner (postgres, who owns the underlying
-- tables and therefore bypasses RLS), and it was anon-granted — an anonymous
-- PostgREST read of every event's team totals (event_id, team_id, points).
-- This migration closes that hole and retires the whole class.
--
-- anon's entire legitimate surface is USAGE on schema public + EXECUTE on the
-- six endpoints (claim_round_info, scan_claim_info, league_by_code, founder_id,
-- share_info, join_covenant_info — all verified SECURITY DEFINER in the same
-- dump). Definer functions read tables as their owner, so anon needs ZERO
-- relation privileges for any of them.
--
-- Deliberately untouched: authenticated + service_role grants (load-bearing —
-- PostgREST reads run as authenticated through RLS, incl. the client's
-- v_event_scoreboard read in the event loader), the profiles column-grant list
-- from the email seal (20260721214500 — column ACLs are separate from table
-- ACLs; revoking FROM anon/PUBLIC cannot reach authenticated's), anon's schema
-- USAGE (needed to call the six endpoints), and all function EXECUTE grants.
--
-- PUBLIC rides along in the revokes: anon inherits anything granted to PUBLIC,
-- so the seal is only real if PUBLIC holds nothing either (the dump shows no
-- PUBLIC relation grants today; this keeps it that way).
-- ============================================================================

-- 1 · Revoke every relation-level privilege anon (and PUBLIC) holds in public.
--     Pure revokes — no drops, so no RLS-policy-dependency risk. "ALL TABLES"
--     covers views, materialized views, and foreign tables too.
revoke all privileges on all tables    in schema public from public, anon;
revoke all privileges on all sequences in schema public from public, anon;

-- 2 · Stop the bleed forward: new tables/sequences are no longer auto-granted
--     to anon. (D37 already flipped FUNCTIONS; these two finish the job.)
alter default privileges for role postgres in schema public
  revoke all on tables from anon;
alter default privileges for role postgres in schema public
  revoke all on sequences from anon;

-- 3 · Assert the seal, so an unexpected leftover fails this push loudly
--     instead of shipping a half-revoke (e.g. a relation not owned by
--     postgres, whose grants step 1 could not remove).
do $$
declare
  offenders text;
begin
  select string_agg(o, ' · ') into offenders from (
    -- relation-level grants
    select format('%s on %s to %s', a.privilege_type, c.relname,
                  case a.grantee when 0 then 'PUBLIC' else a.grantee::regrole::text end)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    cross join lateral aclexplode(c.relacl) a
    where n.nspname = 'public'
      and c.relkind in ('r','p','v','m','f','S')
      and (a.grantee = 0 or a.grantee = 'anon'::regrole)
    union all
    -- column-level grants (revoking a table privilege does not clear these)
    select format('column %s.%s to %s', c.relname, att.attname,
                  case a.grantee when 0 then 'PUBLIC' else a.grantee::regrole::text end)
    from pg_attribute att
    join pg_class c on c.oid = att.attrelid
    join pg_namespace n on n.oid = c.relnamespace
    cross join lateral aclexplode(att.attacl) a
    where n.nspname = 'public' and att.attnum > 0 and not att.attisdropped
      and (a.grantee = 0 or a.grantee = 'anon'::regrole)
    union all
    -- default-privilege re-grants for future tables/sequences
    select format('default-acl (%s) for role %s', d.defaclobjtype, d.defaclrole::regrole)
    from pg_default_acl d
    left join pg_namespace n on n.oid = d.defaclnamespace
    cross join lateral aclexplode(d.defaclacl) a
    where d.defaclobjtype in ('r','S')
      and (n.nspname = 'public'
           or (d.defaclnamespace = 0 and d.defaclrole = 'postgres'::regrole))
      and (a.grantee = 0 or a.grantee = 'anon'::regrole)
  ) t(o);
  if offenders is not null then
    raise exception 'anon seal incomplete: %', offenders;
  end if;
end $$;
