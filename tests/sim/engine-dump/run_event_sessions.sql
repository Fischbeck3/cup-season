-- run_event_sessions() oid=19624
CREATE OR REPLACE FUNCTION public.run_event_sessions()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; v_today date; v_state text; v_msg text;
begin
  for s in
    select es.id, es.opens_on, es.closes_on, es.status, e.tz, e.id as ev, e.kind
      from event_sessions es join events e on e.id = es.event_id
     -- D146: 'complete' included so a clinched event's remaining sessions still
     -- open and resolve for the record (spec R4). resolve_session refuses to
     -- re-decide a settled event, so this cannot move a cup already awarded.
     where e.status in ('setup','live','complete')
     order by es.opens_on
  loop
    begin
      v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
      if s.kind = 'major' then
        if s.status = 'upcoming' and s.closes_on < v_today then
          perform settle_major(s.id);
        elsif s.status = 'upcoming' and s.opens_on <= v_today then
          if (select count(*) from event_players where event_id = s.ev) >= 2 then
            perform open_major(s.id);
          end if;
        elsif s.status = 'open' and s.closes_on = v_today then
          perform major_final_day(s.id);
        elsif s.status = 'open' and s.closes_on < v_today then
          perform settle_major(s.id);
        end if;
      else
        if s.status = 'upcoming' and s.opens_on <= v_today then
          if exists (select 1 from event_players ep join event_teams t on t.id = ep.team_id
                      where t.event_id = s.ev and t.slot = 0)
             and exists (select 1 from event_players ep join event_teams t on t.id = ep.team_id
                      where t.event_id = s.ev and t.slot = 1) then
            perform generate_pairings(s.id);
          end if;
        elsif s.status = 'open' and s.closes_on < v_today then
          perform resolve_session(s.id);
        end if;
      end if;
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
      insert into job_failures (job, subject, sqlstate, message)
      values ('run_event_sessions', 'session ' || s.id::text, v_state, v_msg);
      -- and keep going: one broken event must not close every other one's day
    end;
  end loop;
end $function$

