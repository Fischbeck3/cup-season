-- ============================================================================
-- Cup Season — D71: league cancellation with consent
--
-- delete_league refuses a started league and is commissioner-only — no path to
-- end a league once under way. This adds one, gated by the money at stake:
--   · FREE league  → the Pro cancels alone, immediately.
--   · MONEY league → UNANIMOUS member approval; any decline kills the request.
-- On execution the league is fully removed (cascade); every player's global
-- rounds survive on their profile. Each member is owed their own paid buy-in
-- back — a NOTICE (D39: the app moves nothing), delivered in-app and by email.
--
-- The cancellation email fires from a SELF-CONTAINED snapshot written BEFORE the
-- delete (cancellation_notices, no FK to the league), so the async send never
-- reads deleted data.
-- ============================================================================

-- ---- one open request per league -------------------------------------------
create table if not exists public.league_cancellations (
  league_id    uuid primary key references public.leagues(id) on delete cascade,
  requested_by uuid not null,
  requested_at timestamptz not null default now()
);
alter table public.league_cancellations enable row level security;
revoke all on table public.league_cancellations from public, anon, authenticated;

-- ---- per-member approvals (a row exists only for an APPROVE) ----------------
create table if not exists public.cancellation_votes (
  league_id uuid not null references public.leagues(id) on delete cascade,
  member_id uuid not null,
  voted_at  timestamptz not null default now(),
  primary key (league_id, member_id)
);
alter table public.cancellation_votes enable row level security;
revoke all on table public.cancellation_votes from public, anon, authenticated;

-- ---- the refund snapshot — OUTLIVES the league (no FK) ----------------------
create table if not exists public.cancellation_notices (
  id         uuid primary key default gen_random_uuid(),
  payload    jsonb not null,           -- {league, recipients:[{email,name,cents}]}
  created_at timestamptz not null default now(),
  sent_at    timestamptz,
  error      text
);
alter table public.cancellation_notices enable row level security;
revoke all on table public.cancellation_notices from public, anon, authenticated;

-- ---- the cancel routine (internal; ordered so the email survives) ----------
-- Owned by postgres, EXECUTE revoked from every API role: only the definer RPCs
-- below reach it. Snapshot -> queue notice -> delete (cascade).
create or replace function public.cancel_league_now(p_league uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare v_league text; v_snap jsonb;
begin
  select name into v_league from leagues where id = p_league;

  -- real-address members and each one's own paid buy-in (their refund)
  select coalesce(jsonb_agg(jsonb_build_object(
           'email', t.email, 'name', t.display_name, 'cents', t.cents)), '[]'::jsonb)
    into v_snap
    from (
      select p.email, p.display_name,
             coalesce((select sum(b.amount_cents) from buy_ins b
                        join seasons s on s.id = b.season_id
                       where s.league_id = p_league and b.member_id = lm.id and b.paid), 0) as cents
        from league_members lm
        join profiles p on p.id = lm.profile_id
       where lm.league_id = p_league
         and p.email is not null and p.email <> ''
         and p.email not like '%@cupseason.invalid'
         and p.email not like '%@sandbox.cupseason.test'
    ) t;

  -- a cancellation email only when real money is owed, and never for a sandbox
  if not exists (select 1 from leagues where id = p_league and sandbox)
     and exists (select 1 from jsonb_array_elements(v_snap) e where (e->>'cents')::int > 0) then
    insert into cancellation_notices (payload)
    values (jsonb_build_object('league', coalesce(v_league,'your league'), 'recipients', v_snap));
  end if;

  delete from leagues where id = p_league;   -- cascades everything league-scoped
end $$;
revoke all on function public.cancel_league_now(uuid) from public, anon, authenticated;

-- ---- request (Pro): free -> cancel now; money -> open the vote -------------
create or replace function public.request_league_cancel(p_league uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare lg leagues%rowtype; v_money boolean; v uuid := auth.uid(); v_mid uuid;
begin
  select * into lg from leagues where id = p_league;
  if not found then raise exception 'league not found'; end if;
  if not is_commissioner(p_league) then raise exception 'commissioner only'; end if;
  if lg.phase = 'complete' then
    raise exception 'completed seasons are the record book — they cannot be cancelled';
  end if;

  select (coalesce(buyin_cents,0) > 0) into v_money from league_settings where league_id = p_league;

  if not coalesce(v_money, false) then
    perform cancel_league_now(p_league);          -- free league: Pro-alone
    return 'done';
  end if;

  -- money league: open a fresh request; the Pro's initiation IS their approval
  insert into league_cancellations (league_id, requested_by)
    values (p_league, v)
  on conflict (league_id) do update set requested_by = excluded.requested_by, requested_at = now();
  delete from cancellation_votes where league_id = p_league;
  select id into v_mid from league_members where league_id = p_league and profile_id = v;
  if v_mid is not null then
    insert into cancellation_votes (league_id, member_id) values (p_league, v_mid)
    on conflict do nothing;
  end if;
  -- the Pro may be the ONLY member — their own approval is already unanimous,
  -- so execute inline rather than hang at 1-of-1 forever
  if (select count(*) from league_members   where league_id = p_league)
  <= (select count(*) from cancellation_votes where league_id = p_league) then
    perform cancel_league_now(p_league);
    return 'done';
  end if;
  return 'open';
end $$;
revoke all on function public.request_league_cancel(uuid) from public, anon;
grant execute on function public.request_league_cancel(uuid) to authenticated;

-- ---- vote (member): decline kills it; the vote completing unanimity runs it -
create or replace function public.vote_league_cancel(p_league uuid, p_approve boolean)
returns text
language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); v_mid uuid; n_members int; n_votes int;
begin
  if not is_league_member(p_league) then raise exception 'not your league'; end if;
  if not exists (select 1 from league_cancellations where league_id = p_league) then
    raise exception 'nothing to vote on';
  end if;
  select id into v_mid from league_members where league_id = p_league and profile_id = v;
  if v_mid is null then raise exception 'not a member'; end if;

  if not p_approve then
    delete from cancellation_votes  where league_id = p_league;   -- any decline
    delete from league_cancellations where league_id = p_league;  -- kills it
    return 'declined';
  end if;

  insert into cancellation_votes (league_id, member_id) values (p_league, v_mid)
  on conflict do nothing;
  select count(*) into n_members from league_members  where league_id = p_league;
  select count(*) into n_votes   from cancellation_votes where league_id = p_league;
  if n_votes >= n_members then
    perform cancel_league_now(p_league);          -- unanimous: execute
    return 'done';
  end if;
  return 'pending';
end $$;
revoke all on function public.vote_league_cancel(uuid, boolean) from public, anon;
grant execute on function public.vote_league_cancel(uuid, boolean) to authenticated;

-- ---- withdraw (Pro) --------------------------------------------------------
create or replace function public.withdraw_league_cancel(p_league uuid)
returns text
language plpgsql security definer set search_path = public as $$
begin
  if not is_commissioner(p_league) then raise exception 'commissioner only'; end if;
  delete from cancellation_votes  where league_id = p_league;
  delete from league_cancellations where league_id = p_league;
  return 'withdrawn';
end $$;
revoke all on function public.withdraw_league_cancel(uuid) from public, anon;
grant execute on function public.withdraw_league_cancel(uuid) to authenticated;

-- ---- status (member): drives the consent screen ----------------------------
create or replace function public.league_cancel_status(p_league uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare v uuid := auth.uid(); v_mid uuid; v_req record;
        n_members int; n_votes int; v_cents int; v_mine boolean;
begin
  if not is_league_member(p_league) then raise exception 'not your league'; end if;
  select * into v_req from league_cancellations where league_id = p_league;
  if v_req.league_id is null then return null; end if;   -- no open request

  select id into v_mid from league_members where league_id = p_league and profile_id = v;
  select count(*) into n_members from league_members  where league_id = p_league;
  select count(*) into n_votes   from cancellation_votes where league_id = p_league;
  select exists(select 1 from cancellation_votes where league_id = p_league and member_id = v_mid) into v_mine;
  select coalesce(sum(b.amount_cents),0) into v_cents
    from buy_ins b join seasons s on s.id = b.season_id
   where s.league_id = p_league and b.member_id = v_mid and b.paid;

  return jsonb_build_object(
    'open', true, 'members', n_members, 'approved', n_votes,
    'you_approved', coalesce(v_mine,false), 'you_refund_cents', v_cents,
    'is_pro', is_commissioner(p_league),
    'requested_by_me', v_req.requested_by = v);
end $$;
revoke all on function public.league_cancel_status(uuid) from public, anon;
grant execute on function public.league_cancel_status(uuid) to authenticated;

-- ---- the sender marks its own work done (service_role only) -----------------
create or replace function public.mark_cancellation_sent(p_id uuid, p_error text default null)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update cancellation_notices set sent_at = now(), error = p_error where id = p_id;
end $$;
revoke all on function public.mark_cancellation_sent(uuid, text) from public, anon, authenticated;
grant execute on function public.mark_cancellation_sent(uuid, text) to service_role;
