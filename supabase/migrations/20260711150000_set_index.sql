-- ============================================================================
-- Cup Season — set_index(): the socially-policed handicap self-edit
-- (punch list #5)
--
-- Updates profiles.index_current and announces the change on every league
-- board the profile belongs to — the crew polices the sandbaggers, not an
-- admin. Round history is unaffected: every round snapshots index_at_post
-- at posting time. Card edits via set_profile() pass p_index NULL (coalesce
-- keeps the old value), so this RPC is the ONLY path that moves an index —
-- no silent edits.
-- ============================================================================

create or replace function public.set_index(p_index numeric) returns void
language plpgsql security definer
set search_path = public
as $$
declare v_old numeric; v_name text;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'index out of range';
  end if;
  select index_current, display_name into v_old, v_name
    from profiles where id = auth.uid();
  if not found then raise exception 'no profile'; end if;
  if v_old is not distinct from p_index then return; end if;

  update profiles set index_current = p_index where id = auth.uid();

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || case when v_old is null
           then ' set their index to ' || p_index
           else ' adjusted their index ' || v_old || ' → ' || p_index end
  from league_members lm
  where lm.profile_id = auth.uid();
end $$;

grant execute on function public.set_index(numeric) to authenticated;
