-- D385 integration: an already-revoked legacy link with no objects still needs
-- a confirmable cleanup row when a client retries withdrawal. No new grants.
create or replace function public.withdraw_round_shares(p_round uuid)
returns text[]
language plpgsql security definer set search_path = public
as $$
declare v_me uuid := auth.uid(); v_tokens text[];
begin
  if v_me is null then raise exception 'Sign in first'; end if;
  if p_round is null then return '{}'; end if;
  -- the caller's own round, or links the caller minted for one already deleted
  if not exists (select 1 from rounds where id = p_round and profile_id = v_me)
     and not exists (select 1 from shares where kind = 'round' and ref_id = p_round and created_by = v_me) then
    raise exception 'Not your round';
  end if;
  update shares set revoked = true
   where kind = 'round' and ref_id = p_round and created_by = v_me and not revoked;
  -- Pre-queue revocations without stored copies were not in the backfill.
  -- Every returned token must have an obligation that the owner can confirm.
  insert into share_cleanup (token, owner_id, kind, ref_id)
    select token, created_by, kind, ref_id from shares
     where kind = 'round' and ref_id = p_round and created_by = v_me and revoked
  on conflict (token) do nothing;
  select coalesce(array_agg(token::text order by created_at), '{}') into v_tokens
    from shares where kind = 'round' and ref_id = p_round and created_by = v_me;
  return v_tokens;
end $$;
revoke all on function public.withdraw_round_shares(uuid) from public, anon;
grant execute on function public.withdraw_round_shares(uuid) to authenticated;
