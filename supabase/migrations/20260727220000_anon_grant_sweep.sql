-- ============================================================================
-- Cup Season — D37: make the anon grant claim TRUE
--
-- CLAUDE.md has stated since 20260724150000 that "anon holds ZERO relation
-- privileges in public". A 2026-07-27 audit found that is not the case in prod:
-- 64 of 73 relations still carried `anon=arwdDxtm` — every privilege — on
-- tables including profiles, rounds, posts, device_tokens and push_subscriptions.
--
-- NOTHING IS CURRENTLY EXPOSED, and that was verified empirically rather than
-- reasoned about (this project has been burned by exactly that: "column revokes
-- don't subtract from table grants" — emails stayed readable for weeks after
-- the supposed fix). Probing prod with only the publishable key, signed out:
-- every table returned ZERO rows, profiles hard-failed 42501, and an insert
-- into client_events was refused 42501. RLS is holding the line alone.
--
-- That is the problem. Grants and RLS are two layers and only one is doing any
-- work; a future permissive policy — or one table where RLS is forgotten —
-- turns a documented-safe posture into a live leak. This restores the second
-- layer so the doc and the database agree.
--
-- WHAT THIS DOES NOT TOUCH:
--   · authenticated — untouched, every signed-in read/write is unaffected.
--   · schema USAGE for anon — anon must still reach public to CALL the seven
--     anon RPCs (claim_round_info, scan_claim_info, league_by_code, founder_id,
--     share_info, join_covenant_info, email_unsubscribe). Only RELATION
--     privileges are revoked here.
--   · those seven functions — EXECUTE on a function is a separate privilege,
--     and each is SECURITY DEFINER, so it reads its tables as the OWNER. Table
--     grants to anon were never what made them work.
--   · the storage schema — public-bucket reads (shared/{token}.jpg|.png, D60/D78)
--     go through storage.objects in a different schema and are not affected.
--
-- Idempotent: safe to re-run, and safe to run before or after any client deploy.
-- ============================================================================

do $$
declare r record; n int := 0;
begin
  -- every table, view and materialised view in public
  for r in
    select c.relname
      from pg_class c
      join pg_namespace ns on ns.oid = c.relnamespace
     where ns.nspname = 'public'
       and c.relkind in ('r','v','m','p')
       and coalesce(array_to_string(c.relacl,' | '),'') like '%anon=%'
     order by c.relname
  loop
    execute format('revoke all on public.%I from anon', r.relname);
    n := n + 1;
  end loop;
  raise notice '[anon sweep] relations revoked: %', n;
end $$;

-- sequences too: a bare nextval grant is enough to enumerate row counts
do $$
declare r record; n int := 0;
begin
  for r in
    select c.relname
      from pg_class c
      join pg_namespace ns on ns.oid = c.relnamespace
     where ns.nspname = 'public' and c.relkind = 'S'
       and coalesce(array_to_string(c.relacl,' | '),'') like '%anon=%'
  loop
    execute format('revoke all on sequence public.%I from anon', r.relname);
    n := n + 1;
  end loop;
  raise notice '[anon sweep] sequences revoked: %', n;
end $$;

-- and stop NEW objects from auto-granting. The D37 flip binds to the role that
-- created the objects, and not every migration runner has been the same role —
-- which is the likeliest reason the original sweep did not hold. Cover both.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges for role postgres in schema public revoke all on tables from anon;
alter default privileges for role postgres in schema public revoke all on sequences from anon;

-- anon keeps schema access so it can still CALL the seven public RPCs
grant usage on schema public to anon;

-- Fail the migration rather than report success on a half-done sweep.
do $$
declare leftover text;
begin
  select string_agg(c.relname, ', ' order by c.relname) into leftover
    from pg_class c join pg_namespace ns on ns.oid = c.relnamespace
   where ns.nspname = 'public'
     and c.relkind in ('r','v','m','p','S')
     and coalesce(array_to_string(c.relacl,' | '),'') like '%anon=%';
  if leftover is not null then
    raise exception '[anon sweep] anon still holds privileges on: %', leftover;
  end if;
  raise notice '[anon sweep] verified: anon holds zero relation privileges in public';
end $$;
