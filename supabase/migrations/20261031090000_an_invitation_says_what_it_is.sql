-- D356 · an invitation says what it is, and what it costs.
--
-- `my_invites` returned `kind` as `league` | `event` and nothing else about an
-- event: not whether it is a Ryder or a Major, and not the buy-in a Major can
-- carry (`events.buy_in`, 20260720193000). Both clients therefore titled every
-- event invitation "Ryder invite" and accepted a Major with a stake in one tap
-- with the money never shown — the same L-12 hole D351 closed for leagues,
-- one door over.
--
-- Two columns, both read straight off `events`: `event_kind` (the event's own
-- `kind`; null for a league invitation) and `buy_in` (the event's stake in
-- dollars, as stored; null for a league). Nothing is inferred and no money is
-- handled here — the Major's pot machinery is untouched; this only lets the
-- invitation door SAY the number before the tap. A `returns table` function
-- cannot grow a column under `create or replace`, so this is DROP + CREATE with
-- the same zero-argument signature; the ACL is discarded by the drop and
-- restated below. Every existing column, its order and its meaning are
-- unchanged. `native_home` embeds `to_jsonb(i)` of these rows verbatim, so the
-- Home invitation item carries the two keys with no change of its own.
-- Not deployed by this change.

drop function if exists public.my_invites();

create function public.my_invites()
returns table(id uuid, kind text, container_id uuid, container_name text,
              inviter text, starts_on date, created_at timestamptz,
              event_kind text, buy_in numeric)
language sql stable security definer set search_path = public as $$
  select mi.id,
    case when mi.league_id is not null then 'league' else 'event' end,
    coalesce(mi.league_id, mi.event_id),
    coalesce(l.name, e.name),
    p.display_name,
    e.starts_on,
    mi.created_at,
    e.kind,
    e.buy_in
  from member_invites mi
  left join leagues  l on l.id = mi.league_id
  left join events   e on e.id = mi.event_id
  left join profiles p on p.id = mi.invited_by
  where mi.profile_id = auth.uid() and mi.status = 'pending'
  order by mi.created_at desc;
$$;

revoke all on function public.my_invites() from public, anon;
grant execute on function public.my_invites() to authenticated;

-- Read-only self-check. Raises rather than reporting success.
do $check$
declare n int; v_cols text;
begin
  select count(*) into n from pg_proc
   where proname = 'my_invites' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'D356: my_invites must resolve to exactly one function, found %', n; end if;
  select pg_get_function_result(oid) into v_cols from pg_proc
   where proname = 'my_invites' and pronamespace = 'public'::regnamespace;
  if position('event_kind text' in v_cols) = 0 or position('buy_in numeric' in v_cols) = 0 then
    raise exception 'D356: my_invites is missing a new column: %', v_cols;
  end if;
  if position('kind text, container_id uuid, container_name text, inviter text, starts_on date, created_at timestamp' in v_cols) = 0 then
    raise exception 'D356: my_invites lost or reordered an existing column: %', v_cols;
  end if;
  if has_function_privilege('anon', 'public.my_invites()', 'execute') then
    raise exception 'D356: anon must not execute my_invites';
  end if;
  if not has_function_privilege('authenticated', 'public.my_invites()', 'execute') then
    raise exception 'D356: authenticated lost my_invites in the drop';
  end if;
end $check$;
