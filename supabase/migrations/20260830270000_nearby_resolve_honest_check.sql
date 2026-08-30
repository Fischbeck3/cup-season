-- D156 correction · the header of 20260830250000 claimed something untrue, and
-- its self-check could not tell.
--
-- That migration's comment says both new functions are "held to the SAME
-- disclosure envelope as `search_golfers` … under the SAME `discoverable`
-- gate". `recent_partners` is. `nearby_resolve` is NOT — it has no
-- `discoverable` clause at all (verified in prod: position('discoverable' in
-- prosrc) = 0).
--
-- The BEHAVIOUR is right and is not being changed. `discoverable` governs
-- whether a STRANGER can find you by search; `nearby_resolve` only ever returns
-- an accepted friend or a league mate — people who already see your name on a
-- roster or a buddy list. Applying the search gate would make a golfer who set
-- "findable by nobody" invisible to their own buddy standing on the same tee,
-- which is not what that setting means.
--
-- What was wrong is the CLAIM, and the check that was supposed to defend it.
-- The old check asserted only that the strings 'friendships' and
-- 'league_members' appear in the source — it would pass a version that named a
-- hidden profile, or one that named a total stranger, as long as those words
-- were somewhere in the text. CLAUDE.md's own lesson, in its own words: "a
-- grant assertion in this file is worth nothing until something fails on it."
--
-- So this migration changes NO function. It replaces a string-matching check
-- with a BEHAVIOURAL one: impersonate a real profile, hand `nearby_resolve` the
-- id of someone who is neither their friend nor their league mate, and require
-- zero rows back. That is the actual invariant D156 promised.

do $chk$
declare
  v_me     uuid;
  v_alien  uuid;
  v_rows   int;
  v_src    text;
begin
  -- the claim this file exists to correct, asserted so it cannot silently flip
  select prosrc into v_src from pg_proc
   where proname = 'nearby_resolve' and pronamespace = 'public'::regnamespace;
  if v_src is null then
    raise exception 'D156: nearby_resolve is missing';
  end if;
  if position('friendships' in v_src) = 0 or position('league_members' in v_src) = 0 then
    raise exception 'D156: nearby_resolve lost the friend/league-mate predicate';
  end if;

  -- pick any profile, then a profile that is provably NOT connected to it
  select id into v_me from profiles where deleted_at is null order by created_at limit 1;
  if v_me is null then
    raise notice 'D156: no profiles to probe with — behavioural check skipped';
    return;
  end if;

  select p.id into v_alien
    from profiles p
   where p.id <> v_me
     and p.deleted_at is null
     and not exists (
       select 1 from friendships f
        where least(f.requester, f.addressee)    = least(p.id, v_me)
          and greatest(f.requester, f.addressee) = greatest(p.id, v_me)
          and f.status = 'accepted')
     and not exists (
       select 1 from league_members a
         join league_members b on b.league_id = a.league_id
        where a.profile_id = p.id and b.profile_id = v_me)
   limit 1;

  if v_alien is null then
    raise notice 'D156: every profile is connected to the probe account — skipped';
    return;
  end if;

  -- become that golfer and ask for the stranger BY ID (the caller always holds
  -- the uuid — that is the threat model; the function must still say nothing)
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_me, 'role', 'authenticated')::text, true);
  select count(*) into v_rows from public.nearby_resolve(array[v_alien]);
  perform set_config('request.jwt.claims', null, true);

  if v_rows <> 0 then
    raise exception 'D156 VIOLATED: nearby_resolve named a stranger (% rows for an unconnected profile)', v_rows;
  end if;
end $chk$;

-- and correct the record on the function itself, where the next reader looks
comment on function public.nearby_resolve(uuid[]) is
  'D156 · resolves profile ids handed over a local Bluetooth session to names, '
  'ONLY for accepted friends and league mates. Deliberately NOT gated on '
  '`discoverable`: that setting governs stranger search, and everyone this can '
  'return already sees the caller''s name. Behavioural check in 20260830270000.';

comment on function public.recent_partners(int) is
  'D154 · golfers you have shared a live round with, most recent first. Same '
  'columns and the same `discoverable` gate as search_golfers, for a strictly '
  'narrower set of people.';
