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

## 2 · All pending database changes

| Migration | State |
|---|---|
| through `20261103090000` | applied and read back on 2026-09-13/14 (242) — the last readback this session could make; `deploy-status` in this worktree reports **unknown** (CLI not linked here) |
| `20261024090000_the_loop_has_a_closing_act.sql` | **held** since 2026-09-13 pending capability protection — not part of this packet, and not a dependency of it |
| `20261104090000_the_round_that_counts_explained.sql` | **prepared, reviewed above, not applied** |

Edge functions: none. Secrets: none.

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

## 5 · Checks run

See the handoff addendum for the exact suites and outcomes on this source.

## 6 · Recognition, still proposed

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

## 7 · Release candidates

| | Candidate |
|---|---|
| Quality checkpoint (unchanged) | `714609b` · build **905** · internal-only |
| Counting increment, both clients | **`0792ddd`** on `claude/brand-client-parity` · **no native build archived** for it — the phone's half needs the migration to do anything on production, and the increment is proven on fixtures and the isolated cluster |
| Production web | `1bc307f`, untouched |

**Order when authorized:** push `20261104090000` → re-take the contract from
the live database → confirm `tools/build-db.mjs --check` is clean → archive
the paired build → verify processing and availability separately.
