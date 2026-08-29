# issues.json / issues.csv — final issue dataset

Blind usability, gameplay and retention audit of Cup Season, 2026-08-29. Prod build
`34d20b6` (byte-identical `index.html` to this branch). Built by
`tools/merge_issues.py`; re-running it regenerates every file listed here from
`raw/issues.first-pass.json` (`--review` prints the match table without writing).

## Files

| File | What it is |
|---|---|
| `issues.json` | 135 deduplicated master issues, one object each (schema below). |
| `issues.csv` | The same rows, one per issue, every field quoted; `dedupedFrom` joined with `;`. |
| `issues-counts.json` | Counts by severity, category, stage, journey and agent, plus merge provenance. |
| `raw/issues.first-pass.json` | The 127-issue triage output the script starts from (snapshotted on first run; re-runs read it, never `issues.json`). |
| `raw/persona-results.json` | The 424 raw persona items the dataset is built from (12 results). |
| `raw/synthesis-and-validation-results.json` | Top-five findings + 15 validation verdicts; source of the `validation` field. |

## Schema (one issue)

| Field | Meaning |
|---|---|
| `id` | `M-NNN`. Stable but not contiguous: gaps below M-156 are first-pass triage merges; `M-156` onward were appended by this script. |
| `agent` | `;`-separated persona labels that reported it: `A1-casual`, `A2-competitive`, `A3-novice`, `A4-skeptic`, `A5-organizer`, `A6-joiner`, `A7-observer`, `iOS-survey`. A ` (run 1)` suffix marks the first run of a re-run persona (see Provenance); `A6-joiner (attempt 1)` is the superseded joiner attempt. |
| `screen` | Where it was seen (UI path; screenshot names live in `evidence`). |
| `journey` | The persona's own journey label (A Discovery, B Sign-up, C Create/Explore, D First round or Join, E Mid-season, F Finale, G Next season / Side games, plus free-text hunts). Per-persona, not normalised. |
| `observation` | What the persona saw, with UI copy quoted verbatim where captured. |
| `expected` | What a first-time user expected. |
| `actual` | What actually happened / the mechanism behind it. |
| `severity` | `P0` blocker · `P1` major · `P2` minor · `P3` polish. |
| `category` | comprehension, terminology, visual-hierarchy, gameplay, rules, navigation, onboarding, social, monetization, retention. |
| `recommendation` | The fix the persona/synthesis proposed. |
| `confidence` | 1–10 (raw persona items carried 0–1 floats; appended rows are ×10, rounded). |
| `evidence` | Screenshot paths, console text, `index.html` line numbers, report sections. |
| `stage` | Funnel stage: activation · engagement · retention · monetization. Set by triage for the first 127; inferred from journey/category for appended rows (`infer_stage()` in the script). |
| `validation` | `Confirmed UX problem (TOP-n[, TOP-m])` when the issue is a supporting issue of one of the five adversarially validated top findings; blank otherwise. |
| `note` | Free text; two rows carry one: `M-163` (the joiner attempt-1 "code never arrived" harness artifact) and `M-031` (the "You tab opens the wizard" symptom, validator-refuted as a harness artifact — see `critical-findings.md` TOP-3). |
| `dedupedFrom` | Raw persona item ids this row absorbs. Bare ids reference `raw/persona-results.json` (run 1 for `R7-`, `N-`, `ORG-`, `J-`; run 2 for `A*`, `SK-`, `C-`, `IOS-`). Ids ending ` (run 1)` are first-run items of the re-run personas (`A*`, `SK-`, `C2-`, `ISS-`). `J-01 (attempt 1)` is the joiner's superseded first attempt (markdown report only). |

## Counts

Master issues: **135** from **425** raw items
(424 in `persona-results.json` + 1 from the joiner's attempt-1 report).
51 issues carry a `validation` tag (they support TOP-1…TOP-5).

### By severity
| Severity | Issues |
|---|---|
| P0 | 7 |
| P1 | 44 |
| P2 | 65 |
| P3 | 19 |

### By stage
| Stage | Issues |
|---|---|
| engagement | 57 |
| activation | 41 |
| retention | 31 |
| monetization | 6 |

### By category
| Category | Issues |
|---|---|
| comprehension | 28 |
| gameplay | 17 |
| terminology | 17 |
| visual-hierarchy | 17 |
| rules | 14 |
| navigation | 11 |
| onboarding | 11 |
| social | 8 |
| monetization | 6 |
| retention | 6 |

### By agent (an issue reported by several personas counts under each)
| Agent | Issues |
|---|---|
| A3-novice | 48 |
| A5-organizer | 48 |
| A2-competitive | 44 |
| A1-casual | 43 |
| A4-skeptic | 36 |
| A6-joiner | 35 |
| A1-casual (run 1) | 33 |
| A2-competitive (run 1) | 31 |
| A4-skeptic (run 1) | 31 |
| A7-observer | 30 |
| iOS-survey | 27 |
| iOS-survey (run 1) | 25 |
| A6-joiner (attempt 1) | 1 |

`byJourney` is in `issues-counts.json`; journey labels are per-persona and were not normalised.

## Provenance

Seven blind personas drove prod (headless iPhone-viewport browser, real accounts) plus an iOS
screen survey (static landing screens, no taps). Four of them ran twice:

| Persona | Run 1 | Run 2 | In the first triage pass |
|---|---|---|---|
| A7-observer (owner's real account, read-only) | 32 items `R7-*` | — | run 1 |
| A3-novice (`+blind5`, Desert Dogs) | 38 `N-*` | — | run 1 |
| A5-organizer (`+blind1`, The Papago Grind) | 40 `ORG-*` | — | run 1 |
| A6-joiner (`+blind2`) | 32 `J-*` (final attempt) | — | run 1 |
| A1-casual (`+blind3`) | 36 `A*` | 36 `A*` | run 2 only |
| A4-skeptic (`+blind6`) | 32 `SK-*` | 35 `SK-*` | run 2 only |
| A2-competitive (`+blind4`) | 32 `C2-*` | 38 `C-*` | run 2 only |
| iOS-survey | 40 `ISS-*` | 33 `IOS-*` | run 2 only |

The first triage pass built 127 master issues from the 284 items in the right-hand column.
This script folded in the 140 run-1 items of the four re-run personas:

| Family | Raw ids | Items | Folded into an existing issue | Appended as new |
|---|---|---|---|---|
| A1-casual (run 1) | `A*` | 36 | 33 | 3 |
| A4-skeptic (run 1) | `SK-*` | 32 | 31 | 1 |
| A2-competitive (run 1) | `C2-*` | 32 | 31 | 1 |
| iOS-survey (run 1) | `ISS-*` | 40 | 38 | 2 |

How each fold was decided (the gate that fired; "curated" = hand-verified override or a
miss the heuristic could not make):

| Gate | Folds |
|---|---|
| G1 ratio | 32 |
| G2 screen+category+phrases | 34 |
| G3 screen+verbatim-copy | 24 |
| G4 screen+near-duplicate | 5 |
| curated | 38 |

Gates: **G1** `difflib` ratio ≥ 0.6 on observation text against the master or any raw item
it absorbs · **G2** same screen + same category + shared quoted UI string (≥ 10 chars,
containment counts) or ≥ 5 shared distinctive tokens · **G3** same screen + shared verbatim
UI string ≥ 12 chars, category ignored · **G4** same screen + ratio ≥ 0.45 + ≥ 6 shared
tokens. Candidates passing any gate are ranked by a composite score. The 83
`CURATED` entries in the script were added after reading the full match table line by
line; each carries a one-line reason. Folding adds the run-1 agent label and the raw id;
it never changes the existing row's severity, text or stage.

Appended rows: M-156, M-157, M-158, M-159, M-160, M-161, M-162.

The run-2 personas signed out and re-drove the cold paths on accounts that had already been
used in run 1; they flagged that contamination in their own `blockers` (see
`raw/persona-results.json`). Where run 1 and run 2 saw the same thing, the issue now carries
both agent labels — that is two-run confirmation, not double counting.

## Known caveats

- **Joiner attempt 1 "code never arrived" is a harness artifact.** Supabase Auth recorded every
  send; the audit's mail connector hid messages past the 5th in a thread. The item is kept
  (severity `P3`, `note` field) rather than dropped, so the record shows it was seen and why it
  was discounted. Only that attempt's door/Terms observations are usable evidence, and those
  are covered by the final joiner run's `J-*` items; its other items were not merged.
- **M-031 ("You" opens the wizard) is a harness artifact too** — the TOP-3 validators reproduced
  it as a substring click on "You" hitting "Lock it in and invite **You**r crew". It keeps its
  triage severity (P1) so the counts above stay reproducible, carries a `note`, and is struck
  from every backlog in this folder; the real defect is M-030.
- Headless browser: no native share sheet or clipboard, so share/copy outcomes were judged on
  visible feedback only.
- No in-season play was observable (both test leagues defaulted the first tee to Sat Sep 5,
  a week out); no finished season existed, so finale/next-season items are inferred from what
  the live app says about endings.
- The owner's two real leagues have 2 players each; the observer made no writes (DB check: 0
  rounds, 0 posts). The App Review sandbox was unavailable.
- Course search hit five 502s from the `courses` edge function in one session ("TPC Scottsdale",
  "Papago"); "Ken Mc" hit the cache.
- `stage` on appended rows and `journey` everywhere are persona/heuristic labels, not ground
  truth; filter on `category` and `severity` for anything load-bearing. Severity of a folded
  row is the first-pass value; a run-1 item folded into a lower-severity row keeps the row's
  severity (the raw item still carries its own).
- Raw items also carry `impact`, `interpretation`, `userAssumption` and `timeOrAttempts`; those
  are not in the master schema — follow `dedupedFrom` back to `raw/persona-results.json`.
- Test footprint: accounts `jerecho+blind1..6@fischbeck3.com` and `+blind2x`; leagues
  'The Papago Grind' (`THEPTCQ5`) and 'Desert Dogs' (`DESEUU0K`); rounds, a $5 match-play
  story, guest 'Marco', a skins round and board messages inside those leagues only.

*Companion documents in this folder: `README.md` (start here) · `blind-ux-audit.md` (master report) · `critical-findings.md` · `user-journey-map.md` · `gameplay-loop.md` · `rules-and-mental-model-audit.md` · `retention-audit.md` · the six `synthesis-*.md` files · `raw/` (persona reports, `persona-results.json`, `synthesis-and-validation-results.json`) · `screenshots/`.*
