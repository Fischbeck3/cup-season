# S1 · the review of `1c59a96`, and the fixes that close it — 2026-09-13

Sprint packet: `docs/planning/2026-09-13-claude-led-season-activation.md` at `2f51b45`.
Baseline reviewed: `1c59a96` (`codex/busy-friends-native-2026-09-13`), "Build editable
league setup agreement and repair receipt reconciliation".
Branch: `claude/season-activation`, worktree `~/cup-season-activation`.

**No prior review of `1c59a96` existed when this sprint opened**, so this document
is that review rather than a disposition of someone else's. Nothing here is
attributed to Codex's audit; the handoff at `docs/reviews/2026-09-13-busy-friends-native.md`
is quoted where it named a limit, and its three named limits are carried forward
below as the packet requires, not as things the previous slice solved.

This is S1 only. It contains the review and its fixes. No S2 or S3 behavior is in
this commit, so the review fixes can be integrated on their own.

---

## 1 · Dispositions, area by area

The packet names five areas to recheck. Each was traced first-hand on this exact
branch. Two carried a defect; three are clean and are recorded as clean so the
next reader does not re-trace them.

### Agreement → outgoing fields → stored settings — **CLEAN**

The seam works the way the agreement screen promises. `WizardScreen.reviewDials`
produces `dials.preparedForReview(squadsChosen:)`; `WizardAgreement` is built from
exactly that value; and `publish()` reads `agreement.dials` — not `dials` — so the
settings that reach `lock_league` are the ones the golfer read and approved, even
if the underlying dials moved behind the sheet. The date is pinned at review time
(`startDate(today:)`), which is what keeps a review opened across midnight from
submitting a different day than the one on screen.

One stale comment, not a defect. `WizardService.lock` warns that "the skew retry
drops every optional arg on ANY error, so a lock that reached the database on its
second try wears the SQL defaults". That is no longer reachable: `WizardLockCall`
declares `optionalArgs` empty precisely so the generic retry cannot do this, and
the only declared fallback drops `p_pay_note` alone, on `PGRST202`/`42883`. The
comment describes a hazard that the code beside it already closes. Left in place.

### Selected squad count — **CLEAN**

`preparedForReview` forces `solo` when the squads question was answered no or
never asked, and lifts a stored `solo` to `squads2` when it was answered yes.
An explicitly chosen `squads3` or `squads4` passes through untouched, because the
More-settings picker sets `dials.structure` and `squadsChosen` together. The
advanced-count overwrite that D346 named as the prior behavior is gone.

One cosmetic inconsistency, not a rule change: answering "solo" at step one leaves
`dials.structure` at its default, so the More-settings segment can *display*
`squads2` for a league that will publish as solo. The agreement screen is built
from `reviewDials` and shows the truth, and the truth is what is stored. Recorded
for S3's copy pass rather than fixed here.

### Minimum and bye facts — **CLEAN**

`setupMinimumConsequence` states the three facts in the right order and does not
overclaim: no team penalty in an individual season; "play when you can, no points
lost for playing less" when the floor is zero; a target rather than a penalty
under the casual preset; and, where a penalty does apply, one missed minimum
forgiven each season (D14) with partial months exempt (§14.0). It does not claim
a cap equalizes playing opportunity, which D346 forbids.

### Membership versus invitations — **DEFECT, FIXED** (D348)

`invite_golfer` writes `member_invites` and never `league_members`. The phone's
celebration line did not respect that: `WizardCopy.liveSub` read
`"\(invited + 1) in"`, where `invited` is the number of invitations the wizard
just sent. **A Pro alone in her new league with five invitations out was told
"Six in."** The real `league_members` count was already on the same struct,
fetched by `finish(...)`, and simply unused by that sentence.

The web has always been right here — `openLockShare` counts `league_members`
fresh at that moment and prints the invitation count as its own parenthetical —
so this is the phone catching up, not a new rule. D346's own implementation-audit
line already said "sent invitations are not accepted seats; the share reads
membership separately"; the phone did not do it.

Fixed: `liveSub(weeks:startsOn:invited:members:)` now says both facts and keeps
them apart. One golfer reads "You're in", not "One in". Three tests in
`LockShareCrewTests` hold it.

### Receipt residuals — **CLEAN**

`SquadReceiptBreakdown` is sound and is an improvement on what it replaced. The
old code derived `adj = team.pts − fromRounds` and could print that *plus* the
itemised ledger rows, double-counting the adjustment. The new type sums the round
contributions and the known ledger rows separately, and exposes only the actual
remainder as `unexplained`, with a float-noise floor at 1e-6. When the remainder
is non-zero the sheet says "Breakdown not yet available" and tells the golfer the
total came from the standings — an honest unavailable state rather than an
invented row. `MemberHistorySheet`'s "BUMPED" is now "OUTSIDE MONTHLY BEST" in
both the visible label and the accessibility label.

---

## 2 · The three carried-forward limits

### (i) Ambiguous create responses and reopening after process termination — **OPEN, scoped**

What `1c59a96` actually added is an **in-session** checkpoint:
`WizardService.publish` takes `resuming:` and calls back `didCreate:`, so a lock
that fails after a successful create can be retried without minting a second
league. `WizardScreen.rememberCreated` holds that in `createdHere`, which is model
state and dies with the process.

What I verified beyond the handoff's claim: **an orphaned league is not lost.**
`create_league` inserts a `league_members` row for the creator in the same
transaction, so a created-but-unlocked league appears in the golfer's memberships,
`LeagueRoomModel` gives a `setup`-phase league a room, and that room's `openWizard`
door reopens the wizard on it (`WizardScreen.load` accepts it because its phase is
still `setup`). Recovery exists.

**The residual is duplication, not loss.** The leagueless "Start a season" door
passes `existingLeagueId: nil` unconditionally. A golfer whose app died mid-publish,
or whose create response was ambiguous, can tap that door and mint a second league
beside the first. Closing it means either a durable record of the in-flight create
or a server-owned request identity on `create_league` — an additive contract, which
the packet says must be specified and recorded before implementation. **Not solved
here, and not claimed solved.** It is S2 work under the packet's contract rules.

### (ii) The counting cap — **DEFECT, FIXED** (D347)

Reproduced first, on an isolated PostgreSQL 17 cluster (port 5470, every migration
applied, none skipped), before anything was written:

```
stored counting_cap = 4
select lock_league(..., p_counting_cap => null, ...)
select counting_cap from league_settings  ->  4      -- the Unlimited was swallowed
```

Three separate producers were rewriting a rule nobody chose:

| Producer | Stored value | What it wrote |
|---|---|---|
| `lock_league` | 4, caller sends explicit `null` | 4 — `coalesce(p_counting_cap, counting_cap)` |
| Phone | 5 | 4 — snapped to the nearest rung, then saved the rung |
| Web | 5 | 3 — `CAPMAP[n] ?? 1`, then saved that |

The two clients did not even rewrite it to the same rule. `league_settings`
accepts any integer 1–31 or null; the five-rung ladder is a picker, not the
constraint.

This reaches the points table. The cap decides `month_rank`, which rounds count,
the standings and the receipt — and nothing anywhere says it changed, which is the
shape §16 exists to forbid.

Fixed in three places:

- **`supabase/migrations/20261025090000_unlimited_means_unlimited.sql`** — a
  same-signature `create or replace` of `lock_league` changing one line to
  `counting_cap = p_counting_cap`. The argument default stays `3`, so an old
  client that omits it behaves exactly as before; only an explicit `null` changes
  meaning, and both clients send an explicit `null` only to mean Unlimited. **No
  argument is added, removed or re-typed**, so the overload trap documented in
  `docs/reviews/2026-09-12-after-golf-contract-review.md` §1 is not in play and no
  grants are discarded. The migration carries a read-only self-check that asserts
  the cap coalesce is gone, the participation-floor coalesce survives, and
  `lock_league` still resolves to exactly one function.
- **Phone** — `WizardDials.capExact` carries the stored value beside the picker
  position; `capN` returns it while the picker still sits on the rung it was
  snapped to; `stepCap(_:)` clears it and moves one rung **in the direction of
  travel**, so stepping down from a stored 5 lands on 4 and stepping up lands on 6.
  `WizardDials.from` seeds it from the row.
- **Web** — `state.capExact`, with `capDB()` as the only value permitted to reach
  `league_settings.counting_cap` and `capLabel()` / `capNum()` as the only label
  and math producers. All three send sites and every label site route through
  them. The old `CAP_N[state.cap ?? 2]` default is preserved inside `capIdx()`.

The ladder's snap survives **for display**, which is what it was built for
(`Bylaws.capIndex`, `BoardModels`, and the existing expectation in
`LeagueRoomTests.swift:401`). What changed is only what gets saved and named.

**No backfill.** A league already rewritten by an older client keeps whatever it
was rewritten to, because this code cannot tell a rewrite from a choice.

Evidence, on the isolated database:

| Case | Result |
|---|---|
| stored 4, lock with explicit `null` | now `null` — Unlimited means Unlimited |
| stored 4, lock with explicit `5` | `5` — an explicit off-ladder cap writes unaltered |
| stored 4, lock with the argument **omitted** | `3` — the SQL default, **unchanged by this fix** |
| participation floor beside it | still `2` — the floor's own coalesce survives |
| `lock_league` overload count | 1 |

The third row is a pre-existing sharp edge, not a regression: before the fix,
`coalesce(3, 4)` also wrote `3`. Neither shipped client can reach it — the phone's
`WizardLockCall` declares no droppable arguments and always encodes the cap, and
the web now routes every send through `capDB()`. Named here so nobody rediscovers
it as new.

Client-side, all thirteen stored values round-trip without alteration:

```
stored 1,2,3,4,5,6,7,8,10,12,20,31,null  ->  sent 1,2,3,4,5,6,7,8,10,12,20,31,null
moved the picker off a stored 5 -> sends 6 (the ladder's value, upward)
```

### (iii) The Final spec/D212 conflict — **PRESERVED, unchanged**

§14.3 says the Cup Final's four weeks are "scored fresh". D212 and the shipped
engine say a Final-window round is subject to the counting cap of its **whole
calendar month**, which is not the same rule. My gameplay audit at `8dcd403`
established this, and D346 records it as an open owner decision.

**Nothing in this commit changes qualification, ranking or scoring.** No migration
here touches `enter_cup_final`, `v_rounds_ranked`, `cup_points` or `close_season`.
The cap fix moves in the opposite direction from a secret change: it stops a
stored rule from being silently rewritten. The agreement screen continues to
disclose the current monthly-cap effect, which is the honest half of the conflict.
A fresh-ranking Final stays an owner decision and is not made by a copy edit. The
packet's own note that a lock-time seeding table may not exist is untouched here;
that investigation is listed as post-S1 work.

---

## 3 · Evidence

Everything below was executed. Nothing is counted from a test case that did not run.

| Check | Result |
|---|---|
| `CupSeasonKit` suite, iPhone 17 Pro simulator | **1,095 tests in 178 suites, TEST SUCCEEDED** |
| `CupSeason` app target, same destination | **BUILD SUCCEEDED** (XcodeGen regenerated first) |
| `npm run preflight` | **0 failures, 0 warnings** — including the free-identifier check across all four script blocks |
| `node tools/web-verify.mjs` | no horizontal overflow at 1440 or 390; **0 console errors, 0 warnings** |
| Isolated PostgreSQL 17 cluster, port 5470 | every migration applied, none skipped; cap defect reproduced, then the fix and a non-regression proven |

Tests added or changed:

- `StoredCapFidelityTests` — twelve stored caps plus Unlimited round-trip; the
  stepper still sits on the nearest rung; moving it takes the ladder's value; the
  agreement quotes the stored rule; stepping off an off-ladder cap goes the right way.
- `LockShareCrewTests` — a Pro alone with five invitations is not "six in";
  accepted golfers are counted and pending ones are not; no invitations means no
  invitation clause.
- `WizardTests.swift:273` — the existing expectation that **encoded the defect**
  (`d.cap == 2 && d.capText == "Best 4"` for a stored 5) now reads `"Best 5"` with
  `d.capN == 5`.

**Environment actually used.** Local Mac session; iOS Simulator, iPhone 17 Pro.
The scenario matrix's native conditions — compact phone, AX3 text, dark and light,
actual taps through the changed paths — are **not** claimed for S1 and were not
run; S1 changes one sentence of native copy and no layout. They belong to the
handoff run after S3, and Codex's independent integration QA. No production
database or Edge deployment, no main merge, no TestFlight upload.

---

## 4 · What S1 does not close

- **The duplicate-league residual** in limit (i). It needs either a durable
  in-flight create record or an additive request identity on `create_league`, with
  its ownership, replay and conflicting-body behavior, old-client behavior and
  grants specified and recorded before implementation. S2.
- **Leagues already rewritten** by an older client. There is no way to distinguish
  a rewrite from a deliberate choice, so nothing is backfilled.
- **The Final conflict.** Owner decision, untouched.
- **Deployment.** `20261025090000_unlimited_means_unlimited.sql` is written and
  verified against an isolated database. It is **not applied to production**. It
  ships with `supabase db push` by the owner, and needs no client push of its own;
  the `index.html` half ships on the normal Netlify path.

S2 and S3 are not started. This sprint is not complete.
