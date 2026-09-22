# Expansion gates and stop conditions — proposed

These are proposals for the owner to ratify. Sizes are hypotheses. A gate is
passed on evidence in the scorecard and the session log, never on a feeling
after a good round.

## Always, before any widening

- No unresolved critical security or score-integrity defect (the authorization harness `tests/pilot/authz-flow.py` is green on the candidate; `integrity` reads all zeros or every non-zero is explained).
- No known duplicate start, duplicate post, lost acknowledged score, or trap screen open in the tracker.
- The candidate on TestFlight is the commit the evidence was gathered on.

## A → B · Owner testing to Friends

- Every row of [`owner-checks.md`](owner-checks.md) is PASS on two phones, on the build Friends would receive.
- The migrations the candidate depends on are applied (as of 2026-09-15 night: `20261105090000`–`20261107090000` applied, production at 246; the two revokes `20261109090000` and `20261110090000` are the next push — D372).

## B → C · Friends to independent groups

- Galen/Jade plus one regular group complete **two** rounds each through the booked-round path with **no assisted session** on the second.
- Every finish posted every registered seat; every account-less guest either claimed or was told how.
- Post-round forms: confidence that the score saved averages 4 of 5 or better, and nobody reports work moved to a chat that the app was meant to do.
- Zero integrity non-zeros for the whole stage.

## C → D · Independent groups to the competition pilot

- At least **three** independent groups each complete a second game unassisted, within three weeks of the first.
- Support sessions per completed round are falling week over week.
- At least one organizer says, unprompted, what they would do next time — and it is in the app.

## D → E · Competition pilot to the paid stage — amended 2026-09-21 (D371)

**The public door opens by owner ruling on 2026-10-01**: App Store submission
that day, open outreach the same day, a TestFlight public link for strangers
until Apple approves. Stages A–D remain the *measurement* frame and the stop
conditions below remain in force — they are what pauses outreach. The rows
that follow no longer gate the public door; they gate the **paid** offer
(D183 keeps everything free until 1,000 onboarded golfers). A Ryder or a Major
counts as a competition lifecycle (ruling 11). Ratification of this file as
amended is due at the 2026-09-29 weekly review (ruling 12).

- At least **one full competition lifecycle** verified end to end on production data: locked, played, closed, settled, receipts opened — by a group the founder does not play in.
- At least one organizer starts a second competition.
- The paid offer has been put to at least five organizers with the interview guide; the answers are recorded, whatever they are.

## Stop conditions — stop widening, fix, re-verify

- Any duplicate live round for one booking, any double-posted card, any acknowledged score that did not land.
- Any golfer sees another golfer's data they should not (harness or report).
- A trap screen reported by two testers.
- A week where assisted sessions exceed unassisted completions in a cohort that is meant to be unassisted.
  *Measured* by the report's `assistance_weekly` section (W6 correction 1): per local week and cohort, a completion is one finished real game (however many cards it posted); it is assisted when a logged session of that cohort is linked to it by group or golfer and overlaps it in time, UNKNOWN when the session evidence cannot settle it, and unassisted otherwise. An UNKNOWN week is not a pass — complete the session log and re-run. This states how the proposed condition is counted; it does not ratify it.
- Any account-less guest's claim card exposing more than name, gross, course and date.

## Explicitly not gates

- Daily active use. Golf is weekly at best.
- Clash views. Exposure is not value.
- Percentages from samples under about ten. Report the count.
