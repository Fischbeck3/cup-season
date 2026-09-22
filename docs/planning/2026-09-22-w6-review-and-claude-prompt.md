# W6 review and Claude correction prompt

2026-09-22 · Codex · reviewed `claude/october-launch-w6` at `5404978`.
The branch contains `f49756d` and preserves the previous Mac fixes.

**Disposition: W6 is implemented but needs a correction pass before its
numbers can drive a launch or outreach decision.** The next engineering task
is that pass now, not waiting for the September 29 report. Owner measurements,
cohort assignments, deployments and physical tests remain separate inputs.

## Evidence from this review

- Preflight: zero failures, zero warnings.
- All Node test files: 29 passed, including Claude's nine growth tests.
- `pilot-scorecard.mjs --no-db --as-of 2026-09-22 --store-live false`: exit 0.
- Additional direct calls into the actual acquisition module reproduced the
  false statuses and invalid-date crash below. These cases are not covered by
  the nine current growth tests.
- SQL findings below are from source review against the governing stop
  condition and schema, not a new production read. No SQL was applied or
  production data changed. No native code changed, so the previous native
  verification remains applicable to the unchanged source.

## Required corrections, in order

### 1. P1 — the assistance gate does not count unassisted completions

`tests/pilot/scorecard.sql:296–305` compares assisted sessions over four weeks
with **all** finished live games over four weeks. It never matches a finished
game to assistance by group, golfers or time window. The governing condition
in `docs/pilot/gates-and-stop-conditions.md` is **a week** where assisted
sessions exceed **unassisted completions**.

For example, two assisted sessions and two games completed with that help
produce `2 > 2 = false`, hence `ok`, although there are zero unassisted
completions. Older good weeks can also hide a failing current week. The schema
already provides session group keys, participant IDs and start/end times.

Acceptance: count and display assisted and unassisted completions by week and
cohort, apply the stated weekly condition, and preserve unknown when the
session evidence is insufficient. Distinguish one game from its multiple
posted player cards. Seed fixtures for an all-assisted week, a mixed week,
overlapping sessions, a prior good week/current bad week, and incomplete
session evidence. Do not label all completions unassisted.

### 2. P1 — checkpoint results treat partial or duplicate data as authoritative

`tools/lib/growth-report.mjs:97–113` sums whatever rows happen to be present
and immediately chooses met/missed. `parseAcquisitionCsv` does not enforce the
documented one-row-per-week-per-channel key. Sunday totals also cannot resolve
the October 31 Saturday cutoff, November 30 Monday cutoff, or December 31
Thursday cutoff exactly.

Direct calls to the current module produced:

| Input | Actual result | Defect |
|---|---|---|
| Only Oct 4 logged, 100 downloads; report Nov 1 | Oct target `missed`, cumulative 100 | Missing later weeks treated as a complete month |
| Same Oct 4/channel row with 300 downloads pasted twice | Oct target `met`, cumulative 600; no log problem | Duplicate entry creates a false success |
| 450 through Oct 25, another 100 in the week ending Nov 1 | Oct target `missed`, cumulative 450 | The log cannot tell which of the 100 happened before Oct 31 |

Acceptance: keep logged subtotals separate from complete verified totals.
Preserve missing/partial coverage. Use an explicit dated App Analytics
cumulative reading or daily dated counts for exact month-end checkpoints;
weekly channel totals alone are insufficient. Reject duplicate keys with an
actionable error. Keep the App Store, TestFlight and web counts separate and
never infer a historical install count from today's account rows.

### 3. P2 — `--as-of` is not a shared reporting cutoff

`tools/pilot-scorecard.mjs:31,68–71` passes the date only to the title and the
acquisition renderer. SQL sections still use `now()`/`current_date` and do not
receive that date. `growth-report.mjs:138` renders `weekly(rows)` without
filtering later rows: a report dated October 5 prints the November 1 row.

Acceptance: validate one reporting date and timezone, apply its period bounds
to every temporal section and the CSV output, and exclude future data. Label
current-state sections as current when history cannot be reconstructed from
the schema; do not imply historical invitation/claim status. Cover backdated
reports and the end-of-day/week boundary. The saved September 29 report must
be generated from observations available then, not prewritten with that date.

### 4. P2 — activation counts use different eligible populations

`tests/pilot/scorecard.sql:215–237` excludes founders, deleted profiles and
test-domain accounts from accounts created, but counts the first and second
rounds of every profile. Finished games exclude sandbox leagues; the round
aggregates do not share those eligibility rules.

Acceptance: define the eligible real-golfer population once and apply it
consistently to the relevant account/round/game metrics. Label weekly events
separately from a signup-cohort conversion funnel. Nine first rounds and eight
new accounts in a week are not alone proof of a bug: older accounts can
activate later. Test explicit founder, seeded/test, deleted and real-golfer
fixtures, and preserve the intended treatment of league-less rounds.

### 5. P2 — malformed log dates can crash the runner

`growth-report.mjs:37` only checks the date's shape. `2026-99-99` is accepted
with no problem; `mondayOf` then throws `RangeError: Invalid time value`.
The guide requires Sunday dates, but other weekdays are accepted too. CLI
date/boolean values are also not validated strictly.

Acceptance: validate real calendar dates and the documented weekly boundary,
strict counts and flags; handle malformed CSV rows/quoting with a clear
diagnostic. Never crash or silently count a malformed row. A pre-approval
App Store count must not contradict `--store-live false`; expose contradictory
input explicitly. Add tests beyond shape-only validation.

### 6. P2 — correct the attribution diagnosis before adding another writer

The new inbox entry says `came_via_kind` is never written and proposes adding
a writer to `log_growth_event`. That writer already exists:

- `supabase/migrations/20260828160000_growth_events.sql:133–136` writes both
  attribution columns on `profile_created`.
- `index.html:23580–23583` reads pending claim/join intent and emits the event.
- `apps/ios/CupSeason/Onboarding/CardGateView.swift:311` calls
  `CSGrowth.profileCreated()`, which handles pending claim and join intent in
  `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Growth.swift:56–63`.
- Native growth logging intentionally does nothing in DEBUG builds.

Null production values show missing attribution observations; they do not
prove a missing implementation. The profile can also have arrived directly or
been seeded. Source existence does not prove the deployed path works either.

Acceptance: correct the inbox and release narrative. Trace a fresh real claim
and join through intent persistence, authentication, card completion, the RPC
and profile readback in a nonproduction fixture first. Compare the deployed
function read-only if needed. Fix only a demonstrated break. Existing users
and direct arrivals must not gain fabricated acquisition history. Do not
introduce a second writer based on the incorrect absence claim. Also label
the first observed client platform as a proxy unless it is tied to the signup
event: someone can sign up on web and later send their first event on iOS.

## Paste into Claude

```text
Continue the October launch sprint with a bounded W6 correction pass now.
Start from origin/codex/october-w6-review in a new owned worktree. It contains
your 5404978, the verified Mac fixes from f49756d, and this review packet.
Read AGENTS.md, CLAUDE.md, the launch execution plan, the existing report code,
and docs/planning/2026-09-22-w6-review-and-claude-prompt.md.

Do the six numbered corrections in this packet, in order. Preserve the
October 1 submission/public outreach objective and the 500 / 2,000 / 5,000
first-time App Store download checkpoints. W6 is not accepted yet: passing
the current nine tests does not establish the correctness of its totals or
stop condition.

First reproduce the listed cases with focused tests, then fix the report.
Use populated nonproduction SQL fixtures for assistance and eligibility.
Give each reporting period an explicit cutoff and make incomplete evidence
visible. Keep weekly acquisition channels distinct from exact month-end
App Analytics totals. Correct the attribution absence claim and exercise
the writer that already exists before proposing any new telemetry path.

Do not fill the real acquisition log, name cohorts, or record phone PASSes
without the owner's actual data. Do not wait until September 29 to correct
the report. Continue independent engineering while those inputs are pending.
No production mutation, merge to main, Apple upload or submission is
authorized by this prompt. Existing deployment requirements stay in force.

Deliver focused commits, passing regression evidence for each finding,
preflight and the full Node suite, and a clearly labelled synthetic report
showing complete, partial, failing and missing cases. Update the release
record with implemented/tested/deployed kept separate. Finish with the
remaining owner inputs and the next concrete engineering action.
```

## Release state carried forward

No new deployment is owed from this documentation review. The existing
`20261116090000` and `20261117090000` migrations and subsequent `courses`
deployment remain owed, along with the reviewed client release. Physical
two-phone tests, real Storage API consent proof, the installation link,
current Apple/live state and the review package remain open. Do not convert
those into passed gates because this reporting review is complete.
