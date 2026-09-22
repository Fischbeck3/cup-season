# October 1 — the execution plan, as of Tuesday 2026-09-22

**What this is.** The ruled plan is `spec/launch-readiness-2026-10-01.md` §4A
(the ten days, re-sequenced to D371–D379). This file is the execution view after
this morning's merge: what is verifiably done, what is owed, by whom, on which
day, and the gates between them. It does not re-decide anything. The paste-ready
prompt for the Mac session that runs it is the sibling file
`2026-09-22-claude-october-launch-prompt.md`; the previous session wrote that
prompt outside the repository and it went with the sandbox, which is why both
now live here.

**Nine days.** Launch day is Thursday 2026-10-01: submission to App Review that
morning, outreach open the same day, a TestFlight public link for strangers
until Apple approves (D371, rulings 10 and 14).

---

## 1 · Where things stand — verified 2026-09-22 from a remote sandbox

"Verified" means read from the system named in the last column. What the
sandbox cannot reach is marked and left for the Mac.

| Layer | State | How it was verified |
|---|---|---|
| **`main`** | `1e79279` — PR #6 (pilot readiness) and PR #7 (`claude/elegant-curie-x15hps`: the rulings, the four migrations, the web halves, the legal v2) merged 05:55–05:56 Phoenix; PR #5 closed as subsumed. CI now runs preflight, every `*.test.mjs` and the real `stamp-version.sh` build. | `git log`, the GitHub API; `.github/workflows/ci.yml` read |
| **Tree health** | Preflight PASS, 0 failures, 0 warnings; the five unit files PASS. | Run here on `1e79279` |
| **Live web** | Should read `v23 · 1e79279` in `#obCaption`. **Not reachable from the sandbox** (proxy 403). | Confirm on the Mac before anything else |
| **Database** | 252 migrations on disk, latest `20261115090000`. Production recorded the six pushed on 2026-09-22 (`20261109`, `20261110`, `20261112`–`20261115`) and read back clean. **Codex's `20261111090000_course_cache_atomic` is on the Mac only** and not in this tree; with the `courses` function change it is the one owed database/edge item, migration first. | Rulings packet §5, ACTIVE_WORK addendum; `ls supabase/migrations`; `deploy-status` reads *unknown* here (no CLI) |
| **Edge functions** | Six deployed, none stale as of 09-15. `courses` redeploy owed after `20261111`, with the `flattenTees` coercion. | ACTIVE_WORK release record |
| **TestFlight** | Owner group: build **934** from `1aac23a` — **pre-merge**, 2026-09-16. Friends: **795** (09-12). No build from the merged tip exists. The two-phone checklist (`docs/pilot/owner-checks.md`) has never been run on hardware. | ACTIVE_WORK release record, read from App Store Connect 09-16 |
| **Web halves of the rulings** | Live with the merge: the allowance gloss (D373), the unfinished-link sentence on both doors (D374), the run-it-back copy and the re-up frame (D375), the Ruling sheet and the receipt's ledger row (D376). | Commit `7aa05c8` on `main`; pins in `tests/app-tests.js` |
| **Phone halves of the rulings** | **Not built.** No caller of `Rpc.adjustPoints`; no unfinished-link face beside `.dead`; no `reup` / NOT IN YET / Ask again in `JoinLeague` or `MembersSheet`; the R-M clause absent from `WizardState` / `LeagueSetup` / `JoinLeague` / `LeagueCopy`. `Rpc.swift` is regenerated and carries every new name. The list, verbatim: rulings packet §7. | `grep` over `apps/ios` on `1e79279` |
| **D377** (email fallback removal) | Not built, by ruling after the Friends gate; `state.emails` still at five sites in `index.html`. | `grep` |
| **Legal** | v2 live with the merge: *Last Updated September 21, 2026*, Fischbeck3 LLC named, 13+, the five vendors, the Apple sentence, in `legal/*.md` and `legal.html`. **Counsel not yet engaged** (owner). | Files read |
| **Store** | 13+ corrected in both store docs. `app-review-notes.md` still points the 5.3.4 paragraph and the walkthrough at Sunset Match (season ended 09-05) and carries the password placeholder (by design — the password lives in App Store Connect only). Support URL undecided (`app-store-listing.md` §5 flag: `/support` redirect, or the root). No screenshots. | Files read |
| **Gates file** | Amended to D371; ratification due at the Tue 29 review. | File read |
| **CSP** | Report-Only since July (`netlify.toml:30`). Flip only on a clean deploy console. | File read |
| **Socials** | Re-keyed (8-B); the handles not yet claimed. | File read |

## 2 · The nine days

"Owner" is Mac work; "Claude (Mac)" is the local session the sibling prompt
starts; "Claude (remote)" is a sandbox session and can touch only migrations,
the web client and documents. Phone halves are Mac work by rule 6. The order
inside a day is the order to do it in.

| Day | Who | Item | Done when |
|---|---|---|---|
| **Tue 22** | Owner | `git pull` on `main`. `./tools/ship.sh --dry-run`: every layer clean except Codex's `20261111` once it is placed in the tree. Confirm `#obCaption` on cupseason.app reads `v23 · 1e79279`. Place `20261111` → `supabase db push` → `supabase functions deploy courses` (migration first, function second; the `flattenTees` coercion in the function before the deploy). `tests/db-checks.sql` 37/37. | `deploy-status` clean on all three layers. |
| Tue 22 | Owner | `supabase secrets list` shows no `APNS_SANDBOX` (runbook D5). `tools/ios-archive.sh --upload` from the tip → Owner group. Install on both phones; **read the build number on each device.** Device proof starts today, on the web halves alone. | Two phones, one build, the number read on the screen. |
| Tue 22 | Claude (Mac) | The Swift halves, one commit each, in the packet's order: D373 (the R-M clause in `WizardState` / `LeagueSetup` / `JoinLeague` / `LeagueCopy`, pins updated) · D374 (`ClaimDoor.Face` unfinished and not-started; `ClaimFlow.consume` reads `guest_live_state` first; one Kit test) · D375 (`RunItBackResult`, `MyInvite` season/reup, the covenant's season fact and re-up frame, NOT IN YET + Ask again) · D376 (Ruling row → `Rpc.adjustPoints`; override rows in the receipt) · D378 vii (*since Sunday* → *this week*; verify `SeasonStoryCopy`, do not change). `node tools/build-db.mjs` reports `Rpc.swift` current; Kit and app suites green; preflight 0. | Suites green locally; commits on `main`. |
| **Wed 23** | Owner | Second archive, with the Swift halves → Owner group; both phones updated. | Build number read on both. |
| Wed 23 – Thu 24 | Owner + one friend | `docs/pilot/owner-checks.md`, **every row** (A1–A11, R1–R7, G1–G2), on that build, a real course from the picker. FAIL → Claude fixes → new build → the failed rows re-run. **This is the Friends gate (D372, 2-A) — no known-issues shortcut.** Record PASS/FAIL and the build number per row; no names. | Every row PASS. |
| **Thu 24** | Owner | `python3 tools/asc.py ship <build> "<what to test>"` → Beta App Review → Friends (same version string, `MARKETING_VERSION` 1.0.0; the group add alone is not distribution — the script submits). Name cohorts `owner` and `friends` in `pilot_cohort_members`; send the Friends message (`outreach-drafts.md` B) and the task sheet. Read D186 and set the OTP rate limit in Supabase Auth. Email counsel the D379 packet (D39, D183, D184, D192, D201, the v2, the LLC question) with a fixed-fee scope. Claim the @cupseason handles — claiming, not posting. | Friends current; cohorts named; counsel's inbox has the packet. |
| Thu 24 | Claude (Mac), after the gate passes | D377, one commit on the web that does nothing else: the `lockBylaws` fallback, the `state.emails` plumbing, both "Invites out" readers. The iOS half waits for the first build **after** the Beta App Review build. The review notes: re-point the 5.3.4 paragraph and the walkthrough at a seeded league whose season runs past the review window, run `test-seed`, re-read every figure. The Support URL: either the one-line `/support → /legal.html` redirect in `netlify.toml` (then `https://cupseason.app/support`) or the root — decide, and record it in `app-store-listing.md` §5. | Committed; the notes read true against the seed. |
| **Fri 25 – Sun 27** | Friends | Rounds unassisted. Every assisted or support contact into `pilot_sessions` (`session-log.md`). | Scorecard `assistance` reads true. |
| Fri 25 – Sun 27 | Owner | 6.9" screenshots — the kit's eight shots (`appstore-launch-kit.md` §3), from the reviewer sandbox league or a neutralised one, never a real name without that person's yes. The founding flag: PIGL's id into `app_flags.pricing.founding.ids` (one SQL line). | Eight PNGs; the flag set. |
| Fri 25 – Sun 27 | Claude (Mac) | D377's iOS half, staged for Monday's build. Read the Netlify deploy console: if the CSP report is clean, rename the header to enforcing in `netlify.toml`; if not, file what fired in the inbox and leave it. Fix anything the checklist or Friends surfaced. Only if all of that is done: §4B item 3 (*your first counting round*) — it is a migration plus both clients and can wait. | Committed; the console read is recorded. |
| **Mon 28** | Owner | Full build from the tip → Owner group; the integrity rows re-run on two phones (A3–A6, A8–A10, R1–R5) — the pen and the copy changed the app. Then `asc.py ship` so Friends get it once Beta App Review clears. | PASS; Friends on the Monday build. |
| **Tue 29** | Owner + Claude | Weekly review: `node tools/pilot-scorecard.mjs > docs/pilot/scorecard-2026-09-29.md`, integrity section first, the week's sessions entered before the numbers are read. Ratify the amended gates (ruling 12). **Go / no-go for the submission, one written line.** Physical iPhone Safari pass of the public web door: the signed-out door, a claim link, an invite link, post a round. | Written. |
| **Wed 30** | Owner | The **TestFlight public link** (App Store Connect → TestFlight → the external group → enable the public link; `asc.py` has no command for it). Outreach drafts C and D finalised with the link. App Store Connect metadata complete: listing §1–§8; the privacy labels including contacts, byte-aligned with `PrivacyInfo.xcprivacy` (§7); rating 13+ (Contests yes, Gambling no); the review notes pasted with the real password — App Store Connect only, never the repo; screenshots; Support and Privacy URLs; export compliance. | Link live; every metadata field filled. |
| **Thu Oct 1** | Owner | **Submit to App Review.** Outreach opens: the independent groups by hand and the public link. The r/golf founder post waits for the store link. | Submitted; the season starts. |
| Thu Oct 1, after | Claude | First thing after submission, as ruled: D197 ruling 3 — the age gate and the terms record (attestation / DOB, `terms_version` / `accepted_at`), one migration, both sign-in doors. | Migration validated on the sandbox chain; both doors built; the owner pushes. |

**If the Swift halves slip.** The desk carries the pen and the true sentence on
Oct 1 and the phone follows in the next build; the release record names which
halves missed (D376's tradeoff, D234's "done" waits for them). The checklist is
never the thing that slips.

## 3 · The gates, restated

- **Friends** receive a build only when every row of `owner-checks.md` is PASS
  on that build (D372). A FAIL is fixed and the failed rows re-run.
- **Submission** needs: the legal v2 live (done), the review notes true against
  the seeded reviewer account with a running season, the rating 13+, the privacy
  labels, eight screenshots, a Support URL that loads, no `APNS_SANDBOX` secret,
  `deploy-status` clean.
- **Stop conditions** (`docs/pilot/gates-and-stop-conditions.md`) are the only
  thing that pauses outreach: a duplicate live round for one booking, a
  double-posted card, an acknowledged score that did not land, any golfer seeing
  another's data, a trap screen reported by two testers, a week where assisted
  sessions exceed unassisted completions in an unassisted cohort, a claim card
  exposing more than name, gross, course and date.
- **Assume one Apple rejection cycle** (5.3.4 on the pot, 2.1 on an empty
  reviewer state) and answer from the playbook in `app-review-notes.md`. The
  store goes live when Apple says, not on the 1st.

## 4 · Risks, named

- **Device proof.** Nothing on a physical phone has ever been checked. Everything
  after Wednesday depends on it, which is why the first Owner build goes up
  today from the web halves alone rather than waiting a day for the Swift ones.
  The server side is already proven (72 restricted-role probes, row security on).
- **Apple distribution state.** 934 is pre-merge and five days old; the signing
  certificate runs to 2027-09-14 and the last upload worked on 09-16. The first
  upload of the merged tip is where signing drift shows; `tools/ios-signing.sh`
  is the recovery. Read `tools/asc.py status <build>` after every upload, and
  never treat a group add as distribution.
- **Capacity.** One person is builder, ops, support and publisher, and the Swift
  halves, the checklist, the screenshots, the legal packet and the metadata all
  land on one Mac in one week. The order above puts the checklist ahead of
  everything cosmetic.
- **Acquisition.** The outreach is drafts and a handful of groups by hand; the
  public link brings unknown numbers into a build whose two-phone checks are
  days old. The stop conditions decide, weekly, on the scorecard.
- **Codex's `20261111`** exists on one laptop. If it cannot be placed, the
  `courses` function must not be redeployed — the function change needs the RPC.

## 5 · Explicitly not before October 1

The bylaws re-open at the re-up (D375 is built; the terms carry locked, named
in its as-built note); captains-pick and live drafts (snake is refused at lock);
spreadsheet import; a price on any surface or a `/pricing` page (D183); Stripe;
Android native; a crash pipeline beyond `client_events`; Season Wrapped; the
Record as chapters; the crest; any change to §2.2's bands (D378 i). Each is in
the vision's year, none in its launch day.

## 6 · Running it

Paste `2026-09-22-claude-october-launch-prompt.md` into a fresh local Claude
session on the Mac, from the repo root, after `git pull`. Rule 6 applies: from
the merge onward the Mac owns the launch branch; no remote session runs on it
at the same time. A remote session may still take the migration and document
items above (D197 ruling 3, the inbox), on its own branch, and say so in the
handoff. Every session ends with the handoff block the prompt specifies, and
the release record in `ACTIVE_WORK.md` is corrected the same day anything
ships.
