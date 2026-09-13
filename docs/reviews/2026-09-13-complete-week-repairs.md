# R1–R6 repair pass · Claude handoff — 2026-09-13

Reviewed: `docs/reviews/2026-09-13-complete-week-inspection.md` at `a7f8a3f`.
Continued from `e3f94c1` on `claude/complete-the-week`, worktree
`~/cup-season-complete-week`.

**All six findings are fixed.** Every reproduction in the review is now an
assertion of correct behaviour, and the review's own probe, run unchanged,
returns corrected values for all five of the things it measured.

**Nothing was deployed.** The only production access in this pass was read-only:
the migration ledger, three function signatures, and a `db push --dry-run`.

---

## Commits

| Commit | Findings |
|---|---|
| `56d2ad0` | R2, R3 · one field list; a fence on the item rather than the call |
| `c46edd9` | R1 · the three actions in every placement, and a fixture harness that works |
| `0b78299` | R4, R6 · one server result for the whole attribution; a question that describes this card |
| `08ad329` | R5 · one canonical manifest, and my own count corrected |

---

## What each finding was, and what it is now

### R1 · the capability the native layouts did not implement

The controls shipped on `.empty` alone — the layout for a golfer with neither
seasons nor rounds — so an established golfer got the ember door and no way to
answer or dismiss the card. `HomeView.answers(_:)` is one producer now, called
from all three placements: the empty page, the lead block, and the wire row
beneath another lead. A layout cannot ship the door without the answers again.

**The fixture harness took three fixes and had never shown anybody anything.**
Two were found last checkpoint. The third is the one that mattered: the payload
was applied in a `.task`, so a relaunched scene could lay the scroll view out
once with **no content** — and a scroll view with nothing in it takes its
content's ideal width, which is zero. It never re-expands, so every control
rendered a 16pt column 1,900pt down the page: present in the element tree,
invisible on screen, unhittable. A black screenshot with passing existence
checks is exactly what that looks like. The fixture is applied at init now.

The S18 fixture also carried no membership and so took the lead layout with
nothing to render; it has one, and the Kit asserts it, because that trap is
worth failing on rather than rediscovering.

### R2 · a gross-only card bypassed consent, then lost its score

`inGross` — the hero box, the main total-score field — was missing from **three
of the four** hand-kept copies of the composer's field list. A card carrying only
a gross read as empty: a plan changed its date with no question, and save/restore
returned the date and course with the score gone.

Fixed at the class rather than the call site. `POST_TYPED` and `POST_FIELDS` are
one list, read by the snapshot, the meaningful-work predicate and the consent
check, and lifted into `tests/post-request.test.mjs` from `index.html` so the
real list and the test's cannot part company again.

The plan now rides with the draft under the same owner-scoped key, is never
inherited from a draft another golfer wrote, and leaves with the round it filled
in.

### R3 · the middle server restored the unanswerable card

The ladder walks capability, then day, then neither — and a database with D345
but **without** the gate accepts the second rung, then emits an afterplan item
with no context. Rendered as-is that is the original defect exactly.

The fence is on the **item**, not on which call happened to succeed: an afterplan
item this build cannot faithfully act on is dropped, and every other item in the
same reply is kept. Malformed context falls here too. Database-first is still the
release order; this is what makes the order a preference rather than a cliff.

### R4 · authoritative points under the wrong league and squad

`counts`, `points` and `pvi` came from the server while the league name and squad
were still read off whichever league the browser had open. A backdated round
could be announced with the server's twelve points under the wrong league's name
and a squad the golfer is not on in that season. One result, one attribution now:
`league_name` and `squad` come from the same answer. A round that counts for no
season names neither and claims no points.

The note beside it was stale and the review was right: ordinary posting fails
closed, the direct insert on that path is gone, and a post that does not land
throws before any ceremony runs. The client figures survive only where the
server's answer **omits** a field, and that case is logged as what it is.

### R5 · the deployment instructions contradicted each other

One file now. Scope is **two** migrations and the dry run proves it. Dry run and
real command use the same scope and flags; no applied migration is replayed. A
gate-only first phase is offered with the staging copy it requires. The contract
refresh is specified as a post-push step with its commands and with what it will
surface. Database, Edge, Safari and TestFlight are four separate rows.

**My earlier count was wrong.** I said 239 applied; that came from a `grep -c`
over the listing and miscounted. Reading the Remote column gives **240**, the
review's figure. Who applied D345 and when remains unknown and is not inferred.

### R6 · the question promised a course replacement that does not happen

Both clients leave a course the golfer already typed alone, while the question
said starting the plan's round replaces "the date and course". The approved rule
is untouched; the sentence reads the actual draft now and says which course
stays when one does.

---

## Evidence — everything below was executed

| Check | Result |
|---|---|
| `tests/after-golf-repairs-browser.js` (new) at 390 and 320 | **passed**, zero console errors |
| The review's own probe, unchanged | all five measurements corrected — see below |
| `tests/home-function-browser.js` at 390 and 320 | passed |
| `tests/release-posting-browser.js` | 11 checks, network disabled, five failure journeys |
| `tests/app-tests.js` | 461 checks, zero failures |
| `tests/league-setup-browser.js` | 20 checks |
| `tests/post-request.test.mjs` | **48** assertions |
| `tests/release-chain-database.py` | 242 migrations, 264 public functions |
| `tests/after-golf-postgres.py` | D345 + D353 gate, context, statuses, grants |
| `tests/events-consent-database.py` | Major seating, Ryder seat, run-it-back consent |
| `tests/release-fixes-database.mjs` | ALL PASS |
| `CupSeasonKit` | 1,158 tests in 188 suites |
| `CupSeasonTests` | 85 tests in 17 suites |
| `CupSeasonUITests/AfterGolfAnswerTests` (new) | **5 tests, 0 failures** |
| `CupSeasonUITests` (whole target) | my 5 pass; **8 review-capture tests fail on a missing precondition** — see below |
| `npm run preflight` | 0 failures, 0 warnings |
| `supabase db push --dry-run` | exactly the two migrations |

**The review's probe, before and after.**

| Measurement | Review | Now |
|---|---|---|
| `grossOnly.dateChangedWithoutConsent` | `true` | **`false`** |
| `grossOnly.questionPresent` | `false` | **`true`** |
| `persistence.grossSaved` | `null` | **`"84"`** |
| `reload.gross` | `""` | **`"84"`** |
| `ceremony.league` / `.squad` | Current league / Current squad | **Earlier league / Earlier squad** |
| `oldServer.roundDoor` | `true` | **`false`** |

Its remaining `planSaved: null` and `reload.plan: null` are the **correct
consequence** of consent now being required: that probe never answers the
question it now gets asked, so no plan is ever applied. The repair suite covers
the answered path.

**Native UI tests, driving the real app.** An established golfer gets all three
actions, hittable and at least 44pt; they survive AX3; they survive light
printing; a failed answer **keeps** the card and leaves its controls live; and
the round door is the primary and sits above the ways out.

**Screenshots** at `/tmp/cs-after-golf/`, and attached to the xcresult:
standard dark and light at normal and AX3, compact dark at normal and AX3. Not
committed — this repo is public and prior sprints keep captures out of the tree.

---

## Deploys owed

| Layer | Owed |
|---|---|
| Database | `20261102090000` and `20261103090000` — pending, verified locally only |
| Edge Functions | none |
| Safari | the client half of R1–R6, unpublished, awaiting Codex integration |
| TestFlight | a new candidate with its own build identity; 835 is the previous artifact |

Sequence, flags and readbacks: `docs/reviews/2026-09-13-after-golf-deploy-sequence.md`.
**No deployment happened in this pass.** `tests/db-checks.sql` check 34 reports
the ungated band against production today and is the post-push gate.

---

## Not done, and said rather than implied

- **The wire placement is code-complete and not proven by a UI test.** The wire
  is built from the feed, and `runFixture` clears the feed on purpose — a fixture
  that invented one would be inventing golfers. The Kit asserts the
  `after_golf_wire` payload carries an answerable non-lead card, and the three
  placements share one producer. A real displaced card belongs to a device pass.
- **No device, no live account, no offline pass.** Everything native is
  simulator and fixture.
- **Eight UI tests in four review-capture suites fail, and they are
  environmental.** `AcceptedRoundReviewTests`, `CompeteBoldReviewTests` and
  `CompeteGameplayReviewTests` launch with `-cs_dev_open compete` / `receipt` —
  hatches that open a real screen for a **signed-in** account — and read real
  account data (`compete.row.`, `season.title`, a real receipt). One of them
  fails with its own precondition message, *"Use the signed-in review
  simulator"*. This machine's simulator has no signed-in account. None of them
  touches Home, the after-golf card, the composer draft or the ceremony, which
  is where every change in this pass lives. This is the first run of the whole
  UI target in this workspace — the previous checkpoint ran only
  `LeagueSetupReviewTests` — which is why they surface now rather than earlier.
  A signed-in simulator, which Codex's release workspace has, is what they need.
- **`tests/homefold.test.mjs` fails one assertion** ("Up next" vs "Coming up").
  Pre-existing; confirmed identical on a clean `origin/main` tree in the previous
  checkpoint and unchanged by this pass.
- Renewal consent, the permission model, notifications and Final scoring stayed
  out of this iteration, as instructed. The open items from the previous
  checkpoint remain in `spec/inbox.md`.
