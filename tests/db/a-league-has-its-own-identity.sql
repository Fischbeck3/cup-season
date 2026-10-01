-- Isolated PostgreSQL sandbox ONLY: synthetic cast, rolled back.
\set ON_ERROR_STOP on
begin;
insert into auth.users (id, email) values
 ('00000000-0000-4000-8000-00000000a401', 'pro.clubspread@example.invalid'),
 ('00000000-0000-4000-8000-00000000a402', 'member.clubspread@example.invalid'),
 ('00000000-0000-4000-8000-00000000a403', 'outside.clubspread@example.invalid'),
 ('00000000-0000-4000-8000-00000000a404', 'left.clubspread@example.invalid'),
 ('00000000-0000-4000-8000-00000000a405', 'suspended.clubspread@example.invalid'),
 ('00000000-0000-4000-8000-00000000a406', 'deleted.clubspread@example.invalid');
update profiles set display_name = 'QA Pro', marker = 'lonetree' where id = '00000000-0000-4000-8000-00000000a401';
update profiles set display_name = 'QA Member', marker = 'dunes' where id = '00000000-0000-4000-8000-00000000a402';
insert into leagues (id, name, code, commissioner_id, phase) values
 ('00000000-0000-4000-8000-00000000b401', 'QA Spread', 'SPD401', '00000000-0000-4000-8000-00000000a401', 'setup');
insert into league_members (id, league_id, profile_id, role) values
 ('00000000-0000-4000-8000-00000000d401', '00000000-0000-4000-8000-00000000b401', '00000000-0000-4000-8000-00000000a401', 'commissioner'),
 ('00000000-0000-4000-8000-00000000d402', '00000000-0000-4000-8000-00000000b401', '00000000-0000-4000-8000-00000000a402', 'player'),
 ('00000000-0000-4000-8000-00000000d404', '00000000-0000-4000-8000-00000000b401', '00000000-0000-4000-8000-00000000a404', 'player'),
 ('00000000-0000-4000-8000-00000000d405', '00000000-0000-4000-8000-00000000b401', '00000000-0000-4000-8000-00000000a405', 'player'),
 ('00000000-0000-4000-8000-00000000d406', '00000000-0000-4000-8000-00000000b401', '00000000-0000-4000-8000-00000000a406', 'player');
update league_members set left_at = now() where id = '00000000-0000-4000-8000-00000000d404';
update league_members set suspended_at = now() where id = '00000000-0000-4000-8000-00000000d405';
update profiles set deleted_at = now() where id = '00000000-0000-4000-8000-00000000a406';
do $$
begin
 begin
  update leagues set identity_image_path = 'unpaired.png' where id = '00000000-0000-4000-8000-00000000b401';
  raise exception 'Image without kind accepted';
 exception when check_violation then null; end;
end $$;

select set_config('sim.uid', '00000000-0000-4000-8000-00000000a401', true);
set local role authenticated;
insert into storage.objects (bucket_id, name, owner_id) values
 ('league-media', '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e401.png', auth.uid()::text);
do $$
begin
 begin
  insert into leagues (name, code, commissioner_id, identity_description)
   values ('QA forged identity', 'SPD402', auth.uid(), 'bypassed setter');
  raise exception 'Direct creation bypassed identity validation';
 exception when invalid_parameter_value then null; end;
end $$;
select set_league_identity('00000000-0000-4000-8000-00000000b401', '  Our Saturday golf.  ',
 '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e401.png', 'logo');
do $$
declare v jsonb := league_identities()->0;
begin
 if v->>'description' <> 'Our Saturday golf.' or (v->>'member_count')::int <> 2
    or jsonb_array_length(v->'people') <> 2 or v->'people'->0->>'id' <> auth.uid()::text
    then raise exception 'Identity/roster response is wrong: %', v; end if;
 if public.league_media_retired(v->>'image_path') then raise exception 'Active image is deletable'; end if;
 delete from storage.objects where bucket_id = 'league-media' and name = v->>'image_path';
 if not exists (select 1 from storage.objects where bucket_id = 'league-media' and name = v->>'image_path')
   then raise exception 'RLS deleted active image'; end if;
 begin
   perform set_league_identity('00000000-0000-4000-8000-00000000b401', repeat('a', 161), '', '');
   raise exception 'Oversized description accepted';
 exception when invalid_parameter_value then null; end;
 begin
   perform set_league_identity('00000000-0000-4000-8000-00000000b401', '',
     '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e402.jpg', 'photo');
   raise exception 'Unuploaded image accepted';
 exception when invalid_parameter_value then null; end;
 raise notice 'PASS Pro save, normalization, bounded description, uploaded-image validation, active-image protection';
end $$;

select set_config('sim.uid', '00000000-0000-4000-8000-00000000a402', true);
do $$
begin
 if jsonb_array_length(league_identities()) <> 1 then raise exception 'Member cannot read identity'; end if;
 if not public.league_media_access('00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e401.png')
   then raise exception 'Member cannot read image'; end if;
 begin
   perform set_league_identity('00000000-0000-4000-8000-00000000b401', 'changed', '', '');
   raise exception 'Member can edit identity';
 exception when insufficient_privilege then null; end;
 begin
   insert into storage.objects (bucket_id, name) values
    ('league-media', '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e402.png');
   raise exception 'Member can upload';
 exception when insufficient_privilege then null; end;
 raise notice 'PASS member read; edit and upload refused';
end $$;
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a403', true);
do $$
begin
 if league_identities() <> '[]'::jsonb then raise exception 'Outsider receives identity'; end if;
 if exists (select 1 from storage.objects where bucket_id = 'league-media') then raise exception 'Outsider reads image'; end if;
 if public.league_media_access('invalid/invalid.png') then raise exception 'Invalid path accepted'; end if;
 begin
   perform set_league_identity('00000000-0000-4000-8000-00000000b401', 'changed', '', '');
   raise exception 'Outsider can edit identity';
 exception when insufficient_privilege then null; end;
 raise notice 'PASS outsider reads no identity/image, malformed paths refused, edit refused';
end $$;
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a401', true);
select set_league_identity('00000000-0000-4000-8000-00000000b401', '', '', '');
do $$
begin
 if not public.league_media_retired('00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e401.png')
    then raise exception 'Retired image cannot be reclaimed'; end if;
 if league_identities()->0->>'description' is not null or league_identities()->0->>'image_path' is not null
    then raise exception 'Clear did not clear identity'; end if;
 if has_function_privilege('anon', 'public.league_identities()', 'execute')
   or has_function_privilege('anon', 'public.set_league_identity(uuid,text,text,text)', 'execute')
   then raise exception 'Anon RPC grant'; end if;
 raise notice 'PASS clear, retired-image reclaim, anon grants';
end $$;
delete from storage.objects where bucket_id = 'league-media';
do $$ begin
 if exists (select 1 from storage.objects where bucket_id = 'league-media')
  then raise exception 'Retired image was not deleted'; end if;
end $$;

-- Pro handoff retains shared identity; account deletion removes the author's
-- contribution and leaves physical reclamation to the existing queue/worker.
insert into storage.objects (bucket_id, name, owner_id) values
 ('league-media', '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e402.png', auth.uid()::text);
select set_league_identity('00000000-0000-4000-8000-00000000b401', 'Our shared group.',
 '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e402.png', 'logo');
reset role;
update leagues set commissioner_id = '00000000-0000-4000-8000-00000000a402'
 where id = '00000000-0000-4000-8000-00000000b401';
do $$ begin
 if (select identity_description from leagues where code = 'SPD401') <> 'Our shared group.'
  then raise exception 'Handoff discarded identity'; end if;
end $$;
update profiles set deleted_at = now() where id = '00000000-0000-4000-8000-00000000a401';
do $$ begin
 if exists (select 1 from leagues where code = 'SPD401' and
   (identity_description is not null or identity_image_path is not null))
   then raise exception 'Deleted author still supplies identity'; end if;
 if has_function_privilege('authenticated', 'public._league_media_cleanup_paths(uuid)', 'execute')
   or has_function_privilege('anon', 'public._league_media_cleanup_paths(uuid)', 'execute')
   then raise exception 'Cleanup paths are client callable'; end if;
 if (select count(*) from public._league_media_cleanup_paths('00000000-0000-4000-8000-00000000a401')) <> 1
   or exists (select 1 from public._league_media_cleanup_paths('00000000-0000-4000-8000-00000000a402'))
   then raise exception 'Cleanup owner scope is wrong'; end if;
 if public._media_cleanup_report('00000000-0000-4000-8000-00000000a401') <> 'error'
   then raise exception 'Cleanup marked completed while league image remains'; end if;
end $$;
-- Sandbox-only physical deletion simulates a successful Storage API removal.
delete from storage.objects where bucket_id = 'league-media'
 and owner_id = '00000000-0000-4000-8000-00000000a401';
do $$ begin
 if public._media_cleanup_report('00000000-0000-4000-8000-00000000a401') <> 'completed'
   then raise exception 'Cleanup did not complete after physical removal'; end if;
 raise notice 'PASS handoff retention, deletion privacy, cleanup ownership/grants, physical deletion confirmation';
end $$;
update leagues set identity_description = 'Hard-delete contribution',
 identity_description_owner = '00000000-0000-4000-8000-00000000a403',
 identity_image_path = '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e403.png',
 identity_image_kind = 'photo', identity_image_owner = '00000000-0000-4000-8000-00000000a403'
 where code = 'SPD401';
delete from profiles where id = '00000000-0000-4000-8000-00000000a403';
do $$ begin
 if exists (select 1 from leagues where code = 'SPD401' and
   (identity_description is not null or identity_image_path is not null))
   then raise exception 'Hard-deleted author still supplies identity'; end if;
 begin
  update leagues set identity_image_kind = 'photo',
   identity_image_path = '00000000-0000-4000-8000-00000000b402/00000000-0000-4000-8000-00000000e403.png'
   where code = 'SPD401';
  raise exception 'Image namespace can cross leagues';
 exception when check_violation then null; end;
 raise notice 'PASS hard-deletion privacy and row-level image namespace';
end $$;
-- A still-valid token cannot re-publish after deletion, even if its old Pro
-- role remains in a historical record.
update leagues set commissioner_id = '00000000-0000-4000-8000-00000000a401' where code = 'SPD401';
set local role authenticated;
do $$ begin
 if league_identities() <> '[]'::jsonb or public.league_media_access(
   '00000000-0000-4000-8000-00000000b401/00000000-0000-4000-8000-00000000e404.png', true)
   then raise exception 'Deleted account still receives identity access'; end if;
 begin
  perform set_league_identity('00000000-0000-4000-8000-00000000b401', 'resurrected', '', '');
  raise exception 'Deleted Pro republished identity';
 exception when insufficient_privilege then null; end;
 raise notice 'PASS deleted-account token cannot re-publish identity';
end $$;
rollback;
