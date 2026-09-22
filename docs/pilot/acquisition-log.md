# The acquisition log and the App Analytics readings — owner-run, counts only

Two files beside this one are the owner's half of the weekly growth report
(W6, launch plan §3 and §4A). Both hold **counts, never names**: this
repository is public. A blank cell is **missing** and prints as —; only a typed
`0` prints as 0. The report never guesses a blank and never sums a malformed
row — it names the line, says why, and leaves it out.

## 1 · `acquisition-log.csv` — the weekly pipeline, as SUBTOTALS

One row per **week** per **channel**. The key is `week_ending` + `channel`: a
second row with the same key is not added to the first — the report rejects
**both** and asks you to merge them.

| column | what goes in it | where it comes from |
|---|---|---|
| `week_ending` | the **Sunday** the week ends on, `YYYY-MM-DD`. Any other weekday, or a date that does not exist, rejects the row | the calendar |
| `channel` | lowercase: `by_hand` · `public_link` · `r/golf` · `founder_voice` · `web_door` · `appstore_search` · `appstore_browse` · `unattributed` — one row per channel per week, or one `unattributed` row when the week cannot be split. Blank means `unattributed` | the owner's own record; App Analytics' *Sources* once the store is live |
| `prospects_contacted` | organizers and groups the owner reached that week | the owner's private sheet |
| `organizers_activated` | of those, the ones who created or joined a season, a Ryder or a Major | the app, by hand |
| `groups_playing` | groups that finished a first game unassisted that week | the report's `assistance_weekly` section says whether a session covered it |
| `appstore_first_time_downloads` | **App Store Connect → App Analytics → Metrics → First-Time Downloads**, that Monday–Sunday, App Store build only | App Store Connect |
| `testflight_installs` | App Store Connect → TestFlight → the group → installs, that week | App Store Connect |
| `notes` | anything without a name in it. A note with a comma must be in double quotes | — |

Every count is **digits only**: `12`, never `12.0`, `1e1`, `~12` or `12k`.

**A week's store count is a subtotal.** The weekly column shows where
downloads came from; it does **not** decide a checkpoint. A Sunday total
cannot say what happened before Saturday October 31, Monday November 30 or
Thursday December 31, and a week that was not logged cannot be told from a
week with none. The report prints each checkpoint's logged subtotal with how
many of the expected weeks carry a number — "330 (3 of 4 weeks logged)" — and
labels it *not a verified total*.

## 2 · `appstore-readings.csv` — the dated cumulative readings that DO decide

One row per reading. A reading is the **cumulative** first-time App Store
downloads from the listing's first day **through** `through_date`, inclusive,
exactly as App Store Connect reports it.

| column | what goes in it |
|---|---|
| `through_date` | the last day of the date range you set in App Analytics, `YYYY-MM-DD` — one row per date (a duplicate date rejects both rows) |
| `appstore_first_time_downloads_cumulative` | the First-Time Downloads total for that range, digits only |
| `source` | where it came from, e.g. `App Analytics, range 2026-10-02..2026-10-31` |
| `notes` | anything without a name in it |

**How to take one:** App Store Connect → App Analytics → Metrics →
First-Time Downloads; set the range from the day the listing went live to the
date you are reading through; copy the total. Which calendar day App Analytics
assigns a download to is Apple's reporting, not Phoenix's — write the range you
used in `source`, and read it the same way every time. (Not verified here: the
listing is not live yet.)

**Record one reading through each checkpoint date** — October 31, November 30,
December 31 — as soon as App Analytics shows that date. A reading through any
other day is welcome and fills in the trend.

**How the report judges a checkpoint (500 by Oct 31 · 2,000 by Nov 30 · 5,000
by Dec 31):**

| status | when |
|---|---|
| **met** | a reading dated **on or before** the checkpoint has reached the target (a cumulative count cannot fall) |
| **missed** | a reading dated **on or after** the checkpoint, and no later than the report date, is still short |
| **open** | the report date is before the checkpoint and nothing has met it yet |
| **unverified** | the date has passed and no reading can settle it — e.g. only weekly subtotals, or only a reading from after the date that has reached the target (it cannot say *when*) |
| **not judged** | the inputs contradict each other: readings that go down, or `--store-live false` beside a non-zero App Store count |

## Three numbers that never touch

First-time App Store downloads are the checkpoint metric. TestFlight installs
are the beta door before approval. The database's weekly count of accounts
whose **first client event** came from the web is printed beside them as a
**proxy** — the first event can follow sign-up by days and come from the other
client — and none of the three is ever added to another. Until Apple approves
the listing the store count is zero by definition: pass `--store-live false`,
and the report says *CONTRADICTION* if either file records a store download
anyway.

## Every week, before the review

The report date is **the Sunday the week ended**, so every week in the report
is whole and nothing after it is counted:

```
node tools/pilot-scorecard.mjs --as-of 2026-10-04 --store-live false > docs/pilot/scorecard-2026-10-04.md
```

- `--as-of` must be a real date and never later than today; the report counts
  only what had happened by the end of that day in `--tz` (default
  `America/Phoenix`). A report is generated from what was observed — never
  written ahead with a future date.
- `--store-live` is exactly `true` or `false`; `true` once Apple approves.
- Columns ending `_now` are the state when the report ran; the report says so.
- `--csv` and `--readings` point at other files; `--json` prints the same
  numbers as data.

The October 15 review reads the first two weeks of this log against the
October 31 checkpoint; the checkpoints steer, they do not forecast, and every
acquisition assumption in the launch plan's §0 stays labelled unverified until
the readings say otherwise. A labelled synthetic example of a filled report —
complete, partial, failing and missing — is in
[`examples/`](examples/README.md); none of its numbers is real.
