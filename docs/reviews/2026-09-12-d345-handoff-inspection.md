# D345 / TestFlight handoff inspection · 2026-09-12

Reviewed Claude `040dcd2` (handoff), `482f256` (D345), and the deployment update in `559fc0b`. Codex working branch: `codex/home-no-photo-2026-09-12`, starting at `0993788`. Claude's branch and production code were not edited.

**Verdict: keep D345 held. There is a reproduced runtime blocker, plus a shipped-client date defect and an unsupported participation claim.** The existing client release can remain separate from this unapplied migration; this review is not a fresh certification of that release build.

## 1. High — a qualifying plan makes the Home RPC fail

File on Claude's branch: `supabase/migrations/20261024090000_the_loop_has_a_closing_act.sql:712`.

The outer function declares `e jsonb`. The new loop selects one JSONB column, so the scalar `e` receives that JSON value directly. Its inner declaration incorrectly treats `e` as a record:

```sql
j jsonb := e.j;
```

**Observed on PostgreSQL 17:** applying the exact migration and every self-check succeeds. Calling the exact resulting `home_dispatch(21,current_date)` with one eligible yesterday plan then fails:

```text
ERROR: missing FROM-clause entry for table "e"
QUERY: e.j
CONTEXT: PL/pgSQL function home_dispatch(integer,date)
         line 607 during statement block local variable initialization
```

This fails the whole dispatch request, not just the new item; clients fall back and lose the normal server-ranked response. It explains why syntax checks and a separately extracted predicate did not establish runtime safety.

**Diagnostic correction, proven only in the isolated cluster:** `j jsonb := e;`. With that one change, the same function returned an `afterplan` item with a working composer route; calling Later removed it from that read, and the empty-plan case also returned normally. No patch was made to the real migration or Claude's workspace.

Add a durable regression that invokes the actual migrated `home_dispatch` with an eligible plan, rather than testing only its SELECT predicate. Exercise the new block within the full production-like schema before deployment.

## 2. Medium — old clients violate the approved “never today” rule

D345 helper and default: migration `:28–33,101,113`; after-plan window `:693`.

Both existing clients omit `p_today`:

- Native: `HomeStream.swift:141–149`, `DispatchCall` carries only `p_days`.
- Web: `index.html:16790`, `{ p_days: 21 }`.

On September 12 at 18:00 Phoenix, UTC already says September 13. Without a supplied day, `cs_local_day(null)` returns September 13, and a plan for the golfer's September 12 qualifies as “yesterday.” This new premature prompt is not equivalent to the old client's previous behavior. The approved rule says today belongs to the live bridge.

The existing `native_home()` read also stays UTC-based. Passing a local day into the outer dispatch alone will not restore tonight's upcoming plan if the inner `my_schedule(v_today, v_today+14)` already excluded it. Both read layers must agree.

**Required:** send the local date from new clients with an old-server retry, and define safe behavior when that date is absent so shipped builds do not get a false yesterday prompt. Include old-client/new-server and Phoenix-evening cases. Keep `localHeadline` until its local-date purpose is covered; fixing the server's preposition alone is not enough to justify deleting that behavior.

This finding is a deterministic date/call-site trace, not a simulated production-clock test.

## 3. Medium — the prompt claims an unanswered invitation was played

Migration `:694–697` includes tagged golfers with no RSVP or `maybe`. At `:729–731`, every non-host receives “You were out with [host] …”. There is no posted-round or attendance evidence behind that claim; finding out whether they played is the point of the prompt.

Keep the approved eligibility. Change the sentence to describe the known plan/invitation, or ask whether they played, using one server copy producer. Verify unanswered, maybe and host cases visually. This is a copy/data mismatch, not a request to reopen the owner's eligibility decision.

## Additional inspection notes

- D345 records owner authorization for the recommended three-day window, inclusion of unanswered/maybe tags minus out, one item per day, and the conservative same-day suppression heuristic. These supersede the earlier reports that called all four undecided.
- `answer_plan_followup` upserts either answer over the other. A later request can overwrite `didnt_play`, so “terminal” currently means suppressed until overwritten, not an enforced irreversible state. Before wiring controls, decide and test behavior for retries or stale devices; preserve the golfer's intent without silently rewriting RSVP history.
- The new handoff repeats the incorrect missing-photo VoiceOver-action finding. `b61024d` already has that action on the loaded band at `HomeWire.swift:154`. Its explicit 44pt face target remains separate work.
- D345 adds no composer prefill or Later / Didn't play controls. It opens the plain composer on current builds. The course-page planning door and reaction-focus follow-ups remain client tasks.
- Do not remove the native local headline rewrite merely because D345 fixes “on today”: it also derives the displayed day from the device's calendar.

## Verification performed

Used an isolated PostgreSQL 17 cluster, a private Unix socket with TCP listening disabled, stub tables, fixed illustrative identities, and a stub `native_home` payload. Applied the exact 906-line migration, then invoked its whole `home_dispatch` function. The first harness run lacked `friendships.created_at`; that fixture omission was corrected before the reproduced `e.j` failure. It was not counted as a product defect.

Observed: original migration/self-checks pass; eligible dispatch fails; one-line diagnostic correction makes eligible dispatch pass; Later hides that item; empty plans return a response. This tests the actual loop inside the function, but does not exercise real memberships, all ranking branches, production RLS as multiple identities, PostgREST, or UI screenshots. No application suites were rerun because application code was unchanged.

Local evidence: `work/d345-inspection/setup.sql`, `original.sql`, `apply.log`, `eligible-original.log`, `eligible-patched.log`, `snooze.log`, `empty-patched.log`. These are ignored scratch outputs. The temporary database was stopped and removed after each run. Production queries in this inspection were SELECT-only metadata reads; no production test records were created.

## Handoff

Branch: `codex/home-no-photo-2026-09-12`.
Goal: inspect Claude's latest release-window handoff and D345.
What changed: this review report only; isolated test artifacts are ignored.
Files changed: `docs/reviews/2026-09-12-d345-handoff-inspection.md`.
Verification run: isolated PostgreSQL runtime reproduction and diagnostic correction; source/caller/date review; production metadata read; documentation diff check.
Database deploy owed: D345 remains held. Independently read the production ledger: 231 migrations, latest `20261023090000`, both D343/D344 recorded, D345 absent. Production is UTC and still exposes the one-argument dispatch and D344 helper.
Edge deploy owed: none from this handoff.
Client deploy owed: existing Codex changes remain separate from D345; no build or upload performed in this review.
Open questions / risks: findings 1–3 need resolution before D345 activation; no integrated release build was tested here.
Recommended next step: integrate the handed-off source into the owned branch with both decision/inbox histories preserved, repair D345 and add actual-RPC regression coverage, retain its deployment hold, then continue the independent client release checks.
