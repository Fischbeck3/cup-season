-- ============================================================================
-- Cup Season — a round on the books gets a tee time
--
-- scheduled_rounds gains an OPTIONAL tee_time. The day stays the calendar key
-- (everything grids/sorts by play_on); the time is purely additive, so every
-- round already on the books keeps working with tee_time = null. When present
-- it rides into the board post ("... 7:40AM · PAPAGO GC") and the client shows
-- it in gold as the earned detail that turns a note into a plan.
--
-- declare_round grows a 5th arg (default null); my_schedule returns tee_time.
-- Both functions are dropped + recreated: the 5th default arg would make the
-- old 4-arg declare_round ambiguous, and my_schedule's return shape changes.
-- ============================================================================

alter table public.scheduled_rounds add column tee_time time;

drop function if exists public.declare_round(date, text, text, uuid[]);
create or replace function public.declare_round(
  p_play_on date, p_course text, p_note text,
  p_tagged uuid[] default '{}', p_tee time default null
) returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
  v_name   text;
  v_tags   uuid[];
  v_bad    integer;
  v_with   text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_play_on is null or p_play_on < current_date then
    raise exception 'Pick a day that has not happened yet';
  end if;
  if p_play_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  if v_note is not null and length(v_note) > 140 then
    raise exception 'Notes cap at 140 characters';
  end if;

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven — it is golf, not a scramble league';
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
  if v_bad > 0 then raise exception 'You can tag buddies and league mates'; end if;

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee)
  returning id into v_id;

  select upper(coalesce(display_name, 'A GOLFER')) into v_name
    from profiles where id = auth.uid();
  select string_agg(upper(coalesce(display_name, 'A GOLFER')), ' & ') into v_with
    from profiles where id = any(v_tags);

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || ' PUT A ROUND ON THE BOOKS — '
         || upper(to_char(p_play_on, 'Dy Mon DD'))
         || coalesce(' · ' || to_char(p_tee, 'FMHH12:MIAM'), '')
         || coalesce(' · ' || upper(v_course), '')
         || coalesce(' · WITH ' || v_with, '')
         || coalesce(' · "' || v_note || '"', '')
  from league_members lm
  where lm.profile_id = auth.uid();

  return v_id;
end $$;

drop function if exists public.my_schedule(date, date);
create or replace function public.my_schedule(p_from date, p_to date)
returns table (
  id uuid, profile_id uuid, display_name text, marker text,
  play_on date, course_label text, note text, tee_time time,
  mine boolean, is_friend boolean, shared_league boolean,
  tagged_names text[], tagged_me boolean
)
language sql stable security definer
set search_path = public
as $$
  select sr.id, sr.profile_id, p.display_name, p.marker,
         sr.play_on, sr.course_label, sr.note, sr.tee_time,
         sr.profile_id = auth.uid() as mine,
         exists (select 1 from friendships f
                  where f.status = 'accepted'
                    and ((f.requester = auth.uid() and f.addressee = sr.profile_id)
                      or (f.addressee = auth.uid() and f.requester = sr.profile_id))) as is_friend,
         exists (select 1 from league_members a
                    join league_members b on b.league_id = a.league_id
                  where a.profile_id = auth.uid()
                    and b.profile_id = sr.profile_id
                    and sr.profile_id <> auth.uid()) as shared_league,
         (select array_agg(p2.display_name order by p2.display_name)
            from profiles p2 where p2.id = any(sr.tagged)) as tagged_names,
         auth.uid() = any(sr.tagged) as tagged_me
    from scheduled_rounds sr
    join profiles p on p.id = sr.profile_id
   where sr.play_on between p_from and p_to
     and (
       sr.profile_id = auth.uid()
       or auth.uid() = any(sr.tagged)
       or exists (select 1 from friendships f
                   where f.status = 'accepted'
                     and ((f.requester = auth.uid() and f.addressee = sr.profile_id)
                       or (f.addressee = auth.uid() and f.requester = sr.profile_id)))
       or exists (select 1 from league_members a
                     join league_members b on b.league_id = a.league_id
                   where a.profile_id = auth.uid()
                     and b.profile_id = sr.profile_id)
     )
   order by sr.play_on, sr.tee_time nulls last, sr.created_at;
$$;

grant execute on function public.declare_round(date, text, text, uuid[], time) to authenticated;
grant execute on function public.my_schedule(date, date) to authenticated;
