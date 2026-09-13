-- retag_round(p_id uuid, p_tagged uuid[]) oid=18888
CREATE OR REPLACE FUNCTION public.retag_round(p_id uuid, p_tagged uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tags uuid[];
  v_bad  integer;
  v_old  uuid[];
  v_play date; v_course text; v_who text; v_body text;
begin
  if not exists (select 1 from scheduled_rounds
                  where id = p_id and profile_id = auth.uid()) then
    raise exception 'Not your round';
  end if;
  if (select play_on from scheduled_rounds where id = p_id) < plan_day_floor() then
    raise exception 'That round already happened';
  end if;

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven.';
  end if;

  select count(*) into v_bad
    from unnest(v_tags) t(pid)
   where not (
     exists (select 1 from friendships f
              where f.status = 'accepted'
                and ((f.requester = auth.uid() and f.addressee = t.pid)
                  or (f.addressee = auth.uid() and f.requester = t.pid)))
     or exists (select 1 from league_members a
                   join league_members b on b.league_id = a.league_id
                 where a.profile_id = auth.uid() and b.profile_id = t.pid)
   );
  if v_bad > 0 then raise exception 'You can tag buddies and golfers in your seasons.'; end if;

  -- D104 · remember who was already asked, then write
  select coalesce(tagged, '{}'), play_on, course_label into v_old, v_play, v_course
    from scheduled_rounds where id = p_id;
  update scheduled_rounds set tagged = v_tags where id = p_id;

  -- D104 · ask only the newly tagged (same copy as declare_round)
  if exists (select 1 from unnest(v_tags) t(pid) where not (t.pid = any(v_old))) then
    v_who  := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'Someone');
    v_body := trim(to_char(v_play, 'Dy Mon FMDD'))
              || coalesce(' · ' || nullif(trim(coalesce(v_course, '')), ''), '') || ' — in or out?';
    insert into push_nudges (profile_id, kind, title, body, payload)
    select t.pid, 'rsvp', v_who || ' put you on the schedule', v_body,
           jsonb_build_object('scheduled_round_id', p_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid)
     where not (t.pid = any(v_old));
  end if;
end $function$

