-- Isolated PostgreSQL sandbox ONLY: synthetic cast, rolled back.
-- D402 / D403 · the word list, the golfer report, photo takedown (and its file's
-- removal queue), the ban and its session gate, the live-stake ceiling, and the grants
-- that guard them.
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
-- 1b · the rest of D403's coverage (review, 2026-10-01): home course, a scan claim's
-- partner name and course, every typed course name, the Pro's ruling reason — with
-- official course names, given names and factual rounds left alone
-- ============================================================================
-- an official catalogue name that happens to contain a listed word (Dildo is a real
-- town in Newfoundland); fixtures are written as the server would
insert into api_courses (id, club_name, course_name, city, state, country)
values ('qa-asr-1', 'Dildo Arm Golf Club', 'Dildo Arm', 'Dildo', 'NL', 'Canada');
insert into seasons (id, league_id, starts_on, ends_on)
values ('00000000-0000-4000-8000-0000000005e1', '00000000-0000-4000-8000-00000000e001', current_date - 30, current_date + 60);

set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f002');
-- home course, through set_profile (the RPC both clients call)
select pg_temp.refused($q$select set_profile('QA Alpha', null, 'Kill Yourself Country Club', null, null, null, null, null)$q$, 'Cup Season can''t take that wording');
select pg_temp.refused($q$select set_profile('QA Alpha', null, 'R@pe Valley', null, null, null, null, null)$q$, 'Cup Season can''t take that wording');
select set_profile('QA Alpha', null, 'Dildo Arm Golf Club', null, null, null, null, null);        -- official: passes
select set_profile('QA Alpha', null, 'Dildo Arm Golf Club (Dildo, NL)', null, null, null, null, null); -- official words only
select pg_temp.refused($q$select set_profile('QA Alpha', null, 'Dildo Arm Golf Club, dildos for all', null, null, null, null, null)$q$, 'Cup Season can''t take that wording');
select set_profile('QA Alpha', null, 'Hooker Creek', null, null, null, null, null);              -- ordinary words pass
-- a scan claim: the partner's name (name mode) and the course the recipient reads
select pg_temp.refused($q$select create_scan_claim('n i g g e r', 84, '[]'::jsonb, 'QA Links', 70.1, 120, current_date, 18)$q$, 'Cup Season can''t take that wording');
select pg_temp.refused($q$select create_scan_claim('Pat', 84, '[]'::jsonb, 'kys golf club', 70.1, 120, current_date, 18)$q$, 'Cup Season can''t take that wording');
select create_scan_claim('Kike Hernandez', 84, '[]'::jsonb, 'Dildo Arm Golf Club', 70.1, 120, current_date, 18);  -- a given name, an official course
-- a round typed in: its course name (direct insert, the clients' own path)
select pg_temp.refused($q$insert into rounds (course_label, gross, rating, slope, played_on)
  values ('f a g g o t links', 84, 70.2, 119, current_date - 2)$q$, 'Cup Season can''t take that wording');
insert into rounds (course_label, gross, rating, slope, played_on)
  values ('Dildo Arm Golf Club', 84, 70.2, 119, current_date - 2);
-- a live round's course name, through start_live_round
select pg_temp.refused($q$select start_live_round(null, null, null, 'go die CC', '{"holes":18}'::jsonb, 'none',
  '[{"guest_name":"QA Alpha","guest_index":12,"guest_profile":"00000000-0000-4000-8000-00000000f002"}]'::jsonb, '{}'::jsonb, null)$q$, 'Cup Season can''t take that wording');
-- the Pro's ruling reason, through adjust_points (it is posted to the board)
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
select pg_temp.refused($q$select adjust_points('00000000-0000-4000-8000-0000000005e1', '00000000-0000-4000-8000-00000000d001', -2, 'for being a retard')$q$, 'Cup Season can''t take that wording');
reset role;

do $$
begin
  -- a legacy row with old text: an unrelated edit still goes through
  alter table public.profiles disable trigger cs_text_guard;
  update profiles set home_course = 'legacy kys links' where id = '00000000-0000-4000-8000-00000000f003';
  alter table public.profiles enable trigger cs_text_guard;
  update profiles set city = 'Tempe' where id = '00000000-0000-4000-8000-00000000f003';
  -- server-copied rounds are factual and never refused: a live round's or a claim's
  insert into rounds (profile_id, course_label, gross, rating, slope, index_at_post, played_on, source)
  values ('00000000-0000-4000-8000-00000000f003', 'legacy kys links', 90, 70.2, 119, 14.0, current_date - 3, 'live');
  -- the month close's own reasons are facts, and never stop the close
  insert into season_adjustments (season_id, month, kind, points, reason)
  values ('00000000-0000-4000-8000-0000000005e1', date_trunc('month', current_date)::date, 'floor_penalty', -1,
          'floor missed — legacy kys links');
  -- and the same text in the Pro's own kind is refused at the table too
  begin
    insert into season_adjustments (season_id, month, kind, points, reason)
    values ('00000000-0000-4000-8000-0000000005e1', date_trunc('month', current_date)::date, 'override', -1, 'kys');
    raise exception 'coverage: an override reason with a listed phrase was accepted';
  exception when raise_exception then
    if sqlerrm not like 'Cup Season can''t take that wording%' then raise; end if;
  end;
  if (select home_course from profiles where id = '00000000-0000-4000-8000-00000000f002') <> 'Hooker Creek' then
    raise exception 'coverage: the last good home course did not save';
  end if;
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

-- 4b · the FILE: queued for removal, confirmed only from storage.objects, retried with
-- backoff, and a new photo at the same path is a new photo (never blocked forever)
do $$
declare t media_takedowns; v text;
begin
  if (select count(*) from media_takedowns where status = 'pending') <> 2 then
    raise exception 'takedown: both files were not queued for removal';
  end if;
  select * into t from media_takedowns where path = '00000000-0000-4000-8000-00000000f002/round1.jpg';
  if t.hold_path <> t.id::text || '/' || t.path then raise exception 'takedown: hold path %', t.hold_path; end if;
  -- the worker's due list carries it
  if not exists (select 1 from _takedown_cleanup_due(20) d where d.id = t.id and d.phase = 'remove') then
    raise exception 'takedown: the file is not due for removal';
  end if;
  -- a report while the file is still stored is an error with backoff, never "removed"
  v := _takedown_cleanup_report(t.id, 'remove', null);
  if v <> 'error' then raise exception 'takedown: reported % while the file was still stored', v; end if;
  select * into t from media_takedowns where id = t.id;
  if t.status <> 'error' or t.next_try <= now() or t.last_error is null then raise exception 'takedown: no backoff %', row_to_json(t); end if;
  if exists (select 1 from _takedown_cleanup_due(20) d where d.id = t.id) then raise exception 'takedown: retried before its backoff'; end if;
  -- the Storage API moves it into the hold (simulated here as the API's own effect)
  update storage.objects set bucket_id = 'moderation-hold', name = t.hold_path
   where bucket_id = 'media' and name = t.path;
  v := _takedown_cleanup_report(t.id, 'remove', null);
  if v <> 'removed' then raise exception 'takedown: reported % after the move', v; end if;
  select * into t from media_takedowns where id = t.id;
  if t.removed_at is null or t.hold_path is null or t.purge_after < now() + interval '89 days' then
    raise exception 'takedown: removed without keeping the evidence on its clock %', row_to_json(t);
  end if;
  -- a removal that could not keep the evidence says so
  select * into t from media_takedowns where path = '00000000-0000-4000-8000-00000000f002/avatar.jpg';
  delete from storage.objects where bucket_id = 'media' and name = t.path;
  v := _takedown_cleanup_report(t.id, 'remove', 'move to moderation-hold: not supported');
  select * into t from media_takedowns where id = t.id;
  if v <> 'removed' or t.hold_path is not null or t.last_error not like 'evidence not kept%' then
    raise exception 'takedown: an unkept removal was not recorded honestly %', row_to_json(t);
  end if;
  -- purge: due once purge_after passes, and confirmed from the hold
  update media_takedowns set purge_after = now() - interval '1 minute' where path = '00000000-0000-4000-8000-00000000f002/round1.jpg';
  select * into t from media_takedowns where path = '00000000-0000-4000-8000-00000000f002/round1.jpg';
  if not exists (select 1 from _takedown_cleanup_due(20) d where d.id = t.id and d.phase = 'purge') then
    raise exception 'takedown: kept evidence never comes due for purge';
  end if;
  if _takedown_cleanup_report(t.id, 'purge', null) <> 'error' then raise exception 'takedown: purge claimed while kept'; end if;
  delete from storage.objects where bucket_id = 'moderation-hold' and name = t.hold_path;
  update media_takedowns set next_try = now() where id = t.id;
  if _takedown_cleanup_report(t.id, 'purge', null) <> 'purged' then raise exception 'takedown: purge not confirmed'; end if;
  -- a NEW avatar written at the same path after the takedown is readable again
  insert into storage.objects (bucket_id, name, created_at, updated_at)
  values ('media', '00000000-0000-4000-8000-00000000f002/avatar.jpg', now() + interval '1 second', now() + interval '1 second');
end $$;
set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f003');
do $$ begin
  if not exists (select 1 from storage.objects where bucket_id = 'media' and name = '00000000-0000-4000-8000-00000000f002/avatar.jpg') then
    raise exception 'takedown: a new photo at a taken-down path stays hidden forever';
  end if;
  -- the hold bucket is nobody's but the service role's
  if exists (select 1 from storage.objects where bucket_id = 'moderation-hold') then
    raise exception 'takedown: a client can see the evidence bucket';
  end if;
end $$;
select pg_temp.refused($q$insert into storage.objects (bucket_id, name) values ('moderation-hold', 'x/y.jpg')$q$, 'row-level security');
reset role;
do $$ begin
  if not exists (select 1 from storage.buckets where id = 'moderation-hold' and not public) then
    raise exception 'takedown: the evidence bucket is missing or public';
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
-- 6 · the live stake ceiling — through start_live_round as an authenticated golfer;
-- each amount read on its own; new or changed only; history settles as agreed
-- ============================================================================
create function pg_temp.start_with(p_cfg jsonb) returns jsonb language sql as $f$
  select start_live_round(null, null, null, 'QA Links',
    '{"label":"QA Links","rating":70.2,"slope":119,"holes":18,"pars":[4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]}'::jsonb,
    'skins',
    '[{"guest_name":"QA Alpha","guest_index":12,"guest_profile":"00000000-0000-4000-8000-00000000f002"},
      {"guest_name":"QA Bravo","guest_index":14,"guest_profile":"00000000-0000-4000-8000-00000000f003"}]'::jsonb,
    p_cfg, null)
$f$;
grant execute on function pg_temp.start_with(jsonb) to authenticated;
create function pg_temp.stake_refused(p_cfg text, p_msg text) returns void language plpgsql as $f$
begin
  perform pg_temp.refused(format('select pg_temp.start_with(%L::jsonb)', p_cfg), p_msg);
end $f$;
grant execute on function pg_temp.stake_refused(text, text) to authenticated;

set local role authenticated;
select pg_temp.as_golfer('00000000-0000-4000-8000-00000000f002');
-- over the cap, whatever its sibling holds — the review's case and its reverse
select pg_temp.stake_refused('{"stake":1000,"unit":"bad"}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"unit":1000,"stake":"bad"}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"stake":1000,"unit":""}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"stake":1000,"unit":{}}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"stake":1000,"unit":[]}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"stake":1000,"unit":null}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"unit":1000}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"stake":200.01}', 'Stakes top out at $200');
select pg_temp.stake_refused('{"stake":201}', 'Stakes top out at $200');
-- malformed amounts are refused, not read as zero
select pg_temp.stake_refused('{"stake":"bad"}', 'That stake isn''t an amount');
select pg_temp.stake_refused('{"stake":""}', 'That stake isn''t an amount');
select pg_temp.stake_refused('{"stake":"50"}', 'That stake isn''t an amount');
select pg_temp.stake_refused('{"stake":{}}', 'That stake isn''t an amount');
select pg_temp.stake_refused('{"stake":[]}', 'That stake isn''t an amount');
select pg_temp.stake_refused('{"stake":true}', 'That stake isn''t an amount');
select pg_temp.stake_refused('{"stake":-1}', 'That stake isn''t an amount');
select pg_temp.stake_refused('{"stake":5,"unit":"bad"}', 'That stake isn''t an amount');
-- a configuration that is not an object at all
select pg_temp.stake_refused('[]', 'That game setup can''t be read');
select pg_temp.stake_refused('"skins"', 'That game setup can''t be read');
select pg_temp.stake_refused('5', 'That game setup can''t be read');
-- accepted: boundaries, absent and null amounts, no config
do $$
declare c text;
begin
  foreach c in array array['{}', '{"stake":0}', '{"stake":200}', '{"unit":200}', '{"stake":199.99}', '{"stake":200,"unit":200}',
                           '{"stake":null}', '{"stake":null,"unit":null}', '{"stake":5,"mode":"solo"}'] loop
    if (pg_temp.start_with(c::jsonb)->>'live_round_id') is null then raise exception 'stake: % was not started', c; end if;
  end loop;
  if (pg_temp.start_with(null)->>'live_round_id') is null then raise exception 'stake: a null config was not started'; end if;
end $$;
reset role;

-- a pre-cap agreement: started before the ceiling existed (written as the old server
-- would have), then finished through the real RPC — settled exactly as agreed
do $$
declare v_lr uuid; v_seats jsonb; v_fin jsonb;
begin
  perform set_config('sim.uid', '00000000-0000-4000-8000-00000000f002', true);
  v_lr := (pg_temp.start_with('{"stake":200}'::jsonb)->>'live_round_id')::uuid;
  alter table public.live_rounds disable trigger live_stake_ceiling;
  update live_rounds set game_config = '{"stake":500}'::jsonb where id = v_lr;
  alter table public.live_rounds enable trigger live_stake_ceiling;
  -- an unrelated change to the config keeps the agreed amount (not re-read)...
  update live_rounds set game_config = game_config || '{"si_estimated":true}'::jsonb where id = v_lr;
  -- ...but raising or re-shaping it is a new amount
  begin
    update live_rounds set game_config = '{"stake":600,"si_estimated":true}'::jsonb where id = v_lr;
    raise exception 'stake: a raised historical stake was accepted';
  exception when raise_exception then
    if sqlerrm not like 'Stakes top out%' then raise; end if;
  end;
  begin
    update live_rounds set game_config = game_config || '{"unit":"bad"}'::jsonb where id = v_lr;
    raise exception 'stake: a malformed new sibling was accepted';
  exception when raise_exception then
    if sqlerrm not like 'That stake isn''t an amount%' then raise; end if;
  end;
  select jsonb_agg(jsonb_build_object('player_id', id, 'strokes', jsonb_build_array(4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4)))
    into v_seats from live_round_players where live_round_id = v_lr;
  set local role authenticated;
  v_fin := finish_live_round(v_lr, v_seats, false, '{"game":"skins","stake":500}'::jsonb);
  reset role;
  if (select status from live_rounds where id = v_lr) <> 'final' then raise exception 'stake: the historical round did not finish %', v_fin; end if;
  if (select (game_config->>'stake')::numeric from live_rounds where id = v_lr) <> 500 then
    raise exception 'stake: a historical agreement was clamped or rewritten';
  end if;
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
                           'public._live_stake_ceiling()', 'public.cs_text_refusal()',
                           'public._takedown_cleanup_due(integer)', 'public._takedown_cleanup_report(uuid,text,text)'] loop
    if has_function_privilege('authenticated', f, 'execute') or has_function_privilege('anon', f, 'execute') then
      raise exception 'grant: % is executable by a client role', f;
    end if;
  end loop;
  -- the gate runs for every role PostgREST serves (the live proof found service_role missing)
  foreach f in array array['anon', 'authenticated', 'service_role'] loop
    if not has_function_privilege(f, 'cs_internal.request_gate()', 'execute') or not has_schema_privilege(f, 'cs_internal', 'usage') then
      raise exception 'grant: % cannot run the pre-request gate, so its every API request would fail', f;
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
