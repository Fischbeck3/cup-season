# W6 correction pass — each finding reproduced on the old code, then fixed

2026-09-22 · Claude (remote) · branch `claude/october-w6-fixes` from
`origin/codex/october-w6-review` at `82cb92f`. The findings are Codex's
(`docs/planning/2026-09-22-w6-review-and-claude-prompt.md`). **Every input on
this page is SYNTHETIC** except the section marked *production, read-only*.

How the old answers were obtained: `tools/lib/growth-report.mjs`,
`tools/pilot-scorecard.mjs` and `tests/pilot/scorecard.sql` exactly as they are
at `82cb92f`, run on the same inputs as the new tests — the module called
directly, the runner in a detached worktree, and the SQL on the synthetic
fixture database (`tests/pilot/fixtures/w6-fixtures.sql`, loaded into a
disposable copy of the full 254-migration sandbox chain) with its `now()`
pinned to the end of the report date, since the old SQL had no cutoff of its
own. The new answers are asserted by the tests named in each row.

## 1 · P1 — the assistance gate

| Input (synthetic fixtures) | 82cb92f said | Corrected | Test |
|---|---|---|---|
| Friends, week of Oct 19: two assisted sessions, two games, both covered | report dated Oct 25: `friends · 4 sessions · 8 games · ok` — four weeks pooled, every finished game counted as unassisted | `2026-10-19 · friends · 2 · 2 · assisted 2 · unassisted 0 · STOP` | `scorecard-db`: an all-assisted week is a STOP |
| Friends, week of Oct 12: two sessions on the SAME game | (pooled into the 4 above) | `2 sessions · 3 completions · 1 assisted · 2 unassisted · ok` | two overlapping sessions … one assisted completion |
| Independent, week of Oct 26: one session with no end, one naming only a free-text group | report dated Nov 2: `independent · 3 · 4 · ok` | `2 · 2 · 0 · 0 · unknown 2 · UNKNOWN: 2 completion(s) lack session evidence` | incomplete session evidence is UNKNOWN |
| Competition: a good week (Oct 26) then an assisted week (Nov 2) | report dated **Oct 25**: `competition · 2 sessions · 4 games · ok` — both sessions and all four games are AFTER Oct 25 (no upper bound) | Oct 25: no such week yet. Nov 2: `Oct 26 · ok`, `Nov 2 · 1 · 1 · assisted 1 · STOP` | a good prior week does not hide a failing current week |
| Friends, week of Oct 19: game 4 posted both players' cards, game 5 none | not distinguished (cards were never read) | `completions 2 · cards_posted 2` — a completion is a game, never a card | an all-assisted week … one game with two cards is one completion |

The old query also matched a game to a cohort only through
`guest_profile_id`/`claimed_profile`, so a member seat — every golfer in a
league game — could never be recognised. The corrected match uses every
participant: the starter, member seats (through the league membership),
visitor seats and claimed guest seats.

## 2 · P1 — checkpoints from partial or duplicate data

| Input | 82cb92f said | Corrected | Test |
|---|---|---|---|
| Only Oct 4 logged, 100 downloads; report Nov 1 | Oct `missed`, cumulative 100 | `unverified`; logged subtotal 100 (1 of 4 weeks) | review case 1 |
| The Oct 4 / by_hand row (300) pasted twice; report Nov 1 | Oct `met`, cumulative **600**, no problem reported | both rows rejected: *lines 2, 3 are all week 2026-10-04 / channel by_hand — one row per key; merge them* · `unverified` | review case 2 |
| 450 through Oct 25, 100 in the week ending Nov 1; report Nov 1 | Oct `missed`, cumulative 450 | `unverified`; subtotal 450 through Oct 31, labelled *not a verified total* | review case 3 |
| A dated App Analytics reading of 512 through Oct 31 | (no such input existed) | `met` — and 480 through Oct 31 is `missed`; 530 through Nov 2 is `unverified` (it cannot say when) | a dated App Analytics reading decides it |

## 3 · P2 — one reporting cutoff

| Input | 82cb92f said | Corrected | Test |
|---|---|---|---|
| Report dated Oct 5 with a Nov 1 log row | printed `\| 2026-11-01 \| … \| 90 \|` | row left out and counted: *Left out as after the report date 2026-10-05: 1 log row(s)* | a backdated report leaves out later log rows |
| Every SQL section | `now()` / `current_date`; the date reached only the title | one `:CUTOFF` (the first instant after the report date in `--tz`) in every temporal filter; no `now()` left in the file | the SQL has one clock |
| Account at 23:30 on the report date, another at 00:10 the next day | both counted (no upper bound) | the first counts, the second does not | the end of the report date is the cutoff |
| A round posted Sunday 23:50 in Phoenix (Monday 06:50 UTC) | UTC weeks | the Phoenix week; `--tz UTC` moves it | weeks are local |
| An invitation's status, a claimed seat, an abandoned round | shown as if historical | columns end `_now`, and the report says they are today's state | current-state columns carry _now |

## 4 · P2 — one eligible population

| Input (report dated Nov 2) | 82cb92f said | Corrected | Test |
|---|---|---|---|
| Week of Oct 5: one real account plus the App Review account, a test seed and a deleted account; rounds by the founder, the seed and the deleted account | accounts **2**, first rounds **4** | accounts 1, first rounds 1 | founder, App Review, test-seed and deleted accounts are outside every activation count |
| Week of Oct 26: the founder's solo game | games **5** | games 4 (a real game needs an eligible golfer) | a real game is non-sandbox with an eligible golfer |
| Week of Nov 2: an account ten minutes after the cutoff | accounts **2** | accounts 1 | the end of the report date is the cutoff |
| Week of Oct 19: two first rounds from August accounts, no new account | same numbers, no distinction | `activation_weekly` (events) beside `activation_cohort` (the signup funnel) | weekly events are not a signup funnel |

**Production, read-only (2026-09-22, report date 2026-09-20).** The corrected
SQL executed section by section on the linked project (SELECT only; nothing
saved as a report). Two figures the earlier W6 record quoted were artefacts of
exactly these defects:

- *"8 accounts in the week of Aug 24 with 9 first and 9 second posted rounds"*:
  that week's accounts are 8 test-seed accounts (121 rounds between them) and
  the App Review account (18). **Eligible accounts that week: 0.**
- *"35 guest seats minted and 0 claimed"*: the baseline defaults a claim token
  onto every seat. Of 41 token-carrying seats in non-sandbox games in those
  eight weeks, 21 are member seats and 15 known visitors; 5 are account-less
  guest seats, 1 of them claimed — and in real games (an eligible golfer
  present) there is 1 guest seat, claimed.

## 5 · P2 — malformed input

| Input | 82cb92f said | Corrected | Test |
|---|---|---|---|
| `week_ending` `2026-99-99` | accepted with no problem; the runner then **crashed**: `RangeError: Invalid time value at mondayOf (growth-report.mjs:163)` | *line 2: week_ending "2026-99-99" is not a real calendar date; the row was left out*; the report renders | only a real calendar date is a date · a malformed log is reported row by row |
| `2026-02-30`, a Monday `2026-10-05` | accepted (`2026-02-30` → Monday `2026-03-02`) | rejected, each with its reason | same |
| Counts `1e2`, `0x10`, `3.0` | accepted as 100, 16, 3 | rejected: digits only | a count is digits only |
| An unterminated quote; an unquoted comma in notes | 2 rows and 1 row accepted silently | *a quoted field is never closed* · *9 cells where the header has 8 — check for an unquoted comma* | CSV … reported, not guessed |
| `--as-of 2026-99-99` | exit 0, a report titled 2026-99-99 | exit 2: *not a real calendar date* | a report date is a real calendar date |
| `--store-live yes`, `--bogus` | `yes` read as **false** (anything not starting with `t`); `--bogus` ignored, exit 0 | exit 2 with one sentence each | flags are strict |
| `--store-live false` with 25 logged store downloads | no contradiction reported | *CONTRADICTION: …*; no checkpoint judged | store-live false with any App Store count is a contradiction |

## 6 · P2 — the attribution writer that already exists

The earlier inbox entry said `came_via_kind` is never written. It is written —
by `log_growth_event` on `profile_created` (`20260828160000`, lines 133–136) —
and both clients call it at card completion. Traced, not assumed:

| Step | Evidence | Test |
|---|---|---|
| Intent persisted before auth | `?claim=` → `cs_claim`, `?join=` → `cs_code`, at load | `attribution-trace`: the intents are still pending when the card is saved |
| Not consumed before the card | `boot()` returns at the card gate before it reads `cs_code`; `claimPendingRound` refuses without a marker | same |
| Card completion sends it | the card-save block, run as written: claim → `('profile_created','claim',<token>)`; join → `('profile_created','join',<code>)`; neither → kind and token null; a claim wins over a join | a pending claim … a pending join … a claim wins … a direct arrival |
| The phone does the same | `CardGateView` calls `CSGrowth.profileCreated()` after `set_profile`; claim, then join, then direct; **DEBUG builds never log** | the phone sends the same three shapes |
| The RPC writes once, through the authenticated grant | sandbox, one rolled-back transaction: claim → `claim\|<token>`, join → `join\|synth1` with the league resolved, direct → blank, a second call never overwrites, an existing profile gains nothing | `scorecard-db`: log_growth_event writes attribution once … |
| Exactly one writer | `set came_via_kind =` appears in one migration | there is exactly one writer |
| Deployed = source | production `log_growth_event` body hash equals the chain's (read earlier this session) | — |

Why production reads blank: the newest eligible account predates the writer
(the first production growth event is 2026-08-29; no eligible account has been
created since — production, read-only, above). **Nothing is broken, so nothing
was added**: no second writer, no backfill, no new telemetry path. The
first-event platform column is renamed and labelled a **proxy**
(`signups_first_event_platform`): the first event can follow sign-up by days
and come from the other client, and an event without a platform is
`first_event_unlabelled`, not guessed.

What remains unproven: a real device's release build sending the event after
a real claim. That is a device check for the owner — a DEBUG build cannot
show it.
