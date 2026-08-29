-- D111 · The lock is one server transaction — `lock_league`
--
-- Why this exists (blind UX audit, 2026-08-29, TOP-1). Locking the bylaws was
-- four separate client writes: league_settings.update (bylaws + locked_at) →
-- seasons.insert → form_squads() → leagues.update(phase). Any failure between
-- them left a league half-locked, and a client-side exception AFTER the writes
-- had committed told the Pro "Lock failed" about a league that was live. That
-- exact shape ran in production for 25 days (one lock_ok all-time against
-- eleven lock_fail) and left `Desert Dogs` in prod as structure=squads2 /
-- phase=season / two empty squads / one member — a state spec §15 forbids.
--
-- The fix is not a better catch block. Four writes that must all happen are
-- one transaction, and it belongs on the server where the identity check
-- already lives (CLAUDE.md: "writes with game consequences go through
-- security-definer RPCs, never direct inserts").
--
-- Idempotent on locked_at: a retap (or a client retry after a dropped
-- response) returns the SAME season and phase rather than minting a second
-- season or re-forming squads. That is what makes the client's recovery path
-- safe — it can call again without inventing state.
--
-- Deploy skew (CLAUDE.md): every parameter is defaulted, so an older client
-- calling the new function still works, and a newer client calling an older
-- database still falls back to its four writes until this lands. `finish` is
-- accepted but tolerated as null for the same reason.

create or replace function public.lock_league(
  p_league            uuid,
  p_name              text    default null,
  p_preset            text    default 'standard',
  p_handicap_allowance int     default 95,
  p_verification      text    default 'attested',
  p_counting_cap      int     default 4,
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
    season_months       = coalesce(p_season_months, season_months),
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
    values (p_league, 1,
            coalesce(p_starts_on, current_date),
            coalesce(p_ends_on, current_date + 182))
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

-- D37: grants are explicit, and every new function revokes the ambient ones
-- first (a function created after the default-privilege flip can still pick up
-- PUBLIC execute — the flip binds to the postgres role, and not every migration
-- runner is it).
revoke all on function public.lock_league(uuid, text, text, int, text, int, int, text, text, text, int, int, text, text, int, int, int, date, date) from public, anon;
grant execute on function public.lock_league(uuid, text, text, int, text, int, int, text, text, text, int, int, text, text, int, int, int, date, date) to authenticated;
