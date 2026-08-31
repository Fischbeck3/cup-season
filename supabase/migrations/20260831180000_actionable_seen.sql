-- D179 · the badge means UNSEEN (owner ruling).
--
-- `actionable_count_of` counted pending friendships + pending invites + open
-- live rounds with no notion of whether the golfer had ever LOOKED at them, so
-- the number stayed until you acted. Meanwhile `docs/ios/push-contract.md` §4
-- has said all along:
--
--     "Seeing the list clears it — acting is not required."
--
-- and three call sites quote that line in their comments. The SQL said
-- "unanswered"; the contract said "unseen"; nobody could tell, because prod
-- holds exactly ONE push-registered device. TestFlight is when devices start
-- existing, so the two are reconciled now, in the contract's favour.
--
-- WHY unseen: a badge you cannot clear by looking is one people learn to
-- ignore, and an ignored badge misses the next real thing. The open loop does
-- not disappear — the request still sits on Home and on the buddies screen,
-- where it is a row with two buttons. Only the app-icon nag stands down.
--
-- ONE timestamp, not three. The badge is one number over three sources, and
-- the contract's own clause is coarse in exactly the same way ("Requests,
-- Invites, or the live round"). Three columns would let the number disagree
-- with itself.

alter table public.profiles
  add column if not exists actionable_seen_at timestamptz;

comment on column public.profiles.actionable_seen_at is
  'D179 · when this golfer last SAW their actionable list. actionable_count_of counts only items newer than this. Null = never looked, so everything counts.';

-- The column seal (D37 / migration 20260721214500) FROZE the grant list on
-- profiles: a new column with no grant makes every select naming it fail 42501
-- with a message that never names the column. Nothing selects this one today,
-- which is exactly how that landmine detonates weeks later.
grant select (actionable_seen_at) on public.profiles to authenticated;

-- ---- the count, now scoped to what has not been seen ------------------------
create or replace function public.actionable_count_of(p_profile uuid)
returns integer
language sql
stable
security definer
set search_path to 'public'
as $function$
  with seen as (
    -- null seen_at = never looked: -infinity makes every row count
    select coalesce((select actionable_seen_at from profiles where id = p_profile),
                    '-infinity'::timestamptz) as at
  )
  select (
      (select count(*) from friendships, seen
        where addressee = p_profile and status = 'pending'
          and friendships.created_at > seen.at)
    + (select count(*) from member_invites, seen
        where profile_id = p_profile and status = 'pending'
          and member_invites.created_at > seen.at)
    + (select count(*) from live_rounds lr, seen
        where lr.status in ('setup', 'live')
          and lr.started_at > seen.at
          and exists (select 1 from live_round_players p
                        left join league_members m on m.id = p.member_id
                       where p.live_round_id = lr.id
                         and (m.profile_id = p_profile or p.guest_profile_id = p_profile)))
  )::integer;
$function$;

revoke all on function public.actionable_count_of(uuid) from public, anon, authenticated;
grant execute on function public.actionable_count_of(uuid) to service_role;

-- ---- "I have seen the list" -------------------------------------------------
-- Returns the count AFTER marking, so the phone gets both in one round trip and
-- can never paint a number the server has already superseded.
create or replace function public.mark_actionable_seen()
returns integer
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then return 0; end if;
  update profiles set actionable_seen_at = now() where id = v_uid;
  return actionable_count_of(v_uid);
end $function$;

revoke execute on function public.mark_actionable_seen() from public, anon;
grant execute on function public.mark_actionable_seen() to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_uid uuid; v_before int; v_after int; v_other uuid;
begin
  -- the contract sentence must be true of the SQL now
  if (select pg_get_functiondef(oid) from pg_proc where proname = 'actionable_count_of')
     not like '%actionable_seen_at%' then
    raise exception 'D179: actionable_count_of does not consult actionable_seen_at';
  end if;

  -- D37: the marker is the golfer's own, the counter stays service-only
  if not has_function_privilege('authenticated', 'public.mark_actionable_seen()', 'execute') then
    raise exception 'D37: mark_actionable_seen is not executable by authenticated';
  end if;
  if has_function_privilege('anon', 'public.mark_actionable_seen()', 'execute')
     or has_function_privilege('authenticated', 'public.actionable_count_of(uuid)', 'execute') then
    raise exception 'D37: a badge function is reachable by the wrong role';
  end if;
  if not has_column_privilege('authenticated', 'public.profiles'::regclass, 'actionable_seen_at', 'select') then
    raise exception 'D179: actionable_seen_at is unreadable — the profiles column seal bites';
  end if;

  -- BEHAVIOURAL: someone with a pending request counts it, stops counting it
  -- once seen, and counts a NEWER one again. Asserted, not assumed.
  select f.addressee into v_uid from friendships f
   where f.status = 'pending' limit 1;
  if v_uid is not null then
    update profiles set actionable_seen_at = null where id = v_uid;
    v_before := actionable_count_of(v_uid);
    update profiles set actionable_seen_at = now() where id = v_uid;
    v_after := actionable_count_of(v_uid);
    if not (v_before > 0 and v_after = 0) then
      raise exception 'D179: seen_at did not clear the count (% -> %)', v_before, v_after;
    end if;

    -- a request that arrives AFTER the look must come back
    select p.id into v_other from profiles p
     where p.id <> v_uid and p.deleted_at is null
       and not exists (select 1 from friendships f2
                        where (f2.requester = p.id and f2.addressee = v_uid)
                           or (f2.addressee = p.id and f2.requester = v_uid))
     limit 1;
    if v_other is not null then
      insert into friendships (requester, addressee, status, created_at)
      values (v_other, v_uid, 'pending', now() + interval '1 second');
      if actionable_count_of(v_uid) <> 1 then
        raise exception 'D179: a request newer than the look did not re-raise the badge';
      end if;
      delete from friendships where requester = v_other and addressee = v_uid;
    end if;
    update profiles set actionable_seen_at = null where id = v_uid;
  else
    raise notice 'D179: no pending friendship in this database — behavioural check skipped';
  end if;
end $chk$;
