# SYNTHETIC — the acquisition half on five input scenarios

> **SYNTHETIC.** Every number below is invented to exercise the checkpoint rule. None was observed. Regenerate with `node tests/pilot/fixtures/render-examples.mjs`.

## A · complete — a reading through the checkpoint date decides it

_Report date 2026-11-01 · `--store-live true`._

_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **accounts whose first event came from the web** (the database; a proxy, not a door). A — is missing; only a written 0 is zero._

#### checkpoints — cumulative first-time App Store downloads

_Judged on dated App Analytics readings only: **met** when a reading on or before the date reached the target, **missed** when a reading on or after it (up to the report date) is still short. Weekly log totals are subtotals: they cannot say what happened before a mid-week date and never decide a checkpoint._

| checkpoint | target | status | App Analytics reading | logged weekly subtotal (not a verified total) |
|---|---:|---|---|---|
| 2026-10-31 | 500 | met | 512 through 2026-10-31 | 490 (4 of 4 weeks logged) |
| 2026-11-30 | 2,000 | open | 512 through 2026-10-31 | 490 (4 of 5 weeks logged) |
| 2026-12-31 | 5,000 | open | 512 through 2026-10-31 | 490 (4 of 5 weeks logged) |

_Every acquisition assumption behind these checkpoints is unverified (launch plan §0). The checkpoints steer; they do not forecast. The October 15 review decides the channel mix, not the target._

#### the weekly log — logged subtotals

_Weeks logged: 4 of 5 from 2026-10-04 to 2026-11-01; not logged: 2026-11-01._

| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads (logged) | TestFlight installs | accounts, first event on web (db, proxy) | channels |
|---|---:|---:|---:|---:|---:|---:|---|
| 2026-10-25 | — | — | — | 160 | — | — | by_hand |
| 2026-10-18 | — | — | — | 205 | — | — | by_hand |
| 2026-10-11 | — | — | — | 85 | — | — | by_hand |
| 2026-10-04 | — | — | — | 40 | — | — | by_hand |

#### by channel — logged subtotals, not verified totals

| channel | first-time App Store downloads logged | weeks with a number |
|---|---:|---:|
| by_hand | 490 | 4 |

#### App Analytics readings used

| through | cumulative first-time downloads | source |
|---|---:|---|
| 2026-10-31 | 512 | App Analytics (SYNTHETIC) |

## B · partial — weekly subtotals with a missing week, and no reading: unverified, never missed

_Report date 2026-11-01 · `--store-live true`._

_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **accounts whose first event came from the web** (the database; a proxy, not a door). A — is missing; only a written 0 is zero._

#### checkpoints — cumulative first-time App Store downloads

_Judged on dated App Analytics readings only: **met** when a reading on or before the date reached the target, **missed** when a reading on or after it (up to the report date) is still short. Weekly log totals are subtotals: they cannot say what happened before a mid-week date and never decide a checkpoint._

| checkpoint | target | status | App Analytics reading | logged weekly subtotal (not a verified total) |
|---|---:|---|---|---|
| 2026-10-31 | 500 | unverified — needs an App Analytics reading through the date | — | 350 (2 of 4 weeks logged) |
| 2026-11-30 | 2,000 | open | — | 550 (3 of 5 weeks logged) |
| 2026-12-31 | 5,000 | open | — | 550 (3 of 5 weeks logged) |

_Every acquisition assumption behind these checkpoints is unverified (launch plan §0). The checkpoints steer; they do not forecast. The October 15 review decides the channel mix, not the target._

#### the weekly log — logged subtotals

_Weeks logged: 3 of 5 from 2026-10-04 to 2026-11-01; not logged: 2026-10-11, 2026-10-18._

| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads (logged) | TestFlight installs | accounts, first event on web (db, proxy) | channels |
|---|---:|---:|---:|---:|---:|---:|---|
| 2026-11-01 | — | — | — | 200 | — | — | by_hand |
| 2026-10-25 | — | — | — | 250 | — | — | by_hand |
| 2026-10-04 | — | — | — | 100 | — | — | by_hand |

#### by channel — logged subtotals, not verified totals

| channel | first-time App Store downloads logged | weeks with a number |
|---|---:|---:|
| by_hand | 550 | 3 |

#### App Analytics readings used

| through | cumulative first-time downloads | source |
|---|---:|---|
| — | — | no reading recorded yet |

## C · failing — a reading through Oct 31 short of 500: missed

_Report date 2026-11-01 · `--store-live true`._

_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **accounts whose first event came from the web** (the database; a proxy, not a door). A — is missing; only a written 0 is zero._

#### checkpoints — cumulative first-time App Store downloads

_Judged on dated App Analytics readings only: **met** when a reading on or before the date reached the target, **missed** when a reading on or after it (up to the report date) is still short. Weekly log totals are subtotals: they cannot say what happened before a mid-week date and never decide a checkpoint._

| checkpoint | target | status | App Analytics reading | logged weekly subtotal (not a verified total) |
|---|---:|---|---|---|
| 2026-10-31 | 500 | missed | 480 through 2026-10-31 | 460 (4 of 4 weeks logged) |
| 2026-11-30 | 2,000 | open | 480 through 2026-10-31 | 460 (4 of 5 weeks logged) |
| 2026-12-31 | 5,000 | open | 480 through 2026-10-31 | 460 (4 of 5 weeks logged) |

_Every acquisition assumption behind these checkpoints is unverified (launch plan §0). The checkpoints steer; they do not forecast. The October 15 review decides the channel mix, not the target._

#### the weekly log — logged subtotals

_Weeks logged: 4 of 5 from 2026-10-04 to 2026-11-01; not logged: 2026-11-01._

| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads (logged) | TestFlight installs | accounts, first event on web (db, proxy) | channels |
|---|---:|---:|---:|---:|---:|---:|---|
| 2026-10-25 | — | — | — | 130 | — | — | by_hand |
| 2026-10-18 | — | — | — | 205 | — | — | by_hand |
| 2026-10-11 | — | — | — | 85 | — | — | by_hand |
| 2026-10-04 | — | — | — | 40 | — | — | by_hand |

#### by channel — logged subtotals, not verified totals

| channel | first-time App Store downloads logged | weeks with a number |
|---|---:|---:|
| by_hand | 460 | 4 |

#### App Analytics readings used

| through | cumulative first-time downloads | source |
|---|---:|---|
| 2026-10-31 | 480 | App Analytics (SYNTHETIC) |

## D · missing — nothing logged and nothing read, reported on Dec 1

_Report date 2026-12-01 · `--store-live true`._

_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **accounts whose first event came from the web** (the database; a proxy, not a door). A — is missing; only a written 0 is zero._

#### checkpoints — cumulative first-time App Store downloads

_Judged on dated App Analytics readings only: **met** when a reading on or before the date reached the target, **missed** when a reading on or after it (up to the report date) is still short. Weekly log totals are subtotals: they cannot say what happened before a mid-week date and never decide a checkpoint._

| checkpoint | target | status | App Analytics reading | logged weekly subtotal (not a verified total) |
|---|---:|---|---|---|
| 2026-10-31 | 500 | unverified — needs an App Analytics reading through the date | — | — (0 of 4 weeks logged) |
| 2026-11-30 | 2,000 | unverified — needs an App Analytics reading through the date | — | — (0 of 9 weeks logged) |
| 2026-12-31 | 5,000 | open | — | — (0 of 9 weeks logged) |

_Every acquisition assumption behind these checkpoints is unverified (launch plan §0). The checkpoints steer; they do not forecast. The October 15 review decides the channel mix, not the target._

#### the weekly log — logged subtotals

_Weeks logged: 0 of 9 from 2026-10-04 to 2026-11-29; not logged: 2026-10-04, 2026-10-11, 2026-10-18, 2026-10-25, 2026-11-01, 2026-11-08, 2026-11-15, 2026-11-22, 2026-11-29._

| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads (logged) | TestFlight installs | accounts, first event on web (db, proxy) | channels |
|---|---:|---:|---:|---:|---:|---:|---|
| — | — | — | — | — | — | — | no rows logged yet |

#### by channel — logged subtotals, not verified totals

| channel | first-time App Store downloads logged | weeks with a number |
|---|---:|---:|
| — | — | — |

#### App Analytics readings used

| through | cumulative first-time downloads | source |
|---|---:|---|
| — | — | no reading recorded yet |

## E · contradictory — --store-live false beside a logged store count, and a duplicate row

_Report date 2026-10-05 · `--store-live false`._

_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **accounts whose first event came from the web** (the database; a proxy, not a door). A — is missing; only a written 0 is zero._

_`--store-live false`: the App Store listing is not live, so the store count is zero by definition until Apple approves._

**Input problems (the rows named were left out; nothing here was guessed):**
- log: lines 3, 4 are all week 2026-10-04 / channel public_link — one row per key; merge them into one row. The report left every one of them out.
- CONTRADICTION: --store-live false says the App Store listing is not live, but the inputs record first-time App Store downloads (logged weekly downloads in 2026-10-04/by_hand). Before approval that count is zero by definition — correct the flag or the entry. No checkpoint is judged on contradictory input.

#### checkpoints — cumulative first-time App Store downloads

_Judged on dated App Analytics readings only: **met** when a reading on or before the date reached the target, **missed** when a reading on or after it (up to the report date) is still short. Weekly log totals are subtotals: they cannot say what happened before a mid-week date and never decide a checkpoint._

| checkpoint | target | status | App Analytics reading | logged weekly subtotal (not a verified total) |
|---|---:|---|---|---|
| 2026-10-31 | 500 | not judged — contradictory input | — | 25 (1 of 1 weeks logged) |
| 2026-11-30 | 2,000 | not judged — contradictory input | — | 25 (1 of 1 weeks logged) |
| 2026-12-31 | 5,000 | not judged — contradictory input | — | 25 (1 of 1 weeks logged) |

_Every acquisition assumption behind these checkpoints is unverified (launch plan §0). The checkpoints steer; they do not forecast. The October 15 review decides the channel mix, not the target._

#### the weekly log — logged subtotals

_Weeks logged: 1 of 1 from 2026-10-04 to 2026-10-04._

| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads (logged) | TestFlight installs | accounts, first event on web (db, proxy) | channels |
|---|---:|---:|---:|---:|---:|---:|---|
| 2026-10-04 | — | — | — | 25 | — | — | by_hand |

#### by channel — logged subtotals, not verified totals

| channel | first-time App Store downloads logged | weeks with a number |
|---|---:|---:|
| by_hand | 25 | 1 |

#### App Analytics readings used

| through | cumulative first-time downloads | source |
|---|---:|---|
| — | — | no reading recorded yet |
