-- ============================================================================
-- Cup Season — D65 follow-up: the founder can find a sandbox by its code
--
-- Gap found on the first live run: every sandbox RPC takes a league uuid, but
-- the sandbox Pro is deliberately a SEPARATE account (D65's containment), so
-- the founder is not a member — and leagues RLS correctly hides non-member
-- rows. league_by_code / join_covenant_info both answer with the league's
-- FACE (name, bylaws) and never its id, by design (D57: ids stay out of
-- shared surfaces). So the founder had the code and no way to reach the id.
--
-- sandbox_find(code) closes it: founder-only, returns the uuid. Deliberately
-- NOT limited to already-flagged leagues — arm is the step that sets the flag,
-- so the resolver has to work on a league that is still ordinary. The gate is
-- is_founder, the same one every other sandbox RPC leans on.
-- ============================================================================

create or replace function public.sandbox_find(p_code text)
returns uuid
language plpgsql stable security definer set search_path = public as $$
declare v_founder boolean; v_id uuid;
begin
  select is_founder into v_founder from profiles where id = auth.uid();
  if v_founder is not true then raise exception 'founder only'; end if;
  select id into v_id from leagues where upper(code) = upper(btrim(p_code));
  if v_id is null then raise exception 'no league with that code'; end if;
  return v_id;
end $$;

revoke all on function public.sandbox_find(text) from public, anon;
grant execute on function public.sandbox_find(text) to authenticated;
