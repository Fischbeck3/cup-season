# idx-03 · `index.html` 3764–4577 — demo data, `state`, helpers, nav, live onboarding

Read every line of 3764–4577 (the head of the big classic block, 3764–13427).
Cross-checked against `spec/spec-v1.0.md` §14, `spec/decision-log.md` D40/D111/D126/D127,
`supabase/migrations/*`, and prod (read-only `supabase db query --linked`).

Session hunks inside the range (`git diff 34d20b6..HEAD`): 3743, 3750, **4138–4172**
(`humanError` + `looksLikeOurSentence`), **4193–4226** (`setRoomSeg` Q-12, the
`switchView` wizard gate Q-10), **4243–4258** (schedule back-link), **4534–4577**
(the `IN` badge and the D126/D127 climb note). Those got the harder read.

---

## What the range does

3766–3812 the demo diorama (`dAgo`/`isoAgo`/`M3` are all hand-built local dates —
the UTC-midnight landmine is correctly avoided). 3814–3853 `state`, the
`window.state` QA bridge, the stake/length/cap ladders, and an IIFE that stamps
a fake Sunday season frame onto `state.seasonStart/seasonEnd`. 3857–4105 the
splash reveal net, the comet heads, `csOdo`, the live-dot pulse, and the
desktop door wings. 4107–4170 `toast`/`stampPosted`/`esc`/`humanError`.
4172–4183 `enterApp`/`backToDoor`. 4185–4285 `setRoomSeg` + `switchView`.
4287–4308 the `.tap` a11y observer. 4310–4328 `gateLiveRound`. 4330–4577 the
series builders and the D26 climb ladder.

## Things I checked and cleared

- **The demo season frame can't shadow a real league.** The IIFE at 3846–3853
  writes `state.seasonStart/seasonEnd` unconditionally, but every real path
  clears them first: `enterLeague` calls `resetToBlank` (:14920 → :12378) before
  the season query, and `showWelcome` nulls them (:18010). `renderCalendar`'s
  `inLeague` guard (:12696) therefore never reads demo dates on a real account.
- **`state.demo` gating.** The one bare `CS` reference (:4219) is short-circuited
  by `state.demo ||`, and `state.demo` is `true` until the module runs, so the
  classic↔module boundary is not actually crossed early. Still an idiom break
  (see O-3).
- **Date helpers.** `dAgo`, `isoAgo`, `M3` and the season-frame IIFE all build
  ISO by hand with `getFullYear/getMonth/getDate` and `setDate(1)` before
  `setMonth` — no UTC shift, no month-overflow.
- **`climbOrd`** is correct for 11/12/13 and for 4+ (`['th','st','nd','rd'][n%10] || 'th'`).
- **`climbSpark`** cannot divide by zero: the `arr.length<2` guard covers
  `last.length-1`, and `Math.max(1, max-min)` covers a flat series.
- **`csOdo`** digit strips hold 0–9 twice, so `from + (((to-from)+10)%10)` is
  always a reachable offset; a missed `transitionend` leaves the strip on the
  duplicate bank, which renders identically.
- **`.view` is `display:none`** (:193), so the a11y observer's `tabindex="0"`
  stamping does not put inactive views into the tab order.
- **`#roomSeg` and the schedule back-link are static markup**, so the
  parse-time `addEventListener` at :4207 and the `[data-go]` binding at :13366
  both hold; setting `back.dataset.go` later works because the handler reads
  `dataset.go` at click time.
- **`renderClimb`'s HTML is escaped** — `esc()` on every name, `SQHEX[t.ci]` is
  a fixed palette, `CSS.escape` on the FLIP selector.
- **D127's `K=1` for squads2 is deliberate** on the server (`season_scenarios`,
  `20260716224500:64`: "both reach the Final; the race is the #1 seed (+10)")
  and `climbCut` mirrors it correctly. The bug is downstream — see B-2.

## Findings

**B-1 (P1, session) — the `draft` remap walks around the brand-new wizard gate.**
`:4234` sets `v='wizard'` nine lines *after* the Q-10 gate at `:4217–4225` has
already run. A `player`-role member in a `setup` league who taps the Clubhouse ›
League › "Squads · View" button (`data-go="draft"`, `:3570`, ungated, sub-copy
"OPENS AFTER SETTINGS LOCK" at `:12671`) lands in the Pro's bylaws editor with a
live Lock button — the exact D40 violation Q-10 was written to close.
`join_league` (`20260714040000:21`) has no phase check and the code box is
populated at creation (`:15633`), so a setup-phase member is one code-join away.
Prod today: 7 setup leagues, all single-member, so not live — but nothing
prevents it. Fix: re-run the gate after the remaps, or hoist the gate to just
above the `.view` toggle at `:4257`.

**B-2 (P1, session) — the climb note tells a two-squad league that one squad advances.**
`:4570–4574`. `climbCut` returns `K=1` for `squads2` as a *seed* threshold; the
new `seatLine` reads it as a *seat count* and prints
`TOP 1 ADVANCE TO THE CUP FINAL`, directly above `endgameLine`'s "The top 2
squads seed into a four-week Cup Final… The leader carries +10 in." Spec §14
(`spec-v1.0.md:179`, `:246`) is explicit: at 2-squad scale **both** reach the
Final. Live for 5 of the 18 leagues in prod (`structure='squads2'`,
`finish='cup_final'`). The demo gets it right (`climbCut(null)` → K=2 → "EVERYONE
ADVANCES") while real squads2 leagues get it wrong — two producers of one number.

**B-3 (P2) — the `'CUP LINE'` stake label is dead, so every squads3/4 and solo
league calls the last Cup seat "the top seed".** `:4499–4501`. `climbCut` only
ever emits `'CROWN LINE'`, `'TOP SEED · +10'` and `'CUT LINE'`; `'CUP LINE'`
appears nowhere else in the file. A squads4 Pro sitting 3rd reads
"12 back of Mudsharks — the top seed" when 2nd is the last seat in the Final.
10 squads4 leagues in prod.

**B-4 (P2, session) — `looksLikeOurSentence` leaks GoTrue jargon into the
sign-in screen, ungrammatically.** `:4156`, `:4164–4170`. The canonical expired-OTP
message `Token has expired or is invalid` matches nothing above it
(`invalid.*token` needs "invalid" *before* "token") and clears every shape gate,
so `:15894` renders **"Code didn't take. Token has expired or is invalid Codes
expire with resends, use the newest email."** — no punctuation between the raw
message and the trailing sentence, and "Token" is precisely the vocabulary F-003
exists to suppress. Before this session it fell to the shrug and read cleanly.
The header comment claims the test checks that a sentence "ends like prose";
there is no end check.

**B-5 (P2) — `permission denied` → "Please sign in again" turns the documented
missing-grant failure into an unbreakable loop.** `:4134`. D37 requires an
explicit `grant execute … to authenticated` on every new RPC; when one is
missed PostgREST returns `42501 permission denied for function …` and the Pro
is told to sign in again, signs in, taps, fails identically. CLAUDE.md names
this class ("a new RPC that silently 403s in prod is almost always a missing
grant"). Same for `new row violates row-level security policy …` — the user is
signed in and simply isn't allowed. Both belong in the deploy-skew branch.

**B-6 (P3) — `humanError` shrugs the one server message written for support.**
`delete_account` raises `Could not delete your account: something still
references it (posts.posts_league_id_fkey). Nothing was changed — screenshot
this and send it in via Feedback.` (`20260717205347:96`). The `_` in the
constraint name trips the `[_{}<>]` gate at `:4168`, so `:14411` toasts
"Could not delete the account. Something went wrong — please try again." and the
instruction to screenshot it is destroyed.

**B-7 (P3, session) — four allowlist alternatives match nothing, one is duplicated.**
`:4145`. `isn't open yet`, `is still being set up`, `has wrapped` and
`season is finished` appear in no migration and no edge function (verified
repo-wide); `is empty — draw again` is listed twice. The regex reads as
coverage for the D120/D122 stage guards, which do not exist server-side — so a
Pro who trips a stage guard still gets the shrug.

**B-8 (P3) — `durLabel` collides 8 wk and 10 wk on "2 mo".** `:3836` + `:7592`.
`#lenVal` (`:3281`) is the stepper's only readout, so `+` from 8 → 10 weeks
leaves the control apparently frozen. (`#seasonSpan`'s dates do move, which
softens it.)

**B-9 (P3, session) — D127's hollow-Final warning fires on the demo diorama.**
`:4574`. `climbCut(null)` → K=2, demo n=2 → "EVERYONE ADVANCES — 2 CONTENDERS,
2 SEATS" plus "Every contender already has a seat, so the Final is a formality
until more golfers join." on the app's showcase surface.

## Opportunities

- **O-1 — one producer for the seat sentence.** `climbCut(meta).K`,
  `seatLine` and `endgameLine`'s `seats` (`:5928`, a `structure === 'solo' ? 2 :
  (structure === 'squads2' ? 2 : 2)` that is literally always 2 and never reads
  `meta.k`) are three independent statements of the same rule. D126 §1 asked
  `endgameLine` to read `climbCut(meta).K`; it doesn't. Collapse to one
  `endgameShape(meta)` returning `{K, seats, cutLabel, stakeLabel, sentence}`.
- **O-2 — gate `humanError`'s passthrough on a marker, not on prose shape.**
  Prefix our golfer-facing `raise exception` strings (e.g. `CS: `) or stamp an
  errcode, strip the marker client-side, and delete `looksLikeOurSentence` and
  the hand-maintained allowlist together. That removes B-4, B-6 and B-7 at once
  and makes new server sentences work without a client change.
- **O-3 — `CS.league` / `CS.member` at `:4219` should be `window.CS?.`** per the
  CLAUDE.md bridge rule; the same function uses `window.CS?.league` twenty lines
  later (`:4278`). Safe today only because `state.demo` short-circuits.
- **O-4 — `const SQ` (`:3782`) is dead** (zero references file-wide) and
  `typeof openBoardFull==='function'` (`:4233`) is a dead guard on a hoisted
  same-block declaration; if it ever *were* false the tap would be a silent
  no-op, because `:4233` returns before the `.view` toggle.
- **O-5 — a lock test for the gate.** The Q-10 gate has telemetry
  (`wizard_gate_bounce`) but no test; a check that walks every route that can
  end at `v==='wizard'` would have caught B-1 in the same session that
  introduced the gate.

## Not assessed

The wings/comet/odometer animation IIFEs (3857–4105) were read for correctness
but not visually verified — no browser was driven. `openBoardFull`,
`primeRealRoster`, `renderProChip`, `renderHomeHub`, `renderCalendar` and
`endgameLine` were read only far enough to judge the call sites in this range.
