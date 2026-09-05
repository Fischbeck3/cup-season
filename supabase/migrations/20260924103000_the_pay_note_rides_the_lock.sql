-- ============================================================================
-- D225 (R18) · The pay note rides the lock — publishing stays one transaction
--
-- D225 rules the Pro's payment note REQUIRED AT PUBLISH. Two facts made that
-- unbuildable as drafted:
--
--   1. `set_buy_in_terms(p_league, p_note, p_due_on)` exists (contract.psv:258)
--      and has ZERO call sites on the phone — grep over apps/ios finds it only
--      in the generated Rpc.swift. The web calls it at index.html:6310. So on
--      the shipping client a Pro literally cannot record how to pay, which is
--      the fact two persona walks hit and could not get past.
--   2. `lock_league` has no note parameter, and L-41 requires formation to be
--      ONE transaction. Calling lock_league and then set_buy_in_terms as two
--      taps' worth of network means a season can go live with a stake and no
--      way to pay it — which is the exact state D129's owe line then has to
--      describe, with nowhere to point.
--
-- So: `p_pay_note text default null` is the nineteenth argument, written into
-- league_settings IN THE SAME STATEMENT as every other bylaw. Defaulted and
-- skew-safe (CLAUDE.md:77-80): the eighteen-argument function stays exactly
-- where it is, so a client that has not shipped locks a season the way it does
-- today, and a client that HAS shipped against a database that has not takes
-- PGRST202 and names the miss on screen rather than dropping the note.
--
-- `set_buy_in_terms` survives untouched as the after-the-fact edit and finally
-- gets its phone call site on the pot section.
-- ============================================================================

create or replace function public.lock_league(p_league uuid, p_name text default null::text, p_preset text default 'standard'::text, p_handicap_allowance integer default 95, p_verification text default 'attested'::text, p_counting_cap integer default 3, p_participation_floor integer default 2, p_floor_penalty text default 'deduct'::text, p_season_format text default 'points'::text, p_structure text default 'squads2'::text, p_buyin_cents integer default 0, p_season_months integer default 6, p_draft_type text default 'random'::text, p_finish text default 'cup_final'::text, p_payout_champ integer default 60, p_payout_runnerup integer default 25, p_payout_king integer default 15, p_starts_on date default null::date, p_ends_on date default null::date, p_pay_note text default null::text)
returns json
language plpgsql
security definer
set search_path = public
as $function$
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
    raise exception 'Only the Pro can lock the bylaws.';
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
          'Bylaws locked. First tee ' || to_char(v_season.starts_on, 'Dy Mon FMDD')
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

revoke all on function public.lock_league(uuid, text, text, integer, text, integer, integer, text, text, text, integer, integer, text, text, integer, integer, integer, date, date, text) from public, anon;
grant execute on function public.lock_league(uuid, text, text, integer, text, integer, integer, text, text, text, integer, integer, text, text, integer, integer, integer, date, date, text) to authenticated;

-- ── self-check (L-05: read-only, never mutates a real row) ─────────────────
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname='lock_league' and pronamespace='public'::regnamespace and pronargs=20;
  if v_src is null then raise exception 'R18: lock_league(20) is missing'; end if;
  if position('buy_in_note         = coalesce(v_note, buy_in_note)' in v_src) = 0 then
    raise exception 'R18: the pay note does not ride the lock''s own UPDATE — publishing is no longer one transaction (L-41)';
  end if;

  -- the 19-arg shape survives, or every build in the field stops locking
  if not exists (select 1 from pg_proc
                  where proname='lock_league' and pronamespace='public'::regnamespace and pronargs=19) then
    raise exception 'R18: the 19-argument lock_league was dropped — deploy skew would take every shipped client down';
  end if;

  if has_function_privilege('anon','public.lock_league(uuid,text,text,integer,text,integer,integer,text,text,text,integer,integer,text,text,integer,integer,integer,date,date,text)','execute') then
    raise exception 'R18: lock_league is reachable by anon';
  end if;
  if not has_function_privilege('authenticated','public.lock_league(uuid,text,text,integer,text,integer,integer,text,text,text,integer,integer,text,text,integer,integer,integer,date,date,text)','execute') then
    raise exception 'R18: lock_league is not granted to authenticated';
  end if;
end $chk$;
