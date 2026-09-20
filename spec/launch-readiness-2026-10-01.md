# Cup Season — Launch readiness for 1 October 2026

**Date:** 2026-09-20 (Saturday; launch day is Thursday 2026-10-01, eleven days
out) · **Question asked:** *imagine we go live October 1 — how ready are we, what
do we build until then, and where should the app be that day and a year later.*
The vision half is `vision-2026-10-01.md`. · **Method:** four parallel
deep-dives (mechanics coverage vs `spec-v1.0.md`; technical/ops; product/UX/QA
open findings across every prior audit; business/GTM/legal), each read against
`main` **and** the unmerged `claude/pilot-readiness-2026-09-15` (PR #6), plus
direct verification of the load-bearing claims. · **Posture:** signing off, or
not, for two different launches — a *staged* launch (Friends plus the first
independent groups) and a *cold public* launch (App Store, open door, outreach).

**What could not be verified from this sandbox:** production reads (no Supabase
CLI or credentials here), the live site's stamp and the Netlify previews
(outbound to `cupseason.app` is blocked by the proxy), anything on a physical
phone. Production counts below are the 2026-09-16 scorecard and the 2026-09-15
release record on PR #6, and are labelled as such.

This document builds on two earlier audits rather than replacing them:
`launch-audit-2026-07-18.md` (principal-engineer pass, 1–10 scorecard) and
`docs/pilot/2026-09-18-prelaunch-audit.md` on PR #6 (strict letter grades, the
staged week). Where they already said it, this says only what moved.

---

## 0 · Verdict

**Staged launch on October 1 — ready, if the eleven-day list in §4A is done in
order.** The engine, the walls and the server side of the loop are launch-grade
and proven against the real functions with row security on. What stands between
today and a Friends build in strangers' hands is operational: merge and deploy
the verified branch, push two revokes, run the two-phone checklist, submit one
build for Beta App Review. About five owner-days of work, most of it waiting.

**Cold public launch on October 1 — not ready, and by the project's own
ratified gates not to be attempted.** Three things say so, none of them
architecture: nobody outside the founder has touched the current build on a
phone; the growth loop the public launch depends on has been exercised once in
production; and the product's comprehension is graded C by its own audit while
the legal set is a July stub. The earliest honest public cohort is the D→E gate
in `docs/pilot/gates-and-stop-conditions.md`: after one full competition
lifecycle by a group the founder is not in, three to five weeks past a Friends
build that passes. Call it late October at the earliest, November more likely.

The strongest fact in production stands: every golfer who ever posted a round
posted again (21 of 21). The product keeps the people who get in. Launch is
about the door.

---

## 1 · Launch Readiness Index

One number, so it can be tracked weekly. Eleven areas, the same ones the
2026-09-18 audit graded, each scored 0–10 and weighted; the index is the
weighted sum out of 100. Weights are a proposal — the engine and the walls carry
the most because a scoring or privacy defect ends the product, distribution and
devices carry the next most because they are what a launch *is*.

| # | Area | Weight | July 18 (1–10) | Sep 18 (grade) | **Sep 20 (0–10)** | What moved / what holds it down |
|---|---|:-:|:-:|:-:|:-:|---|
| 1 | Score integrity & engine | 15 | Reliability 4 | A− | **8.5** | 12/12 rounds and both standings recompute exactly; rounds immutable; duplicate posts refused by the database. Held down by: no commissioner adjustment pen (§3.1), the attendance-over-skill band skew (D142 softened it; feel question open). |
| 2 | Authorization, privacy & security | 15 | Security 3 | A− | **7.5** | 72 restricted-role probes PASS / 0 FAIL; anon surface pinned at twelve by preflight and db-checks; emails sealed. Held down by: `20261109090000` (TRUNCATE/TRIGGER revoke) and `20261110090000` (claimer read policy) written, validated, **not pushed**; July's M5/M6 still open; no rate limiting on anon RPCs beyond the platform's; CSP still Report-Only since July. |
| 3 | Core loop — server | 10 | — | A− | **8.5** | Start-or-join per booking, seat-gated joins, idempotent finish, claim-once, offline write clocks — proven on the real functions. Known trap: only the host or a league-member seat can finish a league-less round (D107, told to testers). |
| 4 | Core loop — clients & devices | 10 | UX 8 | C+ | **4** | The two-phone checklist (A1–A11, R1–R7, G1–G2) has **never been run**; no physical iPhone Safari pass is on record; three composer UI tests blocked on simulator sign-in; production shows 21 of 28 live rounds abandoned and 2 of 8 finished games posting nothing. |
| 5 | Onboarding & comprehension | 10 | UX 8 | C | **5** | The wizard discloses every rule and explains none; the allowance is a bare percentage; the five timed gates (profile < 2 min, join < 30 s, post < 60 s, standings < 10 s) were last run in July on v23.163; composer opened 219 times, submitted 24 (2026-09-11 read). |
| 6 | Growth loop | 10 | — | D | **3** | Built and fail-closed; almost unexercised: 7 share links minted, 1 opened; 70 guest seats ever, 55 in rounds never finished, 1 claim. The claim journey itself passes 24/24 on the branch; the dead end is upstream (unfinished rounds mint links nobody can claim) and the signed-out door says nothing about it. |
| 7 | Distribution currency | 10 | — | D+ | **3** | Live web = `c6acc53` (Sep 15); Friends TestFlight = build 795 (Sep 12, pre-D359 identity); PR #6 is 28 commits, 150 files ahead and carries F1–F13, the note door, the Compete repairs, telemetry. Nobody but the owner can see any of it. |
| 8 | Platform & store | 5 | App Store 3 | B | **6.5** | Account deletion on both clients (`delete_account`, tombstone); legal page live; signing recovered (cert to 2027-09-14); 934 VALID in the Owner group. Held down by: App Review never submitted; review notes point at a season that ended 09-05; no `/support` URL; no legal entity for the copyright line. |
| 9 | Ops, observability & measurement | 5 | — | B+ | **7** | `deploy-status`, `ship.sh`, preflight (69 checks, check 50 new), db-checks (34), the read-only scorecard, attempt-keyed telemetry, founder desk. Held down by: cohort table empty (assisted vs unassisted indistinguishable), `v_growth_funnel` has no reader, no crash pipeline beyond `client_events`, the three webhooks live only in the dashboard, CI runs two of five unit files. |
| 10 | Legal & compliance | 5 | (in App Store 3) | — | **4** | Three documents, ~40 lines total, dated July 18, no counsel: no minimum age or age gate (D192 leaves it open), no governing law, liability or dispute terms, contacts hashing (D251) undisclosed, third parties unnamed. Two money postures at once: the disclaimer's "never holds, takes no cut" and the product's D39 ledger line. |
| 11 | Business readiness | 5 | — | C | **4** | Free by decision (D183: until 1,000 onboarded golfers; 33 today), so not a launch blocker by plan. Held down by: the paid offer has been put to nobody; the pilot interview guide quotes July's $49–99 instead of D101's bands; the Founding League flag's `ids` set is empty (PIGL was never written in). |

**Launch Readiness Index, 2026-09-20: 58 / 100.**

**If §4A is completed by October 1: 70 / 100** (distribution 9, devices 7,
security 8.5, growth 4, comprehension 5.5, platform 7 — the rest unchanged).

Proposed thresholds, for the owner to ratify with the gates:

| Launch shape | Index | And, regardless of the index |
|---|:-:|---|
| Stage B, Friends on a fresh build | ≥ 65 | Every row of `owner-checks.md` PASS on that build; the two revokes pushed; zero integrity non-zeros |
| Stage C, independent groups | ≥ 70 | Friends complete two rounds each, the second unassisted |
| Stage E, capped public cohort | ≥ 80 | Growth ≥ 6, comprehension ≥ 7, legal ≥ 6; one full competition lifecycle closed by a non-founder group; the paid offer interviewed with five organizers |

Reading the trend: July's gating scores were Security 3, Reliability 4, App
Store 3 — all three are now the top of the table. The gates have moved to
*legibility, devices and distribution*. That is progress, and it is also the
part of the work that cannot be done from a sandbox.

---

## 2 · The frame — what is where

| Layer | `main` (= live web) | PR #6 `claude/pilot-readiness-2026-09-15` | Production database | TestFlight | Nowhere in git |
|---|---|---|---|---|---|
| Commit | `c6acc53`, 2026-09-15 | `6c9712d`, 2026-09-19; 28 commits ahead; CI green; mergeable; subsumes draft PR #5 | — | Owner group: build **934** from `1aac23a` · Friends group: build **795** (2026-09-12) | Codex's `20261111090000_course_cache_atomic` + the `courses` function change (D370) — a local Mac workspace only |
| Migrations | 243 on disk, latest `20261104090000` | 248 on disk, latest `20261110090000` | **246 applied**, latest `20261107090000` | — | 249 on the sandbox with Codex's file |
| Pending push | none visible — but a `db push` from a `main` checkout **fails** (`LegacyDbPushMissingLocalError`): main is behind production | `20261109090000`, `20261110090000` — validated on the full-chain sandbox, self-checking | | | `20261111` must land **before** the `courses` redeploy, or every detail fetch fails on a missing RPC; `ship.sh` encodes the opposite order for `posts_kind_check` and nothing for this |

Corrections to standing documents found on the way: `20261024090000` is applied,
not held (the deployment packet §10 says so; `ACTIVE_WORK.md` still says held);
the 2026-09-14 release handoff says live web `1bc307f`, the release record says
`c6acc53`; `ACTIVE_WORK.md`'s ownership table names Codex sole editor of
`index.html` while every September `index.html` commit is Claude's under the
09-13 override; `CLAUDE.md`'s monetization section says "parked pending focus
groups" while the operative rule is D183's counter plus D135's checklist.

---

## 3 · Findings by area

Each finding names its evidence. Severity: **P0** blocks the staged launch ·
**P1** fix before strangers · P2 after signal. "On branch" means fixed on PR #6
and not live.

### 3.1 · Engine and mechanics

**Coverage against `spec-v1.0.md`, read from the PR #6 tree (migrations
≤ `20261104` identical to `main`).** Built and verified by function name, with
no caveat worth a line: differential and allowance (`score_round`,
`v_rounds_ranked`); the 12/9/7/6/5 bands (`cup_points`, exact to §2.2);
nine-hole half value and the 0.5 floor credit; the counting cap with
displacement and Unlimited = NULL (D347); floors, penalties and forfeits in
`close_month` with the consequence sentence in the ledger; the partial-month
and join-month waivers; month close on cron with the sentinel and the board
post; the weekly clash; the Cup Final window, seeds and head start; the endgame
dial; the §14.3 tiebreak ladder; 48-hour grace, crown, Trophy Room; the pot
ledger and payouts; Points King; blind draw, Pro assign and the start guards;
late joiner to the thinnest squad; the join covenant on every door; the
WHS-lite engine with the three-round takeover; receipts with every lens
(D362, applied); Match Play, Wolf, Skins and Sunningdale; guests and claim
links; scorecard scan; the Ryder, the Major, the callout, the pride bet; plans,
RSVP, the after-golf follow-up (D345, **applied** — the "held" label in
`ACTIVE_WORK.md` was corrected three times and still stands there); the round
that remembers its plan and the tally (D367/D369); month facts and pulse;
`run_it_back` (**applied** — the 09-14 sprint packet and the iOS file comment
that call it unpushed are stale); the memory layer; curated push.

Everything with a caveat, individually:

| Mechanic | Spec § | Status | Evidence · caveat |
|---|---|---|---|
| Pro void / edit a round, override log | §9 | **UNBUILT** | `rounds.voided` has no writer; `delete_round` is owner-only; `commissioner_log` is written by eight RPCs and read by no client. §9 was never amended to the immutability rule. |
| Commissioner points adjustment with reason | §16 | **UNBUILT** | See below — the ledger has no pen. |
| Handicap ceiling 30.0, +1.0 rise cap, exceptional-score cut | §5 | **UNBUILT** | Only `handicap_index_asof` exists; anti-sandbag rests on the 12-point band ceiling and the three-round takeover. |
| 7-day posting wall, "posted late" stamp | §9 | **UNBUILT** | No enforcement; a backdated round scores silently. |
| Verification tiers (honor / attested / GHIN); Cutthroat witness | §6, §8, §13.3 | **DORMANT** | Stored in `league_settings`, read by nothing in scoring; `attested` flips only for an own-device live seat; partner confirm writes `confirmed_at` and does not flip it. The covenant copy promises what nothing enforces. |
| Solo minimum roster (D205: 2) | §8 | **UNBUILT** | `lock_league` checks the roster only when `structure <> 'solo'`; a one-member solo season can lock. |
| Snake draft engine | §15 | **BUILT, orphaned** | `start_draft` / `make_pick` / `undo_pick` granted and driven by iOS `DraftNightScreen`; hidden from both wizards; the web has no caller. If a league ever lands on `snake`, the desk cannot pick. |
| Captains-pick engine; live draft with a pick clock; paced reveal (D54) | §15 | **UNBUILT** | `'live'` is only a CHECK value; no timer, no reveal scheduling. Neither wizard offers them — not a launch blocker. |
| Iron Man, Most Improved | §4, §14.3 | **PARTIAL** | Computed at render on both clients; no server row; the two clients can disagree. |
| Week snapshots / Week Review | §14.0 | **PARTIAL** | Cut by a fixed Sunday cron while weeks are anchored to the real first-tee weekday (D213); `on conflict do nothing` freezes a mid-week table as "week N" for a non-Sunday league. |
| Standings snapshot at month close | §14.2 | **UNBUILT** | `close_month` takes none; the weekly snapshot stands in. |
| Cup Final open / season close date | §14.0 | **BUILT, UTC** | The tick keys on `current_date` (UTC), local only for the horn — Phoenix leagues flip at 17:00 the evening before. Month-close cron is Phoenix-fixed for every league timezone. |
| Course / tee requirement toggles ("rated tees") | §2.4 | **UNBUILT** | Preset prose only; no column. |
| Sim-round feed flag | §2.4 | **PARTIAL** | The filter exists; the "flagged in the feed" copy exists only in demo. |
| Email | D68 | **PARTIAL** | Season recap and cancellation notices only; no digest; invitations written, never sent. |
| Attestation stage 2 "that wasn't me" void (D125) | §13.1 | **UNBUILT** | — |
| Nassau, presses | §13.2 | **UNBUILT** | Spec roadmap. |

**Spec prose the code has outgrown** (stale text, not defects — amend the spec):
§3.2 "commissioner-approved" bye (the code auto-spends the first, D14); §14.1's
15th-of-the-month rule (D161 waives the whole join month); §9's and §4's tie
ladders (the code follows §14.3 everywhere); §9's join-until-halfway (now the
Pro's door only); §15's "snake retires to the roadmap" (it exists, phone-side);
CLAUDE.md's "server-side draft engines unbuilt" (half true).

Verified directly this pass, beyond the coverage table:

- **The Pro has no adjustment pen (P1, spec §16 and CLAUDE.md rule 4).** The
  only writers to `season_adjustments` are `close_month`, `set_member_bye`, the
  wizard defaults and `start_season`; there is no `adjust_*`, `override_*` or
  `void_*` RPC anywhere in `supabase/migrations/` or `packages/db/contract.psv`,
  and `delete_round` is owner-only. The desk began *reading* the ledger on
  2026-09-13 (D355). A disputed score in a real-money league has a ledger with
  reasons and nobody who can write one. Not a launch blocker for Friends; a
  real blocker for the competition pilot (Stage D).
- **`is_league_member()` never reads `left_at` or `suspended_at`** (P1): zero
  occurrences in any of its definitions, while both columns exist and are
  written in 38 and 33 places. A member who left can still enter a Major or
  create a Ryder. Reported by the complete-the-week review (2026-09-13) and
  confirmed by grep here; not exercised against the sandbox in this pass.
- **Points still reward attendance over golf** (P1 feel, not integrity): the
  season sim found r = +0.96 with rounds counted and +0.04 with skill; D142 cut
  the default cap from 4 to 3; the 09-18 audit calls the band skew "a feel
  question still open". The first real season will surface it in the group
  chat; decide before Stage D.
- **Season two enrols without consent** (P1 decision): `run_it_back` is in
  production (`20260928093000`, inside the 246), re-seats the roster as a count
  and refuses to touch memberships; the covenant re-fire is unreachable because
  neither client sends the stake and length; `league_members.agreed_at` does
  not exist. The sprint packet's candidate C names the smallest increment.
- **The Major**: live board ties alphabetically while `settle_major` uses
  countback, so the leader can differ from the winner; the Major pot is client
  multiplication with no ledger row (P1, money legibility; from the 09-13
  review, not re-verified here).
- **Stale league index at lock** (P1, inbox 2026-09-17): `league_members.
  index_current` reads 18.0 / `self` while profiles read 10.5 / 9.5; scoring is
  untouched (`v_rounds_ranked` reads `rounds.index_at_post`) but a league live
  match seeds its strokes from the league copy.

### 3.2 · Authorization, privacy, security

- **Two migrations owed (P0 for the staged launch — class, not consequence):**
  `20261109090000` revokes TRUNCATE/TRIGGER/REFERENCES/MAINTAIN that production
  default privileges added on the two founder-only pilot tables (RLS does not
  govern TRUNCATE; 0 rows affected; caught by db-check 23; preflight check 50
  now prevents the class); `20261110090000` lets a golfer who claimed a card
  read the round they played in, so a claimed receipt's tally stops going
  silently blank. Both validated on the full-chain sandbox with row security on.
- **Grant discipline holds:** every post-`20260902` migration with `grant
  execute` also revokes from public/anon (47 files, 0 misses); the anon surface
  is exactly the twelve CLAUDE.md names; `has_any_column_privilege` reasoning
  stands.
- **Open from July's follow-ups (P1 for public, low for Friends):** M5
  `add_event_player` without consent; M6 client-chosen league codes with no
  attempt ledger on `league_by_code`; `squad_members_one_per_season` still on
  `(member_id, squad_id)` and enforces nothing. Closed since July: M4, M7, L1,
  L8, the XSS sinks, `test-seed` founder gate, both CHECK bombs.
- **Rate limiting** exists only on `set_handle`; anon RPCs rely on Supabase
  platform limits (P1 for public).
- **CSP is Report-Only** since 2026-07-18 (`netlify.toml:30`); everything else
  in the header set is enforced (P2, one line once the console is clean).
- **Edge functions clean:** every secret via `Deno.env.get`; `push` returns
  JSON, never a bare `ok`; both `--no-verify-jwt` functions gate on the shared
  header; `scan` kill switch and caps intact.
- **The three webhooks live only in the dashboard** — no `net.http_post` or
  trigger in any migration — so the D68 misroute landmine cannot be
  reproduced from source (P2, ops).

### 3.3 · Core loop — clients and devices

- **Zero physical-phone checks, ever (P0).** `docs/pilot/owner-checks.md` rows
  A1–A11, R1–R7, G1–G2 are NOT RUN; "actual iPhone Safari" has been owed on
  every web checkpoint since 09-13. Airplane-mode scoring (A6), kill-and-resume
  (A5), the birdie moment (A7) and the recap's *Round posted* (A8/A9) are
  proven on the server and in a viewport, not on hardware.
- **Live rounds are not finished.** 28 started / 21 abandoned / 7 finished
  (09-11 read); 79 % of guest seats sit in rounds that never finished. Some
  are the founder's own test starts; the split is not established. This is the
  single upstream cause of the growth loop's D.
- **Suites red without anyone noticing:** Compete (two) since F11, CSDesign
  (three) since D359, `homefold` since 09-07 — all repaired on the branch, all
  outside CI, which runs preflight and one unit file. `homefold` fails on
  `main` today (29/30).
- **Composer conversion ~1 in 9** (219 opens → 24 submits) and nobody has
  established why; `receipt_viewed` shows two golfers opened a receipt in four
  weeks.

### 3.4 · Onboarding and comprehension

- The wizard **discloses every rule and explains none**; the allowance reads
  "N percent of your index" with no meaning attached; the founder did not
  retain it. A one-sentence gloss for the wizard and three words in the
  covenant clause await a yes (09-18 decision 3).
- "How do I win": the endgame sentence exists (D126) but ties, seeds and the
  hollow final are still four taps deep.
- The five timed gates have not been run on any build since v23.163 (July);
  D33 replaced them with passive `v_pilot_gates`, which no document has read
  since.
- The signed-out door still says *I have a league code* (LV-14: the container
  is a season); the door's two side wings are hand-authored fiction (MARCUS /
  DANA / RAY) — the last in the app; fine for a pilot, a decision for public.
- iOS prints raw database errors (no `humanError` gate) — voice audit row 60.

### 3.5 · Growth loop

- **The claim journey works** (24/24 on the branch with `20261110`). **The dead
  end is upstream and unaddressed:** an unfinished round still mints guest
  links that land on the plain door with no sentence. Codex's question 3 is the
  right one — explain it signed-out, or stop minting a link for a round that
  was never finished. Either is small; neither is decided.
- Email invitations are written to `invites` and never sent; "your first
  counting round" is never said (sprint candidate A, small, no decision
  required for the first item).
- Instrumentation began producing rows only after D185; `v_growth_funnel` has
  no reader but the SQL editor; 0 growth-attributed profiles.

### 3.6 · Distribution currency

- One merge, two pushes, one build fixes it. PR #6 is reviewed for by Codex
  (requested 09-19), CI green, mergeable. Merging it also subsumes draft PR #5.
- Build numbers come from `git rev-list --count HEAD`; a shallow clone counts
  76 and equal-length parallel branches collide (P2).

### 3.7 · Platform and store

- Realistic by October 1: **TestFlight external (Friends) on a fresh build —
  yes**, if the two-phone checks pass this week and Beta App Review (typically
  one to two days) is submitted by mid-week. **App Store public — no**, by the
  D→E gate and by the state of the review notes (walkthrough league's season
  ended 09-05; reviewer password placeholder live).
- iPhone only (`project.yml`); the web is the Android app and that is the
  ruling.

### 3.8 · Ops, observability, measurement

- The operating system exists on the branch: staged pilot A–E, gates and stop
  conditions, weekly review, session log → `pilot_sessions`, the read-only
  scorecard. **The cohort table is empty**, so assisted and unassisted are one
  number until the founder names cohorts.
- Metric definitions differ across `gtm-year1.md` §1, D135, D183 and the pilot
  gates; no D7/D30 anywhere, deliberately ("golf is weekly at best").
- Rollback exists per release (the deployment packet's rehearsed procedure);
  there is no general client rollback beyond Netlify keeping the last good
  deploy, no status page, no incident runbook, and support is a personal
  address. One person is builder, support, ops and publisher.

### 3.9 · Legal and compliance

- `legal/*.md` + `legal.html`: privacy (~15 lines), terms (~8 lines), pot
  disclaimer (undated), all "Last updated July 18, 2026", linked from the door
  and Settings, live. Account deletion is real (six iterations to
  `20261001140000`-era `delete_means_delete`), but the policy still says only
  "you may request to delete".
- Missing for a public door: minimum age / age gate; governing law, liability
  and dispute terms; the named third parties (Supabase, Brevo, Netlify,
  GolfCourseAPI, Anthropic); contacts hashing disclosure; a legal entity;
  counsel review. Two money postures in one product (disclaimer vs D39 ledger
  line).

### 3.10 · Business

- D183 makes the answer for October 1 simple: nothing is charged, nothing is
  sold, "no in-app purchases" is the store answer. Not a blocker.
- Owed anyway, cheaply: write PIGL's id into `app_flags.pricing.founding.ids`;
  fix the interview guide's numbers to D101; put the offer to five organizers
  during Stage C, because the D→E gate requires it.
- The socials plan is keyed to an August App Store launch that did not happen;
  its one "daily content" week (Presidents Cup) is this week. Decide whether
  to use it or let it go — silence is fine, a stale calendar is not.

### 3.11 · Process

- Two open PRs on the same work (#5 inside #6); a migration and a function
  change on one laptop (Codex's `20261111`, D370) that production and the
  branch both need in a specific order; an ownership table that no longer
  describes who edits `index.html`. None of this is a defect in the product;
  all of it is how a launch week goes wrong.

---

## 4 · Action items

### 4A · Gate-clearing — must be done, in this order, before October 1

| Day | Owner | Item | Done when |
|---|---|---|---|
| Sat 20 – Sun 21 | Codex | Review PR #6 at `6c9712d` (requested 09-19; questions 1–3 in the review package). | Findings returned or "clean". |
| Sun 21 | Claude | Fix PR #6 review findings, if any; keep the diff narrow. | Preflight 0 · web suites PASS · Kit and app green on the Mac. |
| Sun 21 | Owner | From the **PR #6 checkout** (not `main`): `supabase db push --linked` → `20261109090000`, `20261110090000`. Then read back: db-checks 34/34; `pilot-record.py` 13 PASS. | `deploy-status` clean; check 23 PASS. |
| Sun 21 | Owner | Merge PR #6 → Netlify builds `main`; confirm `#obCaption` reads the merge SHA. Close PR #5 as subsumed. | Live web = branch tip. |
| Mon 22 | Owner | `tools/ios-archive.sh --upload` from the merged tip → Owner group; install on both phones; read the build number on each device. | Two phones on the same build. |
| Mon 22 – Tue 23 | Owner + one friend | Run `docs/pilot/owner-checks.md` in order: A1–A11, R1–R7, G1–G2. Record PASS / FAIL per row with build numbers. **This is the Friends gate.** | Every row PASS, or a FAIL list. |
| Tue 23 – Wed 24 | Claude | Fix the FAIL list; new build if anything changed. | Re-run the failed rows only. |
| Wed 24 | Owner | Submit the passing build for **Beta App Review**; on approval, promote to Friends. Name cohorts in `pilot_cohort_members` (`owner`, `friends`); send the Friends task sheets. | Friends on a September build; cohort rows exist. |
| Thu 25 – Sun 28 | Friends | Rounds happen unassisted; every assisted or support contact goes in `pilot_sessions`. | Scorecard `assistance` reads true. |
| Thu 25 – Sun 28 | Owner | Recruit 3–5 independent groups with `docs/pilot/outreach-drafts.md`; one competition group toward a lock. | Names in the private notes; `independent` cohort rows. |
| Mon 29 | Owner + Claude | Weekly review against `gates-and-stop-conditions.md`: B→C go / no-go. | The review is written. |
| Thu Oct 1 | — | **Staged launch starts.** Stage B in flight, Stage C invitations out, web and database current, Friends on the reviewed build. | The morning of `vision-2026-10-01.md` §1. |

### 4B · Cheap, high-value, before October 1 (Claude unless named; none needs a new mechanic)

1. **The unclaimable link says something** — on the owner's answer to Codex's
   question 3 (default if no answer by Wed 24: stop minting a link for a round
   that was never finished; the signed-out door keeps one sentence for links
   already out). Small; touches an anon surface, so it rides the next push.
2. **The allowance gloss** — one sentence in the wizard info, three words in
   the covenant clause (09-18 decision 3). Copy only.
3. **"Your first counting round"** — `round_epilogue.first_counting`, one
   additive column, both clients (sprint candidate A, item 1). Small.
4. **Founding League flag** — write PIGL's id into `app_flags.pricing.founding.ids`
   (owner, one SQL line) and fix `docs/pilot/organizer-interview.md` q11 and the
   post-round form q5 to D101's bands.
5. **Stale records** — `ACTIVE_WORK.md` (20261024 applied; ownership row for
   `index.html`), the 09-14 release handoff's live SHA, `CLAUDE.md`'s
   monetization paragraph (D183 + D135, not "parked pending focus groups"),
   the review notes' walkthrough league and password placeholder.
6. **CI runs every unit file** — add the other four `*.test.mjs` to
   `.github/workflows/ci.yml`; `homefold` is red on `main` today.
7. **Separate the founder's test starts from real abandonment** in the 28 / 21
   / 7 read before drawing the conclusion §3.3 leans on (a `sandbox` flag or
   the owner cohort exclusion the scorecard already has).
8. **Codex's `20261111` + `courses`** — push the migration first, deploy the
   function second, with the strict-cast coercion in `flattenTees` landed
   before the deploy (review finding 1). Owner's push; Claude's one-line fix.
9. **Enforce the CSP** if the deploy console is clean after the merge — one
   line in `netlify.toml`. If not clean, leave it and file what fired.
10. **Solo minimum roster** — `lock_league` refuses a solo lock under two
    members (D205), one guard in one new migration; skew-safe.
11. **The covenant stops promising verification** — "attested" and "GHIN"
    read as facts in the Standard and Cutthroat presets while nothing enforces
    them; copy only, both clients, until the dial does something.
12. **Gate the snake path** — hide or refuse `draft_type = 'snake'` on the
    phone until the desk can pick, or accept it as phone-only in writing.

### 4C · Decisions the owner owes (each with the default if unanswered)

| # | Decision | Default if silent by Oct 1 |
|---|---|---|
| 1 | Push the two revokes and merge PR #6 after Codex's review. | No default — nothing else in §4A happens without it. |
| 2 | Promote to Friends only after A1–A11 and R1–R7 PASS. | Hold. |
| 3 | The allowance gloss: yes or no. | Yes (copy, reversible). |
| 4 | Unclaimable link: explain signed-out, or stop minting. | Stop minting; one sentence for links already out. |
| 5 | Season two: re-ask consent and money (covenant again, `agreed_at`), or the standing agreement carries and the copy stops claiming an opt-in. | No `run_it_back` push until decided; PIGL's renewal is the forcing date. |
| 6 | The commissioner's adjustment pen: build `adjust_points(season, member, delta, reason)` as a ledgered, board-posted RPC before Stage D, or rule that disputes are settled outside the app and say so in the covenant. | Build it before Stage D; it is §16's missing half. |
| 7 | Email as a channel: a `season-email`-style consumer of `invites`, or drop the table. | Drop the rows from the lock flow; decide the channel in Q1. |
| 8 | Presidents Cup content week (socials plan W10): use it or let it go. | Let it go; the plan is re-keyed to the staged launch. |
| 9 | Age gate and the legal set: a counsel pass before Stage E. | Required before Stage E; not before Stage C. |

### 4D · Explicitly not before October 1

Captains-pick and snake-draft engines (no league has chosen them); spreadsheet
import; a `/pricing` page or any price on any surface (D183); Stripe; a native
Android app; a crash pipeline beyond `client_events`; "Season Wrapped"; the
Record as chapters; the crest object; any new format. Each is in the vision's
year, none is in its launch day.

### 4E · The first thirty days after (Oct 1 – Oct 31)

- Weekly review every Thursday against the gates; the index re-scored in this
  file's table each week.
- Stage C: three to five independent groups; the composer's 1-in-9 investigated
  with `v_post_timings` and one watched session; the timed five-gate QA run on
  the shipped build with three testers.
- Decisions 5, 6 built if ruled: season-two consent before PIGL renews; the
  adjustment pen before any Stage D league locks.
- The paid offer put to five organizers with the corrected guide; answers
  recorded whatever they are (the D→E gate).
- July's M5/M6, `is_league_member` vs `left_at`, the Major tie and pot ledger,
  the stale lock index, the UTC tick (Cup Final opens the evening before in
  Phoenix), the Sunday snapshot cron vs weekday-anchored weeks, the handicap
  ceiling and rise cap — each a small migration, each before Stage D.
- Spec maintenance: amend §3.2, §9, §14.1, §15 to what runs; correct
  `ACTIVE_WORK.md`, the sprint packet and the iOS `RunItBackService` comment
  on `run_it_back` and `20261024`.
- Legal: counsel pass, age line, third parties named, one money posture.
- App Store: refresh the review notes against a live league, then submit for
  the Stage E date, not before.

---

## 5 · Not verified in this pass, and worth a targeted check

Code-audit B3 (board fetches the oldest 120 posts) and B10 (`guest_profile`
lets a stranger post onto a profile — no such function found; may be renamed);
the light theme's `--dim` contrast; whether the 22 ledger-line wordings were
swept beyond the one verbatim occurrence; `content-encoding` on the live
`index.html` (1.80 MB raw, 0.59 MB gzipped locally); the live stamp itself.
