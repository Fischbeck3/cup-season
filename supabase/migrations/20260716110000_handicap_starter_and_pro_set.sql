-- ============================================================================
-- Cup Season — handicap override = "starter seed" (B), + a Pro set-index tool
--
-- Decision: a manual index is a STARTER, not a permanent override. It fills the
-- gap before you have 3 posted rounds; once the engine can compute a real index
-- from your scores, your scores win (closes the sandbag hole — a soft manual
-- number can't outlive your record). round_refresh_index drops the index_source
-- gate: once handicap_index() is non-null (>=3 rounds) it takes over and stamps
-- index_source='app' (honest provenance: "from scores").
--
-- set_member_index(): the Pro can set a member's STARTER index (e.g. help
-- someone who hasn't posted 3 yet). Announced on the board, and — like any
-- starter — it yields to the engine once that member establishes.
-- ============================================================================

create or replace function public.round_refresh_index() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_auto numeric;
begin
  if new.voided then return new; end if;
  v_auto := handicap_index(new.profile_id);      -- non-null once >= 3 rounds
  if v_auto is not null then                      -- scores are the truth
    update profiles set index_current = v_auto, index_source = 'app'
     where id = new.profile_id;
  end if;
  return new;
end $$;

create or replace function public.set_member_index(p_member uuid, p_index numeric)
returns void language plpgsql security definer set search_path = public as $$
declare v_league uuid; v_pid uuid; v_name text;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'index out of range';
  end if;
  select league_id, profile_id into v_league, v_pid from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro sets a starter index'; end if;

  select display_name into v_name from profiles where id = v_pid;
  update profiles set index_current = p_index, index_source = 'self' where id = v_pid;

  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          'THE PRO SET ' || upper(coalesce(v_name, 'A MEMBER')) || '''S STARTER INDEX TO ' || p_index);
end $$;
grant execute on function public.set_member_index(uuid, numeric) to authenticated;
