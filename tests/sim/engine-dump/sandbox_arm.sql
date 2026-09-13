-- sandbox_arm(p_league uuid, p_bots integer) oid=20469
CREATE OR REPLACE FUNCTION public.sandbox_arm(p_league uuid, p_bots integer DEFAULT 7)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_names  text[] := array['Sandy Wedge','Chip Draw','Bo Gie','Woody Longiron',
                           'Iron Mikey','Rusty Putter','Mully Gunn','Skip Divot'];
  v_marks  text[] := array['shark','dunes','lonetree','lighthouse',
                           'island','pews','beer','saguaro'];
  v_skill  numeric[] := array[4.2,7.8,9.5,11.3,13.6,16.1,18.4,20.7];
  v_others integer;
  v_uid    uuid;
  v_email  text;
  v_made   jsonb := '[]'::jsonb;
  i        integer;
begin
  perform assert_sandbox(p_league, false);
  if p_bots < 1 or p_bots > 8 then raise exception '1 to 8 bots'; end if;

  -- a real league can never be armed: nobody here but the commissioner
  select count(*) into v_others
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.league_id = p_league
     and p.email not like '%@sandbox.cupseason.test'
     and lm.role <> 'commissioner';
  if v_others > 0 then
    raise exception 'this league has real members — sandbox refuses';
  end if;

  update leagues set sandbox = true where id = p_league;

  for i in 1..p_bots loop
    v_email := 'bot' || i || '-' || left(p_league::text, 8) || '@sandbox.cupseason.test';
    select id into v_uid from auth.users where email = v_email;

    if v_uid is null then
      v_uid := gen_random_uuid();
      -- minimal, never-loginable auth row; the m001 trigger mints the profile
      insert into auth.users
        (instance_id, id, aud, role, email, encrypted_password,
         email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
         created_at, updated_at,
         confirmation_token, recovery_token, email_change_token_new, email_change)
      values
        ('00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
         v_email, '', now(),
         '{"provider":"email","providers":["email"]}'::jsonb,
         jsonb_build_object('display_name', v_names[i]),
         now(), now(), '', '', '', '');
      update profiles
         set marker = v_marks[i], index_current = v_skill[i],
             index_source = 'self', discoverable = 'nobody', city = 'Tempe, AZ'
       where id = v_uid;
    end if;

    insert into league_members (league_id, profile_id, role, index_current, index_source)
    values (p_league, v_uid, 'player', v_skill[i], 'self')
    on conflict do nothing;

    v_made := v_made || jsonb_build_object('name', v_names[i], 'index', v_skill[i]);
  end loop;

  return jsonb_build_object('armed', true, 'bots', v_made);
exception when insufficient_privilege then
  raise exception 'auth.users insert denied by role — run sandbox_arm once from the dashboard SQL editor';
end $function$

