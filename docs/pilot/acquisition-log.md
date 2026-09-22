# The acquisition log — owner-run, weekly, counts only

`acquisition-log.csv` beside this file is the owner's half of the weekly
growth report (W6, launch plan §3 and §4A). One row per week per channel, a
count in every cell that is known and **a blank cell for anything not known**
— a blank prints as — in the report; only a typed `0` prints as 0. No names,
ever: this repository is public.

| column | what goes in it | where it comes from |
|---|---|---|
| `week_ending` | the Sunday the week ends on, `YYYY-MM-DD` | the calendar |
| `channel` | `by_hand` · `public_link` · `r/golf` · `founder_voice` · `web_door` · `appstore_search` · `appstore_browse` · `unattributed` — one row per channel per week, or one `unattributed` row when the week cannot be split | the owner's own record; App Analytics' *Sources* when the store is live |
| `prospects_contacted` | organizers and groups the owner reached that week | the owner's private sheet |
| `organizers_activated` | of those, the ones who created or joined a season, a Ryder or a Major | the app, by hand |
| `groups_playing` | groups that finished a first game unassisted that week | `pilot_sessions` says whether the founder was in the room |
| `appstore_first_time_downloads` | **App Store Connect → App Analytics → Metrics → First-Time Downloads**, that week, for the App Store build only | App Store Connect |
| `testflight_installs` | App Store Connect → TestFlight → the group → installs, that week | App Store Connect |
| `notes` | anything without a name in it | — |

**Three numbers never touch.** First-time App Store downloads are the
checkpoint metric (500 by Oct 31 · 2,000 by Nov 30 · 5,000 by Dec 31,
cumulative). TestFlight installs are the beta door before approval. Web
sign-ups are read from the database by the report itself
(`signups_by_door`) and printed beside the other two. The report never sums
them, and until Apple approves the listing the store count is zero by
definition — pass `--store-live false` and the report says so.

**Every Tuesday**, before the review:

```
node tools/pilot-scorecard.mjs --as-of $(date +%F) --store-live false > docs/pilot/scorecard-$(date +%F).md
```

The October 15 review reads the first two weeks of this log against the
October 31 checkpoint; the checkpoints steer, they do not forecast, and every
acquisition assumption in the launch plan's §0 stays labelled unverified until
this log says otherwise.
