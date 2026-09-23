# Claude · finish the Owner phone beta

Paste the following into a **local Claude session on the Mac**. This handoff
does not itself grant the pending production or Apple approvals.

```text
Finish the remaining steps to get Cup Season onto my phone through the internal Owner TestFlight group. Use the existing signed candidate, verify each deployment separately, and give me a short phone checklist. Start with the checks below and continue through the authorized work without asking for another general “go.”

1. Establish ownership and the exact candidate.

Read AGENTS.md, CLAUDE.md, docs/doc-map.md, and these packets:
- docs/planning/2026-09-22-owner-beta.md
- docs/planning/2026-09-22-course-cache-deploy.md
- docs/planning/2026-09-22-release-checklist.md
- docs/pilot/recipient-journeys.md

Fetch origin. Use your own clean worktree and claude/owner-beta-release branch from origin/codex/october-visual-ui; use a distinct name if already owned. Do not change Codex’s worktree or the older dirty visual checkout at /Users/fischbeck3/cup-season. If this is a remote sandbox, say so and hand the Mac-only steps to a local session; do not substitute lint for native or signing evidence.

The signed candidate is 1.0.0 (986), source commit 37f959e. Claude’s W6 correction tip 8f632ed is already included through merge 9d9ef46. Subsequent commits through dbd0ec6 are documentation-only. Classify any newer changes before proceeding; do not silently replace this candidate.

Exact IPA on the Mac:
/private/tmp/cup-season-visual-ui/apps/ios/build/archive/run-986-37f959e.QoXfzc/export/Cup Season.ipa

SHA-256:
a9de87cfd14590b7cd1d838e7baf63c7b9e5bbe6fb9e160f0edbbfbdafcaf87d

Check the checksum, signatures, app/widget versions and production APNs entitlement. Do not run ios-archive.sh --upload: it would rebuild from today’s commit count. Upload this exact package only after approval. If it is missing or different, prepare and verify a replacement, state its new identity, and obtain approval for that replacement.

2. Respect the evidence already earned.

All 1,493 native unit tests passed. The full final run was 1,508 pass / 1 fail: native share cancellation remained visible after its close tap. All 129 small-phone checks passed, including cancellation; two later standard-phone cancellation runs passed, while another retry failed to open the DEBUG fixture. Keep this limitation explicit and check cancellation on the phone. Do not call the full run green.

Preflight passed. The fresh PostgreSQL 17.11 chain applied 254 migrations with zero skips; W6’s 17 database tests passed with zero skips. The other Node tests passed 57, making 74 total. Do not repeat the W6 correction pass. Rerun checks when source changes, failures or missing evidence justify it.

The remaining Golfers/You/settings audit, store imagery and minor diagnostic-flag cleanup are follow-up work. Freeze the Owner candidate unless a reproducible beta blocker requires a narrow fix and a new verified build.

3. Prepare the exact release actions, then resolve their approvals once.

Read App Store Connect’s latest builds and both groups. Check whether 986 already exists before uploading. Read the live migration ledger, courses function version and secret NAMES only. The last verified state was Owner 934, Friends 795, migrations through 20261115090000, courses version 18, and no APNS_SANDBOX.

In a reviewed checkout containing the migrations, confirm the linked project and run the deployment dry-run. Expected pending SQL:
- 20261116090000_course_cache_atomic.sql
- 20261117090000_shared_card_consent.sql

If the pending set differs, reconcile it before any write. Never deploy from the older dirty checkout or run local mutation probes on production.

Production and Apple approvals remain pending. Codex’s automatic review rejected Apple validation BEFORE execution because it transmits the signed IPA; nothing was sent. Changing agent or tool is not a workaround. If an explicit owner approval for these exact actions is already present, use it. Otherwise, after the read-only checks, ask ONE concise, batched question approving:
A. Both named migrations, followed by deploying only courses.
B. Sending exact build 986 to Apple for validation, then upload and internal Owner distribution if validation succeeds.
Explain that AGENTS.md §15 reserves production changes and the launch prompt §C reserves Apple upload for owner approval. Continue independent preparation while awaiting the answer. Do not treat this pasted handoff as approval.

4. Execute only the approved release scope and read it back.

For A: apply the exact reviewed migrations, then deploy courses. Verify the remote ledger, grants/policies and function version using read-only checks. Report database and Edge results separately. Production Storage API/photo-consent proof remains distinct from local RLS tests.

For B: use existing keychain credentials and signing assets; never request or print secrets. Validate the exact IPA, upload it once, and wait for Apple’s VALID processing state with bounded polling. Reconcile an uncertain upload before retrying.

App ID: 6806251118
Owner group: c4a784fe-22c5-4a75-bd4b-ca864b63574a
Friends group: 9f8db84a-166c-4900-b196-ea2c5459e369

Set What to Test and add the build only to Owner. DO NOT run tools/asc.py ship: it targets Friends and submits external Beta App Review. Read back Owner’s build relationship and the build’s internal availability. Confirm the candidate was not added to Friends. No main merge, Netlify production deployment, public link, external review or App Store submission is included in this handoff. Read the public web stamp and flag any client skew that prevents end-to-end sharing; do not silently publish the web client to cure it.

5. Get actual phone evidence and close the loop.

Once Owner availability is confirmed, tell me to install 1.0.0 (986) from TestFlight and confirm the number shown on the phone. Prioritize:
- Open Share, cancel it, reopen it; check photo on/off and the received card/link.
- Sign in and visit Home, Golfers, Play, Compete, You and settings.
- Find a course/tees; check scoring, background/reopen, recovery and a posted receipt’s points explanation.
- Run the real invitation/claim and Storage consent checks when the second phone is available. A real release-build claim is also needed to prove attribution; DEBUG fixtures cannot prove it.

Do not invent installation, a real round or device PASS results. The two-phone/Friends gates remain open until their actual evidence exists; they do not prevent obtaining this internal Owner beta for testing.

Update the beta packet and ACTIVE_WORK with exact commands, timestamps, commit/build, validation result, ledger/function readback, Owner availability and any unresolved failure. Commit and push your owned branch. End with the repository handoff fields and the one next action I should take. Success means the approved build is actually available to Owner, not merely archived or uploaded. If approval or a real device is the only remaining dependency, state that precisely.
```
