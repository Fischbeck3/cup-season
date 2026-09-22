# Weekly review — thirty minutes, same day every week

1. Fill this week's row of the acquisition log first (`acquisition-log.md`
   says where each count comes from; the store count is App Analytics'
   first-time downloads and nothing else). Then run the report, read-only,
   and keep the output with the date:
   ```
   node tools/pilot-scorecard.mjs --as-of $(date +%F) --store-live false > docs/pilot/scorecard-$(date +%F).md
   ```
   (`--store-live true` once Apple approves the listing.) The acquisition
   section keeps first-time App Store downloads, TestFlight installs and web
   sign-ups apart; a — is missing, not zero.
2. Enter the week's sessions and support requests before reading the numbers (see [`session-log.md`](session-log.md)). Assisted activity is not evidence of unassisted completion.
3. Read the **integrity** section first. Any non-zero in `bookings_with_two_live_rounds`, `double_posted_live_cards` or `live_over_24h_not_abandoned` is a stop condition until explained.
4. Read **live_games** and **posting**: how many games started, finished, abandoned; how many finishes posted every seat; how many account-less guests claimed. Write one sentence per anomaly.
5. Read the **golfer funnel** by cohort: where did the week's stall happen — invited but never joined, joined but never posted, posted once and quiet? Golf is intermittent: "quiet three weeks" is a question to ask, not a churned user.
6. Read **repeat_groups**: did any group play a second game this week? That is the number the expansion gates turn on.
7. Read **clash** and **receipt** together and do not conflate them: shown is not valued.
8. Read the week's `pilot_feedback` rows and the post-round forms. Sort into: comprehension · confidence the score saved · work still happening elsewhere · desire to play again · the paid offer.
9. Check the [gates and stop conditions](gates-and-stop-conditions.md). Write the verdict for the week in one line: **hold · widen · stop**, with the reason.
10. File follow-ups in `spec/inbox.md`. File nothing with a real name in it.
