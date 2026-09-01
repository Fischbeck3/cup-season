-- ============================================================================
-- Cup Season — five hard bounces are scheduled for 2026-09-06
--
-- Found by the merge audit on 2026-09-01 and confirmed in prod the same hour.
-- This one has a date on it.
--
--   league          code      status      ends_on      sandbox
--   Sunset Match    TSTSUN    cup_final   2026-09-05   false
--
-- `daily_season_tick` closes a season past its `ends_on`; `close_season()`
-- fires `seasons_email_on_complete`; that trigger posts to the `season-email`
-- function. `email_queue` has **zero rows, ever** — so this would be the first
-- time in the product's life that the season-recap path runs end to end, and
-- it would run against real Brevo.
--
-- `season_email_payload` skips two address patterns:
--
--     and p.email not like '%@cupseason.invalid'
--     and p.email not like '%@sandbox.cupseason.test'
--
-- The seeded bots in these leagues are `seed+bot0..4@cupseason.test`, which
-- match NEITHER. Five addresses on a reserved TLD would be handed to Brevo on
-- the same account that delivers every sign-in code in this product, six days
-- before the App Store submission target. A bounce rate on a shared sending
-- reputation is the kind of damage you cannot undo inside a week.
--
-- Sunset Match is also the REVIEWER's league. Three more test leagues queue
-- behind it: Ridgeline Cup (2026-12-19), Fairway Society (2027-01-02), Winter
-- Circuit (2027-02-13). So fixing the one season is not the fix.
--
-- THE FIX IS THE RULE, NOT THE LIST. RFC 2606 and RFC 6761 reserve `.test`,
-- `.example`, `.invalid` and `.localhost` precisely so they can never resolve.
-- No deliverable address ends in one, so excluding the class is strictly
-- correct rather than a heuristic — and it cannot drift the way a hand-kept
-- list of two patterns just did. The rule lives in ONE function, for the same
-- reason D187 moved escaping into the helper: a rule copied to two call sites
-- is a rule that will be right in one of them.
-- ============================================================================

create or replace function public.is_undeliverable(p_email text)
returns boolean language sql immutable set search_path = public as $fn$
  select p_email is null
      or btrim(p_email) = ''
      or lower(btrim(p_email)) ~ '\.(test|example|invalid|localhost)$';
$fn$;

revoke all on function public.is_undeliverable(text) from public, anon, authenticated;

-- Both bodies below are prod's own `pg_get_functiondef` output as of
-- 2026-09-01, with ONLY the two filter lines swapped for the helper. Nothing
-- else in either function is touched — they were generated, not retyped.

CREATE OR REPLACE FUNCTION public.season_email_payload(p_season uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se seasons%rowtype; v_league text; v_champ text; v_run text; v_king text;
        v_rows jsonb; v_to jsonb; v_solo boolean; st league_settings%rowtype;
begin
  select * into se from seasons where id = p_season and status = 'complete';
  if se.id is null then return null; end if;
  select name into v_league from leagues where id = se.league_id;
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (coalesce(st.structure,'') = 'solo');

  -- #1: ensure a persisted prefs row (hence a real token) for every member
  -- BEFORE building the list. Idempotent; default recap=true keeps everyone
  -- opted in unless they've turned it off.
  insert into email_prefs (profile_id)
    select lm.profile_id from league_members lm where lm.league_id = se.league_id
  on conflict (profile_id) do nothing;

  if v_solo then
    select p.display_name into v_champ from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.champion_member_id;
    select p.display_name into v_run from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.runnerup_member_id;
  else
    select name into v_champ from squads where id = se.champion_squad_id;
    select name into v_run   from squads where id = se.runnerup_squad_id;
  end if;
  select p.display_name into v_king from league_members lm
    join profiles p on p.id = lm.profile_id where lm.id = se.points_king_member_id;

  if v_solo then
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select p.display_name as name, vi.points from v_individual_standings vi
              join league_members lm on lm.id = vi.member_id
              join profiles p on p.id = lm.profile_id
             where vi.season_id = p_season order by vi.points desc limit 5) q;
  else
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select s.name, vs.points from v_squad_standings vs
              join squads s on s.id = vs.squad_id
             where vs.season_id = p_season order by vs.points desc limit 5) q;
  end if;

  -- recipients: real addresses only, still opted in, with their own money line
  select coalesce(jsonb_agg(jsonb_build_object(
           'email', t.email, 'name', t.display_name,
           'token', t.token, 'cents', t.cents)), '[]'::jsonb)
    into v_to
    from (
      select p.email, p.display_name,
             ep.token,
             coalesce((select sum(sp.cents) from season_payouts sp
                        where sp.season_id = p_season and sp.profile_id = p.id), 0) as cents
        from league_members lm
        join profiles p on p.id = lm.profile_id
        left join email_prefs ep on ep.profile_id = p.id
       where lm.league_id = se.league_id
         and p.email is not null
         and p.email <> ''
         and not is_undeliverable(p.email)
         and coalesce(ep.recap, true)
    ) t;

  return jsonb_build_object(
    'season_id', p_season, 'league', v_league,
    'champion', coalesce(v_champ,'The champion'), 'runner_up', v_run,
    'points_king', v_king,
    'champion_score', se.champion_score, 'runnerup_score', se.runnerup_score,
    'tiebreak', se.tiebreak_rung,
    'starts_on', to_char(se.starts_on,'YYYY-MM-DD'),
    'ends_on',   to_char(se.ends_on,'YYYY-MM-DD'),
    'rows', v_rows, 'recipients', v_to,
    -- D77: v_solo has been computed at the top of this function all along (it
    -- picks squad names vs golfer names above) and was never returned, so the
    -- email could not tell a squad from a person and had to print full legal
    -- names to stay safe. One key, no new query.
    'solo', coalesce(v_solo, false));
end $function$;

CREATE OR REPLACE FUNCTION public.cancel_league_now(p_league uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league text; v_snap jsonb;
begin
  select name into v_league from leagues where id = p_league;

  -- real-address members and each one's own paid buy-in (their refund)
  select coalesce(jsonb_agg(jsonb_build_object(
           'email', t.email, 'name', t.display_name, 'cents', t.cents)), '[]'::jsonb)
    into v_snap
    from (
      select p.email, p.display_name,
             coalesce((select sum(b.amount_cents) from buy_ins b
                        join seasons s on s.id = b.season_id
                       where s.league_id = p_league and b.member_id = lm.id and b.paid), 0) as cents
        from league_members lm
        join profiles p on p.id = lm.profile_id
       where lm.league_id = p_league
         and p.email is not null and p.email <> ''
         and not is_undeliverable(p.email)
    ) t;

  -- a cancellation email only when real money is owed, and never for a sandbox
  if not exists (select 1 from leagues where id = p_league and sandbox)
     and exists (select 1 from jsonb_array_elements(v_snap) e where (e->>'cents')::int > 0) then
    insert into cancellation_notices (payload)
    values (jsonb_build_object('league', coalesce(v_league,'your league'), 'recipients', v_snap));
  end if;

  delete from leagues where id = p_league;   -- cascades everything league-scoped
end $function$;

-- ---- self-enforcing --------------------------------------------------------
do $$
declare bad int;
begin
  if not is_undeliverable('seed+bot0@cupseason.test') then
    raise exception '[email] the reserved-TLD rule does not catch a .test address';
  end if;
  if not is_undeliverable('x@cupseason.invalid') then
    raise exception '[email] the rule no longer catches the .invalid tombstone D189 writes';
  end if;
  if is_undeliverable('jerecho@fischbeck3.com') then
    raise exception '[email] the rule is over-broad — it would silence a real golfer';
  end if;

  select count(*) into bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname in ('season_email_payload','cancel_league_now')
     and p.prosrc like '%sandbox.cupseason.test%';
  if bad > 0 then
    raise exception '[email] % function(s) still carry the hand-kept pattern list', bad;
  end if;
end $$;
