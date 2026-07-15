-- ============================================================================
-- Cup Season — events engine, checkpoint 1: LIVE MOMENTS (round-triggered)
--
-- "Opening Cup Season should reveal something new" (Principle 5). When a real
-- round posts, detect the moment it made and fan a 'moment' board post to
-- every active-season league the golfer belongs to — riding the existing
-- board + realtime + push rails (no new plumbing). Detectors are pure
-- functions of the poster's OWN history, so zero false positives:
--
--   • Career barrier  — first-ever 18-hole gross under 100 / 90 / 80. The
--       lowest newly-crossed threshold is the headline ("BROKE 80 …"). This is
--       the vision doc's canonical memory ("I finally broke 80").
--   • Personal best   — new low differential vs every prior round (needs a
--       prior round; a first-ever post is not a "PB").
--   • Iron-man streak — consecutive weeks with a posted round, announced only
--       at 4-week milestones (4/8/12…) and only on the first post of the week,
--       so it never spams.
--
-- ONE headline per round (barriers > PB > streak) — a round is one story, not
-- a pile of badges. Real rounds only (sim rounds never crow). Definitions match
-- home_feed()'s is_pr / is_sub80 flags so the welcome feed and the board agree.
--
-- Lead-change moments ("X moved into first") are deliberately NOT here: doing
-- them correctly needs a before/after leader comparison (a season_lead state
-- row), which is checkpoint 2 — better than a guessed heuristic that cries wolf.
--
-- The push webhook already fires on posts INSERT; kind='moment' isn't 'chat',
-- so it pushes to every league-mate except the author (member_id excludes them).
-- ============================================================================

-- widen the kind constraint (was chat/round/system/announce)
alter table public.posts drop constraint posts_kind_check;
alter table public.posts add constraint posts_kind_check
  check (kind = any (array['chat'::text, 'round'::text, 'system'::text,
                           'announce'::text, 'moment'::text]));

create or replace function public.round_moments() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v            uuid := new.profile_id;
  v_name       text;
  v_prior_best numeric;
  v_barrier    int  := null;    -- lowest newly-crossed gross threshold
  v_streak     int  := 0;
  v_first_week boolean := false;
  v_moment     text := null;
begin
  -- real, scoring, non-sim rounds only
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  select upper(coalesce(display_name, 'A GOLFER')) into v_name
    from profiles where id = v;

  -- 1) career barrier (18-hole gross): lowest threshold crossed for the first time
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

  -- one headline: milestone barrier > personal best > streak
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

  insert into posts (league_id, season_id, kind, member_id, body)
  select lm.league_id, s.id, 'moment', lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  return new;
end $$;

drop trigger if exists trg_round_moments on public.rounds;
create trigger trg_round_moments
  after insert on public.rounds
  for each row execute function public.round_moments();
