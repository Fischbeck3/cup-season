# Golf around the app · notification and widget proposal

2026-09-12 · owner asked to explore Home/Lock Screen widgets and friend planning, starting and birdie notifications. This is a design proposal, not an activation or a change to the approved notification rules.

## The three jobs

| Surface | Proposed job | Freshness and destination |
|---|---|---|
| Home Screen widget | The next useful golf fact: next plan, current season, recent accepted round | Snapshot with update time; stale state opens to refresh. Not a promise of real-time hole updates. |
| Lock Screen accessory widget | Compact next-plan / season glance | New accessory-family design; never starts a live session merely because a plan exists. |
| Live Activity / Dynamic Island | Own round, or a round explicitly followed with permission | Current progress, last update, stale treatment; end on finish/scrap/access loss. Remote friend following is new work. |
| Push alert | A direct invitation/change, or an opted-in social moment | One meaningful interruption, one destination; no duplicate push for the same routine Live Activity update. |
| In-app Home | The durable place to catch up and resolve an action | Necessary even when OS permission is denied or Focus delays notifications. |

The inline concept lets the owner walk the existing after-golf idea and compare Plan made / Tee off / Birdie / Posted across Home Screen, Lock Screen and Alerts. Example Sam is fictional. A plan is not proof of a booked reservation; a tee time is not proof somebody started playing.

## Proposed defaults

- **Direct relevance first:** invitations, cancellation/time changes to your own plans and the already-approved actionable categories. Existing D104 permission timing, mute handling and actionable-only badge rules remain.
- **General friend planning stays in Home by default.** An invitation or a relevant opening is different from broadcasting every declaration. D248 explicitly moved tee-sheet declarations to feed-only. A broader booking push would need a specific amendment, not an expanded recipient list.
- **Friend starts and highlights are off by default.** A proposed selected-friends preference can enable them, subject to the golfer's sharing permission. Following a particular round enables its live progress only for that session.
- **One event, one interruption:** progress goes into an active followed Live Activity; don't also buzz for that same birdie. Respect mute, OS permission/Focus, user quiet hours and a shared social-alert cap. Exact cap and batching require a decision before implementation.
- **Accepted facts only:** start follows an actual live-round transition; birdie requires recorded strokes of par minus one using the real hole par. Front/back totals cannot establish birdies. No extra mandatory input during play; no season-point claim from a hole.
- **Corrections and delay:** derive event identity from the round/hole/recipient, handle score edits without replaying a celebration, suppress stale offline backfill as a live alert, and refresh the destination with corrected facts. Exact coalescing window remains a contract choice.
- **Privacy and lifecycle:** audience is never inferred from an RSVP. Both sharing and following matter. Revoke access, stop following, sign out, stale data, round end and deletion must clear or end the exposed surface. Lock Screen details can be hidden. No private money on these surfaces.

## Existing implementation observed

At `67e3ed8`, `CupSeasonWidgets.swift` registers `CSSeasonWidget` (systemSmall/systemMedium) and `CSRoundLiveActivity`. The season widget reads an App Group snapshot updated by Home, labels its age and has a stale policy. It is not a network-driven friend feed.

`LiveActivityHost.swift` starts an own-round activity with `pushType: nil`, updates from app state, uses a 45-minute stale date and explicitly ends activities. Remote friend ActivityKit delivery and Lock Screen accessory widget families are not provided by this implementation.

D104 specifies routed/actionable/mute-aware pushes. D248 contains vocabulary for `friend_round`, `tee_tomorrow`, `seat_open` and others, but also records a production APNs delivery gate. The current source has these kinds; their presence is not proof their producers or production delivery are working. This pass did not inspect production delivery logs. Friend-start and birdie fanout need a new event/audience contract and a decision entry.

Apple distinguishes WidgetKit timelines from ActivityKit updates. It also recommends avoiding repeated alerts and duplicate pushes alongside Live Activity updates: [Live Activities guidance](https://developer.apple.com/design/human-interface-guidelines/live-activities), [ActivityKit update model](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).

## Build ownership and gates

1. **Codex:** audit existing widget / own-round Live Activity rendering, accessibility, stale/end paths and deep links. Prototype notification preferences and one followed-round view using existing tokens. Preserve the draft-recovery priority already in the active queue.
2. **Claude:** propose event facts, audience permission, follow lifecycle, idempotency, correction/backfill rules and delivery deduplication. Audit existing producers before adding kinds. Named bounded packet, own branch; not automatically started by this note.
3. **Together:** prove one production APNs delivery under D248's recorded gate, then actual device routes/actions and token environment handling. User's request authorizes this design exploration; it does not authorize sending real notifications or deploying new producers.
4. **First release slice:** own-round Activity and next-round/season glance quality, plus proven direct plan notifications. Followed-friend Activity comes next; social start/highlight pushes after its evidence and audience rules work. No release claim until each relevant layer is verified.

Acceptance must cover denied permission, muted golfer, revoked sharing, repeated deliveries, edited hole score, late offline upload, stale/ended round, cold-start navigation, signed-out widget clearing and return from background. A success in an HTML concept is not an APNs test.

## Handoff

Branch: `codex/vision-next-2026-09-12`.
Goal: show the journey inline and preserve the proposed notification structure.
What changed: conversation-only interactive concept; this planning note and queue pointer.
Files changed: this document; `docs/planning/ACTIVE_WORK.md`. Inline response source remains under ignored `work/inline-journey/`.
Verification run: source inspection; Apple primary documentation; local browser interaction/layout checks and sandbox rendering. No production APNs or native test executed.
Database deploy owed: none.
Edge deploy owed: none.
Client deploy owed: none.
Open questions / risks: selected-friend sharing/follow model; social cap; live event availability and correction timing; current APNs production proof not verified.
Recommended next step: finish draft recovery; run widget/push foundation audit alongside Claude's bounded event-contract proposal when assigned.
