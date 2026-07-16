-- ============================================================================
-- Cup Season — the storyteller voice (memory layer M1 · decision-log batch 4)
--
-- The moment engine already writes ONE ephemeral headline per round (barrier >
-- PB > streak). Its voice was scoreboard ALL-CAPS, and the PB line literally
-- posted "DIFF 5.2 (WAS 6.1)" — the number-soup jargon D2 killed everywhere
-- else. This is a pure VOICE pass: dry, knowing, clubhouse-toned, no jargon.
--
-- create-or-replace of round_moments() — the DETECTION is byte-for-byte the
-- migration 20260716020000 version (barriers, achievements, PB, streak all
-- unchanged); only the three ephemeral headline strings and the name casing
-- change. Achievement LABELS (the pinned trophy-card words) are untouched.
--
-- No client bump: moment posts render through easeCaps(), which passes
-- mixed-case bodies through verbatim (see the landmine note in CLAUDE.md). So
-- a mixed-case headline displays exactly as written. Pure-migration change.
-- ============================================================================
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

  -- name kept in the golfer's own casing (headline is mixed-case now); the
  -- sentence-start capital is applied to the whole line just before posting,
  -- so "JT" / "McDonald" survive intact but "jerecho" opens as "Jerecho".
  select coalesce(display_name, 'Someone') into v_name
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

  -- ---- one ephemeral headline (barrier > PB > streak), clubhouse voice ----
  -- No differential/index jargon on the board (D2): the PB line speaks plainly.
  if v_barrier is not null then
    v_moment := v_name || ' broke ' || v_barrier || ' for the first time — a '
             || new.gross || '. That one goes on the wall.';
  elsif v_prior_best is not null and new.differential < v_prior_best then
    v_moment := v_name || ' set a personal best. New number to chase.';
  elsif v_first_week and v_streak >= 4 and v_streak % 4 = 0 then
    v_moment := v_name || ' has posted ' || v_streak
             || ' weeks running. Iron man doesn''t take weeks off.';
  end if;

  if v_moment is null then return new; end if;

  -- sentence-start capital on the whole line (preserves internal name casing)
  v_moment := upper(left(v_moment, 1)) || substr(v_moment, 2);

  insert into posts (league_id, season_id, kind, member_id, body)
  select lm.league_id, s.id, 'moment', lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  return new;
end $$;
