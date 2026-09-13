-- remove_member(p_member uuid) oid=18881
CREATE OR REPLACE FUNCTION public.remove_member(p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league uuid; v_name text;
begin
  select league_id into v_league from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro removes golfers'; end if;
  if p_member = my_member_id(v_league) then raise exception 'Transfer the Pro role before leaving'; end if;
  if (select phase from leagues where id = v_league) <> 'setup' then
    raise exception 'A golfer can only be removed during setup — mid-season, suspend them instead.';
  end if;

  select coalesce(p.display_name, 'A member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  update posts set member_id = null where member_id = p_member;
  delete from squad_members where member_id = p_member;
  delete from buy_ins where member_id = p_member;
  delete from league_members where id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, my_member_id(v_league), 'remove_member',
          jsonb_build_object('member', p_member, 'name', v_name));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          v_name || ' is off the roster.');
end $function$

