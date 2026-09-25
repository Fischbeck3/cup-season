# Between-round widgets · September 25, 2026

Owner approved the between-round mockups with “Build em, looks good.” This is
the native implementation of The Race, Next Tee, The Record, and The Rivalry.
The separate live-round score-entry exploration is outside this change.

## What appears

| Widget | Source | Tap destination |
|---|---|---|
| The Race | Validated `season_book`, current preferred season; golfers or squads as the season specifies | Season standings |
| Next Tee | `my_schedule` and `round_detail`; next future plan owned by or tagging the golfer | Scheduled round |
| The Record | Latest eligible round-linked achievement from `my_achievements`, otherwise the last round; `round_card` and `round_scorecard` | Round receipt |
| The Rivalry | Deepest weekly-clash history from `my_rivalries`, with the latest `rivalry_weeks` receipt | Weekly rivalry sheet |

All four have small and medium Home Screen layouts. Race and Next Tee also
have monochrome rectangular Lock Screen accessories. The original
`CSSeasonWidget` identifier is retained for existing installations.

Race copies server points and ranks, including ties. It never computes season
scores. Rivalry labels its numbers **Weekly clashes · All time** and keeps Ryder
wins separate. A record without verified nine totals shows its gross alone;
a nine-hole round says **9 holes**, never Out/In. Gold marks an actual awarded
milestone. The widget fonts are bundled in the extension, not assumed to be
available because the app registered them.

Accessibility text sizes use reduced layouts that keep the main facts and the
snapshot timestamp within the fixed widget height. Medium Next Tee retains
44-point reply controls; small Next Tee opens the plan at those sizes. Long
names may truncate visually and retain their full accessibility text.

## Refresh, privacy, and replies

IOS-034's app-authored snapshot remains the boundary. A successful Home read
starts an asynchronous refresh using existing read contracts. Each widget has
its own timestamp; a failed read retains the previous value and previous time.
No credential, money value, private photo, or network client enters the widget
extension. This is cached data, not server-pushed live standings.

The timeline includes both the 24-hour stale boundary and the tee-time expiry,
so a delayed reload does not leave an expired RSVP on screen. Stale Home Screen
facts say Open to refresh; stale Lock Screen accessories stop showing facts.
Sign-out removes every snapshot and requests timeline reloads. Owner identity
and a session epoch reject late writes, including an A → B → A account switch.
Widget read links carry the owner and are ignored for another signed-in golfer.

Next Tee uses an App Intent in the **app process**, retaining authentication in
the app. The iOS 17 compatibility path is `ForegroundContinuableIntent` on the
app target only. The extension stub fails explicitly if unexpectedly invoked.
The action verifies the current account, re-reads eligibility and the date, then
calls the existing `set_round_rsvp` RPC. It displays confirmation only after
acknowledgement. Failure preserves the prior response and offers the plan.
Changing a confirmed answer is supported.

Replies require device authentication. Home Screen interaction can run without
bringing the app forward; Lock Screen accessories are glance-and-open surfaces.
This does not promise score entry or RSVP on a locked, unauthenticated phone.
Apple owns notification chrome and Dynamic Island eligibility. No synthetic
milestone or tee-change notifications are emitted by these widgets.

## Review and release

`-cs_dev_widgets` opens a DEBUG gallery of the production SwiftUI widget views
with in-memory sample records. `-cs_widget_kind` takes the widget identifier;
`-cs_widget_state` accepts full, empty, stale, long, confirmed, error, or nine.
The gallery bypasses auth and never publishes its fixtures into the App Group.
Its reply controls are disabled, so a screenshot cannot RSVP to a real plan.

Verification results are recorded in the [handoff](between-round-widgets-handoff.md). The
remaining device check is system-hosted Home Screen RSVP with the app suspended
and terminated, plus Lock Screen privacy and authentication behavior. Gallery
captures prove layout; they do not substitute for that OS lifecycle check.

No migration or Edge Function deployment is required. Distribution requires a
new native build containing both the app and extension. Existing provisioning
must retain `group.app.cupseason.shared` on both targets.
