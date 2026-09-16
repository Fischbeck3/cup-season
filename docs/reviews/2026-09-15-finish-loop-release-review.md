# Finish-loop release review — changes required

Reviewed Claude branch `claude/phone-fixes-2026-09-15` at `2a85cf0`, whose exported build 928 came from `e45ffda`. Codex read the current tree without modifying it. This review does not certify the entire PR; it focuses on F10/F12, the prepared migration and release instructions. No production writes, archive, upload or tester changes performed.

## Findings to close before release

### R1 · Web finish receipt and photo doors are miswired — high

`index.html:14584–14608` opens `openRoundReceipt(m.id, {})` directly. That function (`:20933`) returns immediately if `roundCache[id]` is absent. `csMyRoundsOn` only obtains id/course/date and does not seed that cache; a newly posted or manually entered course can therefore leave the promised receipt inaccessible. Use the existing asynchronous fetch-by-ID receipt route, carrying an explicit add-photo intent where appropriate.

The photo handler then clicks **`phPhotoBtn`**, which belongs to the profile editor (`openProfileSheet`); the receipt control is **`rcptPhotoBtn`**. Even fixing the selector would leave an arbitrary 250ms race and browser file-picker user-activation concerns. Give the receipt an explicit, visible attach-photo action, or use the existing supported photo-intent path; do not synthesize a timed click on an unrelated control. Prove both buttons with a cold receipt cache, delayed fetch and failed fetch, then confirm the uploaded photo belongs to the intended round.

### R2 · Round cache crosses accounts and preserves stale suppression — high

`CS_MY_ROUNDS` at `index.html:18005` keys by date only. `CS_PLAYED_PLANS` at `:17918` is a monotonic set. Inspection found no reset sites for either. Direct execution of the actual `csMyRoundsOn` source with a mocked read reproduced: account one fetched a round; account two requested the same date and received account one's cached rows without a new query (query count remained one).

Scope both caches to the authenticated identity/session, invalidate after finish/delete/correction, and reject late responses after account/context changes. Recompute completed-plan membership instead of only adding to it. Failed reads are not authoritative empty results. Verify same-day account switches, sign-out/sign-in, stale requests, a just-posted round inside the 60-second cache window, and removal/voiding of a previously matched round. No cross-account result or permanently hidden booking should survive.

### R3 · Save status still matches names instead of identities — high

Native `LiveRecapSheet.status` calls `RoundReconcile.status` with names. Web `csSaveStatus` also compares names and returns posted before checking skipped. Executing the web function with another golfer named Alex posted and the viewer named Alex skipped returned **Round posted**. Native uses the same precedence. Native `findMine` now prefers the server's round ID, but only after passing the name-derived `status.hasRound` guard. Web recap does not yet use the new profile/round IDs at all.

Determine the viewer's result by profile ID and authoritative returned round ID. Include profile identity in skipped outcomes where required. Under older payloads, preserve uncertainty and verify against authoritative evidence; a shared display name or someone else's posted card is insufficient. Add duplicate-name, renamed-profile, missing-identity, skipped-viewer and multi-player tests on both clients. The status cannot be more confident than the receipt identity.

### R4 · The booking invariant is weaker than the approved shared-round behavior — high

`20261105090000_the_round_remembers_its_plan.sql:40` makes `(scheduled_round_id, starter_profile_id)` unique only while live. It intentionally allows different golfers to create separate live rounds for the same booking. F10 calls for eligible participants joining the same linked round and explicitly tests concurrent starters. A duplicate retry also raises a unique violation rather than returning the existing authorized round. Finish state removes the partial-index protection, so historical/retry behavior needs deliberate handling too.

Implement authoritative start-or-join semantics for the agreed booking/group, with existing-round identity returned and permission-checked. If a booking can legitimately contain multiple groups, define that discriminator explicitly before choosing an index; do not silently substitute per-starter groups. Validate booking access and eligible participation before inserting: the current function attaches a supplied foreign key first and only then attempts to clear unauthorized linkage. Audit cancelled plans, declined/pending seats, full groups and concurrent calls. Do not count a function compiling and an index existing as proof of the end-to-end authorization behavior.

The authorization-patch anchor `returning id into v_lr;` is not asserted before replacement, despite the report saying every anchor is asserted. Add exact occurrence/postcondition checks or use a fully specified new function, then verify real refusals and legacy callers in isolation. Do not edit an applied migration if its deployment status changes.

### R5 · Course/day matching cannot disambiguate multiple bookings — medium

`RoundReconcile.booking` and `csBookingPlayed` each inspect one plan's course/day against own rounds. One played round and two bookings at that course on the same day causes both plans to be classified as played. This is distinct from the tested case of two round candidates. Prefer the explicit booking link; for legacy matching, account for competing bookings and ask/retain the reminder when ambiguous. Include changed/cancelled bookings and voided rounds. The final product must not silently suppress an unplayed second booking.

### R6 · F10 and typed contract remain incomplete — scope and release readiness

No client sends `p_scheduled_round` to start a round, and `packages/db/contract.psv:346` still records the old nine-argument `start_live_round`. The migration changes the function signature, drops that overload and introduces a defaulted tenth parameter. Regenerate the typed contract from the validated candidate database, verify the precise diff and old-client default call, then re-take after deployment. Complete both client doors and the data handoff before describing booking linkage as complete.

The claimed naming blocker is inapplicable: the historical “Tee it up” rejection at decision-log ~5029 concerns **closing a season roster**, not starting a booked playing round. The owner explicitly approved this booked-round action in F10. Record that contextual distinction and proceed; no further owner naming permission is needed. “View round,” server-side plan suppression and final receipt birdie/eagle tally are still owed; they were not cancelled by this release handoff.

### R7 · The upload instructions identify the wrong artifact — operational

The exported IPA exists at `apps/ios/build/archive/run-928-e45ffda.UnzX5H/export/Cup Season.ipa`. The archive helper always computes `BUILD=$(git rev-list --count HEAD)` and creates a new archive. At reviewed HEAD `2a85cf0`, that count is **929**. Thus `tools/ios-archive.sh --upload` would rebuild 929, not re-archive 928 as claimed. Later commits will change it again.

After correcting the candidate, use a clean, identified source commit and its actual new build number; validate the resulting IPA and report its source. If intentionally shipping a preserved artifact, use the existing upload-only procedure on that exact verified IPA, not the archive helper, and state that it omits later fixes. Do not ship 928 as the corrected candidate. Verify processing and actual availability to Owner separately; Friends remains untouched.

## Verification performed

- Read-only source review of current migration, native recap/reconciliation, Home suppression, web handlers and archive script.
- Executed extracted web `csSaveStatus` and `csMyRoundsOn` functions in a Node VM with synthetic data: duplicate-name false success and cross-account date cache both reproduced.
- Confirmed receipt's missing-cache early return and the mismatched photo control from source; no browser or physical-device reproduction claimed.
- Confirmed current commit count 929 and presence of the exported 928 IPA. No signature/Apple-state verification claimed.
- SQL was reviewed statically; this review did not execute its migration or full application tests. Claude's prior green suites do not cover the demonstrated cases above.

## Required next handoff

Fix R1–R7 on Claude's owned branch; finish the already-authorized F10 journey, View round copy and final receipt tally. Validate identity, cache lifetime, start/join concurrency, old-client skew and the complete booking → live → finish → receipt/photo → Home flow on both clients. Supply a corrected dry-run, exact candidate/build identity, test evidence and separate database/web/TestFlight states. Keep an undefined heating-up meter deferred; the factual birdie/eagle feedback remains the approved work.

Claude reports automatic permission review rejected its database push and upload. This review did not receive those original rejection details, so it cannot call them a transient hiccup or certify the commands safe to retry. Do not use a different agent or shell route merely to circumvent the rejection. Resolve the concrete findings and use the authorized deployment process with accurate evidence.
