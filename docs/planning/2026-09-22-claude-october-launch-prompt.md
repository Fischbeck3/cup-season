<!-- Paste everything below this line into a fresh LOCAL Claude session on the Mac, from the repo root, after `git pull` on main. The plan it executes is docs/planning/2026-09-22-october-launch-execution.md. -->

This session runs the October 1 launch from the Mac. Lane: GROWTH, LAUNCH &
SCALE, plus the native halves that only a local machine can build (CLAUDE.md
rule 6 — native work runs locally). Launch day is Thursday 2026-10-01:
submission to App Review that morning, outreach open the same day, a
TestFlight public link for strangers until Apple approves. Those are owner
rulings (D371–D379 in spec/decision-log.md); nothing in this session
re-decides them.

READ FIRST, IN THIS ORDER, BEFORE TOUCHING ANYTHING
1. CLAUDE.md — the protocol, the deploy discipline, the landmines. Rule 2 (the
   build stamps the version), rule 6 (one branch, one machine) and the "two
   deploys, always separate" rule are the ones this week trips on.
2. docs/planning/2026-09-22-october-launch-execution.md — the plan you are
   executing: §1 what was verified done on 2026-09-22, §2 the day table, §3
   the gates, §4 the risks, §5 what is not before Oct 1.
3. spec/launch-readiness-2026-10-01.md §4A, §4B, §4D — the ruled plan the
   execution view was cut from; §3 for the evidence behind any item.
4. docs/planning/2026-09-21-launch-rulings.md §7 — the phone halves, file by
   file, sentence by sentence. Build them from that list, not from memory.
5. docs/pilot/owner-checks.md and docs/pilot/gates-and-stop-conditions.md —
   the Friends gate and the stop conditions.
6. docs/ios/app-review-notes.md, docs/ios/app-store-listing.md,
   spec/appstore-runbook.md — the submission's content and order.
7. docs/planning/ACTIVE_WORK.md (the release record at the top) and
   spec/inbox.md — what is recorded as live, and what was found and not built.
8. apps/ios/README.md — how to generate, build, test and archive the phone.

ESTABLISH THE STATE BEFORE DOING ANY WORK, AND REPORT IT AS A TABLE
- `git status` and `git log --oneline -5` — you should be on main at or after
  1e79279 with a clean tree. Say if not.
- `./tools/ship.sh --dry-run` — read all three layers. Codex's
  20261111090000_course_cache_atomic.sql is expected to be Mac-only; report
  whether it is in the tree and whether production carries it.
- `node tests/preflight.mjs` — 0 failures, 0 warnings, or stop and say why.
- The live stamp: `curl -s https://cupseason.app/ | grep -o 'v23 · [0-9a-f]*'`
  should read the main tip. If it reads an older SHA, Netlify has not built
  the merge; say so before anything else.
- `python3 tools/asc.py status 934` (needs the two keychain items the script
  names) — report the Owner and Friends group state, and whether a build from
  the merged tip exists yet. Do not add a build to a group or submit anything
  in this step.
- `grep -rn "adjustPoints\|CS_CLAIM_UNFINISHED\|Ask again" apps/ios --include=*.swift`
  — confirms which phone halves are still absent, so the report is read from
  the tree, not from the plan.
Report all of that as one table (layer · state · how verified) and stop for
the owner's go before the first commit. Anything you could not verify reads
"unknown", never "clean".

THE WORK, IN THE PLAN'S ORDER — one item at a time, verified, then the next
A. The Swift halves (Tue 22), one commit per ruling, in this order, each
   built from the rulings packet §7 and its named files and pins:
   D373 the allowance clause · D374 the unfinished-link face and the read
   before claim_round · D375 the re-up (RunItBackResult, MyInvite, the
   covenant's season fact and frame, NOT IN YET + Ask again) · D376 the
   Ruling row and the receipt's override rows · D378 (vii) "since Sunday" →
   "this week" (verify SeasonStoryCopy, do not change it).
   Every sentence is a twin of a web producer already pinned in
   tests/app-tests.js — copy the pinned string, never reword it (D297: one
   producer per client, the same words on both). Rpc.swift is generated:
   `node tools/build-db.mjs` must report it current; never hand-edit it.
   Done when: `xcodegen` + the CupSeasonKit tests + the app tests are green
   and preflight is 0, per apps/ios/README.md. Say the counts.
B. The build to the Owner group, when the owner asks for it: check
   `supabase secrets list` shows no APNS_SANDBOX, then
   `tools/ios-archive.sh --upload` from a clean tree, then
   `python3 tools/asc.py status <build>`. Uploading is the owner's call each
   time; you run it only when expressly told to in that session. The build
   number is `git rev-list --count HEAD`; report it, and the owner reads the
   same number on both phones before the checklist starts.
C. The two-phone checklist (Wed 23 – Thu 24) is the owner's. Your part: when
   a row FAILs, reproduce from the row's wording, fix narrowly, run the
   suites, and hand back a new build for the failed rows only. Never mark a
   row PASS on the owner's behalf; never suggest a known-issues pass — the
   gate is every row PASS (D372, 2-A).
D. After the Friends gate passes, in this order: D377 as one web commit that
   does nothing else (the lockBylaws fallback, the state.emails plumbing,
   both "Invites out" readers), its iOS half staged for the first build AFTER
   the Beta App Review build, never on it; the review-notes refresh (re-point
   the 5.3.4 paragraph and the walkthrough at a seeded league whose season
   runs past the review window, run test-seed with the founder token, re-read
   every figure in the walkthrough against the seed); the Support URL decided
   and recorded in app-store-listing.md §5 (the one-line /support →
   /legal.html redirect in netlify.toml, or the root).
E. Fri 25 – Sun 27: whatever the checklist and Friends surfaced, narrowly;
   the CSP header flipped to enforcing ONLY if the Netlify deploy console
   shows a clean report (otherwise file what fired in spec/inbox.md and leave
   it); the release record corrected. Item 3 of §4B ("your first counting
   round") only if everything above is done — it is a migration plus both
   clients and can wait.
F. Mon 28 – Wed 30: the Monday build and the integrity re-run are the
   owner's; you fix what they find. Tuesday's weekly review: run
   `node tools/pilot-scorecard.mjs > docs/pilot/scorecard-2026-09-29.md`
   (read-only), read the integrity section first, and write the week's one
   line — hold · widen · stop — with the reason, at the top of that scorecard
   file. Wednesday's metadata is the owner's in App Store
   Connect; you check every field against app-store-listing.md and
   app-review-notes.md and say what is missing.
G. Thu Oct 1, after the owner submits: D197 ruling 3 — the age gate and the
   terms record (attestation / DOB, terms_version / accepted_at), one
   migration, both sign-in doors. Talk first: write the decision-log entry
   under D197's ruling before the migration, validate on the sandbox chain,
   and hand the owner the exact `supabase db push` in the handoff.

WHO RUNS WHAT — the human stays at the wheel for anything that mutates
production or Apple's side: `supabase db push`, `supabase functions deploy`,
`supabase secrets`, the TestFlight upload, adding a build to a group, Beta App
Review, the public link, the App Review submission. You sequence, verify and
state the exact command; the owner runs it, and you read the result back
(deploy-status, db-checks, asc.py status) before calling anything done. A
change touching the database and the client needs both pushes; say which.

RULES THAT DO NOT BEND THIS WEEK
- No hand-edit of the version lines (`__CS_VERSION__` in index.html and
  sw.js), of any generated Swift (Tokens.swift, Markers.swift, Rpc.swift), or
  of any migration that has run — a fix is a NEW timestamped migration.
- Never "dry-run" a migration against the linked project; the wrapper applies
  it. Validate on tests/sim/sandbox/apply.sh and read the result.
- Every new client-called RPC grants execute to authenticated and revokes from
  public and anon in the same file; run tests/db-checks.sql after any
  grant-touching push.
- No secret in the repo, ever: not the reviewer password, not the ASC issuer
  or key ids, not the .p8, not a webhook header. Point at where it lives.
- The repo is public: no real golfer's name, money, legal exposure or league
  politics in any file. Checklist results carry build numbers, not names.
- A mechanic change gets a decision-log entry before it is built. The phone
  halves are already ruled (D373–D378); D197 ruling 3 needs its entry written
  under that ruling. Anything not in the plan is talk-first: say what you
  found, propose, wait.
- One branch, one machine: this Mac session owns main for the launch. Do not
  start or continue a remote session on the same branch. If a remote session
  takes a migration or document item, it says so in the handoff and works on
  its own branch.
- Verify before commit: web changes through preflight and the browser (clear
  the service worker and caches first, or you test a stale build); Swift
  changes through the Kit and app suites and a build to a phone; migrations
  through the sandbox chain. Report failures with their output; never narrate
  a skipped step as done.
- If a stop condition fires (gates file), stop widening, say so in one line
  with the evidence, fix, re-verify, and let the owner decide.

WHAT NOT TO BUILD BEFORE OCTOBER 1 (plan §5): the bylaws re-open at the
re-up; captains-pick or live drafts; spreadsheet import; a price on any
surface; Stripe; Android; a crash pipeline; Season Wrapped; the Record as
chapters; the crest; any change to §2.2's bands.

HOW EVERY SESSION ENDS — the handoff block, exactly these fields, and
docs/planning/ACTIVE_WORK.md's release record corrected the same day:
Branch:
Goal:
What changed:
Files changed:
Verification run:
Database deploy owed:
Edge deploy owed:
Client deploy owed:
Open questions / risks:
Recommended next step:
Anything found and not built goes into spec/inbox.md with the date, the lane
and its first question. Start now with the state table.
