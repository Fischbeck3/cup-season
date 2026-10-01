-- D403 · a takedown reaches the photo, and a ban reaches the session.
--
-- The founder desk (20260901120000_the_takedown_path) can take a post or a comment
-- down; nothing could take a PHOTO down, and nothing could remove a golfer — while
-- the Terms promise both ("remove the offending content, and remove the accounts").
-- This migration extends that desk; it does not build a second one.
--
--   1 · report_content gains its missing branch: both clients send a golfer report as
--       p_kind 'profile' (TourCard.swift:513, index.html:32153), and the function had
--       no such branch — every golfer report raised 'nothing to report'. It now files
--       kind 'profile' behind the same fence as a profile-photo report.
--   2 · takedown_photo (founder only): a profile photo or a round photo. The reference
--       is cleared (the round, its scores and its points are untouched — photo_path is
--       not a scoring column), the object is hidden from every client query at once by
--       a restrictive storage policy (so no NEW link can be minted), every share that
--       could carry the photo is revoked (which queues its public copies and preview for
--       share-cleanup), and the FILE ITSELF is queued for removal (media_takedowns).
--       The policy alone is not enough: a signed URL minted before the takedown (both
--       clients mint them for up to an hour) is served by Storage on its signature, not
--       through RLS, so it keeps working until the object is gone. The share-cleanup
--       function moves the object out of the `media` bucket into the private
--       `moderation-hold` bucket (no client policy reads it), which kills every
--       previously issued URL — original and transformed — at the origin; if the move
--       fails it removes the object outright (removal beats retention), and either way
--       _takedown_cleanup_report re-reads storage.objects before it records `removed`,
--       retrying with backoff until it can. The kept evidence is purged after 90 days.
--       Bounds that remain, and are stated rather than hidden: a CDN may keep serving an
--       already-cached response until it is invalidated or expires, and a copy a viewer
--       already downloaded or screenshotted cannot be recalled.
--   3 · ban_account / unban_account (founder only). A ban needs the golfer's handle
--       typed back as confirmation and a reason; it cannot target the founder or a
--       deleted account. It sets auth.users.banned_until (no new sign-in, no refresh),
--       deletes the golfer's sessions and push targets, and records an audit row.
--   4 · the session: a PostgREST pre-request gate (cs_internal.request_gate) refuses
--       EVERY API request from a banned golfer — including one carrying a token minted
--       before the ban, which no auth-side setting can recall. It lives in a schema the
--       API does not expose, so it is not itself an endpoint. Restrictive storage
--       policies refuse a banned golfer's uploads, which do not pass through PostgREST.
--   5 · moderation_queue (re-emitted whole) carries what the desk needs to act: who the
--       report is about, whether there is a photo, whether they are already banned.
--
-- Audit: public.moderation_actions — one row per takedown, ban and unban, with actor,
-- reason and target. No client reads it; the desk reads through moderation_queue.
--
-- Grants: takedown_photo, ban_account, unban_account → authenticated (each checks the
-- founder itself). The helpers used by storage policies → authenticated. The gate →
-- anon, authenticated and service_role (PostgREST runs it as the request's role, for
-- every role it serves). Nothing new is an anon endpoint in public.
--
-- The gate's limits, stated: it fails OPEN on an error inside it (a bug here must never
-- take the API down), so a confirmed ban is not enforced on the API while its lookup
-- is failing; it does not cover Realtime, which authorises a socket on the JWT; and the
-- role setting names a function, so a future migration that drops or renames
-- cs_internal.request_gate must reset pgrst.db_pre_request FIRST, or every API request
-- fails. Storage writes are covered separately by the restrictive policies below.

-- ---- tables -------------------------------------------------------------------
create table if not exists public.account_bans (
  profile_id  uuid primary key references public.profiles(id) on delete cascade,
  banned_at   timestamptz not null default now(),
  banned_by   uuid not null,
  reason      text not null,
  lifted_at   timestamptz,
  lifted_by   uuid,
  lift_reason text
);
alter table public.account_bans enable row level security;
revoke all on table public.account_bans from public, anon, authenticated;

create table if not exists public.moderation_actions (
  id             uuid primary key default gen_random_uuid(),
  actor          uuid not null,
  action         text not null check (action in ('takedown_photo','ban','unban')),
  target_profile uuid,
  target_round   uuid,
  report_id      uuid,
  reason         text not null,
  detail         jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);
create index if not exists moderation_actions_target on public.moderation_actions (target_profile, created_at desc);
alter table public.moderation_actions enable row level security;
revoke all on table public.moderation_actions from public, anon, authenticated;

create table if not exists public.media_takedowns (
  id          uuid primary key default gen_random_uuid(),
  bucket      text not null,
  path        text not null,
  taken_at    timestamptz not null default now(),
  taken_by    uuid not null,
  -- the file's removal from its bucket, done by share-cleanup and confirmed here
  status      text not null default 'pending'
              check (status in ('pending', 'error', 'removed', 'purged')),
  attempts    integer not null default 0,
  next_try    timestamptz not null default now(),
  last_error  text,
  removed_at  timestamptz,
  -- the evidence, if the move kept it: moderation-hold/<hold_path>, never client-readable
  hold_path   text,
  purge_after timestamptz,
  purged_at   timestamptz
);
create index if not exists media_takedowns_path on public.media_takedowns (bucket, path);
create index if not exists media_takedowns_due on public.media_takedowns (status, next_try);
alter table public.media_takedowns enable row level security;
revoke all on table public.media_takedowns from public, anon, authenticated;

-- the private bucket the evidence is moved into. No storage policy names it, so no
-- client role can list, read, write or delete in it; only the service role can.
insert into storage.buckets (id, name, public)
values ('moderation-hold', 'moderation-hold', false)
on conflict (id) do update set public = false;

create unique index if not exists content_reports_profile_uni
  on public.content_reports (profile_id, reporter) where kind = 'profile';

-- ---- helpers --------------------------------------------------------------------
create or replace function public.is_banned(p_profile uuid default auth.uid())
returns boolean
language sql stable security definer
set search_path = public
as $$
  select p_profile is not null
     and exists (select 1 from account_bans b where b.profile_id = p_profile and b.lifted_at is null)
$$;
revoke all on function public.is_banned(uuid) from public, anon, authenticated;
grant execute on function public.is_banned(uuid) to authenticated;

-- A takedown hides the object that was up WHEN it was taken down. A file written to
-- the same path afterwards (a new avatar at <uid>/avatar.jpg) is a new photo, and the
-- report path is the answer to it — never a path blocked forever.
create or replace function public.media_taken_down(p_name text, p_version timestamptz default null)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from media_takedowns t
                  where t.bucket = 'media' and t.path = p_name
                    and (p_version is null or p_version <= t.taken_at))
$$;
revoke all on function public.media_taken_down(text, timestamptz) from public, anon, authenticated;
grant execute on function public.media_taken_down(text, timestamptz) to authenticated;

-- ---- storage: a taken-down object is unreadable; a banned golfer cannot write ------
drop policy if exists media_takedown_hidden on storage.objects;
create policy media_takedown_hidden on storage.objects as restrictive for select to authenticated
  using (bucket_id <> 'media' or not public.media_taken_down(name, coalesce(updated_at, created_at)));

drop policy if exists banned_no_upload on storage.objects;
create policy banned_no_upload on storage.objects as restrictive for insert to authenticated
  with check (not public.is_banned());

drop policy if exists banned_no_update on storage.objects;
create policy banned_no_update on storage.objects as restrictive for update to authenticated
  using (not public.is_banned()) with check (not public.is_banned());

drop policy if exists banned_no_delete on storage.objects;
create policy banned_no_delete on storage.objects as restrictive for delete to authenticated
  using (not public.is_banned());

-- ---- the session gate -------------------------------------------------------------
create schema if not exists cs_internal;
revoke all on schema cs_internal from public;
-- every role PostgREST can switch a request to runs the gate — service_role included.
-- Without service_role here EVERY Edge-function call through the API fails 42501
-- ("permission denied for function request_gate") before the gate's own fail-open
-- code can run (found by the live local-stack proof, 2026-10-01).
grant usage on schema cs_internal to anon, authenticated, service_role;

create or replace function cs_internal.request_gate()
returns void
language plpgsql stable security definer
set search_path = public
as $$
declare v uuid; v_banned boolean := false;
begin
  -- This runs before EVERY API request. Anything unexpected fails OPEN: a bug here
  -- must never take the whole API down. Only a confirmed, unlifted ban refuses.
  begin
    v := auth.uid();
    if v is null then return; end if;
    select true into v_banned from account_bans b where b.profile_id = v and b.lifted_at is null;
  exception when others then
    return;
  end;
  if coalesce(v_banned, false) then
    raise exception using message = 'This account has been closed.', errcode = 'PT403';
  end if;
end $$;
revoke all on function cs_internal.request_gate() from public;
grant execute on function cs_internal.request_gate() to anon, authenticated, service_role;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'authenticator') then
    execute 'alter role authenticator set pgrst.db_pre_request = ''cs_internal.request_gate''';
    perform pg_notify('pgrst', 'reload config');
  end if;
end $$;

-- ---- report_content: the golfer branch both clients already call -------------------
do $$
declare v_def text; v_anchor constant text := '  if p_kind = ''profile_photo'' then';
begin
  v_def := pg_get_functiondef('public.report_content(uuid,text,text,uuid,uuid)'::regprocedure);
  if (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor) <> 1 then
    raise exception 'D403: report_content no longer has exactly one profile_photo branch — re-read it';
  end if;
  if position('p_kind = ''profile'' then' in v_def) > 0 then
    return;   -- already patched
  end if;
  v_def := replace(v_def, v_anchor, $patch$  -- [D403] a report about a GOLFER (both clients send p_kind 'profile'): the
  -- profile-photo fence, its own kind, one open report per reporter and golfer
  if p_kind = 'profile' then
    if p_profile is null then raise exception 'nothing to report'; end if;
    if p_profile = auth.uid() then raise exception 'You can''t report yourself'; end if;
    if not exists (
      select 1 from league_members a
        join league_members b on b.league_id = a.league_id
       where a.profile_id = auth.uid() and b.profile_id = p_profile
    ) and not exists (
      select 1 from friendships f
       where f.status = 'accepted'
         and ((f.requester = auth.uid() and f.addressee = p_profile)
           or (f.addressee = auth.uid() and f.requester = p_profile))
    ) and not exists (
      select 1 from event_players ea
        join event_players eb on eb.event_id = ea.event_id
       where ea.profile_id = auth.uid() and eb.profile_id = p_profile
    ) then
      raise exception 'You can only report golfers you share a league, event, or friendship with';
    end if;
    insert into content_reports (post_id, reporter, reason, kind, profile_id)
    values (null, auth.uid(), left(coalesce(p_reason,'golfer'), 500), 'profile', p_profile)
    on conflict (profile_id, reporter) where kind = 'profile'
    do update set reason = excluded.reason, created_at = now(),
                  resolved = false, resolved_at = null, resolved_by = null, resolution = null;
    return;
  end if;

$patch$ || v_anchor);
  execute v_def;
end $$;

create or replace function public.notify_founder_of_report()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare v_founder uuid; v_what text;
begin
  begin
    v_founder := founder_id();
    if v_founder is null or v_founder = new.reporter then return new; end if;
    v_what := case new.kind
                when 'profile'       then 'a golfer'
                when 'profile_photo' then 'a profile photo'
                when 'comment'       then 'a comment'
                when 'round_comment' then 'a comment on a round'
                else 'a post' end;
    insert into push_nudges (profile_id, title, body, kind, payload)
    values (v_founder,
            'A report needs you',
            'Someone reported ' || v_what || '. Open the founder''s desk.',
            'nudge',
            jsonb_build_object('report_id', new.id, 'desk', true));
  exception when others then
    null;   -- never let the notification fail the report
  end;
  return new;
end $$;
revoke all on function public.notify_founder_of_report() from public, anon, authenticated;

-- ---- takedown_photo -----------------------------------------------------------------
create or replace function public.takedown_photo(p_kind text, p_target uuid, p_reason text, p_report uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_path   text;
  v_round  uuid;
  v_owner  uuid;
  v_shares int := 0;
  v_take   uuid;
begin
  if auth.uid() is null or auth.uid() is distinct from founder_id() then
    raise exception 'Only the founder can take a photo down';
  end if;
  if p_target is null then raise exception 'nothing to take down'; end if;
  if p_reason is null or length(btrim(p_reason)) < 3 then
    raise exception 'Say why the photo is coming down';
  end if;

  if p_kind = 'profile_photo' then
    select photo_path, id into v_path, v_owner from profiles where id = p_target for update;
    if not found then raise exception 'no such golfer'; end if;
    if v_path is null then raise exception 'That golfer has no photo up'; end if;
    update profiles set photo_path = null where id = p_target;
  elsif p_kind = 'round_photo' then
    select photo_path, profile_id, id into v_path, v_owner, v_round from rounds where id = p_target for update;
    if not found then raise exception 'no such round'; end if;
    if v_path is null then raise exception 'That round has no photo up'; end if;
    -- photo_path is the only column touched: gross, rating, slope, date and points stand
    update rounds set photo_path = null where id = p_target;
    -- the public copies: revoking queues them for share-cleanup (the existing trigger)
    update shares set revoked = true
     where kind in ('round','recap') and ref_id = p_target and not revoked;
    get diagnostics v_shares = row_count;
  else
    raise exception 'unknown kind: %', p_kind;
  end if;

  -- the file itself: queued for share-cleanup to move into moderation-hold and
  -- confirmed gone from `media` by _takedown_cleanup_report (never assumed)
  v_take := gen_random_uuid();
  insert into media_takedowns (id, bucket, path, taken_by, hold_path)
  values (v_take, 'media', v_path, auth.uid(), v_take::text || '/' || v_path);

  if p_report is not null then
    update content_reports
       set resolved = true, resolved_at = now(), resolved_by = auth.uid(),
           resolution = left('photo taken down: ' || btrim(p_reason), 500)
     where id = p_report;
  end if;

  insert into moderation_actions (actor, action, target_profile, target_round, report_id, reason, detail)
  values (auth.uid(), 'takedown_photo', v_owner, v_round, p_report, left(btrim(p_reason), 500),
          jsonb_build_object('kind', p_kind, 'path', v_path, 'shares_revoked', v_shares,
                             'takedown', v_take));

  -- 'queued': the file's removal is share-cleanup's, and is not claimed done here
  return jsonb_build_object('taken_down', true, 'kind', p_kind, 'shares_revoked', v_shares,
                            'file', 'queued', 'takedown', v_take);
end $$;
revoke all on function public.takedown_photo(text, uuid, text, uuid) from public, anon, authenticated;
grant execute on function public.takedown_photo(text, uuid, text, uuid) to authenticated;

-- ---- the file's removal: share-cleanup's queue -----------------------------------------
-- remove: move media/<path> into moderation-hold/<hold_path> (or delete it outright).
-- purge:  delete the kept evidence once purge_after has passed.
create or replace function public._takedown_cleanup_due(p_limit integer default 20)
returns table (id uuid, phase text, bucket text, path text, hold_path text)
language sql
security definer
set search_path = public
as $$
  (select t.id, 'remove'::text, t.bucket, t.path, t.hold_path
     from media_takedowns t
    where t.status in ('pending', 'error') and t.next_try <= now()
    order by t.next_try
    limit greatest(coalesce(p_limit, 20), 0))
  union all
  (select t.id, 'purge'::text, t.bucket, t.path, t.hold_path
     from media_takedowns t
    where t.status = 'removed' and t.hold_path is not null
      and t.purge_after <= now() and t.next_try <= now()
    order by t.purge_after
    limit greatest(coalesce(p_limit, 20), 0))
$$;

-- The server decides from storage.objects itself, never from the caller's word.
create or replace function public._takedown_cleanup_report(p_id uuid, p_phase text, p_error text default null)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare t media_takedowns%rowtype; v_up boolean; v_kept boolean;
begin
  select * into t from media_takedowns where id = p_id for update;
  if not found then return 'unknown'; end if;
  if p_phase = 'remove' then
    if t.status in ('removed', 'purged') then return t.status; end if;
    -- the version that was taken down (a newer upload at the same path is not it)
    select exists (select 1 from storage.objects o
                    where o.bucket_id = t.bucket and o.name = t.path
                      and coalesce(o.updated_at, o.created_at) <= t.taken_at) into v_up;
    if not v_up then
      select exists (select 1 from storage.objects o
                      where o.bucket_id = 'moderation-hold' and o.name = t.hold_path) into v_kept;
      update media_takedowns
         set status = 'removed', removed_at = now(), attempts = attempts + 1, next_try = now(),
             hold_path = case when v_kept then hold_path end,
             purge_after = case when v_kept then now() + interval '90 days' end,
             last_error = case when v_kept then null
                               else left('evidence not kept: ' || coalesce(nullif(p_error, ''), 'the move did not land'), 500) end
       where id = p_id;
      return 'removed';
    end if;
  elsif p_phase = 'purge' then
    select exists (select 1 from storage.objects o
                    where o.bucket_id = 'moderation-hold' and o.name = t.hold_path) into v_kept;
    if not v_kept then
      update media_takedowns set status = 'purged', purged_at = now(), last_error = null,
             attempts = attempts + 1, next_try = now()
       where id = p_id;
      return 'purged';
    end if;
  else
    raise exception 'unknown phase: %', p_phase;
  end if;
  update media_takedowns
     set status = case when p_phase = 'remove' then 'error' else status end,
         attempts = attempts + 1,
         last_error = left(coalesce(nullif(p_error, ''), 'Storage reported success but the file is still stored'), 500),
         -- back off: 2, 4, 8 … minutes, never more than a day between tries
         next_try = now() + least(interval '1 day', make_interval(mins => power(2, least(attempts + 1, 11))::int))
   where id = p_id;
  return 'error';
end $$;
revoke all on function public._takedown_cleanup_due(integer) from public, anon, authenticated;
revoke all on function public._takedown_cleanup_report(uuid, text, text) from public, anon, authenticated;
grant execute on function public._takedown_cleanup_due(integer) to service_role;
grant execute on function public._takedown_cleanup_report(uuid, text, text) to service_role;

-- ---- ban_account / unban_account ------------------------------------------------------
create or replace function public.ban_account(p_profile uuid, p_confirm text, p_reason text, p_report uuid default null)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_handle text;
  v_name   text;
  v_gone   timestamptz;
  v_expect text;
begin
  if auth.uid() is null or auth.uid() is distinct from founder_id() then
    raise exception 'Only the founder can remove a golfer';
  end if;
  if p_profile is null then raise exception 'nobody to remove'; end if;
  if p_profile = founder_id() then raise exception 'The founder''s account can''t be removed here'; end if;
  select handle, display_name, deleted_at into v_handle, v_name, v_gone from profiles where id = p_profile;
  if not found then raise exception 'no such golfer'; end if;
  if v_gone is not null then raise exception 'That account was already deleted'; end if;
  if p_reason is null or length(btrim(p_reason)) < 3 then
    raise exception 'Say why this golfer is being removed';
  end if;
  -- deliberate confirmation: the golfer's handle (or name, when there is no handle), typed back
  v_expect := lower(coalesce(nullif(v_handle, ''), v_name, ''));
  if v_expect = '' or lower(btrim(ltrim(btrim(coalesce(p_confirm, '')), '@'))) <> v_expect then
    raise exception 'Type the golfer''s handle exactly to confirm';
  end if;

  insert into account_bans (profile_id, banned_by, reason)
  values (p_profile, auth.uid(), left(btrim(p_reason), 500))
  on conflict (profile_id) do update
     set banned_at = now(), banned_by = excluded.banned_by, reason = excluded.reason,
         lifted_at = null, lifted_by = null, lift_reason = null;

  -- no new sign-in, no refresh (delete_account uses the same column)
  update auth.users set banned_until = 'infinity'::timestamptz where id = p_profile;
  -- end the sessions the platform holds; tables exist on Supabase, not in every sandbox
  if to_regclass('auth.refresh_tokens') is not null then
    execute 'delete from auth.refresh_tokens where user_id = $1' using p_profile::text;
  end if;
  if to_regclass('auth.sessions') is not null then
    execute 'delete from auth.sessions where user_id = $1' using p_profile;
  end if;
  -- nothing more reaches them, and they reach nobody through push
  delete from device_tokens where profile_id = p_profile;
  delete from push_subscriptions where profile_id = p_profile;

  if p_report is not null then
    update content_reports
       set resolved = true, resolved_at = now(), resolved_by = auth.uid(),
           resolution = left('golfer removed: ' || btrim(p_reason), 500)
     where id = p_report;
  end if;

  insert into moderation_actions (actor, action, target_profile, report_id, reason)
  values (auth.uid(), 'ban', p_profile, p_report, left(btrim(p_reason), 500));

  return jsonb_build_object('banned', true);
end $$;
revoke all on function public.ban_account(uuid, text, text, uuid) from public, anon, authenticated;
grant execute on function public.ban_account(uuid, text, text, uuid) to authenticated;

create or replace function public.unban_account(p_profile uuid, p_reason text)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() is distinct from founder_id() then
    raise exception 'Only the founder can restore a golfer';
  end if;
  if p_reason is null or length(btrim(p_reason)) < 3 then
    raise exception 'Say why this golfer is being restored';
  end if;
  update account_bans
     set lifted_at = now(), lifted_by = auth.uid(), lift_reason = left(btrim(p_reason), 500)
   where profile_id = p_profile and lifted_at is null;
  if not found then raise exception 'That golfer is not removed'; end if;
  update auth.users set banned_until = null
   where id = p_profile
     and not exists (select 1 from profiles p where p.id = p_profile and p.deleted_at is not null);
  insert into moderation_actions (actor, action, target_profile, reason)
  values (auth.uid(), 'unban', p_profile, left(btrim(p_reason), 500));
  return jsonb_build_object('banned', false);
end $$;
revoke all on function public.unban_account(uuid, text) from public, anon, authenticated;
grant execute on function public.unban_account(uuid, text) to authenticated;

-- ---- moderation_queue, re-emitted whole: what the desk needs to act ---------------------
create or replace function public.moderation_queue()
returns jsonb
language plpgsql stable security definer
set search_path = public
as $$
declare v jsonb;
begin
  if auth.uid() is distinct from founder_id() then
    raise exception 'the desk is the founder''s';
  end if;
  select coalesce(jsonb_agg(x order by x->>'created_at' desc), '[]'::jsonb) into v
  from (
    select jsonb_build_object(
      'id',          cr.id,
      'kind',        cr.kind,
      'reason',      cr.reason,
      'created_at',  cr.created_at,
      'reporter',    (select display_name from profiles where id = cr.reporter),
      'post_id',     cr.post_id,
      'comment_id',  cr.comment_id,
      'profile_id',  cr.profile_id,
      'league',      (select l.name from leagues l where l.id = p.league_id),
      'league_id',   p.league_id,
      'author',      (select pr.display_name from league_members lm
                        join profiles pr on pr.id = lm.profile_id
                       where lm.id = p.member_id),
      'body',        left(coalesce(p.body, ''), 400),
      'already_hidden', (p.hidden_at is not null),
      'comment_body',     (select left(c.body, 400) from post_comments c
                            where cr.kind = 'comment' and c.id = cr.comment_id),
      'comment_author',   (select pr.display_name from post_comments c
                             left join league_members lm on lm.id = c.member_id
                             join profiles pr on pr.id = coalesce(c.profile_id, lm.profile_id)
                            where cr.kind = 'comment' and c.id = cr.comment_id),
      'comment_round_id', (select coalesce(c.round_id, pp.round_id) from post_comments c
                             left join posts pp on pp.id = c.post_id
                            where cr.kind = 'comment' and c.id = cr.comment_id),
      'comment_hidden',   (select c.hidden_at is not null from post_comments c
                            where cr.kind = 'comment' and c.id = cr.comment_id),
      -- [D403] what the desk acts on
      'round_comment_body',   (select left(rc.body, 400) from round_comments rc
                                where cr.kind = 'round_comment' and rc.id = cr.comment_id),
      'round_comment_hidden', (select rc.hidden_at is not null from round_comments rc
                                where cr.kind = 'round_comment' and rc.id = cr.comment_id),
      'subject_profile_id', s.subject,
      'subject_name',       (select display_name from profiles where id = s.subject),
      'subject_handle',     (select handle from profiles where id = s.subject),
      'subject_banned',     coalesce(public.is_banned(s.subject), false),
      'subject_is_founder', (s.subject is not null and s.subject = founder_id()),
      'profile_has_photo',  (select pr.photo_path is not null from profiles pr where pr.id = s.subject),
      'round_id',           p.round_id,
      'round_has_photo',    (select r.photo_path is not null from rounds r where r.id = p.round_id)
    ) as x
    from content_reports cr
    left join posts p on p.id = cr.post_id
    cross join lateral (
      select case
        when cr.kind in ('profile','profile_photo') then cr.profile_id
        when cr.kind = 'comment' then (select coalesce(c.profile_id, lm.profile_id) from post_comments c
                                          left join league_members lm on lm.id = c.member_id
                                         where c.id = cr.comment_id)
        when cr.kind = 'round_comment' then (select rc.profile_id from round_comments rc where rc.id = cr.comment_id)
        else coalesce(p.profile_id, (select lm.profile_id from league_members lm where lm.id = p.member_id))
      end as subject
    ) s
    where cr.resolved_at is null and coalesce(cr.resolved, false) = false
  ) q;
  return v;
end $$;
revoke all on function public.moderation_queue() from public, anon, authenticated;
grant execute on function public.moderation_queue() to authenticated;
