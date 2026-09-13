-- transfer_pro(p_member uuid) oid=18882
CREATE OR REPLACE FUNCTION public.transfer_pro(p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league uuid; v_name text; v_me uuid; v_new_profile uuid;
begin
  select league_id, profile_id into v_league, v_new_profile
    from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro hands over the shop'; end if;
  v_me := my_member_id(v_league);
  if p_member = v_me then raise exception 'You already run the shop'; end if;
  if v_new_profile is null then raise exception 'That member has no golfer profile'; end if;

  update league_members set role = 'commissioner' where id = p_member;
  update league_members set role = 'player' where id = v_me;
  -- the column the phone, the create policy and delete_account all read
  update leagues set commissioner_id = v_new_profile where id = v_league;

  select coalesce(p.display_name, 'a member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, p_member, 'transfer_pro', jsonb_build_object('from', v_me, 'to', p_member));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', v_me, 'The Pro role passes to ' || v_name || '.');
end $function$

