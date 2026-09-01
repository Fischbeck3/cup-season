-- ============================================================================
-- D188 · The funnel's middle column, and the crew step that was never measured.
--
-- Two defects, both silent by construction.
--
-- 1. claim_started COULD NEVER BE RECORDED. The client fires it only from the
--    signed-out branch of the claim door, and log_growth_event dropped every
--    anon node that was not link_opened. So the RPC returned void, the
--    v_growth_funnel column stayed zero forever, and nothing complained — the
--    same silent-swallow shape D185 had just diagnosed one node up. The funnel
--    could not show where claim recipients stall, which is the middle of the
--    loop the whole Year-1 plan is a bet on.
--
-- 2. THE 4-OF-23 NUMBER WAS UNMEASURABLE. index.html carries it in a comment:
--    20 of 23 golfers finished a card, only 4 ever reached a league containing
--    another human. That is the product's core retention question and nothing
--    recorded it. crew_reached is added and decided SERVER-SIDE — the client
--    may fire it on every join and once at boot; the server checks the
--    membership itself and dedupes to one row per golfer, ever, which also
--    backfills the existing book on each golfer's next visit (expect a spike
--    in the week this ships; it is history arriving, not a surge).
--
-- Widening an anon-granted endpoint is the security-sensitive half. All five
-- properties that made this the twelfth anon endpoint are preserved: a token is
-- still MANDATORY and must resolve to a real scan_claims / live_round_players
-- row; every path still returns void and never raises, so a made-up token is
-- indistinguishable from a real one and there is no oracle; the <=20 rows per
-- token per hour cap now covers both nodes together; props are still stripped
-- of PII and capped; and anon still holds ZERO relation privileges, so this
-- SECURITY DEFINER remains the only door. Deliberately NOT added: a token-less
-- anon node (a cold-door breadcrumb). The rate limit is keyed on the token, so
-- a null-token node would be an uncapped unauthenticated insert. Cold-door
-- volume belongs in Netlify analytics, not here.
--
-- Body taken verbatim from the live database (pg_get_functiondef) and
-- transformed programmatically, not retyped.
-- ============================================================================

-- the node vocabulary gains crew_reached
alter table public.growth_events drop constraint if exists growth_events_node_check;
alter table public.growth_events add constraint growth_events_node_check
  check (node = any (array['artifact_shared','link_opened','claim_started',
                           'profile_created','crew_reached','first_round_posted']));

CREATE OR REPLACE FUNCTION public.log_growth_event(p_node text, p_kind text DEFAULT NULL::text, p_token text DEFAULT NULL::text, p_props jsonb DEFAULT '{}'::jsonb, p_league uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_uid    uuid := auth.uid();
  v_tok    text := nullif(trim(coalesce(p_token, '')), '');
  v_kind   text := case when p_kind in ('share','claim','join','recap','settlement') then p_kind end;
  v_league uuid := p_league;
  v_props  jsonb;
  v_is_uuid boolean;
begin
  -- unknown node: silent no-op (never an error a probe could read)
  if p_node is null or p_node not in
     ('artifact_shared','link_opened','claim_started','profile_created','crew_reached','first_round_posted') then
    return;
  end if;

  v_is_uuid := v_tok ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

  -- a join code always attributes to its league (both roles)
  if v_kind = 'join' and v_tok is not null and v_league is null then
    select id into v_league from leagues where code = upper(v_tok) limit 1;
  end if;

  if v_uid is null then
    -- Signed-out: a real link being OPENED, and (D188) the claim door being
    -- STARTED on that same real token. claim_started fired only from the
    -- signed-out branch of the client while this dropped every anon node that
    -- was not link_opened, so the column was structurally zero forever and
    -- nothing complained — the same silent swallow D185 diagnosed one node up.
    -- The five properties that made this the twelfth anon endpoint all hold: a
    -- token is still mandatory and must resolve to a real row; every path still
    -- returns void and never raises, so a made-up token is indistinguishable
    -- from a real one and there is no oracle; the rate cap below now covers
    -- both nodes together; props are still stripped; and anon still holds zero
    -- relation privileges — this SECURITY DEFINER is the only door.
    if v_tok is null then return; end if;
    if p_node not in ('link_opened','claim_started') then return; end if;
    if p_node = 'claim_started' and v_kind is distinct from 'claim' then return; end if;
    if v_kind = 'join' then
      if v_league is null then return; end if;
    elsif v_kind = 'claim' then
      if not v_is_uuid then return; end if;
      if not exists (select 1 from scan_claims        where token       = v_tok::uuid)
     and not exists (select 1 from live_round_players where claim_token = v_tok::uuid) then
        return;
      end if;
    elsif v_kind in ('share','recap','settlement') then
      if not v_is_uuid then return; end if;
      if not exists (select 1 from shares where token = v_tok::uuid and not revoked) then return; end if;
    else
      return;   -- anon with no kind: nothing to attribute, nothing to log
    end if;
  else
    -- signed-in: the server decides the facts it can
    if p_node = 'first_round_posted'
       and (select count(*) from rounds where profile_id = v_uid) > 1 then
      return;
    end if;
    -- D188 · crew_reached: the funnel's missing middle. The measured number
    -- this exists to move is 4 of 23 golfers ever reaching a league with
    -- another human in it. The client cannot be trusted to decide it and does
    -- not have to: the server checks the membership itself and dedupes to one
    -- row per golfer, ever, so the client may fire it on every join and at
    -- boot. That also backfills the existing book on each golfer's next visit.
    if p_node = 'crew_reached' then
      if not exists (
        select 1 from league_members me
          join league_members other on other.league_id = me.league_id
                                   and other.profile_id <> me.profile_id
         where me.profile_id = v_uid) then return; end if;
      if exists (select 1 from growth_events
                  where node = 'crew_reached' and actor = v_uid) then return; end if;
    end if;
    if p_node = 'profile_created' and v_kind is not null then
      update profiles
         set came_via_kind = v_kind, came_via_token = v_tok
       where id = v_uid and came_via_kind is null;
    end if;
  end if;

  -- ≤20 rows per token per hour
  if v_tok is not null and (
       select count(*) from growth_events
        where token = v_tok and at > now() - interval '1 hour') >= 20 then
    return;
  end if;

  -- props: never PII, never big
  v_props := coalesce(p_props, '{}'::jsonb);
  if jsonb_typeof(v_props) <> 'object' then v_props := '{}'::jsonb; end if;
  v_props := v_props - 'email' - 'name' - 'handle' - 'display_name' - 'phone';
  if length(v_props::text) > 512 then v_props := '{}'::jsonb; end if;

  insert into growth_events (node, kind, token, league_id, actor, props)
  values (p_node, v_kind, v_tok, v_league, v_uid, v_props);
exception when others then
  -- a breadcrumb never breaks a post, a share, or a door
  return;
end $function$

;

revoke all on function public.log_growth_event(text,text,text,jsonb,uuid) from public;
grant execute on function public.log_growth_event(text,text,text,jsonb,uuid) to anon, authenticated;

-- the funnel reads end to end: shared -> opened -> claim_started -> profile
-- -> crew_reached -> first round
drop view if exists public.v_growth_funnel;
create view public.v_growth_funnel as
  select date_trunc('week', at)::date as week, kind, league_id,
    count(*) filter (where node = 'artifact_shared')    as shared,
    count(*) filter (where node = 'link_opened')        as opened,
    count(*) filter (where node = 'claim_started')      as claim_started,
    count(*) filter (where node = 'profile_created')    as profiles,
    count(*) filter (where node = 'crew_reached')       as crew_reached,
    count(*) filter (where node = 'first_round_posted') as first_rounds
  from growth_events
  group by 1, 2, 3
  order by 1 desc, 2, 3;

-- the funnel is founder-only reading; the API roles never see it
revoke all on public.v_growth_funnel from public, anon, authenticated;

do $chk$
begin
  if position('claim_started' in pg_get_functiondef(
       'public.log_growth_event(text,text,text,jsonb,uuid)'::regprocedure)) = 0
  then raise exception 'D188: log_growth_event cannot record claim_started'; end if;
  if position('crew_reached' in pg_get_functiondef(
       'public.log_growth_event(text,text,text,jsonb,uuid)'::regprocedure)) = 0
  then raise exception 'D188: crew_reached is gone'; end if;
  -- anon must still be unable to read the funnel
  if has_table_privilege('anon', 'public.v_growth_funnel', 'select')
  then raise exception 'D188: anon can read v_growth_funnel'; end if;
end $chk$;
