-- Cup Season — a first round is a baseline (X39, D399).
--
-- Owner ruling in chat, 2026-09-29 (X39: option 2 + option 3's PB rule), D399.
-- HELD for the owner's db push. Nothing here is client-called; no payload
-- changes shape, so either deploy order is safe.
--
-- WHAT A DEBUT SAID. A golfer's first round of 85 minted First round posted,
-- Broke 100 and Broke 90 together (right: option 2 keeps every threshold
-- earnable, and both clients fold a first round's milestones into FIRST
-- ROUND). But `round_moments` also posted the board's headline "Devon broke
-- 90 for the first time — an 85. That one goes on the wall." on a round with
-- nothing before it to break. There was no "first time": it was the first
-- round. And `rederive_achievements`, which runs after every round delete,
-- awarded Personal best to a lone round, while the trigger it re-derives for
-- has always required a prior round (the July backfill did the same; it was a
-- one-off insert in 20260716020000, not a function, so nothing callable is
-- left to fix).
--
-- TWO CHANGES, BOTH create or replace, each body the latest verbatim:
--   1 · round_moments (latest 20260921090000): the barrier headline needs a
--       prior round — the same `v_is_first` test that mints first_round. The
--       achievement rows are untouched. A debut posts no moment; its story on
--       the board is the round's own post from round_to_board.
--   2 · rederive_achievements (latest 20260902173000): Personal best needs an
--       earlier round and must beat every earlier one — the trigger's rule.
--
-- Grants restated as the latest source left them: round_moments is a trigger
-- function (revoked from public, anon); rederive_achievements is revoked from
-- public, anon, authenticated. `trg_round_moments` (20260715234500) is kept by
-- create or replace. Idempotent: applying this file twice is clean.

-- ------------------------------------------------ 1 · the debut's headline
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
  -- X39 · D399 · a first round is a baseline, not "the first time". Every
  -- threshold it crosses is still minted above (each stays earnable, and the
  -- clients fold them into FIRST ROUND); only the board's claim is withheld.
  -- v_is_first is the test that mints first_round, so the headline and the
  -- trophy case agree on which round is the debut. Nothing else fires on a
  -- real first round (PB needs a prior differential, the return three prior
  -- rounds, the streak four posted weeks, the bad day five rounds), so a debut
  -- posts no moment: its story on the board is the round's own post.
  if v_barrier is not null and not v_is_first then
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
;


revoke all on function public.round_moments() from public, anon;

-- ------------------------------------------ 2 · a personal best needs a past
create or replace function public.rederive_achievements(p_profile uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
begin
  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select r.profile_id, 'first_round', 'First round posted', r.played_on, r.id,
         jsonb_build_object('gross', r.gross)
    from rounds r
   where r.profile_id = p_profile
     and not r.voided and coalesce(r.source, 'app') <> 'sim'
   order by r.played_on, r.id
   limit 1
  on conflict (profile_id, kind) do nothing;

  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select distinct on (thr.t) r.profile_id, 'sub_' || thr.t, 'Broke ' || thr.t,
         r.played_on, r.id, jsonb_build_object('gross', r.gross)
    from rounds r
    cross join unnest(array[100, 90, 80]) as thr(t)
   where r.profile_id = p_profile
     and not r.voided and r.holes_played = 18 and r.gross is not null
     and r.gross < thr.t and coalesce(r.source, 'app') <> 'sim'
   order by thr.t, r.played_on, r.id
  on conflict (profile_id, kind) do nothing;

  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select r.profile_id, 'personal_best', 'Personal best',
         r.played_on, r.id, jsonb_build_object('diff', r.differential)
    from rounds r
   where r.profile_id = p_profile
     and not r.voided and r.differential is not null and coalesce(r.source, 'app') <> 'sim'
     -- X39 · D399 · the trigger's rule: a personal best needs a prior round
     -- and beats every one of them (strictly, as `round_moments` does). "Prior"
     -- is the order this function already uses for first_round (played_on,
     -- then id), so a lone round, or a first round nothing later beat, is
     -- never a personal best. What is left is the forward path's last record.
     and exists (
       select 1 from rounds e
        where e.profile_id = r.profile_id and e.id <> r.id
          and not e.voided and e.differential is not null
          and coalesce(e.source, 'app') <> 'sim'
          and (e.played_on, e.id) < (r.played_on, r.id))
     and not exists (
       select 1 from rounds e
        where e.profile_id = r.profile_id and e.id <> r.id
          and not e.voided and e.differential is not null
          and coalesce(e.source, 'app') <> 'sim'
          and (e.played_on, e.id) < (r.played_on, r.id)
          and e.differential <= r.differential)
   order by r.differential asc, r.played_on desc, r.id
   limit 1
  on conflict (profile_id, kind) do nothing;
end $function$;


revoke all on function public.rederive_achievements(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------- 3 · self-check
-- Reads only. Raises if either rule is missing from what is now installed.
do $x39$
declare v_src text;
begin
  select prosrc into v_src from pg_proc where oid = 'public.round_moments()'::regprocedure;
  if strpos(v_src, 'if v_barrier is not null and not v_is_first then') = 0 then
    raise exception '[X39] round_moments still headlines a barrier on a first round';
  end if;
  if strpos(v_src, 'on conflict (profile_id, kind) do nothing') = 0
     or strpos(v_src, '''sub_'' || v_thr') = 0 then
    raise exception '[X39] round_moments lost the barrier achievements';
  end if;
  select prosrc into v_src from pg_proc where oid = 'public.rederive_achievements(uuid)'::regprocedure;
  if strpos(v_src, 'and e.differential <= r.differential') = 0 then
    raise exception '[X39] rederive_achievements still awards a personal best with no prior round';
  end if;
  if not exists (select 1 from pg_trigger
                  where tgname = 'trg_round_moments' and tgrelid = 'public.rounds'::regclass
                    and not tgisinternal) then
    raise exception '[X39] trg_round_moments is not on rounds';
  end if;
end $x39$;
