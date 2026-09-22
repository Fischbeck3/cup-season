-- Run only against the isolated full-chain sandbox. apply.sh must NOT run
-- between seeding the cache here and reapplying the migration below.
\set ON_ERROR_STOP on
begin;
select public.cache_course_card(
  '{"id":"__cache_reapply_probe__","course_name":"Kept card"}',
  '[{"gender":"male","tee_name":"Blue","course_rating":72,"holes":[{"hole_number":1,"par":4}]}]');
create temp table cache_reapply_identity as
  select id from api_course_tees where course_id='__cache_reapply_probe__';

\ir ../supabase/migrations/20261116090000_course_cache_atomic.sql

-- The function still works, preserving the existing tee and sparse hole card.
select public.cache_course_card(
  '{"id":"__cache_reapply_probe__","course_name":"After reapply"}',
  '[{"gender":"male","tee_name":"Blue","course_rating":73,"holes":[]}]');
do $$ begin
  if (select id from api_course_tees where course_id='__cache_reapply_probe__')
       <> (select id from cache_reapply_identity)
     or (select par from api_course_holes where tee_id in (select id from cache_reapply_identity)) <> 4
     or (select course_name from api_courses where id='__cache_reapply_probe__') <> 'After reapply' then
    raise exception 'Reapplying the migration lost the populated cache';
  end if;
  if has_function_privilege('authenticated','cache_course_card(jsonb,jsonb)','execute')
    or has_function_privilege('anon','cache_course_card(jsonb,jsonb)','execute')
    or not has_function_privilege('service_role','cache_course_card(jsonb,jsonb)','execute') then
    raise exception 'Reapplying changed the cache RPC grants';
  end if;
end $$;
select 'PASS: migration reapplied on the same populated database, card retained, RPC and grants intact';
rollback;
