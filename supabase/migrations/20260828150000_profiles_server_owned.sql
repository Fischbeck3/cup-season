-- ============================================================================
-- Cup Season — profiles are SERVER-OWNED (launch review 2026-08-28, blocker #1)
--
-- The hole: `authenticated` held table-level INSERT/UPDATE/DELETE on
-- public.profiles (relacl authenticated=awdDxtm) and the two UPDATE policies
-- (profiles_write, profiles_self_update — baseline :2253/:2257) scoped only
-- by ROW (id = auth.uid()), never by COLUMN. So a signed-in golfer could
-- PATCH their own row and set is_founder=true — passing every founder gate
-- (sandbox_find, sandbox_league, founder_desk, the test-seed Edge Function's
-- is_founder read) — or rewrite index_current / index_source (sandbagging,
-- bypassing set_index), founding_member, email (fires trg_tag_founder), or
-- deleted_at. RLS said "your row"; nothing said "not those columns".
--
-- The fix is the D37 principle applied to the one table that had escaped it:
-- NO client writes profiles directly. Every legitimate change already goes
-- through a SECURITY DEFINER RPC — verified against prod, every function whose
-- body writes profiles is prosecdef=true: create_league, delete_account,
-- handle_new_user (the m001 signup trigger on auth.users), round_refresh_index
-- (the handicap-engine trigger on rounds), sandbox_arm, set_discoverable,
-- set_handle, set_index, set_member_index, set_notify_chat, set_notify_rounds,
-- set_profile. Neither client issues a direct write: index.html has zero
-- `from('profiles').update|upsert|insert`; the Swift packages select only
-- (MeRepository, ProfileRepository, PeopleService, TourCard, YouRepository).
--
-- So: revoke the write grants, drop the write policies. SELECT is untouched —
-- the column-grant list frozen by the email seal (20260721214500, check 9)
-- stays exactly as it is. After this, is_founder / founding_member /
-- index_current / email / deleted_at / handle_set_at have NO client write
-- path at all — status is fixed by construction, not by policy text.
--
-- Self-enforcing (the anon-sweep pattern, 20260727220000): the DO block at the
-- end RAISES if any write privilege or write policy is left, so a partial
-- apply cannot report success. tests/db-checks.sql check 13 keeps it honest.
--
-- No scoring or mechanic change. No functions created (nothing to grant).
-- ============================================================================

-- ---- 1 · table-level write privileges go --------------------------------
revoke insert, update, delete, truncate, references, trigger
  on table public.profiles from authenticated;

-- Column-level write grants would survive the table revoke (the landmine in
-- CLAUDE.md: column and table ACLs are separate layers). Prod holds none
-- today; sweep dynamically so a future one cannot hide behind this file.
do $$
declare r record;
begin
  for r in
    select att.attname, a.privilege_type
      from pg_attribute att
      join pg_class c on c.oid = att.attrelid
      cross join lateral aclexplode(att.attacl) a
     where c.oid = 'public.profiles'::regclass
       and att.attnum > 0 and not att.attisdropped
       and a.grantee = 'authenticated'::regrole
       and a.privilege_type in ('INSERT','UPDATE','REFERENCES')
  loop
    execute format('revoke %s (%I) on table public.profiles from authenticated',
                   r.privilege_type, r.attname);
  end loop;
end $$;

-- ---- 2 · the row-scoped UPDATE policies go ------------------------------
drop policy if exists profiles_write       on public.profiles;
drop policy if exists profiles_self_update on public.profiles;

-- ---- 3 · prove it, or fail the push --------------------------------------
do $$
declare v_pols text; v_cols text;
begin
  if has_table_privilege('authenticated', 'public.profiles', 'insert')
  or has_table_privilege('authenticated', 'public.profiles', 'update')
  or has_table_privilege('authenticated', 'public.profiles', 'delete') then
    raise exception 'profiles_server_owned: authenticated still holds a table-level write on public.profiles';
  end if;

  select string_agg(att.attname || ':' || a.privilege_type, ', ') into v_cols
    from pg_attribute att
    join pg_class c on c.oid = att.attrelid
    cross join lateral aclexplode(att.attacl) a
   where c.oid = 'public.profiles'::regclass
     and att.attnum > 0 and not att.attisdropped
     and a.grantee = 'authenticated'::regrole
     and a.privilege_type <> 'SELECT';
  if v_cols is not null then
    raise exception 'profiles_server_owned: column-level write grant(s) remain: %', v_cols;
  end if;

  select string_agg(polname, ', ') into v_pols
    from pg_policy
   where polrelid = 'public.profiles'::regclass
     and polcmd in ('w', 'a', 'd', '*');
  if v_pols is not null then
    raise exception 'profiles_server_owned: write policy(ies) remain on profiles: %', v_pols;
  end if;

  -- and SELECT survived (the seal's column list must still be readable)
  if not has_column_privilege('authenticated', 'public.profiles', 'display_name', 'select') then
    raise exception 'profiles_server_owned: SELECT on profiles was lost — do not ship';
  end if;
end $$;
