-- run_month_closes() oid=18449
CREATE OR REPLACE FUNCTION public.run_month_closes()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; v_month date; i int; v_state text; v_msg text; v_first date;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    v_first := date_trunc('month', se.starts_on)::date;
    -- the month that just ended, then the two before it (catch-up)
    for i in 1..3 loop
      v_month := (date_trunc('month', current_date) - (i || ' month')::interval)::date;
      exit when v_month < v_first;
      begin
        perform close_month(se.id, v_month);
      exception when others then
        get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
        insert into job_failures (job, subject, sqlstate, message)
        values ('run_month_closes',
                'season ' || se.id::text || ' month ' || v_month::text,
                v_state, v_msg);
        -- and on to the next month / the next league. A league that cannot
        -- close must not close the book on anybody else's.
      end;
    end loop;
  end loop;
end $function$

