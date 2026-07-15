-- ============================================================================
-- Cup Season — events engine, checkpoint 5: ACHIEVEMENTS / the trophy case
--
-- A moment and an achievement are the SAME event with two lifespans: the board
-- post (ckpt 1) scrolls away in a day; the achievement pins to your card
-- forever, across seasons. So the detection stays single-sourced — round_moments()
-- already finds barriers / personal bests / streaks; here it ALSO writes them to
-- an achievements table. Pure "Memory > Statistics" (vision doc): the profile is
-- the permanent home for "every round I've ever played."
--
-- v1 catalog (round-triggered — reuses ckpt-1 detection):
--   first_round · sub_100 / sub_90 / sub_80 (career-first, each once) ·
--   personal_best (evolves to your latest low) · streak_4 / _8 / _12
-- Season-level hardware (league won, Points King, month/season champion) comes
-- off the close_month / close_season chain — a later checkpoint.
--
-- ONE-TIME BACKFILL so the live pilot opens the case to their REAL history, not
-- an empty shelf: earliest round → first_round; earliest sub-100/90/80 → barrier;
-- best differential → personal_best. Streaks are forward-only (historical streak
-- reconstruction isn't worth the complexity for v1).
-- ============================================================================

create table if not exists public.achievements (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  kind       text not null,
  label      text not null,
  earned_on  date not null default current_date,
  round_id   uuid references public.rounds(id) on delete set null,   -- the receipt
  meta       jsonb not null default '{}',
  created_at timestamptz not null default now(),
  unique (profile_id, kind)          -- each career trophy earned once
);
-- read only through my_achievements() (security-definer); trigger writes bypass RLS
alter table public.achievements enable row level security;

create or replace function public.my_achievements()
returns table (kind text, label text, earned_on date, meta jsonb)
language sql stable security definer set search_path = public as $$
  select kind, label, earned_on, meta
    from achievements
   where profile_id = auth.uid()
   order by earned_on desc, kind;
$$;
grant execute on function public.my_achievements() to authenticated;

-- ---- one-time backfill from existing history ------------------------------
insert into achievements (profile_id, kind, label, earned_on, round_id)
select distinct on (r.profile_id) r.profile_id, 'first_round', 'First round posted',
       r.played_on, r.id
  from rounds r
 where not r.voided and coalesce(r.source, 'app') <> 'sim'
 order by r.profile_id, r.played_on, r.id
on conflict (profile_id, kind) do nothing;

insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
select distinct on (r.profile_id, thr.t) r.profile_id, 'sub_' || thr.t, 'Broke ' || thr.t,
       r.played_on, r.id, jsonb_build_object('gross', r.gross)
  from rounds r
  cross join unnest(array[100, 90, 80]) as thr(t)
 where not r.voided and r.holes_played = 18 and r.gross is not null
   and r.gross < thr.t and coalesce(r.source, 'app') <> 'sim'
 order by r.profile_id, thr.t, r.played_on, r.id
on conflict (profile_id, kind) do nothing;

insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
select distinct on (r.profile_id) r.profile_id, 'personal_best', 'Personal best',
       r.played_on, r.id, jsonb_build_object('diff', r.differential)
  from rounds r
 where not r.voided and r.differential is not null and coalesce(r.source, 'app') <> 'sim'
 order by r.profile_id, r.differential asc, r.played_on desc, r.id
on conflict (profile_id, kind) do nothing;

-- ---- recreate round_moments(): ckpt-1 posts + achievement writes -----------
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

  insert into posts (league_id, season_id, kind, member_id, body)
  select lm.league_id, s.id, 'moment', lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  return new;
end $$;
