-- ============================================================================
-- D142 + D143 · the counting cap becomes the quality dial, and the season
--               window stops disagreeing with the bylaw that describes it
--
-- D142 — the season simulation measured, within each league, that season points
-- correlate +0.96 with rounds counted and +0.04 with how well anyone played;
-- rounds-counted was the stronger driver in 61 of 61 leagues. 64% of all rounds
-- land in the bottom two bands, so the best golfer beats the worst by 1.83
-- points a round while one extra round is worth 6.6. The counting cap is the
-- only lever that moves this: the bottom two bands run 47% at cap 2, 64% at
-- cap 4 and 71% at cap 8. The default drops 4 -> 3, which makes a good round
-- matter without making a fourth round worthless. The wizard now offers 3 and
-- names the dial for what it is.
--
-- D143 — season_months was constrained to 3..12 while the REAL length comes from
-- seasons.starts_on/ends_on, and lock_league took both as independent inputs.
-- The client already clamps (`durMonths`, with a comment saying so), so a
-- 2-week season stored "3 months" and nothing complained. Two consequences: a
-- short pilot season could not be described honestly, and a season with no
-- WHOLE calendar month silently never assesses the participation floor.
--
-- The CHECK now allows 1..12, and lock_league makes one of the two
-- authoritative: dates given -> months derived from them; no dates -> end date
-- derived from the months. They can no longer contradict each other.
--
-- Existing leagues are untouched: lock_league is idempotent on locked_at and
-- returns early for anything already locked.
-- ============================================================================

alter table public.league_settings
  drop constraint if exists league_settings_season_months_check;
alter table public.league_settings
  add constraint league_settings_season_months_check
  check (season_months >= 1 and season_months <= 12);

create or replace function public.lock_league(
  p_league            uuid,
  p_name              text    default null,
  p_preset            text    default 'standard',
  p_handicap_allowance int     default 95,
  p_verification      text    default 'attested',
  p_counting_cap      int     default 3,
  p_participation_floor int   default 2,
  p_floor_penalty     text    default 'deduct',
  p_season_format     text    default 'points',
  p_structure         text    default 'squads2',
  p_buyin_cents       int     default 0,
  p_season_months     int     default 6,
  p_draft_type        text    default 'random',
  p_finish            text    default 'cup_final',
  p_payout_champ      int     default 60,
  p_payout_runnerup   int     default 25,
  p_payout_king       int     default 15,
  p_starts_on         date    default null,
  p_ends_on           date    default null
) returns json
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_league   leagues;
  v_settings league_settings;
  v_season   seasons;
  v_phase    text;
  v_starts   date;
  v_ends     date;
  v_months   int;
begin
  select * into v_league from leagues where id = p_league;
  if not found then raise exception 'That league no longer exists.'; end if;

  -- identity at the database, never by hiding a button (D37)
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro can lock the bylaws.';
  end if;

  -- Already locked? Return the standing truth. This is the whole point of the
  -- function: the client can call it again after any ambiguous failure and
  -- learn what actually happened instead of guessing.
  select * into v_settings from league_settings where league_id = p_league;
  if v_settings.locked_at is not null then
    select * into v_season from seasons where league_id = p_league and number = 1;
    return json_build_object(
      'already_locked', true,
      'phase',  v_league.phase,
      'season', row_to_json(v_season));
  end if;

  -- D143 · the season window is the truth; season_months only DESCRIBES it.
  -- The two used to be independent inputs, so a 2-week season stored "3 months"
  -- (the client clamps to the old 3..12 CHECK) and nothing complained. Now one
  -- of them is authoritative: if the caller gives dates, the months are derived
  -- from them; if it does not, the end date is derived from the months. They can
  -- no longer disagree.
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
    locked_at           = now()
  where league_id = p_league
  returning * into v_settings;

  -- season 1, reusing any row a partial lock already created
  select * into v_season from seasons where league_id = p_league and number = 1;
  if not found then
    insert into seasons (league_id, number, starts_on, ends_on)
    values (p_league, 1, v_starts, v_ends)
    returning * into v_season;
  end if;

  -- squads exist from the lock; members join, then the draw fills them.
  -- form_squads is itself idempotent and returns early for solo.
  if v_settings.structure <> 'solo' then
    perform form_squads(v_season.id);
  end if;

  -- The phase comes from the STORED structure, not from what the caller
  -- claimed: a client that mis-sends the structure cannot put the league in a
  -- phase its squads do not match (the §15 violation that reached prod).
  v_phase := case when v_settings.structure = 'solo' then 'season' else 'draft' end;

  update leagues
     set phase = v_phase,
         name  = coalesce(nullif(btrim(p_name), ''), name)
   where id = p_league
  returning * into v_league;

  return json_build_object(
    'already_locked', false,
    'phase',  v_phase,
    'season', row_to_json(v_season));
end $function$;

-- D37: grants are explicit
revoke all on function public.lock_league(uuid, text, text, int, text, int, int, text, text, text, int, int, text, text, int, int, int, date, date) from public, anon;
grant execute on function public.lock_league(uuid, text, text, int, text, int, int, text, text, text, int, int, text, text, int, int, int, date, date) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text; v_def text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'lock_league' and pronamespace = 'public'::regnamespace;
  if position('v_months' in v_src) = 0 then
    raise exception 'D143: lock_league does not derive season_months from the window';
  end if;
  if position('coalesce(p_season_months, season_months)' in v_src) > 0 then
    raise exception 'D143: lock_league still takes season_months as an independent input';
  end if;
  select pg_get_function_arguments(oid) into v_def from pg_proc
   where proname = 'lock_league' and pronamespace = 'public'::regnamespace;
  if position('p_counting_cap integer DEFAULT 3' in v_def) = 0 then
    raise exception 'D142: the counting-cap default is not 3';
  end if;
  -- a one-month season must now be expressible
  if not exists (select 1 from pg_constraint
                  where conname = 'league_settings_season_months_check'
                    and pg_get_constraintdef(oid) like '%>= 1%') then
    raise exception 'D143: season_months still cannot describe a short season';
  end if;
end $chk$;
