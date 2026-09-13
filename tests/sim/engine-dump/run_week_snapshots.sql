-- run_week_snapshots() oid=18450
CREATE OR REPLACE FUNCTION public.run_week_snapshots()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; v_state text; v_msg text;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    begin
      perform snapshot_week(se.id);
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
      insert into job_failures (job, subject, sqlstate, message)
      values ('run_week_snapshots', 'season ' || se.id::text, v_state, v_msg);
    end;
  end loop;
end $function$

