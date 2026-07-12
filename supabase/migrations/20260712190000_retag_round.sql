-- ============================================================================
-- Cup Season — retag a round on the books
--
-- You could only tag your group at declaration time; now the owner can add
-- or drop tags on a future round. Same validation as declare_round (accepted
-- buddies or league mates, never self, seven max). Silent update — the board
-- already knows about the round; retags shouldn't spam it.
-- my_schedule now also returns the raw tagged uuid[] so the client can
-- preselect chips when editing.
-- ============================================================================

create or replace function public.retag_round(p_id uuid, p_tagged uuid[])
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_tags uuid[];
  v_bad  integer;
begin
  if not exists (select 1 from scheduled_rounds
                  where id = p_id and profile_id = auth.uid()) then
    raise exception 'Not your round';
  end if;
  if (select play_on from scheduled_rounds where id = p_id) < current_date then
    raise exception 'That round already happened';
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

  update scheduled_rounds set tagged = v_tags where id = p_id;
end $$;

drop function if exists public.my_schedule(date, date);
create or replace function public.my_schedule(p_from date, p_to date)
returns table (
  id uuid, profile_id uuid, display_name text, marker text,
  play_on date, course_label text, note text,
  mine boolean, is_friend boolean, shared_league boolean,
  tagged_names text[], tagged_me boolean, tagged uuid[]
)
language sql stable security definer
set search_path = public
as $$
  select sr.id, sr.profile_id, p.display_name, p.marker,
         sr.play_on, sr.course_label, sr.note,
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
         auth.uid() = any(sr.tagged) as tagged_me,
         sr.tagged
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
   order by sr.play_on, sr.created_at;
$$;

grant execute on function public.retag_round(uuid, uuid[]) to authenticated;
grant execute on function public.my_schedule(date, date) to authenticated;
