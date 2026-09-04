-- D37 (extended) · TRUNCATE, REFERENCES, TRIGGER and MAINTAIN are not client verbs.
--
-- The write seal on `posts` (20260902210000) removed one table's INSERT and
-- prompted the obvious next question: what ELSE does `authenticated` hold at
-- table level? Read out of prod 2026-09-04:
--
--   authenticated's relacl on a typical table is `rwdDxtm`
--     r SELECT · w UPDATE · d DELETE   — real, and RLS gates them
--     D TRUNCATE · x REFERENCES · t TRIGGER · m MAINTAIN  — none of them
--
--   54 tables grant TRUNCATE to authenticated/anon
--   108 REFERENCES/TRIGGER grants across the same schema
--
-- TRUNCATE is the sharp one: it BYPASSES RLS entirely, so the second layer this
-- project leans on does not cover it — `truncate rounds` is not a delete with a
-- policy, it is a table emptied. It is not reachable through the shipped
-- surface (PostgREST never emits TRUNCATE, and no RPC builds dynamic SQL), so
-- this is latent rather than exploitable — but it is exactly the D37 family of
-- gap this repo has been burned by twice, and "not reachable today" is a
-- statement about today's client.
--
-- profiles is already clean (sealed by 20260828150000) and stays untouched.
-- SELECT, INSERT, UPDATE and DELETE are deliberately left exactly as they are:
-- this migration removes only privileges no client has ever used.
--
-- KNOWN GAP, deliberately not closed here: `pg_default_acl` still grants
-- `arwdDxtm` to authenticated for every NEW table created by `postgres` (and
-- anon as well for tables created by `supabase_admin`). So a table added by a
-- future migration is born with all of this again, INSERT included — the
-- systemic version of the hole `posts` had. Changing that default makes every
-- future migration responsible for its own grants, which is a posture change
-- worth ruling on rather than smuggling into a housekeeping file. Logged for
-- the owner; the self-check below is scoped to today's tables so it cannot
-- fail on a table that has not been written yet.

revoke truncate, references, trigger, maintain on all tables in schema public from authenticated, anon;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_n int; v_names text;
begin
  select count(*), string_agg(distinct c.relname, ', ' order by c.relname)
    into v_n, v_names
    from pg_class c, lateral aclexplode(c.relacl) a
   where c.relnamespace = 'public'::regnamespace
     and c.relkind in ('r','p')
     and a.privilege_type in ('TRUNCATE','REFERENCES','TRIGGER','MAINTAIN')
     and a.grantee::regrole::text in ('authenticated','anon');
  if v_n > 0 then
    raise exception 'still holding % client-useless table grant(s) on: %', v_n, left(v_names, 300);
  end if;

  -- the verbs the app actually needs must survive: posts still readable and
  -- writable by a member, rounds still insertable where the seal allows it.
  if not has_table_privilege('authenticated', 'public.posts', 'SELECT') then
    raise exception 'posts lost SELECT — the board would go dark';
  end if;
  if not has_table_privilege('authenticated', 'public.posts', 'UPDATE') then
    raise exception 'posts lost UPDATE — the takedown path (D188) would break';
  end if;
  if not has_column_privilege('authenticated', 'public.posts', 'body', 'INSERT') then
    raise exception 'posts lost its chat INSERT column grant (20260902210000)';
  end if;

  raise notice 'TRUNCATE/REFERENCES/TRIGGER/MAINTAIN cleared for authenticated and anon; read+write verbs intact';
end $chk$;
