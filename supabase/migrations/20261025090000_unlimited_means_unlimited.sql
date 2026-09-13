-- Cup Season - Unlimited means unlimited (D347).
--
-- `lock_league` wrote `counting_cap = coalesce(p_counting_cap, counting_cap)`.
-- `counting_cap` is `null or between 1 and 31` (D206), so NULL is the ONLY
-- representation of Unlimited - and coalesce turned that NULL into "keep
-- whatever is already stored". A Pro whose unlocked league already carried a
-- cap could accept an agreement reading "All eligible rounds" and start a
-- season that counts the best four.
--
-- REPRODUCED on an isolated cluster before this was written: a league with a
-- stored cap of 4, locked with p_counting_cap => NULL, still read 4 after.
--
-- WHY THIS IS NOT A CONTRACT CHANGE. The parameter's DEFAULT is 3, not null,
-- so a caller that omits it always received 3 and still does. The only
-- behaviour that changes is an EXPLICIT null, and both shipped clients send an
-- explicit null for exactly one reason: the golfer chose Unlimited
-- (`WizardLockCall` passes `d.capN`, nil at the top of the ladder; the web
-- sends the same). No old client is broken, because no old client ever wanted
-- the old meaning.
--
-- SAME SIGNATURE, so this is a plain create-or-replace and NOT a second
-- overload. Adding a parameter here would make every existing caller fail
-- `is not unique` - proven on PostgreSQL 17 and recorded in
-- docs/reviews/2026-09-12-after-golf-contract-review.md section 1.
--
-- The other dials keep their coalesce on purpose: none of them uses null as a
-- meaningful value. `participation_floor` sends 0 for "no minimum", not null.

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
    -- D347 · the argument is taken LITERALLY. `coalesce` made an explicit
    -- NULL mean "keep what is stored", but NULL is the only way this schema
    -- can say Unlimited (CHECK: null or 1..31), so a Pro who chose Unlimited
    -- silently kept the stored cap. The parameter DEFAULTS to 3, so a caller
    -- that omits it is unaffected: only an explicit NULL changes meaning, and
    -- every client that sends one already means Unlimited.
    counting_cap        = p_counting_cap,
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

-- -- a read-only self-check (it writes nothing; D215) --------------------------
do $chk$
declare
  v_def text := pg_get_functiondef('public.lock_league(uuid,text,text,integer,text,integer,integer,text,text,text,integer,integer,text,text,integer,integer,integer,date,date,text)'::regprocedure);
begin
  if position('counting_cap        = coalesce(p_counting_cap' in v_def) > 0 then
    raise exception 'D347: lock_league still coalesces the counting cap';
  end if;
  if position('participation_floor = coalesce(p_participation_floor' in v_def) = 0 then
    raise exception 'D347: the floor coalesce was disturbed - only the cap should change';
  end if;
  if (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
       where n.nspname = 'public' and p.proname = 'lock_league') <> 1 then
    raise exception 'D347: lock_league is not unique - an overload was created';
  end if;
end
$chk$;
