# Widgets and Match first · September 25, 2026

Branch: `codex/between-round-widgets-2026-09-25`.

Goal: Merge and deploy the approved between-round widgets and Match first Live
Activity. Owner authorization: “merge and deploy.”

Source: `cbcc55db` (between-round widgets) and `d468ed40` (Match first), based on
`70d68bcb`. Remote `main` was fast-forwarded to `d468ed40` with an atomic,
non-force push that also published the owned branch. No other workspace or
in-progress branch was changed.

## Release evidence

- Native candidate: **1.0.0 (1025)**, exact source
  `d468ed408f0cc280568ece91ccc30f0bf9015d47`.
- Archive and export succeeded using the existing signing vault. App and widget
  signatures verified, both build 1025, distribution profiles, shared App Group,
  production APNs on the app, and background intent metadata present.
- IPA: `apps/ios/build/archive/run-1025-d468ed40.cTZiE5/export/Cup Season.ipa`,
  **21,261,156 bytes**, SHA-256
  `6bc52351d749fef3e7594409a4057fc1f838104ff6d209b7b6c1306a1d4c4d22`.
- Apple validation passed **17:01:42 UTC**; upload succeeded once at
  **17:03:18 UTC**, delivery `260065cd-67a7-4a5a-af93-a35ea77b09fa`.
- Native read-back: **VALID**, **Owner YES**,
  **IN_BETA_TESTING**, **Friends no**. What to Test saved (200) and verified;
  Owner add succeeded (204). Build 1025 is available to install.
- [Structured deployment evidence](widgets-match-first-deployment-evidence.json).
- Netlify serves `d468ed4` in both HTML and the service worker, HTTP 200, no raw
  version placeholder. This release changes native product code only. A later
  documentation-only commit advances the web stamp without changing product code.
- [GitHub CI](https://github.com/Fischbeck3/cup-season/actions/runs/36164234982)
  passed Client invariants and Migration hygiene. Release preflight passed with
  zero failures and zero warnings. Prior native evidence: 1,292 unit tests,
  2 Match first UI tests, and the earlier between-round widget UI checks.

## Handoff

What changed: Race, Next Tee, Record and Rivalry widgets; authenticated tee
replies; prominent match state; own-score Previous / − / + / Next controls;
durable background saves; owner-bound online/offline scorecard review routing.

Files changed: Source inventory and checks are in
[between-round handoff](between-round-widgets-handoff.md) and
[Match first handoff](match-first-live-activity.md). This release follow-up adds
deployment evidence and updates those handoff statuses.

Database deploy owed: None. No migration in this release.

Edge deploy owed: None. No Edge function change in this release.

Client deploy owed: None within this release. Native build 1025 is available
in Owner TestFlight; Netlify has published the merged source.

Open questions / risks: Simulator captures are not physical-device proof. Check
system-hosted Island and Lock Screen actions, Face ID/passcode, suspended/cold
app execution, offline sync, and account-switch privacy on the installed build.
Installation on the owner's phone is not established by TestFlight availability.

Recommended next step: Install **1025** through Owner TestFlight and exercise
hole 3 → Previous → hole 2 → score 5 → Next → hole 3. Test notes are included
with the build. Public App Store submission and external distribution are not
part of this internal release.

Local logs: `/private/tmp/cs-match-release-preflight.log`,
`cs-match-release-archive.log`, `cs-match-apple-validate.log`,
`cs-match-apple-upload.log`, `cs-match-owner-distribution.log`.
