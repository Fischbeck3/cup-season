# Home Arc — the state-machine home + orientation (D81 · D82)

2026-07-27 · design settled over the fold audit, the ground-truth mapping,
and three artifact rounds. This doc is the build contract; the decisions and
their conflicts live in `decision-log.md` (D80–D82). Client-only — **no
migration anywhere in this arc.**

## 1 · The shape

```
#view-home
  notifBanner · resumeBanner · homeRequests     (unchanged, top)
  HERO SLOT        one card, dispatched on state (§2)
  OCCASION CARD    only when a calendar window is open (§4)
  upNext chips     unchanged (hides when empty)
  "Around your buddies"                          (eyebrow 1)
  homeDigest + homeFeed                          (merged stream, WHOLE — see
                                                  D81 correction: it is not
                                                  the board and never crops)
  "Upcoming golf"                                (eyebrow 2)
  homeRounds       the tee-sheet rows, weather-enriched (§7 R3)
  quiet row        "Start a league · Join with a code" (members only; the
                   league-less get the ladder hero instead — no doors block)
```

DELETED: `renderGreeting` (and its div), `homeRecap` + "Your leagues"
eyebrow (Clubhouse switcher owns it), `renderHomeStart`'s unconditional
grid, `homePulse` as a separate card (the floor gauge folds into the season
hero's foot), the `order:-1` rail flip at index.html:915, two of four
eyebrows. `homeRounds` KEEPS its rows, retitled "Upcoming golf", moved
below the feed.

KEPT UNGATED: requests, resume banner, upNext, digest+feed, ClubGroups sync.

## 2 · The hero dispatch

One function, `renderHomeHero()`, first in the hub chain. Dispatch order —
first match wins:

| # | Condition (all data already in memory) | Hero |
|---|---|---|
| 1 | any membership with `league.phase==='complete'` and no active one | **The record** — position + purse (champagne, `--gold`), "Season recap →", run-it-back button |
| 2 | active league, `seasons.status==='cup_final'` | **The seed** — seed # + "up N" + weeks left, ember |
| 3 | active league, `state.phase==='season'`, past starter | **The standing move** — rank (`scenarios.rows[].rank`), gap (`teams[i-1].pts - teams[i].pts`), arrow (`priorRank` from `seasonHistory`, omissible), cause line; floor bar in the foot (replaces the pulse card); rank 1 renders champagne |
| 4 | active league, phase `setup`/`draft` or pre-starter | **Countdown** — days to first tee + roster fill bar |
| 5 | no league, buddies ≥ 4 | **"Four makes a league — you have N"** + Start/Send-link |
| 6 | no league, rounds > 0, buddies 0 | **"Established. Nobody's seen it."** + Find your buddies |
| 7 | no league, rounds 0 | **"Three rounds and your index goes live"** + 0-of-3 bar + Post CTA |

Rung 4b (weekend clustering → "that's a Major") ships as an *occasion-card
variant*, not a hero: if ≥4 distinct golfers in `watchAll` share a `play_on`
within 7 days, the occasion slot offers the Major regardless of calendar.
Clustering beats calendar when both fire.

Standing-move copy states (state 3): moved up · moved down · held (points
forward: "beat your number by N Saturday and you take 2nd") · week 1 / no
snapshot (movement chip simply absent). Ties use `rank()` semantics (1·1·3).

## 3 · Data sources (all verified this session)

| Fact | Source | Status |
|---|---|---|
| rank / ties | `window.scenarios.rows[].rank` (server `rank()`) | fetched today |
| gap to next | `teams[]` — all squads fetched | expression ships at 4046 |
| movement | `window.seasonHistory` latest snapshot | copy-ready at 4150 |
| floor | `window.leaguePulse` | fetched today |
| buddy count | `my_friends` accepted — **currently discarded** at 14977 | one line |
| rounds/index | `window.career`, `CS.profile` | league-less safe |
| buddies' plans | `window.watchAll` (loads league-less too) | fetched today |
| weather | `weather` Edge Fn — `lo/wind/summary/icon` **discarded** at 9461 | free |
| purse/record | `careerRec` (`earnings_cents`, cups, runner_ups) | fetched today |

NOT built on (cut in design, recorded here so nobody re-adds them casually):
partner history (prod: 0 scan_claims, 3/52 tee-sheet rounds), "buddy has no
league" (RLS-invisible; needs a definer RPC + a privacy call), real majors
*names* (famous-golf-wing rule: every nod oblique, never named).

## 4 · The occasion table

Client constant, ~6 windows, oblique copy only. Widened edges so the card
doesn't blink for a twice-a-week user. Clustering (§2) may preempt.

| Window | Eyebrow | Headline | Offers | Wink |
|---|---|---|---|---|
| Mar 28 – Apr 13 | The first one of the year | "Azaleas are blooming somewhere." | a Major | The Azalea marker art |
| Jun 8 – 22 | The hardest test | "Somewhere out there, par is winning." | a Major | No. 2 |
| Jul 10 – 24 | The oldest one | "Links weather is a state of mind." | a Major | The Jug / Postage Stamp |
| Sep 18 – Oct 5 | The big team match | "Two teams. One cup. You know the one." | the Ryder | two-pennants SVG |
| Oct 1 – Nov 20 | The season's turning | "Cool mornings, empty tee sheets." | a fall Major | — |
| Dec 27 – Jan 15 | A fresh table | "Nobody's ahead yet." | league / run-it-back | — |

Sep window covers the team match in every year without naming which one —
no year logic. Copy above is DRAFT for redline in this review.

## 5 · Orientation (D82)

- **Screen:** after golfer-card save, before first Home. Two teachings only:
  the four places (grid of 4 mini-cards) and long game vs short game (the
  switcher's own copy + two 12-segment bars). Buttons: "See it with a live
  season" (existing demo), "Take me in" (skip). Footer: "Reopen any time
  from You."
- **Guide:** "How it works" group on the You tab — six rows: The four
  places · Leagues vs events · Posting: basic and live · Buddies, invites
  and claims · How scoring works (existing `openScoringHelp`) · Peek at a
  live season (existing demo). Each row opens a sheet; copy verbatim from
  the shipped labels (never "the Post tab" — it's "the ⊕ in the middle").
- **Flag:** `localStorage.cs_oriented` — no migration. Fresh device may
  re-show; acceptable.

## 6 · Telemetry

`client_events` (authenticated insert verified). Log: `home_hero_tap`
{state, cta} and `home_occasion_tap` {window}. Impressions: one
`home_hero_state` row per session (not per render). Errors keep the 4-frame
stack rule.

## 7 · Build order & verification

1. **R1 subtraction** — deletions + gating + eyebrow merge. Verify: fold
   screenshot per state, console clean.
2. **R2 dispatcher + heroes** — states 7→1 in that order (league-less first;
   they're pure client and testable signed-out against demo=false stubs).
3. **R3 warmth** — occasion table + clustering, weather line on tee-sheet
   rows, telemetry.
4. **R4 orientation** — screen + guide + flag.
5. **Verify** on 8642 with SW+caches cleared, both themes, `?exit` resets;
   states forced via a dev override (`window.CS_HOME_STATE`) that demo mode
   ignores; the one known boot rejection is the only allowed console noise.

Landmines that apply: classic↔module bridge (`window.*` checks), mixed
middot encodings (anchor edits on ASCII lines), `new Date('YYYY-MM-DD')`
UTC trap (use `localDate`), demo-mode gating (`!state.demo` on every real
read), no hand-edits to the version line.
