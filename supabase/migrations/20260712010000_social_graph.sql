-- ============================================================================
-- Cup Season — the social graph: handles, discoverability, friendships
--
-- Decisions (2026-07-11): handles REQUIRED at signup (client gates on it),
-- discoverable defaults to 'everyone' (hub valve one tap away), friend
-- events ride the push rails via a second webhook on friendships.
-- All writes go through security-definer RPCs — identity is checked at the
-- database, never by hiding a button.
-- ============================================================================

alter table public.profiles add column handle text;
create unique index profiles_handle_key on public.profiles (lower(handle));
alter table public.profiles add constraint profiles_handle_format
  check (handle is null or handle ~ '^[a-z0-9_]{3,20}$');

alter table public.profiles add column discoverable text not null default 'everyone'
  check (discoverable in ('everyone','friends','nobody'));

create table public.friendships (
  id           uuid primary key default gen_random_uuid(),
  requester    uuid not null references public.profiles(id) on delete cascade,
  addressee    uuid not null references public.profiles(id) on delete cascade,
  status       text not null default 'pending' check (status in ('pending','accepted')),
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  check (requester <> addressee)
);
-- one row per pair, regardless of direction; declines DELETE the row so a
-- fresh request stays possible
create unique index friendships_pair_key on public.friendships
  (least(requester, addressee), greatest(requester, addressee));

alter table public.friendships enable row level security;
create policy fr_own_select on public.friendships
  for select to authenticated
  using (requester = auth.uid() or addressee = auth.uid());

create or replace function public.set_handle(p_handle text) returns void
language plpgsql security definer set search_path = public as $$
declare v text := lower(trim(both from replace(p_handle, '@', '')));
begin
  if v !~ '^[a-z0-9_]{3,20}$' then
    raise exception 'Handles are 3–20 characters: letters, numbers, underscores';
  end if;
  if v in ('pro','demo','cupseason','admin','support','help','official','cup','season','sndycup') then
    raise exception 'That handle is reserved';
  end if;
  begin
    update profiles set handle = v where id = auth.uid();
  exception when unique_violation then
    raise exception 'That handle is taken';
  end;
end $$;

create or replace function public.set_discoverable(p_mode text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_mode not in ('everyone','friends','nobody') then
    raise exception 'bad mode';
  end if;
  update profiles set discoverable = p_mode where id = auth.uid();
end $$;

create or replace function public.search_golfers(p_q text)
returns table (profile_id uuid, handle text, display_name text, city text,
               home_course text, marker text, index_current numeric, rel text)
language sql stable security definer set search_path = public as $$
  select p.id, p.handle, p.display_name, p.city, p.home_course, p.marker,
         p.index_current,
    case
      when f.status = 'accepted' then 'friend'
      when f.status = 'pending' and f.requester = auth.uid() then 'requested'
      when f.status = 'pending' then 'incoming'
      else 'none' end
  from profiles p
  left join friendships f
    on least(f.requester, f.addressee)    = least(p.id, auth.uid())
   and greatest(f.requester, f.addressee) = greatest(p.id, auth.uid())
  where p.id <> auth.uid()
    and length(trim(p_q)) >= 2
    and (p.handle ilike replace(trim(p_q), '@', '') || '%'
         or p.display_name ilike '%' || trim(p_q) || '%')
    and (p.discoverable = 'everyone'
         or (p.discoverable = 'friends' and f.status = 'accepted'))
  order by (p.handle ilike replace(trim(p_q), '@', '') || '%') desc, p.display_name
  limit 10;
$$;

create or replace function public.friend_request(p_profile uuid) returns text
language plpgsql security definer set search_path = public as $$
declare f record;
begin
  if p_profile = auth.uid() then raise exception 'That''s you'; end if;
  select * into f from friendships
   where least(requester, addressee)    = least(p_profile, auth.uid())
     and greatest(requester, addressee) = greatest(p_profile, auth.uid());
  if found then
    if f.status = 'accepted' then return 'friend'; end if;
    if f.requester = auth.uid() then return 'requested'; end if;
    -- they asked first — mutual intent, instant buddies
    update friendships set status = 'accepted', responded_at = now() where id = f.id;
    return 'friend';
  end if;
  insert into friendships (requester, addressee) values (auth.uid(), p_profile);
  return 'requested';
end $$;

create or replace function public.friend_respond(p_id uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_accept then
    update friendships set status = 'accepted', responded_at = now()
      where id = p_id and addressee = auth.uid() and status = 'pending';
  else
    delete from friendships
      where id = p_id and addressee = auth.uid() and status = 'pending';
  end if;
end $$;

create or replace function public.unfriend(p_profile uuid) returns void
language sql security definer set search_path = public as
$$ delete from friendships
   where least(requester, addressee)    = least(p_profile, auth.uid())
     and greatest(requester, addressee) = greatest(p_profile, auth.uid()); $$;

create or replace function public.my_friends()
returns table (friendship_id uuid, profile_id uuid, handle text, display_name text,
               city text, marker text, index_current numeric, status text, incoming boolean)
language sql stable security definer set search_path = public as $$
  select f.id, p.id, p.handle, p.display_name, p.city, p.marker, p.index_current,
         f.status, (f.addressee = auth.uid())
  from friendships f
  join profiles p
    on p.id = case when f.requester = auth.uid() then f.addressee else f.requester end
  where f.requester = auth.uid() or f.addressee = auth.uid()
  order by (f.status = 'pending') desc, p.display_name;
$$;

grant execute on function public.set_handle(text) to authenticated;
grant execute on function public.set_discoverable(text) to authenticated;
grant execute on function public.search_golfers(text) to authenticated;
grant execute on function public.friend_request(uuid) to authenticated;
grant execute on function public.friend_respond(uuid, boolean) to authenticated;
grant execute on function public.unfriend(uuid) to authenticated;
grant execute on function public.my_friends() to authenticated;
