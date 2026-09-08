-- ============================================================================
-- Cup Season — a storage policy never reads a table the golfer cannot (D300)
--
-- THE BUG, AND IT IS 47 DAYS OLD. The owner, on build 748: *"when trying to
-- post photo 'the photo didnt attach, check your signal and try again'."* That
-- sentence is `RoundCopy.photoFailed`, and L-32 is why it says nothing more —
-- a golfer never reads a code. The cost of that rule is that this failure was
-- unreadable by anybody, including the person who wrote the product. A DEBUG
-- probe (`-cs_dev_photo_probe`) ran the real two steps against prod on the
-- owner's own session and printed the answer:
--
--     UPLOAD FAILED · StorageError(statusCode: "403",
--       message: "permission denied for table shares", error: "Unauthorized")
--
-- The upload never reached the RPC. It was refused by `storage.objects`, and
-- NOT by the media policy — `media_insert` is `bucket_id = 'media' and
-- (storage.foldername(name))[1] = auth.uid()::text`, which the client
-- satisfies. It was refused by a policy about a DIFFERENT BUCKET.
--
-- **Postgres evaluates every permissive policy for the command.** An INSERT
-- into `storage.objects` by `authenticated` is checked against `media_insert`
-- OR `shared_copy_insert`, and to evaluate the second one the executor must
-- read `public.shares`. It cannot:
--
--   · `20260722190000_public_shares.sql:35` — `revoke all on table
--     public.shares from public, anon, authenticated` (correct, and D37's
--     posture: clients reach shares through RPCs, never the table).
--   · `20260723210000_shared_photo_travel.sql` — adds `shared_copy_insert`
--     and `shared_copy_delete` on `storage.objects`, both of which
--     `select 1 from shares`.
--
-- One day apart, and neither one is wrong on its own. Together they mean **no
-- signed-in golfer has been able to upload any object to any bucket since
-- 2026-07-23** — not a round photograph at post time, not one on a posted
-- round, not an avatar. The newest object in the `media` bucket is dated
-- **2026-07-22**, the day before. That is the whole evidence, and it also
-- explains why every photograph feature since has looked like it worked in
-- review: the simulator paths and the code are fine, and nothing ever got as
-- far as the bucket.
--
-- THE FIX IS THIS CODEBASE'S OWN PRECEDENT. `media_read` had the identical
-- problem and solved it: it calls `can_see_media(...)`, a SECURITY DEFINER
-- function that reads `league_members` and `friendships` as the owner while
-- `auth.uid()` still resolves to the caller (it reads the JWT claim, not the
-- role). The two `shared_copy_*` policies were simply never converted. They
-- are converted here. Nothing about WHO may write a shared copy changes — the
-- predicate is the same predicate, moved behind a function that is allowed to
-- read the table it asks about.
-- ============================================================================

begin;

-- ---- the two predicates, behind functions that may read `shares` -----------

-- A golfer may write the public copy of a share they created and have not
-- revoked. Same rows, same rule, same `auth.uid()` — only the reader changes.
create or replace function public.can_write_share_copy(p_name text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.shares s
     where (s.token::text || '.jpg') = p_name
       and s.created_by = auth.uid()
       and not s.revoked)
$$;

-- The delete side does not test `revoked`: a golfer who revokes a share must
-- still be able to take its copy out of the bucket. That asymmetry is the
-- deployed policy's, kept deliberately.
create or replace function public.can_drop_share_copy(p_name text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.shares s
     where (s.token::text || '.jpg') = p_name
       and s.created_by = auth.uid())
$$;

revoke all on function public.can_write_share_copy(text) from public, anon;
revoke all on function public.can_drop_share_copy(text)  from public, anon;
grant execute on function public.can_write_share_copy(text) to authenticated;
grant execute on function public.can_drop_share_copy(text)  to authenticated;

-- ---- the two policies, rewritten to call them ------------------------------

drop policy if exists shared_copy_insert on storage.objects;
create policy shared_copy_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'shared' and public.can_write_share_copy(name));

drop policy if exists shared_copy_delete on storage.objects;
create policy shared_copy_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'shared' and public.can_drop_share_copy(name));

-- ---- the self-check, and it is the GENERAL rule ----------------------------
-- Not "shares is gone from the policies" — that is this bug, and a check that
-- only knows this bug is a check that lets the next one through. The rule is
-- that a policy on `storage.objects` may not name a `public` table the
-- `authenticated` role cannot select, because the executor will read it and
-- the whole statement dies with somebody else's bucket in the message.
do $chk$
declare v_bad text; v_n int;
begin
  select string_agg(p.policyname || ' → ' || t.table_name, ', '), count(*)
    into v_bad, v_n
    from pg_policies p
    cross join (
      select c.relname as table_name
        from pg_class c join pg_namespace n on n.oid = c.relnamespace
       where n.nspname = 'public' and c.relkind in ('r','p','v','m')
         and not has_table_privilege('authenticated', c.oid, 'SELECT')
    ) t
   where p.schemaname = 'storage' and p.tablename = 'objects'
     and (coalesce(p.qual,'') || ' ' || coalesce(p.with_check,'')) ~ ('\m' || t.table_name || '\M');
  if v_n > 0 then
    raise exception '[D300] % storage policy/table pair(s) read a table authenticated cannot: %', v_n, v_bad;
  end if;

  -- and the two functions that took the reads over are real, definer, granted
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname='public' and p.proname='can_write_share_copy' and p.prosecdef) then
    raise exception '[D300] can_write_share_copy is missing or is not SECURITY DEFINER'; end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname='public' and p.proname='can_drop_share_copy' and p.prosecdef) then
    raise exception '[D300] can_drop_share_copy is missing or is not SECURITY DEFINER'; end if;
  if not has_function_privilege('authenticated', 'public.can_write_share_copy(text)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.can_drop_share_copy(text)', 'EXECUTE') then
    raise exception '[D300] the share-copy helpers are not executable by authenticated'; end if;
  if has_function_privilege('anon', 'public.can_write_share_copy(text)', 'EXECUTE')
     or has_function_privilege('anon', 'public.can_drop_share_copy(text)', 'EXECUTE') then
    raise exception '[D300] anon can execute a share-copy helper (D37)'; end if;

  -- `shares` itself stays shut to the client; the point was never to open it
  if has_table_privilege('authenticated', 'public.shares', 'SELECT') then
    raise exception '[D300] public.shares was granted to authenticated — the fix was the policy, not the grant'; end if;

  raise notice '[D300] storage policies read nothing the golfer cannot; uploads are open again after 47 days';
end $chk$;

commit;
