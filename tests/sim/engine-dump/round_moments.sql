CREATE OR REPLACE FUNCTION public.round_moments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  v_prior_n    integer := 0;
  v_last_on    date;
  v_gap        integer;
  v_miss       numeric;
  v_n          int := 0;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  select firstname(coalesce(display_name, 'A golfer')) into v_name
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

  -- ---- the return, and the bad day (D166) ----
  select count(*), max(played_on) into v_prior_n, v_last_on
    from rounds
   where profile_id = v and id <> new.id and not voided
     and coalesce(source,'app') <> 'sim' and played_on <= new.played_on;
  v_gap  := case when v_last_on is null then null else new.played_on - v_last_on end;
  v_miss := new.differential - new.index_at_post;

  -- ---- one ephemeral headline (barrier > PB > return > streak > bad day) ----
  if v_barrier is not null then
    v_moment := v_name || ' broke ' || v_barrier
             || ' for the first time — '
             || case when new.gross between 80 and 89 then 'an ' else 'a ' end
             || new.gross || '. That one goes on the wall.';
  elsif v_prior_best is not null and new.differential < v_prior_best then
    v_moment := v_name || ' set a personal best. New number to chase.';
  elsif v_gap >= 42 and v_prior_n >= 3 then
    -- a return, not a debut: there is history here, and a real gap in it
    v_moment := 'First round since '
             || case when v_gap >= 300 then to_char(v_last_on, 'FMMonth YYYY')
                     else to_char(v_last_on, 'FMMonth') end
             || ' for ' || v_name || '. Welcome back.';
  elsif v_first_week and v_streak >= 4 and v_streak % 4 = 0 then
    v_moment := v_name || ' has posted ' || v_streak
             || ' weeks running. The streak holds.';
  elsif v_miss >= 6 and v_prior_n >= 5 and new.holes_played = 18
        and coalesce(new.index_source_at_post, 'app') = 'app'
        and not exists (
          select 1 from posts p2 join rounds r2 on r2.id = p2.round_id
           where r2.profile_id = v and p2.kind = 'moment'
             and p2.created_at > now() - interval '60 days'
             and p2.body like 'Not the day %') then
    -- the observation, never the verdict. Four guards, and every one of them
    -- exists so this can never land on someone who does not deserve it:
    --   · 5+ prior rounds — a beginner is never the subject
    --   · index_source 'app' — their number is one the app DERIVED from their
    --     own scores, not a starter index they guessed at signup (the critic's
    --     catch: a beginner who typed 12 and shot a 20 differential would trip
    --     this on their first ever posted round)
    --   · 18 holes, so a nine is never judged as a full round
    --   · once per 60 days, so it can never become a drumbeat
    -- Every warmer headline outranks it: a return or a streak wins instead.
    v_moment := 'Not the day ' || v_name || ' had in mind. '
             || 'We''ll leave that one on the scorecard.';
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

  get diagnostics v_n = row_count;

  -- D238 · the second rail. A milestone with no live season used to be
  -- detected, written into `achievements`, and then have nowhere to be SAID.
  -- It is now homed on the golfer it is about. Only on zero — never both.
  if v_n = 0 then
    insert into posts (profile_id, kind, round_id, body)
    values (v, 'moment', new.id, v_moment);
  end if;

  return new;
end $function$

