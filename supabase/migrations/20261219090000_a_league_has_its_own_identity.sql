-- Club Spread: owner-approved September 30, 2026. Presentation only.
-- The league survives Run it back, so its identity belongs here, not on a season.
alter table public.leagues
  add column if not exists identity_description text,
  add column if not exists identity_description_owner uuid,
  add column if not exists identity_image_path text,
  add column if not exists identity_image_kind text,
  add column if not exists identity_image_owner uuid;
alter table public.leagues add constraint league_identity_description_length
  check (identity_description is null or char_length(identity_description) <= 160);
alter table public.leagues add constraint league_identity_image_pair
  check ((identity_image_path is null and identity_image_kind is null)
    or (identity_image_path is not null and identity_image_kind is not null and identity_image_kind in ('photo', 'logo')));
alter table public.leagues add constraint league_identity_image_namespace
  check (identity_image_path is null or (split_part(identity_image_path, '/', 1) = id::text
    and identity_image_path ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png)$'));

-- Legacy league creation permits INSERT. New identity fields must still pass
-- the authorized setter after the league and its uploaded object exist.
create or replace function public._league_identity_starts_empty()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.identity_description is not null or new.identity_description_owner is not null
    or new.identity_image_path is not null or new.identity_image_kind is not null
    or new.identity_image_owner is not null then
    raise exception 'Create the league before adding its identity.' using errcode = '22023';
  end if;
  return new;
end $$;
revoke all on function public._league_identity_starts_empty() from public, anon, authenticated;
create trigger league_identity_starts_empty before insert on public.leagues
  for each row execute function public._league_identity_starts_empty();

-- Private, league-owned images: the next Pro can still use the group's image.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('league-media', 'league-media', false, 8388608, array['image/jpeg', 'image/png'])
on conflict (id) do nothing;

create or replace function public.league_media_access(p_name text, p_write boolean default false)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_league uuid;
begin
  if auth.uid() is null or not exists (select 1 from public.profiles where id = auth.uid() and deleted_at is null)
    or p_name is null or p_name !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|png)$'
    then return false; end if;
  v_league := split_part(p_name, '/', 1)::uuid;
  if p_write then return public.is_commissioner(v_league); end if;
  return public.is_league_member(v_league);
end $$;
revoke all on function public.league_media_access(text, boolean) from public, anon;
grant execute on function public.league_media_access(text, boolean) to authenticated;

create policy league_media_read on storage.objects for select to authenticated
  using (bucket_id = 'league-media' and public.league_media_access(name));
create policy league_media_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'league-media' and public.league_media_access(name, true));
-- The active image cannot be deleted through the storage API before its record clears.
create or replace function public.league_media_retired(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select public.league_media_access(p_name, true) and not exists
    (select 1 from public.leagues where identity_image_path = p_name);
$$;
revoke all on function public.league_media_retired(text) from public, anon;
grant execute on function public.league_media_retired(text) to authenticated;
create policy league_media_delete on storage.objects for delete to authenticated
  using (bucket_id = 'league-media' and public.league_media_retired(name));

create or replace function public.set_league_identity(
  p_league uuid, p_description text, p_image_path text, p_image_kind text
) returns void language plpgsql security definer set search_path = public as $$
declare v_description text := nullif(btrim(p_description), '');
        v_path text := nullif(p_image_path, '');
        v_owner uuid;
begin
  perform 1 from public.leagues where id = p_league for update;
  if not found or not public.is_commissioner(p_league)
    or not exists (select 1 from public.profiles where id = auth.uid() and deleted_at is null) then
    raise exception 'Only the Pro can change the league identity.' using errcode = '42501';
  end if;
  if char_length(v_description) > 160 then
    raise exception 'Keep the description to 160 characters.' using errcode = '22023';
  end if;
  if v_path is not null then
    if p_image_kind is null or p_image_kind not in ('photo', 'logo')
       or split_part(v_path, '/', 1) <> p_league::text
       or not public.league_media_access(v_path, true)
       or not exists (select 1 from storage.objects where bucket_id = 'league-media' and name = v_path)
    then raise exception 'Choose an image uploaded for this league.' using errcode = '22023'; end if;
    select coalesce(nullif(owner_id, '')::uuid, owner) into v_owner
      from storage.objects where bucket_id = 'league-media' and name = v_path;
  end if;
  update public.leagues set identity_description_owner = case
      when v_description is null then null
      when v_description is not distinct from identity_description then identity_description_owner
      else auth.uid() end,
    identity_description = v_description,
    identity_image_path = v_path, identity_image_kind = case when v_path is null then null else p_image_kind end,
    identity_image_owner = v_owner
    where id = p_league;
end $$;
revoke all on function public.set_league_identity(uuid, text, text, text) from public, anon;
grant execute on function public.set_league_identity(uuid, text, text, text) to authenticated;

-- D396 still governs uploaded league photographs and owner-authored words.
-- Handing off The Pro retains identity; deleting its author removes their contribution.
create or replace function public._clear_departed_league_identity()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_profile uuid := old.id;
begin
  if tg_op = 'UPDATE' and (new.deleted_at is null or old.deleted_at is not null) then return new; end if;
  update public.leagues set identity_description = null, identity_description_owner = null
    where identity_description_owner = v_profile;
  update public.leagues set identity_image_path = null, identity_image_kind = null, identity_image_owner = null
    where identity_image_owner = v_profile;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;
revoke all on function public._clear_departed_league_identity() from public, anon, authenticated;
create trigger clear_departed_league_identity before delete or update of deleted_at on public.profiles
  for each row execute function public._clear_departed_league_identity();

-- The existing account queue and Edge worker reclaim physical objects through
-- the Storage API; nothing deletes storage.objects in a production function.
create or replace function public._league_media_cleanup_paths(p_profile uuid)
returns setof text language sql stable security definer set search_path = public as $$
  select name from storage.objects where bucket_id = 'league-media'
    and coalesce(nullif(owner_id, ''), owner::text) = p_profile::text
    order by name limit 5000;
$$;
revoke all on function public._league_media_cleanup_paths(uuid) from public, anon, authenticated;
grant execute on function public._league_media_cleanup_paths(uuid) to service_role;

create or replace function public._media_cleanup_report(p_profile uuid, p_error text default null)
returns text language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  select count(*) into n from storage.objects where
    (bucket_id = 'media' and name like p_profile::text || '/%')
    or (bucket_id = 'league-media' and coalesce(nullif(owner_id, ''), owner::text) = p_profile::text);
  if n = 0 then
    update account_media_cleanup set status = 'completed', completed_at = coalesce(completed_at, now()),
           last_error = null, attempts = attempts + 1, updated_at = now()
     where profile_id = p_profile;
    return 'completed';
  end if;
  update account_media_cleanup set status = 'error', attempts = attempts + 1, updated_at = now(),
         last_error = left(coalesce(nullif(p_error, ''), 'Storage reported success but '
                           || n || ' object' || case when n = 1 then ' is' else 's are' end || ' still stored'), 500),
         next_attempt_at = now() + least(interval '1 day', make_interval(mins => power(2, least(attempts + 1, 11))::int))
   where profile_id = p_profile and status <> 'completed';
  return 'error';
end $$;
revoke all on function public._media_cleanup_report(uuid, text) from public, anon, authenticated;
grant execute on function public._media_cleanup_report(uuid, text) to service_role;

-- One authorized read for all the caller's leagues. No per-row roster fetch.
-- Preview counts and faces include only current, unsuspended, undeleted people.
create or replace function public.league_identities()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'league_id', l.id, 'description', l.identity_description,
    'image_path', l.identity_image_path, 'image_kind', l.identity_image_kind,
    'look', l.look,
    'member_count', (select count(*) from league_members m join profiles p on p.id = m.profile_id
      where m.league_id = l.id and m.suspended_at is null and m.left_at is null and p.deleted_at is null),
    'people', (select coalesce(jsonb_agg(x.person order by x.own desc, x.joined_at, x.id), '[]'::jsonb) from
      (select jsonb_build_object('id', p.id, 'name', p.display_name,
        'marker', coalesce(m.marker, p.marker), 'photo_path', p.photo_path) person,
        (p.id = auth.uid()) own, m.joined_at, m.id
       from league_members m join profiles p on p.id = m.profile_id
       where m.league_id = l.id and m.suspended_at is null and m.left_at is null and p.deleted_at is null
       order by (p.id = auth.uid()) desc, m.joined_at, m.id limit 3) x)
  ) order by l.id), '[]'::jsonb)
  from public.leagues l where public.is_league_member(l.id)
    and exists (select 1 from public.profiles where id = auth.uid() and deleted_at is null);
$$;
revoke all on function public.league_identities() from public, anon;
grant execute on function public.league_identities() to authenticated;
