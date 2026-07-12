-- ============================================================================
-- Cup Season — rounds on the books + the clubhouse roster
--
-- 1. DECLARED ROUNDS (the anticipation loop, personas doc). scheduled_rounds
--    is PROFILE-level, like rounds — "Logan plays Pebble in two weeks" is a
--    fact about Logan, not about a league. Visibility = you, your accepted
--    friends, and anyone who shares a league with you; the client highlights
--    the shared-league case. declare_round() fans a board post (with the
--    note riding along) to every league the golfer belongs to — hype rides
--    the existing realtime + push rails. scratch_round() is a quiet delete.
--    RLS keeps direct table reads to the owner; social reads go through the
--    security-definer my_schedule() so the friend/league math lives in SQL.
--
-- 2. ROSTER TOOLS. remove_member() is SETUP-ONLY for the pilot — that's the
--    real use case (a wrong join before lock). Mid-season departures have
--    competitive consequences and wait for the bye/void toolkit. Their chat
--    posts stay (member NULLed, renders as '—'). transfer_pro() swaps the
--    commissioner role; both log to commissioner_log and post to the board.
-- ============================================================================

create table public.scheduled_rounds (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  play_on      date not null,
  course_label text,
  note         text,
  created_at   timestamptz not null default now()
);
create index scheduled_rounds_profile_idx on public.scheduled_rounds (profile_id, play_on);
create index scheduled_rounds_day_idx on public.scheduled_rounds (play_on);

alter table public.scheduled_rounds enable row level security;
create policy sched_own on public.scheduled_rounds
  for all to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create or replace function public.declare_round(p_play_on date, p_course text, p_note text)
returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
  v_name   text;
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

  insert into scheduled_rounds (profile_id, play_on, course_label, note)
  values (auth.uid(), p_play_on, v_course, v_note)
  returning id into v_id;

  select upper(coalesce(display_name, 'A GOLFER')) into v_name
    from profiles where id = auth.uid();

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || ' PUT A ROUND ON THE BOOKS — '
         || upper(to_char(p_play_on, 'Dy Mon DD'))
         || coalesce(' · ' || upper(v_course), '')
         || coalesce(' · "' || v_note || '"', '')
  from league_members lm
  where lm.profile_id = auth.uid();

  return v_id;
end $$;

create or replace function public.scratch_round(p_id uuid) returns void
language plpgsql security definer
set search_path = public
as $$
begin
  delete from scheduled_rounds where id = p_id and profile_id = auth.uid();
end $$;

-- everything on the books that I'm allowed to see, with the social flags
create or replace function public.my_schedule(p_from date, p_to date)
returns table (
  id uuid, profile_id uuid, display_name text, marker text,
  play_on date, course_label text, note text,
  mine boolean, is_friend boolean, shared_league boolean
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
                    and sr.profile_id <> auth.uid()) as shared_league
    from scheduled_rounds sr
    join profiles p on p.id = sr.profile_id
   where sr.play_on between p_from and p_to
     and (
       sr.profile_id = auth.uid()
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

create or replace function public.remove_member(p_member uuid) returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_league uuid; v_name text;
begin
  select league_id into v_league from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro removes members'; end if;
  if p_member = my_member_id(v_league) then raise exception 'Transfer the Pro role before leaving'; end if;
  if (select phase from leagues where id = v_league) <> 'setup' then
    raise exception 'Members can only be removed during setup — mid-season tools are coming';
  end if;

  select coalesce(p.display_name, 'A member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  update posts set member_id = null where member_id = p_member;
  delete from squad_members where member_id = p_member;
  delete from buy_ins where member_id = p_member;
  delete from league_members where id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, my_member_id(v_league), 'remove_member',
          jsonb_build_object('member', p_member, 'name', v_name));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          upper(v_name) || ' LEFT THE LEAGUE');
end $$;

create or replace function public.transfer_pro(p_member uuid) returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_league uuid; v_name text; v_me uuid;
begin
  select league_id into v_league from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro hands over the shop'; end if;
  v_me := my_member_id(v_league);
  if p_member = v_me then raise exception 'You already run the shop'; end if;

  update league_members set role = 'commissioner' where id = p_member;
  update league_members set role = 'player' where id = v_me;

  select upper(coalesce(p.display_name, 'A MEMBER')) into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, p_member, 'transfer_pro', jsonb_build_object('from', v_me, 'to', p_member));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', v_me, 'THE PRO ROLE PASSES TO ' || v_name);
end $$;

grant execute on function public.declare_round(date, text, text) to authenticated;
grant execute on function public.scratch_round(uuid) to authenticated;
grant execute on function public.my_schedule(date, date) to authenticated;
grant execute on function public.remove_member(uuid) to authenticated;
grant execute on function public.transfer_pro(uuid) to authenticated;
