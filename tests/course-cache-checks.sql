-- Local isolated PostgreSQL only; not a production diagnostic.
\set ON_ERROR_STOP on
begin;
select cache_course_card('{"id":"1","course_name":"Original"}',
 '[{"gender":"male","tee_name":"Blue","course_rating":72,"holes":[{"hole_number":1,"par":4}]}]');
create temp table original as select id from api_course_tees where course_id='1';
do $$ begin
  begin
    perform cache_course_card('{"id":"1","course_name":"Bad replacement"}',
      '[{"gender":"male","tee_name":"Blue","holes":[{"hole_number":1,"par":5},{"hole_number":1,"par":3}]}]');
    raise exception 'Expected duplicate-hole rejection';
  exception when unique_violation then null; end;
  if (select course_name from api_courses where id='1') <> 'Original'
    or (select par from api_course_holes) <> 4 then raise exception 'Partial write escaped rollback'; end if;
  perform cache_course_card('{"id":"1","course_name":"Refreshed"}',
    '[{"gender":"male","tee_name":"Blue","course_rating":73,"holes":[]}]');
  if (select id from api_course_tees) <> (select id from original)
    or (select par from api_course_holes) <> 4 then raise exception 'Sparse refresh erased card or changed tee identity'; end if;
  begin
    perform cache_course_card('{"id":"1"}','[]');
    raise exception 'Expected incomplete-card rejection';
  exception when raise_exception then
    if sqlerrm <> 'Course card is incomplete' then raise; end if;
  end;
  if has_function_privilege('authenticated','cache_course_card(jsonb,jsonb)','execute')
    or has_function_privilege('anon','cache_course_card(jsonb,jsonb)','execute')
    or not has_function_privilege('service_role','cache_course_card(jsonb,jsonb)','execute') then
    raise exception 'Incorrect API grants'; end if;
end $$;
set role authenticated;
do $$ begin
  begin
    perform public.cache_course_card('{"id":"1"}','[]');
    raise exception 'Client unexpectedly wrote the cache';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
select 'PASS: rollback, sparse card, stable tee identity, invalid card, grants, restricted-role denial';
rollback;
