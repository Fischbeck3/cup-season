# Audit integration: database and web halves (Claude), 2026-09-24

Branch `claude/audit-integration-2026-09-24`, based on origin/main `32fc9413`. It is **local only**.
Nothing has been pushed, applied or deployed. Codex owns `apps/ios` on its own branch, and this
branch does not touch it.

> **Deployment-security hold.** Several of these migrations repair defects that are live in
> production. This repository is public, so **do not push this branch** until the database push and
> the client push are coordinated as one window (see "Owed, in order" below).

## Commits (oldest first)

| SHA | What |
|---|---|
| fdafabd7 | Brings the repairs forward from `4d7ef398`. S1 gets a fresh version `20261118100000`. The rulings are renumbered D382–D390 so they don't collide with main's D381. |
| 070527f9 | S3 reworked against main's `native_home`: final placement sits beside `points_rank`/`points_tied`, and `in_season` is kept. Also adds the repair harness. |
| c3c1702d | I4: the Book counts what the squad counts (`_counts_for_seat`). Frozen lines are marked, and `withdrawn` is explicit. |
| 527ad69a | I5: durable photo cleanup, meaning the `share_cleanup` queue, the Storage-confirmed report and the `share-cleanup` Edge Function. |
| 404817ae | I5b: one share, one attempt (`prepare_round_share`/`finish_round_share`/`round_share_status`), plus the phone's payload fields. |
| 09eb6dae | I6: the Cup Final `season_story`/`season_scenarios` are read from `cup_finalists`. S1–S12 re-verified. |
| 730e9fbb | Contract union and regeneration. The web confirms a withdrawal instead of assuming it. Codex's probe runs on this branch. |
| da64bc1b | Web: final table, renewal state, the Pro's seat control, and a clean reload after Run it back. |
| 2bb25733 | Web: the share lifecycle, delivery that reports what actually happened, and "Turn off this link". |
| c321fae0 | Web: covenant variants, handle derivation, guest orientation, the join-by-code door, and duplicate LAST. |
| 2637f0da | Web fixes: `window.CS` in a classic block and the covenant dedupe. Share-flow tests now cover the lifecycle. |

## Migration order (after the applied `20261118090000_the_book`, which is untouched)

1. `20261118100000` S1 (D382): the record book has one door
2. `20261119090000` S2 (D383)
3. `20261120090000` S4 (D384)
4. `20261121090000` S5a (D385)
5. `20261122090000` S6
6. `20261123090000` S3: final placement (`final_place`, `is_champion`, `is_runner_up`; `my_rank` = final place, plus `my_points_rank`)
7. `20261124090000` S8 (D390, **PROPOSED**; needs the owner's confirmation before it ships)
8. `20261125090000` S9 (D388)
9. `20261126090000` S7 (D386)
10. `20261127090000` S10 (D387)
11. `20261128090000` S11 (D389)
12. `20261129090000` S12
13. `20261130090000` the Book counts what the squad counts
14. `20261201090000` a withdrawn photo is gone
15. `20261202090000` one share, one attempt
16. `20261203090000` what the phone reads
17. `20261204090000` the final names its seeds

The participation-floor policy for late joiners is unchanged, as the handoff required.

## RPC and payload changes (all additive; old clients keep working)

- **New RPCs, granted to authenticated:**
  - `prepare_round_share(p_round, p_include_photo, p_attempt)` returns `{token, created, include_photo, state, active, rotated?}`.
  - `finish_round_share(p_attempt, p_completed)`.
  - `round_share_status(p_round)` returns `{token, include_photo, cleanup_pending, cleanup[], preparing}`.
  - `my_share_cleanup()`, `retry_share_cleanup(uuid)` and `confirm_share_cleanup(uuid)`.
- **Service-role only:** `_share_cleanup_due(int)`, `_share_cleanup_report(uuid, text)` and `_expire_share_attempts(uuid)`.
- **`season_book` envelope version 2:** entries gain `withdrawn` and `frozen`, and there is a `rules_note`.
- **`native_home`:** memberships gain `renewal_status` (pending/accepted/declined/expired), and standings gain `final_place`, `is_champion` and `is_runner_up` beside `points_rank`/`points_tied`.
- **`join_covenant_info.last_season`:** `my_rank` now means final place, and `my_points_rank` is added.
- **`season_scenarios`:** gains `seed` and `meta.seeds`, and `locked` covers a completed season that has finalists. **`season_story`** final facts gain `locked`, `seeds` and `race`.
- **Contract:** `packages/db/contract.psv` is the union (+18 functions, 0 changed), with every Codex declaration implemented. `rpc.ts` and `Rpc.swift` are regenerated.
- **Cleanup contract:** documented in `docs/planning/2026-09-24-share-cleanup-contract.md`.

## Test evidence (with evidence classes)

| Check | Result | Class |
|---|---|---|
| Fresh PG17 full chain (272 migrations), Book seed + Book verifier | PASS | fixture, local |
| Reapply of every version after `20261118090000` | clean | fixture, local |
| `tests/fixtures/launch-repair/verify.py` (S1–S12 + I4–I6, including trophies) | 50/50 | fixture, local |
| Local Supabase stack, `tests/db-checks.sql` 38–53 | PASS (check 1 fails only because cron is off locally) | integration, local |
| `storage-cleanup.sh` (Storage failure, interruption and retry against the real Storage API) | 20/20 | integration, local |
| Codex's probe: unmodified it reproduces the old defects; the integration variant passes | PASS | integration, local |
| `node --test tests/*.test.mjs` | 65/65 | unit |
| `npm run preflight` | 0 failures, 0 warnings | static |
| Browser (served copy with 0 prod refs, SW and caches cleared): final table, renewal state, clean console; app-tests | 445 run, 1 failure (the same environmental fixture failure as main's baseline) | local browser |
| Production | **not tested** (no production reads were authorized) | none |

**Not browser-driven:** the Pro seat flow, real OS share sheets and the guest pencil. These have
source-level and database evidence only.

## Owed, in order (by the owner; none of this is authorized by the build request)

1. Owner rulings: confirm or reject **D390** (S8).
2. Agree a coordinated window with Codex's native branch, then merge.
3. `supabase db push` (17 migrations), then run `tests/db-checks.sql`.
4. `supabase functions deploy share-cleanup --no-verify-jwt`, then `supabase secrets set SHARE_CLEANUP_SECRET=…`, then create the Database Webhook/cron that calls it with the `x-cleanup-secret` header. Verify the target with `pg_get_triggerdef`, masked, as CLAUDE.md requires.
5. `git push` the client in the same window. The client degrades to the legacy share path if the database lags behind it.
