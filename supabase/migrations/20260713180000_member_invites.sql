-- Member invites — the consent-based "add golfers" backbone (decision B).
--
-- One mechanism for BOTH containers: the Pro/organizer invites an app golfer to
-- a league OR an event; the golfer sees it (notifications banner + top bar) and
-- accepts or declines. Accept → they join (league_member / event_player, no team
-- yet — teams are formed after the room is confirmed). The old email `invites`
-- table stays as the not-on-the-app fallback; this is the in-app front door.

create table if not exists public.member_invites (
  id         uuid primary key default gen_random_uuid(),
  league_id  uuid references public.leagues(id) on delete cascade,
  event_id   uuid references public.events(id)  on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,  -- the invitee
  invited_by uuid not null references public.profiles(id),
  status     text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  constraint one_container check (num_nonnulls(league_id, event_id) = 1)
);
-- at most one live invite per (container, invitee)
create unique index if not exists member_invites_league_uq
  on public.member_invites(league_id, profile_id) where league_id is not null;
create unique index if not exists member_invites_event_uq
  on public.member_invites(event_id, profile_id) where event_id is not null;
create index if not exists member_invites_profile_idx on public.member_invites(profile_id);

alter table public.member_invites enable row level security;
drop policy if exists mi_invitee_read   on public.member_invites;
drop policy if exists mi_container_read  on public.member_invites;
-- the invitee reads their own; the organizer reads their container's
create policy mi_invitee_read on public.member_invites for select to authenticated
  using (profile_id = auth.uid());
create policy mi_container_read on public.member_invites for select to authenticated
  using ( (league_id is not null and is_commissioner(league_id))
       or (event_id  is not null and is_event_organizer(event_id)) );

-- ---- invite: Pro/organizer sends a pending invite to an app golfer ----
create or replace function public.invite_golfer(p_league uuid, p_event uuid, p_profile uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if (p_league is null) = (p_event is null) then
    raise exception 'invite to exactly one of a league or an event';
  end if;
  if p_league is not null and not is_commissioner(p_league) then raise exception 'only the Pro invites'; end if;
  if p_event  is not null and not is_event_organizer(p_event) then raise exception 'only the organizer invites'; end if;
  if p_league is not null and exists (select 1 from league_members where league_id=p_league and profile_id=p_profile) then
    raise exception 'already in the league';
  end if;
  if p_event is not null and exists (select 1 from event_players where event_id=p_event and profile_id=p_profile) then
    raise exception 'already in the event';
  end if;
  -- refresh a prior declined invite back to pending; else insert
  update member_invites set status='pending', invited_by=auth.uid(), created_at=now()
    where profile_id=p_profile and status<>'pending'
      and ((p_league is not null and league_id=p_league) or (p_event is not null and event_id=p_event))
    returning id into v_id;
  if v_id is null then
    insert into member_invites (league_id, event_id, profile_id, invited_by)
      values (p_league, p_event, p_profile, auth.uid())
      on conflict do nothing
      returning id into v_id;
  end if;
  return v_id;
end $$;

-- ---- my pending invites (for the banner + top bar) ----
create or replace function public.my_invites()
returns table(id uuid, kind text, container_id uuid, container_name text,
              inviter text, starts_on date, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select mi.id,
    case when mi.league_id is not null then 'league' else 'event' end,
    coalesce(mi.league_id, mi.event_id),
    coalesce(l.name, e.name),
    p.display_name,
    e.starts_on,
    mi.created_at
  from member_invites mi
  left join leagues  l on l.id = mi.league_id
  left join events   e on e.id = mi.event_id
  left join profiles p on p.id = mi.invited_by
  where mi.profile_id = auth.uid() and mi.status = 'pending'
  order by mi.created_at desc;
$$;

-- ---- accept / decline ----
create or replace function public.respond_invite(p_id uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public as $$
declare mi member_invites%rowtype; v_idx numeric; v_name text;
begin
  select * into mi from member_invites where id = p_id and profile_id = auth.uid();
  if not found then raise exception 'invite not found'; end if;
  if mi.status <> 'pending' then return; end if;

  if p_accept then
    select display_name, index_current into v_name, v_idx from profiles where id = auth.uid();
    if mi.league_id is not null then
      insert into league_members (league_id, profile_id, role, index_current)
        values (mi.league_id, auth.uid(), 'player', coalesce(v_idx, 18.0))
        on conflict (league_id, profile_id) do nothing;
      insert into posts (league_id, kind, body)
        values (mi.league_id, 'system', upper(coalesce(v_name,'A golfer')) || ' JOINED THE LEAGUE');
    else
      insert into event_players (event_id, profile_id, seed)
        values (mi.event_id, auth.uid(),
                coalesce((select max(seed)+1 from event_players where event_id=mi.event_id), 0))
        on conflict (event_id, profile_id) do nothing;
    end if;
    update member_invites set status='accepted' where id = p_id;
  else
    update member_invites set status='declined' where id = p_id;
  end if;
end $$;

revoke all on function public.invite_golfer(uuid,uuid,uuid) from public;
grant execute on function public.invite_golfer(uuid,uuid,uuid) to authenticated;
grant execute on function public.my_invites() to authenticated;
grant execute on function public.respond_invite(uuid,boolean) to authenticated;
