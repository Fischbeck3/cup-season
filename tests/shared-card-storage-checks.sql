-- Isolated full-chain sandbox only: exercise the actual storage RLS as a golfer.
\set ON_ERROR_STOP on
begin;
insert into auth.users(id,email) values
 ('a0000000-0000-4000-8000-000000000001','share-owner@example.invalid'),
 ('a0000000-0000-4000-8000-000000000002','share-other@example.invalid');
insert into profiles(id,email,display_name) values
 ('a0000000-0000-4000-8000-000000000001','share-owner@example.invalid','Share owner'),
 ('a0000000-0000-4000-8000-000000000002','share-other@example.invalid','Other owner')
on conflict(id) do nothing;
insert into shares(token,kind,ref_id,created_by,revoked) values
 ('b0000000-0000-4000-8000-000000000001','round',gen_random_uuid(),'a0000000-0000-4000-8000-000000000001',false),
 ('b0000000-0000-4000-8000-000000000002','round',gen_random_uuid(),'a0000000-0000-4000-8000-000000000002',false),
 ('b0000000-0000-4000-8000-000000000003','round',gen_random_uuid(),'a0000000-0000-4000-8000-000000000001',true);
insert into storage.objects(bucket_id,name) values
 ('shared','b0000000-0000-4000-8000-000000000002.png'),
 ('shared','b0000000-0000-4000-8000-000000000003.png');
select set_config('sim.uid','a0000000-0000-4000-8000-000000000001',true);
set local role authenticated;
insert into storage.objects(bucket_id,name) values
 ('shared','b0000000-0000-4000-8000-000000000001.jpg'),
 ('shared','b0000000-0000-4000-8000-000000000001.png');
do $$ declare n integer; begin
  if (select count(*) from storage.objects where bucket_id='shared') <> 3 then
    raise exception 'The owner cannot list both formats plus their revoked copy';
  end if;
  if exists(select 1 from storage.objects where name='b0000000-0000-4000-8000-000000000002.png') then
    raise exception 'Another golfer copy became listable';
  end if;
  begin
    insert into storage.objects(bucket_id,name) values('shared','b0000000-0000-4000-8000-000000000002.jpg');
    raise exception 'Another golfer copy became writable';
  exception when insufficient_privilege then null; end;
  begin
    insert into storage.objects(bucket_id,name) values('shared','b0000000-0000-4000-8000-000000000003.jpg');
    raise exception 'A revoked token became writable';
  exception when insufficient_privilege then null; end;
  delete from storage.objects where bucket_id='shared';
  get diagnostics n = row_count;
  if n <> 3 then raise exception 'The owner could not remove all their copies'; end if;
end $$;
reset role;
do $$ begin
  if not exists(select 1 from storage.objects where name='b0000000-0000-4000-8000-000000000002.png') then
    raise exception 'Another golfer copy was deleted';
  end if;
  if has_function_privilege('anon','can_write_share_copy(text)','execute')
    or has_function_privilege('anon','can_drop_share_copy(text)','execute') then
    raise exception 'The anonymous surface changed';
  end if;
end $$;
select 'PASS: owner JPEG/PNG upload, listing and cleanup; other owners and revoked writes denied';
rollback;
