-- Q2: execute the real RPC on a disposable whole-chain database.
begin;
insert into auth.users(id,email) values
 ('c5200000-0000-4000-8000-000000000001','q2-pro@example.test'),
 ('c5200000-0000-4000-8000-000000000002','q2-player@example.test');
select set_config('sim.uid','c5200000-0000-4000-8000-000000000001',true);

do $test$
declare
  lid uuid; sid uuid; st text; got text; want text; saved text; count_before integer;
begin
  foreach st in array array['squads2','squads3','squads4','solo'] loop
    lid := (create_league('Q2 Fixture ' || st, upper('Q' || st))->'league'->>'id')::uuid;
    update league_settings set structure = st where league_id = lid;
    perform set_league_finish(lid,'cup_final');
    select body into got from posts where league_id = lid and body like 'The Pro set the finish:%';
    want := 'The Pro set the finish: the Cup Final. ' || case st
      when 'squads2' then 'Both squads play the final four weeks, scored fresh. The leading squad carries a 10-point head start.'
      when 'solo' then 'The top two golfers play the final four weeks, scored fresh.'
      else 'The top two squads play the final four weeks, scored fresh.' end;
    if got is distinct from want then raise exception 'Q2 %: % <> %', st, got, want; end if;
    if (select finish from league_settings where league_id=lid) <> 'cup_final' then raise exception 'Finish did not save'; end if;
    if (select count(*) from posts where league_id=lid and body=want) <> 1 then raise exception 'Announcement not exactly once'; end if;
    saved := got;
    perform set_league_finish(lid,'points_table');
    if not exists(select 1 from posts where league_id=lid and body='The Pro set the finish: the points table. It crowns the champion outright — no Cup Final.') then raise exception 'Table copy changed'; end if;
    if not exists(select 1 from posts where league_id=lid and body=saved) then raise exception 'Historical post changed'; end if;
    raise notice 'PASS Q2 %: exact announcement, saved finish, one post, historical post preserved, table finish unchanged',st;
  end loop;

  count_before := (select count(*) from posts where league_id=lid);
  perform set_config('sim.uid','c5200000-0000-4000-8000-000000000002',true);
  begin
    perform set_league_finish(lid,'cup_final');
    raise exception 'Non-Pro accepted';
  exception when others then if sqlerrm <> 'Only the Pro sets the finish' then raise; end if; end;
  perform set_config('sim.uid','c5200000-0000-4000-8000-000000000001',true);
  begin
    perform set_league_finish(lid,'invalid');
    raise exception 'Invalid finish accepted';
  exception when others then if sqlerrm <> 'finish must be points_table or cup_final' then raise; end if; end;
  if (select count(*) from posts where league_id=lid) <> count_before then raise exception 'Rejected write posted'; end if;
  raise notice 'PASS invalid finish and non-Pro reject without posts';

  insert into seasons(league_id,number,starts_on,ends_on,status)
   values(lid,1,current_date-7,current_date+21,'active') returning id into sid;
  begin
    perform set_league_finish(lid,'cup_final');
    raise exception 'Open window accepted';
  exception when others then if sqlerrm <> 'The finish is locked once the final window opens' then raise; end if; end;
  update seasons set starts_on=current_date+1,ends_on=current_date+35 where id=sid;
  begin
    perform set_league_finish(lid,'cup_final');
    raise exception 'Short Final accepted';
  exception when others then if sqlerrm not like 'A Cup Final needs a season of six weeks or more.%' then raise; end if; end;
  update seasons set starts_on=current_date-7,ends_on=current_date+70,status='cup_final' where id=sid;
  begin
    perform set_league_finish(lid,'points_table');
    raise exception 'Entered Final accepted';
  exception when others then if sqlerrm <> 'The finish is locked once the final window opens' then raise; end if; end;
  if (select count(*) from posts where league_id=lid) <> count_before then raise exception 'Guarded write posted'; end if;
  raise notice 'PASS open-window, short-season D384, and entered-Final guards preserved';

  if has_function_privilege('anon','public.set_league_finish(uuid,text)','execute')
     or exists(select 1 from pg_proc p, lateral aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
                where p.oid='public.set_league_finish(uuid,text)'::regprocedure and a.grantee=0 and a.privilege_type='EXECUTE')
     or not has_function_privilege('authenticated','public.set_league_finish(uuid,text)','execute') then
    raise exception 'RPC grants changed';
  end if;
  raise notice 'PASS authenticated-only RPC execution';
end $test$;
rollback;
