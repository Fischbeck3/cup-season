# Cup Season — Launch readiness for 1 October 2026

**Date:** 2026-09-20 (Sunday; launch day is Thursday 2026-10-01, eleven days
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

**Ruling, 2026-09-21.** The owner chose the public launch: **App Store
submission on October 1**, open outreach the same day, a TestFlight public link
as the phone door for strangers until Apple approves. That collides with the
proposed D→E gate and with the verdict above; the collision is named in D371
(`docs/planning/2026-09-21-launch-rulings.md`) and resolved at the vision level.
The stop conditions stay in force. The index and the findings stand as measured;
§4 below is re-sequenced to the ruling, and every decision point in §4C now
carries its ruling instead of a default.

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
| 8 | Platform & store | 5 | App Store 3 | B | **6.5** | Account deletion on both clients (`delete_account`, tombstone); legal page live; signing recovered (cert to 2027-09-14); 934 VALID in the Owner group. Held down by: App Review never submitted; review notes point at a season that ended 09-05; no `/support` URL; the operator (Fischbeck3 LLC, already Apple's signer) is named nowhere a user reads; two store docs still carry the retired 4+ age answer. |
| 9 | Ops, observability & measurement | 5 | — | B+ | **7** | `deploy-status`, `ship.sh`, preflight (69 checks, check 50 new), db-checks (34), the read-only scorecard, attempt-keyed telemetry, founder desk. Held down by: cohort table empty (assisted vs unassisted indistinguishable), `v_growth_funnel` has no reader, no crash pipeline beyond `client_events`, the three webhooks live only in the dashboard, CI runs two of five unit files. |
| 10 | Legal & compliance | 5 | (in App Store 3) | — | **4** | Three documents, 64 lines total, dated July 18, no counsel: no minimum age or age gate (D192 leaves it open), no governing law, liability or dispute terms, contacts hashing (D251) undisclosed, third parties unnamed. Two money postures at once: the disclaimer's "never holds, takes no cut" and the product's D39 ledger line. |
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
  real blocker for the competition pilot (Stage D). Priced honestly it is
  more than one RPC: `v_individual_standings` reads no adjustments at all, so
  a ruling in a solo league (the only structure real leagues use, D205) would
  post to the board and move nothing; and `cup_final_race` scores the window
  fresh and reads no ledger row, so the Final needs an explicit rule (refuse
  and say so, or read the override). One migration, three parts.
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
- Missing for a public door: minimum age / age gate (D197 ruling 3 builds it
  together with the terms record, deliberately after the store submission);
  governing law, liability and dispute terms; the named third parties
  (Supabase, Brevo, Netlify, GolfCourseAPI, Anthropic); contacts hashing
  disclosure (D251); the operator's name (Fischbeck3 LLC exists and signs the
  app; no user-facing page says so); counsel review. Two money postures in one
  product (disclaimer vs D39 ledger line). Two store documents still answer
  the age rating 4+ (`spec/appstore-runbook.md:131`,
  `spec/appstore-launch-kit.md:40-41`) against D192's 13+.

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

### 4A · The ten days, re-sequenced to the rulings (public launch, submission Oct 1)

Rulings 0-B, 1-B, 2-A, 6-A-before-Oct-1, 10-A, 14 applied. "Owner" is Mac
work; "Claude" is remote work (migrations, web client, docs, drafts). Phone
halves are Mac work by rule 6.

| Day | Who | Item | Done when |
|---|---|---|---|
| **Mon 21 (today)** | Owner | From the **PR #6 checkout**: `supabase db push --linked` → `20261109090000`, `20261110090000`. Read back db-checks 34/34, `pilot-record.py` 13 PASS. | `deploy-status` clean. |
| Mon 21, by 17:00 Phoenix | Owner | iPhone Safari walk of the PR #6 preview: sign in · Play-with · course search with the keyboard up · post a round and read the recap. Then merge PR #6 (with or without Codex — D372), close PR #5, confirm `#obCaption` = merge SHA. | Live web = branch tip. |
| Mon 21 night | Owner | `tools/ios-archive.sh --upload` from the merged tip → Owner group; `MARKETING_VERSION` stays 1.0.0; install on both phones and read the build number on each. | Two phones, one build. |
| Mon 21 | Claude | **Done:** rulings packet and this re-plan; `20261112090000` (D378 bundle), `20261113090000` (D376 pen), `20261114090000` (D371 door counter) — each patches the live function text in place from `pg_get_functiondef` with asserted anchors and a self-check, and each is idempotent. **Validated here** on a Postgres 16 sandbox running the full 251-file chain (PR #6's harness, `MAINTAIN` filtered — production is 17): 18 functional probes pass (a ruling moves a solo total and posts; a non-Pro and the Final are refused; snake refused at lock; the tick cuts week 2 once and opens the Final on the league's day; a leaver keeps read and loses the Ryder door; the 61st lookup from one address is refused). `tests/db-checks.sql` 35/36 added, check 1 amended to three jobs. Contract rows added; `rpc.ts` and `Rpc.swift` regenerated; preflight 0. | Codex review; owner's `db push` from a checkout carrying every file. |
| Tue 22 – Wed 23 | Owner + one friend | `docs/pilot/owner-checks.md`, **every row** (A1–A11, R1–R7, G1–G2), on the Owner build. FAIL → Claude fixes → new build → re-run the failed rows. **This is the Friends gate (2-A).** | Every row PASS. |
| Tue 22 (done) | Claude | **D375 built**, on the owner's order: `20261115090000_season_two_is_a_re_up.sql` (the ask, the recorded yes, the agreed predicate in the lens/table/hat/start/pot/pulse/record, the covenant and `my_invites` saying the season, the Pro's ask-again) and its desk half (run-it-back copy, the season fact and the re-up frame on the covenant, the invitation title, the re-up toast, NOT IN YET + Ask again on the roster). 32 sandbox probes, idempotent re-run, db-check 37, preflight 0. Phone half in the packet §7. **Database pushed by the owner the same day** (six migrations: PR #6's two and the four ruled this week), verified read-only against production. | Codex review; PR #6 and this branch merged (the client is not live until then); the Mac runs the Swift half. |
| Mon 21 (done) | Claude | **Web halves built** on PR #6's tree: the allowance gloss (D373), the unfinished-link sentence on both doors (D374), the run-it-back copy (D375-now), the Pro's Ruling sheet and the receipt's ledger row (D376). The season-story line needs no change (it reads the snapshot's weekday). Pins in `tests/app-tests.js`; preflight 0. The phone halves are listed in the rulings packet §7 for the Mac. | Codex review of the branch; the Mac runs the full web suite and the Swift halves. |
| Thu 24 | Owner | Beta App Review on the passing build (same version string; budget one day) → **Friends**. Name cohorts (`owner`, `friends`) in `pilot_cohort_members`; send the task sheets. Read `rate_limit_otp` and set it (D186). | Friends current; cohorts named. |
| Thu 24 – Fri 25 | Codex · Owner | Codex reviews `20261112`–`20261114` and the web halves. Owner: `supabase db push` from a checkout carrying every file (after Codex's `20261111` is placed, in that order: migration first, `courses` redeploy after, with the `flattenTees` coercion). | Production at 251+; db-checks green. |
| Fri 25 – Sun 27 | Owner (Mac) | Phone halves in Swift: the gloss, the unfinished-link face, the run-it-back copy, the Pro's ruling sheet; `tools/build-db.mjs` regenerates `Rpc.swift`; Kit and app suites green. | Kit/app green locally. |
| Fri 25 – Sun 27 | Friends | Rounds unassisted; every assisted or support contact in `pilot_sessions`. | Scorecard `assistance` reads true. |
| Fri 25 – Sun 27 | Owner + Claude | **D379:** Claude drafts the legal v2 (13+, vendors, contacts, deletion in-app, Fischbeck3 LLC, one money posture), the Contacts-label reconciliation, the review-notes refresh and the two 4+ → 13+ fixes; owner approves (the entity, Fischbeck3 LLC, confirmed Sep 22), emails counsel the packet. Owner: 6.9" screenshots; claim the @cupseason handles. | One legal commit; counsel engaged; ASC metadata ready. |
| Mon 21 (done early) | Claude | Socials plan re-keyed (8-B); gates file amended to D371 for Tue 29's ratification; D371–D379 appended to the decision log (the branch is based on PR #6's tip); `ACTIVE_WORK.md`, the store docs' age rating, the interview guide's numbers and the review notes' pricing sentence corrected; the legal v2 drafted (D379) for the owner's confirmation and counsel. Still after the gate by ruling: the email-fallback removal (D377). | Committed. |
| Mon 28 | Owner | Full build from the tip → Owner group; **integrity rows re-run** on two phones (A3–A6, A8–A10, R1–R5) since the pen and the copy changed the app. | PASS. |
| Tue 29 | Owner + Claude | Weekly review; ratify the amended gates (12); go/no-go for the submission. **Physical iPhone Safari pass of the public web door**: signed-out door, a claim link, an invite link, post a round. | Written. |
| Wed 30 | Owner | Create the **TestFlight public link** for Stage C (10-A); finalize the outreach drafts with it; final App Store Connect metadata (privacy labels incl. contacts, 13+ rating, review notes). Friends get the Mon 28 build once Beta App Review clears it. | Link live; metadata complete. |
| **Thu Oct 1** | Owner | **Submit to App Review (14).** Outreach opens: the independent groups by hand and the public link. The r/golf founder post is held until Apple approves — the store link is its CTA. First thing after submission: D197 ruling 3's age gate and terms record (one migration, both doors). | Submitted; the season starts. |

**Capacity, said plainly.** The pen (D376) is three to four working days and its
phone half is Mac time on the same weekend as the screenshots, the legal review
and the Swift copy halves. If the phone half slips, the desk carries the pen on
Oct 1 and the phone follows in the next build — the release record says so, and
D234's "done" waits for it. The season-two re-ask (D375) was pulled forward by
the owner on Sep 22 ("build the season two re-ask now") and its database and
desk halves are **built** (`20261115090000`); the phone half joins the Mac
list. Its forcing date was the first staked run-back (Fellas, 2027-01-18). The anon rate-limit migration is the cost
D371 carried in its option text; it is in the list because the door is public.

### 4B · Cheap, high-value, before October 1 (Claude unless named; none needs a new mechanic)

1. **The unclaimable link says the true thing, on both surfaces, client-only.**
   `guest_live_state` already returns the round's status, so the signed-out
   door prints "this round was never finished — ask whoever ran it" and drops
   the token when the status is `abandoned`; the signed-in claim path calls the
   same read before `claim_round` instead of matching the "still live" raise.
   No migration, no anon-grant change; half a day; rides the merge and the
   Monday build. "Stop minting" is NOT the answer — the link is minted at seat
   time because it is the guest's pencil (D85/D87/D107).
2. **The allowance gloss** — one sentence in the wizard info, a few words in
   the covenant clause, in R-M's sanctioned shape ("scored against your playing
   HCP — your index at ninety-five percent"). Copy only, both clients; its own
   small commit on `main` after the merge, never folded into PR #6 while Codex
   reviews it. Fix the phone's "of your handicap" to "of your index" while
   there.
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
10. ~~Solo minimum roster~~ — **struck.** D205 rules it: a solo league of one
    is "a season waiting for its second"; the Pro may lock alone (D180). Not a
    defect.
11. ~~The covenant stops promising verification~~ — **already so.** M-15 is
    built verbatim on both clients ("Verification is a norm the league holds,
    not a filter Cup Season applies") and the server covenant carries no
    attested/GHIN text. Close it in the decision log as a stated norm; nothing
    to build.
12. **Gate the snake path** — `lock_league` refuses `draft_type in
    ('snake','live')` until the desk can pick; in the D378 bundle
    (`20261112090000`), before Oct 1 by ruling.

### 4C · The decision points, ruled 2026-09-21

Options and analysis: the 2026-09-21 briefing; the entries: `docs/planning/2026-09-21-launch-rulings.md` (D371–D379, reserved until PR #6 merges).

| # | Decision | Ruling | What it changes |
|---|---|---|---|
| 0 | Launch shape | **B — public.** App Store submission Oct 1; outreach opens the same day; TestFlight public link for strangers until approval | D371. Collides with the proposed D→E gate — named, resolved at the vision level; stop conditions stay in force. Pulls forward the legal v2, the anon rate limits, `rate_limit_otp`, the review-notes refresh. |
| 1 | Push and merge | **B** — revokes today from the PR #6 checkout; merge by Mon 21 17:00 Phoenix with or without Codex, after the iPhone Safari walk | D372. Overrides the 09-13 "Codex integrates" row for this merge. |
| 2 | Friends gate | **A** — every row PASS, no known-issues shortcut | D372. Friends on Thu 24 if Tue–Wed passes clean. |
| 3 | Allowance gloss | **A** — yes | D373. Own commit after the merge; phone half before the next archive. |
| 4 | Unclaimable link | **A** — say the true thing on both doors, client-only | D374. No migration; the pencil stays (D85/D87). |
| 5 | Season two | **A** — the covenant again, a recorded yes | D375. Amends D243, restores §14.5. Copy correction now; the build in October before Fellas wraps. |
| 6 | Adjustment pen | **A, before Oct 1** | D376. One migration, three parts; desk sheet + phone sheet; §9 amended. |
| 7 | Email invitations | **B** — link and code only | D377. Built after the Friends gate; table dropped in Q1. |
| 8 | Presidents Cup week | **B** — let it go | Socials plan re-keyed; handles claimed; PIGL moments in the founder's own voice. |
| 9 | Legal set | founder v2 before submission; counsel engaged now | D379. D197 ruling 3's age gate first thing after submission. |
| 10 | Stage C install path | **A** — TestFlight public link | Created Wed 30; in the outreach drafts. |
| 11 | Competition lifecycle at D→E | **A** — a Ryder or Major counts | Moot for launch while free (D183); stands as the paid-stage gate. |
| 12 | Gates file | ratify, amended to D371 | Tue 29 review: E opened by ruling; stale A→B line corrected. |
| 14 | Store date | **Oct 1 is the submission date** | Logged in D371 so it cannot slip a third time. |
| D | Stage D mechanics | **address every item** | D378: (i) bands stay, recorded; (ii) closed as a norm; (iii) `is_active_member` on write paths; (iv) struck; (v) snake/live refused at lock; (vi) league-local dates; (vii) snapshot on the tick. One bundle, `20261112090000`, before Oct 1. |

### 4D · Explicitly not before October 1

The re-open of the bylaws at the re-up (D375 is built; the terms still carry
locked, named in its as-built note); captains-pick and live-draft engines (no league has chosen them; snake is now
refused at lock); spreadsheet import; a `/pricing` page or any price on any
surface (D183); Stripe; a native Android app; a crash pipeline beyond
`client_events`; "Season Wrapped"; the Record as chapters; the crest object; any
change to §2.2's bands (D378 (i)). Each is in the vision's year, none is in its
launch day.

### 4E · The first thirty days after (Oct 1 – Oct 31)

- **The Apple cycle.** Assume one rejection (5.3.4 on the pot, 2.1 on an empty
  reviewer state); answer from D39's ledger language and a running walkthrough
  league; the store goes live when Apple says. The r/golf post goes out that
  day, not before.
- **D197 ruling 3** first: the age gate and the terms record, one migration,
  both sign-in doors.
- **D375's phone half** in the first post-launch build (the database and desk
  halves shipped Sep 22); the bylaws re-open at the re-up when a Pro asks.
- **D377's commit**: the dead email fallback and both "Invites out" readers
  removed; `drop table invites` queued for Q1.
- **The phone halves that missed the Oct 1 build**, if any, in the first
  post-launch build; the release record names which.
- Weekly review every Tuesday against the amended gates; the index re-scored in
  §1 each week; the stop conditions are the only thing that pauses outreach.
- Stage C measured: three to five independent groups plus whoever the public
  link brings; the composer's 1-in-9 investigated with `v_post_timings` and one
  watched session; the timed five-gate QA run on the shipped build with three
  strangers.
- Still owed from the audit, now with a public door: July's M5/M6; the Major
  tie and pot ledger; the stale lock index; the handicap ceiling and rise cap;
  `homefold` and the other unit files into CI; the CSP enforced once the
  console is clean.
- The paid offer put to five organizers with the corrected interview guide —
  the gate for the paid stage, not for launch (ruling 11).
- Spec maintenance: §9, §14.5's citation, §3.2, §14.1 amended to what runs;
  `ACTIVE_WORK.md`, the sprint packet and the iOS `RunItBackService` comment
  corrected on `run_it_back` and `20261024`.

---

## 5 · Not verified in this pass, and worth a targeted check

Code-audit B3 (board fetches the oldest 120 posts) and B10 (`guest_profile`
lets a stranger post onto a profile — no such function found; may be renamed);
the light theme's `--dim` contrast; whether the 22 ledger-line wordings were
swept beyond the one verbatim occurrence; `content-encoding` on the live
`index.html` (1.80 MB raw, 0.59 MB gzipped locally); the live stamp itself.
