-- round_duel_nudge() oid=19654
CREATE OR REPLACE FUNCTION public.round_duel_nudge()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare d record; v_best numeric; v_name text;
begin
  if new.voided or coalesce(new.source,'app') = 'sim'
     or new.index_at_post is null or new.differential is null then
    return new;
  end if;
  for d in
    select du.id, du.event_id, s.opens_on, s.closes_on, s.closes_on - current_date as days_left,
           e.name as ename, e.allowance,
           case when ea.profile_id = new.profile_id then eb.profile_id else ea.profile_id end as opp_profile,
           case when ea.profile_id = new.profile_id then eb.notify_target else ea.notify_target end as opp_wants,
           case when ea.profile_id = new.profile_id then ea.profile_id else eb.profile_id end as me_profile
      from event_duels du
      join event_sessions s on s.id = du.session_id and s.status = 'open'
      join events e on e.id = du.event_id and e.status = 'live'
      join event_players ea on ea.id = du.a_player
      join event_players eb on eb.id = du.b_player
     where du.result = 'pending'
       and new.played_on between s.opens_on and s.closes_on
       and (ea.profile_id = new.profile_id or eb.profile_id = new.profile_id)
  loop
    if not d.opp_wants then continue; end if;
    -- the standing target = the poster's BEST in the window (this round or better)
    select max((r.index_at_post * d.allowance / 100.0) - r.differential) into v_best
      from rounds r
     where r.profile_id = new.profile_id
       and r.played_on between d.opens_on and d.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null;
    select display_name into v_name from profiles where id = new.profile_id;
    -- wave 7 · routed: the phone opens the event room (contract §2, `nudge`)
    insert into push_nudges (profile_id, kind, title, body, payload)
    values (d.opp_profile, 'nudge', d.ename,
      coalesce(v_name,'Your opponent') || ' posted — '
      || (case when v_best >= 0 then '+' else '' end) || round(v_best,1) || ' to beat · '
      || case when d.days_left <= 0 then 'closes tonight'
              else d.days_left || ' day' || case when d.days_left = 1 then '' else 's' end || ' left' end,
      jsonb_build_object('event_id', d.event_id));
  end loop;
  return new;
end $function$

