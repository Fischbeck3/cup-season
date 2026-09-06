-- Cup Season · wave D — THE GLOSS SAYS PLAYING HCP (D260, IOS-041, R-M)
--
-- The owner retired `your number` as the COMPARISON noun, 2026-09-05: the
-- figure a round is measured against is the index with the league's allowance
-- applied, and *playing handicap* is the real term for exactly that. Under a
-- Standard league's 95 % allowance the two differ by about half a shot, so
-- "over your number" was arithmetic a golfer could catch being wrong.
--
-- THE FIVE BAND LABELS DO NOT MOVE. `band_name(p_pvi)` still returns
-- Torched it / **Beat your number** / Played to it / A little loose / Posted
-- anyway — spec §2.2's own words, and the owner ruled "leave Beat your number
-- for now" (R-M, SETTLED). A settlement post can therefore carry the band
-- "Beat your number" and the phrase "beat their playing HCP by 2.1" in the
-- same breath: one fact wearing two nouns, deliberate, recorded, and NOT a
-- defect. Preflight 42 is what keeps the two sets out of each other.
--
-- WHAT CHANGES HERE: exactly four string literals, inside the ONE live server
-- generator that mints a comparison gloss — `settle_week_clash`'s winner
-- phrase, which becomes the first sentence of a board post and therefore of a
-- push body (`functions/push/index.ts:62-82`). Every other gloss in the
-- product is on a client and is renamed there.
--
-- The body below is `20260902170000_the_clash_stops_repeating_itself.sql`
-- lines 329-471 VERBATIM — copied by script, not by hand, and with only those
-- four literals substituted — because an applied migration is never edited
-- (rule 2 / L-05) and a re-typed 140-line body is how a rule quietly changes.
-- No behaviour moves: same ranking, same walkover rule, same band, same posts.
--
-- Grants: the function is `revoke all ... from public, anon, authenticated`
-- exactly as its predecessor was — it is called by the season tick, never by a
-- client — and the revoke is repeated below because `create or replace` on a
-- function that already exists keeps its ACL, but a first create on a fresh
-- database would not.
--
-- Deploy-skew: none. No signature change, no new argument, no payload key. A
-- client older or newer than this migration reads the same board post.

begin;

create or replace function public.settle_week_clash(p_season uuid, p_week integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  wc       record;
  se       record;
  v_ws     date;                                   -- week window start / end
  v_we     date;
  v_a_best jsonb;
  v_b_best jsonb;
  v_winner uuid;
  v_win_b  jsonb;
  v_name   text;
  v_a_name text;
  v_b_name text;
  v_pvi    numeric;
  v_phrase text;
  v_run    integer;
begin
  select * into wc from week_clashes
   where season_id = p_season and week_no = p_week
   for update;
  if wc.id is null or wc.settled_at is not null then
    return null;                                   -- nothing open here — idempotent
  end if;

  select * into se from seasons where id = p_season;
  v_ws := se.starts_on + 7 * (p_week - 1);
  v_we := v_ws + 6;

  -- each side's best band-of-week: highest-points round in the window. D207:
  -- idle means no round in the window, not no COUNTING round — a golfer who
  -- played is never a walkover, whatever the calendar cap later kept.
  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case cup_points(rr.pvi)
                        when 12 then 'Torched it'
                        when 9  then 'Beat your number'
                        when 7  then 'Played to it'
                        when 6  then 'A little loose'
                        else 'Posted anyway' end)
    into v_a_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case cup_points(rr.pvi)
                        when 12 then 'Torched it'
                        when 9  then 'Beat your number'
                        when 7  then 'Played to it'
                        when 6  then 'A little loose'
                        else 'Posted anyway' end)
    into v_b_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  -- the band decides the W; equal bands are ALL SQUARE (D2: named bands, not
  -- raw differential); one side idle is a walkover W; both idle is quiet.
  if v_a_best is null and v_b_best is null then
    v_winner := null;
  elsif v_b_best is null
     or (v_a_best is not null
         and (v_a_best->>'points')::int > (v_b_best->>'points')::int) then
    v_winner := wc.a_member; v_win_b := v_a_best;
  elsif v_a_best is null
     or (v_b_best->>'points')::int > (v_a_best->>'points')::int then
    v_winner := wc.b_member; v_win_b := v_b_best;
  else
    v_winner := null;                              -- both posted, same band
  end if;

  update week_clashes
     set settled_at = now(), winner_member = v_winner,
         a_best = v_a_best, b_best = v_b_best
   where id = wc.id;

  select p.display_name into v_a_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.a_member;
  select p.display_name into v_b_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.b_member;

  if v_winner is not null then
    v_name := case when v_winner = wc.a_member then v_a_name else v_b_name end;
    v_pvi  := (v_win_b->>'pvi')::numeric;
    v_phrase := case cup_points(v_pvi)
      when 12 then 'beat their playing HCP by ' || to_char(v_pvi, 'FM990.0')
      when 9  then 'beat their playing HCP by ' || to_char(v_pvi, 'FM990.0')
      when 7  then 'played to their playing HCP'
      else to_char(abs(v_pvi), 'FM990.0') || ' over their playing HCP' end;
    insert into posts (league_id, season_id, kind, round_id, body)
    values (se.league_id, p_season, 'system', (v_win_b->>'round_id')::uuid,
            firstname(v_name) || ' took the week — ' || v_phrase
            || ' on ' || to_char((v_win_b->>'played_on')::date, 'FMDay') || '.');

    -- #23 · rivalry heat. The settlement headline above stays furniture; this
    -- is prose, so it is natural case. True run length, so it fires ONCE at
    -- three and once at five — never every week thereafter.
    with hist as (
      select wc2.winner_member,
             row_number() over (order by wc2.week_no desc) as rn
        from week_clashes wc2
       where wc2.season_id = p_season and wc2.settled_at is not null
         and (wc2.a_member = v_winner or wc2.b_member = v_winner)
    )
    select coalesce(min(h.rn) - 1, (select count(*) from hist))
      into v_run
      from hist h
     where h.winner_member is distinct from v_winner;
    if v_run = 3 then
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, p_season, 'moment',
              'Three clashes in a row to ' || firstname(v_name)
              || '. This is becoming a problem.');
    elsif v_run = 5 then
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, p_season, 'moment',
              'Five straight for ' || firstname(v_name) || '. Annoyingly good.');
    end if;
  elsif v_a_best is not null or v_b_best is not null then
    -- D176 · the week ended; say what happened to it, don't re-announce it
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system', 'All square in the clash. Nothing settled.');
  end if;
  -- both idle: row settled above, no post (D52's honesty rule).

  return jsonb_build_object(
    'week', p_week, 'winner_member', v_winner,
    'a_best', v_a_best, 'b_best', v_b_best);
end $function$;

revoke all on function public.settle_week_clash(uuid, integer) from public, anon, authenticated;

commit;
