# Independent inspection of Claude complete-the-week sprint

Reviewed commit: `e3f94c1`, six commits after release `8fdf516`.
Review branch: `codex/complete-week-review-2026-09-13`, worktree `/Users/fischbeck3/cup-season-week-review`.
Claude remains the implementation lead on `claude/complete-the-week`. This inspection changes no application, migration, certificate or production state.

**Disposition: return for focused repairs before client publication.** The database gate and event seating tests pass, but native controls are placed on only one layout, web draft recovery loses entered work, and the new ceremony still mixes server scores with the currently viewed league. Do not start another expansion sprint before closing these paths.

## Findings

### R1 · P1 · Native declares a capability that its normal Home layouts do not implement

`HomeView.swift:224` is the sole `AfterGolfAnswers` call site, inside `case .empty`. `HomePage.swift:272–283` selects that layout only when the golfer has neither seasons nor rounds. A golfer with rounds or a league sees `case .block` (`HomeView.swift:232`) with no answers. An after-golf item below the lead renders through `.item` (`:419`), also with no answers. The new S18 fixture has 22 rounds, so its intended layout is exactly the one missing the controls.

Fix all supported placements. Prove actual visible/hittable Add my round, Later and Didn't play actions for established golfers and for an item displaced below another lead. The current Kit tests assert `answerable`, not that the buttons render. Repair the signed-out fixture harness and add executable native UI tests; screenshots at normal/AX3, light/dark and compact/standard phone sizes must show the actual component. No production writes from a fixture.

### R2 · P1 · A gross-only card bypasses consent, then loses its score on restore

`index.html:17352` (`csPostVals`) and `:10005` (`postDraftHasContent`) omit `inGross`, the main total-score field. With only gross 84 entered and today's stamped date, `csPlanToComposer` changes the date to yesterday with no confirmation. Independently reproduced at 390 and 320.

`savePostDraft` also omits `inGross`. After the plan prefill, save/clear/restore returns the plan date and course but an empty gross. This is an existing persistence omission exposed by the new journey; it still blocks the claimed end-to-end result. The new `state.post.plan` is never serialized or restored either, despite D354's promise that plan context survives relaunch. Only the native PostDraft gained this field.

Fix the real draft snapshot/meaningful-work predicate, not just the new consent call. Include gross, the supported persisted fields and owner-scoped plan context. Preserve pending request/kept-card protections. Clear plan context on accepted completion/reset/account boundaries as appropriate. Test actual save/restore and full page relaunch, including gross-only, nines, changed date, photo/partner-only meaningful state, failed storage and a pending request. Do not silently discard unsupported work.

### R3 · P1 · Older-server retry restores the unanswerable web card

`index.html:17203–17206` first sends capabilities, then retries with `p_today`. A D345-only server accepts the second call and emits an afterplan item without context. The candidate renders its Add my round door and zero answer buttons, recreating the original blank-composer failure. Reproduced at 390/320 with the exact two-argument server shape. Claude's existing test skips this intermediate case by rejecting both newer calls, then accepting only the oldest one.

Make downgrade safe: preserve legitimate Home information while refusing/suppressing an afterplan item this build cannot faithfully act on. Test no-D345, D345-only and capability-enabled servers, schema-cache skew, malformed context and transport failures. Database-first remains the release order; it is not a substitute for the explicitly promised compatibility behavior.

### R4 · P1 · Ceremony uses authoritative points under the wrong league/squad

The new server-first values at `index.html:10487` are good. But `:10500` still passes `mySquad` derived from the open league, and `:10504` still passes `CS.league.name`, ignoring `rpcRound.squad` and `rpcRound.league_name` from that same authoritative result.

Probe: server returns 12 points, PvI 3, Earlier league / Earlier squad; composer preview is 99 points / 8 and the open league is Current league / Current squad. Ceremony receives 12 / 3 but Current league / Current squad. Reproduced twice. Use one consistent server result for the entire attribution. Keep absent server facts absent where required; the comment about a declared insert fallback is stale because ordinary posting now fails closed. Test multi-league/backdated and no-season replies through the actual Post handler, and inspect native parity.

### R5 · P1 release gate · Deployment instructions contradict each other and current state

Read-only production query against explicit project `zddbfcokmvneltrgukzf`, performed during this inspection, returned:

- **240 applied migrations**, through `20261101090000`.
- D345 `20261024090000` is present in migration history.
- `plan_followups` exists; `answer_plan_followup(uuid,text,date)` exists.
- `home_dispatch(integer,date)` contains `afterplan:` and does not contain `afterplan.v1`.
- Neither new sprint migration is in the returned applied-version list.

This confirms the present ungated exposure. It does not establish who deployed D345 or when. The prior release's executed readback returned 239 and `held_d345_applied=false`; preserve both observations with times/context rather than treating false as proof it had applied. Claude's assertion of 239 applied including D345 is not the current count. Do not infer schema history solely from function presence.

`docs/reviews/2026-09-13-after-golf-deploy-sequence.md:73–79` expects ONE migration and then runs unrestricted `supabase db push`; its handoff expects TWO. The executable scope must match the reviewed scope. Update one canonical manifest/sequence for `20261102090000` and `20261103090000`, with a deliberate separate gate-only phase if chosen. Dry run and actual command must use the same scope and `--skip-vault`; no replay of applied migrations. Refresh the changed RPC signatures from the deployed catalog and regenerate source outputs as part of release verification. Explicitly track database, Edge, Safari and TestFlight independently. The owner handles certificates.

### R6 · P2 · The draft question promises a course replacement that does not happen

Web `:17401` and native `PostPlanCopy.explain` say starting the plan changes/replaces date and course. Both implementations preserve a non-empty existing course. A golfer agreeing to start the Papago round can keep a different course and its tee details. Preserve the approved existing-course rule, but have the question accurately describe the changes for the actual draft. Test populated course and blank course separately on both clients. No mechanic decision is needed to make copy match the approved behavior.

## Independent verification executed

- `npm ci` and `npm run preflight`: zero failures/warnings.
- `python3 tests/after-golf-postgres.py`: passed D345/D353 eligibility, gate, context, status, grants and serial replay cases.
- `python3 tests/events-consent-database.py`: passed invitation seating and existing renewal-behavior cases.
- `python3 tests/release-chain-database.py`: 242 migrations / 264 public functions passed in an isolated local cluster.
- Claude's `tests/home-function-browser.js`: passed at 390/320; zero console errors.
- Independent browser probes: reproduced R2/R3/R4 at both widths. Probe output below. Network disabled before setting any fictional signed-in state. The browser harness PASS means no console errors/overflow; it does **not** mean the product criteria passed.
- Native R1 is confirmed by complete call-site/layout inspection; no native UI execution is claimed in this review. Claude already records the missing native visual/interaction evidence. This gap remains a release gate.
- No production writes/deploy, app code edits, scoring changes, certificates or new dependencies.

```json
{
  "grossOnly": {"dateChangedWithoutConsent": true, "questionPresent": false, "gross": "84"},
  "persistence": {"grossSaved": null, "planSaved": null, "dateSaved": "2026-09-12"},
  "reload": {"restored": true, "gross": "", "plan": null, "date": "2026-09-12"},
  "ceremony": {"points": 12, "vs": 3, "league": "Current league", "squad": "Current squad"},
  "oldServer": {"calls": 2, "roundDoor": true, "answerButtons": 0}
}
```

Reproduction script: [browser probes](2026-09-13-complete-week-inspection.probe.js). Serve this worktree on 8796, then:

```sh
node tools/web-verify.mjs --url 'http://127.0.0.1:8796/?exit' --widths 390,320 --eval '(async()=>eval(await (await fetch("/docs/reviews/2026-09-13-complete-week-inspection.probe.js")).text()))()'
```

Temporary logs: `/tmp/cup-season-week-review-{preflight,db,events,chain,home,probes}.log`.

## Claude's next assignment

Continue from `e3f94c1` on your owned branch. Read this review; fix R1–R6 in small checkpoint commits and convert the reproductions into assertions of correct behavior. Most implementation stays with Claude; Codex owns independent review/integration. No expansion into renewal consent, permission-model rewrites, new friend notifications or Final scoring before today's release closes.

Checkpoint A: make the native after-golf controls real and close web consent/draft/relaunch/old-server paths. Checkpoint B: correct ceremony attribution and state-specific prefill copy, then prepare the exact release manifest and evidence. Return commits, screenshots, runnable failure tests and deploys owed. Do not deploy during the repair pass. If the database-only capability gate is proposed as an earlier mitigation, hand off that exact reviewed migration separately; do not couple it to unverified client capability claims.

Codex will audit the returned fixes, integrate the candidate and verify Safari first, then native once the owner resolves signing. Build 835 is the previous release artifact; today's expanded candidate needs its own source/build identity and verification.

## Handoff

Branch: `codex/complete-week-review-2026-09-13`
Goal: independently inspect Claude's sprint and return a concrete repair prompt.
What changed: review evidence and a network-disabled browser reproduction artifact only.
Files changed: this report and its companion probe; no application code.
Verification run: preflight, local database suites/full chain, existing Home browser audit and independent probes.
Database deploy owed: two candidate migrations, pending precise scope and release review; D345 is now observed applied.
Edge deploy owed: none identified for this sprint.
Client deploy owed: Claude's sprint remains unpublished; fixes and native UI proof required.
Open questions / risks: actual signing access, live D345 exposure, native layout gap, draft loss and attribution defects above; larger consent/permissions/tiebreak questions remain in the inbox.
Recommended next step: Claude fixes R1–R6, Codex audits the returned commits, then publish today's tested iteration.
