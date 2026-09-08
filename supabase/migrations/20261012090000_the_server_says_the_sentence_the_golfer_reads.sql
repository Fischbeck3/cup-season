-- ============================================================================
-- Cup Season — the server says the sentence the golfer reads (D296)
--
-- The voice review of 2026-09-07 read every user-facing string against
-- spec/voice-and-tone.md and kept 36 server findings (S-01 … S-37, S-24
-- killed). Every one of them sits in a function a migration has already run
-- in production, and CLAUDE.md rule 2 is that a migration is never edited
-- after it runs — so this is the one new file, and every function below is
-- its LIVE definition (pg_get_functiondef, the same way 20260831120000 was
-- built), re-emitted whole with only the sentence changed. Each body was
-- checked byte for byte against the newest migration that defines it before
-- a word was touched; nothing about a rule, a query, a guard or a grant moves.
--
-- Six patterns, by class rather than by line (the judge's ruling, §5):
--
--   4 · THE SHOUT. Three generators written after D165 re-shouted —
--       "GALEN NOW GOES BY …", "SEASON 2 IS ON. FIRST TEE …", "STAKE POSTED: …"
--       with upper() on the golfers' own names. Natural case at the generator,
--       and the pride bet is a forfeit, as the sheet that posts it is titled.
--   5 · THE MACHINE'S VOICE AT THE SOURCE. 'commissioner only' and
--       'organizer only' (twelve sites), 'index out of range', 'invalid league
--       code', 'crew only', 'not your league', 'nothing to vote on', 'no squads
--       — run form_squads first', 'name a rivalry only once it has history' —
--       lowercase raises that fail the web's own looksLikeOurSentence gate, so
--       the desk printed "Something went wrong" while the server had said the
--       reason, and the phone (which has no gate) printed the raw P0001. The
--       raise now says the golfer's sentence — the one the web's humanError
--       map was already substituting for 'commissioner only'.
--   3 · RULED WORDS PAST THEIR LINT. session → week · duel → clash · the tee
--       sheet / on the sheet → the schedule / in · league mate → a golfer in
--       your season · players / members → golfers · bylaws locked → the rules
--       are set · Exhibition / the clubhouse → doesn't count this year / the
--       lead · champs → champion · on the books (a plan) → on the schedule ·
--       counting rounds → rounds count · season bye → bye · Tour Card → gone.
--       Where prod carried the identical sentence in a function the readers
--       did not name — 'organizer only' in open_major and resolve_session,
--       'not your league' in set_league_marker, 'tagged players' in
--       set_round_rsvp, 'counting rounds' in close_season's last-place post —
--       it is fixed here too; the apply is by class.
--   6 · THE WINK WITHOUT ITS SCENE. "Tag up to seven — it is golf, not a
--       scramble league" is a validation; a validation is a field.
--   2 · THE SECOND TELLING. "… is in — the Pro added them. Welcome to the
--       league." says it twice; " · settle between yourselves" welded to the
--       pot line becomes the ledger sentence, whole, as brand-canon §3 asks
--       everywhere money appears.
--   And the one that was simply FALSE: "Members can only be removed during
--       setup — mid-season tools are coming" — suspend_member shipped on
--       2026-09-02 (20260902100000). "Season two starts when you say it does"
--       — false for any league past its second season.
--
-- WHAT THE CLIENTS OWE (D234, named so the twin lands): the web's humanError
-- allowlist (index.html ~5980) passes 'still in the pool' verbatim and will
-- need 'not on a squad yet' (S-11's sentence opens with a count, so the shape
-- gate alone will not pass it); the phone's HumanError (PeopleModels.swift
-- ~162) passes 'already in the league' and will need "already in" (S-30).
-- Everything else here either already passes both gates or is a board post.
--
-- GRANTS (D37, the landmine): every function carries its explicit revoke and
-- its grant, mirroring exactly what prod holds today — 41 are client-callable
-- and stay granted to authenticated; close_season, daily_season_tick,
-- round_major_story and sched_major_story are engine-only (cron / internal)
-- and stay OFF the API surface. The self-check at the foot raises if any of
-- the 45 gained an overload (preflight 34), lost or gained a grant, leaked to
-- anon, or still says a retired sentence.
--
-- Dry-run: wrap in begin; … rollback; and `supabase db query --linked --file`.
-- ============================================================================

begin;

-- ---- set_profile · S-01 -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_profile(p_name text, p_city text DEFAULT NULL::text, p_home text DEFAULT NULL::text, p_index numeric DEFAULT NULL::numeric, p_marker text DEFAULT NULL::text, p_ghin text DEFAULT NULL::text, p_photo_path text DEFAULT NULL::text, p_index_source text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_old text; v_src text := nullif(btrim(coalesce(p_index_source, '')), '');
begin
  -- the avatar path is own-prefix by law (mirrors the storage policy)
  if p_photo_path is not null and p_photo_path <> ''
     and p_photo_path !~ ('^' || auth.uid()::text || '/') then
    raise exception 'photo path must live under your own prefix';
  end if;

  -- R23's refusal, and it is the load-bearing half of this file. The sibling
  -- CHECKs admit self / app / ghin (`initial_baseline.sql:1065, :1267`).
  -- 'starter' is C-13 and C-13 is NOT in this migration, so a caller who sends
  -- it is told so plainly rather than having the value silently dropped —
  -- a silently ignored source is how a client comes to believe it wrote one.
  if v_src is not null and v_src not in ('self', 'app', 'ghin') then
    raise exception 'index_source must be self, app or ghin (a starter is client-side until D124 is reopened)';
  end if;

  select display_name into v_old from profiles where id = auth.uid();

  insert into profiles (id, email, display_name, city, home_course, index_current, marker, ghin_number, photo_path, index_source)
  values (
    auth.uid(),
    coalesce((select email from auth.users where id = auth.uid()), ''),
    p_name, p_city, p_home, p_index, p_marker,
    nullif(trim(coalesce(p_ghin,'')), ''), nullif(p_photo_path, ''), v_src)
  on conflict (id) do update set
    display_name  = coalesce(excluded.display_name,  profiles.display_name),
    city          = coalesce(excluded.city,          profiles.city),
    home_course   = coalesce(excluded.home_course,   profiles.home_course),
    index_current = coalesce(excluded.index_current, profiles.index_current),
    marker        = coalesce(excluded.marker,        profiles.marker),
    ghin_number   = case when p_ghin is null then profiles.ghin_number
                         else nullif(trim(p_ghin), '') end,
    photo_path    = case when p_photo_path is null then profiles.photo_path
                         else nullif(p_photo_path, '') end,
    index_source  = coalesce(v_src, profiles.index_source);

  if p_name is not null and v_old is not null and trim(p_name) <> v_old then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           v_old || ' now goes by ' || trim(p_name)
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $function$;
revoke all on function public.set_profile(p_name text, p_city text, p_home text, p_index numeric, p_marker text, p_ghin text, p_photo_path text, p_index_source text) from public, anon;
grant execute on function public.set_profile(p_name text, p_city text, p_home text, p_index numeric, p_marker text, p_ghin text, p_photo_path text, p_index_source text) to authenticated;

-- ---- run_it_back · S-02 S-33 --------------------------------------------------
CREATE OR REPLACE FUNCTION public.run_it_back(p_league uuid, p_starts_on date DEFAULT NULL::date, p_ends_on date DEFAULT NULL::date, p_buyin_cents integer DEFAULT NULL::integer, p_season_months integer DEFAULT NULL::integer, p_pay_note text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league    leagues%rowtype;
  v_settings  league_settings%rowtype;
  v_last      seasons%rowtype;
  v_open      seasons%rowtype;
  v_new       seasons%rowtype;
  v_starts    date;
  v_ends      date;
  v_months    int;
  v_buyin     int;
  v_note      text := nullif(btrim(coalesce(p_pay_note, '')), '');
  v_stake_moved  boolean;
  v_length_moved boolean;
  v_seated    int := 0;
  v_invited   int := 0;
  v_has_left  boolean;
  v_phase     text;
  v_changed   text;
begin
  select * into v_league from leagues where id = p_league;
  if not found then raise exception 'That league no longer exists.'; end if;

  -- D243's second half: a member who taps this must never become a founder.
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro can run it back.';
  end if;

  select * into v_settings from league_settings where league_id = p_league;
  if not found then raise exception 'That league never started a season.'; end if;

  -- IDEMPOTENT. A double tap, or a retry after a dropped response, must not
  -- mint a second season — so an already-open season is the answer, not an
  -- error, and the client renders the same screen either way.
  select * into v_open from seasons
   where league_id = p_league and status <> 'complete'
   order by number desc limit 1;
  if found then
    return json_build_object(
      'already_running', true,
      'league_id', p_league,
      'season', row_to_json(v_open),
      'seated', (select count(*) from league_members where league_id = p_league),
      'invited', 0,
      'covenant_refires', false);
  end if;

  select * into v_last from seasons
   where league_id = p_league
   order by number desc limit 1;
  if not found then
    raise exception 'This league has no season to run back yet.';
  end if;

  -- the window
  v_starts := coalesce(p_starts_on, greatest(current_date, v_last.ends_on + 1));
  v_months := greatest(1, least(12, coalesce(p_season_months, v_settings.season_months, 6)));
  v_ends   := coalesce(p_ends_on, v_starts + (v_months * 30.44)::int - 1);
  if v_ends <= v_starts then raise exception 'A season ends after it starts.'; end if;
  -- the stored figure is the one the window actually describes, exactly as
  -- lock_league derives it, so the two cannot disagree about "how long"
  v_months := greatest(1, least(12, round((v_ends - v_starts + 1) / 30.44::numeric)::int));
  v_buyin  := coalesce(p_buyin_cents, v_settings.buyin_cents, 0);

  v_stake_moved  := v_buyin is distinct from coalesce(v_settings.buyin_cents, 0);
  v_length_moved := v_months is distinct from v_settings.season_months;

  update league_settings
     set buyin_cents   = v_buyin,
         season_months = v_months,
         -- coalesce, never clobber: a Pro who sends no note keeps the one
         -- set_buy_in_terms recorded (R18's own rule)
         buy_in_note   = coalesce(v_note, buy_in_note),
         -- a new season opens its roster again; D161's window is per season
         roster_closed_at = null
   where league_id = p_league
  returning * into v_settings;

  insert into seasons (league_id, number, starts_on, ends_on)
  values (p_league, v_last.number + 1, v_starts, v_ends)
  returning * into v_new;

  if v_settings.structure <> 'solo' then
    perform form_squads(v_new.id);
  end if;
  v_phase := case when v_settings.structure = 'solo' then 'season' else 'draft' end;
  update leagues set phase = v_phase where id = p_league;

  -- THE ROSTER. "Re-seating" is a count, not an insert: a member of the league
  -- is a member of its next season by construction. What matters is who is
  -- LIVING — D244's `left_at` (forward-only) and a suspension both stand.
  select exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'league_members' and column_name = 'left_at'
  ) into v_has_left;

  if v_has_left then
    execute 'select count(*) from league_members where league_id = $1 and left_at is null and suspended_at is null'
      into v_seated using p_league;
  else
    select count(*) into v_seated
      from league_members where league_id = p_league and suspended_at is null;
  end if;

  -- THE COVENANT FIRES AGAIN (L-12) when the terms moved.
  if v_stake_moved or v_length_moved then
    -- refresh a settled invite back to pending, then insert for anybody with
    -- none; `member_invites_league_uq` is what makes both halves safe
    update member_invites
       set status = 'pending', invited_by = auth.uid(), created_at = now()
     where league_id = p_league
       and status <> 'pending'
       and profile_id in (
         select lm.profile_id from league_members lm
          where lm.league_id = p_league and lm.suspended_at is null
            and lm.profile_id <> v_league.commissioner_id);

    insert into member_invites (league_id, profile_id, invited_by)
    select p_league, lm.profile_id, auth.uid()
      from league_members lm
     where lm.league_id = p_league
       and lm.suspended_at is null
       and lm.profile_id <> v_league.commissioner_id
       and not exists (select 1 from member_invites mi
                        where mi.league_id = p_league and mi.profile_id = lm.profile_id)
    on conflict do nothing;

    get diagnostics v_invited = row_count;
  end if;

  v_changed := case
    when v_stake_moved and v_length_moved then ' The stake and the length changed — everyone reads the terms again.'
    when v_stake_moved  then ' The stake changed — everyone reads the terms again.'
    when v_length_moved then ' The length changed — everyone reads the terms again.'
    else '' end;

  insert into posts (league_id, season_id, kind, body)
  values (p_league, v_new.id, 'system',
          'Season ' || v_new.number || ' is on. First tee '
          || to_char(v_new.starts_on, 'Dy Mon FMDD') || ' · '
          || case when coalesce(v_settings.counting_cap, 0) > 0
                  then 'best ' || v_settings.counting_cap || ' a month.'
                  else 'every round counts.' end
          || v_changed);

  return json_build_object(
    'already_running', false,
    'league_id',       p_league,
    'season',          row_to_json(v_new),
    'seated',          v_seated,
    'invited',         coalesce(v_invited, 0),
    'covenant_refires', (v_stake_moved or v_length_moved),
    'stake_moved',     v_stake_moved,
    'length_moved',    v_length_moved);
end $function$;
revoke all on function public.run_it_back(p_league uuid, p_starts_on date, p_ends_on date, p_buyin_cents integer, p_season_months integer, p_pay_note text) from public, anon;
grant execute on function public.run_it_back(p_league uuid, p_starts_on date, p_ends_on date, p_buyin_cents integer, p_season_months integer, p_pay_note text) to authenticated;

-- ---- create_forfeit · S-03 S-30 -----------------------------------------------
CREATE OR REPLACE FUNCTION public.create_forfeit(p_league uuid, p_name text, p_terms text, p_kind text DEFAULT 'custom'::text, p_other uuid DEFAULT NULL::uuid, p_hangs text DEFAULT NULL::text, p_event uuid DEFAULT NULL::uuid, p_round uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_name text; v_terms text; v_a text; v_b text; v_homes int;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;

  v_homes := (case when p_league is not null then 1 else 0 end)
           + (case when p_event  is not null then 1 else 0 end)
           + (case when p_round  is not null then 1 else 0 end);
  if v_homes > 1 then raise exception 'A forfeit hangs on one thing'; end if;
  if v_homes = 0 and p_other is null then
    raise exception 'Say who it is with, or what it hangs on';
  end if;

  -- "a shared season, a shared moment, a shared plan, or accepted buddies"
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'Only the crew can post a forfeit here.';
  end if;
  if p_event is not null and not is_event_member(p_event) then
    raise exception 'You have to be in it to put something on it';
  end if;
  if p_round is not null and not exists (
       select 1 from scheduled_rounds sr
        where sr.id = p_round
          and (sr.profile_id = auth.uid() or auth.uid() = any(sr.tagged))) then
    raise exception 'You have to be on the round to put something on it';
  end if;

  v_name  := nullif(trim(coalesce(p_name,'')),'');
  v_terms := nullif(trim(coalesce(p_terms,'')),'');
  if v_name is null or v_terms is null then
    raise exception 'A stake needs a name and terms';
  end if;
  if coalesce(p_kind,'custom') not in ('hosts','course_pick','strokes','bounty','custom') then
    raise exception 'unknown stake kind';
  end if;
  if p_other is not null then
    if p_other = auth.uid() then raise exception 'You can''t stake against yourself'; end if;
    if p_league is not null then
      if not exists (select 1 from league_members
                      where league_id = p_league and profile_id = p_other) then
        raise exception 'The other side has to be in the crew';
      end if;
    elsif p_event is not null then
      if not exists (select 1 from event_players
                      where event_id = p_event and profile_id = p_other) then
        raise exception 'The other side has to be in it';
      end if;
    elsif p_round is not null then
      if not exists (select 1 from scheduled_rounds sr
                      where sr.id = p_round
                        and (sr.profile_id = p_other or p_other = any(sr.tagged))) then
        raise exception 'The other side has to be on the round';
      end if;
    else
      -- no container at all: buddies only, the same consent rule an RSVP uses (D69)
      if not exists (select 1 from friendships f
                      where f.status = 'accepted'
                        and ((f.requester = auth.uid() and f.addressee = p_other)
                          or (f.addressee = auth.uid() and f.requester = p_other))) then
        raise exception 'Forfeits are between buddies. Add them first';
      end if;
    end if;
  end if;

  insert into forfeits (league_id, event_id, scheduled_round_id, name, terms, kind,
                        party_a, party_b, hangs_on, created_by)
  values (p_league, p_event, p_round, left(v_name,60), left(v_terms,200),
          coalesce(p_kind,'custom'), auth.uid(), p_other,
          nullif(trim(coalesce(p_hangs,'')),''), auth.uid())
  returning id into v_id;

  -- The board post is written only where there IS a board. A forfeit between
  -- two buddies with no season tells nobody but the two of them (L-22).
  if p_league is not null then
    select display_name into v_a from profiles where id = auth.uid();
    select display_name into v_b from profiles where id = p_other;
    insert into posts (league_id, kind, body)
    values (p_league, 'system',
      'Forfeit posted: ' || v_name
      || case when v_b is not null then ' — ' || v_a || ' v ' || v_b
              else ' — ' || v_a || ' v the field' end
      || ' · ' || v_terms);
  end if;
  return v_id;
end $function$;
revoke all on function public.create_forfeit(p_league uuid, p_name text, p_terms text, p_kind text, p_other uuid, p_hangs text, p_event uuid, p_round uuid) from public, anon;
grant execute on function public.create_forfeit(p_league uuid, p_name text, p_terms text, p_kind text, p_other uuid, p_hangs text, p_event uuid, p_round uuid) to authenticated;

-- ---- close_season · S-04 S-05 S-26 (+S-28 by class) ---------------------------
CREATE OR REPLACE FUNCTION public.close_season(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; king uuid;
  v_solo boolean; v_finalists boolean; v_cup boolean;
  cap_n integer; cf_start date;
  c1 record; c2 record;
  k1 record; k2 record; v_king_rung text := null;
  v_rung text := null; v_story text; v_score1 text; v_score2 text;
  v_kname text; v_champname text; v_runname text;
  v_money jsonb; v_owed_names text; v_pot_line text;
  v_last record; v_lastname text; v_field integer;
begin
  select * into se from seasons where id = p_season;
  if se.status = 'complete' then return; end if;              -- idempotent
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (st.structure = 'solo');
  cap_n := coalesce(st.counting_cap, 10000);
  cf_start := se.ends_on - 27;
  v_finalists := exists (select 1 from cup_finalists where season_id = p_season);
  v_cup := coalesce(st.finish,'cup_final') = 'cup_final' and v_finalists;

  drop table if exists _cont; drop table if exists _ranked; drop table if exists _king;
  create temp table _cont (
    cid uuid, member_id uuid, head numeric default 0
  ) on commit drop;

  if v_cup then
    if v_solo then
      insert into _cont select cf.member_id, cf.member_id, coalesce(cf.head_start,0)
        from cup_finalists cf where cf.season_id = p_season and cf.member_id is not null;
    else
      insert into _cont select cf.squad_id, sm.member_id, coalesce(cf.head_start,0)
        from cup_finalists cf
        join squad_members sm on sm.squad_id = cf.squad_id
       where cf.season_id = p_season and cf.squad_id is not null;
    end if;
  else
    if v_solo then
      insert into _cont select ist.member_id, ist.member_id, 0
        from v_individual_standings ist where ist.season_id = p_season;
    else
      insert into _cont select sm.squad_id, sm.member_id, 0
        from squads s join squad_members sm on sm.squad_id = s.id
       where s.season_id = p_season;
    end if;
  end if;

  create temp table _ranked (
    cid uuid, score numeric, months_won int, best_month numeric,
    rounds_used int, coin double precision
  ) on commit drop;
  insert into _ranked
  with pts as (
    -- D105: in the Final the window score is the SHARED helper — the same rows
    -- cup_final_race() shows the room, so the crown and the race cannot drift.
    select c.cid, max(c.head) + coalesce(sum(w.points), 0) as score
      from _cont c
      left join _cup_window_rounds(p_season) w on w.member_id = c.member_id
     where v_cup
     group by c.cid
    union all
    select c.cid,
           max(c.head) + coalesce(sum(rr.points) filter (where rr.month_rank <= cap_n), 0) as score
      from _cont c
      left join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
     where not v_cup
     group by c.cid
  ),
  months as (
    select c.cid, date_trunc('month', rr.played_on)::date as mon,
           sum(rr.points) as mpts
      from _cont c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n
     group by 1, 2
  ),
  months_won as (
    select m.cid, count(*) as won
      from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.cid <> m.cid), -1)
     group by m.cid
  ),
  best_month as (
    select cid, max(mpts) as best from months group by cid
  ),
  rounds_used as (
    select c.cid, count(rr.*) as used
      from _cont c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n
     group by c.cid
  )
  select p.cid, p.score,
         coalesce(w.won,0),
         coalesce(b.best,0),
         coalesce(u.used,0),
         random()
    from pts p
    left join months_won w on w.cid = p.cid
    left join best_month b on b.cid = p.cid
    left join rounds_used u on u.cid = p.cid;

  if not v_cup then
    if v_solo then
      update _ranked r set score = coalesce(
        (select i.points from v_individual_standings i
          where i.season_id = p_season and i.member_id = r.cid), 0);
    else
      update _ranked r set score = coalesce(
        (select s.points from v_squad_standings s
          where s.season_id = p_season and s.squad_id = r.cid), 0);
    end if;
  end if;

  select * into c1 from _ranked
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   limit 1;
  select * into c2 from _ranked
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   offset 1 limit 1;

  if c2.cid is not null and c1.score = c2.score then
    if c1.months_won <> c2.months_won then v_rung := 'months won';
    elsif c1.best_month <> c2.best_month then v_rung := 'best single month';
    elsif c1.rounds_used <> c2.rounds_used then v_rung := 'fewest rounds used';
    else v_rung := 'coin flip'; end if;
  end if;

  -- D212 / D126 (5) · the Points King on the same ladder, over every member
  -- of the season: season points (the standings' own number) · months won ·
  -- best single month · fewest rounds used · coin. The rung that decided a
  -- level top two is stored like tiebreak_rung.
  create temp table _king (
    member_id uuid, score numeric, months_won int, best_month numeric,
    rounds_used int, coin double precision
  ) on commit drop;
  insert into _king
  with base as (
    select ist.member_id, coalesce(ist.points, 0)::numeric as score
      from v_individual_standings ist where ist.season_id = p_season
  ),
  months as (
    select rr.member_id, date_trunc('month', rr.played_on)::date as mon,
           sum(rr.points) as mpts
      from v_rounds_ranked rr
     where rr.season_id = p_season and rr.month_rank <= cap_n
     group by 1, 2
  ),
  months_won as (
    select m.member_id, count(*) as won
      from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.member_id <> m.member_id), -1)
     group by m.member_id
  ),
  best_month as (
    select member_id, max(mpts) as best from months group by member_id
  ),
  rounds_used as (
    select rr.member_id, count(*) as used
      from v_rounds_ranked rr
     where rr.season_id = p_season and rr.month_rank <= cap_n
     group by rr.member_id
  )
  select b.member_id, b.score,
         coalesce(w.won,0),
         coalesce(bm.best,0),
         coalesce(u.used,0),
         random()
    from base b
    left join months_won w  on w.member_id  = b.member_id
    left join best_month bm on bm.member_id = b.member_id
    left join rounds_used u on u.member_id  = b.member_id;

  select * into k1 from _king
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   limit 1;
  select * into k2 from _king
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   offset 1 limit 1;
  king := k1.member_id;
  if k2.member_id is not null and k1.score = k2.score then
    if k1.months_won <> k2.months_won then v_king_rung := 'months won';
    elsif k1.best_month <> k2.best_month then v_king_rung := 'best single month';
    elsif k1.rounds_used <> k2.rounds_used then v_king_rung := 'fewest rounds used';
    else v_king_rung := 'coin flip'; end if;
  end if;

  -- D66: the deciding numbers are STORED, not just narrated
  update seasons set status = 'complete',
    champion_squad_id  = case when not v_solo then c1.cid end,
    champion_member_id = case when v_solo then c1.cid end,
    runnerup_squad_id  = case when not v_solo then c2.cid end,
    runnerup_member_id = case when v_solo then c2.cid end,
    points_king_member_id = king,
    champion_score = c1.score,
    runnerup_score = c2.score,
    tiebreak_rung  = v_rung,
    king_rung      = v_king_rung
    where id = p_season;
  update leagues set phase = 'complete' where id = se.league_id;

  if v_solo then
    select coalesce(p.display_name,'The champion') into v_champname
      from league_members lm join profiles p on p.id = lm.profile_id where lm.id = c1.cid;
    select coalesce(p.display_name,'') into v_runname
      from league_members lm join profiles p on p.id = lm.profile_id where lm.id = c2.cid;
  else
    select name into v_champname from squads where id = c1.cid;
    select name into v_runname from squads where id = c2.cid;
  end if;
  select coalesce(p.display_name,'') into v_kname
    from league_members lm join profiles p on p.id = lm.profile_id where lm.id = king;
  -- (never trim(trailing '.0') — it eats real zeros: '210.0' -> '21')
  v_score1 := case when c1.score = floor(c1.score) then c1.score::int::text else round(c1.score,1)::text end;
  v_score2 := case when c2.cid is null then null
                   when c2.score = floor(c2.score) then c2.score::int::text
                   else round(c2.score,1)::text end;

  -- D66: natural case — proper nouns survive the client's easeCaps intact.
  -- D212: "months won" is the whole season, and the post says so; the King's
  -- rung prints the same way.
  v_story := 'Season complete: ' || coalesce(v_champname,'The champion')
    || case when v_solo then ' takes' else ' take' end
    || case when v_cup then ' the Cup Final' else ' the Cup' end
    || case when v_score2 is not null then ' ' || v_score1 || '–' || v_score2 else '' end
    || case when v_rung is not null then '. Tiebreak: '
              || case v_rung when 'months won' then 'months won this season' else v_rung end
            else '' end
    || case when v_kname <> '' then '. Points King: ' || v_kname
              || case when v_king_rung is not null then ' (tiebreak: '
                        || case v_king_rung when 'months won' then 'months won this season' else v_king_rung end
                        || ')'
                      else '' end
            else '' end
    || '.';
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_story);

  -- the trophies, and the money — split from what was COLLECTED (D106)
  perform award_season_trophies(p_season);

  -- the pot line: tracked, never held (§14.4 — the settlement is a post)
  select jsonb_build_object(
           'pot_cents', s.pot_cents, 'collected_cents', s.collected_cents,
           'champ',  coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Cup champion'), 0),
           'runner', coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Runner-up'), 0),
           'king',   coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Points king'), 0))
    into v_money from seasons s where s.id = p_season;
  if coalesce((v_money->>'pot_cents')::bigint, 0) > 0 then
    select string_agg(coalesce(p.display_name, 'A golfer'), ', ' order by p.display_name)
      into v_owed_names
      from league_members lm join profiles p on p.id = lm.profile_id
     where lm.league_id = se.league_id
       and not exists (select 1 from buy_ins b where b.season_id = p_season and b.member_id = lm.id and b.paid);
    v_pot_line := 'The pot: $' || round((v_money->>'pot_cents')::numeric / 100.0);
    if (v_money->>'collected_cents')::bigint < (v_money->>'pot_cents')::bigint then
      v_pot_line := v_pot_line || ' · collected $' || round((v_money->>'collected_cents')::numeric / 100.0);
    end if;
    v_pot_line := v_pot_line
      || ' — champion $'    || round((v_money->>'champ')::numeric  / 100.0)
      || ' · runner-up $'   || round((v_money->>'runner')::numeric / 100.0)
      || ' · points king $' || round((v_money->>'king')::numeric   / 100.0);
    if (v_money->>'collected_cents')::bigint < (v_money->>'pot_cents')::bigint then
      v_pot_line := v_pot_line || ' · still owed: $'
        || round(((v_money->>'pot_cents')::numeric - (v_money->>'collected_cents')::numeric) / 100.0)
        || coalesce(' (' || v_owed_names || ')', '');
    end if;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system', v_pot_line || '. Cup Season keeps the ledger; the money moves between friends.');
  end if;

  -- #23 · the field, completed. SEASON CLOSE ONLY — there is no mid-season
  -- last-place post anywhere, by design. It punches at nothing: the line is
  -- affectionate, and where the ledger shows they kept posting, it says so.
  select count(*) into v_field from _ranked;
  -- CRITIC B4 · in a Cup Final `_ranked` holds ONLY the finalists, so the
  -- bottom row is the FOURTH-BEST TEAM IN THE LEAGUE, not last place. Naming
  -- them would be the exact thing hard rule 4 forbids.
  if v_field >= 4 and not v_cup then
    select * into v_last from _ranked
     order by score asc, months_won asc, best_month asc, rounds_used desc, coin asc
     limit 1;
    if v_last.cid is not null and v_last.cid <> c1.cid
       and (c2.cid is null or v_last.cid <> c2.cid) then
      if v_solo then
        select coalesce(p.display_name, 'A golfer') into v_lastname
          from league_members lm join profiles p on p.id = lm.profile_id
         where lm.id = v_last.cid;
      else
        select name into v_lastname from squads where id = v_last.cid;
      end if;
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, p_season, 'system',
              'Someone had to complete the field. This season, '
              || coalesce(v_lastname, 'someone') || '.'
              || case when coalesce(v_last.rounds_used, 0) >= 4
                      then ' ' || v_last.rounds_used
                           || ' rounds that counted says they kept showing up.'
                      else '' end);
    end if;
  end if;
end $function$;
revoke all on function public.close_season(p_season uuid) from public, anon, authenticated;   -- engine-only: the tick and the story generators; service_role keeps it, as today

-- ---- mark_buy_in · S-26 -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_buy_in(p_season uuid, p_member uuid, p_paid boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league uuid;
  v_status text;
  v_stake  integer;
  v_name   text;
  v_paid_n integer;
  v_total  integer;
  v_money  jsonb;
begin
  select league_id, status into v_league, v_status from seasons where id = p_season;
  if v_league is null then raise exception 'No such season'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro marks buy-ins'; end if;
  if not exists (select 1 from league_members where id = p_member and league_id = v_league) then
    raise exception 'Not a member of this league';
  end if;

  select coalesce(buyin_cents, 0) into v_stake from league_settings where league_id = v_league;

  insert into buy_ins (season_id, member_id, amount_cents, paid, marked_by, marked_at)
  values (p_season, p_member, coalesce(v_stake, 0), p_paid, my_member_id(v_league), now())
  on conflict (season_id, member_id) do update
    set paid = excluded.paid,
        marked_by = excluded.marked_by,
        marked_at = excluded.marked_at;

  select coalesce(p.display_name, 'A member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  if v_status = 'complete' then
    -- D106 §4: the ledger is rewritten from the new collected total and the
    -- room is told — the ceremony re-renders from season_payouts
    v_money := recompute_season_payouts(p_season);
    if p_paid and coalesce((v_money->>'collected_cents')::bigint, 0) > 0 then
      insert into posts (league_id, season_id, kind, member_id, body)
      values (v_league, p_season, 'system', my_member_id(v_league),
              v_name || '''s buy-in came in after the final. Payouts updated: champion $'
              || round((v_money->>'champ_cents')::numeric / 100.0)
              || ' · runner-up $'   || round((v_money->>'runner_cents')::numeric / 100.0)
              || ' · points king $' || round((v_money->>'king_cents')::numeric / 100.0));
    end if;
    return;
  end if;

  if p_paid then
    select count(*) filter (where b.paid) into v_paid_n
      from buy_ins b where b.season_id = p_season;
    select count(*) into v_total from league_members where league_id = v_league;

    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, p_season, 'system', my_member_id(v_league),
            v_name || '''s buy-in is in — ' || v_paid_n || '/' || v_total || ' collected.');
  end if;
end $function$;
revoke all on function public.mark_buy_in(p_season uuid, p_member uuid, p_paid boolean) from public, anon;
grant execute on function public.mark_buy_in(p_season uuid, p_member uuid, p_paid boolean) to authenticated;

-- ---- home_dispatch · S-06 S-07 S-08 -------------------------------------------
CREATE OR REPLACE FUNCTION public.home_dispatch(p_days integer DEFAULT 21)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v          uuid := auth.uid();
  v_me       jsonb;
  v_today    date := current_date;
  v_items    jsonb := '[]'::jsonb;
  v_out      jsonb := '[]'::jsonb;
  v_days     int  := greatest(1, coalesce(p_days, 21));
  m          jsonb;       -- one membership
  st         jsonb;       -- its standing
  se         jsonb;       -- its season
  cl         jsonb;       -- its clash
  pu         jsonb;       -- its pulse
  bi         jsonb;       -- its buy_in
  e          jsonb;       -- a generic element
  v_nearest  uuid;        -- the league with the nearest dated thing (M11)
  v_best     date;
  v_lead_ix  int;
  v_rank     int := 0;
  v_sup      jsonb := '[]'::jsonb;
  v_friends  int := 0;
  v_rounds   int := 0;
  v_when_s   text;
begin
  if v is null then
    return jsonb_build_object('me', null, 'items', '[]'::jsonb, 'generated_at', now());
  end if;

  begin
    v_me := native_home();
  exception when others then
    v_me := null;
  end;
  if v_me is null then
    return jsonb_build_object('me', null, 'items', '[]'::jsonb, 'generated_at', now());
  end if;

  v_rounds  := coalesce((v_me #>> '{profile,rounds_count}')::int, 0);
  begin
    select count(*)::int into v_friends from friendships f
     where f.status = 'accepted' and (f.requester = v or f.addressee = v);
  exception when others then
    v_friends := 0;
  end;

  -- M11 · which season carries the nearest dated thing (its week's close,
  -- else its end). One pass, before any item is built.
  for m in select * from jsonb_array_elements(coalesce(v_me->'memberships', '[]'::jsonb)) loop
    se := m->'season';
    if se is not null and se <> 'null'::jsonb then
      v_when_s := coalesce(nullif(se->>'week_ends_on', ''), nullif(se->>'ends_on', ''));
      if v_when_s is not null then
        begin
          if v_best is null or v_when_s::date < v_best then
            v_best := v_when_s::date;
            v_nearest := (m->>'league_id')::uuid;
          end if;
        exception when others then null;
        end;
      end if;
    end if;
  end loop;

  -- =========================================================================
  -- BAND 1 · CLOSING — a clock I can still change
  -- =========================================================================

  -- my live round: the highest score the function can produce, and the one
  -- state where the lead is a place I am already standing in (S11).
  if (v_me->'live_round') is not null and (v_me->'live_round') <> 'null'::jsonb then
    e := v_me->'live_round';
    -- R-04 · TWO FACES. `native_home.live_round` is "a live round the caller
    -- is SEATED in", which includes a round somebody else started and I have
    -- never opened — where "You are on the card right now" and "the card is
    -- open" are both false, the host is unnamed and the verb JOIN is missing.
    -- LV-09 · and the noun: §2.1 splits "your card" (the person) from "your
    -- scorecard" (the holes). This is the holes.
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key',           'live:' || coalesce(e->>'id', ''),
      'tier',          'closing', 'band', 1000,
      'mods',          70, 'mod_reason', 'M1 30 (live) + M2 40 (me)',
      'subject',       case when (e->>'mine')::boolean is not false then 'you'
                            else coalesce(firstname(e->>'host'), 'a golfer') end,
      'human_subject', true,
      'eyebrow',       case when (e->>'mine')::boolean is not false
                            then upper(coalesce(nullif(e->>'course_label', ''), 'A round is live'))
                            else 'JUST TEED OFF · NOTHING SCORED YET' end,
      'headline',      case when (e->>'mine')::boolean is not false
                            then 'You’re in a live round right now.'
                            else coalesce(firstname(e->>'host'), 'Somebody')
                                   || ' started a live round with you.' end,
      'standfirst',    case when (e->>'mine')::boolean is not false
                            then case when nullif(e->>'league_name', '') is not null
                                      then e->>'league_name' || ' — the scorecard is open.' end
                            else coalesce(nullif(e->>'course_label', ''), nullif(e->>'league_name', '')) end,
      'action',        case when (e->>'mine')::boolean is not false then 'Back to the round' else 'Join' end,
      'route',         jsonb_build_object('kind', 'live', 'id', e->>'id'),
      'league_id',     e->>'league_id',
      'suppress',      '[]'::jsonb,
      'spine',         'ember',
      'at',            e->>'started_at'));
  end if;

  -- an invitation waiting: band 1 with a buddy's weight. The verb is "See the
  -- terms", never "Join" — every join passes the covenant (L-12, D136).
  for e in select * from jsonb_array_elements(coalesce(v_me->'invites', '[]'::jsonb)) loop
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key',           'invite:' || coalesce(e->>'id', ''),
      'tier',          'closing', 'band', 1000,
      'mods',          12, 'mod_reason', 'M6 12 (a buddy asked)',
      'subject',       coalesce(firstname(e->>'inviter'), 'A golfer'),
      'human_subject', nullif(e->>'inviter', '') is not null,
      'eyebrow',       'AN INVITATION',
      'headline',      coalesce(firstname(e->>'inviter'), 'A golfer') || ' put you on '
                         || coalesce(nullif(e->>'container_name', ''), 'a season') || '.',
      'standfirst',    'See the terms before you are in.',
      'action',        'See the terms',
      'route',         jsonb_build_object('kind', 'invite', 'id', e->>'container_id',
                                          'pane', e->>'kind'),
      'league_id',     case when e->>'kind' = 'league' then e->>'container_id' end,
      'suppress',      '[]'::jsonb,
      'spine',         'ember',
      'at',            e->>'created_at'));
  end loop;

  -- a buddy request waiting: answered in place, so its door is the Golfers list
  for e in
    select jsonb_build_object('id', f.requester, 'name', firstname(p.display_name),
                              'at', f.created_at)
      from friendships f join profiles p on p.id = f.requester
     where f.addressee = v and f.status = 'pending'
     order by f.created_at desc limit 3
  loop
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key',           'friend:' || coalesce(e->>'id', ''),
      'tier',          'closing', 'band', 1000,
      'mods',          8, 'mod_reason', 'M8 8 (recent)',
      'subject',       coalesce(e->>'name', 'A golfer'), 'human_subject', true,
      'eyebrow',       'A BUDDY REQUEST',
      'headline',      coalesce(e->>'name', 'A golfer') || ' wants to be golf buddies.',
      'standfirst',    null,
      'action',        'Answer it',
      'route',         jsonb_build_object('kind', 'people', 'id', e->>'id'),
      'league_id',     null,
      'suppress',      '[]'::jsonb,
      'spine',         'ember',
      'at',            e->>'at'));
  end loop;

  -- =========================================================================
  -- per membership: the clash, the floor, the movement, the chapter
  -- =========================================================================
  for m in select * from jsonb_array_elements(coalesce(v_me->'memberships', '[]'::jsonb)) loop
    se := nullif(m->'season', 'null'::jsonb);
    st := nullif(m->'standing', 'null'::jsonb);
    cl := nullif(m->'clash', 'null'::jsonb);
    pu := nullif(m->'pulse', 'null'::jsonb);
    bi := nullif(m->'buy_in', 'null'::jsonb);

    -- ---- the weekly clash -------------------------------------------------
    if cl is not null then
      declare
        v_them  text := coalesce(firstname(cl->>'them_name'), 'your opponent');
        v_mine  jsonb := nullif(cl->'mine', 'null'::jsonb);
        v_their jsonb := nullif(cl->'theirs', 'null'::jsonb);
        v_left  int  := coalesce((cl->>'days_left')::int, 0);
        v_close boolean := coalesce((cl->>'closes_today')::boolean, false);
        v_idle  boolean;
        v_when  text;
        v_head  text;
        v_stand text;
        v_act   text;
        v_route jsonb;
        v_band  int;
        v_mods  int;
        v_why   text;
        v_up    text := nullif(m #>> '{standing,next_up,name}', '');
        v_dn    text := nullif(m #>> '{standing,next_down,name}', '');
      begin
        v_idle  := (v_mine is null and v_their is null);
        v_when  := case when v_close then 'today'
                        when v_left = 1 then 'tomorrow'
                        else 'in ' || v_left || ' days' end;
        -- G4 · D216's yield, verbatim: nobody has played, so there is no
        -- stake yet and the clash drops to band 3. It re-enters the moment
        -- either side posts, or on the last-call day.
        if v_idle and v_left > 1 and not v_close then
          v_band := 600;
          v_head := 'Your clash with ' || v_them || ' is open.';
          v_stand := 'Best round of the week takes it.';
          v_act  := 'Add my round';
          v_route := jsonb_build_object('kind', 'composer');
        elsif v_their is not null and v_mine is null then
          v_band := 1000;
          v_head := v_them || ' posted ' || coalesce((v_their->>'gross'), 'a round')
                      || case when nullif(v_their->>'played_on', '') is not null
                              then ' on ' || to_char((v_their->>'played_on')::date, 'Dy') else '' end || '.';
          v_stand := 'That is the number, and the week closes ' || v_when || '.';
          v_act  := 'Add my round';
          v_route := jsonb_build_object('kind', 'composer');
        elsif v_mine is not null and v_their is null then
          -- SA-2 · "I have posted, they have not" — the state the owner's own
          -- account is in most weeks, and the one the shipped lead had no
          -- sentence for. The subject is the OPPONENT, and the pressure is
          -- named where it actually sits.
          v_band := 1000;
          v_head := v_them || ' has ' || (case when v_close then 'today' when v_left = 1 then 'one day'
                                               else v_left || ' days' end)
                      || ' to answer your ' || coalesce((v_mine->>'gross'), 'round') || '.';
          v_stand := 'Your round is the number to beat.';
          v_act  := 'See the receipt';
          v_route := case when nullif(v_mine->>'round_id', '') is not null
                          then jsonb_build_object('kind', 'receipt', 'id', v_mine->>'round_id')
                          else jsonb_build_object('kind', 'season', 'id', m->>'league_id') end;
        else
          v_band := 1000;
          v_head := 'You and ' || v_them || ' are both in.';
          v_stand := 'The week closes ' || v_when || '. Best round takes it.';
          v_act  := 'See the receipt';
          v_route := case when nullif(v_mine->>'round_id', '') is not null
                          then jsonb_build_object('kind', 'receipt', 'id', v_mine->>'round_id')
                          else jsonb_build_object('kind', 'season', 'id', m->>'league_id') end;
        end if;
        -- M1 the clock (band 1 only), M4 an opponent, M3 the man I am chasing
        v_mods := case when v_band = 1000 then greatest(0, 30 - (v_left * 10)) else 0 end + 24;
        v_why  := case when v_band = 1000 then 'M1 ' || greatest(0, 30 - (v_left * 10)) || ' (the clock) + ' else '' end
                    || 'M4 24 (an opponent)';
        if v_up is not null and firstname(cl->>'them_name') = v_up then
          v_mods := v_mods + 30; v_why := v_why || ' + M3 30 (he is the man above me)';
        elsif v_dn is not null and firstname(cl->>'them_name') = v_dn then
          v_mods := v_mods + 30; v_why := v_why || ' + M3 30 (she is the row below me)';
        end if;
        if (m->>'league_id')::uuid = v_nearest then
          v_mods := v_mods + 5; v_why := v_why || ' + M11 5 (the nearest season)';
        end if;
        v_items := v_items || jsonb_build_array(jsonb_build_object(
          'key',           'clash:' || coalesce(m->>'league_id', '') || ':' || coalesce(cl->>'week_no', ''),
          'tier',          case when v_band = 1000 then 'closing' else 'coming' end,
          'band',          v_band, 'mods', least(99, v_mods), 'mod_reason', v_why,
          'subject',       v_them, 'human_subject', true,
          'eyebrow',       upper(coalesce(nullif(cl->>'rivalry', ''), m->>'name'))
                             || ' · THE CLASH · CLOSES ' || upper(v_when),
          'headline',      v_head,
          'standfirst',    v_stand,
          'action',        v_act,
          'route',         v_route,
          'league_id',     m->>'league_id',
          'suppress',      case when v_mine is not null then '["my_last_round"]'::jsonb else '[]'::jsonb end,
          'spine',         'ember',
          'at',            cl->>'ends_on'));
      end;
    end if;

    -- ---- the month floor (D140 · squads only, never a solo season) --------
    if pu is not null and coalesce(m #>> '{settings,structure}', '') <> 'solo'
       and coalesce((pu->>'floor')::numeric, 0) > 0
       and coalesce((pu->>'partial')::boolean, false) = false
       and coalesce((pu->>'credits')::numeric, 0) < coalesce((pu->>'floor')::numeric, 0)
       and (date_trunc('month', v_today) + interval '1 month - 1 day')::date - v_today <= 3 then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'floor:' || coalesce(m->>'league_id', ''),
        'tier',          'closing', 'band', 1000,
        'mods',          70, 'mod_reason', 'M1 30 (the month) + M2 40 (me)',
        'subject',       'you', 'human_subject', true,
        'eyebrow',       upper(to_char(v_today, 'FMMonth')) || ' CLOSES '
                           || upper(to_char((date_trunc('month', v_today) + interval '1 month - 1 day')::date, 'Dy')),
        'headline',      'You are '
                           || rtrim(trim(to_char(coalesce((pu->>'floor')::numeric, 0) - coalesce((pu->>'credits')::numeric, 0), 'FM999990.9')), '.')
                           || ' short of the minimum.',
        'standfirst',    case when nullif(m #>> '{squad,name}', '') is not null
                              then 'The ' || (m #>> '{squad,name}') || ' carry the penalty, not you.' end,
        'action',        'Add my round',
        'route',         jsonb_build_object('kind', 'composer'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'ember',
        'at',            null));
    end if;

    -- ---- BAND 2 · CHANGED — my rank moved, and the label carries its clock
    -- A-4: `prev_rank` is a SUNDAY snapshot, so the movement is stated
    -- "since Sunday" or it is not stated at all. A bare "held" is unwritable.
    if st is not null and coalesce(se->>'status', '') = 'active'
       and nullif(st->>'prev_rank', '') is not null
       and (st->>'prev_rank')::int <> (st->>'rank')::int then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'move:' || coalesce(m->>'league_id', ''),
        'tier',          'changed', 'band', 800,
        'mods',          60, 'mod_reason', 'M2 40 (me) + M8 20 (this week)',
        'subject',       'you', 'human_subject', true,
        'eyebrow',       upper(m->>'name') || ' · WEEK ' || coalesce(se->>'week_no', '?'),
        'headline',      case when (st->>'prev_rank')::int > (st->>'rank')::int
                              then 'You moved up ' || ((st->>'prev_rank')::int - (st->>'rank')::int) || ' since Sunday.'
                              else 'You were passed since Sunday.' end,
        'standfirst',    case when nullif(st #>> '{next_up,name}', '') is not null
                              then (st #>> '{next_up,name}') || ' is the next one up.' end,
        'action',        'See the table',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id', 'pane', 'table'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'gold',
        'at',            null));
    end if;

    -- ---- BAND 3 · COMING — the first tee, when the season has not started
    if se is not null and nullif(se->>'days_to_first_tee', '') is not null then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'firsttee:' || coalesce(m->>'league_id', ''),
        'tier',          case when (se->>'days_to_first_tee')::int <= 3 then 'closing' else 'coming' end,
        'band',          case when (se->>'days_to_first_tee')::int <= 3 then 1000 else 600 end,
        'mods',          14, 'mod_reason', 'M8 14 (a dated thing)',
        'subject',       coalesce(nullif(m->>'pro_name', ''), 'you'),
        'human_subject', true,
        'eyebrow',       'FIRST TEE ' || upper(to_char((se->>'starts_on')::date, 'Dy Mon FMDD')),
        'headline',      m->>'name' || ' starts in ' || (se->>'days_to_first_tee')
                           || case when (se->>'days_to_first_tee')::int = 1 then ' day.' else ' days.' end,
        'standfirst',    'Rounds you post before then still build your number — they just do not score yet.',
        'action',        'Open the season',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'ember',
        'at',            se->>'starts_on'));
    end if;

    -- ---- BAND 5 · CHAPTER — the season's slow truth, told by a person -----
    if st is not null and coalesce(se->>'status', '') in ('active', 'cup_final')
       and nullif(st->>'leader_name', '') is not null then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'chapter:' || coalesce(m->>'league_id', ''),
        'tier',          'chapter', 'band', 200,
        'mods',          case when (m->>'league_id')::uuid = v_nearest then 5 else 0 end,
        'mod_reason',    case when (m->>'league_id')::uuid = v_nearest
                              then 'M11 5 (the nearest season)' else 'none' end,
        'subject',       st->>'leader_name', 'human_subject', true,
        'eyebrow',       upper(m->>'name') || ' · WEEK ' || coalesce(se->>'week_no', '?')
                           || ' OF ' || coalesce(se->>'weeks_total', '?'),
        'headline',      case when (st->>'rank')::int = 1
                              then 'You are the one to catch.'
                              else (st->>'leader_name') || ' is the one to catch.' end,
        'standfirst',    case when coalesce((se->>'days_left')::int, 0) > 0
                              then coalesce(se->>'days_left', '?') || ' days still to play.' end,
        'action',        'Open the season',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'mut',
        'at',            null));
    end if;

    -- ---- BAND 5b · R-H's reach into history ------------------------------
    -- A quiet day reaches BACK for an older true fact rather than stopping at
    -- "nothing has moved". The last completed season of this league is that
    -- fact, it is on the payload already, and it is the state every member of
    -- a wrapped season is in the morning after (S7).
    if nullif(m->'last_season', 'null'::jsonb) is not null
       and nullif(m #>> '{last_season,champion_name}', '') is not null
       and coalesce(se->>'status', '') <> 'active' then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'lastseason:' || coalesce(m->>'league_id', ''),
        'tier',          'chapter', 'band', 200, 'mods', 0, 'mod_reason', 'none',
        -- LV-11 · the champion may be the CALLER. Without the branch a golfer
        -- who WON read their own name in the third person, beside "You
        -- finished 1 of 8." The file already branches this way one item down
        -- ("You are the one to catch.").
        'subject',       case when (m #>> '{last_season,champion_is_me}')::boolean is true
                              then 'you' else m #>> '{last_season,champion_name}' end,
        'human_subject', true,
        'eyebrow',       upper(m->>'name') || ' · SEASON COMPLETE',
        'headline',      case when (m #>> '{last_season,champion_is_me}')::boolean is true
                              then 'You took the last one.'
                              else (m #>> '{last_season,champion_name}') || ' took the last one.' end,
        -- LV-11 · an ORDINAL, the way the Swift fallback prints it
        -- (`CSCopy.ordinal`). This printed a raw rank — "You finished 3 of 8."
        'standfirst',    case when nullif(m #>> '{last_season,my_rank}', '') is not null
                                   and nullif(m #>> '{last_season,of}', '') is not null
                              then 'You finished ' || ordinal((m #>> '{last_season,my_rank}')::int)
                                     || ' of ' || (m #>> '{last_season,of}') || '.' end,
        'action',        'See how it ended',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'gold',
        'at',            m #>> '{last_season,ended_on}'));
    end if;

    -- ---- BAND 6 · OPPORTUNITY — a wrapped season with nothing live -------
    if coalesce(se->>'status', '') = 'complete' then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'runitback:' || coalesce(m->>'league_id', ''),
        'tier',          'opportunity', 'band', 100,
        'mods',          case when coalesce(bi->>'note', '') <> '' then 6 else 0 end,
        'mod_reason',    'none',
        'subject',       case when m->>'role' = 'commissioner' then 'you'
                              else coalesce(nullif(m->>'pro_name', ''), 'the Pro') end,
        'human_subject', true,
        'eyebrow',       upper(m->>'name'),
        'headline',      case when m->>'role' = 'commissioner'
                              then 'The next season starts when you say it does.'
                              else 'The next season starts when '
                                     || coalesce(nullif(m->>'pro_name', ''), 'the Pro') || ' says it does.' end,
        'standfirst',    null,
        'action',        case when m->>'role' = 'commissioner' then 'Run it back'
                              else 'Ask ' || coalesce(nullif(m->>'pro_name', ''), 'the Pro') || ' to run it back' end,
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'mut',
        'at',            null));
    end if;

    -- ---- v2 / D257 · THE PLAN YOU NEED (R-K, second half) -----------------
    -- A round that has to be SCHEDULED to close a gap or hold a lead. It is a
    -- ranked item, not a sixth slot on the plan sheet, and its whole design is
    -- the fence: L-21 forbids a manufactured stake, so every guard below is a
    -- condition on the ARITHMETIC being real, not on the sentence being good.
    if st is not null
       and coalesce(se->>'status', '') = 'active'
       and coalesce(m #>> '{settings,structure}', '') = 'solo'
       and nullif(st->>'rank', '') is not null
       and coalesce((st->>'of')::int, 0) >= 2
       and nullif(m #>> '{settings,counting_cap}', '') is not null
       and (m #>> '{settings,counting_cap}')::int > 0
    then
      declare
        v_cap   int := (m #>> '{settings,counting_cap}')::int;
        v_mc    jsonb;
        v_used  int;
        v_worst numeric;
        v_gain  numeric;
        v_wkl   int;
        v_when2 text;
        v_gap2  numeric;
        v_who2  text;
        v_head2 text;
        v_sub2  text;
      begin
        v_mc    := month_counters((m->>'member_id')::uuid, (se->>'id')::uuid, v_cap, v_today);
        v_used  := coalesce((v_mc->>'used')::int, 0);
        v_worst := (v_mc->>'worst')::numeric;
        v_gain  := round_worth(v_cap, v_used, v_worst);
        -- "the counting rounds are in hand": a slot the golfer can still fill
        -- this month. With the month full the honest item is the climb's, on
        -- the season page, and Home says nothing.
        if v_used < v_cap and v_gain is not null and v_gain > 0 then
          -- weeks left comes from D246's ONE week producer (native_home), never
          -- from a second ceil(days/7) — §4.27's whole point.
          v_wkl := greatest(0, coalesce((se->>'weeks_total')::int, 0) - coalesce((se->>'week_no')::int, 0));
          v_when2 := case when v_wkl = 0 then 'in the last week'
                          when v_wkl = 1 then 'with one week left'
                          else 'with ' || v_wkl || ' weeks left' end;
          v_head2 := null;
          if (st->>'rank')::int > 1
             and nullif(st #>> '{next_up,name}', '') is not null
             and nullif(st->>'gap_to_next', '') is not null then
            -- CHASING · one top-band round must genuinely close it, which is
            -- the same refusal the climb makes: two rounds each bump a better
            -- counter, so "two rounds closes it" is arithmetic nobody can
            -- stand behind.
            v_gap2 := (st->>'gap_to_next')::numeric;
            if v_gap2 > 0 and v_gain >= v_gap2 then
              v_who2  := firstname(st #>> '{next_up,name}');
              v_head2 := 'You are ' || rtrim(trim(to_char(v_gap2, 'FM999990.9')), '.') || ' back of ' || v_who2 || ' ' || v_when2 || '.';
              v_sub2  := 'One counting round in the top band closes it — your best ' || v_cap
                           || ' count this month and you have ' || v_used || '.';
            end if;
          elsif (st->>'rank')::int = 1
             and nullif(st #>> '{next_down,name}', '') is not null
             and nullif(st #>> '{next_down,points}', '') is not null then
            -- LEADING · the row below must be inside ONE top-band round of me.
            -- That is a challenger the engine can point at; a lead nobody can
            -- take in one round is not a thing to nudge anybody about.
            v_gap2 := coalesce((st->>'points')::numeric, 0) - (st #>> '{next_down,points}')::numeric;
            if v_gap2 > 0 and v_gap2 <= cup_points(3)::numeric then
              v_who2  := firstname(st #>> '{next_down,name}');
              v_head2 := 'You are ' || rtrim(trim(to_char(v_gap2, 'FM999990.9')), '.') || ' clear of ' || v_who2 || ' ' || v_when2 || '.';
              v_sub2  := 'One more counting round is worth up to ' || rtrim(trim(to_char(v_gain, 'FM999990.9')), '.')
                           || ' — your best ' || v_cap || ' count this month and you have ' || v_used || '.';
            end if;
          end if;
          if v_head2 is not null then
            v_items := v_items || jsonb_build_array(jsonb_build_object(
              'key',           'need:' || coalesce(m->>'league_id', ''),
              'tier',          'coming', 'band', 600,
              'mods',          70, 'mod_reason', 'M2 40 (me) + M3 30 (the row beside me)',
              'subject',       v_who2, 'human_subject', true,
              'eyebrow',       upper(m->>'name') || ' · WEEK ' || coalesce(se->>'week_no', '?'),
              'headline',      v_head2,
              'standfirst',    v_sub2,
              'action',        'Put a round on the schedule',
              'route',         jsonb_build_object('kind', 'declare'),
              'league_id',     m->>'league_id',
              'suppress',      '[]'::jsonb,
              'spine',         'mut',
              'at',            se->>'week_ends_on'));
          end if;
        end if;
      end;
    end if;
  end loop;

  -- =========================================================================
  -- BAND 3 · COMING — a plan on the sheet. The ME strip owns NEXT (L-34), so
  -- this item names the COURSE and the PEOPLE, never the time a second time.
  -- =========================================================================
  for e in select * from jsonb_array_elements(coalesce(v_me->'upcoming_rounds', '[]'::jsonb)) loop
    if coalesce(e->>'my_rsvp', '') <> 'out'
       and (coalesce((e->>'mine')::boolean, false) or coalesce((e->>'tagged_me')::boolean, false))
       and nullif(e->>'play_on', '') is not null
       and (e->>'play_on')::date between v_today and v_today + 8 then
      declare
        v_in  int := greatest(0, coalesce((e->>'rsvp_in')::int, 0));
        v_d   int := (e->>'play_on')::date - v_today;
        v_who text := coalesce(firstname(e->>'display_name'), 'A golfer');
        -- the day as a WORD, for a sentence rather than a slot. `MeStripCopy
        -- .dayWord` is its twin on the phone and `HomeFallbackItems` uses it
        -- for the same item, so the ranker and the declared fallback say the
        -- same thing about the same plan.
        v_day text := case ((e->>'play_on')::date - v_today)
                        when 0 then 'today' when 1 then 'tomorrow'
                        else case when (e->>'play_on')::date - v_today between 2 and 6
                                  then to_char((e->>'play_on')::date, 'FMDay')
                                  else to_char((e->>'play_on')::date, 'FMMon FMDD') end end;
      begin
        v_items := v_items || jsonb_build_array(jsonb_build_object(
          'key',           'plan:' || coalesce(e->>'id', ''),
          'tier',          case when v_d <= 3 then 'closing' else 'coming' end,
          'band',          case when v_d <= 3 then 1000 else 600 end,
          'mods',          least(99, greatest(0, 20 - v_d * 2) + 12),
          'mod_reason',    'M8 ' || greatest(0, 20 - v_d * 2) || ' (a dated thing) + M6 12 (a buddy)',
          'subject',       case when coalesce((e->>'mine')::boolean, false) then 'you' else v_who end,
          'human_subject', true,
          'eyebrow',       upper(to_char((e->>'play_on')::date, 'Dy'))
                             || case when nullif(e->>'course_label', '') is not null
                                     then ' · ' || upper(e->>'course_label') else '' end,
          -- L-34 · the EYEBROW above already carries the where-and-when, so the
          -- headline carries the who-and-what and the standfirst the detail.
          -- It read `MON · GOLD CANYON — DINOSAUR MOUNTAIN · BLACK/BLUE` with
          -- `Galen has you down for Gold Canyon — Dinosaur Mountain ·
          -- Black/Blue.` immediately under it: the same fact, in full, twice
          -- on one card. That is the whole reason the grammar has three slots.
          'headline',      case when coalesce((e->>'mine')::boolean, false)
                                then 'You have a round on ' || v_day || '.'
                                else v_who || ' has you down for ' || v_day || '.' end,
          'standfirst',    nullif(concat_ws(' · ',
                                   nullif(to_char((e->>'tee_time')::time, 'FMHH12:MI'), '') || ' tee',
                                   case when v_in > 1 then v_in || ' of you in' end)
                                 || '.', '.'),
          'action',        case when coalesce(e->>'my_rsvp', '') = '' then 'Say you''re in' else 'Open the plan' end,
          'route',         jsonb_build_object('kind', 'plan', 'id', e->>'id'),
          'league_id',     null,
          'suppress',      '[]'::jsonb,
          'spine',         'ember',
          'at',            e->>'play_on'));
      end;
    end if;
  end loop;

  -- =========================================================================
  -- BAND 4 · CIRCLE — someone I know did something. One item, the freshest.
  -- =========================================================================
  begin
    select jsonb_build_object(
             'key',           'story:' || s.round_id,
             'tier',          'circle', 'band', 400,
             'mods',          12, 'mod_reason', 'M6 12 (a buddy)',
             'subject',       firstname(s.golfer), 'human_subject', true,
             'eyebrow',       'AROUND YOUR BUDDIES',
             'headline',      firstname(s.golfer) || ' posted ' || s.gross
                                || case when nullif(s.course, '') is not null then ' at ' || s.course else '' end || '.',
             'standfirst',    case when s.is_pr then 'A personal best.'
                                   when s.is_sub80 then 'Under 80 for the first time.'
                                   when s.is_first then 'Their first posted round.'
                                   when not s.has_rating then 'No rating on that one, so it builds a number and nothing else.'
                              end,
             'action',        'See the round',
             'route',         jsonb_build_object('kind', 'receipt', 'id', s.round_id),
             'league_id',     null,
             'suppress',      '[]'::jsonb,
             'spine',         case when s.is_pr or s.is_sub80 then 'gold' else 'mut' end,
             'at',            s.created_at)
      into e
      from home_stories(v_days, null) s
     where not s.is_me and s.gross is not null
     order by s.created_at desc
     limit 1;
    if e is not null then v_items := v_items || jsonb_build_array(e); end if;
  exception when others then
    null;
  end;

  -- =========================================================================
  -- BAND 6 · OPPORTUNITY — the door worth walking through today, fired only
  -- on a REAL shape. Never a tip, never a promotion.
  -- =========================================================================
  if v_rounds = 0 then
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key', 'first_round', 'tier', 'opportunity', 'band', 100, 'mods', 40,
      'mod_reason', 'M2 40 (me)',
      'subject', 'you', 'human_subject', true,
      'eyebrow', 'NEW HERE',
      'headline', 'Your first round is the only thing missing.',
      'standfirst', 'Add one you already played — course, score, done. Your number starts building at three.',
      'action', 'Add my round',
      'route', jsonb_build_object('kind', 'composer'),
      'league_id', null, 'suppress', '[]'::jsonb, 'spine', 'ember', 'at', null));
  elsif v_friends = 0 then
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key', 'find_golfers', 'tier', 'opportunity', 'band', 100, 'mods', 40,
      'mod_reason', 'M2 40 (me)',
      'subject', 'you', 'human_subject', true,
      'eyebrow', v_rounds || ' ROUNDS IN',
      'headline', 'Your number is yours, and nobody has seen it.',
      'standfirst', 'The golfers you already play with are the ones worth adding.',
      'action', 'Find golfers',
      'route', jsonb_build_object('kind', 'people'),
      'league_id', null, 'suppress', '[]'::jsonb, 'spine', 'mut', 'at', null));
  end if;

  -- =========================================================================
  -- The gates, applied after the score.
  -- =========================================================================

  -- G1 · the fence. An item with no door does not render. (Every item above
  -- carries one; the clause is here so a later item that forgets is dropped
  -- rather than shipped as a dead sentence.)
  select coalesce(jsonb_agg(x order by (x->>'band')::int + (x->>'mods')::int desc,
                            coalesce(x->>'at', '') desc, x->>'key'), '[]'::jsonb)
    into v_items
    from jsonb_array_elements(v_items) x
   where nullif(x #>> '{route,kind}', '') is not null;

  -- G2 · the veto. Rank 1 goes to the highest-scoring item WITH A HUMAN
  -- SUBJECT. A bare standing can never lead; it keeps its score and sits in
  -- the deck. This is one clause and it is the whole difference between this
  -- Home and the shipped one.
  v_lead_ix := null;
  for i in 0 .. coalesce(jsonb_array_length(v_items), 0) - 1 loop
    if v_lead_ix is null and coalesce((v_items->i->>'human_subject')::boolean, false) then
      v_lead_ix := i;
    end if;
  end loop;

  v_rank := 0;
  if v_lead_ix is not null then
    e := v_items->v_lead_ix;
    v_rank := 1;
    v_sup := coalesce(e->'suppress', '[]'::jsonb);
    v_out := jsonb_build_array(e || jsonb_build_object(
      'rank', 1,
      'score', (e->>'band')::int + (e->>'mods')::int,
      'rank_reason', 'B' || (case (e->>'tier')
                               when 'closing' then '1' when 'changed' then '2'
                               when 'coming' then '3' when 'circle' then '4'
                               when 'chapter' then '5' else '6' end)
                       || ' ' || (e->>'band') || ' + ' || (e->>'mods') || ' ('
                       || coalesce(e->>'mod_reason', 'none') || ') = '
                       || ((e->>'band')::int + (e->>'mods')::int) || ' · lead (the veto is satisfied)'));
  end if;

  -- G5 · the cap. One lead plus at most four.
  for i in 0 .. coalesce(jsonb_array_length(v_items), 0) - 1 loop
    e := v_items->i;
    if v_rank >= 5 then exit; end if;
    if exists (select 1 from jsonb_array_elements(v_out) o where o->>'key' = e->>'key') then
      continue;
    end if;
    v_rank := v_rank + 1;
    v_out := v_out || jsonb_build_array(e || jsonb_build_object(
      'rank', v_rank,
      'score', (e->>'band')::int + (e->>'mods')::int,
      'rank_reason', 'B' || (case (e->>'tier')
                               when 'closing' then '1' when 'changed' then '2'
                               when 'coming' then '3' when 'circle' then '4'
                               when 'chapter' then '5' else '6' end)
                       || ' ' || (e->>'band') || ' + ' || (e->>'mods') || ' ('
                       || coalesce(e->>'mod_reason', 'none') || ') = '
                       || ((e->>'band')::int + (e->>'mods')::int)));
  end loop;

  return jsonb_build_object(
    'me',           v_me,
    'items',        v_out,
    'lead_suppress', v_sup,
    'generated_at', now());
end $function$;
revoke all on function public.home_dispatch(p_days integer) from public, anon;
grant execute on function public.home_dispatch(p_days integer) to authenticated;

-- ---- declare_round · S-09 S-10 S-27 -------------------------------------------
CREATE OR REPLACE FUNCTION public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[] DEFAULT '{}'::uuid[], p_tee time without time zone DEFAULT NULL::time without time zone, p_course_id text DEFAULT NULL::text, p_name text DEFAULT NULL::text, p_game text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
  v_label  text := nullif(trim(coalesce(p_name,'')), '');
  v_game   text := nullif(trim(lower(coalesce(p_game,''))), '');
  v_tags   uuid[];
  v_bad    integer;
  v_name   text;
  v_with   text;
  v_who    text;
  v_body   text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_play_on is null or p_play_on < current_date then
    raise exception 'Pick a day that has not happened yet';
  end if;
  if p_play_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  if v_note is not null and length(v_note) > 140 then
    raise exception 'Notes cap at 140 characters';
  end if;
  if v_label is not null and length(v_label) > 60 then v_label := left(v_label, 60); end if;
  if v_label is not null and length(v_label) < 2 then v_label := null; end if;
  -- An unknown game is REFUSED, never stored: the plan's game is the live
  -- round's own vocabulary and there is exactly one list.
  if v_game is not null and v_game not in ('just_golf','skins','match','wolf') then
    raise exception 'Pick one of the games on the card';
  end if;
  if v_game = 'just_golf' then v_game := null; end if;   -- "just golf" is the absence of a game

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');

  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven.';
  end if;
  select count(*) into v_bad
    from unnest(v_tags) t(pid)
   where not (
     exists (select 1 from friendships f
              where f.status = 'accepted'
                and ((f.requester = auth.uid() and f.addressee = t.pid)
                  or (f.addressee = auth.uid() and f.requester = t.pid)))
     or exists (select 1 from league_members a
                   join league_members b on b.league_id = a.league_id
                 where a.profile_id = auth.uid() and b.profile_id = t.pid)
   );
  if v_bad > 0 then raise exception 'You can tag buddies and golfers in your seasons.'; end if;

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time, course_id, name, game)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee,
          nullif(trim(coalesce(p_course_id,'')), ''), v_label, v_game)
  returning id into v_id;

  select coalesce(display_name, 'A golfer') into v_name
    from profiles where id = auth.uid();
  select string_agg(coalesce(display_name, 'a golfer'), ' & ') into v_with
    from profiles where id = any(v_tags);

  -- D219 · the post carries the round it announces. A NAMED weekend leads with
  -- its name; a plain plan reads exactly as it does today.
  insert into posts (league_id, kind, member_id, body, scheduled_round_id)
  select lm.league_id, 'system', lm.id,
         v_name || ' put a round on the schedule — '
         || coalesce(v_label || ' · ', '')
         || to_char(p_play_on, 'Dy Mon DD')
         || coalesce(' · ' || to_char(p_tee, 'FMHH12:MIAM'), '')
         || coalesce(' · ' || v_course, '')
         || coalesce(' · with ' || v_with, '')
         || coalesce(' · "' || v_note || '"', ''),
         v_id
    from league_members lm
   where lm.profile_id = auth.uid();

  if array_length(v_tags, 1) > 0 then
    v_who  := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'Someone');
    v_body := coalesce(v_label || ' · ', '')
              || trim(to_char(p_play_on, 'Dy Mon FMDD'))
              || coalesce(' · ' || v_course, '') || ' — in or out?';
    insert into push_nudges (profile_id, kind, title, body, payload)
    select t.pid, 'rsvp', v_who || ' put you on the schedule', v_body,
           jsonb_build_object('scheduled_round_id', v_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid);
  end if;

  return v_id;
end $function$;
revoke all on function public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[], p_tee time without time zone, p_course_id text, p_name text, p_game text) from public, anon;
grant execute on function public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[], p_tee time without time zone, p_course_id text, p_name text, p_game text) to authenticated;

-- ---- retag_round · S-10 S-27 --------------------------------------------------
CREATE OR REPLACE FUNCTION public.retag_round(p_id uuid, p_tagged uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tags uuid[];
  v_bad  integer;
  v_old  uuid[];
  v_play date; v_course text; v_who text; v_body text;
begin
  if not exists (select 1 from scheduled_rounds
                  where id = p_id and profile_id = auth.uid()) then
    raise exception 'Not your round';
  end if;
  if (select play_on from scheduled_rounds where id = p_id) < current_date then
    raise exception 'That round already happened';
  end if;

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven.';
  end if;

  select count(*) into v_bad
    from unnest(v_tags) t(pid)
   where not (
     exists (select 1 from friendships f
              where f.status = 'accepted'
                and ((f.requester = auth.uid() and f.addressee = t.pid)
                  or (f.addressee = auth.uid() and f.requester = t.pid)))
     or exists (select 1 from league_members a
                   join league_members b on b.league_id = a.league_id
                 where a.profile_id = auth.uid() and b.profile_id = t.pid)
   );
  if v_bad > 0 then raise exception 'You can tag buddies and golfers in your seasons.'; end if;

  -- D104 · remember who was already asked, then write
  select coalesce(tagged, '{}'), play_on, course_label into v_old, v_play, v_course
    from scheduled_rounds where id = p_id;
  update scheduled_rounds set tagged = v_tags where id = p_id;

  -- D104 · ask only the newly tagged (same copy as declare_round)
  if exists (select 1 from unnest(v_tags) t(pid) where not (t.pid = any(v_old))) then
    v_who  := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'Someone');
    v_body := trim(to_char(v_play, 'Dy Mon FMDD'))
              || coalesce(' · ' || nullif(trim(coalesce(v_course, '')), ''), '') || ' — in or out?';
    insert into push_nudges (profile_id, kind, title, body, payload)
    select t.pid, 'rsvp', v_who || ' put you on the schedule', v_body,
           jsonb_build_object('scheduled_round_id', p_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid)
     where not (t.pid = any(v_old));
  end if;
end $function$;
revoke all on function public.retag_round(p_id uuid, p_tagged uuid[]) from public, anon;
grant execute on function public.retag_round(p_id uuid, p_tagged uuid[]) to authenticated;

-- ---- start_season · S-11 ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_season(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; st record; loose int; total int; empty_sq text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  -- brand canon §3: "The Pro", never "commissioner", on anything a golfer
  -- reads. This string reaches them as an error toast; the same file already
  -- says "Only the Pro can lock the bylaws." for the identical guard.
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can start the season.'; end if;

  if st.structure <> 'solo' then
    select count(*) into total from league_members lm where lm.league_id = se.league_id;
    if total < 4 then
      raise exception 'Minimum four to tee off — % in so far. Share the invite link.', total;
    end if;

    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% not on a squad yet — everyone needs one before the first tee', loose;
    end if;

    select q.name into empty_sq
    from squads q left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id, q.name having count(sm.member_id) = 0 limit 1;
    if empty_sq is not null then
      raise exception '% is empty — draw again or assign somebody before the season starts', empty_sq;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          case when se.starts_on > (now() at time zone se.timezone)::date
               then 'The squads are set. First tee ' || to_char(se.starts_on, 'Dy Mon FMDD') || '.'
               else 'The squads are set. The season is live — add your round.' end);
end $function$;
revoke all on function public.start_season(p_season uuid) from public, anon;
grant execute on function public.start_season(p_season uuid) to authenticated;

-- ---- ask_for_a_seat · S-12 ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.ask_for_a_seat(p_scheduled_round uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_row scheduled_rounds%rowtype;
  v_me text;
  v_can boolean;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_scheduled_round is null then raise exception 'Which round?'; end if;

  select * into v_row from scheduled_rounds where id = p_scheduled_round;
  if not found then raise exception 'That round is not on the schedule any more'; end if;
  if v_row.profile_id = v then raise exception 'That is your own round'; end if;
  if v_row.play_on < current_date then raise exception 'That round has already been played'; end if;
  if v = any(coalesce(v_row.tagged, '{}'::uuid[])) then
    -- they are already in the group; the RSVP control is the honest door
    return jsonb_build_object('state', 'already_in');
  end if;

  -- the circle: a buddy, a league mate, or somebody in the same event. A
  -- stranger cannot ping a stranger (L-37, and the same bound `home_feed` uses
  -- to decide whose plans reach whom).
  select exists (
    select 1 from friendships f
     where f.status = 'accepted'
       and ((f.requester = v and f.addressee = v_row.profile_id)
         or (f.addressee = v and f.requester = v_row.profile_id)))
    or exists (
    select 1 from league_members a join league_members b on b.league_id = a.league_id
     where a.profile_id = v and b.profile_id = v_row.profile_id)
    or exists (
    select 1 from event_players a join event_players b on b.event_id = a.event_id
     where a.profile_id = v and b.profile_id = v_row.profile_id)
    into v_can;
  if not v_can then raise exception 'You can only ask somebody you play with'; end if;

  -- ONCE per person per plan (L-20/L-21)
  if exists (select 1 from push_nudges n
              where n.profile_id = v_row.profile_id
                and n.kind = 'rsvp'
                and n.payload->>'scheduled_round_id' = p_scheduled_round::text
                and n.payload->>'from' = v::text) then
    return jsonb_build_object('state', 'already_asked');
  end if;

  select coalesce(display_name, 'A golfer') into v_me from profiles where id = v;

  insert into push_nudges (profile_id, title, body, kind, payload)
  values (v_row.profile_id,
          v_me || ' wants in',
          v_me || ' is asking for a seat on your ' ||
            to_char(v_row.play_on, 'Dy Mon FMDD') || ' round' ||
            coalesce(' at ' || nullif(v_row.course_label, ''), '') || '.',
          'rsvp',
          jsonb_build_object('scheduled_round_id', p_scheduled_round,
                             'from', v,
                             'play_on', v_row.play_on));

  return jsonb_build_object('state', 'asked');
end $function$;
revoke all on function public.ask_for_a_seat(p_scheduled_round uuid) from public, anon;
grant execute on function public.ask_for_a_seat(p_scheduled_round uuid) to authenticated;

-- ---- resolve_session · S-13 (+S-23 by class) ----------------------------------
CREATE OR REPLACE FUNCTION public.resolve_session(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_event uuid; v_no int; v_open date; v_close date; v_allow integer; v_rule text; v_def uuid;
  v_ename text;
  dl record; v_apvi numeric; v_bpvi numeric; a_rid uuid; b_rid uuid;
  v_res text; v_ap numeric; v_bp numeric;
  v_pairs integer; m_total numeric;
  v_ta uuid; v_tb uuid; v_na text; v_nb text; pa numeric; pb numeric; sa numeric; sb numeric;
  v_lines text; v_score text; v_win uuid; v_was text;
  mvp_name text; mvp_rec text; v_rung text; v_the text;
begin
  select s.event_id, s.session_no, s.opens_on, s.closes_on, e.allowance, e.draw_rule,
         e.defender_team_id, e.name, e.status
    into v_event, v_no, v_open, v_close, v_allow, v_rule, v_def, v_ename, v_was
    from event_sessions s join events e on e.id = s.event_id
   where s.id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'Only the organizer can do that.';
  end if;
  -- spec R6: idempotent — a re-run on a closed session is a no-op. Without this
  -- a second call re-reads rounds, re-stamps resolved_at, re-posts the session
  -- story and re-runs the clinch, and can RETRO-FLIP an already-decided duel if
  -- a round was voided or posted late (which R10 forbids). settle_major has had
  -- exactly this guard since 20260727160000; the Ryder never got it, and the
  -- function is granted to authenticated with a client button behind it.
  if (select status from event_sessions where id = p_session) = 'closed' then
    return;
  end if;

  for dl in select * from event_duels where session_id = p_session loop
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into a_rid, v_apvi
      from rounds r join event_players ep on ep.id = dl.a_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into b_rid, v_bpvi
      from rounds r join event_players ep on ep.id = dl.b_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;

    if v_apvi is null and v_bpvi is null then
      v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    elsif v_bpvi is null then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif v_apvi is null then v_res := 'b'; v_ap := 0; v_bp := 1;
    elsif v_apvi > v_bpvi then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif v_bpvi > v_apvi then v_res := 'b'; v_ap := 0; v_bp := 1;
    else v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    end if;

    update event_duels
       set a_round = a_rid, b_round = b_rid, a_pvi = v_apvi, b_pvi = v_bpvi,
           a_points = v_ap, b_points = v_bp, result = v_res, resolved_at = now()
     where id = dl.id;
  end loop;

  update event_sessions set status = 'closed' where id = p_session;

  select id, name into v_ta, v_na from event_teams where event_id = v_event and slot = 0;
  select id, name into v_tb, v_nb from event_teams where event_id = v_event and slot = 1;
  select coalesce(sum(points),0) into pa from v_event_scoreboard where event_id = v_event and team_id = v_ta;
  select coalesce(sum(points),0) into pb from v_event_scoreboard where event_id = v_event and team_id = v_tb;

  -- the session story: every duel line + the running scoreline
  select string_agg(line, ' · ') into v_lines from (
    select case d.result
        when 'a' then firstname(pa2.display_name) || ' beat ' || firstname(pb2.display_name)
              || coalesce(' by ' || round(abs(d.a_pvi - d.b_pvi), 1), '')
        when 'b' then firstname(pb2.display_name) || ' beat ' || firstname(pa2.display_name)
              || coalesce(' by ' || round(abs(d.b_pvi - d.a_pvi), 1), '')
        else firstname(pa2.display_name) || ' and ' || firstname(pb2.display_name) || ' halved'
      end as line
      from event_duels d
      join event_players ea on ea.id = d.a_player join profiles pa2 on pa2.id = ea.profile_id
      join event_players eb on eb.id = d.b_player join profiles pb2 on pb2.id = eb.profile_id
     where d.session_id = p_session
     order by d.id
  ) x;
  v_score := case when pa = pb then 'All square, ' || evhalf(pa) || '–' || evhalf(pb)
                  when pa > pb then v_na || ' lead ' || evhalf(pa) || '–' || evhalf(pb)
                  else v_nb || ' lead ' || evhalf(pb) || '–' || evhalf(pa) end;
  if v_lines is not null then
    perform event_post(v_event,
      v_score || ' after week ' || v_no || '. ' || v_lines || '.');
  end if;

  -- D146 · a settled event is never re-decided. The tick now keeps resolving a
  -- completed event's remaining sessions so the dead rubbers go on the record
  -- (spec R4), which means this block can run again after the cup is won — and
  -- a late swing must not move the winner_team_id that was already awarded.
  if v_was <> 'complete' then
  -- clinch / completion (draw rule from 20260716150000, unchanged)
  select least(
      (select count(*) from event_players where event_id = v_event and team_id = v_ta),
      (select count(*) from event_players where event_id = v_event and team_id = v_tb))
    into v_pairs;
  m_total := v_pairs * (select session_count from events where id = v_event);

  if m_total > 0 and greatest(pa, pb) > m_total/2.0 then
    v_rung := null;                              -- clinched on the sheet
    update events set status='complete', decided_by = v_rung,
      winner_team_id = case when pa > pb then v_ta else v_tb end
      where id = v_event;
  elsif not exists (select 1 from event_sessions where event_id=v_event and status <> 'closed') then
    if pa <> pb then
      v_rung := null;                            -- points alone decided it
      update events set status='complete', decided_by = v_rung,
        winner_team_id = case when pa > pb then v_ta else v_tb end
        where id = v_event;
    else
      if v_rule = 'defender' and v_def is not null then
        update events set status='complete', winner_team_id = v_def where id = v_event;
      elsif v_rule = 'shared' then
        v_rung := 'shared cup';
        update events set status='complete', decided_by = v_rung,
          winner_team_id = null where id = v_event;
      else
        select coalesce(sum(case when ep.team_id = v_ta then x.pvi end),0),
               coalesce(sum(case when ep.team_id = v_tb then x.pvi end),0)
          into sa, sb
          from (
            select a_player as player, a_pvi as pvi from event_duels where event_id = v_event and a_pvi is not null
            union all
            select b_player, b_pvi from event_duels where event_id = v_event and b_pvi is not null
          ) x join event_players ep on ep.id = x.player;
        v_rung := case when sa = sb then 'shared cup' else 'total PvI' end;
        update events set status='complete', decided_by = v_rung,
          winner_team_id = case when sa > sb then v_ta when sb > sa then v_tb else null end
          where id = v_event;
      end if;
    end if;
  end if;

  end if;   -- /D146 settled-event guard

  -- completion story: the cup + the MVP (best record, tiebreak total PvI)
  if v_was <> 'complete' and (select status from events where id = v_event) = 'complete' then
    select pr.display_name, s.w || '-' || s.l || '-' || s.h
      into mvp_name, mvp_rec
      from (
        select ep.profile_id,
          count(*) filter (where (d.a_player=ep.id and d.result='a') or (d.b_player=ep.id and d.result='b')) w,
          count(*) filter (where (d.a_player=ep.id and d.result='b') or (d.b_player=ep.id and d.result='a')) l,
          count(*) filter (where d.result='halve') h,
          coalesce(sum(case when d.a_player=ep.id then d.a_pvi when d.b_player=ep.id then d.b_pvi end),0) tot
        from event_players ep
        join event_duels d on d.event_id = ep.event_id
             and (d.a_player = ep.id or d.b_player = ep.id) and d.result <> 'pending'
        where ep.event_id = v_event
        group by ep.id, ep.profile_id
        order by w desc, tot desc limit 1
      ) s join profiles pr on pr.id = s.profile_id;
    select winner_team_id, decided_by into v_win, v_rung from events where id = v_event;
    -- an event actually called "The Grudge" produced "take the The Grudge"
    v_the := case when v_ename ~* '^the\s' then '' else 'the ' end;
    perform event_post(v_event,
      case when v_win is null
              then v_na || ' and ' || v_nb || ' share ' || v_the || v_ename
                   || ', ' || evhalf(pa) || '–' || evhalf(pb) || '.'
            -- D146: a tie broken by the draw rule announced a tie AND a winner
            -- in one breath, with no reason. Say which rung decided it.
            when v_rung is not null
              then 'Level at ' || evhalf(greatest(pa,pb)) || '–' || evhalf(least(pa,pb))
                   || ' — ' || (case when v_win = v_ta then v_na else v_nb end)
                   || ' take ' || v_the || v_ename || ' on ' || v_rung || '.'
            when v_win = v_ta
              then v_na || ' take ' || v_the || v_ename || ' ' || evhalf(pa) || '–' || evhalf(pb) || '.'
            else v_nb || ' take ' || v_the || v_ename || ' ' || evhalf(pb) || '–' || evhalf(pa) || '.' end
      || coalesce(' ' || firstname(mvp_name) || ' is MVP at ' || mvp_rec || '.', ''));
  end if;
end $function$;
revoke all on function public.resolve_session(p_session uuid) from public, anon;
grant execute on function public.resolve_session(p_session uuid) to authenticated;

-- ---- generate_pairings · S-14 S-23 --------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_pairings(p_session uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_event uuid; v_no int; v_team_a uuid; v_team_b uuid; v_pairs integer; i integer;
  a_ids uuid[]; b_ids uuid[]; v_lines text;
begin
  select event_id, session_no into v_event, v_no from event_sessions where id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'Only the organizer can do that.';
  end if;

  select id into v_team_a from event_teams where event_id = v_event and slot = 0;
  select id into v_team_b from event_teams where event_id = v_event and slot = 1;

  select array_agg(id order by benched_count, seed) into a_ids
    from event_players where event_id = v_event and team_id = v_team_a;
  select array_agg(id order by benched_count, seed) into b_ids
    from event_players where event_id = v_event and team_id = v_team_b;

  v_pairs := least(coalesce(array_length(a_ids,1),0), coalesce(array_length(b_ids,1),0));
  if v_pairs = 0 then return 0; end if;   /* S5-01: an empty side pairs nobody — touch nothing */

  delete from event_duels where session_id = p_session;
  for i in 1..v_pairs loop
    insert into event_duels (event_id, session_id, a_player, b_player)
      values (v_event, p_session, a_ids[i], b_ids[i]);
  end loop;

  for i in (v_pairs+1)..coalesce(array_length(a_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = a_ids[i];
  end loop;
  for i in (v_pairs+1)..coalesce(array_length(b_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = b_ids[i];
  end loop;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = v_event and status = 'setup';

  select string_agg(firstname(pa.display_name) || ' v ' || firstname(pb.display_name), ', ')
    into v_lines
    from event_duels d
    join event_players ea on ea.id = d.a_player join profiles pa on pa.id = ea.profile_id
    join event_players eb on eb.id = d.b_player join profiles pb on pb.id = eb.profile_id
   where d.session_id = p_session;
  perform event_post(v_event,
    case when v_pairs <= 3
         then 'Week ' || v_no || ' is up: ' || v_lines || '.'
         else 'Week ' || v_no || ' is up. ' || v_pairs
              || ' clashes — find yours.' end);
  return v_pairs;
end $function$;
revoke all on function public.generate_pairings(p_session uuid) from public, anon;
grant execute on function public.generate_pairings(p_session uuid) to authenticated;

-- ---- create_event · S-15 ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_event(p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer, p_draw_rule text, p_team_a text, p_team_b text, p_league uuid DEFAULT NULL::uuid, p_tz text DEFAULT NULL::text, p_lineage uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_event uuid; v_team_a uuid; v_cap uuid; i integer; v_open date; v_tz text; v_root uuid; v_allow integer;
begin
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'You have to be in that season to run a Ryder with it';
  end if;
  if extract(dow from p_starts_on) <> 0 then
    raise exception 'The Ryder starts on a Sunday — each week runs Sun to Sat';
  end if;

  -- the chain link (D62): rematch-only, your own history only, like to like
  if p_lineage is not null then
    if not exists (select 1 from events e
                    where e.id = p_lineage and e.kind is distinct from 'major'
                      and (e.created_by = auth.uid() or is_event_member(e.id))) then
      raise exception 'You can only run back a Ryder you were part of';
    end if;
    v_root := lineage_root(p_lineage);
  end if;

  -- tz: league's active season > creator's device (validated) > Phoenix
  if p_league is not null then
    select timezone into v_tz from seasons
     where league_id = p_league order by number desc limit 1;
  end if;
  if v_tz is null and p_tz is not null then
    begin perform now() at time zone p_tz; v_tz := p_tz;
    exception when others then v_tz := null; end;
  end if;
  v_tz := coalesce(v_tz, 'America/Phoenix');

  -- D147 · an ATTACHED event scores at its league's allowance. events.allowance
  -- was never written by anything and sat at its default of 100, so a Ryder run
  -- inside a 95% league valued the same round differently from the league that
  -- borrowed it out — with nothing on any surface saying so. A standalone event
  -- keeps the 100 default, because there is no league to inherit from.
  if p_league is not null then
    select handicap_allowance into v_allow from league_settings where league_id = p_league;
  end if;

  insert into events (name, created_by, league_id, starts_on, session_count,
                      session_weeks, draw_rule, tz, lineage_id, allowance)
  values (p_name, auth.uid(), p_league, p_starts_on,
          greatest(1, least(26, coalesce(p_sessions,3))),
          greatest(1, least(4, coalesce(p_session_weeks,1))),
          coalesce(p_draw_rule,'team_pvi'), v_tz, v_root, coalesce(v_allow, 100))
  returning id into v_event;

  insert into event_teams (event_id, slot, name, color)
    values (v_event, 0, coalesce(p_team_a,'Team A'), 0) returning id into v_team_a;
  insert into event_teams (event_id, slot, name, color)
    values (v_event, 1, coalesce(p_team_b,'Team B'), 1);

  insert into event_players (event_id, profile_id, team_id, role, seed)
    values (v_event, auth.uid(), v_team_a, 'captain', 0) returning id into v_cap;
  update event_teams set captain_player_id = v_cap where id = v_team_a;

  for i in 1..(select session_count from events where id = v_event) loop
    v_open := p_starts_on + ((i-1) * 7 * (select session_weeks from events where id = v_event));
    insert into event_sessions (event_id, session_no, opens_on, closes_on)
      values (v_event, i, v_open, v_open + (7 * (select session_weeks from events where id = v_event)) - 1);
  end loop;

  return v_event;
end $function$;
revoke all on function public.create_event(p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer, p_draw_rule text, p_team_a text, p_team_b text, p_league uuid, p_tz text, p_lineage uuid) from public, anon;
grant execute on function public.create_event(p_name text, p_starts_on date, p_sessions integer, p_session_weeks integer, p_draw_rule text, p_team_a text, p_team_b text, p_league uuid, p_tz text, p_lineage uuid) to authenticated;

-- ---- join_league · S-16 S-30 --------------------------------------------------
CREATE OR REPLACE FUNCTION public.join_league(p_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league uuid; v_new uuid; v_name text;
begin
  select id into v_league from leagues where upper(code) = upper(p_code);
  if not found then raise exception 'That code didn''t match — check it and try again.'; end if;
  -- D161 · the code is for assembling the league, not an evergreen entrance
  perform _join_gate(v_league, false);
  insert into league_members (league_id, profile_id)
    values (v_league, auth.uid())
    on conflict (league_id, profile_id) do nothing
    returning id into v_new;
  -- only announce on a genuine join, not a re-tap of a league you're already in
  if v_new is not null then
    select display_name into v_name from profiles where id = auth.uid();
    insert into posts (league_id, kind, body)
      values (v_league, 'system', coalesce(v_name,'A golfer') || ' is in.');
  end if;
  return v_league;
end $function$;
revoke all on function public.join_league(p_code text) from public, anon;
grant execute on function public.join_league(p_code text) to authenticated;

-- ---- respond_invite · S-16 ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.respond_invite(p_id uuid, p_accept boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare mi member_invites%rowtype; v_idx numeric; v_name text; v_new uuid; v_squad text;
begin
  select * into mi from member_invites where id = p_id and profile_id = auth.uid();
  if not found then raise exception 'invite not found'; end if;
  if mi.status <> 'pending' then return; end if;

  if p_accept then
    -- D161 · staged by the Pro, so it follows the Pro's window. A decline is
    -- never gated: saying no must always work.
    if mi.league_id is not null then
      perform _join_gate(mi.league_id, true);
    end if;
    select display_name, index_current into v_name, v_idx from profiles where id = auth.uid();
    if mi.league_id is not null then
      insert into league_members (league_id, profile_id, role, index_current)
        values (mi.league_id, auth.uid(), 'player', coalesce(v_idx, 18.0))
        on conflict (league_id, profile_id) do nothing
        returning id into v_new;
      -- D95: only a genuine join is news. Accepting an invite for a league you
      -- already code-joined must not announce you a second time.
      if v_new is not null then
        v_squad := _late_squad(mi.league_id, v_new);
        insert into posts (league_id, kind, body)
          values (mi.league_id, 'system',
                  coalesce(v_name,'A golfer') || ' is in.'
                  || case when v_squad is not null
                          then ' The thinnest squad takes them: ' || v_squad || '.'
                          else '' end);
      end if;
    else
      insert into event_players (event_id, profile_id, seed)
        values (mi.event_id, auth.uid(),
                coalesce((select max(seed)+1 from event_players where event_id=mi.event_id), 0))
        on conflict (event_id, profile_id) do nothing;
    end if;
    update member_invites set status='accepted' where id = p_id;
  else
    update member_invites set status='declined' where id = p_id;
  end if;
end $function$;
revoke all on function public.respond_invite(p_id uuid, p_accept boolean) from public, anon;
grant execute on function public.respond_invite(p_id uuid, p_accept boolean) to authenticated;

-- ---- remove_member · S-16 S-18 S-36 -------------------------------------------
CREATE OR REPLACE FUNCTION public.remove_member(p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league uuid; v_name text;
begin
  select league_id into v_league from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro removes golfers'; end if;
  if p_member = my_member_id(v_league) then raise exception 'Transfer the Pro role before leaving'; end if;
  if (select phase from leagues where id = v_league) <> 'setup' then
    raise exception 'A golfer can only be removed during setup — mid-season, suspend them instead.';
  end if;

  select coalesce(p.display_name, 'A member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  update posts set member_id = null where member_id = p_member;
  delete from squad_members where member_id = p_member;
  delete from buy_ins where member_id = p_member;
  delete from league_members where id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, my_member_id(v_league), 'remove_member',
          jsonb_build_object('member', p_member, 'name', v_name));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          v_name || ' is off the roster.');
end $function$;
revoke all on function public.remove_member(p_member uuid) from public, anon;
grant execute on function public.remove_member(p_member uuid) to authenticated;

-- ---- randomize_squads · S-17 S-23 S-30 ----------------------------------------
CREATE OR REPLACE FUNCTION public.randomize_squads(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; m record;
  sq_n int; total int; pool_n int;
  reveal text := '';
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can do that.'; end if;

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if coalesce(st.draft_type, 'random') <> 'random' then
    raise exception 'The Pro picks the squads in this league — tap golfers into squads instead of drawing.';
  end if;

  select count(*) into sq_n from squads where season_id = p_season;
  if sq_n = 0 then raise exception 'No squads yet — set the squads first.'; end if;

  select count(*) into total from league_members lm where lm.league_id = se.league_id;
  if total < sq_n then
    raise exception 'Not enough golfers to cover every squad — % in, % squads. Share the invite link first.', total, sq_n;
  end if;

  select count(*) into pool_n from league_members lm
  where lm.league_id = se.league_id
    and not exists (select 1 from squad_members x
                    join squads q on q.id = x.squad_id and q.season_id = p_season
                    where x.member_id = lm.id);
  if pool_n = 0 then return; end if;   /* nothing to deal — no story, no captain churn */

  for m in
    select lm.id from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id)
    order by random()
  loop
    /* the hat deals to the smallest squad — draws AND redraws stay balanced */
    insert into squad_members (squad_id, member_id)
    select q.id, m.id
    from squads q
    left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id
    order by count(sm.member_id) asc, random()
    limit 1;
  end loop;

  update squads q set captain_member_id = (
    select member_id from squad_members where squad_id = q.id limit 1)
  where q.season_id = p_season and q.captain_member_id is null;

  select string_agg(q.name||' — '||cnt||' golfer'||case when cnt=1 then '' else 's' end, ' · ')
    into reveal
  from (select q.name, count(sm.member_id) cnt
        from squads q left join squad_members sm on sm.squad_id = q.id
        where q.season_id = p_season group by q.name, q.id order by q.name) q;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'The squads are drawn. The hat has spoken. '||coalesce(reveal,''));
end $function$;
revoke all on function public.randomize_squads(p_season uuid) from public, anon;
grant execute on function public.randomize_squads(p_season uuid) to authenticated;

-- ---- enter_major · S-19 -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enter_major(p_event uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v record; v_id uuid; v_seed integer; v_exh boolean; v_n integer;
begin
  select e.id, e.kind, e.status, e.league_id into v from events e where e.id = p_event;
  if v.id is null or v.kind <> 'major' then raise exception 'No such Major'; end if;
  if v.status = 'complete' then raise exception 'That one is settled — catch the next Major'; end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'The horn has sounded — catch the next Major';
  end if;
  if v.league_id is null or not is_league_member(v.league_id) then
    raise exception 'Entry is by invite — ask the organizer';
  end if;

  v_exh := not major_contender(auth.uid());
  select coalesce(max(seed),0)+1 into v_seed from event_players where event_id = p_event;
  insert into event_players (event_id, profile_id, seed, exhibition)
    values (p_event, auth.uid(), v_seed, v_exh)
    on conflict (event_id, profile_id) do nothing
    returning id into v_id;
  if v_id is not null then
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event,
      (select display_name from profiles where id = auth.uid())
      || ' is in. Field of ' || v_n || '.'
      || case when v_exh then ' Doesn''t count this year — official by the next one.' else '' end);
  end if;
  return v_id;
end $function$;
revoke all on function public.enter_major(p_event uuid) from public, anon;
grant execute on function public.enter_major(p_event uuid) to authenticated;

-- ---- round_major_story · S-19 -------------------------------------------------
CREATE OR REPLACE FUNCTION public.round_major_story()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m record; v_pvi numeric; v_prior numeric; v_lead numeric; v_name text; v_line text;
begin
  if new.voided or coalesce(new.source,'app') = 'sim' or new.holes_played <> 18
     or new.index_at_post is null or new.differential is null then
    return new;
  end if;
  for m in
    select e.id as ev, e.allowance, s.opens_on, s.closes_on,
           ep.id as player_id, ep.exhibition
      from events e
      join event_sessions s on s.event_id = e.id and s.status = 'open'
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status = 'live'
       and new.played_on between s.opens_on and s.closes_on
  loop
    v_pvi := round((new.index_at_post * m.allowance / 100.0) - new.differential, 1);
    select max(round((r.index_at_post * m.allowance / 100.0) - r.differential, 1))
      into v_prior
      from rounds r
     where r.profile_id = new.profile_id and r.id <> new.id
       and r.played_on between m.opens_on and m.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;
    if v_prior is not null and v_pvi <= v_prior then continue; end if;

    select max(pvi) into v_lead from major_board(m.ev)
     where not exhibition and pvi is not null and player_id <> m.player_id;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := coalesce(v_name,'A golfer')
      || case when v_prior is null then ' opens with ' else ' improves to ' end
      || new.gross || ' — ' || lower(mj_vs(v_pvi));
    if m.exhibition then
      v_line := v_line || '. Doesn''t count this year.';
    elsif v_lead is null or v_pvi > v_lead then
      v_line := v_line || '. Takes the lead.';
    elsif v_pvi = v_lead then
      v_line := v_line || '. Ties the lead.';
    else
      v_line := v_line || '. The lead is ' || lower(mj_vs(v_lead)) || '.';
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $function$;
revoke all on function public.round_major_story() from public, anon, authenticated;   -- engine-only: the tick and the story generators; service_role keeps it, as today

-- ---- sched_major_story · S-19 -------------------------------------------------
CREATE OR REPLACE FUNCTION public.sched_major_story()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m record; l record; v_name text; v_line text;
begin
  for m in
    select e.id as ev, ep.id as player_id
      from events e
      join event_sessions s on s.event_id = e.id and s.status in ('upcoming','open')
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status in ('setup','live')
       and new.play_on between s.opens_on and s.closes_on
  loop
    select * into l from major_board(m.ev)
     where not exhibition and pvi is not null
     order by pvi desc, best_posted_at asc limit 1;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := coalesce(v_name,'A golfer') || ' is down for ' || to_char(new.play_on,'FMDay')
      || coalesce(' at ' || new.course_label, '');
    if l.player_id is null then
      v_line := v_line || '. First card takes the lead.';
    elsif l.player_id = m.player_id then
      v_line := v_line || '. Defending the lead at ' || lower(mj_vs(l.pvi)) || '.';
    else
      v_line := v_line || '. Chasing ' || lower(mj_vs(l.pvi)) || '.';
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $function$;
revoke all on function public.sched_major_story() from public, anon, authenticated;   -- engine-only: the tick and the story generators; service_role keeps it, as today

-- ---- settle_major · S-19 S-23 -------------------------------------------------
CREATE OR REPLACE FUNCTION public.settle_major(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s record; p record; t record; f record;
  b_pvi numeric[]; b_rid uuid[]; b_gross integer[]; b_at timestamptz[];
  v_cards integer; v_pot numeric; v_entrants integer;
  v_champ record; v_ru record; v_third record;
  v_share numeric; v_paid numeric := 0; v_places integer;
  v_line text; v_flip text := ''; v_tie text := '';
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.allowance, e.buy_in, e.pot_split, e.league_id,
         e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if s.status = 'closed' then return; end if;          -- idempotent
  if auth.uid() is not null then
    if not is_event_organizer(s.event_id) then raise exception 'Only the organizer can do that.'; end if;
    if s.closes_on >= (now() at time zone coalesce(s.tz,'America/Phoenix'))::date then
      raise exception 'The window runs through % — the horn sounds after', to_char(s.closes_on,'Dy Mon DD');
    end if;
  end if;

  -- freeze every player's card: best + second-best eligible in the window
  for p in select ep.id, ep.profile_id, ep.exhibition
             from event_players ep where ep.event_id = s.event_id
  loop
    select array_agg(x.pvi), array_agg(x.rid), array_agg(x.gross), array_agg(x.at)
      into b_pvi, b_rid, b_gross, b_at
      from (
        select round((r.index_at_post * s.allowance / 100.0) - r.differential, 1) as pvi,
               r.id as rid, r.gross, r.created_at as at
          from rounds r
         where r.profile_id = p.profile_id
           and r.played_on between s.opens_on and s.closes_on
           and not r.voided and coalesce(r.source,'app') <> 'sim'
           and r.holes_played = 18
           and r.index_at_post is not null and r.differential is not null
         order by pvi desc, r.created_at asc, r.id
         limit 2
      ) x;
    select count(*) into v_cards
      from rounds r
     where r.profile_id = p.profile_id
       and r.played_on between s.opens_on and s.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;

    insert into event_major_cards
      (event_id, player_id, round_id, gross, pvi, second_pvi, cards,
       best_posted_at, no_card, exhibition)
    values
      (s.event_id, p.id, b_rid[1], b_gross[1], b_pvi[1], b_pvi[2], v_cards,
       b_at[1], b_pvi[1] is null, p.exhibition)
    on conflict (event_id, player_id) do nothing;
  end loop;

  -- rank the contenders: the countback ladder (D45), coin flip last.
  -- Reset first so a rerun after a mid-settle crash can't strand a stale
  -- rank or prize on a row the fresh ranking no longer pays.
  update event_major_cards set rank = null, prize = 0 where event_id = s.event_id;
  with ranked as (
    select id, pvi, second_pvi, best_posted_at,
           row_number() over (order by pvi desc, second_pvi desc nulls last,
                              best_posted_at asc, random()) as rn
      from event_major_cards
     where event_id = s.event_id and not exhibition and not no_card
  )
  update event_major_cards c set rank = r.rn
    from ranked r where c.id = r.id;

  -- name the rungs that decided anything (receipts on the board)
  for t in
    select a.rank as arank, pa.display_name as aname, pb.display_name as bname,
           (a.second_pvi is not distinct from b.second_pvi
            and a.best_posted_at is not distinct from b.best_posted_at) as flipped
      from event_major_cards a
      join event_major_cards b on b.event_id = a.event_id and b.rank = a.rank + 1
      join event_players epa on epa.id = a.player_id join profiles pa on pa.id = epa.profile_id
      join event_players epb on epb.id = b.player_id join profiles pb on pb.id = epb.profile_id
     where a.event_id = s.event_id and a.pvi = b.pvi and a.rank <= 3
  loop
    if t.flipped then
      v_flip := v_flip || ' Coin flip: ' || t.aname || ' over ' || t.bname || '.';
    elsif t.arank = 1 then
      v_tie := ' On countback.';
    end if;
  end loop;

  -- the pot: contender entrants only (exhibition never buys in, never pays)
  select count(*) into v_entrants
    from event_major_cards where event_id = s.event_id and not exhibition;
  v_pot := s.buy_in * v_entrants;
  select count(*) into v_places
    from event_major_cards where event_id = s.event_id and rank is not null;

  if v_pot > 0 and v_places > 0 then
    if s.pot_split = 'wta' then
      update event_major_cards set prize = v_pot
       where event_id = s.event_id and rank = 1;
    else
      -- 60/25/15; a place the field can't fill rolls up to the champion
      if v_places >= 2 then
        v_share := round(v_pot * 0.25, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 2;
        v_paid := v_paid + v_share;
      end if;
      if v_places >= 3 then
        v_share := round(v_pot * 0.15, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 3;
        v_paid := v_paid + v_share;
      end if;
      update event_major_cards set prize = v_pot - v_paid
       where event_id = s.event_id and rank = 1;
    end if;
  end if;

  update event_sessions set status = 'closed' where id = p_session;

  -- podium reads
  select pr.display_name, c.gross, c.pvi, c.prize into v_champ
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 1;
  select pr.display_name, c.pvi into v_ru
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 2;
  select pr.display_name, c.pvi into v_third
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 3;

  -- completion FIRST (trophy trigger reads the ranked cards), then the story
  update events set status = 'complete' where id = s.event_id;

  if v_champ.display_name is null then
    v_line := s.name || '. '
      || case when exists (select 1 from event_major_cards
                            where event_id = s.event_id and exhibition and not no_card)
              then 'No official cards — the jug stays in the case.'
              else 'No cards posted — the jug stays in the case.' end
      || case when s.buy_in > 0 then ' Buy-ins returned.' else '' end;
  else
    v_line := firstname(v_champ.display_name) || ' takes '
      || case when s.name ~* '^the\s' then '' else 'the ' end || s.name
      || ', ' || lower(mj_vs(v_champ.pvi)) || '.' || v_tie
      || case when v_pot > 0 and s.pot_split = 'wta' then ' And the ' || mj_money(v_pot) || '.'
              when v_pot > 0 then ' ' || mj_money(v_pot) || ' in the pot.'
              else '' end
      || v_flip;
  end if;
  perform major_post(s.event_id, v_line);

  -- the best exhibition run gets its line (never the jug — D44)
  select pr.display_name, c.gross, c.pvi into f
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.exhibition and not c.no_card
   order by c.pvi desc limit 1;
  if f.display_name is not null then
    perform event_post(s.event_id,
      'Not counting this year: ' || f.display_name || ' went ' || f.gross || ' (' || lower(mj_vs(f.pvi))
      || '). Official by the next one.');
  end if;
end $function$;
revoke all on function public.settle_major(p_session uuid) from public, anon;
grant execute on function public.settle_major(p_session uuid) to authenticated;

-- ---- open_major · S-23 --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.open_major(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; v_today date; v_n integer; v_days integer;
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.buy_in, e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if auth.uid() is not null and not is_event_organizer(s.event_id) then
    raise exception 'Only the organizer can do that.';
  end if;
  if s.status <> 'upcoming' then return; end if;
  v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
  if s.opens_on > v_today then
    raise exception 'The window opens %', to_char(s.opens_on, 'Dy Mon DD');
  end if;
  select count(*) into v_n from event_players where event_id = s.event_id;
  if v_n < 2 then raise exception 'A Major needs a field — 2 at least'; end if;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = s.event_id and status = 'setup';

  v_days := s.closes_on - s.opens_on + 1;
  perform major_post(s.event_id,
    s.name || ' is live. ' || v_days || ' days, field of ' || v_n
    || '. Best card by ' || to_char(s.closes_on, 'FMDay') || ' night takes the jug.');
end $function$;
revoke all on function public.open_major(p_session uuid) from public, anon;
grant execute on function public.open_major(p_session uuid) to authenticated;

-- ---- lock_league · S-20 -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.lock_league(p_league uuid, p_name text DEFAULT NULL::text, p_preset text DEFAULT 'standard'::text, p_handicap_allowance integer DEFAULT 95, p_verification text DEFAULT 'attested'::text, p_counting_cap integer DEFAULT 3, p_participation_floor integer DEFAULT 2, p_floor_penalty text DEFAULT 'deduct'::text, p_season_format text DEFAULT 'points'::text, p_structure text DEFAULT 'squads2'::text, p_buyin_cents integer DEFAULT 0, p_season_months integer DEFAULT 6, p_draft_type text DEFAULT 'random'::text, p_finish text DEFAULT 'cup_final'::text, p_payout_champ integer DEFAULT 60, p_payout_runnerup integer DEFAULT 25, p_payout_king integer DEFAULT 15, p_starts_on date DEFAULT NULL::date, p_ends_on date DEFAULT NULL::date, p_pay_note text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league   leagues;
  v_settings league_settings;
  v_season   seasons;
  v_phase    text;
  v_starts   date;
  v_ends     date;
  v_months   int;
  v_note     text := nullif(btrim(coalesce(p_pay_note, '')), '');
begin
  select * into v_league from leagues where id = p_league;
  if not found then raise exception 'That league no longer exists.'; end if;

  if not is_commissioner(p_league) then
    raise exception 'Only the Pro can start the season.';
  end if;

  select * into v_settings from league_settings where league_id = p_league;
  if v_settings.locked_at is not null then
    select * into v_season from seasons where league_id = p_league and number = 1;
    return json_build_object(
      'already_locked', true,
      'phase',  v_league.phase,
      'season', row_to_json(v_season));
  end if;

  v_starts := coalesce(p_starts_on, current_date);
  if p_ends_on is not null then
    v_ends := p_ends_on;
  else
    v_ends := v_starts + (coalesce(p_season_months, 6) * 30.44)::int - 1;
  end if;
  v_months := greatest(1, least(12, round((v_ends - v_starts + 1) / 30.44::numeric)::int));

  update league_settings set
    preset              = coalesce(p_preset, preset),
    handicap_allowance  = coalesce(p_handicap_allowance, handicap_allowance),
    verification        = coalesce(p_verification, verification),
    counting_cap        = coalesce(p_counting_cap, counting_cap),
    participation_floor = coalesce(p_participation_floor, participation_floor),
    floor_penalty       = coalesce(p_floor_penalty, floor_penalty),
    season_format       = coalesce(p_season_format, season_format),
    structure           = coalesce(p_structure, structure),
    buyin_cents         = coalesce(p_buyin_cents, buyin_cents),
    season_months       = v_months,
    draft_type          = coalesce(p_draft_type, draft_type),
    finish              = coalesce(p_finish, finish),
    payout_champ        = coalesce(p_payout_champ, payout_champ),
    payout_runnerup     = coalesce(p_payout_runnerup, payout_runnerup),
    payout_king         = coalesce(p_payout_king, payout_king),
    -- R18 · one statement. A season above $0 cannot go live with nowhere to
    -- send the money, because the note lands in the same UPDATE as the stake.
    -- coalesce keeps an existing note when the caller sends none, so a re-lock
    -- (or an old client) never erases what set_buy_in_terms recorded.
    buy_in_note         = coalesce(v_note, buy_in_note),
    locked_at           = now()
  where league_id = p_league
  returning * into v_settings;

  select * into v_season from seasons where league_id = p_league and number = 1;
  if not found then
    insert into seasons (league_id, number, starts_on, ends_on)
    values (p_league, 1, v_starts, v_ends)
    returning * into v_season;
  end if;

  if v_settings.structure <> 'solo' then
    perform form_squads(v_season.id);
  end if;

  v_phase := case when v_settings.structure = 'solo' then 'season' else 'draft' end;

  update leagues
     set phase = v_phase,
         name  = coalesce(nullif(btrim(p_name), ''), name)
   where id = p_league
  returning * into v_league;

  insert into posts (league_id, season_id, kind, body)
  values (p_league, v_season.id, 'system',
          'The rules are set. First tee ' || to_char(v_season.starts_on, 'Dy Mon FMDD')
          || ' · ' || initcap(v_settings.preset)
          || case when v_settings.counting_cap is not null
                  then ' · best ' || v_settings.counting_cap || ' a month.'
                  else ' · every round counts.' end);

  return json_build_object(
    'already_locked', false,
    'phase',  v_phase,
    'season', row_to_json(v_season),
    -- so the client can say the truth on the share screen rather than assume it
    'has_pay_note', (v_settings.buy_in_note is not null));
end $function$;
revoke all on function public.lock_league(p_league uuid, p_name text, p_preset text, p_handicap_allowance integer, p_verification text, p_counting_cap integer, p_participation_floor integer, p_floor_penalty text, p_season_format text, p_structure text, p_buyin_cents integer, p_season_months integer, p_draft_type text, p_finish text, p_payout_champ integer, p_payout_runnerup integer, p_payout_king integer, p_starts_on date, p_ends_on date, p_pay_note text) from public, anon;
grant execute on function public.lock_league(p_league uuid, p_name text, p_preset text, p_handicap_allowance integer, p_verification text, p_counting_cap integer, p_participation_floor integer, p_floor_penalty text, p_season_format text, p_structure text, p_buyin_cents integer, p_season_months integer, p_draft_type text, p_finish text, p_payout_champ integer, p_payout_runnerup integer, p_payout_king integer, p_starts_on date, p_ends_on date, p_pay_note text) to authenticated;

-- ---- form_squads · S-23 -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.form_squads(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; st record; n int; i int;
        names text[] := array['Squad 1','Squad 2','Squad 3','Squad 4'];
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can do that.'; end if;
  if st.structure = 'solo' then return; end if;
  if exists (select 1 from squads where season_id = p_season) then return; end if;

  n := case st.structure when 'squads2' then 2 when 'squads3' then 3 else 4 end;
  for i in 1..n loop
    insert into squads (season_id, name, color) values (p_season, names[i], i-1);
  end loop;
end $function$;
revoke all on function public.form_squads(p_season uuid) from public, anon;
grant execute on function public.form_squads(p_season uuid) to authenticated;

-- ---- assign_player · S-23 -----------------------------------------------------
CREATE OR REPLACE FUNCTION public.assign_player(p_squad uuid, p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record;
begin
  select s.* into se from seasons s
  join squads q on q.season_id = s.id where q.id = p_squad;
  if se.id is null then raise exception 'no such squad'; end if;
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can do that.'; end if;

  -- moving a player: clear any prior seat this season, then seat them
  delete from squad_members sm using squads q
  where q.id = sm.squad_id and q.season_id = se.id and sm.member_id = p_member;
  insert into squad_members (squad_id, member_id) values (p_squad, p_member);

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (se.league_id, my_member_id(se.league_id), 'assign_player',
          jsonb_build_object('squad', p_squad, 'member', p_member));
end $function$;
revoke all on function public.assign_player(p_squad uuid, p_member uuid) from public, anon;
grant execute on function public.assign_player(p_squad uuid, p_member uuid) to authenticated;

-- ---- delete_league · S-23 S-30 ------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_league(p_league uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  lg leagues%rowtype;
  se seasons%rowtype;
begin
  select * into lg from leagues where id = p_league;
  if not found then raise exception 'league not found'; end if;
  if not is_commissioner(p_league) then raise exception 'Only the Pro can do that.'; end if;

  if lg.phase = 'complete' then
    raise exception 'Completed seasons are the record book — they can''t be deleted.';
  elsif lg.phase not in ('setup','draft') then
    select * into se from seasons
     where league_id = p_league order by number desc limit 1;
    -- a season row that has kicked off, or whose first tee has passed, is live
    if found and (se.kicked_off or se.starts_on <= current_date) then
      raise exception 'The season''s under way — a live league can''t be deleted.';
    end if;
  end if;

  delete from leagues where id = p_league;
end $function$;
revoke all on function public.delete_league(p_league uuid) from public, anon;
grant execute on function public.delete_league(p_league uuid) to authenticated;

-- ---- request_league_cancel · S-23 S-30 ----------------------------------------
CREATE OR REPLACE FUNCTION public.request_league_cancel(p_league uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare lg leagues%rowtype; v_money boolean; v uuid := auth.uid(); v_mid uuid;
begin
  select * into lg from leagues where id = p_league;
  if not found then raise exception 'league not found'; end if;
  if not is_commissioner(p_league) then raise exception 'Only the Pro can do that.'; end if;
  if lg.phase = 'complete' then
    raise exception 'Completed seasons are the record book — they can''t be cancelled.';
  end if;

  select (coalesce(buyin_cents,0) > 0) into v_money from league_settings where league_id = p_league;

  if not coalesce(v_money, false) then
    perform cancel_league_now(p_league);          -- free league: Pro-alone
    return 'done';
  end if;

  -- money league: open a fresh request; the Pro's initiation IS their approval
  insert into league_cancellations (league_id, requested_by)
    values (p_league, v)
  on conflict (league_id) do update set requested_by = excluded.requested_by, requested_at = now();
  delete from cancellation_votes where league_id = p_league;
  select id into v_mid from league_members where league_id = p_league and profile_id = v;
  if v_mid is not null then
    insert into cancellation_votes (league_id, member_id) values (p_league, v_mid)
    on conflict do nothing;
  end if;
  -- the Pro may be the ONLY member — their own approval is already unanimous,
  -- so execute inline rather than hang at 1-of-1 forever
  if (select count(*) from league_members   where league_id = p_league)
  <= (select count(*) from cancellation_votes where league_id = p_league) then
    perform cancel_league_now(p_league);
    return 'done';
  end if;
  return 'open';
end $function$;
revoke all on function public.request_league_cancel(p_league uuid) from public, anon;
grant execute on function public.request_league_cancel(p_league uuid) to authenticated;

-- ---- withdraw_league_cancel · S-23 --------------------------------------------
CREATE OR REPLACE FUNCTION public.withdraw_league_cancel(p_league uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not is_commissioner(p_league) then raise exception 'Only the Pro can do that.'; end if;
  delete from cancellation_votes  where league_id = p_league;
  delete from league_cancellations where league_id = p_league;
  return 'withdrawn';
end $function$;
revoke all on function public.withdraw_league_cancel(p_league uuid) from public, anon;
grant execute on function public.withdraw_league_cancel(p_league uuid) to authenticated;

-- ---- vote_league_cancel · S-30 ------------------------------------------------
CREATE OR REPLACE FUNCTION public.vote_league_cancel(p_league uuid, p_approve boolean)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v uuid := auth.uid(); v_mid uuid; n_members int; n_votes int;
begin
  if not is_league_member(p_league) then raise exception 'Not your league.'; end if;
  if not exists (select 1 from league_cancellations where league_id = p_league) then
    raise exception 'Nothing to vote on.';
  end if;
  select id into v_mid from league_members where league_id = p_league and profile_id = v;
  if v_mid is null then raise exception 'Not a member.'; end if;

  if not p_approve then
    delete from cancellation_votes  where league_id = p_league;   -- any decline
    delete from league_cancellations where league_id = p_league;  -- kills it
    return 'declined';
  end if;

  insert into cancellation_votes (league_id, member_id) values (p_league, v_mid)
  on conflict do nothing;
  select count(*) into n_members from league_members  where league_id = p_league;
  select count(*) into n_votes   from cancellation_votes where league_id = p_league;
  if n_votes >= n_members then
    perform cancel_league_now(p_league);          -- unanimous: execute
    return 'done';
  end if;
  return 'pending';
end $function$;
revoke all on function public.vote_league_cancel(p_league uuid, p_approve boolean) from public, anon;
grant execute on function public.vote_league_cancel(p_league uuid, p_approve boolean) to authenticated;

-- ---- league_cancel_status · S-30 ----------------------------------------------
CREATE OR REPLACE FUNCTION public.league_cancel_status(p_league uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v uuid := auth.uid(); v_mid uuid; v_req record;
        n_members int; n_votes int; v_cents int; v_mine boolean;
begin
  if not is_league_member(p_league) then raise exception 'Not your league.'; end if;
  select * into v_req from league_cancellations where league_id = p_league;
  if v_req.league_id is null then return null; end if;   -- no open request

  select id into v_mid from league_members where league_id = p_league and profile_id = v;
  select count(*) into n_members from league_members  where league_id = p_league;
  select count(*) into n_votes   from cancellation_votes where league_id = p_league;
  select exists(select 1 from cancellation_votes where league_id = p_league and member_id = v_mid) into v_mine;
  select coalesce(sum(b.amount_cents),0) into v_cents
    from buy_ins b join seasons s on s.id = b.season_id
   where s.league_id = p_league and b.member_id = v_mid and b.paid;

  return jsonb_build_object(
    'open', true, 'members', n_members, 'approved', n_votes,
    'you_approved', coalesce(v_mine,false), 'you_refund_cents', v_cents,
    'is_pro', is_commissioner(p_league),
    'requested_by_me', v_req.requested_by = v);
end $function$;
revoke all on function public.league_cancel_status(p_league uuid) from public, anon;
grant execute on function public.league_cancel_status(p_league uuid) to authenticated;

-- ---- set_league_marker · S-30 by class ----------------------------------------
CREATE OR REPLACE FUNCTION public.set_league_marker(p_league uuid, p_marker text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if p_marker is not null and length(p_marker) > 24 then
    raise exception 'that is not a marker';
  end if;
  update league_members set marker = nullif(p_marker, '')
   where league_id = p_league and profile_id = auth.uid();
  if not found then raise exception 'Not your league.'; end if;
end $function$;
revoke all on function public.set_league_marker(p_league uuid, p_marker text) from public, anon;
grant execute on function public.set_league_marker(p_league uuid, p_marker text) to authenticated;

-- ---- add_event_player · S-23 S-31 ---------------------------------------------
CREATE OR REPLACE FUNCTION public.add_event_player(p_event uuid, p_profile uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_kind text; v_league uuid; v_exh boolean; v_n int; v_name text;
begin
  if not is_event_organizer(p_event) then
    raise exception 'Only the organizer can do that.';
  end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'Roster locks once a week has been scored';
  end if;

  select kind, league_id into v_kind, v_league from events where id = p_event;

  -- D148: consent. A direct add needs a standing relationship; everyone else
  -- goes through invite_golfer, which asks and can be declined.
  if p_profile <> auth.uid()
     and not (v_league is not null and exists (
                select 1 from league_members lm
                 where lm.league_id = v_league and lm.profile_id = p_profile))
     and not exists (
                select 1 from friendships f
                 where f.status = 'accepted'
                   and ((f.requester = auth.uid() and f.addressee = p_profile)
                     or (f.addressee = auth.uid() and f.requester = p_profile)))
  then
    raise exception 'You can add golfers from this league or your buddies list. For anyone else, send an invite so they can accept.';
  end if;

  v_exh := (v_kind = 'major') and not major_contender(p_profile);

  select coalesce(max(seed), 0) + 1 into v_n from event_players where event_id = p_event;

  insert into event_players (event_id, profile_id, seed, exhibition)
  values (p_event, p_profile, v_n, v_exh)
  on conflict (event_id, profile_id) do nothing
  returning id into v_id;

  if v_id is not null and v_kind = 'major' then
    select display_name into v_name from profiles where id = p_profile;
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event, coalesce(v_name,'A golfer') || ' is in. Field of ' || v_n || '.');
  end if;

  return v_id;
end $function$;
revoke all on function public.add_event_player(p_event uuid, p_profile uuid) from public, anon;
grant execute on function public.add_event_player(p_event uuid, p_profile uuid) to authenticated;

-- ---- set_event_team · S-23 ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_event_team(p_player uuid, p_team uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_event uuid;
begin
  select event_id into v_event from event_players where id = p_player;
  if not is_event_organizer(v_event) then raise exception 'Only the organizer can do that.'; end if;
  update event_players set team_id = p_team where id = p_player;
end $function$;
revoke all on function public.set_event_team(p_player uuid, p_team uuid) from public, anon;
grant execute on function public.set_event_team(p_player uuid, p_team uuid) to authenticated;

-- ---- daily_season_tick · S-28 -------------------------------------------------
CREATE OR REPLACE FUNCTION public.daily_season_tick()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; v_finish text; v_local date; wcr record;
        v_floor integer; v_struct text; v_pen text;
        v_state text; v_msg text;
begin
  -- live rounds die on their own now: 24h after start, an unfinished round is
  -- abandoned — resume and join surfaces go dark server-side, not just client.
  update live_rounds
     set status = 'abandoned', finished_at = coalesce(finished_at, now())
   where status in ('setup', 'live')
     and started_at < now() - interval '24 hours';

  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- D193 · one league's bad day is its own. Every other cron entry point
    -- already isolates per subject; this one ran six live seasons in a single
    -- transaction, so a season that raised rolled back the whole tick and left
    -- no trace in job_failures — the job simply failed. The busiest days of the
    -- year for this loop are 2026-09-07 (five leagues roll their week at once)
    -- and 2026-09-08 (close_season runs on Sunset Match for the first time in
    -- the product's life), which is what made this worth fixing now.
    begin
    -- D204 · the first-tee horn: first tick on/after the first tee, league-
    -- local, once ever (the sentinel is the idempotence, as the original was).
    v_local := (now() at time zone se.timezone)::date;
    if se.status = 'active' and not se.kicked_off and v_local >= se.starts_on then
      update seasons set kicked_off = true where id = se.id;
      select participation_floor, structure, floor_penalty
        into v_floor, v_struct, v_pen
        from league_settings where league_id = se.league_id;
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, se.id, 'system',
              'The season is live. Week 1 — rounds count from here.'
              || case when coalesce(v_floor, 0) > 0 and coalesce(v_struct, 'solo') <> 'solo'
                      then ' Post ' || v_floor || ' round' || case when v_floor = 1 then '' else 's' end
                           || ' a month'
                           || case when v_pen in ('deduct', 'forfeit')
                                   then ' — miss once and your bye covers it.'
                                   else '.' end
                      else '' end);
    end if;

    select finish into v_finish from league_settings where league_id = se.league_id;
    if se.status = 'active' and coalesce(v_finish,'cup_final') = 'cup_final'
       and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;

    -- D108: the weekly clash rides the tick. On the league's local date,
    -- settle every opened clash whose window has fully passed (the week-
    -- rollover detection — settles week N−1 on the increment, and self-heals
    -- across missed ticks and the season's final week), then open the current
    -- week's clash (which is also the first-run catch-up for live seasons).
    v_local := (now() at time zone se.timezone)::date;
    for wcr in
      select wc.week_no from week_clashes wc
       where wc.season_id = se.id and wc.settled_at is null
         and (se.starts_on + 7 * (wc.week_no - 1) + 6) < v_local
       order by wc.week_no
    loop
      perform settle_week_clash(se.id, wcr.week_no);
    end loop;
    perform open_week_clash(se.id);   -- no-ops outside the season / solo leagues
    -- D176 · and on the window's last day, say so. Runs AFTER the open so a
    -- one-week season's clash is opened and called on the same tick.
    perform clash_last_call(se.id);
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
      insert into job_failures (job, subject, sqlstate, message)
      values ('daily_season_tick', 'season ' || se.id::text, v_state, v_msg);
      -- and on to the next league. A season that cannot tick must not stop
      -- anybody else's week from opening.
    end;
  end loop;
end $function$;
revoke all on function public.daily_season_tick() from public, anon, authenticated;   -- engine-only: the tick and the story generators; service_role keeps it, as today

-- ---- set_rivalry_name · S-29 --------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_rivalry_name(p_opponent uuid, p_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_lo   uuid := least(auth.uid(), p_opponent);
  v_hi   uuid := greatest(auth.uid(), p_opponent);
  v_name text := nullif(btrim(coalesce(p_name, '')), '');
begin
  if p_opponent is null or p_opponent = auth.uid() then
    raise exception 'no such rivalry';
  end if;
  -- must have actual head-to-head history (weekly clash or Ryder duel)
  if not exists (select 1 from my_rivalries() where opponent = p_opponent) then
    raise exception 'Name a rivalry once it has history.';
  end if;

  if v_name is null then                 -- clear (the misuse valve)
    delete from rivalry_names where pair_low = v_lo and pair_high = v_hi;
    return;
  end if;
  v_name := left(v_name, 40);

  insert into rivalry_names (pair_low, pair_high, name, named_by)
  values (v_lo, v_hi, v_name, auth.uid())
  on conflict (pair_low, pair_high)
    do update set name = excluded.name, named_by = excluded.named_by, named_at = now();
end $function$;
revoke all on function public.set_rivalry_name(p_opponent uuid, p_name text) from public, anon;
grant execute on function public.set_rivalry_name(p_opponent uuid, p_name text) to authenticated;

-- ---- invite_golfer · S-30 -----------------------------------------------------
CREATE OR REPLACE FUNCTION public.invite_golfer(p_league uuid, p_event uuid, p_profile uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_title text; v_who text;
begin
  if (p_league is null) = (p_event is null) then
    raise exception 'invite to exactly one of a league or an event';
  end if;
  if p_league is not null and not is_commissioner(p_league) then raise exception 'only the Pro invites'; end if;
  if p_event  is not null and not is_event_organizer(p_event) then raise exception 'only the organizer invites'; end if;
  if p_league is not null and exists (select 1 from league_members where league_id=p_league and profile_id=p_profile) then
    raise exception 'They''re already in.';
  end if;
  if p_event is not null and exists (select 1 from event_players where event_id=p_event and profile_id=p_profile) then
    raise exception 'They''re already in.';
  end if;
  -- refresh a prior declined invite back to pending; else insert
  update member_invites set status='pending', invited_by=auth.uid(), created_at=now()
    where profile_id=p_profile and status<>'pending'
      and ((p_league is not null and league_id=p_league) or (p_event is not null and event_id=p_event))
    returning id into v_id;
  if v_id is null then
    insert into member_invites (league_id, event_id, profile_id, invited_by)
      values (p_league, p_event, p_profile, auth.uid())
      on conflict do nothing
      returning id into v_id;
  end if;
  -- D104 · the invitation rings. Title = the container's name (what the lock
  -- screen bolds); body in the tee-sheet voice, first name only.
  if v_id is not null then
    select coalesce(l.name, e.name, 'Cup Season') into v_title
      from (select 1) x
      left join leagues l on l.id = p_league
      left join events  e on e.id = p_event;
    v_who := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'The Pro');
    insert into push_nudges (profile_id, kind, title, body, payload)
    values (p_profile, 'invite', v_title, v_who || ' invited you',
            jsonb_strip_nulls(jsonb_build_object(
              'invite_id', v_id, 'league_id', p_league, 'event_id', p_event)));
  end if;
  return v_id;
end $function$;
revoke all on function public.invite_golfer(p_league uuid, p_event uuid, p_profile uuid) from public, anon;
grant execute on function public.invite_golfer(p_league uuid, p_event uuid, p_profile uuid) to authenticated;

-- ---- set_index · S-30 ---------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_index(p_index numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_old numeric; v_name text; v_auto numeric;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'Index looks off — anywhere from -10 to 54.';
  end if;

  v_auto := handicap_index(auth.uid());
  if v_auto is not null then
    raise exception 'Your number comes from your scores now (%). A starter only helps before 3 posted rounds.', v_auto;
  end if;

  select index_current, display_name into v_old, v_name from profiles where id = auth.uid();
  if not found then raise exception 'no profile'; end if;

  update profiles set index_current = p_index, index_source = 'self' where id = auth.uid();
  if v_old is not distinct from p_index then return; end if;

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || case when v_old is null
           then ' set their index to ' || p_index
           else ' adjusted their index ' || v_old || ' → ' || p_index end
    from league_members lm where lm.profile_id = auth.uid();
end $function$;
revoke all on function public.set_index(p_index numeric) from public, anon;
grant execute on function public.set_index(p_index numeric) to authenticated;

-- ---- set_member_index · S-30 --------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_member_index(p_member uuid, p_index numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league uuid; v_pid uuid; v_name text; v_auto numeric;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'Index looks off — anywhere from -10 to 54.';
  end if;
  select league_id, profile_id into v_league, v_pid from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro sets a starter index'; end if;

  -- behavior B: a starter only helps before the engine can compute a number.
  -- Setting one now would post a board line the next round instantly overrides.
  v_auto := handicap_index(v_pid);
  if v_auto is not null then
    raise exception 'Their number comes from their scores now (%). A starter only helps before 3 posted rounds.', v_auto;
  end if;

  select display_name into v_name from profiles where id = v_pid;
  update profiles set index_current = p_index, index_source = 'self' where id = v_pid;

  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          'The Pro set ' || coalesce(v_name, 'a member') || '''s starter index to ' || p_index);
end $function$;
revoke all on function public.set_member_index(p_member uuid, p_index numeric) from public, anon;
grant execute on function public.set_member_index(p_member uuid, p_index numeric) to authenticated;

-- ---- delete_event · S-31 ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_event(p_event uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v record;
begin
  select id, status, kind, name into v from events where id = p_event;
  if v.id is null then raise exception 'No such event'; end if;
  if not is_event_organizer(p_event) then
    raise exception 'Only the organizer can scrap it';
  end if;
  if v.status = 'complete' then
    raise exception 'That one is in the books — a settled % is history, not a draft',
      case when v.kind = 'major' then 'Major' else 'event' end;
  end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'A week has already been scored — this one stays on the record';
  end if;

  -- explicit: the trophies FK is SET NULL, so these would orphan (see header)
  delete from trophies where event_id = p_event;
  delete from events where id = p_event;
end $function$;
revoke all on function public.delete_event(p_event uuid) from public, anon;
grant execute on function public.delete_event(p_event uuid) to authenticated;

-- ---- delete_account · S-32 ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_account()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  has_footprint boolean;
  v_table text; v_constraint text;
begin
  if v is null then raise exception 'not signed in'; end if;

  if exists (
    select 1 from leagues l
    where l.commissioner_id = v
      and exists (select 1 from league_members m
                  where m.league_id = l.id and m.profile_id <> v)
  ) then
    raise exception 'You run a league with other golfers in it. Hand it off or delete that league first, then delete your account.';
  end if;

  if exists (
    select 1 from events e
    where e.created_by = v
      and exists (select 1 from event_players ep
                  where ep.event_id = e.id and ep.profile_id <> v)
  ) then
    raise exception 'You created a Ryder or a Major with other golfers in it. Delete it first, then delete your account.';
  end if;

  has_footprint :=
       exists (select 1 from rounds where profile_id = v)
    or exists (select 1 from season_adjustments sa join league_members m on m.id = sa.member_id
               where m.profile_id = v)
    or exists (select 1 from draft_picks dp join league_members m on m.id = dp.picked_by
               where m.profile_id = v)
    or exists (select 1 from live_round_players lp join league_members m on m.id = lp.member_id
               where m.profile_id = v
                 and exists (select 1 from live_round_players x
                             where x.live_round_id = lp.live_round_id and x.id <> lp.id));

  -- Every stored object this golfer owns lives under `media/<their id>/…`
  -- (avatars are `<id>/avatar.jpg`; round photos share the folder). One
  -- statement therefore reclaims the avatar AND every scorecard they ever
  -- uploaded — the leak the audit found, on both branches. It runs BEFORE the
  -- hard branch's `delete from auth.users` so that a failure there rolls the
  -- object rows back with everything else.
  delete from storage.objects where bucket_id = 'media' and name like v::text || '/%';

  if not has_footprint then
    begin
      delete from post_comments pc using league_members m
        where pc.member_id = m.id and m.profile_id = v;
      delete from posts p using league_members m
        where p.member_id = m.id and m.profile_id = v;
      delete from live_round_players lp using league_members m
        where lp.member_id = m.id and m.profile_id = v;
      delete from live_rounds lr using league_members m
        where lr.started_by = m.id and m.profile_id = v;
      update live_round_players set claimed_profile = null where claimed_profile = v;
      delete from feedback f using league_members m
        where f.member_id = m.id and m.profile_id = v;
      update squads s set captain_member_id = null
        from league_members m
        where s.captain_member_id = m.id and m.profile_id = v;
      delete from posts        where league_id in (select id from leagues where commissioner_id = v);
      delete from live_rounds  where league_id in (select id from leagues where commissioner_id = v);
      delete from leagues where commissioner_id = v;
      delete from events  where created_by = v;
      delete from member_invites where invited_by = v or profile_id = v;
      update courses set created_by = null where created_by = v;
      delete from device_tokens where profile_id = v;   -- no cascade reaches these
      delete from auth.users where id = v;
      return;
    exception when others then
      get stacked diagnostics v_table = table_name, v_constraint = constraint_name;
      raise exception 'Could not delete your account: something still references it (%.%). Nothing was changed — screenshot this and send it in via Feedback.',
        coalesce(nullif(v_table, ''), 'unknown table'), coalesce(nullif(v_constraint, ''), 'unknown constraint');
    end;
  end if;

  update profiles set
    display_name = 'Former member',
    handle       = null,
    city         = null,
    home_course  = null,
    marker       = null,
    ghin_number  = null,     -- H1b: don't leave a departed member's GHIN readable
    photo_path   = null,     -- the face comes off the roster with the name
    email        = 'deleted+' || v::text || '@cupseason.invalid',
    discoverable = 'nobody',
    deleted_at   = now()
  where id = v;

  delete from push_subscriptions where profile_id = v;   -- web push
  delete from device_tokens      where profile_id = v;   -- APNs: the phone stops

  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $function$;
revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;

-- ---- friend_request · S-34 ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.friend_request(p_profile uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare f record; v_fid uuid; v_who text;
begin
  if p_profile = auth.uid() then raise exception 'That''s you'; end if;
  select * into f from friendships
   where least(requester, addressee)    = least(p_profile, auth.uid())
     and greatest(requester, addressee) = greatest(p_profile, auth.uid());
  if found then
    if f.status = 'accepted' then return 'friend'; end if;
    if f.requester = auth.uid() then return 'requested'; end if;
    -- they asked first — mutual intent, instant buddies
    update friendships set status = 'accepted', responded_at = now() where id = f.id;
    return 'friend';
  end if;
  insert into friendships (requester, addressee) values (auth.uid(), p_profile)
    returning id into v_fid;
  -- D104 · the doorbell, routed: request_id answers Accept/Decline from the
  -- lock screen (CS_REQUEST → friend_respond), profile_id lands Requests.
  v_who := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'A golfer');
  insert into push_nudges (profile_id, kind, title, body, payload)
  values (p_profile, 'request', v_who || ' wants in your crew', 'Their rounds land in your feed',
          jsonb_build_object('request_id', v_fid, 'profile_id', auth.uid()));
  return 'requested';
end $function$;
revoke all on function public.friend_request(p_profile uuid) from public, anon;
grant execute on function public.friend_request(p_profile uuid) to authenticated;

-- ---- season_story · S-35 ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.season_story(p_season uuid DEFAULT NULL::uuid, p_league uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se        record;
  ls        record;
  v_league  text;
  v_solo    boolean;
  v_finish  text;
  v_today   date;
  v_week    int;
  v_weeks   int;
  v_ends    date;
  v_opens   date;
  v_me      uuid;
  v_now     jsonb  := '[]'::jsonb;      -- the table, now
  v_snaps   jsonb  := '[]'::jsonb;      -- every weekly snapshot, ranked
  v_facts   jsonb;
  v_hist    jsonb  := '[]'::jsonb;
  v_arc     jsonb  := '[]'::jsonb;
  v_arch    jsonb  := '[]'::jsonb;
  v_lead    jsonb;
  v_run     int    := 0;
  v_flip    jsonb;
  v_closer  jsonb;
  v_live    int;
  v_scen    jsonb;
  v_riv     record;
  v_opp     uuid;
  v_since   date;
  v_mine    jsonb;
  v_streak  int    := 0;
  v_best    jsonb;
  i         int;
  j         int;
  w         jsonb;
  wprev     jsonb;
  r         jsonb;
begin
  if p_season is not null then
    select * into se from seasons where id = p_season;
  elsif p_league is not null then
    select * into se from seasons where league_id = p_league
     order by (status in ('active', 'cup_final')) desc, starts_on desc limit 1;
  end if;
  if se.id is null then return null; end if;
  if not is_league_member(se.league_id) then raise exception 'not a league member'; end if;

  select * into ls from league_settings where league_id = se.league_id;
  select name into v_league from leagues where id = se.league_id;
  v_solo   := coalesce(ls.structure, 'squads2') = 'solo';
  v_finish := coalesce(ls.finish, 'cup_final');
  v_today  := (now() at time zone coalesce(se.timezone, 'UTC'))::date;
  v_weeks  := greatest(1, ceil((se.ends_on - se.starts_on)::numeric / 7)::int);
  v_week   := greatest(1, least(v_weeks, floor((v_today - se.starts_on)::numeric / 7)::int + 1));
  v_ends   := se.starts_on + (greatest(0, v_today - se.starts_on) / 7) * 7 + 6;
  v_opens  := case when v_finish = 'cup_final' then se.ends_on - 27 else null::date end;
  v_me     := my_member_id(se.league_id);

  -- =========================================================================
  -- THE TABLE, now. One row per rung, with the clause of WHY beside the
  -- number (§7.3): its rank, its run at that rank, its best week, and — for a
  -- solo season — how many of this month's rounds are counting against the cap
  -- (from v_rounds_ranked's own month_rank, never from the participation
  -- floor's credit count, which knows nothing about the cap).
  -- =========================================================================
  if v_solo then
    select coalesce(jsonb_agg(z.r order by (z.r->>'rank')::int), '[]'::jsonb) into v_now from (
      select jsonb_build_object(
               'id',      lm.id,
               'name',    coalesce(p.display_name, 'A golfer'),
               'points',  coalesce(vi.points, 0),
               'rank',    row_number() over (order by coalesce(vi.points, 0) desc, lm.id),
               'rounds',  coalesce(vi.rounds_posted, 0),
               'counted', (select count(*) from v_rounds_ranked rr
                            where rr.member_id = lm.id and rr.season_id = se.id
                              and date_trunc('month', rr.played_on) = date_trunc('month', v_today)
                              and rr.month_rank <= coalesce(ls.counting_cap, 2147483647)),
               'left',    (lm.left_at is not null),
               'is_me',   (lm.id = v_me)) as r
        from v_individual_standings vi
        join league_members lm on lm.id = vi.member_id
        left join profiles p on p.id = lm.profile_id
       where vi.season_id = se.id) z;
  else
    select coalesce(jsonb_agg(z.r order by (z.r->>'rank')::int), '[]'::jsonb) into v_now from (
      select jsonb_build_object(
               'id',      q.id,
               'name',    q.name,
               'points',  coalesce(ss.points, 0),
               'rank',    row_number() over (order by coalesce(ss.points, 0) desc, q.id),
               'rounds',  null::int,
               'counted', null::int,
               'left',    false,
               'is_me',   exists (select 1 from squad_members sm where sm.squad_id = q.id and sm.member_id = v_me)) as r
        from squads q
        left join v_squad_standings ss on ss.squad_id = q.id and ss.season_id = q.season_id
       where q.season_id = se.id) z;
  end if;

  -- =========================================================================
  -- EVERY WEEKLY SNAPSHOT, ranked. This is the season's own history and the
  -- read four of the seven rungs count over. `captured_at` rides along so a
  -- movement clause can name the day it is measured FROM (A-4) — a bare arrow
  -- over a Sunday snapshot lies about time on a Tuesday.
  -- =========================================================================
  select coalesce(jsonb_agg(z.w order by (z.w->>'week')::int), '[]'::jsonb) into v_snaps from (
    select jsonb_build_object(
             'week', ss.week_no,
             'at',   ss.captured_at,
             'rows', (select coalesce(jsonb_agg(jsonb_build_object('id', y.cid, 'points', y.pts, 'rank', y.rk)
                                                order by y.rk), '[]'::jsonb)
                        from (select coalesce(x->>'squad_id', x->>'member_id')::uuid as cid,
                                     coalesce((x->>'points')::numeric, 0) as pts,
                                     row_number() over (order by coalesce((x->>'points')::numeric, 0) desc,
                                                                 coalesce(x->>'squad_id', x->>'member_id')) as rk
                                from jsonb_array_elements(
                                       case when v_solo then coalesce(ss.standings->'individuals', '[]'::jsonb)
                                            else coalesce(ss.standings->'squads', '[]'::jsonb) end) x) y)) as w
      from standings_snapshots ss
     where ss.season_id = se.id) z;

  -- =========================================================================
  -- THE FACTS the ladder reads. Every one is a count or a difference over the
  -- two arrays above, or over a named table. Nothing is a guess ahead.
  -- =========================================================================
  v_lead := v_now->0;

  -- rung 2 · the leader's run: consecutive most-recent snapshot weeks whose
  -- top row is the leader now. `season_lead.since` is the same fact for a
  -- squads season and is carried beside it rather than instead of it.
  if v_lead is not null and jsonb_array_length(v_snaps) > 0 then
    i := jsonb_array_length(v_snaps) - 1;
    while i >= 0 loop
      w := v_snaps->i;
      exit when coalesce(w->'rows'->0->>'id', '') <> coalesce(v_lead->>'id', '-');
      v_run := v_run + 1;
      i := i - 1;
    end loop;
  end if;

  -- rung 1 · the most recent week whose top row changed hands, and whether
  -- the new leader had ever led before it.
  for i in reverse coalesce(jsonb_array_length(v_snaps), 0) - 1 .. 1 loop
    w     := v_snaps->i;
    wprev := v_snaps->(i - 1);
    if coalesce(w->'rows'->0->>'id', '') <> coalesce(wprev->'rows'->0->>'id', '')
       and coalesce(w->'rows'->0->>'id', '') <> '' then
      v_flip := jsonb_build_object(
        'week', (w->>'week')::int,
        'on',   (w->>'at')::timestamptz,
        'to',   (select x->>'name' from jsonb_array_elements(v_now) x
                  where x->>'id' = w->'rows'->0->>'id'),
        'to_id', w->'rows'->0->>'id',
        'from', (select x->>'name' from jsonb_array_elements(v_now) x
                  where x->>'id' = wprev->'rows'->0->>'id'),
        'first_time', not exists (
          select 1 from jsonb_array_elements(v_snaps) s2
           where (s2->>'week')::int < (w->>'week')::int
             and s2->'rows'->0->>'id' = w->'rows'->0->>'id'),
        'source', 'standings_snapshots');
      exit;
    end if;
  end loop;

  -- rung 4 · a rung that has closed at least half its gap to the lead in the
  -- last two snapshot weeks. The figure is the difference of two differences —
  -- both from the same read.
  if jsonb_array_length(v_snaps) >= 3 and v_lead is not null then
    declare
      s_now  jsonb := v_snaps->(jsonb_array_length(v_snaps) - 1);
      s_then jsonb := v_snaps->(jsonb_array_length(v_snaps) - 3);
      lead_now numeric;
      lead_then numeric;
      gap_now numeric;
      gap_then numeric;
      best numeric := 0;
    begin
      lead_now  := coalesce((s_now ->'rows'->0->>'points')::numeric, 0);
      lead_then := coalesce((s_then->'rows'->0->>'points')::numeric, 0);
      for j in 1 .. coalesce(jsonb_array_length(s_now->'rows'), 1) - 1 loop
        r := s_now->'rows'->j;
        gap_now  := lead_now - coalesce((r->>'points')::numeric, 0);
        gap_then := lead_then - coalesce((select (x->>'points')::numeric
                                            from jsonb_array_elements(s_then->'rows') x
                                           where x->>'id' = r->>'id'), 0);
        if gap_then > 0 and gap_now <= gap_then / 2 and (gap_then - gap_now) > best then
          best := gap_then - gap_now;
          v_closer := jsonb_build_object(
            'name',  (select x->>'name' from jsonb_array_elements(v_now) x where x->>'id' = r->>'id'),
            'taken', gap_then - gap_now,
            'weeks', 2,
            'source', 'standings_snapshots');
        end if;
      end loop;
    end;
  end if;

  -- rung 5 · who can still reach the Final. `season_scenarios` owns that
  -- arithmetic; calling it is the difference between one answer and two.
  if v_opens is not null then
    begin
      v_scen := season_scenarios(se.id);
      select count(*) into v_live
        from jsonb_array_elements(coalesce(v_scen->'rows', '[]'::jsonb)) x
       where coalesce((x->>'eliminated')::boolean, false) = false;
    exception when others then
      v_live := null;
    end;
  end if;

  v_facts := jsonb_build_object(
    'week_no',      v_week,
    'weeks_total',  v_weeks,
    'weeks_left',   greatest(0, v_weeks - v_week),
    'week_ends_on', v_ends,
    'field',        coalesce(jsonb_array_length(v_now), 0),
    'leader',       case when v_lead is null then null else jsonb_build_object(
                      'id',        v_lead->>'id',
                      'name',      v_lead->>'name',
                      'points',    (v_lead->>'points')::numeric,
                      'run_weeks', v_run,
                      'since',     (select sl.since from season_lead sl where sl.season_id = se.id),
                      'is_me',     coalesce((v_lead->>'is_me')::boolean, false),
                      'source',    'standings_snapshots') end,
    'runner_up',    case when jsonb_array_length(v_now) < 2 then null else jsonb_build_object(
                      'name',   v_now->1->>'name',
                      'points', (v_now->1->>'points')::numeric) end,
    'top_gap',      case when jsonb_array_length(v_now) < 2 then null
                         else (v_now->0->>'points')::numeric - (v_now->1->>'points')::numeric end,
    'lead_flip',    v_flip,
    'closer',       v_closer,
    'final',        case when v_opens is null then null else jsonb_build_object(
                      'opens_on',   v_opens,
                      'in_weeks',   case when v_opens < v_today then null
                                         else ceil((v_opens - v_today)::numeric / 7)::int end,
                      'seats',      2,
                      'still_live', v_live,
                      'source',     'season_scenarios') end,
    'last_snapshot_on', case when jsonb_array_length(v_snaps) = 0 then null
                             else (v_snaps->(jsonb_array_length(v_snaps) - 1)->>'at')::timestamptz end);

  -- =========================================================================
  -- RUNG 7 · THE REACH BACK (R-H). When nothing has moved this week the
  -- ladder is allowed to look FURTHER BACK — and not one inch further into
  -- invention. Every candidate below is a count over a read named in its own
  -- `source`, the client renders nothing whose source it does not recognise,
  -- and no candidate manufactures a stake: a rivalry that exists is described,
  -- a rivalry that does not is left alone.
  -- =========================================================================
  select x into v_mine from jsonb_array_elements(v_now) x
   where coalesce((x->>'is_me')::boolean, false) limit 1;

  -- 7a · the unsettled week — `week_clashes` for WHEN, `my_rivalries` for the
  -- all-time record. Both are existing reads; neither is re-derived here.
  if v_me is not null then
    begin
      select mr.opponent, mr.display_name, mr.wins, mr.losses, mr.ties, mr.meetings
        into v_riv
        from my_rivalries() mr
        join league_members lm2 on lm2.profile_id = mr.opponent and lm2.league_id = se.league_id
       order by mr.meetings desc, mr.display_name
       limit 1;
      if v_riv.opponent is not null then
        select lm2.id into v_opp from league_members lm2
         where lm2.profile_id = v_riv.opponent and lm2.league_id = se.league_id;
        select max(wc.settled_at)::date into v_since
          from week_clashes wc
          join seasons s2 on s2.id = wc.season_id and s2.league_id = se.league_id
         where wc.settled_at is not null
           and ((wc.a_member = v_me and wc.b_member = v_opp)
             or (wc.b_member = v_me and wc.a_member = v_opp));
        if v_since is not null then
          v_hist := v_hist || jsonb_build_array(jsonb_build_object(
            'kind',     'unsettled_week',
            'source',   'week_clashes',
            'record_source', 'my_rivalries',
            'opponent', v_riv.display_name,
            'since',    v_since,
            'days',     (v_today - v_since),
            'wins',     coalesce(v_riv.wins, 0),
            'losses',   coalesce(v_riv.losses, 0),
            'ties',     coalesce(v_riv.ties, 0)));
        end if;
      end if;
    exception when others then
      null;   -- my_rivalries is not there yet: the rung simply has one fewer candidate
    end;
  end if;

  -- 7b · my own run at my own place, from the same snapshots the table reads.
  if v_mine is not null and jsonb_array_length(v_snaps) >= 2 then
    declare
      my_rank int;
    begin
      select (x->>'rank')::int into my_rank
        from jsonb_array_elements(v_snaps->(jsonb_array_length(v_snaps) - 1)->'rows') x
       where x->>'id' = v_mine->>'id';
      if my_rank is not null then
        i := jsonb_array_length(v_snaps) - 1;
        while i >= 0 loop
          exit when (select (x->>'rank')::int from jsonb_array_elements(v_snaps->i->'rows') x
                      where x->>'id' = v_mine->>'id') is distinct from my_rank;
          v_streak := v_streak + 1;
          i := i - 1;
        end loop;
        if v_streak >= 2 then
          v_hist := v_hist || jsonb_build_array(jsonb_build_object(
            'kind',   'my_run',
            'source', 'standings_snapshots',
            'rank',   my_rank,
            'weeks',  v_streak));
        end if;
      end if;
    end;
  end if;

  -- 7c · my best week of the season — the largest week-over-week gain in the
  -- snapshots. A difference between two rows that exist.
  if v_mine is not null and jsonb_array_length(v_snaps) >= 2 then
    declare
      gain numeric;
      best numeric := 0;
      bw   int;
      prev numeric;
      cur  numeric;
    begin
      for i in 1 .. jsonb_array_length(v_snaps) - 1 loop
        select (x->>'points')::numeric into cur
          from jsonb_array_elements(v_snaps->i->'rows') x where x->>'id' = v_mine->>'id';
        select (x->>'points')::numeric into prev
          from jsonb_array_elements(v_snaps->(i - 1)->'rows') x where x->>'id' = v_mine->>'id';
        gain := coalesce(cur, 0) - coalesce(prev, 0);
        if gain > best then best := gain; bw := (v_snaps->i->>'week')::int; end if;
      end loop;
      if best > 0 then
        v_best := jsonb_build_object('kind', 'my_best_week', 'source', 'standings_snapshots',
                                     'week', bw, 'points', best);
        v_hist := v_hist || jsonb_build_array(v_best);
      end if;
    end;
  end if;

  -- =========================================================================
  -- THE ARC — the season week by week, newest first. Three reads, each row
  -- carrying its own. `posts.body` is the one sentence this function returns
  -- rather than the facts behind it, because the server already wrote it.
  -- =========================================================================
  -- lead changes, from the snapshots
  select coalesce(v_arc || jsonb_agg(z.a order by (z.a->>'week')::int desc), v_arc) into v_arc from (
    select jsonb_build_object(
             'kind',   'lead_change',
             'source', 'standings_snapshots',
             'week',   (s2->>'week')::int,
             'on',     (s2->>'at')::timestamptz,
             'subject', (select x->>'name' from jsonb_array_elements(v_now) x
                          where x->>'id' = s2->'rows'->0->>'id'),
             'other',  (select x->>'name' from jsonb_array_elements(v_now) x
                          where x->>'id' = sp->'rows'->0->>'id')) as a
      from jsonb_array_elements(v_snaps) with ordinality t(s2, o)
      join lateral (select v_snaps->(o::int - 2) as sp) l on true
     where o > 1
       and coalesce(s2->'rows'->0->>'id', '') <> coalesce(l.sp->'rows'->0->>'id', '')
       and coalesce(s2->'rows'->0->>'id', '') <> '') z;

  -- the weeks that were settled, mine among them
  if v_me is not null then
    select coalesce(v_arc || jsonb_agg(z.a order by z.wk desc), v_arc) into v_arc from (
      select wc.week_no as wk, jsonb_build_object(
               'kind',   'clash',
               'source', 'week_clashes',
               'week',   wc.week_no,
               'on',     wc.settled_at,
               'subject', case when wc.winner_member = v_me then 'you'
                               else coalesce((select p.display_name from league_members lm3
                                               join profiles p on p.id = lm3.profile_id
                                              where lm3.id = wc.winner_member), null) end,
               'other',  coalesce((select p.display_name from league_members lm4
                                    join profiles p on p.id = lm4.profile_id
                                   where lm4.id = case when wc.a_member = v_me then wc.b_member else wc.a_member end), 'a golfer in your season'),
               'mine',   true) as a
        from week_clashes wc
       where wc.season_id = se.id and wc.settled_at is not null
         and (wc.a_member = v_me or wc.b_member = v_me)) z;
  end if;

  -- what the season said about itself
  select coalesce(v_arc || jsonb_agg(z.a order by z.at desc), v_arc) into v_arc from (
    select po.created_at as at, jsonb_build_object(
             'kind',   'post',
             'source', 'posts',
             'week',   greatest(1, least(v_weeks, floor((po.created_at::date - se.starts_on)::numeric / 7)::int + 1)),
             'on',     po.created_at,
             'text',   po.body,
             'post_kind', po.kind) as a
      from posts po
     where po.league_id = se.league_id
       and po.kind in ('moment', 'system')
       and po.created_at::date between se.starts_on and se.ends_on
     order by po.created_at desc
     limit 40) z;

  -- one order, newest first
  select coalesce(jsonb_agg(x order by (x->>'on') desc nulls last), '[]'::jsonb) into v_arc
    from jsonb_array_elements(v_arc) x;

  -- =========================================================================
  -- THE ARCHIVE — every season this league has played, browsable. The web
  -- leans on it (R-C: the archive is a thing a desk does and a phone does
  -- not); the phone carries it behind the story page.
  -- =========================================================================
  select coalesce(jsonb_agg(z.a order by z.n desc), '[]'::jsonb) into v_arch from (
    select s3.number as n, jsonb_build_object(
             'season_id',  s3.id,
             'number',     s3.number,
             'starts_on',  s3.starts_on,
             'ends_on',    s3.ends_on,
             'status',     s3.status,
             'champion',   coalesce(
                             (select q.name from squads q where q.id = s3.champion_squad_id),
                             (select p.display_name from league_members lm5
                               join profiles p on p.id = lm5.profile_id
                              where lm5.id = s3.champion_member_id)),
             'is_current', (s3.id = se.id)) as a
      from seasons s3 where s3.league_id = se.league_id) z;

  return jsonb_build_object(
    'season', jsonb_build_object(
      'id',           se.id,
      'league_id',    se.league_id,
      'league',       v_league,
      'number',       se.number,
      'starts_on',    se.starts_on,
      'ends_on',      se.ends_on,
      'status',       se.status,
      'finish',       v_finish,
      'structure',    coalesce(ls.structure, 'squads2'),
      'solo',         v_solo,
      'today',        v_today,
      'my_member_id', v_me,
      'i_left',       (select lm6.left_at is not null from league_members lm6 where lm6.id = v_me)),
    'facts',        v_facts,
    'history',      v_hist,
    'arc',          v_arc,
    'table',        v_now,
    'archive',      v_arch,
    'generated_at', now());
end $function$;
revoke all on function public.season_story(p_season uuid, p_league uuid) from public, anon;
grant execute on function public.season_story(p_season uuid, p_league uuid) to authenticated;

-- ---- add_friend_to_league · S-36 S-37 -----------------------------------------
CREATE OR REPLACE FUNCTION public.add_friend_to_league(p_league uuid, p_profile uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_name text; v_idx numeric; v_member uuid; v_squad text;
begin
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro adds golfers';
  end if;
  -- the probe found the old helper never existed in prod — this is the inline
  -- test the rest of the schema uses (search_golfers, nearby_resolve)
  if not exists (select 1 from friendships f
                  where least(f.requester, f.addressee)    = least(auth.uid(), p_profile)
                    and greatest(f.requester, f.addressee) = greatest(auth.uid(), p_profile)
                    and f.status = 'accepted') then
    raise exception 'Not golf buddies yet — send a request first';
  end if;
  if exists (select 1 from league_members
             where league_id = p_league and profile_id = p_profile) then
    raise exception 'Already in the league';
  end if;
  -- D161 · the Pro vouches, so this door stays open to the halfway turn
  perform _join_gate(p_league, true);

  select display_name, index_current into v_name, v_idx
    from profiles where id = p_profile;

  insert into league_members (league_id, profile_id, role, index_current)
  values (p_league, p_profile, 'player', coalesce(v_idx, 18.0))
  returning id into v_member;

  -- §15 · a joiner after the draw lands on the thinnest squad, and it is said
  v_squad := _late_squad(p_league, v_member);

  insert into posts (league_id, kind, body)
  values (p_league, 'system',
          coalesce(v_name, 'A golfer') || ' is in — the Pro added them.'
          || case when v_squad is not null
                  then ' The thinnest squad takes them: ' || v_squad || '.'
                  else '' end);
end $function$;
revoke all on function public.add_friend_to_league(p_league uuid, p_profile uuid) from public, anon;
grant execute on function public.add_friend_to_league(p_league uuid, p_profile uuid) to authenticated;

-- ---- start_live_round · S-36 --------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_live_round(p_league uuid DEFAULT NULL::uuid, p_course_id uuid DEFAULT NULL::uuid, p_tee_id uuid DEFAULT NULL::uuid, p_course_label text DEFAULT NULL::text, p_snapshot jsonb DEFAULT NULL::jsonb, p_game text DEFAULT NULL::text, p_players jsonb DEFAULT NULL::jsonb, p_config jsonb DEFAULT '{}'::jsonb, p_api_course_id text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_member uuid; v_season uuid; v_lr uuid; v_pos int := 0; v_el jsonb;
  v_code text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  v_who text; v_where text; v_title text; v_body text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_league is not null then
    select id into v_member from league_members where league_id = p_league and profile_id = v;
    if v_member is null then raise exception 'You are not in this league'; end if;
    select id into v_season from seasons
     where league_id = p_league and status in ('active','cup_final')
     order by starts_on desc limit 1;
    if v_season is null then raise exception 'No active season to post into'; end if;
  end if;
  -- D107: without a league, v_member and v_season stay null — the round
  -- belongs to its starter by profile, and there is nothing to post into.

  insert into live_rounds (league_id, season_id, course_id, tee_id, course_label,
                           course_snapshot, game, game_config, status, started_by,
                           starter_profile_id, join_code, api_course_id)
  values (p_league, v_season, p_course_id, p_tee_id,
          coalesce(nullif(trim(p_course_label), ''), 'Course'),
          coalesce(p_snapshot, '{}'::jsonb),
          coalesce(nullif(p_game, ''), 'none'),
          coalesce(p_config, '{}'::jsonb), 'live', v_member, v, v_code,
          nullif(trim(coalesce(p_api_course_id, '')), ''))
  returning id into v_lr;

  for v_el in select * from jsonb_array_elements(coalesce(p_players, '[]'::jsonb)) loop
    if (v_el->>'member_id') is not null then
      if p_league is null then
        raise exception 'No league on this round — seat golfers as guests';
      end if;
      if not exists (
        select 1 from league_members
         where id = (v_el->>'member_id')::uuid and league_id = p_league) then
        raise exception 'A tagged golfer is not in this league';
      end if;
    end if;
    insert into live_round_players (live_round_id, member_id, guest_name, guest_index,
                                    index_source, position, guest_profile_id)
    values (
      v_lr,
      nullif(v_el->>'member_id','')::uuid,
      nullif(trim(coalesce(v_el->>'guest_name','')), ''),
      nullif(v_el->>'guest_index','')::numeric,
      case when (v_el->>'member_id') is not null then 'member'
           when (v_el->>'guest_index') is not null then 'self' else 'estimated' end,
      v_pos,
      -- D88: only meaningful on a guest row; a member row is already identified
      case when (v_el->>'member_id') is null
           then nullif(v_el->>'guest_profile','')::uuid end);
    v_pos := v_pos + 1;
  end loop;

  -- D86/D88 · the invitation. Members by member_id, visitors by
  -- guest_profile_id; never the starter, never an account-less guest (there is
  -- no one to notify — they have a name and nothing else).
  select split_part(coalesce(playerlabel(v), 'Someone'), ' ', 1) into v_who;
  v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');
  v_title := v_who || ' started a live round with you';
  v_body  := 'Live round at ' || v_where || ' — open the app to score it with them';
  -- wave 7 · routed: the phone opens THIS live round (contract §2, `nudge`)
  insert into push_nudges (profile_id, kind, title, body, payload)
  select distinct pr, 'nudge', v_title, v_body,
         jsonb_build_object('live_round_id', v_lr, 'league_id', p_league)
    from (
    select m.profile_id as pr
      from live_round_players p
      join league_members m on m.id = p.member_id
     where p.live_round_id = v_lr and p.member_id is not null
    union
    select p.guest_profile_id
      from live_round_players p
     where p.live_round_id = v_lr and p.guest_profile_id is not null
  ) t where pr is distinct from v;

  return jsonb_build_object('live_round_id', v_lr, 'join_code', v_code, 'players', (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', id, 'member_id', member_id, 'guest_name', guest_name,
             'claim_token', claim_token, 'position', position) order by position), '[]'::jsonb)
      from live_round_players where live_round_id = v_lr));
end $function$;
revoke all on function public.start_live_round(p_league uuid, p_course_id uuid, p_tee_id uuid, p_course_label text, p_snapshot jsonb, p_game text, p_players jsonb, p_config jsonb, p_api_course_id text) from public, anon;
grant execute on function public.start_live_round(p_league uuid, p_course_id uuid, p_tee_id uuid, p_course_label text, p_snapshot jsonb, p_game text, p_players jsonb, p_config jsonb, p_api_course_id text) to authenticated;

-- ---- set_round_rsvp · S-36 by class -------------------------------------------
CREATE OR REPLACE FUNCTION public.set_round_rsvp(p_round uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_owner uuid; v_tagged uuid[];
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_status not in ('in','maybe','out') then raise exception 'bad status'; end if;

  select profile_id, tagged into v_owner, v_tagged
    from scheduled_rounds where id = p_round;
  if v_owner is null then raise exception 'No such round'; end if;

  -- D69: only the host and the players they tagged may RSVP. Visibility is
  -- unchanged (can_see_round still lets league-mates SEE the round) — this
  -- guards the write alone.
  if auth.uid() is distinct from v_owner
     and not (auth.uid() = any(coalesce(v_tagged, '{}'::uuid[]))) then
    raise exception 'Only the host and tagged golfers can RSVP to this round';
  end if;

  insert into round_rsvp (round_id, profile_id, status)
  values (p_round, auth.uid(), p_status)
  on conflict (round_id, profile_id) do update
    set status = excluded.status, updated_at = now();
end $function$;
revoke all on function public.set_round_rsvp(p_round uuid, p_status text) from public, anon;
grant execute on function public.set_round_rsvp(p_round uuid, p_status text) to authenticated;

-- ── the self-check (read-only; raises rather than reporting) ──────────────
-- D296 · every re-created function still has exactly one overload (preflight
-- 34's rule: a new argument list overloads, it does not replace), every one
-- still says the golfer's sentence and none of the retired words, and the
-- grants are exactly what they were — a `create or replace` keeps an ACL, and
-- this block is where that belief gets tested instead of assumed.
do $chk$
declare v_src text; v_n int; v_fn text;
begin
  foreach v_fn in array array['set_profile', 'run_it_back', 'create_forfeit', 'close_season', 'mark_buy_in', 'home_dispatch', 'declare_round', 'retag_round', 'start_season', 'ask_for_a_seat', 'resolve_session', 'generate_pairings', 'create_event', 'join_league', 'respond_invite', 'remove_member', 'randomize_squads', 'enter_major', 'round_major_story', 'sched_major_story', 'settle_major', 'open_major', 'lock_league', 'form_squads', 'assign_player', 'delete_league', 'request_league_cancel', 'withdraw_league_cancel', 'vote_league_cancel', 'league_cancel_status', 'set_league_marker', 'add_event_player', 'set_event_team', 'daily_season_tick', 'set_rivalry_name', 'invite_golfer', 'set_index', 'set_member_index', 'delete_event', 'delete_account', 'friend_request', 'season_story', 'add_friend_to_league', 'start_live_round', 'set_round_rsvp'] loop
    select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = v_fn;
    if v_n <> 1 then raise exception '[D296] % has % overloads — expected exactly one', v_fn, v_n; end if;
    if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = v_fn and has_function_privilege('anon', p.oid, 'execute')) then
      raise exception '[D296] % leaked to anon', v_fn; end if;
    if (v_fn in ('close_season', 'daily_season_tick', 'round_major_story', 'sched_major_story')) = (select has_function_privilege('authenticated', p.oid, 'execute') from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = v_fn) then
      raise exception '[D296] % — its authenticated grant is not what prod held (engine-only stays off the API; everything else stays on)', v_fn; end if;
  end loop;

  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_profile';
  if strpos(v_src, $q$v_old || ' now goes by ' || trim(p_name)$q$) = 0 or strpos(v_src, $q$upper(v_old) || ' NOW GOES BY ' || upper(trim(p_name))$q$) > 0 then raise exception '[D296] set_profile still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'run_it_back';
  if strpos(v_src, $q$'Season ' || v_new.number || ' is on. First tee '$q$) = 0 or strpos(v_src, $q$'SEASON ' || v_new.number || ' IS ON. FIRST TEE '$q$) > 0 then raise exception '[D296] run_it_back still says the old sentence'; end if;
  if strpos(v_src, $q$'That league never started a season.'$q$) = 0 or strpos(v_src, $q$'That league never locked its bylaws.'$q$) > 0 then raise exception '[D296] run_it_back still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'create_forfeit';
  if strpos(v_src, $q$select display_name into v_a$q$) = 0 or strpos(v_src, $q$select upper(display_name) into v_a$q$) > 0 then raise exception '[D296] create_forfeit still says the old sentence'; end if;
  if strpos(v_src, $q$select display_name into v_b$q$) = 0 or strpos(v_src, $q$select upper(display_name) into v_b$q$) > 0 then raise exception '[D296] create_forfeit still says the old sentence'; end if;
  if strpos(v_src, $q$'Forfeit posted: ' || v_name$q$) = 0 or strpos(v_src, $q$'STAKE POSTED: ' || upper(v_name)$q$) > 0 then raise exception '[D296] create_forfeit still says the old sentence'; end if;
  if strpos(v_src, $q$' — ' || v_a || ' v ' || v_b$q$) = 0 or strpos(v_src, $q$' — ' || v_a || ' VS ' || v_b$q$) > 0 then raise exception '[D296] create_forfeit still says the old sentence'; end if;
  if strpos(v_src, $q$' — ' || v_a || ' v the field'$q$) = 0 or strpos(v_src, $q$' — ' || v_a || ' VS THE FIELD'$q$) > 0 then raise exception '[D296] create_forfeit still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the crew can post a forfeit here.'$q$) = 0 or strpos(v_src, $q$'crew only'$q$) > 0 then raise exception '[D296] create_forfeit still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'close_season';
  if strpos(v_src, $q$'. Cup Season keeps the ledger; the money moves between friends.'$q$) = 0 or strpos(v_src, $q$' · settle between yourselves'$q$) > 0 then raise exception '[D296] close_season still says the old sentence'; end if;
  if strpos(v_src, $q$'. Tiebreak: '$q$) = 0 or strpos(v_src, $q$' · tiebreak: '$q$) > 0 then raise exception '[D296] close_season still says the old sentence'; end if;
  if strpos(v_src, $q$'. Points King: '$q$) = 0 or strpos(v_src, $q$' · Points king: '$q$) > 0 then raise exception '[D296] close_season still says the old sentence'; end if;
  if strpos(v_src, $q$            else '' end
    || '.';
  insert into posts$q$) = 0 or strpos(v_src, $q$            else '' end;
  insert into posts$q$) > 0 then raise exception '[D296] close_season still says the old sentence'; end if;
  if strpos(v_src, $q$' — champion $'    || round$q$) = 0 or strpos(v_src, $q$' — champs $'      || round$q$) > 0 then raise exception '[D296] close_season still says the old sentence'; end if;
  if strpos(v_src, $q$' rounds that counted says they kept showing up.'$q$) = 0 or strpos(v_src, $q$' counting rounds says they kept showing up.'$q$) > 0 then raise exception '[D296] close_season still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'mark_buy_in';
  if strpos(v_src, $q$Payouts updated: champion $'$q$) = 0 or strpos(v_src, $q$Payouts updated: champs $'$q$) > 0 then raise exception '[D296] mark_buy_in still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'home_dispatch';
  if strpos(v_src, $q$'The next season starts when you say it does.'$q$) = 0 or strpos(v_src, $q$'Season two starts when you say it does.'$q$) > 0 then raise exception '[D296] home_dispatch still says the old sentence'; end if;
  if strpos(v_src, $q$'The next season starts when '$q$) = 0 or strpos(v_src, $q$'Season two starts when '$q$) > 0 then raise exception '[D296] home_dispatch still says the old sentence'; end if;
  if strpos(v_src, $q$v_in || ' of you in'$q$) = 0 or strpos(v_src, $q$v_in || ' of you on the sheet'$q$) > 0 then raise exception '[D296] home_dispatch still says the old sentence'; end if;
  if strpos(v_src, $q$'Their first posted round.'$q$) = 0 or strpos(v_src, $q$'Their first round on the card.'$q$) > 0 then raise exception '[D296] home_dispatch still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'declare_round';
  if strpos(v_src, $q$' put a round on the schedule — '$q$) = 0 or strpos(v_src, $q$' put a round on the books — '$q$) > 0 then raise exception '[D296] declare_round still says the old sentence'; end if;
  if strpos(v_src, $q$'You can tag buddies and golfers in your seasons.'$q$) = 0 or strpos(v_src, $q$'You can tag buddies and league mates'$q$) > 0 then raise exception '[D296] declare_round still says the old sentence'; end if;
  if strpos(v_src, $q$'Tag up to seven.'$q$) = 0 or strpos(v_src, $q$'Tag up to seven — it is golf, not a scramble league'$q$) > 0 then raise exception '[D296] declare_round still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'retag_round';
  if strpos(v_src, $q$'You can tag buddies and golfers in your seasons.'$q$) = 0 or strpos(v_src, $q$'You can tag buddies and league mates'$q$) > 0 then raise exception '[D296] retag_round still says the old sentence'; end if;
  if strpos(v_src, $q$'Tag up to seven.'$q$) = 0 or strpos(v_src, $q$'Tag up to seven — it is golf, not a scramble league'$q$) > 0 then raise exception '[D296] retag_round still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'start_season';
  if strpos(v_src, $q$'% not on a squad yet — everyone needs one before the first tee'$q$) = 0 or strpos(v_src, $q$'% golfer(s) still in the pool — everyone needs a squad before the first tee'$q$) > 0 then raise exception '[D296] start_season still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'ask_for_a_seat';
  if strpos(v_src, $q$'That round is not on the schedule any more'$q$) = 0 or strpos(v_src, $q$'That round is not on the tee sheet any more'$q$) > 0 then raise exception '[D296] ask_for_a_seat still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'resolve_session';
  if strpos(v_src, $q$' after week '$q$) = 0 or strpos(v_src, $q$' after session '$q$) > 0 then raise exception '[D296] resolve_session still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the organizer can do that.'$q$) = 0 or strpos(v_src, $q$'organizer only'$q$) > 0 then raise exception '[D296] resolve_session still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'generate_pairings';
  if strpos(v_src, $q$'Week ' || v_no || ' is up: '$q$) = 0 or strpos(v_src, $q$'Session ' || v_no || ' is up: '$q$) > 0 then raise exception '[D296] generate_pairings still says the old sentence'; end if;
  if strpos(v_src, $q$'Week ' || v_no || ' is up. '$q$) = 0 or strpos(v_src, $q$'Session ' || v_no || ' is up. '$q$) > 0 then raise exception '[D296] generate_pairings still says the old sentence'; end if;
  if strpos(v_src, $q$' clashes — find yours.'$q$) = 0 or strpos(v_src, $q$' duels on the sheet — find yours.'$q$) > 0 then raise exception '[D296] generate_pairings still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the organizer can do that.'$q$) = 0 or strpos(v_src, $q$'organizer only'$q$) > 0 then raise exception '[D296] generate_pairings still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'create_event';
  if strpos(v_src, $q$'You have to be in that season to run a Ryder with it'$q$) = 0 or strpos(v_src, $q$'you must be in the league to run an event with it'$q$) > 0 then raise exception '[D296] create_event still says the old sentence'; end if;
  if strpos(v_src, $q$'The Ryder starts on a Sunday — each week runs Sun to Sat'$q$) = 0 or strpos(v_src, $q$'The Ryder starts on a Sunday — sessions run Sun to Sat'$q$) > 0 then raise exception '[D296] create_event still says the old sentence'; end if;
  if strpos(v_src, $q$'You can only run back a Ryder you were part of'$q$) = 0 or strpos(v_src, $q$'You can only run back an event you were part of'$q$) > 0 then raise exception '[D296] create_event still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'join_league';
  if strpos(v_src, $q$' is in.'$q$) = 0 or strpos(v_src, $q$' joined the league.'$q$) > 0 then raise exception '[D296] join_league still says the old sentence'; end if;
  if strpos(v_src, $q$'That code didn''t match — check it and try again.'$q$) = 0 or strpos(v_src, $q$'invalid league code'$q$) > 0 then raise exception '[D296] join_league still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'respond_invite';
  if strpos(v_src, $q$' is in.'$q$) = 0 or strpos(v_src, $q$' joined the league.'$q$) > 0 then raise exception '[D296] respond_invite still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'remove_member';
  if strpos(v_src, $q$' is off the roster.'$q$) = 0 or strpos(v_src, $q$' left the league.'$q$) > 0 then raise exception '[D296] remove_member still says the old sentence'; end if;
  if strpos(v_src, $q$'A golfer can only be removed during setup — mid-season, suspend them instead.'$q$) = 0 or strpos(v_src, $q$'Members can only be removed during setup — mid-season tools are coming'$q$) > 0 then raise exception '[D296] remove_member still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the Pro removes golfers'$q$) = 0 or strpos(v_src, $q$'Only the Pro removes members'$q$) > 0 then raise exception '[D296] remove_member still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'randomize_squads';
  if strpos(v_src, $q$'The Pro picks the squads in this league — tap golfers into squads instead of drawing.'$q$) = 0 or strpos(v_src, $q$'This league seats its squads by Pro assign — tap players into squads instead of drawing.'$q$) > 0 then raise exception '[D296] randomize_squads still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the Pro can do that.'$q$) = 0 or strpos(v_src, $q$'commissioner only'$q$) > 0 then raise exception '[D296] randomize_squads still says the old sentence'; end if;
  if strpos(v_src, $q$'No squads yet — set the squads first.'$q$) = 0 or strpos(v_src, $q$'no squads — run form_squads first'$q$) > 0 then raise exception '[D296] randomize_squads still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'enter_major';
  if strpos(v_src, $q$' Doesn''t count this year — official by the next one.'$q$) = 0 or strpos(v_src, $q$' Exhibition for now — official by the next one.'$q$) > 0 then raise exception '[D296] enter_major still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'round_major_story';
  if strpos(v_src, $q$'. Doesn''t count this year.'$q$) = 0 or strpos(v_src, $q$'. Exhibition.'$q$) > 0 then raise exception '[D296] round_major_story still says the old sentence'; end if;
  if strpos(v_src, $q$'. Takes the lead.'$q$) = 0 or strpos(v_src, $q$'. Clubhouse lead.'$q$) > 0 then raise exception '[D296] round_major_story still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'sched_major_story';
  if strpos(v_src, $q$'. First card takes the lead.'$q$) = 0 or strpos(v_src, $q$'. First card takes the clubhouse.'$q$) > 0 then raise exception '[D296] sched_major_story still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'settle_major';
  if strpos(v_src, $q$'Not counting this year: ' || f.display_name$q$) = 0 or strpos(v_src, $q$'Exhibition: ' || f.display_name$q$) > 0 then raise exception '[D296] settle_major still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the organizer can do that.'$q$) = 0 or strpos(v_src, $q$'organizer only'$q$) > 0 then raise exception '[D296] settle_major still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'open_major';
  if strpos(v_src, $q$'Only the organizer can do that.'$q$) = 0 or strpos(v_src, $q$'organizer only'$q$) > 0 then raise exception '[D296] open_major still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'lock_league';
  if strpos(v_src, $q$'The rules are set. First tee '$q$) = 0 or strpos(v_src, $q$'Bylaws locked. First tee '$q$) > 0 then raise exception '[D296] lock_league still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the Pro can start the season.'$q$) = 0 or strpos(v_src, $q$'Only the Pro can lock the bylaws.'$q$) > 0 then raise exception '[D296] lock_league still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'form_squads';
  if strpos(v_src, $q$'Only the Pro can do that.'$q$) = 0 or strpos(v_src, $q$'commissioner only'$q$) > 0 then raise exception '[D296] form_squads still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'assign_player';
  if strpos(v_src, $q$'Only the Pro can do that.'$q$) = 0 or strpos(v_src, $q$'commissioner only'$q$) > 0 then raise exception '[D296] assign_player still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'delete_league';
  if strpos(v_src, $q$'Only the Pro can do that.'$q$) = 0 or strpos(v_src, $q$'commissioner only'$q$) > 0 then raise exception '[D296] delete_league still says the old sentence'; end if;
  if strpos(v_src, $q$'Completed seasons are the record book — they can''t be deleted.'$q$) = 0 or strpos(v_src, $q$'completed seasons are the record book — they cannot be deleted'$q$) > 0 then raise exception '[D296] delete_league still says the old sentence'; end if;
  if strpos(v_src, $q$'The season''s under way — a live league can''t be deleted.'$q$) = 0 or strpos(v_src, $q$'the season is under way — a live league cannot be deleted'$q$) > 0 then raise exception '[D296] delete_league still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'request_league_cancel';
  if strpos(v_src, $q$'Only the Pro can do that.'$q$) = 0 or strpos(v_src, $q$'commissioner only'$q$) > 0 then raise exception '[D296] request_league_cancel still says the old sentence'; end if;
  if strpos(v_src, $q$'Completed seasons are the record book — they can''t be cancelled.'$q$) = 0 or strpos(v_src, $q$'completed seasons are the record book — they cannot be cancelled'$q$) > 0 then raise exception '[D296] request_league_cancel still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'withdraw_league_cancel';
  if strpos(v_src, $q$'Only the Pro can do that.'$q$) = 0 or strpos(v_src, $q$'commissioner only'$q$) > 0 then raise exception '[D296] withdraw_league_cancel still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'vote_league_cancel';
  if strpos(v_src, $q$'Not your league.'$q$) = 0 or strpos(v_src, $q$'not your league'$q$) > 0 then raise exception '[D296] vote_league_cancel still says the old sentence'; end if;
  if strpos(v_src, $q$'Nothing to vote on.'$q$) = 0 or strpos(v_src, $q$'nothing to vote on'$q$) > 0 then raise exception '[D296] vote_league_cancel still says the old sentence'; end if;
  if strpos(v_src, $q$'Not a member.'$q$) = 0 or strpos(v_src, $q$'not a member'$q$) > 0 then raise exception '[D296] vote_league_cancel still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'league_cancel_status';
  if strpos(v_src, $q$'Not your league.'$q$) = 0 or strpos(v_src, $q$'not your league'$q$) > 0 then raise exception '[D296] league_cancel_status still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_league_marker';
  if strpos(v_src, $q$'Not your league.'$q$) = 0 or strpos(v_src, $q$'not your league'$q$) > 0 then raise exception '[D296] set_league_marker still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'add_event_player';
  if strpos(v_src, $q$'Only the organizer can do that.'$q$) = 0 or strpos(v_src, $q$'organizer only'$q$) > 0 then raise exception '[D296] add_event_player still says the old sentence'; end if;
  if strpos(v_src, $q$'Roster locks once a week has been scored'$q$) = 0 or strpos(v_src, $q$'Roster locks once a session has been scored'$q$) > 0 then raise exception '[D296] add_event_player still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_event_team';
  if strpos(v_src, $q$'Only the organizer can do that.'$q$) = 0 or strpos(v_src, $q$'organizer only'$q$) > 0 then raise exception '[D296] set_event_team still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'daily_season_tick';
  if strpos(v_src, $q$'The season is live. Week 1 — rounds count from here.'$q$) = 0 or strpos(v_src, $q$'The season is live. Week 1 — counting rounds start now.'$q$) > 0 then raise exception '[D296] daily_season_tick still says the old sentence'; end if;
  if strpos(v_src, $q$' — miss once and your bye covers it.'$q$) = 0 or strpos(v_src, $q$' — miss once and your season bye covers it.'$q$) > 0 then raise exception '[D296] daily_season_tick still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_rivalry_name';
  if strpos(v_src, $q$'Name a rivalry once it has history.'$q$) = 0 or strpos(v_src, $q$'name a rivalry only once it has history'$q$) > 0 then raise exception '[D296] set_rivalry_name still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'invite_golfer';
  if strpos(v_src, $q$'They''re already in.'$q$) = 0 or strpos(v_src, $q$'already in the league'$q$) > 0 then raise exception '[D296] invite_golfer still says the old sentence'; end if;
  if strpos(v_src, $q$'They''re already in.'$q$) = 0 or strpos(v_src, $q$'already in the event'$q$) > 0 then raise exception '[D296] invite_golfer still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_index';
  if strpos(v_src, $q$'Index looks off — anywhere from -10 to 54.'$q$) = 0 or strpos(v_src, $q$'index out of range'$q$) > 0 then raise exception '[D296] set_index still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_member_index';
  if strpos(v_src, $q$'Index looks off — anywhere from -10 to 54.'$q$) = 0 or strpos(v_src, $q$'index out of range'$q$) > 0 then raise exception '[D296] set_member_index still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'delete_event';
  if strpos(v_src, $q$'Only the organizer can scrap it'$q$) = 0 or strpos(v_src, $q$'Only the organizer can scrap an event'$q$) > 0 then raise exception '[D296] delete_event still says the old sentence'; end if;
  if strpos(v_src, $q$'A week has already been scored — this one stays on the record'$q$) = 0 or strpos(v_src, $q$'A session has already been scored — this one stays on the record'$q$) > 0 then raise exception '[D296] delete_event still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'delete_account';
  if strpos(v_src, $q$'You run a league with other golfers in it. Hand it off or delete that league first, then delete your account.'$q$) = 0 or strpos(v_src, $q$'You run a league with other players in it. Hand it off or delete that league first, then delete your account.'$q$) > 0 then raise exception '[D296] delete_account still says the old sentence'; end if;
  if strpos(v_src, $q$'You created a Ryder or a Major with other golfers in it. Delete it first, then delete your account.'$q$) = 0 or strpos(v_src, $q$'You created an event with other players in it. Delete that event first, then delete your account.'$q$) > 0 then raise exception '[D296] delete_account still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'friend_request';
  if strpos(v_src, $q$'Their rounds land in your feed'$q$) = 0 or strpos(v_src, $q$'Tap to accept'$q$) > 0 then raise exception '[D296] friend_request still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'season_story';
  if strpos(v_src, $q$'a golfer in your season'$q$) = 0 or strpos(v_src, $q$'a league mate'$q$) > 0 then raise exception '[D296] season_story still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'add_friend_to_league';
  if strpos(v_src, $q$'Only the Pro adds golfers'$q$) = 0 or strpos(v_src, $q$'Only the Pro adds players'$q$) > 0 then raise exception '[D296] add_friend_to_league still says the old sentence'; end if;
  if strpos(v_src, $q$' is in — the Pro added them.'$q$) = 0 or strpos(v_src, $q$' is in — the Pro added them. Welcome to the league.'$q$) > 0 then raise exception '[D296] add_friend_to_league still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'start_live_round';
  if strpos(v_src, $q$'A tagged golfer is not in this league'$q$) = 0 or strpos(v_src, $q$'A tagged player is not in this league'$q$) > 0 then raise exception '[D296] start_live_round still says the old sentence'; end if;
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'set_round_rsvp';
  if strpos(v_src, $q$'Only the host and tagged golfers can RSVP to this round'$q$) = 0 or strpos(v_src, $q$'Only the host and tagged players can RSVP to this round'$q$) > 0 then raise exception '[D296] set_round_rsvp still says the old sentence'; end if;
  raise notice '[D296] 45 functions re-created in the golfer''s words; overloads, grants and sentences verified';
end $chk$;

commit;
