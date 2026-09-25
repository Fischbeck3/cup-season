# Selected Compete build · September 24, 2026

The owner selected **Scoreboard for Compete, the Book opening to Weeks, and Race inside the Book**, then explicitly approved normal app code and local, unapplied migration files with “Yes go ahead.” D381 records that authorization. This supersedes the exploration's unchanged-Release and no-migration boundaries for the selected implementation. This work remains local to `codex/compete-explorations-2026-09-24` in `/Users/fischbeck3/cup-season-compete-explore`. Nothing was pushed or deployed.

## What is built

Compete keeps its existing ordering, invitations, destinations and empty states. Its lead season now uses Scoreboard: large points, the shared points standing, and a factual competition sentence. Only live competition earns the ember band. Full `brandInk` text fixes the small-label contrast; its contours run continuously behind the text and figures, following the owner’s September 24 visual correction. The canonical a08 opacity preserves small-text contrast over ember; neutral heads use a24 livery contours. The Book heading uses the same continuous background treatment. The season room uses the same head treatment, with its standings and receipt routes preserved.

The prominent Book door appears for ten or more golfers or any squad season. Small solo seasons open **Rounds & points**, with each total opening its complete record. The large Book defaults to **Weeks**, with **Totals** and **Race** alongside it. Golfers and squads share the same read; filtering a squad shows each golfer's round contribution and the squad adjustments needed to reach the team total. Exact integers stay exact. Phone names remain fixed while weeks scroll. Accessibility text sizes use a week selector and full-name rows. The desktop uses a wide matrix and a receipt column; at narrow widths the receipt follows the matrix.

Every cell and total opens its actual included and dropped rounds and adjustments. Receipts identify the golfer and date, explain the contribution, and link into the existing round-receipt route. A missing week, future week, dropped round, bye and adjustment remain distinct. Adjustment rows name their subject and assessed week. The Book contains no money or pot styling.

Race explicitly means **points counting today**, grouped by week played or assessed. Later best-N displacement restates earlier contributions. It is not a historical standings chart. Negative totals and earlier peaks remain in range. A selected race containing points assessed outside the season weeks explains why its curve is omitted; totals and receipts remain available.

## One standing

The earlier 41–41 discrepancy came from `native_home` including names in its rank window, and `LeagueRecord` using array position. The local migration separates alphabetical display order from points rank and adds `points_rank` / `points_tied`. Compete, the Book, the existing points table and You now use equal ranks for equal points. You records a win only for an explicitly recorded champion. Qualification seeds and final tiebreak outcomes are separate facts; no scoring or playoff mechanic changed. An older home payload without explicit points-rank fields leaves the new hero's standing absent.

## Read contract and deployment dependency

Local migration: `supabase/migrations/20261118090000_the_book.sql`. RPC: `season_book(p_league_id uuid, p_season_id uuid) → jsonb`, version 1. It is stable/read-only and security-definer with a fixed search path; public/anon execution is revoked. Only an active, unsuspended league member who agreed to that season can read it. Unknown seasons, mismatched league/season pairs and unauthorized requests have the same denial. No table, scoring view, round or adjustment is changed.

The envelope includes league/season identity, current-rule provenance, timezone, dates, current week, settings, field size, weeks, a coverage flag and rows. Rows have identity/scope, name, points standing, total, unplaced points, exact weekly/cumulative cells, and complete source entries. Each entry carries its round/adjustment id, member/squad, played/assessed date and week, affected month, raw points, included contribution, count state and reason. Null assessment weeks stay outside the weekly axis. Week boundaries derive from the season and its timezone.

Scoring comes from the existing views: `v_rounds_ranked`, `v_individual_standings`, and `v_squad_standings`. Individual overrides count individually; squad floors and other squad adjustments count in the squad total. Their receipts remain visible in the individual record with zero individual contribution where appropriate. Every row reconciles to its actual standings total, and both clients reject partial/mismatched reads rather than displaying a plausible incomplete total. The RPC refuses more than 104 weeks, 200 golfers, 10,000 rounds or 10,000 adjustments; it never silently truncates.

The measured synthetic 16-golfer × 15-week solo read is **85,350 bytes / about 4 KB gzip**. Four squads plus individuals and contributions is **257,117 bytes / about 10 KB gzip**, including 193 real scored rounds and repeated scoped receipts. The fresh local PostgreSQL 17 run measured **31 ms solo / 59 ms squads**, including local `psql` startup; this is not a production latency claim.

The RPC and home-rank patch are **unapplied remotely**. A missing deployment produces a real load error and retry. No Edge deployment is needed. Database review/application must precede shipping the clients. Native distribution and web deployment remain separately unauthorized.

## Verification and evidence

See [selected verification](SELECTED-VERIFICATION.md) for commands, final results and retained failure output. The earlier preparation run is preserved in `evidence/selected-*`; it predates normal app integration. The original **564 exploration captures from `9959c620` remain unchanged**.

New captures use the actual production renderers through the DEBUG-only `-cs_dev_compete_selected` hatch. Synthetic JSON was returned by the local SQL implementation, not fabricated by the renderer. Auth startup, push sync and telemetry are skipped by this hatch. The gallery's **Selected build** section distinguishes these captures from the original three directions. The browser harness also uses the actual production rendering functions and a disconnected fixture RPC.

## Remaining decisions

The design selections are settled by D381: Scoreboard; live-only ember; monochrome contours on ember; ten golfers or squads; small-league Rounds & points; and a race of points counting today. No new product ruling is needed to review this build. A locked historical rules/standings snapshot and pagination beyond the stated Book bounds would be separate future work. Deployment and distribution require separate authorization.
