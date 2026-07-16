-- ============================================================================
-- Cup Season — the post-round peak (memory layer M2 · decision-log D17)
--
-- Two pieces, both "the poster hears it first":
--
--   1. round_epilogue(p_round) — a gather RPC for the private epilogue sheet
--      shown to the poster right after they post, BEFORE they land on the board.
--      Returns, in one call: the round's points/band context under its season
--      lens, the achievements THIS round just earned (read by round_id — the
--      trigger wrote them synchronously on the insert), and the live rivalry
--      records for opponents who also posted this week (the "you're now 4–3 up
--      on Jake" beat). Read-only, security-definer, guarded to the owner.
--      Reuses my_rivalries() as the single source of the head-to-head record.
--
--   2. squad_lead_moments() — the comeback/collapse tag (#23). A lead change is
--      the standing flip; the moment now NAMES the deposed squad and speaks the
--      M1 clubhouse voice (mixed-case → passes easeCaps untouched) instead of
--      the flat "MUDSHARKS MOVED INTO FIRST". Detection/state logic byte-
--      identical to 20260716000000 — only the announced string changes.
--
-- Deploy skew: the client wraps the round_epilogue call in try/catch and simply
-- skips the sheet if the function isn't deployed yet — never blocks a post.
-- ============================================================================

-- 1) the epilogue gather ------------------------------------------------------
create or replace function public.round_epilogue(p_round uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_prof   uuid;
  v_played date;
  v_gross  int;
  v_holes  int;
  v_season uuid;
  v_pvi    numeric := null;
  v_points int     := null;
  v_rank   int     := null;
  v_earned jsonb   := '[]'::jsonb;
  v_rivals jsonb   := '[]'::jsonb;
begin
  select profile_id, played_on, gross, holes_played, season_id
    into v_prof, v_played, v_gross, v_holes, v_season
    from rounds where id = p_round;

  -- only the round's owner gets its epilogue
  if v_prof is null or v_prof <> auth.uid() then
    return null;
  end if;

  -- points + band under the round's own season lens (null for a league-less post)
  if v_season is not null then
    select pvi, points, month_rank
      into v_pvi, v_points, v_rank
      from v_rounds_ranked
     where round_id = p_round and season_id = v_season
     limit 1;
  end if;

  -- achievements THIS exact round earned (PB / broke 80·90·100 / streak / first)
  select coalesce(jsonb_agg(
           jsonb_build_object('kind', kind, 'label', label)
           order by case kind
             when 'personal_best' then 0 when 'sub_80' then 1
             when 'sub_90' then 2 when 'sub_100' then 3
             when 'first_round' then 4 else 5 end), '[]'::jsonb)
    into v_earned
    from achievements
   where profile_id = v_prof and round_id = p_round;

  -- rivalries live THIS week: opponents who also posted this week in a shared
  -- season, with the current lifetime record. my_rivalries() owns the record
  -- definition; we filter it to the opponents this round actually clashed with.
  select coalesce(jsonb_agg(
           jsonb_build_object('name', mr.display_name, 'handle', mr.handle,
             'wins', mr.wins, 'losses', mr.losses, 'ties', mr.ties, 'lead', mr.lead)
           order by mr.meetings desc), '[]'::jsonb)
    into v_rivals
    from my_rivalries() mr
   where exists (
     select 1
       from v_rounds_ranked rr
       join league_members lm1 on lm1.profile_id = v_prof
       join league_members lm2 on lm2.league_id = lm1.league_id
                              and lm2.profile_id = mr.opponent
      where rr.profile_id = mr.opponent
        and rr.member_id  = lm2.id
        and date_trunc('week', rr.played_on) = date_trunc('week', v_played)
   );

  return jsonb_build_object(
    'gross', v_gross, 'holes', v_holes,
    'pvi', v_pvi, 'points', v_points, 'month_rank', v_rank,
    'earned', v_earned, 'rivals', v_rivals
  );
end $$;

grant execute on function public.round_epilogue(uuid) to authenticated;

-- 2) comeback/collapse tag on the lead-change moment --------------------------
create or replace function public.squad_lead_moments() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  r            record;
  v_leader     uuid;
  v_leader_pts numeric;
  v_second_pts numeric;
  v_prior      uuid;
  v_lname      text;
  v_pname      text;
  v_moment     text;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  for r in
    select s.id as season_id, s.league_id
      from league_members lm
      join seasons s on s.league_id = lm.league_id
                    and s.status in ('active', 'cup_final')
                    and new.played_on between s.starts_on and s.ends_on
     where lm.profile_id = new.profile_id
  loop
    select squad_id, points into v_leader, v_leader_pts
      from v_squad_standings
     where season_id = r.season_id
     order by points desc, squad_id
     limit 1;
    if v_leader is null then continue; end if;

    select points into v_second_pts
      from v_squad_standings
     where season_id = r.season_id and squad_id <> v_leader
     order by points desc
     limit 1;

    -- a real, sole leader (nobody tied at the top)
    if v_second_pts is not null and v_leader_pts <= v_second_pts then
      continue;
    end if;

    select squad_id into v_prior from season_lead where season_id = r.season_id;

    if v_prior is null then
      -- first-ever strict leader: record silently, never announce
      insert into season_lead (season_id, squad_id) values (r.season_id, v_leader)
        on conflict (season_id) do update set squad_id = excluded.squad_id, since = now();
      continue;
    end if;

    if v_leader <> v_prior then
      -- the standing flipped: name both sides, clubhouse voice (mixed-case so
      -- it rides easeCaps untouched, per M1)
      select name into v_lname from squads where id = v_leader;
      select name into v_pname from squads where id = v_prior;
      v_moment := coalesce(v_lname, 'A squad') || ' just snatched first from '
               || coalesce(v_pname, 'the field') || '.';
      v_moment := upper(left(v_moment, 1)) || substr(v_moment, 2);
      insert into posts (league_id, season_id, kind, member_id, body)
      values (r.league_id, r.season_id, 'moment', null, v_moment);
      update season_lead set squad_id = v_leader, since = now()
       where season_id = r.season_id;
    end if;
  end loop;

  return new;
end $$;
