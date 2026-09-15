# Deployment packet · the round that counts, explained (D362) — 2026-09-14, late

**No production database push has been made.** This packet is what a push would
apply, what both clients do before and after it, and how each was verified.
The quality checkpoint `714609b` / build 905 stays separate and unchanged.

## 1 · The migration under review

`supabase/migrations/20261104090000_the_round_that_counts_explained.sql` — one
file, three additive changes, each skew-safe:

| Function | Change | Grant | Why |
|---|---|---|---|
| `my_month_counters(p_on date)` | **new** | authenticated | what the caller's round on that date can add, per membership whose active season holds the date, from the engine's own `month_counters` (internal, no grant). Returns `[]` signed out or out of season. |
| `round_card(p_round, p_league default null)` | **re-signed** (the one-argument form is dropped so a one-argument call is not ambiguous) | authenticated | the receipt says **whose lens** it scored under. `contributions` = every league the round counts in that the **viewer** may see (owner: all; league mate: shared leagues). The scalars are the explicit lens (`p_league`), the only lens when there is one, and **null otherwise** — never a result picked by month rank. `pvi` falls back to the 100% figure when no lens is selected. Every prior key keeps its meaning. |
| `counting_rounds(p_member, p_season, p_month default null)` | **new** | authenticated | one golfer's rounds under one season's rule, optionally one month, each marked counting or not — the way back from a figure to the rounds behind it (§16). Authorized like the receipt. |

**Validated on an isolated cluster** (the simulation branch's sandbox on port
5471): every migration on disk applied in order — 266 public functions — then
`tests/db/counting-explained.sql` (inserts; isolated only):

| Case | Result |
|---|---|
| owner, round counting in two leagues, no context | 2 lenses; scalars null; per lens `Fellas:3/2 Sunday Cup:3/∞` |
| owner, explicit `p_league` | the chosen lens, rank 3 in either |
| counting rounds, one month, cap 2 | `#1` and `#2` counting, the third **bumped** |
| whole season | the **backdated** August round is listed (4 rounds) |
| composer counters on a date | Fellas cap 2 · used 2 · worst 6; Sunday Cup uncapped · used 3 · worst 5 |
| viewer sharing one league | 1 lens; scalars **are** that lens |
| viewer reading the unshared league's rounds | refused |
| viewer sharing only the other league | the receipt opens; the unshared lens is **withheld** |

## 2 · All pending database changes — read from production, 2026-09-14 late

`supabase migration list --linked`, read-only, from the linked checkout:

| | |
|---|---|
| Applied in production | **242**, latest `20261103090000` |
| On disk in this worktree | 243 |
| **On disk and NOT applied** | **`20261104090000` — this file, and nothing else** |
| Applied but not on disk | none |

**A correction to the earlier packet.** It recorded
`20261024090000_the_loop_has_a_closing_act.sql` as *held*. It is **applied in
production** — the remote list returns it, dated 2026-10-24 — and has been
since before this session. There is no held migration left to exclude, and
`supabase db push` from this branch applies exactly one file.

Edge functions: none. Secrets: none.

### Revalidated against a production-equivalent schema

An isolated cluster was built from **exactly the 242 migrations production
reports as applied** (this file skipped), then this file was applied alone:

| | Before | After |
|---|---|---|
| `round_card` argument count | 1 | 2 |
| `my_month_counters` | 0 | 1 |
| `counting_rounds` | 0 | 1 |
| public functions | 264 | 266 |
| migrations recorded | 242 | 243 |

All **55** assertions in `tests/db/counting-explained.sql` pass on that schema,
and the contract snapshot taken from it **matches `packages/db/contract.psv`
exactly** — so the file in the repository is what the push produces.

## 3 · The typed contract

`packages/db/contract.psv` was regenerated with the canonical query **from the
isolated cluster** (every migration on disk, including the held one and this
one), not from production; its header says so. Diff against the previous
production snapshot: exactly `my_month_counters`, `counting_rounds`, and
`round_card`'s new argument list — nothing else moved. `tools/build-db.mjs`
then regenerated `rpc.ts` (248) and `Rpc.swift` (196 client-callable).
**Re-take the snapshot from the live database after the push**, exactly as the
file's header instructs.

## 4 · Paired implementation

| | Web | Native |
|---|---|---|
| Before posting | `my_month_counters` when served, cached by date; the engine rows the desk already holds when not. One sentence per season, the season named when there are two. Nothing outside a live season. | `my_month_counters` on every date change; empty on the older database — the counting note alone. |
| The receipt's lens | the open league is the **explicit** lens; a database refusing `p_league` gets the one-argument call | no league context on the phone's receipt today → no explicit lens; the server's `contributions` decide |
| Lens rows | one per lens the viewer may see; the league named when >1, with its points; `COUNTING #n OF cap`, `COUNTING #n` when uncapped, `BUMPED` past the cap | the same, from `ReceiptRows.build` |
| The way back | a door per lens → `counting_rounds` → the sheet: counting or BUMPED, each opening its receipt; the older database gets the member-history door for the open league | a door per lens → `CountingRoundsSheet` (the same producer); the older database gets no door and says so honestly if the sheet is opened |
| Unavailable | no lens the viewer may see → no row, no door; RPC missing → toast, the receipt stands | the same |

**Closed web limitations:** routing no longer depends on the league the desk
has open (the server names each lens's league, season and member), and the
door opens the **month**, not the season.

**Gaps that remain, named:** the phone's receipt passes no explicit lens (the
Compete tab could pass its league; today the server's rule decides, which is
correct and complete). Squads: the sheet is the member's own rounds; a squad's
counting set is the sum of its members' and is not drawn.

## 5 · Compatibility with build 905, proved rather than assumed

Build 905 is on TestFlight and calls `round_card(p_round)` with one argument.
This migration **drops** that signature. Two pieces of evidence:

1. **The call still resolves.** On the production-equivalent cluster, the
   one-argument call returns a payload carrying **every one of the 25 keys
   build 905 reads** (asserted by name, not by eye). PostgREST and SQL both
   resolve `round_card(p_round := …)` to the two-argument function with
   `p_league` defaulted.
2. **Its own code, frozen, against the new payload.**
   `Build905CompatTests` copies `714609b`'s `ReceiptSeed.merged(with:)` and its
   month-row rule verbatim and runs them against the two payloads the new
   function returns:

   | Payload | Build 905 prints |
   |---|---|
   | one league (scalars filled) | `COUNTING #2 OF 4` — unchanged |
   | two leagues (scalars null) | **no month row at all** |

   The two-league case degrades to **silence**, never to another league's rank.
   The current client, given the same payload, prints both lenses.

That is the whole risk of replacing the signature, and it is bounded: a shipped
build loses one row on a round that counts in more than one league, until it is
replaced by a build that reads `contributions`.

## 6 · Checks run

**Database — assertions, not probes.** `tests/db/counting-explained.sql` is
**55 assertions** that raise on a wrong answer. Each compares through one
`want()` with explicit typed overloads, because a polymorphic helper silently
fails to resolve an int/bigint or jsonb/text mix — which is how a probe file
stops half way down and still exits 0. An expected refusal matches the exact
message the function raises; **any other error is re-raised as a wrong-reason
failure**, so a missing column or a bad call can never read as an access
denial. Two negative controls were run:

| Control | Result |
|---|---|
| flip one expectation (`2` → `99`) | `psql` exits **3**: *FAIL owner sees two lenses — got 2, expected 99* |
| make a refused call invalid instead | `psql` exits **3**: *refused for the WRONG reason: function … does not exist (expected Those rounds are not yours to read)* |

They cover: the grants (authenticated only, no `anon`, no `PUBLIC`, all three
SECURITY DEFINER, the one-argument `round_card` gone), signed-out behaviour,
the two-lens owner with null scalars and the 100% `pvi` fallback, lens
ordering, explicit lens selection both ways, a league the round does not count
in, the one-argument call's 25 keys, month filtering against a backdated
round, counting status row by row against the cap, the uncapped season, a
month with no rounds, a member/season mismatch, per-league counters, a mate
who sees one lens and is refused the other league, a third golfer who sees
only his own league's lens, and a stranger refused outright.

**Web:** `counting-explained-browser.js` on the live preview.

**Native:** `Build905CompatTests` (4), `ReceiptLensesTests` (5),
`ReceiptLensesUITests` (3 modes × rows, doors, sheet), `ComposerWorthUITests`
(5 sentences, plus readability with the keypad up, while typing, dismissed,
and at AX3 on a small phone).

### The three acceptance corrections

| Item | Before | Now |
|---|---|---|
| The sentence's readability | inside the `How points work` disclosure, three sections below the fold and under the keypad at AX3 — present in the tree, invisible on screen | in the hero under the points, where the desk's `#calcSeason` sits; the page scrolls it to the bottom edge when it arrives and again when the keypad rises. Asserted by **frame**: inside the window, `maxY` above the keyboard, and hittable |
| Refetching on a score edit | `card` changed on every keystroke and each one re-asked the server | keyed to **date + session**; only a date change asks. An answer for a context the golfer has left is dropped, and the sentence is cleared while the context changes rather than left standing |
| The sheet's rule | `cap` nil meant "Every round counts" — also true of an unloaded or failed payload | the rule prints only when the payload **has** a `cap` key; a missing counting status stays unknown and says nothing rather than defaulting to counting |

## 7 · Recognition, still proposed

**First counting round** = the earliest-*posted* round that entered the
counting set of that membership at the moment it was posted.

- **Resets each season?** Yes — it is per membership *and season*: a golfer's
  first counting round in season two is a new recognition, because the
  counting set is the season's. (Per membership only would make it a one-time
  join reward, which is a different product claim.)
- **Backdated:** posting time governs; a round played earlier and posted later
  is not first because of its date.
- **Corrections:** an edit to a round's facts that keeps it in the counting
  set keeps the recognition; nothing is recomputed from later standings.
- **Deletion:** `delete_round` clears the pointer when it points at the
  deleted round; the next qualifying post may claim it. The claim is not
  transferred to the next-earliest existing round, because that round did not
  *enter* the set first — it was already there.
- **Retries:** `post_round` is the only writer, and the claim is `update …
  set first_counting_round_id = new.id where first_counting_round_id is null`
  — idempotent under a retried post of the same round, and a duplicate post
  is refused before it.
- **Concurrent posts:** two rounds posted at once by the same member for the
  same season: the row lock on `league_members` serializes the claim; the
  first to commit wins, the second sees the pointer set. Two different
  members: independent rows, no contention.
- **Storage:** `league_members.first_counting_round_id uuid`,
  `first_counting_season uuid`, `first_counting_at timestamptz`; written only
  by `post_round`, cleared only by `delete_round`.

**Historical movement** stays as proposed in the sprint packet: a posting-time
`round_movement` row written by `post_round`, `voided_at` on deletion, never a
recalculation labelled as history. Neither is prepared as a migration: both
change `post_round`, the one function with game consequences, and each needs
its definition accepted first.

## 8 · The exact deployment procedure

Run from the **linked** checkout (`~/cup-season`), on a branch that carries
this file. Every step is copy-paste; the push is the only mutating one.

```sh
# 1 · confirm the gap is exactly one file, from production itself
supabase migration list --linked        # expect: latest applied 20261103090000

# 2 · show what the push WILL do, without doing it
supabase db push --linked --dry-run     # expect: 20261104090000 only

# 3 · apply it (the one mutating command; `ship.sh` asks for the word `push`)
supabase db push --linked

# 4 · read production back
supabase migration list --linked        # expect: latest applied 20261104090000

# 5 · re-take the contract FROM THE LIVE DATABASE (the header's own query)
supabase db query --linked --output-format text \
  "select string_agg(sig, E'\n' order by sig) from (
     select p.proname || '|' || coalesce(pg_get_function_arguments(p.oid),'')
         || '|' || pg_get_function_result(p.oid)
         || '|' || case when p.prosecdef then 'definer' else 'invoker' end
         || '|' || coalesce((select string_agg(x, ',' order by x) from (
              select case when a.grantee::regrole::text='anon' then 'anon'
                          when a.grantee::regrole::text='authenticated' then 'auth'
                          else null end as x
              from aclexplode(p.proacl) a where a.privilege_type='EXECUTE') g
            where x is not null), 'none') as sig
     from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname='public' and p.prokind='f') s;"
# paste the rows under the header in packages/db/contract.psv, then:
node tools/build-db.mjs --check         # expect: clean, no diff

# 6 · the grants, read back from production
supabase db query --linked --output-format text \
  "select p.proname, a.grantee::regrole::text, a.privilege_type
     from pg_proc p join pg_namespace n on n.oid=p.pronamespace,
          aclexplode(p.proacl) a
    where n.nspname='public'
      and p.proname in ('round_card','counting_rounds','my_month_counters')
    order by 1,2;"
# expect authenticated EXECUTE on all three, and NO anon row

# 7 · the paired native build, from the same source
tools/ios-archive.sh --upload
python3 tools/asc.py status <build>     # processing
# attach to the internal Owner group, then read availability back separately
```

**What this does not do:** it applies no other migration (there is none
pending), deploys no Edge function, and touches no secret. Build 905 and its
source `714609b` are untouched by every step.

**If the push must be rolled back:** the change is additive except for the
dropped one-argument `round_card`. Reverting means re-creating that signature
from `20260930090000_one_band_name.sql` in a NEW migration — never editing an
applied file (CLAUDE.md rule 2). Build 905 keeps working either way: its
one-argument call resolves to the two-argument function, proved in §5.

## 9 · Release candidates

| | Candidate |
|---|---|
| Quality checkpoint (unchanged) | `714609b` · build **905** · internal-only |
| Counting increment, both clients | **`0792ddd`** on `claude/brand-client-parity` · **no native build archived** for it — the phone's half needs the migration to do anything on production, and the increment is proven on fixtures and the isolated cluster |
| Production web | `1bc307f`, untouched |

