-- Cup Season — TRUNCATE is not a client verb (db-check 23, caught 2026-09-18).
--
-- WRITTEN AND VALIDATED IN ISOLATION. NOT PUSHED. The owner pushes it.
--
-- 20261106090000 created the two pilot tables with an explicit grant of
-- SELECT, INSERT, UPDATE, DELETE — and production's default privileges for
-- the migration runner ADDED the rest of ALL on top (TRUNCATE, REFERENCES,
-- TRIGGER, MAINTAIN to `authenticated`). CLAUDE.md warns about exactly this:
-- the D37 default-privilege flip binds to the `postgres` role, and the CLI's
-- runner is not it. Row security does not govern TRUNCATE or TRIGGER, so any
-- signed-in golfer could have emptied the founder's pilot record or attached
-- a trigger to it. No score, round or league table is touched by this file.
--
-- The lesson this file also writes down: a new table's grants are stated by
-- REVOKING ALL first and granting the exact list after — additive grants on
-- top of leaked defaults look correct in the migration and are not.

revoke all on table public.pilot_cohort_members from public, anon, authenticated;
revoke all on table public.pilot_sessions        from public, anon, authenticated;
grant select, insert, update, delete on table public.pilot_cohort_members to authenticated;
grant select, insert, update, delete on table public.pilot_sessions        to authenticated;

do $chk$
declare v int;
begin
  select count(*) into v
    from pg_class c, aclexplode(c.relacl) a
   where c.relname in ('pilot_cohort_members','pilot_sessions')
     and a.grantee::regrole::text in ('anon','authenticated','public')
     and a.privilege_type not in ('SELECT','INSERT','UPDATE','DELETE');
  if v > 0 then raise exception 'check: % excess client grant(s) remain on the pilot tables', v; end if;
  if not exists (select 1 from pg_policies where tablename = 'pilot_cohort_members') then
    raise exception 'check: the cohort policy vanished'; end if;
end
$chk$;
