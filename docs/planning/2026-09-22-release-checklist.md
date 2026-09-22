# Release checklist — the gates, their evidence, and who supplies it

**2026-09-22.** One table for the September 28 release candidate, the
September 29 submission-readiness assessment and the October 1 submission.
Every gate is **not passed** until its evidence column is filled with the
thing it names — a build number read on a device, a Storage API answer, a
production ledger read, an App Store Connect read. A green local suite, a
simulator fixture or a sentence in a handoff is not evidence for a device or
production gate. The owner supplies the device, production and Apple
evidence; engineering supplies the rest and never marks the owner's rows.

## 1 · Code and database

| Gate | Evidence required | Who | State 2026-09-22 |
|---|---|---|---|
| Native suites green on the release commit | Kit, design, app and focused UI counts from `xcodebuild test`, with the commit | Mac | Passed on f49756d: 1,235 / 120 / 122 / 6 (Mac verification handoff) — re-run on the RC commit |
| Web suites green on the release commit | preflight 0/0; in-browser suite count with the module loaded; Node regressions | Mac | Passed on f49756d: preflight 0/0, 489 in-browser, 20 Node — re-run on the RC commit |
| Migrations `20261116090000` and `20261117090000` applied | A fresh `supabase migration list --linked` read AFTER the push, both versions in the Remote column; `tests/db-checks.sql` green | Owner | **Not passed.** Both owed; production ledger last read 2026-09-22 before either existed |
| `courses` redeployed after its RPC | `supabase functions list` showing the new version; one detail fetch from a phone returning tees for an uncached course | Owner | **Not passed.** Owed after the migration |
| `deploy-status` clean on all three layers | The tool's output on the Mac, no `unknown` | Owner | **Not passed** |

## 2 · Devices — the two-phone gate (D372: every row PASS, no known-issues shortcut)

| Gate | Evidence required | Who | State |
|---|---|---|---|
| A1–A11 lifecycle, R1–R7 recovery, G1–G2 guest (`docs/pilot/owner-checks.md`) | PASS on every row with the build number read on each phone; the failed rows re-run on the next build | Owner + one friend | **Not passed.** No hardware results located; the record says NOT RUN |
| Re-up and ruling on a phone | B5–B9 of `docs/pilot/recipient-journeys.md` and one ruling recorded from the roster, with the build number | Owner | **Not passed.** Simulator fixtures only, by their own note |
| A real round posted from the release build | The round's receipt on the phone and the same row read from production | Owner | **Not passed** |
| Integrity rows re-run on the RC build (A3–A6, A8–A10, R1–R5) | PASS with the RC build number | Owner | **Not passed** |

## 3 · Recipient journeys and the share consent gate

| Gate | Evidence required | Who | State |
|---|---|---|---|
| Claim link A1–A7 | The rows filled, build number and web stamp, on a real phone | Owner | **Not passed** |
| Season invitation B1–B9 | The rows filled, build number and web stamp | Owner | **Not passed** |
| Share consent C1–C5 | The Storage API and `share_info` answers copied into the rows, on the release build against production | Owner (the phone) + engineering (the reads) | **Not passed.** Local RLS probes and mocks passed on the Mac; they do not prove the Storage API or the CDN |
| Install-then-reopen (universal link after install) | A7 on a phone that installed after opening the link | Owner | **Not passed** |

## 4 · Comprehension — the timed tests (`docs/pilot/timed-tests.md`)

| Gate | Evidence required | Who | State |
|---|---|---|---|
| G1–G4 with three people who have not seen the app | The results sheet: three rows per gate, build numbers, seconds, met or the miss filed | Owner | **Not passed.** Not run since v23.163 (July) |

## 5 · The store package (submission Oct 1, D371)

| Gate | Evidence required | Who | State |
|---|---|---|---|
| Live web stamp = the release commit | `#obCaption` read on cupseason.app | Owner | **Not read** since the merge; egress from the sandbox is blocked |
| Latest builds and both TestFlight groups read | App Store Connect, the build numbers and each group's newest build, today | Owner | **Not read.** The record names 934 / 795 as of 09-16 |
| Beta App Review passed on the Friends build | The group's state in App Store Connect | Owner | **Not passed** |
| Reviewer account seeded, walkthrough true against the seed | `test-seed` run; every figure in `app-review-notes.md` re-read; the walkthrough league's season running past the review window | Owner + engineering | **Not passed.** The notes still point at a season that ended 09-05 |
| Review notes pasted with the real password | App Store Connect only; never the repo | Owner | **Not passed** |
| Screenshots, 6.9", the kit's eight | The PNGs, from the reviewer sandbox league or a neutralised one | Owner | **Not passed** |
| Metadata complete: listing §1–§8, privacy labels incl. contacts, rating 13+, Support URL `/support`, Privacy URL, export compliance | Each field read back in App Store Connect | Owner | **Not passed** |
| `/get` carries a real invitation or the store link, never a generic page | The `data-href` value in `get.html` on the release commit, and the page read live | Owner supplies the link; engineering pastes | **Not passed.** The button is hidden until a real link exists |
| Legal v2 live | `legal.html` read live with the September 21 dates | Owner | Committed; **not read live** |
| Counsel engaged | The owner's word, with the date the packet went | Owner | **Not done** |

## 6 · Measurement

| Gate | Evidence required | Who | State |
|---|---|---|---|
| Cohorts named | `pilot_cohort_members` non-empty; the Tue 29 report's cohort sections show rows | Owner | **Not passed.** Both pilot tables are empty in production as of 2026-09-22 |
| The weekly growth report runs | `node tools/pilot-scorecard.mjs --as-of <the Sunday the week ended> --store-live false` on the Mac, saved as `docs/pilot/scorecard-<date>.md` | Owner | **Implemented and locally tested; not accepted until the owner's first real run.** The W6 correction pass (Codex's six findings) is on `claude/october-w6-fixes`; every corrected section executed read-only on production for 2026-09-20. The first saved report is generated Tue Sep 29, dated Sun Sep 27 |
| The acquisition log started | `docs/pilot/acquisition-log.csv` with the week ending Oct 4's rows | Owner | **Not started** |
| App Analytics readings recorded | `docs/pilot/appstore-readings.csv` with a reading through Oct 31 (then Nov 30, Dec 31) — the only input that can mark a checkpoint met or missed | Owner | **Not possible yet** — the listing is not live |
| The assistance gate is fed | `pilot_sessions` rows with end times and golfers or ids; no UNKNOWN week left unresolved at a review | Owner | **Not started** — 0 sessions in production |

## 7 · The written assessment (Sep 29)

One page, written from this table and nothing else: which gates passed with
what evidence, which did not, and a go / no-go for the October 1 submission
in one line. A gate whose evidence is a sentence rather than the thing named
is not passed, whoever wrote the sentence.
