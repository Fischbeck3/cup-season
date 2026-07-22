-- ============================================================================
-- Cup Season — the sandbox league (D65): a season in an hour
--
-- The owner needs to walk a WHOLE league lifecycle (create → draw → weeks of
-- posting → month closes → cup final → crowning) without recruiting eight
-- humans and waiting three months. The sandbox is real mechanics, fake people:
--   · bots are real auth users on an unroutable domain (@sandbox.cupseason.test,
--     empty password, never sent an OTP — unloginable by construction),
--     non-discoverable, members of the sandbox league ONLY. Their rounds ride
--     the exact production path: direct insert → score_round fills the index
--     snapshot + differential → round_to_board fans the story → the WHS-lite
--     engine (round_refresh_index) evolves their index round by round.
--   · time moves with sandbox_rewind: both season dates slide back together
--     (length preserved), so "week 7" simply IS in the past and the cup-final
--     window / season end arrive through the same daily-tick law as any league.
--   · the founder drives the machinery; the sandbox Pro is a SEPARATE
--     throwaway account. The founder's real profile never posts here — a
--     round fans into EVERY league its profile belongs to (v_rounds_ranked
--     joins by membership + date), so a real member posting backdated sandbox
--     rounds would score them into their real leagues. The fence is social,
--     not schema: single-league profiles cannot leak.
--
-- Fences (all four RPCs): caller must be the founder (profiles.is_founder),
-- and every function except arm refuses a league not flagged sandbox. Arm
-- refuses a league that already has more members than its commissioner —
-- a real league can never be armed. Scrap deletes the league graph and the
-- bot users; it never touches a league without the flag.
--
-- Deliberately NOT in tests/db-checks.sql check 3: that list is the CLIENT's
-- RPC surface, and these are console-driven founder tools. Check 3 fails only
-- on missing grants, so the omission is safe (D65 logs the reasoning).
-- ============================================================================

alter table public.leagues add column if not exists sandbox boolean not null default false;

-- ---- shared gate ------------------------------------------------------------
create or replace function public.assert_sandbox(p_league uuid, p_need_flag boolean)
returns void
language plpgsql stable security definer set search_path = public as $$
declare v_founder boolean; v_sandbox boolean;
begin
  select is_founder into v_founder from profiles where id = auth.uid();
  if v_founder is not true then raise exception 'founder only'; end if;
  select sandbox into v_sandbox from leagues where id = p_league;
  if v_sandbox is null then raise exception 'league not found'; end if;
  if p_need_flag and not v_sandbox then
    raise exception 'not a sandbox league — arm it first';
  end if;
end $$;

-- ---- arm: flag the league, mint the bots ------------------------------------
create or replace function public.sandbox_arm(p_league uuid, p_bots integer default 7)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_names  text[] := array['Sandy Wedge','Chip Draw','Bo Gie','Woody Longiron',
                           'Iron Mikey','Rusty Putter','Mully Gunn','Skip Divot'];
  v_marks  text[] := array['shark','dunes','lonetree','lighthouse',
                           'island','pews','beer','saguaro'];
  v_skill  numeric[] := array[4.2,7.8,9.5,11.3,13.6,16.1,18.4,20.7];
  v_others integer;
  v_uid    uuid;
  v_email  text;
  v_made   jsonb := '[]'::jsonb;
  i        integer;
begin
  perform assert_sandbox(p_league, false);
  if p_bots < 1 or p_bots > 8 then raise exception '1 to 8 bots'; end if;

  -- a real league can never be armed: nobody here but the commissioner
  select count(*) into v_others
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.league_id = p_league
     and p.email not like '%@sandbox.cupseason.test'
     and lm.role <> 'commissioner';
  if v_others > 0 then
    raise exception 'this league has real members — sandbox refuses';
  end if;

  update leagues set sandbox = true where id = p_league;

  for i in 1..p_bots loop
    v_email := 'bot' || i || '-' || left(p_league::text, 8) || '@sandbox.cupseason.test';
    select id into v_uid from auth.users where email = v_email;

    if v_uid is null then
      v_uid := gen_random_uuid();
      -- minimal, never-loginable auth row; the m001 trigger mints the profile
      insert into auth.users
        (instance_id, id, aud, role, email, encrypted_password,
         email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
         created_at, updated_at,
         confirmation_token, recovery_token, email_change_token_new, email_change)
      values
        ('00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
         v_email, '', now(),
         '{"provider":"email","providers":["email"]}'::jsonb,
         jsonb_build_object('display_name', v_names[i]),
         now(), now(), '', '', '', '');
      update profiles
         set marker = v_marks[i], index_current = v_skill[i],
             index_source = 'self', discoverable = 'nobody', city = 'Tempe, AZ'
       where id = v_uid;
    end if;

    insert into league_members (league_id, profile_id, role, index_current, index_source)
    values (p_league, v_uid, 'player', v_skill[i], 'self')
    on conflict do nothing;

    v_made := v_made || jsonb_build_object('name', v_names[i], 'index', v_skill[i]);
  end loop;

  return jsonb_build_object('armed', true, 'bots', v_made);
exception when insufficient_privilege then
  raise exception 'auth.users insert denied by role — run sandbox_arm once from the dashboard SQL editor';
end $$;

-- ---- rewind: the time dial --------------------------------------------------
-- After rewind(w): w whole weeks are in the past, today is week w+1's first
-- day. Season LENGTH is preserved, so the cup-final window (ends_on − 27) and
-- season end (ends_on + grace) arrive naturally as w grows. Forward only —
-- dial deeper to reach the cup, deeper still to reach the crowning.
create or replace function public.sandbox_rewind(p_league uuid, p_weeks integer)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare se seasons%rowtype; v_len integer;
begin
  perform assert_sandbox(p_league, true);
  if p_weeks < 1 or p_weeks > 52 then raise exception '1 to 52 weeks'; end if;
  select * into se from seasons where league_id = p_league
   order by number desc limit 1;
  if se.id is null then raise exception 'no season yet — lock the league first'; end if;

  v_len := se.ends_on - se.starts_on;
  update seasons
     set starts_on = current_date - (p_weeks * 7),
         ends_on   = (current_date - (p_weeks * 7)) + v_len
   where id = se.id;

  return jsonb_build_object(
    'week_now', p_weeks + 1,
    'starts_on', current_date - (p_weeks * 7),
    'ends_on', (current_date - (p_weeks * 7)) + v_len,
    'cup_window_opens', (current_date - (p_weeks * 7)) + v_len - 27);
end $$;

-- ---- week: the bots play the next empty week --------------------------------
create or replace function public.sandbox_week(p_league uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  se seasons%rowtype;
  v_week integer; v_start date; v_day date;
  b record; v_diff numeric; v_gross integer; v_n integer := 0;
  v_rating numeric; v_slope integer; v_course text; v_pick integer;
begin
  perform assert_sandbox(p_league, true);
  select * into se from seasons where league_id = p_league
   and status in ('active','cup_final') order by number desc limit 1;
  if se.id is null then raise exception 'no active season'; end if;

  -- next sequential week with no bot rounds yet (0-based)
  select coalesce(max(floor((r.played_on - se.starts_on) / 7)) + 1, 0)::integer
    into v_week
    from rounds r
    join profiles p on p.id = r.profile_id
   where p.email like '%@sandbox.cupseason.test'
     and r.played_on between se.starts_on and se.ends_on
     and r.profile_id in (select profile_id from league_members where league_id = p_league);

  v_start := se.starts_on + (v_week * 7);
  if v_start > current_date then
    raise exception 'the bots are caught up — rewind deeper or play on';
  end if;

  for b in
    select lm.profile_id, coalesce(p.index_current, lm.index_current, 15) as idx,
           row_number() over (order by lm.joined_at) as rn
      from league_members lm join profiles p on p.id = lm.profile_id
     where lm.league_id = p_league
       and p.email like '%@sandbox.cupseason.test'
  loop
    -- ~80% play a given week; the first three always do (guaranteed progress)
    continue when b.rn > 3 and random() > 0.8;

    v_pick := 1 + floor(random() * 5)::integer;
    select c.label, c.rating, c.slope into v_course, v_rating, v_slope
      from (values ('Papago Golf Club', 72.1, 128), ('Encanto 18', 68.9, 117),
                   ('Aguila Golf Course', 71.4, 124), ('Dobson Ranch GC', 70.2, 121),
                   ('Grayhawk — Talon', 73.4, 135)) as c(label, rating, slope)
     offset (v_pick - 1) limit 1;

    -- a differential near the bot's number, ±3.5 both ways
    v_diff  := greatest(-3, b.idx + (random() * 7 - 3.5));
    v_gross := greatest(61, least(140, round(v_rating + v_diff * v_slope / 113.0)::integer));
    v_day   := least(v_start + ((b.rn * 2 + v_week) % 7), current_date);

    insert into rounds (profile_id, gross, rating, slope, course_label,
                        played_on, holes_played, source)
    values (b.profile_id, v_gross, v_rating, v_slope, v_course, v_day, 18, 'quick');
    v_n := v_n + 1;
  end loop;

  return jsonb_build_object('week', v_week + 1, 'rounds_posted', v_n,
                            'week_of', v_start);
end $$;

-- ---- advance: month closes + the daily tick, on demand ----------------------
create or replace function public.sandbox_advance(p_league uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  se seasons%rowtype; m date; v_closed integer := 0; v_status text;
begin
  perform assert_sandbox(p_league, true);
  select * into se from seasons where league_id = p_league
   order by number desc limit 1;
  if se.id is null then raise exception 'no season yet'; end if;

  -- close every fully-elapsed month (close_month is sentinel-idempotent)
  m := date_trunc('month', se.starts_on)::date;
  while m <= se.ends_on and (m + interval '1 month')::date - 1 < current_date loop
    perform close_month(se.id, m);
    v_closed := v_closed + 1;
    m := (m + interval '1 month')::date;
  end loop;

  perform snapshot_week(se.id);      -- on-conflict-do-nothing inside
  perform daily_season_tick();       -- the same law every league lives under

  select status into v_status from seasons where id = se.id;
  return jsonb_build_object('months_touched', v_closed, 'season_status', v_status);
end $$;

-- ---- scrap: the whole diorama goes in the bin -------------------------------
create or replace function public.sandbox_scrap(p_league uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_bots uuid[]; v_n integer;
begin
  perform assert_sandbox(p_league, true);

  select coalesce(array_agg(p.id), '{}') into v_bots
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.league_id = p_league
     and p.email like '%@sandbox.cupseason.test';

  -- league graph first (posts/seasons/members cascade from leagues) — this
  -- clears every no-action member_id reference before the users go
  delete from leagues where id = p_league;
  -- then the bots: auth.users → profiles cascade takes their rounds with them
  delete from auth.users where id = any(v_bots);
  get diagnostics v_n = row_count;

  return jsonb_build_object('scrapped', true, 'bots_removed', v_n);
end $$;

-- ---- grants: founder-gated inside, authenticated at the door (D37) ----------
revoke all on function public.assert_sandbox(uuid, boolean) from public, anon, authenticated;
revoke all on function public.sandbox_arm(uuid, integer)    from public, anon;
revoke all on function public.sandbox_rewind(uuid, integer) from public, anon;
revoke all on function public.sandbox_week(uuid)            from public, anon;
revoke all on function public.sandbox_advance(uuid)         from public, anon;
revoke all on function public.sandbox_scrap(uuid)           from public, anon;
grant execute on function public.sandbox_arm(uuid, integer)    to authenticated;
grant execute on function public.sandbox_rewind(uuid, integer) to authenticated;
grant execute on function public.sandbox_week(uuid)            to authenticated;
grant execute on function public.sandbox_advance(uuid)         to authenticated;
grant execute on function public.sandbox_scrap(uuid)           to authenticated;
