-- Launch-audit integration I5 (2026-09-24) · D385 · a withdrawn photo is GONE, not just unlinked.
--
-- D385 (20261121090000) made remove / replace / delete revoke the round's links, and the
-- clients remove `shared/{token}.jpg|png` through the Storage API afterwards. Codex's
-- review (2026-09-24): both client halves discard cleanup failures, so a failed or
-- interrupted cleanup left the old image PUBLIC with no error and no retry — and
-- revocation disables the app's page, it does not remove bytes from the public URL. An
-- old client (986) never cleans at all. The database may not delete a storage object
-- (D303: 42501, "Use the Storage API instead"), so this adds a DURABLE OBLIGATION:
--
--   1 · public.share_cleanup: one row per revoked token, created by a trigger on
--       shares the moment ANY path revokes a link (remove, replace, delete, turn off, a
--       cancelled share, an old client). It stays `pending` until both copies are
--       CONFIRMED absent from storage.objects; `error` records what failed and when to
--       try again; `completed` records when it was confirmed.
--   2 · The owner reads their own rows (my_share_cleanup), can retry
--       (retry_share_cleanup) and can confirm after their own client removed the files
--       (confirm_share_cleanup, which checks storage itself: a client's word is not proof).
--   3 · The service side — the `share-cleanup` Edge Function, invoked by a Database
--       Webhook on this table and sweeping every due row on each call — takes the due
--       tokens (_share_cleanup_due), removes both copies through the Storage API, and
--       reports each attempt (_share_cleanup_report), which re-verifies absence before it
--       ever says completed. Service role only.
--   4 · Backfill: revoked tokens whose copies are still stored, and live round links whose
--       round no longer exists (the L-05 orphans), are revoked and queued now.
--
-- Deploy owed beyond the migration (not done here): the `share-cleanup` function, its
-- SHARE_CLEANUP_SECRET, and the Database Webhook (INSERT and UPDATE on public.share_cleanup
-- → share-cleanup, header x-cleanup-secret). Until then the queue is durable and visible,
-- and clients' own cleanup + confirm_share_cleanup completes rows.

-- ── 1 · the obligation ──────────────────────────────────────────────────────
create table if not exists public.share_cleanup (
  token           uuid primary key,
  owner_id        uuid references public.profiles(id) on delete set null,
  kind            text not null,
  ref_id          uuid,
  status          text not null default 'pending' check (status in ('pending', 'completed', 'error')),
  attempts        integer not null default 0,
  last_error      text,
  requested_at    timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  next_attempt_at timestamptz not null default now(),
  completed_at    timestamptz
);
create index if not exists share_cleanup_due on public.share_cleanup (next_attempt_at) where status <> 'completed';
create index if not exists share_cleanup_owner on public.share_cleanup (owner_id, requested_at desc);

alter table public.share_cleanup enable row level security;
revoke all on table public.share_cleanup from public, anon, authenticated;
grant select on table public.share_cleanup to authenticated;
drop policy if exists share_cleanup_owner_read on public.share_cleanup;
create policy share_cleanup_owner_read on public.share_cleanup for select to authenticated
  using (owner_id = auth.uid());

-- how many public copies of a token are still stored (a read; SQL never deletes them)
create or replace function public._share_copies_remaining(p_token uuid)
returns integer language sql stable security definer set search_path = public, storage
as $$ select count(*)::int from storage.objects o
       where o.bucket_id = 'shared' and o.name in (p_token::text || '.jpg', p_token::text || '.png') $$;
revoke all on function public._share_copies_remaining(uuid) from public, anon, authenticated;

-- every revocation, by any path, queues its cleanup
create or replace function public._queue_share_cleanup()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.revoked and not coalesce(old.revoked, false) then
    insert into share_cleanup (token, owner_id, kind, ref_id)
    values (new.token, new.created_by, new.kind, new.ref_id)
    on conflict (token) do update
      set status = 'pending', next_attempt_at = now(), updated_at = now()
      where share_cleanup.status <> 'completed';
  end if;
  return new;
end $$;
revoke all on function public._queue_share_cleanup() from public, anon, authenticated;
drop trigger if exists shares_queue_cleanup on public.shares;
create trigger shares_queue_cleanup after update of revoked on public.shares
  for each row execute function public._queue_share_cleanup();

-- ── 2 · the owner's view, retry and confirmation ────────────────────────────
create or replace function public.my_share_cleanup()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'token', c.token, 'kind', c.kind, 'ref_id', c.ref_id, 'status', c.status,
      'attempts', c.attempts, 'last_error', c.last_error, 'requested_at', c.requested_at,
      'next_attempt_at', case when c.status <> 'completed' then c.next_attempt_at end,
      'completed_at', c.completed_at,
      'paths', jsonb_build_array(c.token::text || '.jpg', c.token::text || '.png'))
      order by c.requested_at desc)
    from share_cleanup c where c.owner_id = v), '[]'::jsonb);
end $$;
revoke all on function public.my_share_cleanup() from public, anon;
grant execute on function public.my_share_cleanup() to authenticated;

create or replace function public.retry_share_cleanup(p_token uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); c share_cleanup%rowtype;
begin
  if v is null then raise exception 'Sign in first'; end if;
  update share_cleanup set status = 'pending', next_attempt_at = now(), updated_at = now()
   where token = p_token and owner_id = v and status <> 'completed'
  returning * into c;
  if c.token is null then
    select * into c from share_cleanup where token = p_token and owner_id = v;
    if c.token is null then raise exception 'Nothing to retry'; end if;
  end if;
  return jsonb_build_object('token', c.token, 'status', c.status,
    'paths', jsonb_build_array(c.token::text || '.jpg', c.token::text || '.png'));
end $$;
revoke all on function public.retry_share_cleanup(uuid) from public, anon;
grant execute on function public.retry_share_cleanup(uuid) to authenticated;

-- after a client removed its own copies: the server checks storage, never the client's word
create or replace function public.confirm_share_cleanup(p_token uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); n integer; c share_cleanup%rowtype;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into c from share_cleanup where token = p_token and owner_id = v;
  if c.token is null then raise exception 'Nothing to confirm'; end if;
  n := _share_copies_remaining(p_token);
  if n = 0 then
    update share_cleanup set status = 'completed', completed_at = coalesce(completed_at, now()),
           last_error = null, updated_at = now()
     where token = p_token returning * into c;
  else
    update share_cleanup set status = 'error', attempts = attempts + 1, updated_at = now(),
           last_error = n || ' public cop' || case when n = 1 then 'y is' else 'ies are' end || ' still stored',
           next_attempt_at = now()
     where token = p_token and status <> 'completed' returning * into c;
  end if;
  return jsonb_build_object('token', c.token, 'status', c.status, 'remaining', n, 'last_error', c.last_error);
end $$;
revoke all on function public.confirm_share_cleanup(uuid) from public, anon;
grant execute on function public.confirm_share_cleanup(uuid) to authenticated;

-- ── 3 · the service side (the share-cleanup Edge Function) ──────────────────
create or replace function public._share_cleanup_due(p_limit integer default 50)
returns setof uuid language sql stable security definer set search_path = public as $$
  select token from share_cleanup
   where status <> 'completed' and next_attempt_at <= now()
   order by next_attempt_at limit greatest(1, least(coalesce(p_limit, 50), 500)) $$;

create or replace function public._share_cleanup_report(p_token uuid, p_error text default null)
returns text language plpgsql security definer set search_path = public as $$
declare n integer := _share_copies_remaining(p_token); v_attempts integer;
begin
  if n = 0 then
    update share_cleanup set status = 'completed', completed_at = coalesce(completed_at, now()),
           last_error = null, attempts = attempts + 1, updated_at = now()
     where token = p_token;
    return 'completed';
  end if;
  update share_cleanup set status = 'error', attempts = attempts + 1, updated_at = now(),
         last_error = left(coalesce(nullif(p_error, ''), 'Storage reported success but '
                           || n || ' public cop' || case when n = 1 then 'y is' else 'ies are' end || ' still stored'), 500),
         -- back off: 2, 4, 8 … minutes, never more than a day between tries
         next_attempt_at = now() + least(interval '1 day', make_interval(mins => power(2, least(attempts + 1, 11))::int))
   where token = p_token and status <> 'completed'
  returning attempts into v_attempts;
  return 'error';
end $$;
revoke all on function public._share_cleanup_due(integer) from public, anon, authenticated;
revoke all on function public._share_cleanup_report(uuid, text) from public, anon, authenticated;
grant execute on function public._share_cleanup_due(integer) to service_role;
grant execute on function public._share_cleanup_report(uuid, text) to service_role;

-- ── 4 · what was left before this existed ───────────────────────────────────
do $backfill$
declare v_orphans integer; v_revoked integer;
begin
  -- round links whose round is gone (deleted before D385 revoked on delete): revoke them;
  -- the trigger queues each
  update shares s set revoked = true
   where s.kind = 'round' and not s.revoked
     and not exists (select 1 from rounds r where r.id = s.ref_id);
  get diagnostics v_orphans = row_count;
  -- links revoked earlier whose public copies are still stored
  insert into share_cleanup (token, owner_id, kind, ref_id)
  select s.token, s.created_by, s.kind, s.ref_id from shares s
   where s.revoked and _share_copies_remaining(s.token) > 0
  on conflict (token) do nothing;
  get diagnostics v_revoked = row_count;
  raise notice '[I5] % orphaned round link(s) revoked and queued; % earlier revocation(s) with stored copies queued',
    v_orphans, v_revoked;
end $backfill$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if not exists (select 1 from pg_trigger where tgname = 'shares_queue_cleanup'
                   and tgrelid = 'public.shares'::regclass and not tgisinternal) then
    raise exception '[I5] a revocation does not queue its cleanup';
  end if;
  if has_function_privilege('authenticated', 'public._share_cleanup_report(uuid, text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public._share_cleanup_due(integer)', 'EXECUTE')
     or has_function_privilege('anon', 'public.my_share_cleanup()', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.confirm_share_cleanup(uuid)', 'EXECUTE')
     or has_table_privilege('authenticated', 'public.share_cleanup', 'UPDATE')
     or has_table_privilege('anon', 'public.share_cleanup', 'SELECT') then
    raise exception '[I5] a grant on the cleanup obligation is wrong';
  end if;
  -- the anon surface is unchanged (twelve public endpoints)
  if has_function_privilege('anon', 'public.retry_share_cleanup(uuid)', 'EXECUTE') then
    raise exception '[I5] a cleanup door is open signed out';
  end if;
end $chk$;
