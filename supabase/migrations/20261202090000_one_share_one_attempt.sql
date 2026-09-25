-- Launch-audit integration I5b (2026-09-24) · D385 §3–§5 · one share, one attempt.
-- The server half of docs/planning/2026-09-24-native-audit-contract.md (Codex's native
-- branch), for both clients. Additive: create_share / revoke_share / withdraw_round_shares
-- keep working for older clients.
--
-- The old flow minted (or re-returned) the one live token before the share sheet opened,
-- so a cancelled sheet had already published, a re-share could not tell a photo-less link
-- from one whose consent had changed, and two attempts could revoke each other's links.
--
--   shares gains `include_photo` (the recorded consent; null = a legacy link whose consent
--   was never recorded) and `completed_at` (the link was actually shared; null while an
--   attempt prepares it). share_attempts records each attempt, its token and its lease.
--
--   prepare_round_share(round, include_photo, attempt) → {token, created, include_photo}
--     idempotent on the attempt. A COMPLETED live link whose recorded consent equals this
--     request is reused (created=false; a photo-less link stays photo-less). A changed
--     consent, or a legacy link with no recorded consent, is rotated: revoked (its copies
--     queued for durable cleanup, 20261201090000) and a new token minted for THIS attempt
--     (created=true) under a 15-minute lease. Another attempt's live preparation is never
--     borrowed or revoked — the caller is told to try again — until its lease lapses.
--   finish_round_share(attempt, completed) → idempotent acknowledgement. Completed makes a
--     link this attempt created durable. Cancelled/failed retires ONLY a token this attempt
--     created and never completed; a reused, completed link is untouched. A finished,
--     expired or revoked attempt is never reactivated by a late or duplicate call.
--   round_share_status(round) → {token, cleanup_pending, …}: owner-only, read-only, never
--     mints. cleanup_pending stays true until Storage is verified clean for every revoked
--     token of the round; a missing token is not proof the bytes are gone.
--   _expire_share_attempts() reclaims abandoned preparations (a sheet the app never
--     reported back): expired, and a created, never-completed token revoked (and so queued
--     for cleanup). Called by prepare (for that round) and by the share-cleanup sweep.

-- ── the recorded consent and completion ─────────────────────────────────────
alter table public.shares add column if not exists include_photo boolean;
alter table public.shares add column if not exists completed_at timestamptz default now();
-- links minted before this change were shared the old way: complete, consent unrecorded
update public.shares set completed_at = created_at where completed_at is null and not coalesce(revoked, false);

create table if not exists public.share_attempts (
  attempt_id       uuid primary key,
  owner_id         uuid not null references public.profiles(id) on delete cascade,
  kind             text not null default 'round',
  ref_id           uuid not null,
  token            uuid not null,
  created          boolean not null,
  include_photo    boolean not null,
  state            text not null default 'prepared' check (state in ('prepared', 'completed', 'cancelled', 'expired')),
  lease_expires_at timestamptz not null,
  created_at       timestamptz not null default now(),
  finished_at      timestamptz
);
create index if not exists share_attempts_open on public.share_attempts (ref_id, owner_id) where state = 'prepared';
alter table public.share_attempts enable row level security;
revoke all on table public.share_attempts from public, anon, authenticated;

-- ── reclaim what nobody finished ────────────────────────────────────────────
create or replace function public._expire_share_attempts(p_ref uuid default null)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  with gone as (
    update share_attempts a set state = 'expired', finished_at = now()
     where a.state = 'prepared' and a.lease_expires_at < now()
       and (p_ref is null or a.ref_id = p_ref)
    returning a.token, a.created
  )
  update shares s set revoked = true            -- the trigger queues its cleanup
    from gone g
   where s.token = g.token and g.created and s.completed_at is null and not s.revoked;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public._expire_share_attempts(uuid) from public, anon, authenticated;
grant execute on function public._expire_share_attempts(uuid) to service_role;

-- ── prepare ─────────────────────────────────────────────────────────────────
create or replace function public.prepare_round_share(p_round uuid, p_include_photo boolean, p_attempt uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid(); a share_attempts%rowtype; live shares%rowtype;
  v_photo boolean; v_tok uuid; v_open share_attempts%rowtype;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_round is null or p_attempt is null then raise exception 'Nothing to share'; end if;

  -- idempotent on the attempt: the same answer, whatever has happened since
  select * into a from share_attempts where attempt_id = p_attempt;
  if a.attempt_id is not null then
    if a.owner_id is distinct from v then raise exception 'Nothing to share'; end if;
    return jsonb_build_object('token', a.token, 'created', a.created, 'include_photo', a.include_photo,
      'state', a.state, 'active', exists (select 1 from shares where token = a.token and not revoked));
  end if;

  -- your own posted, unvoided round (create_share's rule); the photo only if there is one
  select nullif(btrim(coalesce(r.photo_path, '')), '') is not null into v_photo
    from rounds r where r.id = p_round and r.profile_id = v and not r.voided;
  if not found then raise exception 'Nothing to share'; end if;
  v_photo := coalesce(p_include_photo, false) and v_photo;

  perform _expire_share_attempts(p_round);
  -- one preparation at a time per round: never borrow or revoke another attempt's token
  select * into v_open from share_attempts
   where ref_id = p_round and owner_id = v and state = 'prepared' and lease_expires_at >= now()
   order by created_at desc limit 1
   for update;
  select * into live from shares
   where kind = 'round' and ref_id = p_round and created_by = v and not revoked
   for update;

  -- another open attempt: only a same-consent reuse of a completed link may run beside it;
  -- anything that would mint, rotate or retire is refused until that attempt finishes or lapses
  if v_open.attempt_id is not null
     and not (live.token is not null and live.completed_at is not null
              and live.include_photo is not null and live.include_photo = v_photo) then
    raise exception 'This round is already being shared. Try again in a moment.';
  end if;

  if live.token is not null and live.completed_at is not null
     and live.include_photo is not null and live.include_photo = v_photo then
    -- the completed link, consent unchanged: reuse it (a photo-less link stays photo-less)
    insert into share_attempts (attempt_id, owner_id, ref_id, token, created, include_photo, lease_expires_at)
    values (p_attempt, v, p_round, live.token, false, v_photo, now() + interval '15 minutes');
    return jsonb_build_object('token', live.token, 'created', false, 'include_photo', v_photo,
                              'state', 'prepared', 'active', true);
  end if;

  if live.token is not null then
    -- consent changed, or never recorded: rotate (the trigger queues the old copies' cleanup)
    update shares set revoked = true where token = live.token;
  end if;

  insert into shares (kind, ref_id, created_by, include_photo, completed_at)
  values ('round', p_round, v, v_photo, null)
  returning token into v_tok;
  insert into share_attempts (attempt_id, owner_id, ref_id, token, created, include_photo, lease_expires_at)
  values (p_attempt, v, p_round, v_tok, true, v_photo, now() + interval '15 minutes');
  return jsonb_build_object('token', v_tok, 'created', true, 'include_photo', v_photo,
                            'state', 'prepared', 'active', true,
                            'rotated', live.token is not null);
end $$;
revoke all on function public.prepare_round_share(uuid, boolean, uuid) from public, anon;
grant execute on function public.prepare_round_share(uuid, boolean, uuid) to authenticated;

-- ── finish ──────────────────────────────────────────────────────────────────
create or replace function public.finish_round_share(p_attempt uuid, p_completed boolean)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); a share_attempts%rowtype; s shares%rowtype;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into a from share_attempts where attempt_id = p_attempt and owner_id = v for update;
  if a.attempt_id is null then raise exception 'Nothing to finish'; end if;

  if a.state = 'prepared' and a.lease_expires_at < now() then
    perform _expire_share_attempts(a.ref_id);
    select * into a from share_attempts where attempt_id = p_attempt;
  end if;

  if a.state = 'prepared' then
    select * into s from shares where token = a.token for update;
    if coalesce(p_completed, false) then
      update share_attempts set state = 'completed', finished_at = now() where attempt_id = p_attempt;
      -- durable only if nothing revoked it meanwhile (a withdrawal never gets reactivated)
      if a.created and not s.revoked then
        update shares set completed_at = coalesce(completed_at, now()) where token = a.token;
      end if;
    else
      update share_attempts set state = 'cancelled', finished_at = now() where attempt_id = p_attempt;
      -- retire ONLY a token this attempt created and never completed
      if a.created and not s.revoked and s.completed_at is null then
        update shares set revoked = true where token = a.token;   -- the trigger queues cleanup
      end if;
    end if;
    select * into a from share_attempts where attempt_id = p_attempt;
  end if;

  select * into s from shares where token = a.token;
  return jsonb_build_object('attempt', a.attempt_id, 'state', a.state, 'token', a.token,
    'created', a.created, 'active', not s.revoked and s.completed_at is not null,
    'cleanup_pending', exists (select 1 from share_cleanup c where c.token = a.token and c.status <> 'completed'));
end $$;
revoke all on function public.finish_round_share(uuid, boolean) from public, anon;
grant execute on function public.finish_round_share(uuid, boolean) to authenticated;

-- ── status ──────────────────────────────────────────────────────────────────
create or replace function public.round_share_status(p_round uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v uuid := auth.uid(); live shares%rowtype;
begin
  if v is null then raise exception 'Sign in first'; end if;
  -- the creator's view, for a round that exists or one already deleted
  if not exists (select 1 from rounds where id = p_round and profile_id = v)
     and not exists (select 1 from shares where kind = 'round' and ref_id = p_round and created_by = v) then
    raise exception 'Nothing to show';
  end if;
  select * into live from shares
   where kind = 'round' and ref_id = p_round and created_by = v and not revoked and completed_at is not null;
  return jsonb_build_object(
    'token', live.token,
    'include_photo', live.include_photo,
    'cleanup_pending', exists (select 1 from share_cleanup c join shares s on s.token = c.token
                                where s.kind = 'round' and s.ref_id = p_round and s.created_by = v
                                  and c.status <> 'completed'),
    'cleanup', coalesce((select jsonb_agg(jsonb_build_object('token', c.token, 'status', c.status,
                                  'last_error', c.last_error, 'next_attempt_at', c.next_attempt_at)
                                  order by c.requested_at desc)
                           from share_cleanup c join shares s on s.token = c.token
                          where s.kind = 'round' and s.ref_id = p_round and s.created_by = v
                            and c.status <> 'completed'), '[]'::jsonb),
    'preparing', exists (select 1 from share_attempts a where a.ref_id = p_round and a.owner_id = v
                           and a.state = 'prepared' and a.lease_expires_at >= now()));
end $$;
revoke all on function public.round_share_status(uuid) from public, anon;
grant execute on function public.round_share_status(uuid) to authenticated;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if not has_function_privilege('authenticated', 'public.prepare_round_share(uuid, boolean, uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.finish_round_share(uuid, boolean)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.round_share_status(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.prepare_round_share(uuid, boolean, uuid)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public._expire_share_attempts(uuid)', 'EXECUTE')
     or has_table_privilege('authenticated', 'public.share_attempts', 'SELECT')
     or has_table_privilege('authenticated', 'public.shares', 'SELECT') then
    raise exception '[I5b] a share-lifecycle grant is wrong';
  end if;
end $chk$;
