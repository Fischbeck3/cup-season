# Weekly review — thirty minutes, same day every week

1. Fill last week's row(s) of the acquisition log first, and add an App
   Analytics reading if a checkpoint date has passed ([`acquisition-log.md`](acquisition-log.md)
   says where each count comes from; the store count is App Analytics'
   first-time downloads and nothing else). Then run the report, read-only,
   **dated the Sunday the week ended**, and keep the output under that date:
   ```
   node tools/pilot-scorecard.mjs --as-of 2026-10-04 --store-live false > docs/pilot/scorecard-2026-10-04.md
   ```
   (`--store-live true` once Apple approves the listing.) Every section counts
   only what had happened by the end of that Sunday in Phoenix; a column ending
   `_now` is today's state and says so. The acquisition section keeps
   first-time App Store downloads, TestFlight installs and the web first-event
   proxy apart; a — is missing, not zero; a checkpoint is judged only on a
   dated App Analytics reading.
2. Enter the week's sessions and support requests before running the report (see [`session-log.md`](session-log.md)) — with an end time, and the golfers or the league/booking/round id. A session without them makes the games it overlaps UNKNOWN. Assisted activity is not evidence of unassisted completion.
3. Read the **integrity** section first. Any non-zero in `bookings_with_two_live_rounds_now`, `double_posted_live_cards` or `live_over_24h_now` is a stop condition until explained.
4. Read **live_games** and **posting**: how many real games started, finished, abandoned; how many finishes posted every seat; how many account-less guests claimed. Write one sentence per anomaly.
5. Read the **golfer funnel** by cohort: where did the week's stall happen — invited but never joined, joined but never posted, posted once and quiet? Golf is intermittent: "quiet three weeks" is a question to ask, not a churned user.
6. Read **repeat_groups**: did any group play a second game this week? That is the number the expansion gates turn on.
7. Read **clash** and **receipt** together and do not conflate them: shown is not valued.
8. Read the week's `pilot_feedback` rows and the post-round forms. Sort into: comprehension · confidence the score saved · work still happening elsewhere · desire to play again · the paid offer.
9. Read **assistance_weekly**, the stop condition's own table, week by week and cohort by cohort. A STOP row is a stop. An UNKNOWN row is not a pass: complete the session log and re-run before deciding. Then read **activation_weekly** (events in the week) apart from **activation_cohort** (the signup funnel) — a week with more first rounds than new accounts is older accounts activating, not a bug.
10. Check the [gates and stop conditions](gates-and-stop-conditions.md). Write the verdict for the week in one line: **hold · widen · stop**, with the reason.
11. File follow-ups in `spec/inbox.md`. File nothing with a real name in it.
