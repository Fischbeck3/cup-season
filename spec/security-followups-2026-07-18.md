# Security follow-ups — reviewed SQL, deferred from the 2026-07-18 hardening

These items from `spec/launch-audit-2026-07-18.md` were NOT put in the two
hardening migrations because they touch live-scoring flows or are product calls,
not pure security fixes. Each is written and reviewed — apply as a new migration
when you've decided/tested. They matter before OPEN signup, not for the friends
pilot.

## M4 · Foursome-scope live-round writes (not league-wide)
Today any league member can rewrite another group's in-progress scores. Restrict
writes to the round's participants + starter. **Test a live round after applying**
— this touches the actively-used scoring path.
```sql
-- replace the FOR ALL policies with league-read + participant-write.
-- (names/columns: verify against the live_round_players / live_rounds schema first)
drop policy if exists "lives_all"  on public.live_scores;
create policy "lives_read" on public.live_scores for select to authenticated
  using (exists (select 1 from live_rounds lr
                 where lr.id = live_scores.live_round_id and is_league_member(lr.league_id)));
create policy "lives_write" on public.live_scores for all to authenticated
  using (exists (select 1 from live_round_players p join league_members m on m.id = p.member_id
                 where p.live_round_id = live_scores.live_round_id and m.profile_id = auth.uid()))
  with check (exists (select 1 from live_round_players p join league_members m on m.id = p.member_id
                 where p.live_round_id = live_scores.live_round_id and m.profile_id = auth.uid()));
-- repeat the pattern for game_results (gamer_all) and live_round_players (livep_all).
```

## M5 · Event-roster consent
`add_event_player` lets an organizer add any profile with no relationship,
granting them tour-card/feed visibility. Gate it: require an accepted friendship
or a shared league before a direct add; otherwise route through `member_invites`.
Needs a `create or replace` of `add_event_player` (final body in
`20260716150000_ryder_v2_gaps.sql`) with a guard like:
```sql
if not (exists (select 1 from league_members a join league_members b
                on a.league_id=b.league_id
                where a.profile_id=auth.uid() and b.profile_id=p_profile)
     or exists (select 1 from friendships where status='accepted'
                and ((requester=auth.uid() and addressee=p_profile)
                  or (requester=p_profile and addressee=auth.uid()))))
then raise exception 'Add players you share a league or friendship with, or send an invite'; end if;
```

## M6 · Join surface — PRODUCT CALL, not a pure security fix
`join_league` has no phase gate, so someone can join mid-season/complete leagues.
**This may be intended** (late joiners). Decide the product rule first. Security
parts worth doing regardless: generate league codes server-side in
`create_league` (8+ chars from `gen_random_bytes`) instead of accepting a
client-chosen code, and add a simple attempt ledger on `league_by_code`/`join_league`.

## one-squad-per-season enforcement
The `squad_members_one_per_season` index is misnamed and enforces nothing (a
`make_pick` over a pre-assigned roster can double-seat, double-counting standings).
Cleanest fix — denormalize the season and make it real:
```sql
alter table public.squad_members add column season_id uuid;
update public.squad_members sm set season_id = s.season_id
  from public.squads s where s.id = sm.squad_id;      -- backfill
-- ^ if this reveals an existing double-seat, fix the data first, then:
create unique index squad_members_one_per_season_real
  on public.squad_members (member_id, season_id);
-- + a trigger to keep season_id filled from squads on insert.
```

## M7 remainder · played_on future-bound (needs a trigger, not a CHECK)
`current_date` isn't immutable enough for a CHECK. A BEFORE INSERT/UPDATE trigger
on `rounds`: `if new.played_on > current_date + 1 then raise exception 'round date is in the future'; end if;`
Also consider making `score_round()` ignore a client-supplied `index_at_post`
for `source='quick'` (it currently trusts it).

## L1 · Reaction deletes (post_kudos)
Split `kudos_all` so DELETE is self-only (a member can currently delete others'
reactions). Verify post_kudos columns first (it references league via post_id).

## L8 · Guest claim_token exposure
`live_round_players.claim_token` is readable league-wide, so a member could claim
a guest's card first. Exclude the column from member reads (a view, or a column
grant) — the claim RPCs don't need the client to see the raw token.
