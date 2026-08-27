# Phase 3 · Parity wave 1 + wave 2 (Home) — status artifact

*2026-08-27 · branch `native/m0-foundation` @ `c5000ae` · IOS-018 parity waves*

## Completed
- **A · Standings & the league room** — header, phase-dispatched body, stats strip, pressure meter, the climb, standings table with the storytelling sentence / heat arrows / split-flap / scenario line, individual race + member history, squad receipt with ledger reasons, bylaws + endgame dial, scoring help, pot pane (mark-paid, forfeits), season ceremony from `season_payouts`, album, members sheet with Pro tools, share/invite, D71 cancellation, delete league. (`CupSeason/League/`, `CupSeasonKit/League/`)
- **B · The board** — compact + full feeds, kinds, pinned announcement, digest, round story cards from a `RoundCache`, `CSBands` verbatim, six-emoji reactions (one write path), comments on round posts, report, chat composer, Pro announce, `ScorecardSheet`, `LeagueRealtime` on the dedicated client. (`Board/`)
- **C · Rounds read, You, Tour Card** — receipt with the arithmetic row, You tab (credential, display case + engraver, career record, lifetime tiles, form row, recent rounds + delete, guide), Tour Card (buddy action, rivalry, mute, report photo), rivalries + naming, album. (`Rounds/`, `You/`)
- **D · People, invites, join, calendar** — buddies + picker, invites banner, join by code with the covenant (fails closed), welcome, `JoinIntent`, the calendar (grid, watch list, week-by-week), declare a round with `CourseSearchField`, scheduled-round sheet (RSVP, comments, weather), Up Next chips, Coming up. (`People/`, `Schedule/`)
- **F · Card & settings** — the full web sheet, feedback, founder desk + note, APNs registration, `CSToastCenter`. (`Settings/`)
- **Wave 2 · Home** — invites, live-round banner, hero, occasion engine, Up Next, digest (since / quiet), the one feed (rounds + league moments, buckets), Coming up; the tab shell with navigation paths and a `Presenter` for cross-cutting sheets; join intent after the card gate; Universal Links for `?join` / `?claim`.

## Verified
- Merged tree: **BUILD SUCCEEDED**, **TEST SUCCEEDED** (see below), preflight **17/17**.
- Each slice built and tested in its own worktree before merge; merge clashes (duplicate `FlowRow`, `BandTests`, `AlbumScreen`, `ScoringHelpSheet`, `UUID: Identifiable`, `CheckRow`/`MathRow`/`Fine`/`CSMini`, a duplicate `CSPalette.squad`) resolved by prefixing the later slice's helpers.
- Not yet verified on a device: the phone was unplugged when wave 1 finished; the last device build is the M0 one.

## Remaining in these waves
- Home reactions (`fetchHomeSocial` — reactions on circle rounds through the shared-league post) and the digest's mentions line.
- Toast hosts: slices B, C, D each mount their own; consolidate on `CSToastCenter` (installed at the root).
- Generator gaps noted by D: nullable scalar returns and nullable non-defaulted uuid args in `build-db.mjs` (two hand-declared calls exist meanwhile).
- ~~`native_home` still unpushed~~ — IOS-009 batch 1 pushed 2026-08-27 (`close_month` revoke held; snapshot refreshed; db-checks 11/12 — check 8 flags one pre-existing duplicate `month_closed` sentinel to look at in the SQL editor). Home reactions + digest mentions landed (`05618fc`).

## Next
Waves 3–6 launched in parallel 2026-08-27: post a round · the live round · league creation + draft + Pro tools · the Ryder and the Major.
