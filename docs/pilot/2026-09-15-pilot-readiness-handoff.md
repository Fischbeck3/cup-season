# Pilot readiness — handoff, 2026-09-15

Branch `claude/pilot-readiness-2026-09-15` (from `99fb052`, the tip of the phone-fixes branch). Nothing deployed, uploaded, promoted, invited or sent. The single release record is at the top of `docs/planning/ACTIVE_WORK.md`.

## Verdict

**Ready for Owner testing. Not yet ready for Friends.**

- The server side of every core flow is proven against the real functions with row security on (72 PASS, 0 FAIL, 2 NOT VERIFIED), duplicate starts and posts are refused by the database, and no authorization boundary leaked in 72 probes across six actors.
- What stands between Owner testing and Friends is not code: it is the two-phone checks (`docs/pilot/owner-checks.md`), which need physical phones, and the two pending migrations, which need the owner's push. Build 932 on Owner is the commit `d93b6f4`; the telemetry and the round-holes fix on this branch are **not** in 932.
- One integrity defect was found and fixed on this branch (`20261107090000`): the owner of a league-less round could not read their own hole detail, and the receipt tally then reported a confident zero. It is not in production and not in 932; it becomes live with that migration and a new build.

## Acceptance scenarios

Environment column: **sandbox** = disposable full-chain cluster, every migration including the two pending ones, real functions, `authenticated`/`anon` roles (not superuser); **browser** = the local web build driven by `tools/web-verify.mjs`; **sim** = iPhone 17 Pro simulator; **prod-ro** = the linked project, read-only; **phone** = physical device.

| # | Scenario | Result | Environment | Evidence |
|---|---|---|---|---|
| 1 | Planned round → start → join → score → resume → finish → posted cards | PASS | sandbox | `tests/pilot/authz-flow.py` §1–6 |
| 2 | Registered participants and an account-less guest seated in one round | PASS | sandbox | §2 (three seats, claim token minted) |
| 3 | Repeated start by host = join; concurrent second starter handed the standing round; one live round per booking | PASS | sandbox | §3; `real-flow.py` (race under the unique index) |
| 4 | Score retry idempotent; older write clock cannot overwrite; newer wins | PASS | sandbox | §4 |
| 5 | Interrupted connectivity: offline scores replay by write clock | PASS (server rule) / NOT RUN (phone) | sandbox / phone | §4; owner-checks A6 |
| 6 | Repeated finish answers already_final, posts nothing twice | PASS | sandbox | §6 |
| 7 | Later guest claim posts once; second claim "already"; another golfer refused | PASS | sandbox | §7 |
| 8 | Planned-round linkage survives completion (both rounds carry the booking) | PASS | sandbox | §6 |
| 9 | Valid par provenance survives hydration and finish; historical snapshots claim nothing | PASS | sandbox + Kit | §6 tally; `ParProvenanceTests` (7) |
| 10 | Owner can read own holes on a league-less round; tally honest without evidence | PASS (with `20261107090000`) / **FAIL on production today** | sandbox / prod | found by §6, fixed by the pending migration |
| 11 | Spontaneous league-less Match Play, Wolf, Skins start and finish, cards post | PASS (posting) / NOT VERIFIED (settlement math is client-side; `LiveEngineTests` cover it) | sandbox | §10 |
| 12 | Web starts once through a booking; join hydrates; skew falls through once; refusal starts nothing | PASS | browser | `tests/tee-off-plan-browser.js` (exit 0) |
| 13 | Save status by identity; duplicate names; unknown reads never hide a booking | PASS | browser + Kit | `round-reconcile-browser.js`, `RoundReconcileTests` |
| 14 | Every full-screen flow has a safe exit | PASS (code) / NOT RUN (phone) | code review | live host Close, post cover close, wizard close on every step, receipt preview back, camera cancel; web finish dialog `finBack` |
| 15 | + opens the Play cover with Post a round / Score it live / Start something as distinct doors | PASS (code + web) / NOT RUN (sim signed out) | code, browser | `PostCoverView.swift`; web composer |
| 16 | Invitation, attendance and live-seat states legible (In / Maybe / Out / no reply, pending named, declined excluded, "teed off without a seat") | PASS (web capture) / NOT RUN (phone) | browser | `f10-tee-it-up` capture; server messages in §3 |
| 17 | Errors visible and never claim success (refused start → toast, back in setup; unconfirmed post → "Not confirmed yet") | PASS | browser + Kit | tee-off `denied` case; `RoundReconcileTests` |
| 18 | Authorization: host / seated / invited-unseated / unrelated / anon valid token / anon invalid token, tables and RPCs, claim-token privacy, duplicate-post prevention | PASS 72 · NOT VERIFIED 2 | sandbox | `authz-flow.py` full output in the PR |
| 19 | Pilot record under restricted roles; retry stored once | PASS 13 | sandbox | `tests/pilot/pilot-record.py` |
| 20 | Scorecard runs read-only on production and on the sandbox | PASS (exit 0 both) | prod-ro, sandbox | `docs/pilot/scorecard-2026-09-15.md` |
| 21 | Preflight; Kit; app target; 11 web suites | PASS (exit 0; 1224/198; 100/19; 11×PASS) | local | this session |
| 22 | Two-phone lifecycle and recovery (A1–A11, R1–R7, G1–G2) | **NOT RUN** | phone | `owner-checks.md` |

## What was fixed narrowly (no new mechanics)

- `20261107090000` — `rholes_owner_read` policy; `round_tally` answers `known:false` with no readable hole detail. Logged as D369 before implementation.
- Telemetry attempt ids on both clients for start/join/finish; `receipt_viewed` on the web; `clash_seen` on both — exposure only.

## Exact migrations and deployments owed, in order

1. `supabase db push --linked` — applies `20261106090000` (pilot record) and `20261107090000` (owner reads own holes). Dry-run lists exactly these two. Both validated on the full-chain sandbox with restricted roles. Nothing client-visible depends on `20261106`; `20261107` changes only what the owner of a league-less round can read and what the tally admits.
2. Archive and upload a new native build from this branch's tip (the archive helper computes the number from the commit count) to the **internal Owner group only**; run `docs/pilot/owner-checks.md` on two phones against it.
3. Only after A1–A11 and R1–R7 pass on phones: consider Friends (external group). That is a separate authorization.
4. Web promotion to main is a separate decision; the branch's served files are not live.

## Sample sizes today (production, read-only, no cohort table yet)

33 profiles · 21 have posted a round and 21 have posted again · 9 organizers, 5 opened a competition, 1 completed one, 1 started another · 8 live games finished in 12 weeks, 5 posted every seat, 2 posted nothing, 8 had account-less guests and 0 saw every guest claim · 3 groups with a finished game, 2 with a second · integrity all zero · 9 client-error rows in 4 weeks (8 from 2026-09-03, 1 from 2026-09-11). The 2026-09-11 row and 4 of the 09-03 rows report build `1`, which is what an unarchived local Xcode run carries — development runs, not a tester's build; the other 4 report build 669, the pre-905 era whose field crash was fixed.

These are counts, not conclusions.
