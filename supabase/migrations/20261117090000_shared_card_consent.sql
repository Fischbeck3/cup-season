-- D380 verification: a shared card is PNG, and a consent check must be able
-- to see the sharer's existing copies. The old helpers admitted JPEG only;
-- storage SELECT covered private media only, so list() returned no shared files.
-- Keep the existing owner/live-token boundaries and anon surface unchanged.
create or replace function public.can_write_share_copy(p_name text)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.shares s
    where p_name in (s.token::text || '.jpg', s.token::text || '.png')
      and s.created_by = auth.uid() and not s.revoked)
$$;

create or replace function public.can_drop_share_copy(p_name text)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.shares s
    where p_name in (s.token::text || '.jpg', s.token::text || '.png')
      and s.created_by = auth.uid())
$$;

revoke all on function public.can_write_share_copy(text) from public, anon;
revoke all on function public.can_drop_share_copy(text) from public, anon;
grant execute on function public.can_write_share_copy(text) to authenticated;
grant execute on function public.can_drop_share_copy(text) to authenticated;

-- Ownership stays behind the existing definer, since clients cannot read
-- shares. Read/delete include revoked tokens so the owner can finish cleanup.
drop policy if exists shared_copy_read on storage.objects;
create policy shared_copy_read on storage.objects for select to authenticated
  using (bucket_id = 'shared' and public.can_drop_share_copy(name));
