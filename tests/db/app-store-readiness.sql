-- Isolated PostgreSQL sandbox ONLY: synthetic cast, rolled back.
-- D402 / D403 · the word list, the golfer report, photo takedown, the ban and its
-- session gate, the live-stake ceiling, and the grants that guard them.
--
--   tests/sim/sandbox/apply.sh   (builds the cluster with every migration)
--   psql -h /tmp/cs-sim-sock -p 5478 -U postgres -d cupseason -f tests/db/app-store-readiness.sql
--
-- Every assertion about denial runs as `authenticated` with sim.uid set — never as
-- postgres, which bypasses row security and proves nothing.
\set ON_ERROR_STOP on
begin;

create function pg_temp.refused(p_sql text, p_msg text) returns void
language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if position(p_msg in sqlerrm) > 0 then return; end if;
    raise exception 'expected "%" but got "%" for: %', p_msg, sqlerrm, p_sql;
  end;
  raise exception 'expected a refusal ("%") for: %', p_msg, p_sql;
end $$;
grant execute on function pg_temp.refused(text, text) to authenticated, anon;
create function pg_temp.as_golfer(p uuid) returns void language sql as
  $$ select set_config('sim.uid', coalesce(p::text, ''), true) $$;
grant execute on function pg_temp.as_golfer(uuid) to authenticated, anon;

-- ---- the cast ----------------------------------------------------------------
insert into auth.users (id, email) values
 ('00000000-0000-4000-8000-00000000f001', 'founder.asr@example.invalid'),
 ('00000000-0000-4000-8000-00000000f002', 'alpha.asr@example.invalid'),
 ('00000000-0000-4000-8000-00000000f003', 'bravo.asr@example.invalid'),
 ('00000000-0000-4000-8000-00000000f004', 'outside.asr@example.invalid');
update profiles set is_founder = false where is_founder;
update profiles set display_name = 'QA Founder', handle = 'qa_founder', marker = 'lonetree', is_founder = true
 where id = '00000000-0000-4000-8000-00000000f001';
update profiles set display_name = 'QA Alpha', handle = 'qa_alpha', marker = 'dunes',
       photo_path = '00000000-0000-4000-8000-00000000f002/avatar.jpg'
 where id = '00000000-0000-4000-8000-00000000f002';
update profiles set display_name = 'QA Bravo', handle = 'qa_bravo', marker = 'thistle'
 where id = '00000000-0000-4000-8000-00000000f003';
update profiles set display_name = 'QA Outside', handle = 'qa_outside', marker = 'island'
 where id = '00000000-0000-4000-8000-00000000f004';

insert into leagues (id, name, code, commissioner_id, phase) values
 ('00000000-0000-4000-8000-00000000e001', 'QA Readiness', 'ASR001', '00000000-0000-4000-8000-00000000f003', 'season');
insert into league_members (id, league_id, profile_id, role) values
 ('00000000-0000-4000-8000-00000000d001', '00000000-0000-4000-8000-00000000e001', '00000000-0000-4000-8000-00000000f002', 'player'),
 ('00000000-0000-4000-8000-00000000d002', '00000000-0000-4000-8000-00000000e001', '00000000-0000-4000-8000-00000000f003', 'commissioner');
insert into rounds (id, profile_id, course_label, gross, rating, slope, index_at_post, played_on, photo_path) values
 ('00000000-0000-4000-8000-00000000c001', '00000000-0000-4000-8000-00000000f002', 'QA Links', 84, 70.2, 119, 12.0,
  current_date - 1, '00000000-0000-4000-8000-00000000f002/round1.jpg');
insert into shares (token, kind, ref_id, created_by) values
 ('00000000-0000-4000-8000-0000000051a1', 'round', '00000000-0000-4000-8000-00000000c001', '00000000-0000-4000-8000-00000000f002');
insert into storage.objects (bucket_id, name) values
 ('media', '00000000-0000-4000-8000-00000000f002/round1.jpg'),
 ('media', '00000000-0000-4000-8000-00000000f002/avatar.jpg');
insert into device_tokens (token, profile_id, platform) values ('qa-token-alpha', '00000000-0000-4000-8000-00000000f002', 'ios');

-- ============================================================================
-- 1 · the word list — direct writes, as a golfer, under row security
-- ============================================================================
set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f002');

-- allowed: swearing, banter, golf
insert into posts (league_id, kind, member_id, body) values
 ('00000000-0000-4000-8000-00000000e001', 'chat', '00000000-0000-4000-8000-00000000d001',
  'Shot 79, killed that drive. We''re gonna beat you Saturday — who''s the bitch now? Fuck yeah.');

-- refused: a slur, an obfuscated slur, explicit content, a stated threat
select pg_temp.refused($q$insert into posts (league_id, kind, member_id, body) values
  ('00000000-0000-4000-8000-00000000e001','chat','00000000-0000-4000-8000-00000000d001','you f4gg0t')$q$, 'Cup Season can''t take that wording');
select pg_temp.refused($q$insert into posts (league_id, kind, member_id, body) values
  ('00000000-0000-4000-8000-00000000e001','chat','00000000-0000-4000-8000-00000000d001','n i g g e r')$q$, 'Cup Season can''t take that wording');
select pg_temp.refused($q$insert into posts (league_id, kind, member_id, body) values
  ('00000000-0000-4000-8000-00000000e001','chat','00000000-0000-4000-8000-00000000d001','send nudes')$q$, 'Cup Season can''t take that wording');
select pg_temp.refused($q$insert into posts (league_id, kind, member_id, body) values
  ('00000000-0000-4000-8000-00000000e001','chat','00000000-0000-4000-8000-00000000d001','I''m gonna stab you')$q$, 'Cup Season can''t take that wording');

-- the edit bypass: clients hold no UPDATE on posts, comments or plans (writes are
-- RPCs), so the paths that write golfer text are the RPCs themselves
select pg_temp.refused($q$select declare_round(current_date + 3, 'QA Links', 'k y s', null, null, null, null, null)$q$,
  'Cup Season can''t take that wording');
select declare_round(current_date + 3, 'QA Links', 'Bring the rangefinder.', null, null, null, 'Saturday nine', null);
select pg_temp.refused($q$select set_profile('Big N1gga', null, null, null, null, null, null, null)$q$, 'Cup Season can''t take that wording');
select pg_temp.refused($q$select set_handle('f_a_g_g_o_t')$q$, 'Cup Season can''t take that wording');

-- every other listed path
select pg_temp.refused($q$insert into round_comments (round_id, profile_id, body) values
  ('00000000-0000-4000-8000-00000000c001','00000000-0000-4000-8000-00000000f002','kill yourself')$q$, 'Cup Season can''t take that wording');
insert into post_comments (post_id, member_id, body)
  select id, '00000000-0000-4000-8000-00000000d001', 'Torched it. Drinks on you, dickhead.' from posts
   where member_id = '00000000-0000-4000-8000-00000000d001' and kind = 'chat' limit 1;
select pg_temp.refused($q$insert into post_comments (post_id, member_id, body)
  select id, '00000000-0000-4000-8000-00000000d001', 'go die' from posts
   where member_id = '00000000-0000-4000-8000-00000000d001' and kind = 'chat' limit 1$q$, 'Cup Season can''t take that wording');
select set_profile('QA Alpha', 'Coon Rapids', null, null, null, null, null, null);   -- a real place passes
reset role;

-- server-written posts are never filtered: a round story with any text still posts
do $$
begin
  insert into posts (league_id, kind, body) values
    ('00000000-0000-4000-8000-00000000e001', 'system', 'QA system line naming a retard');   -- server kind: not filtered
  -- a pre-existing row with old text can still be edited in another column
  alter table public.posts disable trigger cs_text_guard;
  insert into posts (id, league_id, kind, member_id, body) values
    ('00000000-0000-4000-8000-0000000b0001', '00000000-0000-4000-8000-00000000e001', 'chat',
     '00000000-0000-4000-8000-00000000d001', 'legacy f4gg0t');
  alter table public.posts enable trigger cs_text_guard;
  update posts set hidden_at = now(), hidden_reason = 'QA' where id = '00000000-0000-4000-8000-0000000b0001';
end $$;

-- ============================================================================
-- 2 · a golfer report (p_kind 'profile') files and wakes the founder
-- ============================================================================
set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
select report_content(null, 'Harassment or abuse', 'profile', '00000000-0000-4000-8000-00000000f002', null);
select report_content(null, 'An inappropriate photo', 'profile', '00000000-0000-4000-8000-00000000f002', null); -- twice → one open row
select pg_temp.refused($q$select report_content(null, 'x', 'profile', '00000000-0000-4000-8000-00000000f003', null)$q$, 'can''t report yourself');
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f004');
select pg_temp.refused($q$select report_content(null, 'x', 'profile', '00000000-0000-4000-8000-00000000f002', null)$q$, 'You can only report golfers');
reset role;
do $$
begin
  if (select count(*) from content_reports where kind = 'profile' and profile_id = '00000000-0000-4000-8000-00000000f002') <> 1 then
    raise exception 'golfer report: expected exactly one open row';
  end if;
  if not exists (select 1 from push_nudges where profile_id = '00000000-0000-4000-8000-00000000f001'
                  and body like 'Someone reported a golfer%') then
    raise exception 'golfer report: the founder was not woken';
  end if;
end $$;

-- ============================================================================
-- 3 · the desk: only the founder reads it, and it carries what the desk acts on
-- ============================================================================
set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
select pg_temp.refused($q$select moderation_queue()$q$, 'the desk is the founder''s');
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f001');
do $$
declare q jsonb := moderation_queue(); r jsonb;
begin
  select e into r from jsonb_array_elements(q) e where e->>'kind' = 'profile' limit 1;
  if r is null then raise exception 'desk: golfer report missing'; end if;
  if r->>'subject_profile_id' <> '00000000-0000-4000-8000-00000000f002' then raise exception 'desk: wrong subject %', r; end if;
  if r->>'subject_handle' <> 'qa_alpha' or (r->>'profile_has_photo')::boolean is not true then raise exception 'desk: fields %', r; end if;
end $$;
reset role;

-- ============================================================================
-- 4 · photo takedown — founder only; scores stand; the object and its shares go dark
-- ============================================================================
set local role authenticated;
-- a league-mate can see the photo before
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
do $$ begin
  if not exists (select 1 from storage.objects where name = '00000000-0000-4000-8000-00000000f002/round1.jpg') then
    raise exception 'takedown: precondition — the league-mate could not read the photo';
  end if;
end $$;
select pg_temp.refused($q$select takedown_photo('round_photo','00000000-0000-4000-8000-00000000c001','QA reason')$q$, 'Only the founder');
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f001');
select pg_temp.refused($q$select takedown_photo('round_photo','00000000-0000-4000-8000-00000000c001','')$q$, 'Say why');
select takedown_photo('round_photo', '00000000-0000-4000-8000-00000000c001', 'QA: explicit image');
select takedown_photo('profile_photo', '00000000-0000-4000-8000-00000000f002', 'QA: explicit avatar',
  (select (e->>'id')::uuid from jsonb_array_elements(moderation_queue()) e where e->>'kind' = 'profile' limit 1));
-- the league-mate and the owner can no longer read either object
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
do $$ begin
  if exists (select 1 from storage.objects where bucket_id = 'media' and name like '00000000-0000-4000-8000-00000000f002/%') then
    raise exception 'takedown: a league-mate can still read a taken-down object';
  end if;
end $$;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f002');
do $$ begin
  if exists (select 1 from storage.objects where bucket_id = 'media' and name = '00000000-0000-4000-8000-00000000f002/round1.jpg') then
    raise exception 'takedown: the owner can still read a taken-down object';
  end if;
end $$;
reset role;
do $$
declare r rounds;
begin
  select * into r from rounds where id = '00000000-0000-4000-8000-00000000c001';
  if r.photo_path is not null then raise exception 'takedown: photo_path not cleared'; end if;
  if r.gross <> 84 or r.rating <> 70.2 or r.slope <> 119 or r.differential is null then
    raise exception 'takedown: the factual round changed';
  end if;
  if (select photo_path from profiles where id = '00000000-0000-4000-8000-00000000f002') is not null then
    raise exception 'takedown: avatar not cleared';
  end if;
  if not (select revoked from shares where token = '00000000-0000-4000-8000-0000000051a1') then
    raise exception 'takedown: the round share was not revoked';
  end if;
  if not exists (select 1 from share_cleanup where token = '00000000-0000-4000-8000-0000000051a1') then
    raise exception 'takedown: the public copies were not queued for share-cleanup';
  end if;
  if (select count(*) from moderation_actions where action = 'takedown_photo') <> 2 then
    raise exception 'takedown: audit rows missing';
  end if;
  if not (select resolved from content_reports where kind = 'profile' and profile_id = '00000000-0000-4000-8000-00000000f002') then
    raise exception 'takedown: the report was not resolved';
  end if;
end $$;

-- ============================================================================
-- 5 · the ban — founder only, typed confirmation, every session refused, unban
-- ============================================================================
set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
select pg_temp.refused($q$select ban_account('00000000-0000-4000-8000-00000000f002','qa_alpha','QA reason')$q$, 'Only the founder');
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f001');
select pg_temp.refused($q$select ban_account('00000000-0000-4000-8000-00000000f002','qa_bravo','QA reason')$q$, 'Type the golfer''s handle');
select pg_temp.refused($q$select ban_account('00000000-0000-4000-8000-00000000f002','qa_alpha','')$q$, 'Say why');
select pg_temp.refused($q$select ban_account('00000000-0000-4000-8000-00000000f001','qa_founder','QA reason')$q$, 'can''t be removed');
select ban_account('00000000-0000-4000-8000-00000000f002', '@QA_Alpha', 'QA: threats after a warning');

-- the banned golfer's still-valid session: the gate refuses every request
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f002');
select pg_temp.refused($q$select cs_internal.request_gate()$q$, 'This account has been closed.');
-- and the storage service, which PostgREST's gate does not see, refuses uploads
select pg_temp.refused($q$insert into storage.objects (bucket_id, name) values ('media','00000000-0000-4000-8000-00000000f002/again.jpg')$q$,
  'row-level security');
-- everyone else passes the gate, signed in or not
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
select cs_internal.request_gate();
reset role;
set local role anon;
select pg_temp.as_golfer(null);
select cs_internal.request_gate();
reset role;
do $$
begin
  if (select banned_until from auth.users where id = '00000000-0000-4000-8000-00000000f002') <> 'infinity'::timestamptz then
    raise exception 'ban: auth.users.banned_until not set';
  end if;
  if exists (select 1 from device_tokens where profile_id = '00000000-0000-4000-8000-00000000f002') then
    raise exception 'ban: push targets kept';
  end if;
end $$;

set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f001');
select pg_temp.refused($q$select unban_account('00000000-0000-4000-8000-00000000f003','QA reason')$q$, 'not removed');
select unban_account('00000000-0000-4000-8000-00000000f002', 'QA: appeal accepted');
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f002');
select cs_internal.request_gate();     -- passes again
reset role;
do $$
begin
  if (select banned_until from auth.users where id = '00000000-0000-4000-8000-00000000f002') is not null then
    raise exception 'unban: banned_until kept';
  end if;
  if (select count(*) from moderation_actions where action in ('ban','unban')) <> 2 then
    raise exception 'ban: audit rows missing';
  end if;
end $$;

-- ============================================================================
-- 6 · the live stake ceiling — new or changed only; history stands
-- ============================================================================
-- clients hold no INSERT on live_rounds (start_live_round is the door); the trigger
-- guards the table itself, whoever writes — so the refusals are asserted at the table
select pg_temp.refused($q$insert into live_rounds (course_label, course_snapshot, game, game_config, starter_profile_id)
  values ('QA Links', '{}'::jsonb, 'skins', '{"stake":250}'::jsonb, '00000000-0000-4000-8000-00000000f002')$q$,
  'Stakes top out at $200 a golfer.');
select pg_temp.refused($q$insert into live_rounds (course_label, course_snapshot, game, game_config, starter_profile_id)
  values ('QA Links', '{}'::jsonb, 'sunningdale', '{"unit":201}'::jsonb, '00000000-0000-4000-8000-00000000f002')$q$,
  'Stakes top out at $200 a golfer.');
do $$
begin
  insert into live_rounds (id, course_label, course_snapshot, game, game_config, starter_profile_id) values
    ('00000000-0000-4000-8000-00000000a501', 'QA Links', '{}'::jsonb, 'skins', '{"stake":200}'::jsonb,
     '00000000-0000-4000-8000-00000000f002');
  -- a pre-cap agreement, written before this trigger existed
  alter table public.live_rounds disable trigger live_stake_ceiling;
  insert into live_rounds (id, course_label, course_snapshot, game, game_config, starter_profile_id) values
    ('00000000-0000-4000-8000-00000000a502', 'QA Links', '{}'::jsonb, 'skins', '{"stake":500}'::jsonb,
     '00000000-0000-4000-8000-00000000f002');
  alter table public.live_rounds enable trigger live_stake_ceiling;
  -- it still finishes exactly as agreed
  update live_rounds set status = 'final', finished_at = now(), game_result = '{"stake":500}'::jsonb
   where id = '00000000-0000-4000-8000-00000000a502';
  if (select (game_config->>'stake')::numeric from live_rounds where id = '00000000-0000-4000-8000-00000000a502') <> 500 then
    raise exception 'stake: a historical agreement was clamped';
  end if;
  begin
    update live_rounds set game_config = '{"stake":300}'::jsonb where id = '00000000-0000-4000-8000-00000000a501';
    raise exception 'stake: a raised stake was accepted';
  exception when others then
    if sqlerrm not like 'Stakes top out%' then raise; end if;
  end;
  -- the season buy-in ceiling (D113) still holds at the table
  begin
    update league_settings set buyin_cents = 25000 where league_id = '00000000-0000-4000-8000-00000000e001';
  exception when check_violation then null;
  end;
end $$;

-- ============================================================================
-- 7 · grants — nothing new is an anon endpoint; internals are nobody's
-- ============================================================================
do $$
declare f text;
begin
  foreach f in array array['public.takedown_photo(text,uuid,text,uuid)', 'public.ban_account(uuid,text,text,uuid)',
                           'public.unban_account(uuid,text)', 'public.moderation_queue()'] loop
    if has_function_privilege('anon', f, 'execute') then raise exception 'grant: anon can execute %', f; end if;
    if not has_function_privilege('authenticated', f, 'execute') then raise exception 'grant: authenticated cannot execute %', f; end if;
  end loop;
  foreach f in array array['public.cs_text_refused(text,boolean)', 'public._cs_text_guard()', 'public._cs_fold(text)',
                           'public._live_stake_ceiling()', 'public.cs_text_refusal()'] loop
    if has_function_privilege('authenticated', f, 'execute') or has_function_privilege('anon', f, 'execute') then
      raise exception 'grant: % is executable by a client role', f;
    end if;
  end loop;
  if has_table_privilege('authenticated', 'public.account_bans', 'select')
     or has_table_privilege('authenticated', 'public.moderation_actions', 'select')
     or has_table_privilege('authenticated', 'public.media_takedowns', 'select') then
    raise exception 'grant: an audit table is readable by clients';
  end if;
end $$;

select 'app-store-readiness: all assertions passed' as result;
rollback;
