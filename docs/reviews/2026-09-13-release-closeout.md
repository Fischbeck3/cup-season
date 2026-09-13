# Release closeout · Claude handoff — 2026-09-13

Reviewed: `../cup-season-week-review/docs/reviews/2026-09-13-complete-week-repair-inspection.md`.
Continued from `c6dab49` on `claude/complete-the-week`, worktree
`~/cup-season-complete-week`. Codex's workspace was read and never written.

**Candidate: the tip of `claude/complete-the-week`.** The last commit carrying
application code is **`ca74d9b`**; everything after it on this branch is
documentation, including this file. Integrate the tip.

**Nothing was deployed.** Production access this pass was read-only: the
migration ledger, a `db push --dry-run`, and one dry run from a staging
directory that proved a recipe wrong (below).

---

## Commits

| Commit | What |
|---|---|
| `a645389` | F1 · the fourth placement, where the reminder was stranded |
| `1ab2b82` | F2 · one reset lifecycle, and Start over actually starts over |
| `9443f83` | F4 · correct the contradictory history, delete a recipe that does not work |
| `ca74d9b` | F3 · account for every native test, and correct the count I published |

---

## Findings closed

### F1 · the native reminder lost its actions

`HomePage.make` promotes the highest remaining item to `wireEmptyItem` when
another story leads **and** the activity feed is empty. That block drew an
eyebrow, a headline and a standfirst and offered no act at all — it never called
`take` or `answers`. Its design note says the door lives in the floor beneath,
but the floor now offers only "Something else", so the sentence that asks a
golfer about their round had no way to answer it and no way to dismiss it.

An answerable card carries its own actions there now. The one-act rule still
holds for every other item; a card that *asks* a question carries the answers to
it. The headline also goes through `localHeadline()` like every other placement.

**My own note in that test file was wrong and is replaced.** I had written that a
displaced card was unreachable through a fixture because the wire is built from
the feed. It is reachable: with an empty feed the item is promoted *out* of the
wire into this block, so `after_golf_wire` finds it without inventing a feed row.
Codex's reproduction is brought across and extended rather than re-derived.

### F2 · Safari Start over kept the gross and the plan

`resetPostComposer` kept its own field list without `inGross` — the hero box and
the main total score — and never cleared the plan, the partners, the nine or the
course's cached card. A comment beside `clearPostComposerAfterPost` claimed Start
over shared it. It did not, and that comment is gone.

`putTheCardDown` is the one place a card is put down now, reading `POST_TYPED`
like everything else. The two callers differ in exactly one way and it is an
argument: Start over restamps today's date, because a card with no date cannot be
posted at all (Q-21); an accepted post leaves the date to its own caller.

What it deliberately does not do: it never touches the post request. A start-over
after an ambiguous failure is exactly the case the frozen id exists for (D350).
And it never runs on navigation — only an explicit button or a server-accepted
round puts a card down, so an ordinary draft survives leaving the screen.

### F3 · the native verification understated the coverage

Not eight failures. **41 UI tests: 21 passed, 14 failed, 6 skipped.** Every one
is accounted for individually in
[`2026-09-13-native-test-accounting.md`](2026-09-13-native-test-accounting.md),
with its cause established from source: `-cs_dev_open` is gated on
`store.me != nil` (`MainTabView.swift:503`), this simulator has no session, and
the six skips throw `XCTSkip` naming that. The control is inside the same
suites — the two tests that do not need an account pass.

A missing precondition explains a red; it does not turn it green. The affected
journeys are listed as unverified and owed, not as passing.

### F4 · the canonical history contradicted itself

`D353`–`D356` each landed twice; they are disambiguated as `a` (release
candidate) and `b` (complete week), with an index stating that a bare number in
after-golf, plan-prefill, ceremony or Major-seating code means `b`. Nothing is
renumbered, so citations in either wave still resolve.

A labelled correction block now supersedes three claims, with the original text
left standing beneath it and inline pointers on the two affected bullets:

1. **239 → 240 applied.** My count came from a `grep -c` and miscounted.
2. **D345's history.** The entry said it reached production "without
   `schema_migrations` knowing" while its own previous sentence cited the listing
   showing it applied. What is observed: the version is in migration history and
   the body is live; and the prior release's readback returned 239 with
   `held_d345_applied=false`. Both stand. **Who applied it, when, and why the
   documents believed it held are not known and are no longer implied.**
3. **The stale insert fallback** in the ceremony entry, which the code had
   already dropped.

**The gate-only staging recipe is removed, because I tested it and it fails.**
A staging directory holding one migration, dry-run against the linked project,
returns `LegacyDbPushMissingLocalError` — and the CLI's own suggestion is
`migration repair --status reverted` across all 240 applied versions followed by
`db pull`. That would rewrite a live database's ledger to agree with a directory
containing one file. It was written but never executed. There is one phase now.

---

## Evidence — exact commands and results

All run on `ca74d9b` unless noted.

```sh
npm run preflight                                     # 0 failures, 0 warnings
node tests/post-request.test.mjs                      # 48 passed, 0 failed
python3 tests/release-chain-database.py               # 242 migrations, 264 functions
python3 tests/after-golf-postgres.py                  # D345 + D353 gate/context/status
python3 tests/events-consent-database.py              # Major seating, Ryder, run-it-back
node tests/release-fixes-database.mjs                 # ALL PASS
python3 -m http.server 8791 &
node tools/web-verify.mjs --url 'http://127.0.0.1:8791/?exit' \
  --widths <390|320> --wait 1500 --eval "$(cat tests/<suite>.js)"
cd apps/ios && xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath /tmp/cs-closeout-native.xcresult
supabase migration list --linked
supabase db push --linked --dry-run --skip-vault
```

| Check | 390 | 320 |
|---|---|---|
| `tests/after-golf-repairs-browser.js` | passed | passed |
| `tests/release-posting-browser.js` | 11 checks, network disabled | 11 checks |
| `tests/home-function-browser.js` | passed | passed |
| `tests/app-tests.js` | 461, zero failures | 461, zero failures |

No console errors and no horizontal overflow at either width.

**Codex's own F2 reproduction, run unchanged against the fix**, at both widths:

```json
{"afterActualStartOver":{"gross":"","plan":null,"date":"2026-09-13"}}
```

It reported `gross 84` with the plan still attached.

**Native**: `CupSeasonKit` 1,158 · `CupSeasonTests` 120 (Swift Testing) + 38
(XCTest) · `CupSeasonUITests` 41 = 21 passed, 14 failed, 6 skipped, all itemised.
The 14 after-golf tests — 5 lead, 3 displaced (F1), 6 plan-route seam — all pass.

**Database, read-only on this commit**: 240 applied, exactly two pending, and the
dry run names those two and nothing else.

Screenshots at `/tmp/cs-after-golf/` and attached to the xcresult. Not committed:
this repo is public and prior sprints keep captures out of the tree.

---

## Remaining blockers

None for the repair itself. **Two release gates are outside my reach:**

1. **No authorized review account in this workspace.** Fourteen UI tests fail and
   six skip for want of a session, so saved course, offline cold boot, the
   Compete rooms and the accepted-round receipt are **unverified**, not passing.
   Codex's release workspace has the signed-in simulator these need.
2. **Signing** for a native candidate. The owner's.

One journey is covered at the seam rather than end to end: **plan → composer as a
real tap**. The fixture renders Home outside the tab shell, so no presenter
raises the composer. `AfterGolfPlanRouteTests` and the browser suite cover what
the tap carries; the tap itself belongs to a device or signed-in pass.

---

## Work owed, by layer

| Layer | Owed | State |
|---|---|---|
| **Database** | `20261102090000`, `20261103090000` | pending; verified on disposable clusters; fresh dry run names exactly these two |
| **Edge Functions** | none | nothing owed |
| **Safari** | the client half of R1–R6 and F1–F2 | unpublished; awaiting Codex integration, then `git push` and a live-SHA check |
| **TestFlight** | a fresh candidate with its own build identity | blocked on signing; 835 is the previous release's artifact and must not be reused |

Sequence, flags and readbacks: [`2026-09-13-after-golf-deploy-sequence.md`](2026-09-13-after-golf-deploy-sequence.md).
Database first and alone; `tests/db-checks.sql` check 34 must flip from FAIL to
PASS; then the contract refresh; then Safari; then TestFlight separately.

---

## Final candidate

**Branch** `claude/complete-the-week`, at its tip. `ca74d9b` is the last commit
that changes application code, test code or a migration; the commits after it are
this handoff and the test accounting.

No new features, no scoring change, no dependency, and no production deployment
in this closeout.
