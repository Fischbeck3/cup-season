-- Cup Season — who was out there (D239, IOS-030).
--
-- C-2 · `round_players(round_id, profile_id, confirmed_at)` — the programme's
-- ONLY new table, and it is born sealed.
--
-- Why a table and not `rounds.played_with uuid[]`: a `rounds` row is never
-- updated (L-02, and `rounds_owner_update` stays dead), and a claim ABOUT
-- ANOTHER PERSON needs a state. `confirmed_at` is that state: null means the
-- tagged golfer has not answered, and the record reads "Galen hasn't
-- confirmed" rather than asserting a meeting nobody agreed to. A tag is never
-- a vouch (L-19) — the receipt says "Played with Galen" and nothing about
-- attestation.
--
-- ITS ACL IS PART OF THE RULING, IN THIS FILE (CC-52 / D221: `pg_default_acl`
-- still grants everything on every new table, so a table left to a reviewer is
-- a table born wide):
--   * revoke all from public, anon
--   * grant select to authenticated — and NO insert, update or delete grant.
--     Writes go only through `post_round` (R11) and, from wave 5,
--     `confirm_round_partner`, both SECURITY DEFINER.
--   * RLS on, read bounded by the Tour-Card predicate (L-37): the round is
--     mine, the row is about me, we are buddies, we share a league, or we
--     share an event.
--   * one line in `tests/db-checks.sql`.
--
-- Nothing reads it yet. Wave 5 builds `confirm_round_partner` and the surfaces;
-- this file exists in wave 2 because `post_round` ships with `p_played_with`
-- in its signature the FIRST time it ships, rather than being dropped and
-- recreated three waves later.

create table if not exists public.round_players (
  round_id     uuid not null references public.rounds(id) on delete cascade,
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  claimed_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now(),
  confirmed_at timestamptz,
  primary key (round_id, profile_id)
);

create index if not exists round_players_profile_idx on public.round_players (profile_id, created_at desc);

comment on table public.round_players is
  'C-2 (D239) · who else was out there for a posted round. A claim with a state: confirmed_at is null until the tagged golfer answers. Written only by post_round and confirm_round_partner; never by a client.';

-- ---------------------------------------------------------------------------
-- the seal, in the same file as the table (CC-52)
-- ---------------------------------------------------------------------------

-- `pg_default_acl` hands `authenticated` arwdDxtm on every new table in this
-- schema, so the revoke has to name authenticated too — revoking from public
-- and anon alone leaves the write grant standing. That is CC-52's whole point,
-- and the self-check below fails the migration if this line is ever dropped.
revoke all on table public.round_players from public;
revoke all on table public.round_players from anon;
revoke all on table public.round_players from authenticated;
grant select on table public.round_players to authenticated;

alter table public.round_players enable row level security;

drop policy if exists round_players_read on public.round_players;
create policy round_players_read on public.round_players
for select to authenticated
using (
  profile_id = auth.uid()
  or exists (select 1 from rounds r where r.id = round_players.round_id and r.profile_id = auth.uid())
  or exists (select 1 from friendships f
              where f.status = 'accepted'
                and ((f.requester = auth.uid() and f.addressee = round_players.profile_id)
                  or (f.addressee = auth.uid() and f.requester = round_players.profile_id)))
  or exists (select 1 from league_members a
               join league_members b on b.league_id = a.league_id
              where a.profile_id = auth.uid() and b.profile_id = round_players.profile_id)
  or exists (select 1 from event_players a
               join event_players b on b.event_id = a.event_id
              where a.profile_id = auth.uid() and b.profile_id = round_players.profile_id)
);

-- ---------------------------------------------------------------------------
-- self-check — catalogue only, no row is written (L-05)
-- ---------------------------------------------------------------------------
do $check$
declare
  v text;
begin
  if to_regclass('public.round_players') is null then
    raise exception 'round_players: the table was not created';
  end if;

  if not (select relrowsecurity from pg_class where oid = 'public.round_players'::regclass) then
    raise exception 'round_players: RLS is off (L-37)';
  end if;

  -- the whole point of CC-52: born sealed, not sealed later
  for v in select unnest(array['INSERT', 'UPDATE', 'DELETE', 'TRUNCATE']) loop
    if has_table_privilege('authenticated', 'public.round_players', v) then
      raise exception 'round_players: authenticated holds % — writes go through post_round only', v;
    end if;
  end loop;
  for v in select unnest(array['SELECT', 'INSERT', 'UPDATE', 'DELETE']) loop
    if has_table_privilege('anon', 'public.round_players', v) then
      raise exception 'round_players: anon holds % (the anon surface stays at twelve)', v;
    end if;
  end loop;
  if not has_table_privilege('authenticated', 'public.round_players', 'SELECT') then
    raise exception 'round_players: authenticated cannot read it';
  end if;
end $check$;
