# idx-08 · `index.html` 8479–9944 — the rest of the live round, and the home stat strip

Read line by line: 8479–9944 (the D85 classic side ends at 8479; the slice picks up at
`holeDone`/`netOf` and runs through the demo `#finishBtn`). Also read, as context for
call sites: the live globals and engines above the slice (7695–7790), the resume/snapshot
layer (7940–8250), `renderStats` (9944–10078 — the prompt named `#statFinal`, whose sort
sits just past the nominal boundary), `finish_live_round` and `start_live_round` in
`supabase/migrations/20260829090000_leagueless_live_rounds.sql`, and D74/D75/D77/D78/D79/
D107/D108/D126 in `spec/decision-log.md`.

**Session code in this slice: none.** `git diff -U3 34d20b6..HEAD -- index.html` produces
hunks at new-file lines 8162–8174 and then nothing until 10166. The `[live-resume]` FK fix
(commit `7765eb7`, M-085) is at 8162–8174, immediately *above* the slice; I checked it
anyway because the brief asked:

- The hint is **correct**. `live_round_players_live_round_id_fkey` is the real constraint
  name — `supabase/migrations/00000000000000_initial_baseline.sql:1796` declares it, and
  the ambiguity the comment describes is real (`game_results_live_round_id_fkey` at :1761
  and `live_scores_live_round_id_fkey` at :1831 both give PostgREST a junction path).
- The skew ladder is **still right**, and is now the good pattern: `_sel(true,true)` →
  `_sel(true,false)` → `_sel(false,false)`, retrying on **any** error rather than sniffing
  the message. That is the 42501 lesson applied. The two skew retries *inside* my slice
  (`start_live_round` at 9527 and `finish_live_round` at 9701) still sniff
  `/p_config|function|schema cache/i` and `/p_result|function|schema cache/i`. In both
  cases the miss they guard is a "function not found in the schema cache" PostgREST error,
  whose text does contain `schema cache`, so they fire today — but they are the older,
  weaker shape and are worth converging on the resume ladder's.

---

## What the engines get right

I tried hard to break the maths and mostly failed. Recording the passes so a later
auditor does not re-walk them:

- **Skins** (`skinsCalc`, 8657–8676). Carry starts at 1, resets on an outright low net,
  increments on a tie; `carry-1` at the end is exactly the number that died. The ledger
  `pts = won*n − total` is algebraically `won*(n−1) − (total − won)` and sums to zero for
  any n. Correct, and correct for 2, 3 and 4 players.
- **Sunningdale 2-side** (`sunnEngine`, 8678–8702). `dA = max(0, (b−a)−1)` is D74's rule
  verbatim: 2 down → 1 stroke, 3 down → 2. The bank only moves on a win taken *while
  strictly ahead* (`if(a>b) bank++`), signed so one counter holds both owners. Strokes
  after `closed` are zeroed. `sunnStrokesAt(h)` truncates the card to `k<h` and re-runs the
  pure engine — deficit *entering* the hole, which is the right quantity.
- **Sunningdale solo** (`sunnSoloEngine`, 8704–8714). The bank's single-owner walk through
  zero is implemented as written; `outright` is computed after the increment.
- **Round robin** (`rrCalc`/`rrRecords`/`rrResult`, 8768–8825). Every pairing is
  independent, halves move nothing, and D79's `pts = w − l` really is net-zero by
  construction, so reusing `settleTransfers` is sound.
- **Wolf comeback** (`wolfAt`, 8503–8512). `h < liveHoles()−2` → rotation; the last two go
  to last place. On a nine that is holes 8–9, on eighteen holes 17–18, as the comment
  claims. The apparent recursion (`wolfAt` → `wolfPointsThrough` → `wolfAt`) bottoms out at
  depth 2 because every hole below `H−2` answers from the fixed order.
- **`holeLedger`/`renderHoleStrip`/`holeHighlights`** (8558–8626). The `hot == null` checks
  are `== null`, not falsy — so player index 0 survives as a legitimate hot key. That is
  the kind of thing that usually bites; here it was done right in all four callers.
- **`guestTokens` keying.** `state.live.guestTokens[pl.position]` (9525) is read back as
  `L.guestTokens[x.i]` (9866) — a 0-based LIVE index against a server `position`. I checked
  the RPC: `v_pos int := 0` (`20260829090000:101`), so positions are 0-based and the keys
  line up. No off-by-one.
- **Local-date discipline.** `renderPlanBridge` builds `todayISO` by hand (8896–8898) and
  `renderStats`' month math constructs `new Date(y, m+1, 1)` rather than parsing a string.
  The UTC-midnight landmine is respected throughout the slice.

## What is wrong

Eleven bugs and eight opportunities, detailed in the structured findings. The ones I would
fix first:

1. **Wolf's ledger stops summing to zero when the comeback wolf turns out to be the player
   the previous wolf already picked** (8529). `side = [w, pick.partner]` becomes `[w, w]`,
   `opp` widens to three, and the hole pays ±2 against ∓3. `settleTransfers` then walks a
   credit list and a debit list that do not balance and silently drops the tail payment.
   The comeback wolf is *recomputed from live standings on every render*, so any score
   correction on an earlier hole can re-assign holes 17/18 onto the stored partner. This is
   the only place in the slice where money can go missing.
2. **`renderLiveBanner` labels match-play sides by slot order** (9402–9403) while
   `matchCalc` scores `MTEAMS`. In singles it prints `" & "` as one side's name; with a
   swapped court (`PAIRINGS[1]`/`[2]`) it announces the wrong pair as leading. The
   identical bug was found and fixed inside `renderPlay` — the comment at 8993 says so in
   as many words — and the banner was missed.
3. **Home renders two live banners.** `#resumeBanner` (D85/D86, 8247) has no phase gate;
   `#liveBanner` (9393) shows whenever `state.phase==='season'`, and `#homeSeason` is
   `display:flex` for exactly that case (12639). A member with a live round sees both, with
   different copy — and on someone else's round one says "Marcus put you on the tee sheet ·
   JOIN" while the other says "Live round in progress". `#liveBanner` also has no
   Sunningdale branch and falls back to a blank "SCORING LIVE", and defaults a blank course
   to the demo's `'Encanto GC'` (9418) on a real account.
4. **The finish sheet undercounts a league round's app-golfer guests and promises them a
   claim link the server will not mint** (9676, 9679). The server posts any seat with
   `guest_profile_id` straight to that profile whenever the card is complete and rated —
   league or not (`20260829090000:322–346`) — and returns it in `posted`, never `guests`.
   The client's `_lg ? !x.p.guest : (!x.p.guest || x.p.pid)` is the S6-01 mismatch again,
   pointing the other way.
5. **The tee-off strokes preview does not halve the course handicap for a nine** (9232).
   `recomputeStrokes` does (7746). The first-tee argument §2.2 exists to settle is settled
   with numbers the round then contradicts.
6. **`#statFinal` computes the week close as "the next Sunday" and labels it "Sun"**
   (9990–9992) while `currentWeek()` in the same file counts weeks from `seasonS()` (12436)
   and D108 states weeks roll on the league's real first-tee weekday. `seasonSpanText()`
   already carries a comment about this exact regression surviving the v1.1 flexible-start
   fix — it survived here too. The sibling line says "floors assessed" in months where the
   partial-month waiver applies, contradicting `#nextTxt` thirty lines below it in the same
   function.

## Cross-range causes worth naming

- **`.step button{width:36px; height:36px}`** (`index.html:735`). The score stepper is the
  most-tapped control in the product — two adjacent 36px targets, 2px apart, used
  one-handed in sunlight. Under both WCAG 2.5.5 and Apple's 44pt floor. The markup that
  consumes it is in-slice (8963–8967); the size is not.
- **`applyServerRound` sets `guestTokens:{}`** (~8090) and the resume query's column list
  (8172) does not select `claim_token`. That is why the in-slice group sheet says "No
  guests in this round." on a fresh-device resume.
- **D126's "three homes" for `endgameLine()`.** The function exists at 5923 and is
  referenced at exactly one call site, the climb note at 4573. Neither the hero's season
  branch nor `#statFinal`'s pin — both named in the recommendation and both restated in the
  commit body — was built. The decision log reads as though the endgame is now visible
  everywhere a standing is; on the Season tile it still renders on one day in 155 by
  D126's own arithmetic.

## Deliberate, not bugs

- The `+`/`−` stepper's first tap writing `PAR[h]` rather than `PAR[h]±1` (8973) is the
  golf-scoring convention, not an off-by-one.
- `netParThru`'s `noH` branch (9139) reporting to-par under a "net" label for Sunningdale
  is correct: D74 says the game is scratch, so net *is* to-par there.
- `rrCalc` netting every pairing off the **group's** low man rather than each pair's own
  low man is stated in the D75 comment at 8768 and is a rules choice.
- `settleRows`' `esc()`ing of every name, and `showLiveRecap`'s `esc(money)` around the
  transfer strings, are correct — no unescaped user text reaches `innerHTML` in this slice.
