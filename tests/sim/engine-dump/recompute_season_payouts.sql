-- recompute_season_payouts(p_season uuid) oid=21525
CREATE OR REPLACE FUNCTION public.recompute_season_payouts(p_season uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record;
  n_members int; pot_c bigint; col_c bigint;
  c_cents int; r_cents int; k_cents int; n_champ int; n_run int;
  v_owed jsonb;
begin
  select * into se from seasons where id = p_season;
  if not found then return null; end if;
  select * into st from league_settings where league_id = se.league_id;

  select count(*) into n_members from league_members where league_id = se.league_id;
  pot_c := coalesce(st.buyin_cents, 0)::bigint * n_members;
  select coalesce(sum(b.amount_cents), 0) into col_c
    from buy_ins b
    join league_members lm on lm.id = b.member_id and lm.league_id = se.league_id
   where b.season_id = p_season and b.paid;
  col_c := least(col_c, pot_c);            -- a stale amount can't collect more than the roster owes

  -- who still owes: every roster member without a paid buy-in for this season
  select coalesce(jsonb_agg(jsonb_build_object(
           'member_id', lm.id,
           'name', coalesce(p.display_name, 'A golfer'),
           'cents', coalesce(st.buyin_cents, 0)) order by p.display_name), '[]'::jsonb)
    into v_owed
    from league_members lm
    join profiles p on p.id = lm.profile_id
   where lm.league_id = se.league_id
     and coalesce(st.buyin_cents, 0) > 0
     and not exists (select 1 from buy_ins b where b.season_id = p_season and b.member_id = lm.id and b.paid);

  -- the ledger is rewritten from scratch every time: idempotent, and a late
  -- payment simply produces a bigger split (D106 §4)
  delete from season_payouts where season_id = p_season;

  if se.status = 'complete' and col_c > 0 then
    -- champion absorbs the champ/runner/king rounding so the three sum to collected
    r_cents := round(col_c * coalesce(st.payout_runnerup, 25) / 100.0);
    k_cents := round(col_c * coalesce(st.payout_king, 15) / 100.0);
    c_cents := greatest(0, col_c::int - r_cents - k_cents);

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

    -- the per-seat split rides the remainder to the earliest seats (row_number
    -- order), exactly like csSplitCents, so the rows sum to c_cents / r_cents
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

  update seasons set pot_cents = pot_c, collected_cents = col_c where id = p_season;

  return jsonb_build_object(
    'pot_cents', pot_c, 'collected_cents', col_c,
    'champ_cents', coalesce(c_cents, 0), 'runner_cents', coalesce(r_cents, 0), 'king_cents', coalesce(k_cents, 0),
    'still_owed', v_owed);
end $function$

