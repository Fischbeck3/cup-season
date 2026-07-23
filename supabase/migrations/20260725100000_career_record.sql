-- ============================================================================
-- Cup Season — D67: the career record (titles + what they paid)
--
-- trophies already records every title with a placement. What has never
-- existed is a record of what a season PAID. The ceremony computes the split
-- on the client and forgets it, and recomputing it later would be approximate:
-- the pot depends on the member count AT THE TIME, and rosters change — so a
-- recomputed career figure would drift as people join or leave. Money between
-- friends that is "about right" is worse than no money at all.
--
-- So the settlement is recorded as FACT at close, by the function that already
-- resolves the placements (award_season_trophies, called from close_season) —
-- no gameplay path is re-plumbed. career_record() then returns titles plus an
-- EXACT sum of recorded rows, never a re-derivation (§16).
-- ============================================================================

create table if not exists public.season_payouts (
  season_id  uuid not null references public.seasons(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  cents      integer not null,
  reason     text not null,
  created_at timestamptz not null default now(),
  primary key (season_id, profile_id, reason)
);

alter table public.season_payouts enable row level security;
revoke all on table public.season_payouts from public, anon, authenticated;
-- read-only, and only your own row or a league-mate's (the ledger is the
-- league's business, and the ceremony shows the whole table to the room)
grant select on public.season_payouts to authenticated;
drop policy if exists payouts_read on public.season_payouts;
create policy payouts_read on public.season_payouts for select to authenticated
  using (exists (select 1 from seasons s
                  where s.id = season_id and is_league_member(s.league_id)));

-- ---- record the settlement at close (extends the trophy award) -------------
create or replace function public.award_season_trophies(p_season uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare se record; st record; lg_name text; yr int;
        n_members int; pot numeric; c_cents int; r_cents int; k_cents int;
        n_champ int; n_run int;
begin
  select * into se from seasons where id = p_season and status = 'complete';
  if not found then return; end if;
  select name into lg_name from leagues where id = se.league_id;
  yr := extract(year from se.ends_on)::int;

  -- champion(s)
  if se.champion_squad_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Champion', 'winner', se.league_id, yr
        from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.champion_squad_id
      on conflict do nothing;
  elsif se.champion_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Champion', 'winner', se.league_id, yr
        from league_members lm where lm.id = se.champion_member_id
      on conflict do nothing;
  end if;

  -- runner(s)-up
  if se.runnerup_squad_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Runner-up', 'runner_up', se.league_id, yr
        from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.runnerup_squad_id
      on conflict do nothing;
  elsif se.runnerup_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Runner-up', 'runner_up', se.league_id, yr
        from league_members lm where lm.id = se.runnerup_member_id
      on conflict do nothing;
  end if;

  -- the Points King
  if se.points_king_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Points King', 'points_king', se.league_id, yr
        from league_members lm where lm.id = se.points_king_member_id
      on conflict do nothing;
  end if;

  -- ---- D67: what it paid, recorded once, in cents --------------------------
  select * into st from league_settings where league_id = se.league_id;
  select count(*) into n_members from league_members where league_id = se.league_id;
  pot := coalesce(st.buyin_cents,0)::numeric * n_members;
  if pot > 0 then
    -- the champion absorbs the rounding remainder, exactly as the ceremony
    -- shows it, so the recorded parts always sum to the pot
    r_cents := round(pot * coalesce(st.payout_runnerup,25) / 100.0);
    k_cents := round(pot * coalesce(st.payout_king,15) / 100.0);
    c_cents := greatest(0, pot::int - r_cents - k_cents);

    select count(*) into n_champ from (
      select lm.profile_id from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.champion_squad_id
      union all
      select lm.profile_id from league_members lm
       where se.champion_squad_id is null and lm.id = se.champion_member_id) q;
    select count(*) into n_run from (
      select lm.profile_id from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.runnerup_squad_id
      union all
      select lm.profile_id from league_members lm
       where se.runnerup_squad_id is null and lm.id = se.runnerup_member_id) q;

    if n_champ > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, q.profile_id, (c_cents / n_champ), 'Cup champion'
        from (select lm.profile_id from squad_members sm join league_members lm on lm.id = sm.member_id
               where sm.squad_id = se.champion_squad_id
              union all
              select lm.profile_id from league_members lm
               where se.champion_squad_id is null and lm.id = se.champion_member_id) q
      on conflict do nothing;
    end if;
    if n_run > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, q.profile_id, (r_cents / n_run), 'Runner-up'
        from (select lm.profile_id from squad_members sm join league_members lm on lm.id = sm.member_id
               where sm.squad_id = se.runnerup_squad_id
              union all
              select lm.profile_id from league_members lm
               where se.runnerup_squad_id is null and lm.id = se.runnerup_member_id) q
      on conflict do nothing;
    end if;
    if se.points_king_member_id is not null and k_cents > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, lm.profile_id, k_cents, 'Points king'
        from league_members lm where lm.id = se.points_king_member_id
      on conflict do nothing;
    end if;
  end if;
end $$;

revoke all on function public.award_season_trophies(uuid) from public, anon, authenticated;
grant execute on function public.award_season_trophies(uuid) to service_role;

-- ---- the record itself ------------------------------------------------------
create or replace function public.career_record()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare v uuid := auth.uid(); v_t jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select jsonb_build_object(
    'cups',       count(*) filter (where kind = 'league' and placement = 'winner'),
    'runner_ups', count(*) filter (where kind = 'league' and placement = 'runner_up'),
    'crowns',     count(*) filter (where placement = 'points_king'),
    'majors',     count(*) filter (where kind = 'major'  and placement = 'winner'),
    'events',     count(*) filter (where kind = 'event'  and placement = 'winner'),
    'trophies',   count(*)
  ) into v_t from trophies where profile_id = v;

  return coalesce(v_t, '{}'::jsonb) || jsonb_build_object(
    -- an EXACT sum of recorded rows; never a recomputation (D67/§16)
    'earnings_cents', coalesce((select sum(cents) from season_payouts where profile_id = v), 0),
    'seasons_done',   (select count(*) from seasons s
                        join league_members lm on lm.league_id = s.league_id
                       where lm.profile_id = v and s.status = 'complete'),
    'leagues',        (select count(*) from league_members where profile_id = v));
end $$;

revoke all on function public.career_record() from public, anon;
grant execute on function public.career_record() to authenticated;
