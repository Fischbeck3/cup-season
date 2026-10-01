# Combined candidate · physical-device release checks

Item 5 of the September 30 launch sprint. **Every row below is NOT RUN.**
Simulator fixtures prove layout and code paths; they do not satisfy these gates.

Run after the release owner installs the same unified candidate on both phones.
The candidate must contain Build 2, D400, Q2 and the recipient follow-up. Copy the
exact source SHA, TestFlight build and live web stamp from the release record;
do not use widget-only build 2024 as proof of the later repairs. Database,
web and phone deployment are independent. Do not enable Friends/public
access based on this sheet before D372's other release gates pass.

| Candidate identity | Value |
| --- | --- |
| Native source SHA | Awaiting release |
| TestFlight build, phone T1 / T2 | Awaiting release |
| Web stamp | Awaiting release |
| Q2 migration applied/read back | Awaiting release |
| T1 / T2 model and iOS version | Owner fills |
| Date, tester labels, evidence location | Owner fills; private evidence only |

Use two dedicated test golfers, T1 and T2, a test season both belong to, and a
real course/tee from the picker. Keep screenshots containing actual account
information outside the public repository. The owner performs the interactions;
this checklist does not authorize an agent to post on real accounts or send links.

## Recipient links · 15 minutes

| ID | Action | Required result | State |
| --- | --- | --- | --- |
| L1 | On T2 Safari, signed out, open T1's buddy card. Tap Sign in, reload once, finish email/code and card creation if needed. | Same buddy intent survives. The named confirmation appears. No buddy request until T2 says yes. One request after yes. | NOT RUN |
| L2 | Open a future plan link signed out. Tap Sign in to take the seat, finish auth, dismiss the question. Reopen and explicitly accept. | Auth keeps the intended plan. Dismiss sends nothing. Acceptance produces one seat and the described buddy outcome, never a duplicate. | NOT RUN |
| L3 | As T2, already agreed to the test season, open its invitation in Safari and then native. | Web opens that season; native's Open the season does likewise. No new join welcome, duplicate seat, or repeated pending invitation on relaunch. | NOT RUN |
| L4 | Interrupt connectivity while reading invitation terms, then restore it and retry. | Recoverable failure, enabled retry, same invitation; no join before terms and the golfer's yes. | NOT RUN |

L1/L2 do not replace the separate claim/photo-consent journeys in
[recipient-journeys](../../pilot/recipient-journeys.md).

## Two-phone recovery · 35–45 minutes

Run [owner-checks](../../pilot/owner-checks.md) A1–A11, R1–R7 and G1–G2.
The rows below make the key failure injections and evidence explicit.

| ID | Action | Required result and evidence | State |
| --- | --- | --- | --- |
| P1 | T1 books today and tags T2; T2 says IN. T1 tees off; T2 opens the same booking. | Same live-round identity on both, same roster, one round. Record private screenshots before scoring. A1–A3. | NOT RUN |
| P2 | Each golfer scores two holes; correct one score on T1. | T2 sees the correction and both agree. Save exact scores, not “sync looked good.” A4. | NOT RUN |
| P3 | Kill T2 mid-round and reopen. Put T1 in airplane mode, enter three holes, kill/reopen, then restore connectivity. | Active round and queued scores survive; no new local card, no lost or doubled score, one server round after replay. A5–A6. | NOT RUN |
| P4 | Finish with no signal; restore signal. Repeat on a new test round with a kill during finish. Tap Finish again from each phone. | One finished live round, one posted card for each golfer, no duplicate posts. Each recap opens its own receipt; Home retires the booking. A8–A10, R3–R4. | NOT RUN |
| P5 | Start without signal; retry. Double-tap tee-off on another test round. Tagged but unseated golfer attempts to join after start. | Visible, recoverable failure; no half-start. One round on double tap. No silent seat for the unseated golfer. R1–R2, R7. | NOT RUN |
| P6 | Check known-par birdie/tally, old receipt, guest claim and flow exits. | A7/A11, G1/G2 and R5/R6 all recorded individually in owner-checks. | NOT RUN |

After P4, the release owner reads back the finished round and its posted-card
identities using the existing read-only verification path. An on-screen toast
alone does not prove exactly-once posting. Record any failure's first observed
state, timestamps, build identity and read-back before retrying; engineering
then makes one narrow fix and repeats that failing case on the replacement build.

## System-hosted widgets · 30–45 minutes plus observation

Install widgets from the actual extension, not the DEBUG gallery. Test both
printings and the Lock Screen accessories where they exist.

| ID | Action | Required result and evidence | State |
| --- | --- | --- | --- |
| W1 | Last open an unseated/zero-point season while another played season has points. Add Race. | Race selects a season actually played, not Start a season. Compare the displayed server rank/points to the app. | NOT RUN |
| W2 | Compare What's On to Home, then leave the app closed and observe its next 20-minute tile. | Same served words/routes; rotation uses the saved deck. Each tapped item opens its intended object. No pot/currency line. Rotation is not evidence of a new server read. | NOT RUN |
| W3 | Tap Race, Next Tee, Record, Rivalry and What's On routes after suspension and termination. | Correct season/plan/receipt/rivalry/Home destination; no prior unrelated navigation left above it. | NOT RUN |
| W4 | RSVP on Next Tee with the app suspended and terminated; retry with no signal. Test a locked phone. | Acknowledged answer only, prior answer retained on failure, plan reachable; authentication required. No server mutation from a failed/unauthenticated action. | NOT RUN |
| W5 | Sign out, inspect all Home/Lock Screen widgets, then sign in as the other test golfer. Exercise A → B → A with a read in flight. | No old golfer facts or routes remain usable. Late writes do not restore the old snapshot; another owner's widget link is rejected. | NOT RUN |
| W6 | With the app backgrounded, exercise the documented debugger task launch and record snapshot times before/after. | Registered task runs the current owner's Home read, publishes successful fresh slices, ends cleanly and schedules the next request. This proves handler execution, not natural iOS cadence. | NOT RUN |
| W7 | Leave the app closed and record natural background updates with timestamps. | Record observed runs and failures separately. iOS decides cadence: no observed run is NOT OBSERVED, not a claimed refresh pass. Stale facts/routes obey their boundaries. | NOT RUN |

The debugger command and lifecycle contract are in
[between-round-widgets](../../ios/between-round-widgets.md). A simulated task
launch cannot make W7 PASS. A forced close may restrict future background work;
record that condition rather than promising a refresh interval.

## Result

| Gate | Disposition |
| --- | --- |
| Recipient physical journeys | NOT RUN |
| Owner-checks A/R/G rows | NOT RUN |
| System widget lifecycle/privacy | NOT RUN |
| Natural background cadence | NOT OBSERVED |
| Friends/public distribution | Not advanced by this work |

Current Mac inventory: one physical phone available and the second unavailable;
no phone interaction or account mutation performed by this session. Engineering
proof for item 3 is recorded in the sibling README. The release owner fills
identity fields and row results after installing the exact released candidate.
