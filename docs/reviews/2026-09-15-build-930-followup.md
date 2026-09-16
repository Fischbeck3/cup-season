# Build 930 follow-up and deployment authorization

Reviewed `c3c1f76` / code `d5ea192`, Claude's branch, read-only. Prior R1–R7 changes are substantial, but the source still has the following release-blocking integration defects. No database push or upload performed by Codex.

## Owner authorization — not an owner-only task

The owner explicitly says: **“I am away from computer and cannot push. I am okay with Claude pushing.”** In this context authorization covers the reviewed application migration and corrected TestFlight candidate uploaded and made available to the **internal Owner group only**. Friends remains untouched. The user should not be handed local shell commands as the default delivery path or asked to authorize these same actions again.

Complete and verify the corrections first, then use the supported deployment tools. An actual tool/automatic-review refusal remains a separate constraint; user approval does not override it. Report the exact rejected action and stated reason. Do not predeclare a refusal solely from the earlier rejected candidate, call it transient without evidence, or route around a refusal using a different agent/tool. No web-main promotion, Edge deployment, unrelated migration or account-role change is added by this authorization.

## S1 — Web starts twice after a successful plan-aware start

`index.html:14314` invokes `start_live_round_from_plan`. Success stores its response in `window.__csPlanStart`. That global has exactly one occurrence in the file: it is never consumed. Execution then unconditionally invokes `start_live_round` at ~14319 and assigns the ordinary response to `state.live.lr`.

Thus the booking-aware success does not control the client round. It can create a second, unlinked round and duplicate start side effects; the per-booking index cannot prevent a round without a booking link. Make the paths mutually exclusive and consume the returned plan result. A join result must hydrate the existing round rather than initialize it as a new one. Add an integration regression driving the real tee-off handler with mocked RPC responses: successful plan start/join makes zero ordinary-start calls; missing-function fallback is deliberate; permission/network failures never silently start an unrelated round. Assert final client ID, authoritative roster/score state and absence of duplicate invitations/start announcements.

## S2 — Native join consumes a start payload as if it created the round

The migration's existing-round result contains only `live_round_id`, `join_code`, `joined:true`. `LiveStartOutcome` decodes absent `players` into an empty seats list. `LiveRoundStore.teeOff` builds fresh local players, blank scores, game/settings and `mine = true` before the call, then on `joined` only toasts. It continues to overwrite `startedAt`, set `pmap` from the empty seats, persist the fresh state, join sync and announce a start.

Route joined outcomes through authoritative existing-round loading before exposing the scoring interface. Restore course/tees, game, actual roster/seat IDs, scores, original start time, host and viewer permissions. A sync subscription is not a substitute for correct roster/host identity. Do not announce a second start. The server must also ensure a caller receiving `joined:true` is eligible for the existing round's participant model; a pending tagged caller is not automatically a seated participant. Prove a second phone joining after the first has entered scores, a changed local setup, an unseated tagged caller and concurrent starters with the real start function rather than only a signature-shaped stub.

## S3 — Course ID is not proof that par is known

`round_tally` considers a non-null API course ID plus a pars array sufficient to report `known:true`. Native `applyTee` sets `parsCourse` and installs standard template pars before the actual card read succeeds; `momentParIsKnown` treats `parsCourse != nil` as sufficient. The course snapshot does not carry explicit verified-par provenance. Consequently a course with missing/failed hole data can generate birdie/eagle feedback and receipt counts against template pars.

Persist actual par provenance, or derive it from a trustworthy existing source. The course identity and a populated array alone are insufficient. Unknown/estimated pars must produce no confident event/tally; explicit user-confirmed pars can qualify. Keep client and SQL definitions aligned. Verify a known course with failed card fetch and retained template pars, manual confirmed pars, incomplete arrays and historical snapshots without provenance. Preserve factual gross scoring; do not silently invent net or estimated highlights.

## Artifact and next delivery

Current branch HEAD `c3c1f76` has commit count **931**. Exported 930 is from `d5ea192`. Corrections need a newly identified tested commit and build; do not ship the old IPA as corrected. If using an existing verified IPA, upload-only means that exact file; `tools/ios-archive.sh --upload` always creates a fresh archive for its current checkout. Check signing/artifact identity, Apple processing and Owner availability separately.

After S1–S3 are closed: verify the full booked round → live score → finish → personal receipt/photo → Home path, the exact migration dry-run and contract, and old-client compatibility. Then execute the authorized migration and native release through the supported approval path, internal Owner only. Return actual results instead of owner-executed command instructions. If blocked, name the unresolved tool restriction precisely; work that does not depend on it should continue.
