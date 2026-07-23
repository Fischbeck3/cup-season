-- ============================================================================
-- Cup Season — D68: the season-end email (the ceremony, delivered)
--
-- A season ends inside the app. The run-it-back decision gets made in the days
-- AFTER it closes, which is exactly when nobody is opening the app. So the
-- ceremony goes to the inbox: champion, margin, points king, the top of the
-- table, and the recipient's OWN payout line.
--
-- Shape mirrors the push webhook that already works: a queue table, a Database
-- Webhook on its INSERT, an Edge Function that sends. The trigger lives on
-- seasons.status so no gameplay function is re-plumbed, and the unique key
-- makes a re-close physically unable to double-send.
--
-- Consent lives in its OWN table, deliberately. profiles' grant list is sealed
-- (20260721214500) and, worse, a league-mate can read a league-mate's profile
-- row — an unsubscribe token there would let friends unsubscribe each other.
-- email_prefs is definer-only: no policies, no client reach.
-- ============================================================================

-- ---- consent ---------------------------------------------------------------
create table if not exists public.email_prefs (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  recap      boolean not null default true,
  token      uuid not null default gen_random_uuid(),
  updated_at timestamptz not null default now()
);
alter table public.email_prefs enable row level security;
-- no policies on purpose: the RPCs below are the only path (D37 posture)
revoke all on table public.email_prefs from public, anon, authenticated;

-- ---- the queue -------------------------------------------------------------
create table if not exists public.email_queue (
  id         uuid primary key default gen_random_uuid(),
  season_id  uuid not null references public.seasons(id) on delete cascade,
  kind       text not null default 'season_recap',
  created_at timestamptz not null default now(),
  sent_at    timestamptz,
  error      text,
  unique (season_id, kind)          -- a re-close can never double-send
);
alter table public.email_queue enable row level security;
revoke all on table public.email_queue from public, anon, authenticated;

-- ---- fire on close ---------------------------------------------------------
create or replace function public.season_email_on_complete()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'complete' and coalesce(old.status,'') <> 'complete' then
    insert into email_queue (season_id, kind) values (new.id, 'season_recap')
    on conflict (season_id, kind) do nothing;
  end if;
  return new;
end $$;
revoke all on function public.season_email_on_complete() from public, anon, authenticated;

drop trigger if exists seasons_email_on_complete on public.seasons;
create trigger seasons_email_on_complete
  after update of status on public.seasons
  for each row execute function public.season_email_on_complete();

-- ---- the payload: all game logic stays in the database ---------------------
-- service_role only. Returns recipients (with their own payout + unsubscribe
-- token) and the season's result. Placeholder/bot addresses are filtered here,
-- so a sandbox league physically cannot mail anyone.
create or replace function public.season_email_payload(p_season uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare se seasons%rowtype; v_league text; v_champ text; v_run text; v_king text;
        v_rows jsonb; v_to jsonb; v_solo boolean; st league_settings%rowtype;
begin
  select * into se from seasons where id = p_season and status = 'complete';
  if se.id is null then return null; end if;
  select name into v_league from leagues where id = se.league_id;
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (coalesce(st.structure,'') = 'solo');

  if v_solo then
    select p.display_name into v_champ from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.champion_member_id;
    select p.display_name into v_run from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.runnerup_member_id;
  else
    select name into v_champ from squads where id = se.champion_squad_id;
    select name into v_run   from squads where id = se.runnerup_squad_id;
  end if;
  select p.display_name into v_king from league_members lm
    join profiles p on p.id = lm.profile_id where lm.id = se.points_king_member_id;

  if v_solo then
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select p.display_name as name, vi.points from v_individual_standings vi
              join league_members lm on lm.id = vi.member_id
              join profiles p on p.id = lm.profile_id
             where vi.season_id = p_season order by vi.points desc limit 5) q;
  else
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select s.name, vs.points from v_squad_standings vs
              join squads s on s.id = vs.squad_id
             where vs.season_id = p_season order by vs.points desc limit 5) q;
  end if;

  -- recipients: real addresses only, still opted in, with their own money line
  select coalesce(jsonb_agg(jsonb_build_object(
           'email', t.email, 'name', t.display_name,
           'token', t.token, 'cents', t.cents)), '[]'::jsonb)
    into v_to
    from (
      select p.email, p.display_name,
             ep.token,
             coalesce((select sum(sp.cents) from season_payouts sp
                        where sp.season_id = p_season and sp.profile_id = p.id), 0) as cents
        from league_members lm
        join profiles p on p.id = lm.profile_id
        left join email_prefs ep on ep.profile_id = p.id
       where lm.league_id = se.league_id
         and p.email is not null
         and p.email <> ''
         and p.email not like '%@cupseason.invalid'
         and p.email not like '%@sandbox.cupseason.test'
         and coalesce(ep.recap, true)
    ) t;

  return jsonb_build_object(
    'season_id', p_season, 'league', v_league,
    'champion', coalesce(v_champ,'The champion'), 'runner_up', v_run,
    'points_king', v_king,
    'champion_score', se.champion_score, 'runnerup_score', se.runnerup_score,
    'tiebreak', se.tiebreak_rung,
    'starts_on', to_char(se.starts_on,'YYYY-MM-DD'),
    'ends_on',   to_char(se.ends_on,'YYYY-MM-DD'),
    'rows', v_rows, 'recipients', v_to);
end $$;
revoke all on function public.season_email_payload(uuid) from public, anon, authenticated;
grant execute on function public.season_email_payload(uuid) to service_role;

-- ---- one-click unsubscribe (THE SEVENTH ANON ENDPOINT — D68) ---------------
-- Fail-closed and strictly one-way: an unguessable token can only ever turn
-- the flag OFF. It cannot enumerate, read, or re-enable anything, and it
-- answers identically whether or not the token existed.
create or replace function public.email_unsubscribe(p_token uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if p_token is null then return true; end if;
  update email_prefs set recap = false, updated_at = now()
   where token = p_token and recap;
  return true;                      -- always the same answer, nothing to probe
end $$;
revoke all on function public.email_unsubscribe(uuid) from public;
grant execute on function public.email_unsubscribe(uuid) to anon, authenticated;

-- ---- the in-app toggle (read with no argument, write with one) -------------
create or replace function public.set_email_recap(p_on boolean default null)
returns boolean
language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); v_now boolean;
begin
  if v is null then raise exception 'Sign in first'; end if;
  insert into email_prefs (profile_id) values (v) on conflict (profile_id) do nothing;
  if p_on is not null then
    update email_prefs set recap = p_on, updated_at = now() where profile_id = v;
  end if;
  select recap into v_now from email_prefs where profile_id = v;
  return coalesce(v_now, true);
end $$;
revoke all on function public.set_email_recap(boolean) from public, anon;
grant execute on function public.set_email_recap(boolean) to authenticated;

-- ---- the sender marks its own work done ------------------------------------
create or replace function public.mark_email_sent(p_id uuid, p_error text default null)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update email_queue set sent_at = now(), error = p_error where id = p_id;
end $$;
revoke all on function public.mark_email_sent(uuid, text) from public, anon, authenticated;
grant execute on function public.mark_email_sent(uuid, text) to service_role;
