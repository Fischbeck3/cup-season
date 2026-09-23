# September 22 · Owner phone beta

## Target and scope

Prepare the recent launch and visual work for Jerecho's phone tonight. Codex owns integration, visual corrections, local verification and the signed candidate. This is an internal **Owner** beta to collect real-device evidence. The Friends gate in D372 and the public launch checklist remain open.

Candidate branch: `codex/october-visual-ui`, isolated worktree `/private/tmp/cup-season-visual-ui`. The older dirty visual checkout remains intact. Claude's W6 corrections (`8f632ed`) are integrated by `9d9ef46`; the native launch fixes, D380 sharing flow and V1 entrance fixes are all included. Archived source: **`37f959e`**, **1.0.0 (986)**. Later documentation-only commits do not change that package.

## Tonight's visual corrections

1. **Readable entry fields:** shared `CSField` placeholder prompts use opaque `mut`, matching the existing secondary-text rule in both rooms.
2. **Honest Home emphasis:** the full Home lead uses competition/live styling only for competition items, matching F11 and the compact row. An ordinary after-golf plan no longer receives a live dot or live VoiceOver label.
3. **A clean exported card header:** keep the pennant and Cup Season name together, with a guaranteed gap and a full-width header before the record label. The exported canvas, mark and typography stay canonical.
4. **Competition reachability:** exercise the existing populated competition fixture in dark/light and default/AX3 text. Check row bounds and the Start something action after scrolling.

Existing launch improvements in this candidate include unfinished/claim/ruling/re-up UI, one Share action with card/link and photo consent, atomic course-cache client support, and the invitation context at the native welcome. This packet does not claim the entire visual sprint is complete.

## Verified baseline, September 22

- App Store Connect readback: latest uploaded build **934**; internal Owner carries 934, 932, 919, 905 and 898. External Friends' latest is **795**. No recent native work has reached either group yet.
- Production migration ledger ends at **20261115090000**. The course-cache and shared-card migrations are absent. Supabase `courses` is version **18**, updated August 29.
- Fresh local PostgreSQL **17** chain: **254 applied, zero skipped**. The 17 W6 database tests passed. Course-cache validation, reapplication on the same populated sandbox and shared-card storage policy probes passed.
- Integrated top-level Node tests: **57 passed**, zero failed; with the separate database suite, **74 passed**. Preflight passed with zero failures/warnings before the final visual corrections.
- Baseline visual walkthroughs: **27 passed**, zero failed/skipped. Coverage includes Home with/without photos, after-golf states, ruling/re-up sheets, setup, offline score/relaunch/keep, share photo choices and native share cancellation.
- The initial field/competition verification passed **1,497 native tests**, zero failed/skipped, on the iPhone 17 Pro simulator. The final-pass results, including the observed test failures, are recorded below.

Machine-local evidence: `/private/tmp/cup-season-beta-db/`, `/private/tmp/cup-season-beta-baseline.xcresult`, `/private/tmp/cup-season-beta-verified.xcresult`, and their exported screenshot directories. Fixture renders establish layout, not authenticated production behavior or an unassisted real round.

## Release dependencies and boundaries

The reviewed [deployment packet](2026-09-22-course-cache-deploy.md) contains exactly `20261116090000_course_cache_atomic.sql`, `20261117090000_shared_card_consent.sql`, then the `courses` Edge deployment. An explicit owner approval is pending. Re-read the ledger and dry-run the exact pending set before any production write. Never execute the local mutation probes on production.

The signed archive can be prepared while that approval is pending. Upload and internal Owner distribution must identify the exact build and source commit. Do not use `tools/asc.py ship`: it targets Friends and external review. Do not merge to main, submit for App Review, open the Friends gate or publish a public installation link as part of this Owner beta.

## What to test on the phone

Record the installed version/build, device/iOS, room/look and text size. Use real existing golf records or clearly designated test data; do not fabricate a real round to improve a metric.

1. **Get in and move around.** Sign in, then visit Home, Golfers, Play, Compete and You. Open settings and return. Check text, tabs, back buttons, sheet dismissal and the keyboard in dark and light.
2. **Prepare and score.** Find a course and its tees; check a long course name. Exercise the approved round/score workflow, background/reopen and the documented offline recovery path. Confirm the saved state is understandable.
3. **Finish and understand.** Open a posted receipt, the season and the points/adjustment explanation. Check the no-round adjustment state and Run it back covenant where available.
4. **Share deliberately.** Preview a real photo round and a no-photo round. With the photo off, confirm the image, public page and link preview omit it; with it on, confirm the intended image. Cancel the share sheet and return safely. The production Storage API proof in recipient-journeys.md remains required.
5. **Receive it.** On the second phone, run the actual claim and invitation scripts through sign-in. Record expired/already-used behavior and install-then-reopen. Local fixtures are not a substitute for this check.

Use the full [owner checks](../pilot/owner-checks.md) and [recipient journeys](../pilot/recipient-journeys.md) for the formal release gate. Record failures with a screenshot, the last action, expected result and build number; a screenshot alone cannot establish the behavior.

## UI work after tonight's beta

- Golfers, relationships, You, record and settings: capture populated/empty/error/private states and verify the real signed-in routes.
- Complete the 13-family inventory: course search failures, code errors, setup/admin variants, public recipients, widgets/live activity and permission-denied states.
- Complete accessibility evidence: long names, largest useful text sizes, VoiceOver/focus order, reduced motion and safe-area/keyboard reachability across those routes.
- Run the timed comprehension tasks with real golfers, then fix the observed failures.
- Capture App Store imagery from the accepted build with approved content; replace `/get`'s hidden installation target only when the real invitation/store URL is authorized and available.

These remain in the [visual sprint](2026-09-22-visual-ui-sprint.md). They do not all have to be complete to obtain tonight's internal phone feedback; they do have to be accounted for before the public launch claim.

## Candidate evidence and disposition

### Final local checks

- Preflight: **PASS, zero failures/warnings** after replacing the added literal card spacing with `CSTokens.Space.s4`.
- Full final native pass: **1,508 passed, one failed**, zero skipped. All **1,493 Kit/design/app tests passed**. The failure was the standard-phone native share-cancellation UI check: the activity sheet remained visible five seconds after the recorded close tap. Its recording and accessibility hierarchy were inspected; do not relabel that run as green.
- Small phone (iPhone SE 3, 375pt): **129 passed**, zero failed/skipped, including all design tests, artifact exports, invitation/field, competition, after-golf AX3 and all five round-share walkthroughs. This rebuild includes the final token-based card spacing. Long-value export, large-text share, email and competition screenshots were visually inspected.
- Standard-phone cancellation diagnostic: three repetitions; the first failed to open the DEBUG share fixture at all, and the next **two passed**, including native dismissal. The baseline cancellation check and the small-phone cancellation check also passed. These results leave an intermittent simulator/UI-harness observation; real-phone cancellation still needs checking. No production cancellation code was changed in this visual pass.
- One initial final-suite attempt stalled before test execution and was cancelled. The isolated simulator was restarted before the recorded full final pass. Preserve this as infrastructure evidence, not a product pass.
- TestFlight push precheck: the production secret-name listing has **no `APNS_SANDBOX`**. No secret value was printed or changed.
- The competition test now checks full vertical visibility, not just `isHittable`; the final run **passed on both 375pt and 402pt phones**, in dark/light and default/AX3 variants. The full-label screenshots were inspected.

Result bundles: `/private/tmp/cup-season-beta-final-rerun.xcresult`, `/private/tmp/cup-season-beta-small.xcresult`, `/private/tmp/cup-season-beta-cancel-repeat.xcresult`, `/private/tmp/cup-season-beta-action-bounds.xcresult`. The known Supabase initial-session runtime warning remains unchanged.

### Candidate

**Prepared, signed and exported; not Apple-validated, uploaded or distributed.**

- Source commit: `37f959e`; build **1.0.0 (986)**, generated from commit count.
- Archive: `/private/tmp/cup-season-visual-ui/apps/ios/build/archive/run-986-37f959e.QoXfzc/CupSeason.xcarchive`.
- Exact IPA: `/private/tmp/cup-season-visual-ui/apps/ios/build/archive/run-986-37f959e.QoXfzc/export/Cup Season.ipa` (**19,965,012 bytes**).
- SHA-256: `a9de87cfd14590b7cd1d838e7baf63c7b9e5bbe6fb9e160f0edbbfbdafcaf87d`.
- App and widget signatures: `codesign --verify --deep --strict` **PASS**. Both are 1.0.0 (986), iOS 17 minimum, non-debuggable, and use the same app group. Distribution profiles expire September 14, 2027. App APNs entitlement is `production`.
- Archive/export completed successfully using the existing local signing vault. Existing compiler warnings in unchanged sources were retained; this is not a warning-free archive claim.
- Release-string inspection found the existing `-cs_dev_no_worth` argument check in `PostRoundModel` remains compiled outside its neighboring DEBUG block. It only suppresses the worth read when explicitly supplied; the normal phone launch does not supply it. Move that diagnostic guard wholly under DEBUG in a later code slice. The inspected visual fixture launch switches are absent from this executable. Do not claim a blanket zero-debug-string check passed.
- Local package inspection: `/private/tmp/cup-season-beta-986-package-check.json`. Archive/export logs remain beside the archive.
- Visual review: `/Users/fischbeck3/.codex/visualizations/2026/09/22/01a0c938-cfd8-7640-a89d-da9d1edade7e/cup-season-owner-beta-review.html` (four embedded native captures, rendered and checked in the browser).

**Approval state (superseded 2026-09-23 — see [Owner approvals](#owner-approvals--recorded-2026-09-23t030928z)):** automatic approval review rejected `altool --validate-app` before execution because transmitting the signed IPA to Apple needs explicit approval for this build. No package was sent. The owner has been asked to approve validation, upload and internal Owner distribution of this exact IPA. The earlier two-migration/`courses` production approval is also pending. Do not rerun the denied validation or perform dependent Apple/production writes without the corresponding answer.

Owner group: `c4a784fe-22c5-4a75-bd4b-ca864b63574a`. Friends group: `9f8db84a-166c-4900-b196-ea2c5459e369` (closed to this candidate). After approval, validate this exact package, upload it without rebuilding, await VALID processing, update its What to Test, add only to Owner and read that group's build relationship back. An upload alone is not distribution, and distribution is not proof that the phone installed it.

No database, Edge, Netlify production, Apple upload, group assignment, review submission or main merge was performed by this beta-preparation pass.

## Release execution · 2026-09-23 (Claude, remote sandbox) — branch `claude/owner-beta-release`

**This session ran in a remote Linux sandbox, not on the Mac.** It has no copy
of the IPA, no Xcode/`codesign`/`altool`, no App Store Connect key, no
`supabase` CLI, and cupseason.app is blocked by its egress policy. It therefore
did NOT verify the package, read App Store Connect, read the `courses` version
or secret names, read the live web stamp, apply anything or upload anything.
Those steps are the Mac runbook below; lint is not offered in place of any of
them. What the sandbox could check, it checked read-only.

### Verified here (read-only, 2026-09-23 ~03:05 UTC)

| Check | Result |
|---|---|
| Candidate identity | `origin/codex/october-visual-ui` = `bedc03e`. The three commits after `37f959e` (`77e91cc`, `dbd0ec6`, `bedc03e`) touch only `docs/`; `git diff 37f959e bedc03e -- apps supabase index.html sw.js tools` is empty. `8f632ed` is an ancestor of `37f959e`. **1.0.0 (986) from `37f959e` remains the candidate; nothing to rebuild.** |
| Production migration ledger | **252** applied, latest **`20261115090000`**. Diffed against this checkout's 254 files: local-only are exactly `20261116090000_course_cache_atomic.sql` (sha256 `fbde7a98…cba19`) and `20261117090000_shared_card_consent.sql` (sha256 `4dd55a58…8fe4`); nothing is remote-only. |
| Not applied out of band | `cache_course_card` absent; `can_write_share_copy` / `can_drop_share_copy` exist from `20261015090000` and admit **`.jpg` only**; no `shared_copy_read` policy (storage has `shared_copy_insert`, `shared_copy_delete`). |
| Build 986 against today's production | Before it makes a round's link, `PostService.shareLink` asks `can_drop_share_copy('<token>.png')` and throws `ShareConsent.NotReady` when it says no — which production says today. **On the phone, Share → link shows "Round sharing needs the latest update. Try again shortly." until `20261117090000` is applied.** It fails safe (no copy is published and no absence is inferred), but the share, photo-consent and cancel-after-link checks need deployment A first. Course search works either way; A adds the atomic cache. |
| Web client skew (from source; live stamp unread) | `origin/main` = `1e79279` is an ancestor of the candidate. If the live site is `main`: the public page shows a round's photo only when `shared/{token}.jpg` exists (`share_info.photo`), so an opt-out that removes the JPEG cannot leak through the old page; the link preview on `main` never uses the travelling card PNG (it shows the photo when consented, else the brand image); "Get the app" goes to `/`; `/get` and `/support` do not exist on `main`. None of this blocks the Owner phone test; publishing the web client is outside this handoff and was not done. |

### Owner approvals — recorded 2026-09-23T03:09:28Z

Asked once, batched, after the read-only checks above, in the owner's Claude
session (remote sandbox `claude/owner-beta-release`). The owner's answers:

- **A — APPROVED:** `supabase db push` of exactly
  `20261116090000_course_cache_atomic.sql` and
  `20261117090000_shared_card_consent.sql` (the only pending pair against the
  live ledger at 252 / `20261115090000`), then `supabase functions deploy
  courses` only, with the read-backs in step A below.
- **B — APPROVED:** send the exact signed **1.0.0 (986)** IPA from `37f959e`
  (sha256 `a9de87cfd14590b7cd1d838e7baf63c7b9e5bbe6fb9e160f0edbbfbdafcaf87d`,
  19,965,012 bytes) to Apple for validation, upload it **once** if valid, then
  add it to the internal **Owner** group only — never Friends, never external
  review — and read back its availability.

Scope limits that travel with these approvals: they cover exactly these two
files, `courses`, and this one package. If the ledger has advanced, the
pending set differs, or the package's checksum, size, versions, signatures or
APNs entitlement differ from step 0, the approval does not transfer — stop
and ask. They do not cover a main merge, Netlify production, a public link,
Friends, Beta App Review or App Store submission.

**Not executed in this session:** the sandbox cannot run them (no IPA,
`altool`, App Store Connect key or `supabase` CLI). Applying the SQL through
the database connector instead would skip `db push`'s ledger record (the
first landmine in CLAUDE.md), and changing tools is not a workaround, so
nothing was applied, deployed, validated or uploaded. A local session on
the Mac executes the runbook below under these approvals.

### Mac runbook — exact commands (a local session on the Mac)

(CLI ≥2.116 prints JSON when piped, so every piped `supabase` read below passes `--output-format text`, as `tools/deploy-status.mjs` does.) Run from a clean worktree of this branch (`git fetch origin && git worktree add -b owner-beta-mac /private/tmp/cs-owner-beta origin/claude/owner-beta-release`), never the older dirty checkout. No command below prints a secret.

**0 · The package (before anything is sent).**

```bash
IPA="/private/tmp/cup-season-visual-ui/apps/ios/build/archive/run-986-37f959e.QoXfzc/export/Cup Season.ipa"
shasum -a 256 "$IPA"      # must be a9de87cfd14590b7cd1d838e7baf63c7b9e5bbe6fb9e160f0edbbfbdafcaf87d
stat -f %z "$IPA"         # must be 19965012
W=$(mktemp -d) && unzip -q "$IPA" -d "$W" && APP="$W/Payload/CupSeason.app"
codesign --verify --deep --strict --verbose=2 "$APP"
codesign --verify --strict --verbose=2 "$APP/PlugIns/CupSeasonWidgets.appex"
for p in "$APP" "$APP/PlugIns/CupSeasonWidgets.appex"; do
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' -c 'Print :CFBundleVersion' "$p/Info.plist"; done   # 1.0.0 / 986, twice
codesign -d --entitlements :- "$APP" 2>/dev/null | plutil -p - | grep -E 'aps-environment|get-task-allow'   # "production"; get-task-allow false or absent
```

Any mismatch stops the run: a replacement package needs its own identity and its own approval.

**1 · Read-only state.**

```bash
python3 tools/asc.py builds 8        # latest uploads and which group has each (expect 934 newest, Owner)
python3 tools/asc.py groups          # Owner newest 934…, Friends newest 795
python3 tools/asc.py status 986      # expect "no build 986 on the app yet" — if it exists, do NOT upload again
supabase migration list --output-format text | tail -4   # Remote ends 20261115090000; Local adds 20261116090000, 20261117090000
supabase functions list --output-format text | grep -E 'courses'   # expect version 18
supabase secrets list --output-format text | grep -q 'APNS_SANDBOX' && echo "APNS_SANDBOX present — stop" || echo "no APNS_SANDBOX"   # names only; no value is printed
./tools/ship.sh --dry-run            # database / edge / client, reported separately; runs nothing
curl -s https://cupseason.app/ | grep -oE 'v23 · [0-9a-f]+' ; git rev-parse --short origin/main    # the live stamp vs main
```

**A · Database, then Edge (only with approval A).**

```bash
supabase db push --dry-run           # exactly the two files above, nothing else
supabase db push
supabase migration list --output-format text | tail -3   # 20261116090000 and 20261117090000 now Remote
supabase functions deploy courses    # only after the cache RPC exists
supabase functions list --output-format text | grep -E 'courses'   # version advanced past 18
supabase db query --linked "select
  (select count(*) from supabase_migrations.schema_migrations where version in ('20261116090000','20261117090000')) as recorded,
  has_function_privilege('service_role','public.cache_course_card(jsonb,jsonb)','execute') as cache_service_role,
  has_function_privilege('authenticated','public.cache_course_card(jsonb,jsonb)','execute') as cache_authenticated,
  has_function_privilege('anon','public.cache_course_card(jsonb,jsonb)','execute') as cache_anon,
  (select bool_and(position('.png' in prosrc) > 0) from pg_proc where proname in ('can_write_share_copy','can_drop_share_copy')) as helpers_admit_png,
  has_function_privilege('anon','public.can_drop_share_copy(text)','execute') as drop_anon,
  (select count(*) from pg_policies where schemaname='storage' and tablename='objects' and policyname='shared_copy_read') as read_policy"
# expect: 2 · t · f · f · t · f · 1
supabase db query --linked --output-format text -f tests/db-checks.sql   # read-only; every row PASS (the file's own header gives this form)
```

Never run `tests/course-cache-*.sql` or `tests/shared-card-storage-checks.sql` against production — they are sandbox probes.

**B · Apple (only with approval B).**

```bash
export ASC_ISSUER_ID=$(security find-generic-password -a "$USER" -s cupseason-asc-issuer -w)
export ASC_KEY_ID=$(security find-generic-password -a "$USER" -s cupseason-asc-key -w)
xcrun altool --validate-app --type ios -f "$IPA" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
python3 tools/asc.py status 986      # still absent? then, once:
xcrun altool --upload-app --type ios -f "$IPA" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
python3 tools/asc.py owner 986 "Owner beta 1.0.0 (986), source 37f959e. Please check: Share — open, cancel, reopen; photo on and off on the card, the page and the link preview. Move through Home, Golfers, Play, Compete, You and settings. Find a course and tees, score, background and reopen. Open a posted receipt's points explanation. Known: one simulator run left the share sheet open after Close — check it here."
python3 tools/asc.py status 986      # Owner YES · internalBuildState IN_BETA_TESTING · Friends no
```

`asc.py owner` (added on this branch) waits for VALID with a 30-minute bound, sets What to Test, adds the build to **Owner only**, then reads back Owner membership, `internalBuildState` and Friends. It refuses to continue if Friends cannot be read or already holds the build, never posts a Beta App Review submission, and exits non-zero unless the build is in Owner, `IN_BETA_TESTING` and absent from Friends. **Never `asc.py ship`** — Friends plus external review. If an upload's outcome is uncertain, read `asc.py status 986` before any retry; a second upload of the same build number is rejected anyway.

Order: A before the share checks (see above). B does not depend on A — the app installs and runs against today's production — but the share row of the phone checklist waits for A.

### Executed on the Mac · 2026-09-23 03:13–03:23 UTC

Run from a clean worktree of this branch at `1470cf7` (`/Users/fischbeck3/cup-season-owner-beta`; the Supabase link had to be re-established there with `supabase link --project-ref zddbfcokmvneltrgukzf`, since a fresh worktree carries no `supabase/.temp`). Every step below is a command from the runbook; nothing outside it was run. No secret was printed.

| UTC | Step | Result |
|---|---|---|
| 03:13:50 | **0** package | sha256 `a9de87cfd14590b7cd1d838e7baf63c7b9e5bbe6fb9e160f0edbbfbdafcaf87d` · 19,965,012 bytes · app and widget `valid on disk`, `satisfies its Designated Requirement` · 1.0.0 / 986 on both · `aps-environment` production · `get-task-allow` false. **Match.** |
| 03:13:56 | **1** ASC | builds: 934 newest, Owner; groups: Owner newest 934 (6), Friends newest 795 (9); `status 986`: "no build 986 on the app yet". **Match.** |
| 03:14:38 | **1** database / edge / web | ledger 254 local, **252 remote**, latest remote `20261115090000`; local-only exactly `20261116090000` (`fbde7a98…`) and `20261117090000` (`4dd55a58…`), nothing remote-only · `courses` version **18** · no `APNS_SANDBOX` among 26 secret names · `ship.sh --dry-run`: database owed (the two), edge MAYBE (courses), client owed (38 commits) · live `v23 · 1e79279` = `origin/main`, an ancestor of HEAD. **Match — the approvals transfer.** |
| 03:15:27 | **A** `db push --dry-run` | exactly `20261116090000_course_cache_atomic.sql`, `20261117090000_shared_card_consent.sql` |
| 03:16:01 | **A** `db push` | both applied; 03:16:06 ledger reads both as Remote (254) |
| 03:16:38 | **A** `functions deploy courses` | deployed (`index.ts`, `normalize.ts`); 03:16:41 list reads **version 19**, 2026-09-23 03:16:40 |
| 03:17:03 | **A** read-backs | probe: `recorded 2 · cache_service_role t · cache_authenticated f · cache_anon f · helpers_admit_png t · drop_anon f · read_policy 1` — the expected `2 · t · f · f · t · f · 1`. `tests/db-checks.sql`: **37 rows, 37 PASS**, no FAIL. |
| 03:17:32 | **B** `altool --validate-app` | 03:19:02 **VERIFY SUCCEEDED with no errors** |
| 03:19:2x | **B** `status 986` | still absent → upload once |
| 03:19:27 | **B** `altool --upload-app` | 03:20:31 **UPLOAD SUCCEEDED with no errors**, Delivery UUID `80f0393a-dc5e-427d-916b-ba7c671c543a`, transferred 19,965,012 bytes |
| 03:20:40 | **B** `asc.py owner 986 "…"` | not visible ×3 → VALID (READY_FOR_BETA_TESTING) → what to test 200 → add to Owner 204 → read-back **in Owner YES · IN_BETA_TESTING · in Friends no** (03:22:48) |
| 03:23 | final `status 986` / `groups` / `deploy-status` | VALID · IN_BETA_TESTING · betaReviewState None · Owner YES (7 builds, newest 986) · Friends no (9, newest 795) · database clean 254 · edge clean · client still owed (main unchanged, by scope) |

Not run, by scope: `asc.py ship`, Friends, Beta App Review, main merge, Netlify, any public link. Phone install is **not** confirmed by any of the above.

### Phone checklist (1.0.0 (986), after `asc.py owner` reports availability)

Install from TestFlight and read the build on the phone (TestFlight → Cup Season, and You → settings). Note device, iOS, dark/light and text size. Record each line as PASS / FAIL + screenshot + last action; nothing below is pre-filled.

1. **Share cancellation** (the one open automated failure): post-round → Share → cancel the system sheet → it closes and you are back where you were; open Share again → it works. Repeat twice.
2. **Photo consent** (after A): a round with a photo — share with the photo **off**: the card, the opened link and the chat preview show no photo; share again with it **on**: the photo appears. Turn it off once more: a new link is made. A round with no photo shares cleanly.
3. **Navigation:** sign in → Home, Golfers, Play, Compete, You → settings → back. Tabs, back buttons, sheet dismissal, keyboard; dark and light.
4. **Scoring:** find a course and tees (a long name too) → start, enter scores → background the app and reopen → the round and scores are still there → finish.
5. **Receipt:** open a posted round's receipt → the points explanation reads correctly; check a no-round adjustment line if you have one.

Second phone, when available: the claim and invitation scripts in `docs/pilot/recipient-journeys.md`, the Storage consent reads there, and one real claim on this release build read back from `profiles.came_via_kind` (attribution cannot be proven with DEBUG).

### For the Mac session — paste this

```text
Execute the approved Owner beta release on this Mac. Read
docs/planning/2026-09-22-owner-beta.md on origin/claude/owner-beta-release,
section "Release execution · 2026-09-23": the owner approved A (the two named
migrations, then courses only) and B (validate, upload once and distribute to
internal Owner only the exact 1.0.0 (986) IPA, sha256 a9de87cf…af87d). Work in
a clean worktree of that branch. Run step 0 and step 1 first; if any identity,
ledger or pending-set check differs, stop and ask — the approval does not
transfer. Then A with its read-backs, then B ending in `asc.py owner 986`
reporting Owner YES, IN_BETA_TESTING, Friends no. Never asc.py ship, never
Friends, review, main, Netlify or a public link. Record timestamps, command
results and read-backs in that packet and ACTIVE_WORK, push the branch, and
tell me to install 986 from TestFlight.
```
