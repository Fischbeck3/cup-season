-- D161 (ruled: option A) · the join window — the code closes at first tee,
-- the Pro's door stays open to the halfway turn.
--
-- The principle, in the owner's words: "things like this should be set early
-- with money on the line." A covenant is consent to fixed terms (D112), and
-- once the season is running the roster is one of those terms — so nobody
-- SELF-joins a race that has started. But a league is a human thing, and the
-- Pro vouching for a straggler at week 2 is not a stranger with a leaked code:
-- the two doors get different rules.
--
--   the CODE (join_league)            lock → first tee, then it stops working
--   the PRO (add_friend_to_league,    lock → the season's halfway turn
--            respond_invite)
--   after halfway                     the roster is the roster; the tee sheet
--                                     (D107) stays open to everyone
--
-- What a late joiner gets, so the door is governed rather than merely open:
--   · their join-month floor is WAIVED (close_month skips a member whose
--     joined_at falls inside the month being closed — the partial-month
--     blanket rule, §14.0, applied to a partial member-month)
--   · in a squad league they land on the THINNEST squad, announced (§15)
--
-- Also D112 as ruled 2026-08-29: setup refuses ("the Pro is still locking in
-- the rules"), complete refuses ("ask the Pro to run it back") — on all three
-- paths. league_members.joined_at already exists with real data (default
-- now(), 0 nulls of 47), so no backfill is needed anywhere.
--
-- Amends spec §15: "mid-season joins until halfway" is now BY THE PRO ONLY;
-- §14.1's floor proration becomes the simpler join-month waiver. Every body
-- below is the LIVE definition with the guards added (CLAUDE.md rule 2) —
-- except one repair found by the behavioural probe: the live
-- add_friend_to_league calls are_friends(uuid, uuid), A FUNCTION THAT DOES NOT
-- EXIST in prod (only friend_request / friend_respond / my_friends do). Every
-- call has raised "function does not exist" since it shipped; the Pro's adds
-- that worked went through the invite flow instead. The check becomes the
-- inline friendships test the rest of the schema uses.

-- ---- the shared guard -------------------------------------------------------
-- One reader for "where does this league stand", so three functions cannot
-- drift. INTERNAL: revoked from everyone; only the definers below call it.
create or replace function public._join_gate(p_league uuid, p_via_pro boolean)
returns void
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v_phase text; v_name text;
  v_starts date; v_ends date; v_tz text;
  v_today date; v_half date;
begin
  select phase, name into v_phase, v_name from leagues where id = p_league;
  if v_phase = 'setup' then
    raise exception '% isn''t open yet — the Pro is still locking in the rules. Try again once they have.', coalesce(v_name, 'That league');
  end if;
  if v_phase = 'complete' then
    raise exception 'That season is finished — ask the Pro to run it back.';
  end if;

  select s.starts_on, s.ends_on, coalesce(s.timezone, 'America/Phoenix')
    into v_starts, v_ends, v_tz
    from seasons s
   where s.league_id = p_league and s.status in ('active', 'cup_final')
   order by s.starts_on desc limit 1;
  if v_starts is null then return; end if;   -- no live season: the open window

  v_today := (now() at time zone v_tz)::date;
  if v_today < v_starts then return; end if;  -- before first tee: open to all

  if not p_via_pro then
    raise exception 'The season''s underway — ask the Pro to add you. You''re welcome on the tee sheet meanwhile.';
  end if;

  v_half := v_starts + ((v_ends - v_starts) / 2);
  if v_today > v_half then
    raise exception 'Past the halfway turn — the roster''s set for this season. They''re welcome on the tee sheet, and in the next one the moment you run it back.';
  end if;
end $fn$;

revoke all on function public._join_gate(uuid, boolean) from public, anon, authenticated;

-- ---- the late-squad rule (§15: thinnest squad, logged) ----------------------
-- Returns the squad's name when it seated someone, null when the league has no
-- drawn squads (solo, or pre-draw). INTERNAL like the gate.
create or replace function public._late_squad(p_league uuid, p_member uuid)
returns text
language plpgsql
security definer
set search_path = public
as $fn$
declare v_season uuid; v_squad uuid; v_name text;
begin
  select s.id into v_season from seasons s
   where s.league_id = p_league and s.status in ('active', 'cup_final')
   order by s.starts_on desc limit 1;
  if v_season is null then return null; end if;

  select sq.id, sq.name into v_squad, v_name
    from squads sq
    left join squad_members sm on sm.squad_id = sq.id
   where sq.season_id = v_season
   group by sq.id, sq.name
   order by count(sm.member_id) asc, sq.name
   limit 1;
  if v_squad is null then return null; end if;

  insert into squad_members (squad_id, member_id) values (v_squad, p_member)
  on conflict do nothing;
  return v_name;
end $fn$;

revoke all on function public._late_squad(uuid, uuid) from public, anon, authenticated;

-- ---- join_league: the code door ---------------------------------------------
create or replace function public.join_league(p_code text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v_league uuid; v_new uuid; v_name text;
begin
  select id into v_league from leagues where upper(code) = upper(p_code);
  if not found then raise exception 'invalid league code'; end if;
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
      values (v_league, 'system', upper(coalesce(v_name,'A golfer')) || ' JOINED THE LEAGUE');
  end if;
  return v_league;
end $function$;

-- ---- add_friend_to_league: the Pro's door -----------------------------------
create or replace function public.add_friend_to_league(p_league uuid, p_profile uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare v_name text; v_idx numeric; v_member uuid; v_squad text;
begin
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro adds players';
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
          upper(coalesce(v_name, 'A GOLFER')) || ' WAS ADDED BY THE PRO — WELCOME TO THE LEAGUE'
          || case when v_squad is not null
                  then '. THE THINNEST SQUAD TAKES THEM: ' || upper(v_squad)
                  else '' end);
end $function$;

-- ---- respond_invite: an invite is the Pro's door too ------------------------
create or replace function public.respond_invite(p_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
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
                  upper(coalesce(v_name,'A golfer')) || ' JOINED THE LEAGUE'
                  || case when v_squad is not null
                          then '. THE THINNEST SQUAD TAKES THEM: ' || upper(v_squad)
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

-- ---- join_covenant_info: the door can say "not open yet" before the OTP -----
create or replace function public.join_covenant_info(p_code text)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'name',        l.name,
    'buyin_cents', coalesce(ls.buyin_cents, 0),
    'preset',      ls.preset,
    'floor',       ls.participation_floor,
    'finish',      coalesce(ls.finish, 'cup_final'),
    'structure',   ls.structure,
    -- D129, fail-closed: a boolean and a date, never the note itself
    'has_pay_note', (ls.buy_in_note is not null),
    'buy_in_due_on', ls.buy_in_due_on,
    -- D161/D112 · so the door can say where the league stands before the OTP
    'phase',       l.phase)
  from leagues l
  join league_settings ls on ls.league_id = l.id
  where upper(l.code) = upper(p_code)
  limit 1;
$function$;

-- ---- close_month: the join-month floor is waived ----------------------------
-- One WHERE clause added to the floor loop, nothing else. The live body's own
-- comment style kept: a member whose joined_at falls inside the month being
-- closed was only there for part of it — the partial-month blanket rule
-- (§14.0, "floors are waived in partial edge months") applied to a partial
-- MEMBER-month. Their floor bites from their first full month.
do $patch$
declare v_def text;
begin
  select pg_get_functiondef(oid) into v_def from pg_proc
   where proname = 'close_month' and pronamespace = 'public'::regnamespace;

  v_def := replace(v_def,
    $old$      -- a bye already booked for THIS month (Pro pre-grant) skips the member
      where not exists (select 1 from season_adjustments b
                        where b.season_id = p_season and b.member_id = sm.member_id
                          and b.month = p_month and b.kind = 'bye')$old$,
    $new$      -- a bye already booked for THIS month (Pro pre-grant) skips the member
      where not exists (select 1 from season_adjustments b
                        where b.season_id = p_season and b.member_id = sm.member_id
                          and b.month = p_month and b.kind = 'bye')
        -- D161 · a member who JOINED during this month was only there for part
        -- of it — the partial-month rule, applied per member. No penalty, no
        -- bye spent; the floor bites from their first full month.
        and not exists (select 1 from league_members lm
                        where lm.id = sm.member_id
                          and date_trunc('month',
                                (lm.joined_at at time zone coalesce(se.timezone,'America/Phoenix')))::date
                              = p_month)$new$);

  if position('D161' in v_def) = 0 then
    raise exception 'D161: close_month floor loop did not match — the live body moved';
  end if;
  execute v_def;
end $patch$;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'join_league' and pronamespace = 'public'::regnamespace;
  if position('_join_gate' in v_src) = 0 then
    raise exception 'D161: join_league lost its gate';
  end if;

  select prosrc into v_src from pg_proc
   where proname = 'add_friend_to_league' and pronamespace = 'public'::regnamespace;
  if position('_join_gate' in v_src) = 0 or position('_late_squad' in v_src) = 0 then
    raise exception 'D161: add_friend_to_league lost its gate or the thinnest-squad rule';
  end if;
  if position('Only the Pro adds players' in v_src) = 0
     or position('Not golf buddies yet' in v_src) = 0 then
    raise exception 'D161: add_friend_to_league built on the wrong body';
  end if;
  if position('are_friends' in v_src) > 0 then
    raise exception 'D161: add_friend_to_league calls are_friends again — that function does not exist';
  end if;

  select prosrc into v_src from pg_proc
   where proname = 'respond_invite' and pronamespace = 'public'::regnamespace;
  if position('_join_gate' in v_src) = 0 or position('event_players' in v_src) = 0 then
    raise exception 'D161: respond_invite lost its gate or its event branch';
  end if;

  select prosrc into v_src from pg_proc
   where proname = 'join_covenant_info' and pronamespace = 'public'::regnamespace;
  if position('''phase''' in v_src) = 0 or position('has_pay_note' in v_src) = 0 then
    raise exception 'D161: join_covenant_info lost phase or D129''s fail-closed fields';
  end if;

  select prosrc into v_src from pg_proc
   where proname = 'close_month' and pronamespace = 'public'::regnamespace;
  if position('joined_at' in v_src) = 0 then
    raise exception 'D161: close_month no longer waives the join month';
  end if;
  if position('Auto-bye' in v_src) = 0 then
    raise exception 'D161: close_month rebuilt on the wrong body — the auto-bye is gone';
  end if;

  -- D37 · the internal pair must be reachable by nobody
  if has_function_privilege('anon', 'public._join_gate(uuid, boolean)', 'execute')
     or has_function_privilege('authenticated', 'public._join_gate(uuid, boolean)', 'execute')
     or has_function_privilege('authenticated', 'public._late_squad(uuid, uuid)', 'execute') then
    raise exception 'D37: _join_gate/_late_squad are internal only';
  end if;
  -- and the public three keep their grants
  if not has_function_privilege('authenticated', 'public.join_league(text)', 'execute')
     or not has_function_privilege('authenticated', 'public.add_friend_to_league(uuid, uuid)', 'execute')
     or not has_function_privilege('authenticated', 'public.respond_invite(uuid, boolean)', 'execute') then
    raise exception 'D37: a join path lost its authenticated grant';
  end if;
end $chk$;
