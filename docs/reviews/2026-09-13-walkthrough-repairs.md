# Walkthrough repairs · Claude handoff for Codex's follow-up walk

Date 2026-09-13. Answers `docs/reviews/2026-09-13-signed-in-account-walkthrough.md`
(WA1–WA6) and `docs/reviews/2026-09-13-integrated-welcome-review.md` (F1–F3),
in the build order Codex set, and continues checkpoint B.

Branch **`claude/mobile-web-integration`**, worktree `~/cup-season-mobile-web-integration`,
on top of the reviewed candidate `8f85dac`. Neither source branch was reset;
`claude/mobile-safari-experience` and `claude/d339-web-half` are untouched.

## The candidate and the deployed version

| | |
|---|---|
| **Candidate** | **`f79140b`** (the last commit is test-only; the application source is `cb5d5be`) |
| **Preview** | **https://deploy-preview-3--cupseason.netlify.app** — PR #3, the same preview, rebuilt |
| **Readback** | `#obCaption` `v23 · f79140b` and `sw.js` `VERSION = 'f79140b'`, read at 20:09:51 |
| Live web | `https://cupseason.app` **unchanged at `963d0e6`**. Nothing promoted. |
| Backend | the production Supabase project, as before. Nothing was written from the preview by this pass. |
| Native | no app change; 857 archived from `963d0e6`, export still blocked on signing. |

Commits, in Codex's order:

| Commit | Findings |
|---|---|
| `4b59b37` | **WA1**, **WA2** (= F2) |
| `bd2bc3b` | **WA3**, **F1** |
| `da23d77` | **F3** |
| `67a831d` | **WA4**, **WA6** |
| `cb5d5be` | **MW-05** (checkpoint B; WA5's named half) |
| `f79140b` | regression corrections only — no product change |

---

## Findings

### WA1 · P1 · fixed — a posted round opens the posted receipt

The lead's *See the receipt* and the compact strip's last score handed a
**posted** round's id to `openRoundSheet`, which reads `round_detail` — the
**scheduled** round's read. That RPC 400s on a posted id, so the sheet closed
and the golfer was told "Couldn't load that round" about their own round.

`openRoundReceipt` alone could not be the substitute, exactly as Codex warned:
handed a bare id it looks the round up in `roundCache` and **returns silently**
when it is not there, which is every round the current page has not listed.
There is one opener now, `csOpenPostedRound(id)`: the cache when it has the
round, `round_card` when it does not, a loading sheet while it reads, and an
honest line if it cannot be read — never an empty receipt. The **league lens
stays the server's**, which is what `round_card` is for: it picks the scoring
membership itself and returns points, month rank and counting cap together.
Scheduled doors are untouched.

### WA2 (= F2) · P1 · fixed — one click reaches the season it names

Home's season item and Compete's league row both called
`enterLeagueById(id, false)` and stopped; `enterLeague` navigates only when
`nav` is true. Passing `true` is not the fix either — its own navigation picks
Home, or the wizard for a Pro in setup, never the season room.

`csOpenSeason(id)` loads, **confirms the context actually changed**, then opens
the room. A failed load, a thrown load and a league that is no longer a
membership each leave the golfer where they are and say why; navigating on a
failed load would put one league's table under another league's name. Both
doors share it, so the pre-existing Compete path is repaired with the new one.

### WA3 · P2 · fixed — a count that has not arrived is not zero

The credential read `career?.rounds ?? 0` and printed it, and `loadCareer` only
came back to correct it while the index was still building — so every
established golfer kept a zero beside their real history. There are three
states: `career` is null before the read lands **and** after it fails, and an
empty history is `rounds: 0`. The card prints an em dash, the number, or zero
accordingly, and refreshes whenever the count arrives.

### WA4 · P2 · fixed — standings history reaches the round behind it

The history sheet's only control was Close. A row that has a round is a door
now, into the same posted receipt (so an uncached round resolves itself); a row
without one stays a plain line. The bumped explanation is unchanged and no
competition points are recomputed. The attribute is `data-histround`, because
`data-hround` already means a **scheduled** round card on Home.

### WA5 / MW-05 · fixed (copy + phone hierarchy) — checkpoint B continues

The composer printed one line in every league: *"Your best few each month count
toward your squad."* In a solo season there is no squad, and "a few" is a number
the league stores. `csCountingNote()` is one producer, painted where the eyebrow
is painted, reading the **league's own** rules — `CS.settings`, the bylaws row,
not `capDB()`, which answers for whichever rung a Pro is currently looking at
while editing (that mistake printed "best three" for a league storing two, and
the regression caught it). Four shapes:

| League | Sentence |
|---|---|
| solo, cap 2 | Every posted round scores. Your best two each month count toward **your season total** — a better round always replaces your lowest, in real time. |
| squads, cap 3 | …Your best three each month count toward **your squad** — … |
| Unlimited | Every posted round scores, and in this season **every one of them counts** toward your season total. |
| no season | Every posted round posts to your rounds. Join a season and it counts there too. |

Hierarchy: on a phone the empty 150×100 photo frame sat between the gross and
the course line, so the optional thing was the biggest thing above the primary
action. With no photograph attached the plate is a quiet full-measure row beside
the scan; the moment one **is** attached it takes its frame back. Both keep
their words and their 44. Nothing moves in the DOM and above 460 the
composition is untouched.

### WA6 · P2 · fixed — the receipt says one thing once

`gross − rating × 113 / slope` is grouped now: `(gross − rating) × 113 ⁄ slope`,
the way it is computed. The verdict stuttered because `vsPhrase` and `bandName`
are two names for one judgment and agree at two of the five bands; the band is
added only when it says something the phrase has not. While fixing it: only the
**band** had been put into the third person, so another golfer's round was
announced in the reader's voice. The whole sentence turns now, or none of it
does. Server figures and the vocabulary are unchanged.

### F1 · P1 · fixed — the phone's scheduled round is somewhere

Suppression was copied from the full desktop strip while the phone renders the
compact one, so the hidden sidebar "owned" the next round and both fallbacks
stood down. On the reviewed candidate the probe returns
`placesTheScheduledRoundAppears: []` at 390 with `my_next_round` in the set.
My own MW-02 comment claiming `#homeUpNext` carried it was wrong and is gone.
The set is derived from the slots the current width renders, and ownership
transfers explicitly: whatever **prints** the fact claims it, so the Up next
chip claims it on the phone and the tile stands down. Crossing 960 rebuilds the
chain. `my_money` leaves the phone's set with no consumer — the pot keeps its
own page and no money copy was added.

### F3 · P2 · fixed — the statement reflows instead of clipping

`.onboard` is a fixed overlay with `overflow-x:hidden`, so a document-level
overflow check prints PASS while the headline loses its end. The size is in
`rem` so enlargement actually reaches it (a px literal ignores the setting —
on the candidate the statement is still 42px at 200%), and a word longer than
the measure breaks rather than running past it. 2.625rem is 42px and 4rem is
the desk's 64, so the ordinary composition is unchanged.

**One visual consequence, named rather than hidden:** at 200% the statement
breaks mid-word (`ANYWHE / RE.`). Nothing is lost and the controls stay usable,
which is the acceptance; whether enlargement fidelity or shrink-to-fit is the
better trade at that size is a visual call, and shrink-to-fit would mean the
reader's text setting stops reaching this line. Capture is in the evidence
below.

---

## Evidence

```sh
npm run preflight                                   # PASS — 0 failures, 0 warnings
python3 -m http.server 8798 &
node tools/web-verify.mjs --url 'http://127.0.0.1:8798/?exit' \
  --widths <320|390|1440> [--height 560] --wait 1800 --eval "$(cat tests/<suite>.js)"
```

| Suite | 320 | 390 | 1440 | proves |
|---|---|---|---|---|
| `home-receipt-browser.js` **(new)** | passed | passed | passed | WA1, WA4, WA6 |
| `home-hierarchy-browser.js` (rewritten) | passed | passed | passed | WA2, F1, MW-02 |
| `you-credential-browser.js` **(new)** | passed | passed | passed | WA3 |
| `post-hierarchy-browser.js` **(new)** | passed | passed | passed | MW-05 |
| `brand-door-browser.js` (extended) | passed | passed | passed | F3 (+390×560) |
| `compete-start-browser.js` | passed | passed | passed | MW-01 |
| `compete-rows-browser.js` | passed | passed | passed | MW-03 |
| `home-function-browser.js` · `after-golf-repairs-browser.js` · `release-posting-browser.js` · `league-setup-browser.js` · `app-tests.js` | — | all passed | — | unchanged behaviour |

**Every repair fails on the reviewed candidate.** Served `8f85dac`'s own
`index.html` and ran the same suites against it:

| Suite | Message on `8f85dac` |
|---|---|
| `home-receipt-browser` | `WA1: the lead's receipt never opened` |
| `home-hierarchy-browser` | `WA2: the other league's season door never opened the season` |
| F1 probe (isolated) | `placesTheScheduledRoundAppears: []` at 390 → `["chip"]` here |
| `you-credential-browser` ¹ | `WA3: an unread career printed a zero: 0` |
| `brand-door-browser` | `F3: the statement ignored the reader's text size (still 42px)` |
| `post-hierarchy-browser` | `MW-05: a SOLO league is still told its rounds count toward a squad: …count toward your squad…` |

¹ the credential is a module-scope renderer, so this one was run against
`8f85dac` **plus the one-line `window.refreshWhoChip` bridge and nothing else**,
to separate the defect from the bridge the fix adds.

**Preview-origin checks.** `brand-door`, `compete-start` and `post-hierarchy`
were re-run against `https://deploy-preview-3--cupseason.netlify.app` itself at
390: all passed.

**Captures** (local, labelled fixtures, no account data):
`…/scratchpad/wa/{post,hist,door-big}.png` — the composer leading with the
score and printing the solo sentence; the standings history with three doors
and the bumped row intact; the door at 200% text. Earlier states remain under
`…/scratchpad/welcome/` and `…/scratchpad/caps/`.

**Console.** The harness still reports Netlify's collaboration-drawer
report-only CSP errors on the preview origin; those are tooling. One transient
`401` appeared in an early `post-hierarchy` run — entering the composer for
real logs, and with a fictional user and no session that write 401s. It is the
walk's artefact and is now stubbed in the suite, so a console error there means
the composer and not the harness.

---

## Still open

- **MW-04** (season page) and **MW-06** (setup copy/progress) — checkpoint B's
  remaining two. Not started; WA5 named them as pending and they stay pending.
- **Actual iPhone Safari** — safe areas, keyboard, VoiceOver, Dynamic Type.
  Everything above is Chromium at the stated viewports.
- **A signed-in walk on the preview origin** by me — not done; Codex's account
  walk is the signed-in evidence, and repeating it is the point of this handoff.
- **F3's mid-word break at 200%** — a visual call, described above.
- **Write paths** — no round, league, invitation or profile change was
  submitted from any tree in this pass.

## Handoff

Branch: `claude/mobile-web-integration`. Goal: repair WA1–WA6 and F1/F3 and
continue checkpoint B on the same preview. What changed: five product commits
and one test-only commit; no production state. Database deploy owed: none.
Edge deploy owed: none. Client deploy owed: none — the candidate is unpromoted
by design. Recommended next: Codex repeats the affected signed-in read paths on
`f79140b` at that preview URL — Home's lead and last-score receipts, both season
doors from Home and Compete, the You credential after a reload, standings
history → receipt, and the composer's sentence in a solo league.
