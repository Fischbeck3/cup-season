# October 1 — the execution plan, as of Tuesday 2026-09-22 (revised the same day)

**What this is.** The ruled plan is `spec/launch-readiness-2026-10-01.md` §4A
(the ten days, re-sequenced to D371–D379). This file is the execution view after
this morning's merge: the objective in full, what is verifiably done, what is
owed, by whom, on which day, the launch workstreams with owners and acceptance
criteria, the owner's outreach track kept apart from the engineering, and the
gates between all of it. It does not re-decide anything ruled. The paste-ready
prompt for the Mac session that runs it is the sibling file
`2026-09-22-claude-october-launch-prompt.md`; the previous session wrote that
prompt outside the repository and it went with the sandbox, which is why both
now live here.

**Revised 2026-09-22, same day**, on the owner's instruction: the year-end
objective and the download checkpoints restored, six workstreams added, the
execution protocol corrected (a dedicated branch, no extra "go", the latest
Apple builds read rather than one build number, missing evidence told apart
from confirmed absence, the `20261111` ordering validated, D376's web-only
exception confined to the adjustment tool). The release checklist, the scope
cuts and the two-phone gate are unchanged.

---

## 0 · The objective

**October 1 is the public launch.** Submitted to App Review that morning,
outreach open the same day, a TestFlight public link as the phone door for
strangers until Apple approves (D371; rulings 10 and 14). The store goes live
when Apple says.

**By December 31: 5,000 first-time App Store downloads, supported by
successful real rounds and repeat groups.** The downloads are the number; the
rounds and the repeat groups are what make the number worth anything, and the
stop conditions pause outreach whatever the count reads.

| Checkpoint | Cumulative first-time App Store downloads |
|---|---:|
| 2026-10-31 | 500 |
| 2026-11-30 | 2,000 |
| 2026-12-31 | 5,000 |

**How the number is counted.** First-time downloads as App Store Connect's App
Analytics reports them for the App Store build, read every Tuesday and written
into the weekly report. **TestFlight installs never count. Web sign-ups never
count.** Until Apple approves, the count is zero by definition, so the October
checkpoint depends on the review cycle as much as on the outreach.

**What "supported by" means, measured.** Unassisted completed rounds (every
finish posts every seat; the founder not in the room, per `pilot_sessions`) and
groups that play a second game — the B→C and C→D gates in
`docs/pilot/gates-and-stop-conditions.md`, reported by cohort every week.

**Acquisition assumptions — UNVERIFIED, every one.** The channel is the
shareable artifact — claim links, settlement cards, recaps — foursome by
foursome, with no paid acquisition (canon). An independent group is assumed to
bring four to eight downloads; the public link is assumed to convert to store
installs only after approval; the r/golf founder post is one shot and waits for
the store link. None of this has data behind it: seven share links minted and
one opened, seventy guest seats and one claim, as of the 09-15 read. The first
two weeks of App Analytics set the real rate. The checkpoints steer; they do not
forecast. If October 31 misses 500, the November review decides the channel,
not the target.

---

## 1 · Where things stand — verified 2026-09-22 from a remote sandbox

Three words are kept apart in the last column. **Confirmed**: read from the
system named. **Confirmed absent**: looked for in the tree and not there.
**Missing evidence**: the sandbox could not reach the system; the Mac reads it
first, and until then the state is unknown, never assumed.

| Layer | State | Evidence |
|---|---|---|
| **`main`** | `1e79279` — PR #6 (pilot readiness) and PR #7 (`claude/elegant-curie-x15hps`: the rulings, the four migrations, the web halves, the legal v2) merged 05:55–05:56 Phoenix; PR #5 closed as subsumed. CI runs preflight, every `*.test.mjs` and the real `stamp-version.sh` build. | Confirmed — `git log`, the GitHub API, `.github/workflows/ci.yml` |
| **Tree health** | Preflight PASS, 0 failures, 0 warnings; the five unit files PASS. | Confirmed — run here on `1e79279` |
| **Live web** | Expected `v23 · 1e79279` in `#obCaption`. | **Missing evidence** — proxy 403 from the sandbox; the Mac reads it first |
| **Database** | 252 migrations on disk, latest `20261115090000`. Production recorded the six pushed on 2026-09-22 (`20261109`, `20261110`, `20261112`–`20261115`), read back clean that hour. Codex's `20261111090000_course_cache_atomic` is **not in this tree**; it sorts *before* four migrations that are already applied, so its ordering is a validation item (§2, Tue 22), not a push. | Confirmed for the tree; production state from the rulings packet §5 and the ACTIVE_WORK addendum, both written from the read-back — `deploy-status` itself reads *unknown* here (no CLI) |
| **Edge functions** | Six deployed, none stale as of 09-15; the `courses` redeploy follows `20261111`, with the `flattenTees` coercion. | Missing evidence since 09-15 — the Mac's `deploy-status` |
| **TestFlight** | The **record** names Owner group build 934 from `1aac23a` (pre-merge, uploaded 09-16) and Friends 795 (09-12). Whether any build was uploaded since, and what each group holds today, is **not known from the record** — the Mac reads the latest builds and both groups from App Store Connect before anything is archived. No build from the merged tip can exist yet (the merge is this morning's). The two-phone checklist has never been run on hardware. | Missing evidence for the current groups; confirmed for "no build from `1e79279`" |
| **Web halves of the rulings** | Live with the merge: the allowance gloss (D373), the unfinished-link sentence on both doors (D374), the run-it-back copy and the re-up frame (D375), the Ruling sheet and the receipt's ledger row (D376). | Confirmed — commit `7aa05c8` on `main`; pins in `tests/app-tests.js` |
| **Phone halves of the rulings** | No caller of `Rpc.adjustPoints`; no unfinished-link face beside `.dead`; no `reup` / NOT IN YET / Ask again in `JoinLeague` or `MembersSheet`; the R-M clause absent from `WizardState` / `LeagueSetup` / `JoinLeague` / `LeagueCopy`. `Rpc.swift` is regenerated and carries every new name. The list, file by file: rulings packet §7. | **Confirmed absent** — `grep` over `apps/ios` on `1e79279` |
| **D377** (email fallback removal) | `state.emails` still at five sites in `index.html`; by ruling, after the Friends gate. | Confirmed present — `grep` |
| **Legal** | v2 live with the merge: *Last Updated September 21, 2026*, Fischbeck3 LLC named, 13+, the five vendors, the Apple sentence, in `legal/*.md` and `legal.html`. Counsel not yet engaged. | Confirmed for the files; counsel — owner's word |
| **Store** | 13+ corrected in both store docs. `app-review-notes.md` still points the 5.3.4 paragraph and the walkthrough at Sunset Match (season ended 09-05) and carries the password placeholder (by design — the password lives in App Store Connect only). Support URL undecided (`app-store-listing.md` §5 flag). No screenshots. No installation page: the signed-out door's *Get the app* points at the root. | Confirmed — files read; `index.html:30927` |
| **Universal links** | `.well-known/apple-app-site-association` is in the dist allowlist with its header in `netlify.toml`; a link reopened after install should route into the app. Not proven on a device. | Confirmed for the files; the device — missing evidence |
| **Measurement** | `v_pilot_gates` (D33) times the card and the join passively; post and standings have no passive timer. `v_growth_funnel` has no reader. The scorecard reads cohort, assistance, live games, posting, repeat groups, integrity; nothing reads App Store Connect. | Confirmed — migrations and `tests/pilot/scorecard.sql` |
| **Gates file** | Amended to D371; ratification due at the Tue 29 review. | Confirmed |
| **CSP** | Report-Only since July (`netlify.toml:30`). Flip only on a clean deploy console. | Confirmed |
| **Socials** | Re-keyed (8-B); the handles not yet claimed. | Confirmed for the plan; the handles — owner's word |

---

## 2 · The release checklist — the nine days, engineering and release only

"Owner" is Mac work the owner runs (uploads, groups, submissions, `db push`);
"Claude (Mac)" is the local session the sibling prompt starts, on its own
branch (`claude/october-launch`, §8); "Claude (remote)" is a sandbox session
and can touch only migrations, the web client and documents. Phone halves are
Mac work by rule 6. **The owner's outreach is §4, not here.** The order inside
a day is the order to do it in.

| Day | Who | Item | Done when |
|---|---|---|---|
| **Tue 22** | Claude (Mac) | `git pull` on `main`; a clean `claude/october-launch` branch in its own worktree from the current `main` tip. **The baseline** (§8): `ship.sh --dry-run`, preflight, the live stamp, the latest App Store Connect builds and both groups, the Swift-halves grep. Reported as one table, then the work begins. | Table in the session; the branch exists. |
| Tue 22 | Claude (Mac) + Owner | **`20261111` ordering, validated before it is pushed.** It sorts before four migrations production already carries, so file order and applied order differ. (1) Read its body: if it patches any function that `20261112`–`20261115` also patched in place, it must be rebased on the live text. (2) Because it has run nowhere but a sandbox, **rename it to sort after `20261115`** (`20261116090000_course_cache_atomic.sql`) so the file order equals the applied order — rule 2 forbids editing a migration that has run in production, and this one has not; expect the CLI to refuse or to demand its include-all flag if the old name is kept. (3) Sandbox chain: the 252, then the renamed file, the course-cache probes, an idempotent second run. (4) Owner: `supabase db push` → `supabase functions deploy courses` (with the `flattenTees` coercion in the function first) → `tests/db-checks.sql` 37/37 → `deploy-status` clean. | Production at 253; `courses` redeployed after it; db-checks green. |
| Tue 22 | Owner | `supabase secrets list` shows no `APNS_SANDBOX` (runbook D5). Archive from the tip → `tools/ios-archive.sh --upload` → the Owner group. Install on both phones; **read the build number on each device.** Device proof starts today, on the web halves alone — the second archive carries the Swift halves. | Two phones, one build, the number read on the screen. |
| Tue 22 – Wed 23 | Claude (Mac) | The Swift halves, one commit per ruling, from the rulings packet §7 and its named files and pins: D373 (the R-M clause in `WizardState` / `LeagueSetup` / `JoinLeague` / `LeagueCopy`; pins updated) · D374 (`ClaimDoor.Face` unfinished and not-started; `ClaimFlow.consume` reads `guest_live_state` first; one Kit test) · D375 (`RunItBackResult`, `MyInvite` season/reup, the covenant's season fact and re-up frame, NOT IN YET + Ask again) · D376 (the Ruling row → `Rpc.adjustPoints`; override rows in the receipt) · D378 vii (*since Sunday* → *this week*; verify `SeasonStoryCopy`, do not change it). Every sentence is the twin of a web producer pinned in `tests/app-tests.js`. `node tools/build-db.mjs` reports `Rpc.swift` current; Kit and app suites green; preflight 0. | Suites green; commits on the branch. |
| **Wed 23** | Owner | Second archive, with the Swift halves → the Owner group; both phones updated. | Build number read on both. |
| Wed 23 – Thu 24 | Owner + one friend | `docs/pilot/owner-checks.md`, **every row** (A1–A11, R1–R7, G1–G2), on that build, a real course from the picker. FAIL → Claude fixes → new build → the failed rows re-run. **This is the Friends gate (D372, 2-A) — no known-issues shortcut.** Record PASS / FAIL and the build number per row; no names. | Every row PASS. |
| **Thu 24** | Owner | `python3 tools/asc.py ship <build> "<what to test>"` → Beta App Review → Friends (same version string, `MARKETING_VERSION` 1.0.0; the group add alone is not distribution — the script submits). Name the cohorts `owner` and `friends` in `pilot_cohort_members`. Read D186 and set the OTP rate limit in Supabase Auth. | Friends current; cohorts named. |
| Thu 24 – Fri 25 | Claude (Mac) | After the gate: D377 as one web commit that does nothing else (the `lockBylaws` fallback, the `state.emails` plumbing, both "Invites out" readers); its iOS half staged for the first build **after** the Beta App Review build, never on it. The review notes: re-point the 5.3.4 paragraph and the walkthrough at a seeded league whose season runs past the review window, run `test-seed`, re-read every figure against the seed. **W5 — the installation destination and the support page** (§3): `support.html` and `get.html` written, in the dist allowlist, the Support URL recorded in `app-store-listing.md` §5. **W4 — install-then-reopen** (§3): the sentence on the signed-out door and in every outreach draft. | Committed; the pages load on the preview. |
| **Fri 25 – Sun 27** | Claude (Mac) | **W2 — the one round-sharing action** (§3), web half and phone half, after the owner's ruling on its shape (Thu 24, talk-first). Fixes for anything the checklist or Friends surfaced, narrowly. The CSP header flipped to enforcing ONLY if the Netlify deploy console shows a clean report; otherwise file what fired and leave it. | Committed; suites green. |
| Fri 25 – Sun 27 | Owner | 6.9" screenshots — the kit's eight shots (`appstore-launch-kit.md` §3), from the reviewer sandbox league or a neutralised one, never a real name without that person's yes. PIGL's id into `app_flags.pricing.founding.ids` (one SQL line). **W1 — the timed tests** (§3) with three Friends on the Friends build. **W3 — the recipient journeys** (§3) walked on a physical phone, both links, both clients. | Eight PNGs; the flag set; W1 and W3 results written. |
| **Mon 28** | Owner | Full build from the branch tip → the Owner group; the integrity rows re-run on two phones (A3–A6, A8–A10, R1–R5) — the pen, the copy and the share action changed the app. Then `asc.py ship` so Friends get it once Beta App Review clears. | PASS; Friends on the Monday build. |
| **Tue 29** | Owner + Claude | **W6 — the first weekly report** (§3): `node tools/pilot-scorecard.mjs > docs/pilot/scorecard-2026-09-29.md`, the week's sessions entered before the numbers are read, the integrity section first; the five sections present. Ratify the amended gates (ruling 12). **Go / no-go for the submission, one written line.** Physical iPhone Safari pass of the public web door: the signed-out door, a claim link, an invite link, post a round. | Written. |
| **Wed 30** | Owner | The **TestFlight public link** (App Store Connect → TestFlight → the external group → enable the public link; `asc.py` has no command for it) pasted into `get.html` and the drafts. App Store Connect metadata complete: listing §1–§8; the privacy labels including contacts, byte-aligned with `PrivacyInfo.xcprivacy` (§7); rating 13+ (Contests yes, Gambling no); the review notes pasted with the real password — App Store Connect only, never the repo; screenshots; Support URL `https://cupseason.app/support`; Privacy URL; export compliance. | Link live; every field filled. |
| **Thu Oct 1** | Owner | **Submit to App Review.** The outreach in §4 opens. | Submitted. |
| Thu Oct 1, after | Claude | First thing after submission, as ruled: D197 ruling 3 — the age gate and the terms record (attestation / DOB, `terms_version` / `accepted_at`), one migration, both sign-in doors; the decision-log entry under D197 first. | Validated on the sandbox chain; both doors built; the owner pushes. |
| Approval day | Owner + Claude | `get.html` swaps the TestFlight link for the App Store link; the r/golf post goes out (§4); the download count starts. | The store link on the page. |

**The one native gap allowed to trail the launch build is D376's adjustment
tool.** D376's own tradeoff says so: if its Swift sheet misses the build, the
desk carries the pen and the phone follows in the next build, and the release
record names it. **That exception is not extended.** D373, D374, D375, D378
(vii), D377's iOS half (on the build after the Beta App Review build, by its
ruling) and the phone halves of W2 and W4 ship in the builds named above, or
the build waits. The readiness audit's §4E had placed D375's phone half in the
first post-launch build; under this instruction it is in the launch build, and
if the owner prefers §4E's placement that is a ruling to record, not a slip.

---

## 3 · The launch workstreams — owners and acceptance criteria

Each names its owner (who builds or runs it), what it is, what "done" means,
and by when. None is a new mechanic; W2 is an IA change and gets a
decision-log entry before it is built. The release checklist in §2 carries
each one on its day.

| # | Workstream | Owner | What it is | Acceptance | By when |
|---|---|---|---|---|---|
| **W1** | **Timed comprehension tests** — onboarding, join, post, standings | Owner runs; Claude writes the script and reads the passive view | The four timed gates from `spec/prelaunch-qa-2026-07-13.md`, never run since v23.163 (July): the golfer card in under 2 minutes; a join by link or code in under 30 seconds; a round posted in under 60 seconds; a standings figure explained (where it came from, via its receipt) in under 10 seconds. Run with a stopwatch on the Friends build, three people who have not seen the app, no walkthrough; then again in October with three strangers from the public link. `v_pilot_gates` reads the card and the join passively; post and standings have no passive timer and are timed by hand. | Three runs recorded per gate with the build number; each gate met by two of three, or the miss filed in `spec/inbox.md` naming the screen it stalled on. The passive view read the same week and the two agree within reason. | First run Fri 25 – Sun 27; the stranger run by Oct 17 |
| **W2** | **One coherent round-sharing action**, respecting photo and privacy choices | Claude (web and phone halves); the owner rules on the shape Thu 24 | Today a posted round shares through four doors on the web (`shareRoundCard`, `shareRecapCard`, `shareSettlementCard`, `shareMajorCard`) plus the share link (`share_info`, D57), and the phone has `ShareIntent` / `ShareLinkService`. One **Share** action from a posted round, on both clients, that produces the round card and the share link together; the recap, settlement and major cards stay their own artifacts on their own surfaces. The photo rides the card only when the golfer attached it to that round and says yes on the share sheet; never another golfer's photo; the marker medallion stays (D59). The card never carries a golfer whose findability is *nobody* beyond their own share. Logged through `log_growth_event`. | From a posted round on the web and on the phone, one action, the same artifact and the same sentence (one producer per client, D297); a round without a photo shares the card without one; declining the photo shares the card without it; the share appears in `v_growth_funnel`; pins in `tests/app-tests.js` and the Kit; a decision-log entry (IA level) before the build. | Web half by Fri 27; phone half on the Mon 28 build |
| **W3** | **Guest-claim and season-invitation recipient journeys** | Owner walks; Claude fixes | The two journeys a stranger arrives by, walked end to end as the recipient on a physical phone, signed out: a claim link (`/?claim=`) from a finished round — the door, the sentence for an unfinished round (D374), the account, the claimed card on the record; and a season invitation (`/?join=CODE` and the re-up invitation, D375) — the door, the covenant with the season fact, the seat. Web first (the link opens there), then the app after install. `tests/pilot/claim-walkthrough.py` (24/24 on PR #6) is the server half. | Both journeys complete on both clients with no assisted step; every dead end reads a sentence, never a blank door; `claim-walkthrough.py` green on the tip; the steps visible in `v_growth_funnel`; every stall filed. | Fri 25 – Sun 27, and again on the Mon 28 build |
| **W4** | **Explicit install-then-reopen guidance; no deferred linking promised** | Claude (copy on the door, in `get.html` and in the drafts); owner approves the words | A link opened on a phone without the app lands on the web. Nothing carries the token into an app installed afterwards, and nothing will be built to (deferred deep linking is out of scope). The truth, said once: *Install the app, then open this link again* — the reopened link routes into the app by universal link. | The signed-out door's *Get the app* leads to `get.html`, which says install-then-reopen in one sentence and links back; every outreach draft and the Friends task sheet carry the same sentence; no copy anywhere says the app will remember or restore a link; a universal link reopened after install lands in the app on a device (W3). | Thu 24 – Fri 25 |
| **W5** | **A public installation destination and a useful support page** | Claude builds; owner supplies the links | `get.html`: one page, the TestFlight public link until approval and the App Store link after, the web app as the other door, the install-then-reopen sentence. `support.html`: how to get help (the support address), the install guidance, what to do when a link does not open, account deletion in one sentence, the legal links. Both static, in the dist allowlist in `stamp-version.sh` (or they 404), a `/get` and `/support` redirect each in `netlify.toml`. | `https://cupseason.app/support` and `/get` load on the Netlify preview and, after the merge, live; App Store Connect's Support URL field carries `/support`; the pages pass preflight's allowlist check; the door's footer points at `/get`. | Thu 24 – Fri 25; the App Store link swapped in on approval day |
| **W6** | **Cohort, assistance, activation, sharing and acquisition reporting** | Claude extends the scorecard; owner runs it every Tuesday and reads App Store Connect | One weekly report, `tools/pilot-scorecard.mjs`, with five sections and a denominator on every number: **cohort** (owner · friends · independent · competition · founding, from `pilot_cohort_members`); **assistance** (assisted vs unassisted completions, from `pilot_sessions`); **activation** (account → first posted round → second round; groups with a second game); **sharing** (share links minted and opened, claims, invitations accepted — `v_growth_funnel` gets its first reader); **acquisition** (cumulative first-time App Store downloads from App Analytics against the checkpoints in §0; TestFlight installs and web sign-ups shown separately and never summed in). The App Store number is read by hand from App Store Connect until an `asc.py` command reads it. | The Tue 29 report has all five sections; each later Tuesday's report is written before the review; the acquisition line reads zero until approval and says so; no report sums TestFlight or web into the store count. | First report Tue 29; the acquisition section live on approval day |

---

## 4 · The owner's outreach — kept apart from the engineering

Nothing here is engineering, and nothing in §2 or §3 depends on it. Drafts stay
drafts in `docs/pilot/outreach-drafts.md`; nothing is sent from the repository;
no name enters it. The stop conditions pause this track, whatever the count.

| When | What | Assumption it rests on (unverified) |
|---|---|---|
| Thu 24 | The Friends message (draft B) and the task sheet, once the gate is passed. Counsel emailed the D379 packet (D39, D183, D184, D192, D201, the v2, the LLC question) with a fixed-fee scope. The @cupseason handles claimed — claiming, not posting. | Friends complete two rounds each, the second unassisted (B→C). |
| Oct 1 | The independent groups by hand (draft C): three to five Phoenix-area groups; the TestFlight public link to whoever the outreach reaches (D371, ruling 10). PIGL's own moments in the founder's own voice, on his own accounts. | A group brings four to eight downloads once the store link exists; the public link installs are TestFlight and do not count. |
| Approval day | The r/golf founder post, with the store link as its CTA — one shot, held until then. The brand's first post, keyed to the link (socials plan, re-keyed). | The post is the one reach at a cold audience; its rate is unknown. |
| October | Competition groups (draft D) as the Stage C groups finish a second round. The paid offer put to five organizers with the corrected interview guide — the gate for the paid stage, not for launch (ruling 11). | — |
| Every Tuesday | The download count read from App Analytics into the W6 report; the checkpoint in §0 compared; the week's line — hold · widen · stop. | The checkpoints steer; if Oct 31 misses 500 the review decides the channel, not the target. |

---

## 5 · The gates, restated — and the approvals that do not move

- **Friends** receive a build only when every row of `owner-checks.md` is PASS
  on that build (D372). A FAIL is fixed and the failed rows re-run. **The
  two-phone gate stands** for every build that reaches a stranger.
- **Submission** needs: the legal v2 live (done), the review notes true against
  the seeded reviewer account with a running season, the rating 13+, the
  privacy labels, eight screenshots, `/support` loading, no `APNS_SANDBOX`
  secret, `deploy-status` clean on all three layers.
- **Production and Apple approvals are the owner's, every time.** `supabase db
  push`, `supabase functions deploy`, `supabase secrets`, the TestFlight upload,
  adding a build to a group, Beta App Review, the public link, the App Review
  submission. Claude sequences, states the exact command and reads the result
  back; the owner runs it. Nothing in this plan changes that.
- **Stop conditions** (`docs/pilot/gates-and-stop-conditions.md`) are the only
  thing that pauses outreach: a duplicate live round for one booking, a
  double-posted card, an acknowledged score that did not land, any golfer seeing
  another's data, a trap screen reported by two testers, a week where assisted
  sessions exceed unassisted completions in an unassisted cohort, a claim card
  exposing more than name, gross, course and date.
- **Assume one Apple rejection cycle** (5.3.4 on the pot, 2.1 on an empty
  reviewer state) and answer from the playbook in `app-review-notes.md`.

---

## 6 · Risks, named

- **Device proof.** Nothing on a physical phone has ever been checked.
  Everything after Wednesday depends on it, which is why the first Owner build
  goes up today from the web halves alone. The server side is already proven
  (72 restricted-role probes, row security on).
- **Apple state is a record, not a reading.** 934 is what the record names as
  of 09-16; the groups may hold something newer. Read the latest builds and both
  groups from App Store Connect before archiving, and never treat a group add as
  distribution. The signing certificate runs to 2027-09-14; `tools/ios-signing.sh`
  is the recovery if the first upload of the merged tip shows drift.
- **`20261111` is out of order** with four applied migrations. Rename before
  the push, validate on the chain in the applied order, and never push it under
  a name that sorts before what production already has.
- **The October checkpoint is hostage to the review cycle.** The count is zero
  until approval; a rejection on the 2nd and an approval on the 9th leaves three
  weeks for 500. Say so in the Oct 31 review rather than move the target.
- **Capacity.** One person is builder, ops, support and publisher, and the Swift
  halves, the checklist, the screenshots, the share action, the pages and the
  metadata all land on one Mac in one week. The order in §2 puts the checklist
  ahead of everything cosmetic; W1 and W3 ride Friends' weekend.
- **Acquisition is assumed, not known** (§0). The stop conditions decide
  weekly, on the scorecard, not the download count.

---

## 7 · Explicitly not before October 1 — the scope cuts stand

The bylaws re-open at the re-up (D375 is built; the terms carry locked, named
in its as-built note); captains-pick and live drafts (snake is refused at
lock); spreadsheet import; a price on any surface or a `/pricing` page (D183);
Stripe; Android native; a crash pipeline beyond `client_events`; Season
Wrapped; the Record as chapters; the crest; any change to §2.2's bands (D378
i); **deferred deep linking** (W4 says the true thing instead). Each is in the
vision's year, none in its launch day.

---

## 8 · The execution protocol

1. **A dedicated branch.** The Mac session works on a clean
   `claude/october-launch` branch in its own worktree, cut from the current
   `main` tip at the start of the first session. Never on `main` directly;
   never a remote session on the same branch at the same time (rule 6). A
   remote session that takes a migration or a document item works on its own
   branch and says so in its handoff.
2. **Baseline first, then the work — no extra "go".** The session establishes
   the state as one table (layer · state · confirmed / confirmed absent /
   missing evidence · how), reports it, and begins the authorized work in §2's
   order in the same session. Only a stop condition, a FAIL on the checklist,
   or an item outside this plan waits for the owner.
3. **The approvals in §5 do not move.** The owner runs every production and
   Apple mutation; Claude hands over the exact command and reads the result back.
4. **D376's web-only exception is D376's alone.** No other native half trails
   the build it is named on.
5. **Read Apple, do not remember it.** The latest builds and both groups from
   App Store Connect at the start of every session that touches a build.
6. **Missing evidence is not absence.** A thing the session could not read is
   "unknown"; a thing it looked for in the tree and did not find is "absent".
   Never the one word for the other.
7. **`20261111` is validated in the applied order** before it is pushed (§2,
   Tue 22).
8. **Every session ends** with the handoff block the prompt specifies, the
   release record in `ACTIVE_WORK.md` corrected the same day anything ships, and
   anything found and not built in `spec/inbox.md`.

Paste `2026-09-22-claude-october-launch-prompt.md` into a fresh local Claude
session on the Mac, from the repo root, after `git pull`.
