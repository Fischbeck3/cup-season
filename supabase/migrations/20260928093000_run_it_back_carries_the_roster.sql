-- R10 · D243 · Run it back carries the roster.
--
-- THE DEFECT. "Run it back" on both clients opens the WIZARD with last
-- season's bylaws carried in and a "· S2" name — which mints a NEW `leagues`
-- row and a NEW code, so every member has to be re-invited and re-type a code
-- to play the season they already agreed to. Worse, the card is shown to every
-- member, not only the Pro, so a member who taps it is silently made the
-- founder of a different league with the same name.
--
-- WHAT SEASON 2 ACTUALLY IS. A second `seasons` row under the SAME `leagues`
-- row. Everything else the object model already has: `league_members` is per
-- LEAGUE (not per season), `v_rounds_ranked` fans a round into whichever
-- season's window holds it, and the standings, the pot and the story all key
-- on `season_id`.
--
-- ONE CORRECTION TO D243's OWN TEXT, MADE HERE RATHER THAN DISCOVERED LATER.
-- The entry says the RPC "clones `league_settings`". It does not, because
-- `league_settings.league_id` is the PRIMARY KEY — there is exactly one row per
-- league and every season reads it. Carrying the terms forward is therefore the
-- DEFAULT and the work is the opposite one: applying only what the Pro changed,
-- and noticing when that change is one the crew has to be told about.
--
-- THE COVENANT (L-12). If the stake or the length moved, the crew agreed to
-- different terms from the ones now in force. Every living member but the Pro
-- gets a PENDING `member_invites` row, which is the covenant's existing carrier
-- on both clients (the invite banner's primary control is "See the terms"), and
-- the board post names what changed. It is a NOTICE with an accept, not a gate:
-- a member is not un-seated, because un-seating them would erase last season's
-- rounds from everyone else's standings — the exact harm D244's forward-only
-- `left_at` exists to avoid — and D243's own tradeoff already names D244 as the
-- exit for a member who does not want back in.
--
-- L-03: this is a definer RPC, not a client insert. L-04: the grant and the
-- revoke are in this file. CLAUDE.md:77-80: every argument but the league
-- DEFAULTS, so a client that ships before the database still calls it.

create or replace function public.run_it_back(
  p_league        uuid,
  p_starts_on     date    default null,
  p_ends_on       date    default null,
  p_buyin_cents   int     default null,
  p_season_months int     default null,
  p_pay_note      text    default null
) returns json
language plpgsql
security definer
set search_path = public
as $fn$
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
  if not found then raise exception 'That league never locked its bylaws.'; end if;

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
          'SEASON ' || v_new.number || ' IS ON. FIRST TEE '
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
end $fn$;

revoke all on function public.run_it_back(uuid, date, date, int, int, text) from public, anon;
grant execute on function public.run_it_back(uuid, date, date, int, int, text) to authenticated;

-- ---------------------------------------------------------------------------
-- self-check (L-05 · read-only; nothing below mutates a real row)
-- ---------------------------------------------------------------------------
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'run_it_back' and pronamespace = 'public'::regnamespace;
  if v_src is null then raise exception 'R10: run_it_back is missing'; end if;

  if position('is_commissioner' in v_src) = 0 then
    raise exception 'R10: a member could run it back and become a founder — the whole defect D243 names';
  end if;
  if position('member_invites' in v_src) = 0 then
    raise exception 'R10: a changed stake or length no longer fires the covenant (L-12)';
  end if;
  -- the season must be minted under the SAME league. A `create_league` here
  -- would be the old mechanic wearing the new name.
  if position('insert into seasons' in v_src) = 0 or position('create_league' in v_src) > 0 then
    raise exception 'R10: season 2 must be a seasons row under the same league';
  end if;
  -- and nobody may be un-seated: a delete from league_members would erase last
  -- season's rounds from everyone else's standings
  if v_src ~* 'delete\s+from\s+league_members' then
    raise exception 'R10: run_it_back must never un-seat a member (D244 is the exit)';
  end if;

  if has_function_privilege('anon', 'public.run_it_back(uuid,date,date,int,int,text)', 'execute') then
    raise exception 'D37/L-04: run_it_back is authenticated-only';
  end if;
  if not has_function_privilege('authenticated', 'public.run_it_back(uuid,date,date,int,int,text)', 'execute') then
    raise exception 'L-04: run_it_back has no grant — every call would be 42501';
  end if;
end $chk$;
