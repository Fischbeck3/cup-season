# Codex inspection of Claude's decisions · 2026-09-12

Reviewed `claude/after-golf-audit` through `8093871` against Codex `b61024d`. Claude's workspace was clean. This is a source inspection and handoff, not a deployment or a fresh database-runtime certification.

## Approved decisions found

- **D343**, `1a539f7`: declaring a plan seats its host as `in`. Existing host RSVP choices remain possible. Backfill includes server-today/future plans only, and does not overwrite existing RSVP rows.
- **D344**, `bea56eb`: four plan-write guards use `plan_day_floor() = current_date - 1`. This is the approved compatibility allowance; it is not precise golfer-local date handling. Existing RPC signatures stay unchanged.

I compared the function bodies programmatically with the latest preceding definitions in the repository. D343 adds only the host insert inside `declare_round`. D344 preserves that insert and changes exactly one lower-date guard in each of `declare_round`, `retag_round`, `ask_for_a_seat`, and `redeem_share`. The one-year ceiling, ownership/participation checks, copy, and remaining bodies are preserved. Each public RPC explicitly revokes public/anon execution and grants authenticated execution. The new helper is stable and revoked from client roles; security-definer callers use it internally.

No new migration-body regression was found in that comparison. Claude reports testing both migrations in order on a throwaway PostgreSQL cluster. I read that evidence but did not rerun the cluster or query production in this inspection.

## Findings and remaining limits

### 1. Home's evening read still needs local-date handling — medium, confirmed in source

D344 repairs the write-side rejection, but neither migration changes `native_home` or `home_dispatch`.

- `20261019090000_the_card_knows_where_it_has_been.sql:244`: `v_today := current_date`.
- Same file, `:837`: `my_schedule(v_today, v_today + 14)`.
- `20261012090000_the_server_says_the_sentence_the_golfer_reads.sql:772,1277`: UTC server day and the forward-only dispatch filter remain.

At 18:00 Phoenix on September 12, a UTC server's day is September 13. D344 admits a September 12 plan, but the Home source range begins September 13 and excludes it. D343's backfill also intentionally begins at server-today, so an existing unseated September 12 host is not backfilled in that interval. This is an existing read-path gap, not a newly introduced regression; do not describe these migrations as completing the whole evening Home flow. Resolve read/write date consistency as part of the next shared Home contract.

### 2. “One day into the past” needs a timezone qualification — low, deterministic boundary

D344's floor is yesterday **in UTC**, not yesterday in every golfer's calendar. At September 12 12:00 UTC, a UTC+14 golfer's date is September 13, while the floor is September 11: two local calendar dates earlier. The implementation fits the approved UTC-slack recommendation; the worldwide tradeoff wording overstates its precision. Clarify the decision/release description rather than silently narrowing the approved behavior. The unchanged upper bound is also server-relative.

### 3. Correct the loaded-photo accessibility finding — report correction, confirmed

Claude's `c7236ea` inspection and `8093871` handoff say the loaded photo has no custom golfer action. That is incorrect for the exact commit reviewed: `git show b61024d:apps/ios/CupSeason/Home/HomeWire.swift` contains `.accessibilityAction(named: Text("Open golfer"), openPerson)` at line 154, in the successful band. It was already present before this review batch.

The face still uses `.list` and `.onTapGesture` at lines 127–128 without an explicit 44pt frame. That touch-target concern remains separate and worth addressing. Source presence proves the action was not omitted; actual VoiceOver operation on a successfully loaded photo still deserves device/UI verification. Do not add a duplicate action based on the report.

### 4. The course-page planning door and reaction focus remain real follow-ups

- **Course page:** `CourseScreen.swift:54–61,361` only presents “Put it on the plan” through `neverKept`. A loaded course follows `page(book)`, whose footer has “The whole card” and no planning door (`:163–167`). Claude's correction is right: making planning available needs a deliberate hierarchy, not just moving a button. Prepare the placement for visual review within the current token system.
- **Keyboard focus:** `index.html:15756,15768` rerenders the feed after a reaction or rollback; `renderHomeFeed` replaces its DOM. Reveal focuses a choice, but selection does not restore focus to the replacement control. Source-confirmed gap; no new browser run in this inspection. Fix both selection/removal and failed-save rollback while preserving the focused round.
- **Tee-less search:** both `ScheduleService.searchCacheResult` and `searchRemote` filter empty tees (`ScheduleService.swift:148,160`). This can hide a known course. The plan RPC accepts nullable course identity and does not require rated tees, so the shared picker constraint should not be described as an inherent database requirement for planning. Choosing how planning differs from score entry remains an owner/product decision.

### 5. Host status can still disagree after an explicit RSVP change — existing limit

D343 intentionally preserves a host's ability to choose `maybe` or `out`. The existing `my_schedule` roster still synthesizes the host with `status: in` (`20260924093000_a_weekend_has_a_name_and_a_game.sql:204–215`), while `my_rsvp` and `rsvp_in` read actual rows. The new default fixes creation, but does not make every later state consistent. Retain this as a separate read-model follow-up; do not change historical RSVP records to repair it.

## Contract and integration status

The after-golf audit is still a proposal. The new decisions settle host seating and write-side date slack; they do not settle prompt window, maybe/unanswered eligibility, per-day prompt cap, or ambiguous same-day suppression. Claude corrected the earlier route proposal to `composer` and identified the read/write local-day requirement. A nullable plan link would establish identity for explicitly linked new posts; historical or manually entered unlinked rounds would still need a policy.

Claude handed off its branch for integration. Its rehearsal reports append conflicts in `spec/decision-log.md` and `spec/inbox.md`; keep both histories when integrating. I inspected the changed-file sets but did not merge or repeat the rehearsal during this review. Claude's source branch stays intact.

## Handoff

Branch: `codex/home-no-photo-2026-09-12`.
Goal: inspect the owner's new Claude decisions and their implementation.
What changed: this inspection report only; no application or migration edits.
Files changed: `docs/reviews/2026-09-12-claude-decisions-inspection.md`.
Verification run: branch/status inspection, committed reports and decisions read, programmatic before/after function-body comparison, source tracing of Home dates, course routing, reaction focus and loaded-photo accessibility. No fresh runtime tests; Claude's reported test runs are attributed above.
Database deploy owed: Claude's two migrations remain pending per its handoff; production deployment state was not re-queried here.
Edge deploy owed: none from these changes.
Client deploy owed: prior Codex client changes remain unreleased; TestFlight held.
Open questions / risks: read-path timezone gap, local-date tradeoff wording, remaining UI follow-ups and four after-golf choices. Codex branch has no upstream, so the session pull could fetch but not rebase.
Recommended next step: integrate the reviewed branch preserving both documentation histories; correct the review record; resolve the bounded client accessibility/focus issues, then design the loaded-course planning door. Keep Home local-day handling in the after-golf contract checkpoint.
