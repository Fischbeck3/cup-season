-- run_it_back(p_league uuid, p_starts_on date, p_ends_on date, p_buyin_cents integer, p_season_months integer, p_pay_note text) oid=35018
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
end $function$

