-- ============================================================================
-- Cup Season — deep-dive fixes, money batch (audit b7: findings #4/#16, #7)
--
-- #4/#16  award_season_trophies split a squad's champion/runner share with
--         INTEGER division ((c_cents / n_champ)), truncating and dropping up to
--         n-1 pennies. The recorded season_payouts then undershot the pot AND
--         disagreed with the ceremony, which splits with csSplitCents (the
--         earliest seats absorb the remainder). Money between friends must sum
--         exactly. Distribute the remainder pennies to the earliest seats,
--         mirroring the ceremony, so the recorded rows sum to c_cents / r_cents.
--
-- #7      career_record.seasons_done counted EVERY complete season in every
--         league the profile belongs to — so "Settled across N seasons" under
--         the earnings total overcounted (a golfer who earned in 1 of 3 seasons
--         read "across 3"). Count only seasons that actually PAID this profile.
--
-- Recomputing historical payouts is safe here: the top-level champ/runner/king
-- split (c_cents = pot - r_cents - k_cents) is unchanged, so totals are
-- identical; only the per-seat cents shift by at most a penny to close the gap.
-- ============================================================================

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
    -- champion absorbs the champ/runner/king rounding so the three sum to pot
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

    -- #4/#16: the per-seat split rides the remainder to the earliest seats
    -- (row_number order), exactly like csSplitCents, so the rows sum to c_cents.
    if n_champ > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, q.profile_id,
             (c_cents / n_champ) + case when q.rn <= (c_cents % n_champ) then 1 else 0 end,
             'Cup champion'
        from (
          select pid as profile_id, row_number() over (order by pid) as rn
            from (select lm.profile_id as pid from squad_members sm join league_members lm on lm.id = sm.member_id
                   where sm.squad_id = se.champion_squad_id
                  union all
                  select lm.profile_id from league_members lm
                   where se.champion_squad_id is null and lm.id = se.champion_member_id) m
        ) q
      on conflict do nothing;
    end if;
    if n_run > 0 then
      insert into season_payouts (season_id, profile_id, cents, reason)
      select p_season, q.profile_id,
             (r_cents / n_run) + case when q.rn <= (r_cents % n_run) then 1 else 0 end,
             'Runner-up'
        from (
          select pid as profile_id, row_number() over (order by pid) as rn
            from (select lm.profile_id as pid from squad_members sm join league_members lm on lm.id = sm.member_id
                   where sm.squad_id = se.runnerup_squad_id
                  union all
                  select lm.profile_id from league_members lm
                   where se.runnerup_squad_id is null and lm.id = se.runnerup_member_id) m
        ) q
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

-- ---- #7: "settled across N seasons" counts only seasons that PAID you -------
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
    -- #7: the denominator under the earnings total is the count of seasons that
    -- actually paid this profile — not every complete season they were in.
    'seasons_done',   (select count(distinct season_id) from season_payouts where profile_id = v),
    'leagues',        (select count(*) from league_members where profile_id = v));
end $$;

revoke all on function public.career_record() from public, anon;
grant execute on function public.career_record() to authenticated;
