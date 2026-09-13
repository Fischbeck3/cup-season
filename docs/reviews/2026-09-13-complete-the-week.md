# Complete the week · Claude handoff — 2026-09-13

Branch `claude/complete-the-week`, worktree `~/cup-season-complete-week`, from
`origin/main` at `8fdf516`. Codex audits the committed checkpoints independently.

**Nothing is deployed.** Two migrations are written, self-checking and verified
against disposable local clusters only. No production mutation, no push, no
merge, no certificate work.

---

## The finding this sprint opened with

The packet says D345 is held and asks for a sequence that excludes the unsafe
original deployment path. **That path already ran.** Verified read-only against
production:

| Check | Result |
|---|---|
| `supabase migration list --linked` | 239 rows, every Local matching Remote, **including `20261024090000`** |
| live signature | `home_dispatch(integer, date)` |
| `plan_followups`, `answer_plan_followup` | both present |
| `afterplan:` in the deployed body | **true** |
| deployed body vs the migration file | **byte-identical**, 43,441 characters each |

Nothing drifted. The hold did not hold. Every planning document in the
repository — the release review, the sprint packet, the contract report, the
migration manifest, and the release-chain test harness — encoded the belief that
it had.

**What that costs a golfer today.** The band's only gate is `p_today is not
null`, which the shipped Safari client sends. So the after-golf card is live on a
client with no Later, no Didn't play and no date prefill: its one door opens a
blank composer dated **today** rather than the day played, a round posted from it
carries the wrong date — which mis-scores the window *and* fails the same-day
suppression predicate, so the card stays — and there is no other control, so it
cannot be dismissed at all.

Live exposure when checked: one plan in the window (2026-09-12), the host plus
three tagged golfers, no course named, no round posted, and zero answers ever
recorded because no client can record one.

`tests/db-checks.sql` check 34 is new and reports this against production now.
The other 33 checks pass.

---

## Commits

| Commit | What |
|---|---|
| `175ee4c` | Checkpoint 1 · the band waits for a client that can answer it |
| `dd6c375` | Prove the shipped two-argument call still resolves after the gate |
| `679741e` | db-check 34 · a band nobody can answer is never served |
| `973ef59` | Checkpoint 2 · say what the server decided, and seat people by the rule |
| `9ce74c6` | Make the Home state hatch reach the states it exists for |

Decisions recorded in `spec/decision-log.md`: **D353** the capability gate,
**D354** a post can start from a plan, **D355** the ceremony says what the server
decided, **D356** an invitation seats you the way every other door does,
**D357** say the unit, the window and the money you can establish.

---

## Checkpoint 1 · complete the golf week

**The capability signal, because `p_today` never was one.** It says the client
knows its own calendar day — which every shipped build already said. A client
must now name `afterplan.v1`, and a capability is added to a client's list only
when the code beside it implements the feature.

**Deploying the migration alone takes the band off every client in the field.**
Home returns to exactly what it was before D345, and the band comes back only for
a build that can answer it. That property is the point: the database fix stops
the harm without waiting for a client, and the shipped two-argument call still
*resolves* rather than erroring, so nothing else about Home changes.

**Prefill, with consent.** The item now carries `context` — plan id, day played,
raw course label, course id, tee time — because the plan id used to exist only
inside a display key and there was no raw label at all. The date is applied
whenever the composer is free to take it. The course goes in as **text with no
catalogue id**: without a tee there is no rating or slope, and a stamped id
beside typed figures would claim the catalogue supplied numbers it never did. A
course the golfer already named is left alone. Holes, gross, photo, tee and
**partners** are never filled — a tag is not attendance.

Three states decide whether a plan may write at all. A kept phone scorecard is
never replaced. A round already sent under a frozen request is never touched,
because rewriting its date would change the body of a request the server may hold
and D350's guarantee is that the body does not move. A started card is replaced
only after an explicit tap that names the day and says exactly what changes.

**Three identities, kept apart** on disk and in the model: `plan` is display
context, `request` is what the server deduplicates the post on, `sourceLive` is a
kept scorecard that already exists.

**The answer says what it did.** `answer_plan_followup` returned void, so a
client could not tell a recorded answer from an already-terminal one or from a
plan that was never theirs. It returns a status; a scratched plan and a plan that
is not yours both answer `not_available`, one reason for both so a stranger
cannot learn whether a plan id exists.

**Course and cache defects were not needed and were not touched.** The prefill
never writes a course id on either client, so the bare-course FK hazard and the
tee-cache replacement hazard are not on this journey's path. Verified rather than
assumed: the plan's `course_id` is decoded, carried for display, and written
nowhere.

---

## Checkpoint 2 · make competition understandable

Audited from a posted round through the month, the standings and the Record, then
through Major, Ryder and Run it back.

**What was already right, so nobody re-audits it.** The season story's historical
claims are fenced by a hard allowlist of named server reads; a sentence with an
unknown source renders nothing. The Record asserts nothing untraceable — a win
requires a completed season, and "since" is nil rather than guessed. No copy
anywhere promises a round *will* add points, overtake anybody or guarantee
qualification: every forward-looking sentence is a ceiling, a gated conditional,
or "another chance to improve". The phone's squad receipt has itemised the ledger
and disclosed an unexplained remainder since D220.

**What was wrong, and is fixed.**

1. **The desk's post ceremony showed a prediction.** `post_round` returns the
   round's `counts` and the epilogue's `points` and `pvi` in one answer. The
   phone reads them; the desk fed the ceremony its own composer preview and
   derived `counts` by comparing the date to whichever league the browser had
   open. Two ways to be wrong: client floats disagree with Postgres's exact
   decimal at band edges, and D229 moved season derivation to the server
   precisely because a golfer can be in two seasons. Now server-first, with the
   client figures surviving only the declared insert fallback, logged.
2. **The desk never read `season_adjustments`.** The squad receipt derived
   total-minus-rounds and labelled the whole difference "the ledger" — attributing
   every discrepancy to rows nobody had looked at. It now itemises each
   adjustment with its reason and names only the actual remainder as not yet
   available.
3. **A Major invitation seated a full contender.** Three of the four doors into a
   Major set `exhibition` by the established-number rule both clients print.
   `respond_invite` did not, so anyone who *accepted* was ranked for the jug and
   counted into the pot however few rounds they had posted. Latent, not live:
   production holds no Major and no accepted event invitation, so it is fixed
   forward with nothing to backfill.
4. **Four sentences asserted more than their payload carried.** The Unlimited
   counting tile printed `floor_credit` as "rounds" under "every round counts".
   The pulse card called credits "rounds counted". A Major invitation said "one
   week" when the window is two to four days. A Major card said "buy-in stays in
   the pot" when **no Major payment record exists anywhere in the schema**.

**A reported defect deliberately not fixed.** `run_it_back`'s length comparison
would fire the covenant refire for a NULL and announce a change nobody made.
`league_settings.season_months` is `integer DEFAULT 9 NOT NULL` in the baseline
and no migration relaxed it, so the column cannot hold a NULL. Proven by trying —
the update is refused by the constraint, and that refusal is now a test.
Replacing a live function to guard a state its own schema forbids is churn.

---

## Evidence — everything below was executed

| Check | Result |
|---|---|
| `tests/release-chain-database.py` | **242 migrations applied, 264 public functions, nothing held** |
| `tests/after-golf-postgres.py` | every D345 case, plus the D353 gate, context and answer statuses |
| `tests/events-consent-database.py` (new) | the Major seating rule, the Ryder seat, and run-it-back's consent behaviour pinned |
| `tests/db-checks.sql` | 34 checks against production; 33 pass, **check 34 reports the live defect** |
| `tests/home-function-browser.js` at 390 and 320 | passed, **zero console errors** |
| `tests/release-posting-browser.js` | 11 checks, network disabled, all five failure journeys |
| `tests/app-tests.js` | 461 checks, zero failures |
| `CupSeasonKit` | **1,158 tests in 188 suites** |
| `CupSeasonTests` | **85 tests in 17 suites** |
| `CupSeason` app build | **BUILD SUCCEEDED**, iPhone 17 Pro |
| `npm run preflight` | **0 failures, 0 warnings** |

The browser audit covers the three-rung call ladder, both controls present and at
least 44px, the door filling the day **played** and the course as text with no
id, a started card surviving until the golfer taps, keep and replace both
behaving, a failed answer keeping the card and re-enabling its controls, an
applied and a terminal answer both clearing it, and telemetry carrying the door
family and the answer but never the plan id.

**Two audit artefacts were found and fixed in the harness rather than papered
over:** a real tap logs, and with the audit's fictional user and no session that
log is an authenticated write that 401s; and switching view starts loads that
outlive the walk. Both are the walk's artefacts, proven by probes showing the
render, the prefill and the door make no network requests at all.

**Pre-existing and not mine:** `tests/homefold.test.mjs` fails one assertion
("Up next" vs "Coming up"). Confirmed identical on a clean `origin/main` tree.

**Not run, so not claimed.** Native dark/light and accessibility-size capture of
the after-golf card. The Home state hatch needed two fixes this sprint and still
renders nothing over a signed-out root; the fixture demonstrably loads (the log
prints `[home-state] S18`), so a third dependency remains, recorded in the inbox
with what was ruled out. The card's behaviour is covered by the Kit suite and the
browser audit instead. Also not run: a real device, a live account end-to-end, and
any offline or older-server pass.

---

## Migrations owed, and the order

Full sequence and rationale: `docs/reviews/2026-09-13-after-golf-deploy-sequence.md`.

| File | What |
|---|---|
| `20261102090000_the_band_waits_for_a_client_that_can_answer.sql` | the capability gate, the item's context, the answer status |
| `20261103090000_an_invitation_seats_you_the_way_the_door_does.sql` | a Major invitation seats by the established-number rule |

**Do not run a blanket `supabase db push`.** The dry run must list exactly these
two and nothing else; anything more means something else is unrecorded too, and
that is the finding rather than the deploy. The database goes **first** and
alone — that is what removes the live band from the field. Read the contract back
before any client ships. Both migrations are idempotent and both raise rather
than reporting success.

No Edge Function, no secret and no contract regeneration is owed for either.

---

## Open, named, not built

Twelve items are in `spec/inbox.md`, each with the first question it needs
answered. The three that matter most:

1. **Run it back enrols a member and bills them without asking.** It writes no
   membership row — a member of the league is a member of its next season by
   construction — and overwrites the league's stake in the same call. With no
   `buy_ins` row the Home strip then prints **"YOU OWE $X"** for a stake that
   member never agreed to, and the copy says "6 of you are on it" about six
   people who were not asked. Declining does not un-seat anybody. **There is no
   acceptance artefact anywhere in the schema.** This is a product decision and
   is surfaced, not taken.
2. **`is_league_member` ignores `left_at` and `suspended_at`,** so a golfer who
   left a season keeps event-creation and Major-entry rights on that league. It
   touches RLS, so it needs its own packet.
3. **The Major's live leader and its settled winner can be different people.**
   The live board breaks ties alphabetically; settlement uses the countback
   ladder the room's own fine print promises, and the payload does not carry the
   countback keys.

---

## To rerun this independently

```
cd ~/cup-season-complete-week
npm ci && npm run preflight
python3 tests/release-chain-database.py
python3 tests/after-golf-postgres.py
python3 tests/events-consent-database.py
supabase db query --linked -f tests/db-checks.sql      # check 34 reports the live defect
python3 -m http.server 8791 &
node tools/web-verify.mjs --url 'http://127.0.0.1:8791/?exit' --widths 390 \
  --wait 1500 --eval "$(cat tests/home-function-browser.js)"
(cd apps/ios && xcodegen generate)
(cd apps/ios/Packages/CupSeasonKit && xcodebuild test -scheme CupSeasonKit \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
(cd apps/ios && xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
```

Production was read but never written. Every database test builds its own
disposable cluster and no test accepts a remote URL.
