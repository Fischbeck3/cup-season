-- ============================================================================
-- Cup Season — pilot feedback batch A: integrity fixes (2026-07-22)
--
-- 1. Moment posts cascade with their round. round_moments() stamped round_id
--    on the DURABLE achievements rows but not on the ephemeral 'moment' board
--    posts — so deleting a round left "X SET A PERSONAL BEST" standing in the
--    home feed (pilot: "I deleted a round and it remains here on this week").
--    The posts insert now carries new.id; posts.round_id already has
--    ON DELETE CASCADE (baseline). The trophy row keeps ON DELETE SET NULL on
--    purpose: hardware survives, the receipt link dies.
--    Client pairs with this: the home moments query switched from
--    round_id-is-null to kind-based filtering, so stamped moments still show.
--
-- 2. Live rounds get a lifecycle. Nothing ever closed a 'setup'/'live'
--    live_rounds row unless someone finished or scrapped it — a buddy's round
--    stayed "open to join" 9½ hours after he walked off the course (pilot).
--    daily_season_tick() now sweeps rows older than 24h to 'abandoned' (the
--    vocabulary 20260717050000 added). A golf round is hours, not days.
-- ============================================================================

-- ---- 1. round_moments(): the ephemeral headline now rides the round --------
create or replace function public.round_moments() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v            uuid := new.profile_id;
  v_name       text;
  v_prior_best numeric;
  v_barrier    int  := null;
  v_streak     int  := 0;
  v_first_week boolean := false;
  v_is_first   boolean := false;
  v_thr        int;
  v_moment     text := null;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  select upper(coalesce(display_name, 'A GOLFER')) into v_name
    from profiles where id = v;

  -- 1) career barrier (18-hole gross): lowest threshold crossed for the headline
  if new.holes_played = 18 and new.gross is not null then
    if new.gross < 80 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 80
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 80;
    elsif new.gross < 90 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 90
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 90;
    elsif new.gross < 100 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 100
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 100;
    end if;
  end if;

  -- 2) personal-best differential (vs every prior round)
  select min(differential) into v_prior_best
    from rounds where profile_id = v and id <> new.id
      and not voided and differential is not null
      and coalesce(source,'app') <> 'sim';

  -- 3) iron-man streak — only when this is the first post of its week
  select count(*) = 0 into v_first_week
    from rounds where profile_id = v and id <> new.id and not voided
      and date_trunc('week', played_on) = date_trunc('week', new.played_on);
  if v_first_week then
    with wks as (
      select distinct date_trunc('week', played_on)::date w
        from rounds
       where profile_id = v and not voided and played_on <= new.played_on
    ), grp as (
      select w, w - (row_number() over (order by w) * interval '7 day') as g
        from wks
    )
    select count(*) into v_streak
      from grp
     where g = (select g from grp order by w desc limit 1);
  end if;

  -- ---- persistent achievements (same detection, permanent home) ----
  v_is_first := not exists (
    select 1 from rounds where profile_id = v and id <> new.id
      and not voided and coalesce(source,'app') <> 'sim');
  if v_is_first then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'first_round', 'First round posted', new.played_on, new.id,
            jsonb_build_object('gross', new.gross))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- barriers for the case: award EVERY threshold newly crossed (not just the headline)
  if new.holes_played = 18 and new.gross is not null then
    foreach v_thr in array array[100, 90, 80] loop
      if new.gross < v_thr and not exists (
        select 1 from rounds where profile_id = v and id <> new.id
          and not voided and holes_played = 18 and gross < v_thr
          and coalesce(source,'app') <> 'sim') then
        insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
        values (v, 'sub_' || v_thr, 'Broke ' || v_thr, new.played_on, new.id,
                jsonb_build_object('gross', new.gross))
        on conflict (profile_id, kind) do nothing;
      end if;
    end loop;
  end if;

  if v_prior_best is not null and new.differential < v_prior_best then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'personal_best', 'Personal best', new.played_on, new.id,
            jsonb_build_object('diff', new.differential))
    on conflict (profile_id, kind) do update
      set earned_on = excluded.earned_on, round_id = excluded.round_id, meta = excluded.meta;
  end if;

  if v_first_week and v_streak in (4, 8, 12) then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'streak_' || v_streak, v_streak || '-week streak', new.played_on, new.id,
            jsonb_build_object('weeks', v_streak))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- ---- one ephemeral headline (barrier > PB > streak) ----
  if v_barrier is not null then
    v_moment := v_name || ' BROKE ' || v_barrier
             || ' FOR THE FIRST TIME — ' || new.gross || ' GROSS';
  elsif v_prior_best is not null and new.differential < v_prior_best then
    v_moment := v_name || ' SET A PERSONAL BEST — DIFF ' || new.differential
             || ' (WAS ' || v_prior_best || ')';
  elsif v_first_week and v_streak >= 4 and v_streak % 4 = 0 then
    v_moment := v_name || ' — ' || v_streak || ' STRAIGHT WEEKS. IRON MAN';
  end if;

  if v_moment is null then return new; end if;

  -- round_id rides the post: delete the round, the headline goes with it
  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'moment', new.id, lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  return new;
end $$;

revoke all on function public.round_moments() from public, anon, authenticated;

-- ---- 2. daily_season_tick(): + the live-round sweep ------------------------
create or replace function public.daily_season_tick() returns void
language plpgsql security definer set search_path = public as $$
declare se record; v_finish text;
begin
  -- live rounds die on their own now: 24h after start, an unfinished round is
  -- abandoned — resume and join surfaces go dark server-side, not just client.
  update live_rounds
     set status = 'abandoned', finished_at = coalesce(finished_at, now())
   where status in ('setup', 'live')
     and started_at < now() - interval '24 hours';

  for se in select * from seasons where status in ('active','cup_final')
  loop
    select finish into v_finish from league_settings where league_id = se.league_id;
    if se.status = 'active' and coalesce(v_finish,'cup_final') = 'cup_final'
       and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;
  end loop;
end $$;

revoke all on function public.daily_season_tick() from public, anon, authenticated;
