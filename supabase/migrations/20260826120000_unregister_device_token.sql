-- Cup Season - unregister a device token (iOS arc, W5 completion)
--
-- register_device_token() shipped in 20260722013000 with no counterpart, so
-- "Disable on this device" had nothing to call inside the native shell: the
-- row survived the toggle and the phone kept buzzing after the UI said off.
-- device_tokens runs RLS with no owner policy by design (service-role reads,
-- RPC writes), so the delete has to arrive the same way the insert does.

create or replace function public.unregister_device_token(p_token text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  -- scoped to the caller: a token you do not own is not yours to delete
  delete from device_tokens
   where token = left(trim(p_token), 200)
     and profile_id = auth.uid();
end $$;

-- D37: default privileges no longer auto-grant execute, and a function created
-- by a non-postgres migration runner can still pick up PUBLIC execute - so the
-- revoke is not redundant with the flip. preflight check 2 asserts the grant.
revoke all on function public.unregister_device_token(text) from public, anon;
grant execute on function public.unregister_device_token(text) to authenticated;
