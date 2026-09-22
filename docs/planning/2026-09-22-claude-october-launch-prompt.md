<!-- Paste everything below this line into a fresh LOCAL Claude session on the Mac, from the repo root, after `git pull` on main. The plan it executes is docs/planning/2026-09-22-october-launch-execution.md. -->

This session runs the October 1 launch from the Mac. Lane: GROWTH, LAUNCH &
SCALE, plus the native halves that only a local machine can build (CLAUDE.md
rule 6 — native work runs locally).

THE OBJECTIVE, IN FULL
October 1 is the public launch: submitted to App Review that morning, outreach
open the same day, a TestFlight public link for strangers until Apple approves
(D371; rulings 10 and 14 in spec/decision-log.md). By December 31: 5,000
first-time App Store downloads, supported by successful real rounds and repeat
groups. Cumulative checkpoints: 500 by October 31, 2,000 by November 30, 5,000
by December 31 — first-time downloads as App Store Connect's App Analytics
counts them. TestFlight installs never count; web sign-ups never count; the
count is zero until Apple approves. Every acquisition assumption in the plan
is labelled unverified and stays so until App Analytics has two weeks of data.
The rounds and the repeat groups are measured by cohort every week, and the
stop conditions pause outreach whatever the count reads. The owner keeps a
weekly acquisition pipeline (prospects contacted, organizers activated, groups
playing, first-time downloads by channel; plan §4A) and reviews it against the
October 31 checkpoint by October 15 — you carry its four totals into the
weekly report; you never run the outreach. Nothing in this session re-decides
a ruling.

READ FIRST, IN THIS ORDER, BEFORE TOUCHING ANYTHING
1. CLAUDE.md — the protocol, the deploy discipline, the landmines. Rule 2 (the
   build stamps the version; migrations are never edited after they run), rule
   6 (one branch, one machine) and "two deploys, always separate" are the ones
   this week trips on.
2. docs/planning/2026-09-22-october-launch-execution.md — the plan you are
   executing: §0 the objective, §1 what was verified on 2026-09-22 and how, §2
   the release checklist by day, §3 the six workstreams with owners and
   acceptance criteria, §4 the owner's outreach (not yours), §5 the gates and
   the approvals that do not move, §6 the risks, §7 the scope cuts, §8 the
   protocol you are under.
3. spec/launch-readiness-2026-10-01.md §4A, §4B, §4D — the ruled plan the
   execution view was cut from; §3 for the evidence behind any item.
4. docs/planning/2026-09-21-launch-rulings.md §7 — the phone halves, file by
   file, sentence by sentence. Build them from that list, not from memory.
5. docs/pilot/owner-checks.md and docs/pilot/gates-and-stop-conditions.md —
   the two-phone gate and the stop conditions.
6. docs/ios/app-review-notes.md, docs/ios/app-store-listing.md,
   spec/appstore-runbook.md, spec/appstore-launch-kit.md §3 — the submission's
   content and order.
7. docs/planning/ACTIVE_WORK.md (the release record and its addenda) and
   spec/inbox.md — what is recorded as live, and what was found and not built.
8. apps/ios/README.md and tools/asc.py's header — how to generate, build, test,
   archive, and what the App Store Connect script does and does not do.

THE BRANCH
Work on a clean `claude/october-launch` branch in its own worktree, cut from
the current `main` tip at the start of this session:
  git fetch origin main && git worktree add ../cup-season-october-launch -b claude/october-launch origin/main
Every commit of this launch goes there; nothing is committed on `main`
directly; no remote session runs on this branch while you hold it. Merges to
`main` are the owner's call, one PR at a time, CI green.

THE BASELINE — establish it, report it as one table, then begin
No "go" is needed after the table: the work in the plan's §2 is authorized,
and you start it in this same session. The table's last column says one of
three things for every row, and never one for another: CONFIRMED (read from
the system named), CONFIRMED ABSENT (looked for in the tree and not there),
MISSING EVIDENCE (could not read it; state unknown).
- `git status`, `git log --oneline -5` on the new branch — at or after
  1e79279, clean tree.
- `./tools/ship.sh --dry-run` — all three layers. Report whether Codex's
  20261111090000_course_cache_atomic.sql is in the tree. It cannot tell you
  whether production carries it: deploy-status subtracts the ledger from the
  local files, so a version applied remotely with no local file reads as
  clean. Read the ledger itself — `supabase migration list --linked`, the
  Remote column — and report 20261111090000 as APPLIED or UNAPPLIED from that
  read alone.
- `node tests/preflight.mjs` — 0 failures, 0 warnings, or stop and say why.
- The live stamp: `curl -s https://cupseason.app/ | grep -o 'v23 · [0-9a-f]*'`
  — expected 1e79279. An older SHA means Netlify has not built the merge; say
  so before anything else.
- App Store Connect, READ, not remembered: the latest builds by upload date
  and what the Owner group and the Friends group each hold today. The record
  names 934 (Owner, pre-merge, 09-16) and 795 (Friends); anything uploaded
  since is not in the record, and this morning's merge proves nothing about
  what was archived after it — a build from the merged tip may already exist.
  `tools/asc.py status <build>` reads one build;
  if it cannot list builds and groups, add a `latest` command to it as a small
  tooling commit (no secrets, the same keychain items) and use that. Do not
  add a build to a group or submit anything in this step.
- `grep -rn "adjustPoints\|CS_CLAIM_UNFINISHED\|Ask again" apps/ios --include=*.swift`
  — the phone halves: read from the tree, not from the plan.
- The two-phone checklist: look for results — a filled row in
  docs/pilot/owner-checks.md, a scorecard or session-log note, anything the
  owner says. The record reads NOT RUN as of 09-16. Until results are located
  or the owner runs it, it is MISSING EVIDENCE, never "never run".
- `ls .well-known/ ; grep -n well-known netlify.toml stamp-version.sh` — the
  universal-links file is served; whether a reopened link lands in the app is
  MISSING EVIDENCE until a device says so (W3).

THE WORK, IN THE PLAN'S §2 ORDER — one item at a time, verified, then the next
A. 20261111: the ledger first, then the order. (0) Read production's
   migration ledger before anything else — `supabase migration list --linked`,
   the Remote column (read-only; `select version from
   supabase_migrations.schema_migrations order by version desc limit 12` says
   the same). A clean deploy-status does not establish that the migration is
   unapplied when the file is absent locally. If 20261111090000 is in the
   ledger it is APPLIED: obtain the file from the Mac workspace exactly as it
   was applied, place it in the tree under its own name, do not rename or edit
   it (rule 2), validate that the chain still applies cleanly with it in file
   order, and record in the handoff that the chain order and the applied order
   differ — a fact, not a repair. The rest of this item applies only if the
   ledger does not carry it. It sorts before four migrations production
   already carries (20261112–20261115), so file order and applied order
   differ. (1) Read its body: if it patches in
   place any function that 20261112–20261115 also patched (the
   pg_get_functiondef pattern), it must be rebased on the live text — say
   which functions, and rebase. (2) It has run nowhere but a sandbox, so
   rename it to sort after 20261115 — 20261116090000_course_cache_atomic.sql —
   so the file order equals the applied order; rule 2 forbids editing a
   migration that has run in production and this one has not. Expect the CLI
   to refuse an out-of-order file or to demand its include-all flag if the old
   name is kept; the rename is the answer, not the flag. (3) Sandbox chain
   (tests/sim/sandbox/apply.sh): the 252, then the renamed file, the
   course-cache probes, an idempotent second run; read the result. (4) Hand
   the owner, in this order: `supabase db push`, then `supabase functions
   deploy courses` with the flattenTees coercion already in the function, then
   tests/db-checks.sql 37/37, then `deploy-status` clean. Read each back.
B. The Swift halves, one commit per ruling, in this order, each from the
   rulings packet §7 and its named files and pins: D373 the allowance clause ·
   D374 the unfinished-link face and the read before claim_round · D375 the
   re-up (RunItBackResult, MyInvite, the covenant's season fact and frame, NOT
   IN YET + Ask again) · D376 the Ruling row and the receipt's override rows ·
   D378 (vii) "since Sunday" → "this week" (verify SeasonStoryCopy, do not
   change it). Every sentence is the twin of a web producer pinned in
   tests/app-tests.js — copy the pinned string, never reword it (D297: one
   producer per client). Rpc.swift is generated: `node tools/build-db.mjs`
   must report it current; never hand-edit it. Done when `xcodegen` + the
   CupSeasonKit tests + the app tests are green and preflight is 0, per
   apps/ios/README.md; say the counts.
   The only native half allowed to trail the launch build is D376's Ruling
   sheet (its own tradeoff: the desk carries the pen, the phone follows, the
   release record says so). That exception is D376's alone — D373, D374, D375
   and D378 (vii) ship in the build that goes to Friends, or the build waits.
   The readiness audit's §4E had placed D375's phone half post-launch; under
   the plan it is in the launch build. If the owner prefers §4E's placement,
   record it as a ruling in the handoff; do not treat it as a slip.
C. The builds to the Owner group are the owner's: you check `supabase secrets
   list` shows no APNS_SANDBOX, hand over `tools/ios-archive.sh --upload` from
   a clean tree, and read `python3 tools/asc.py status <build>` back. Run the
   upload yourself only when the owner says so in that session. The build
   number is `git rev-list --count HEAD`; the owner reads the same number on
   both phones before the checklist starts.
D. The two-phone checklist (Wed 23 – Thu 24) is the owner's. Your part: when a
   row FAILs, reproduce from the row's wording, fix narrowly, run the suites,
   hand back a new build for the failed rows only. Never mark a row PASS on
   the owner's behalf; never suggest a known-issues pass — the gate is every
   row PASS (D372, 2-A), and it stands for every build that reaches a stranger.
E. After the Friends gate, in this order:
   - D377, one web commit that does nothing else (the lockBylaws fallback, the
     state.emails plumbing, both "Invites out" readers); its iOS half staged for
     the first build AFTER the Beta App Review build, never on it.
   - The review notes: re-point the 5.3.4 paragraph and the walkthrough at a
     seeded league whose season runs past the review window; run test-seed with
     the founder token; re-read every figure in the walkthrough against the
     seed. The password stays a placeholder in the repo; it lives in App Store
     Connect only.
   - W5, the installation destination and the support page: `get.html` (the
     TestFlight public link until approval, the App Store link after, the web
     app as the other door, the install-then-reopen sentence) and
     `support.html` (how to get help, the install guidance, what to do when a
     link does not open, deletion in one sentence, the legal links). Both in
     the dist allowlist in stamp-version.sh or they 404; `/get` and `/support`
     redirects in netlify.toml; the door's footer points at `/get`; the Support
     URL recorded in app-store-listing.md §5 as https://cupseason.app/support.
     Done when both load on the Netlify preview.
   - W4, install-then-reopen: the one sentence — "Install the app, then open
     this link again" — on the signed-out door, in get.html, in every outreach
     draft and the Friends task sheet. No copy anywhere promises that the app
     will remember or restore a link; deferred deep linking is out of scope
     and is not built.
F. W2, the one round-sharing action, Fri 25 – Sun 27, after the owner rules
   on its shape (put the shape to the owner on Thu 24, talk-first, with a
   decision-log entry at the IA level before the build). Today a posted round
   shares through four web doors (shareRoundCard, shareRecapCard,
   shareSettlementCard, shareMajorCard) plus the share link (share_info, D57),
   and the phone has ShareIntent / ShareLinkService. The target: one Share
   action from a posted round on both clients that produces the round card and
   the share link together; the recap, settlement and major cards stay their
   own artifacts. The photo rides the card only when the golfer attached it to
   that round and says yes on the share sheet; never another golfer's photo;
   the marker medallion stays (D59); a golfer whose findability is "nobody"
   is never on a card they did not share. Logged through log_growth_event.
   Photo consent governs EVERY output, not only the card: the exported image;
   the public share page (/?share=TOKEN, which draws shared/{token}.jpg as the
   card's ground when share_info.photo is true); the link preview
   (netlify/edge-functions/share-preview.ts, which sets og:image to the same
   copy). Today none of them ask: PostService.shareLink reads
   rounds.photo_path and uploads the copy to shared/{token}.jpg on its own;
   the web's csShareLink uploads it when the listing finds none; create_share
   re-returns the live token; share_info.photo is exists(copy). So a copy
   uploaded once serves the page and the preview for as long as the token
   lives. Build the consent half FIRST, whatever shape the action takes: the
   yes or no is asked on the share sheet and carried into the mint on both
   clients; NO means no upload, and on a reused token that already has a
   copy, delete the copy (the storage policy lets the sharer delete their own
   token's copy) or revoke and re-mint so a cached preview cannot keep serving
   it; with the copy gone share_info.photo reads false, the page draws no
   ground and the preview falls back to the brand image.
   Done when: the same artifact and the same sentence from one action on both
   clients (one producer per client, D297); a round without a photo shares the
   card without one; declining the photo keeps it out of all three outputs —
   the exported image, the public page, the preview — INCLUDING when the token
   already existed with a copy (prove it: share_info for that token reads
   photo false and the copy's URL answers 404); accepting puts it in all
   three; a Kit test on shareLink with consent false and a copy present; a web
   pin on the consent branch; the share appears in v_growth_funnel.
   Consent half on both clients and the action's web half by Fri 27; the
   action's phone half on the Mon 28 build.
G. Fri 25 – Sun 27, alongside: whatever the checklist and Friends surfaced,
   narrowly; the CSP header flipped to enforcing ONLY if the Netlify deploy
   console shows a clean report (otherwise file what fired in spec/inbox.md
   and leave it); the release record corrected. W1 (the timed tests) and W3
   (the recipient journeys) are the owner's to run that weekend — your part is
   the W1 script (the four gates, the stopwatch protocol, the recording sheet
   with build numbers and no names), reading v_pilot_gates the same week, and
   fixing every stall W3 files. tests/pilot/claim-walkthrough.py green on the
   tip is your half of W3.
H. Mon 28 – Wed 30: the Monday build and the integrity re-run are the owner's;
   you fix what they find. Tuesday: W6, the first weekly report — extend
   tools/pilot-scorecard.mjs (and tests/pilot/scorecard.sql) to five sections
   with a denominator on every number: cohort, assistance, activation (account
   → first posted round → second round; groups with a second game), sharing
   (v_growth_funnel's first reader), acquisition (cumulative first-time App
   Store downloads against the §0 checkpoints, BY CHANNEL where App Analytics'
   sources or the owner's pipeline can attribute them, read by hand from App
   Analytics until asc.py reads it; the owner's four pipeline totals —
   prospects contacted, organizers activated, groups playing, downloads by
   channel — carried in as the owner reports them, from the week of Oct 1;
   TestFlight installs and web sign-ups shown separately and never summed in;
   zero until approval, and the report says so). By October 15 the report
   carries the pipeline's first two weeks against the October 31 checkpoint,
   with the contact-to-activation and activation-to-playing rates as measured,
   for the owner's review. Run it
   read-only: `node tools/pilot-scorecard.mjs > docs/pilot/scorecard-2026-09-29.md`,
   the week's sessions entered first, the integrity section read first; write
   the week's one line — hold · widen · stop — with the reason, at the top of
   that file. Wednesday's metadata is the owner's in App Store Connect; you
   check every field against app-store-listing.md and app-review-notes.md and
   say what is missing.
I. Thu Oct 1, after the owner submits: D197 ruling 3 — the age gate and the
   terms record (attestation / DOB, terms_version / accepted_at), one
   migration, both sign-in doors. The decision-log entry under D197's ruling
   first; validate on the sandbox chain; hand the owner the exact
   `supabase db push` in the handoff. On approval day: get.html swaps the
   TestFlight link for the App Store link, and the acquisition section of W6
   starts counting.

WHO RUNS WHAT — the approvals do not move
The human stays at the wheel for anything that mutates production or Apple's
side: `supabase db push`, `supabase functions deploy`, `supabase secrets`, the
TestFlight upload, adding a build to a group, Beta App Review, the public
link, the App Review submission. You sequence, verify and state the exact
command; the owner runs it; you read the result back (deploy-status,
db-checks, asc.py status) before calling anything done. A change touching the
database and the client needs both pushes; say which. The owner's outreach —
the Friends message, the independent groups, the public link, the r/golf post,
the handles, counsel, the weekly acquisition pipeline — is the plan's §4 and
§4A and is not engineering: you do not send anything, and the drafts stay
drafts with no name in them.
Keep implementation moving while an owner action or a production approval is
pending. A hand-over — a push, an upload, a group add, a submission, the
ledger read, a ruling — is not a wait: take the next item in §2 or §3 that
does not depend on it, and return to the pending one when its result is read
back. Never perform the owner's step yourself to unblock.

RULES THAT DO NOT BEND THIS WEEK
- No hand-edit of the version lines (`__CS_VERSION__` in index.html and
  sw.js), of any generated Swift (Tokens.swift, Markers.swift, Rpc.swift), or
  of any migration that has run — a fix is a NEW timestamped migration.
  (Whether 20261111 has run in production is read from the ledger, never
  assumed: an unapplied file may be renamed; an applied one is preserved
  exactly as applied, name and body.)
- Never "dry-run" a migration against the linked project; the wrapper applies
  it. Validate on tests/sim/sandbox/apply.sh and read the result.
- Every new client-called RPC grants execute to authenticated and revokes from
  public and anon in the same file; run tests/db-checks.sql after any
  grant-touching push. A new served page goes in the dist allowlist or it 404s.
- No secret in the repo, ever: not the reviewer password, not the ASC issuer
  or key ids, not the .p8, not a webhook header. Point at where it lives.
- The repo is public: no real golfer's name, money, legal exposure or league
  politics in any file. Checklist and test results carry build numbers, not
  names.
- A mechanic change gets a decision-log entry before it is built. The phone
  halves are already ruled (D373–D378); W2 needs an IA-level entry; D197
  ruling 3 needs its entry under that ruling. Anything not in the plan is
  talk-first: say what you found, propose, wait.
- Missing evidence is not absence. What you could not read is "unknown"; what
  you looked for in the tree and did not find is "absent". Never one word for
  the other, in the baseline or in a handoff.
- Verify before commit: web changes through preflight and the browser (clear
  the service worker and caches first, or you test a stale build); Swift
  changes through the Kit and app suites and a build to a phone; migrations
  through the sandbox chain. Report failures with their output; never narrate
  a skipped step as done.
- If a stop condition fires (gates file), stop widening, say so in one line
  with the evidence, fix, re-verify, and let the owner decide.

WHAT NOT TO BUILD BEFORE OCTOBER 1 (plan §7): the bylaws re-open at the
re-up; captains-pick or live drafts; spreadsheet import; a price on any
surface; Stripe; Android; a crash pipeline; Season Wrapped; the Record as
chapters; the crest; any change to §2.2's bands; deferred deep linking.

HOW EVERY SESSION ENDS — the handoff block, exactly these fields, and
docs/planning/ACTIVE_WORK.md's release record corrected the same day anything
ships:
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
and its first question. Start now: cut the branch, establish the baseline,
report the table, and begin item A.
