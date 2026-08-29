# T4 — The first round tells the truth

*Remediation plan for TOP-4 of the blind UX audit (2026-08-29). Theme prefix `T4`.
Every file:line below was re-read against the working tree at `34d20b6` (== HEAD,
branch `native/m0-foundation`) on 2026-08-29. This is a PLAN: nothing in
`index.html`, `supabase/`, `apps/ios/`, `spec/` was edited. Rule 5 applies —
the four mechanic/IA changes are drafted as PROPOSED decision-log entries and
nothing that depends on them is built until the owner says so.*

**Closes (audit ids):** M-040 · M-043 · M-044 · M-045 · M-046 · M-047 · M-048 ·
M-049 · M-076 · M-080 · M-159 · M-160 · M-077 · M-086 · M-087 · M-093 (logged,
not built) · M-132 (partial) · M-150 (iOS composer) · Appendix A #2, #4, #5, #10, #20.
**Leaves to other themes:** M-042 (the floor/month chip on Home — T3's hero and
tiles), M-041 (league-stage label table — T3), M-050/M-051 (starter-index
precedence — see Open question 5), M-052 (index-scaled bands — a gameplay
decision, not a truth defect), M-121 (index delta — You/Board), M-090 (scrap —
live lane).

---

## 0. What is actually wrong (verified)

The audit's diagnosis holds line for line. There are **three scoring engines**,
**two definitions of "season"**, and **one phrase producer that reaches a third
of the surfaces**:

| Engine | Where | Allowance | Window | Points rule at −1.0 |
|---|---|---|---|---|
| `v_rounds_ranked` — the spec | `00000000000000_initial_baseline.sql:1347–1391` (playing_index `:1359`, pvi `:1360`, points `:1361–1364`, season join `:1370` — `played_on between starts_on and ends_on`, status in active/cup_final/complete) | league's `handicap_allowance` (95 under Standard) | yes | `cup_points` `:247–257` — `> -1 → 7`, so −1.0 → **6** |
| client preview `recalc()` | `index.html:6306–6346` — `vs = state.myIndex − diff` `:6315`, `pointsFor(vs)` `:6316`, signed `:6339` | 100% | none | `pointsFor` `:5693–5699` — `vs>=-1 → 7`, so −1.0 → **7** |
| feed / You / career / receipt fallback | `home_feed` `20260723090000_home_feed_photo.sql:51` (`index_at_post − differential`), `tour_card` `20260726190000_tour_card_form.sql:51,67`, client `:11547`, `:11578`, `:16641–16642` | 100% | none | n/a |

Consequences the personas hit, each with its cause:

- **"LEAGUE POINTS THIS ROUND 12" a week before first tee (M-040).** Static heading
  `:3191`, unconditional "No league yet?" `:3198`, no window in `recalc()`. The
  season-window predicate exists only inside the post handler (`:6588–6594`,
  commit `75682a1`) and gates the ceremony alone (`:6186–6192`). The Home hero
  keys on `state.phase==='season'` (`:10076`, "Rounds count from today." `:10105`)
  while the Clubhouse keys on `atStarter()` (`:11981–11984` → `:12218–12227`).
  **The rule itself is unlogged**: no sentence in spec §14 or the decision log
  says a pre-season round scores nothing. `round_epilogue`
  (`20260716210000_named_rivalries.sql:174–176`) reads `v_rounds_ranked`, so the
  epilogue's band row is *also* silent pre-season (no ranked row → no pvi row).
- **Sign inverted (M-045).** `vsPhrase()` `:5709–5714` has D1's words and reaches
  the ceremony (`:6184`), the epilogue (`:6094`), the Home feed (`:10437`) and the
  share card (`:5797`, `:5816`, `:17727`). Everything else prints
  `(x>=0?'+':'')`: the form `:6339`, You career `:11341–11347`, standings
  `:11401`, `:11418`, `:11440–11443`, `:11465`, member history `:11478`, `:11481`,
  the receipt verdict `:11519`, finalist receipt `:4566`, `:4578`, duel sheets
  `:12495–12503`, tour card `:13560`, demo receipts `:11830–11913`. iOS mirrors
  the leak: `RoundStoryCard.swift:77–79` (`pviChip`), `SeasonStats.swift:36–37`,
  `Career.swift:42`, `TourCard.swift:107`, the composer chip
  `PostRoundScreen.swift:402`.
- **One round, two numbers (M-047, M-049).** Home card "beat your number by 3.3"
  is `home_feed` at 100%; the receipt's "+2.6 · 9 PTS" is `round_card` at 95%
  (`20260729180000_round_card.sql:105–110`, `:128–133`). The receipt prints the
  raw `index_at_post` (`:11513–11515`) beside a 95%-applied verdict and never
  renders the `playing_index` it already receives; only the **demo** receipt has
  the "Index × allowance" row (`:11912`). Spec §16 (`spec-v1.0.md:264`) requires
  the allowance snapshot on receipts; D2 says allowance is "visible only inside
  receipts" — the receipt is exactly where it is missing.
- **"+0.0 — PLAYED TO IT" for a golfer with no number (M-048).** `score_round()`
  (`20260716100000_handicap_engine.sql:85–88`) falls back to
  `index_at_post := differential`. For a golfer with no starter this is every
  round until `handicap_index_asof` establishes (3 rounds) — i.e. the engine has
  quietly re-created the flat 7 that D49 retired. The client meanwhile carried a
  blind 18 (`:15110` `|| 18`; iOS `PostCalc.fallbackIndex = 18` at
  `PostCard.swift:194`) so the preview said "−9.8". D49's "provisional" badge:
  zero occurrences in `index.html`.
- **Receipt stops short (M-044, M-080).** `roundCardBody` `:11495–11530` renders
  Points only when `r.points!=null` (`:11520`) — pre-season that is a silent
  null, not a sentence. No League row, no allowance row, no correction control;
  delete exists only as an unlabeled ✕ on You (`:11353–11369`, native
  `confirm()` at `:11360`).
- **Blank date (M-159).** `resetPostComposer()` `:6845–6858` clears `inDate`
  (`:6846`); today is set only at boot (`:12973`); the payload sends
  `played_on: value || null` (`:6501`); `rounds.played_on` is NOT NULL
  (`baseline:1251`); `humanError`'s constraint branch (`:4116`) yields "That
  didn't go through — please try again." under the `'Post failed.'` prefix
  (`:6640`). iOS `PostCard.startOver()` (`PostCard.swift:111–114`) sets
  `date = nil` while the model's `day` (`PostRoundModel.swift:19`) keeps the old
  pick — the payload omits `played_on` (server defaults to today) while the
  picker still shows the old day.
- **Placeholders read as values (M-076).** `#inRating placeholder="72.1"`
  `:3123`, `#inSlope placeholder="128"` `:3124`, nines "41"/"43" `:3156–3157`;
  `recalc()` runs with `rating=0`, `slope=113` and Post stays enabled; only the
  ceremony has the `|vs|>30` sanity gate (`:6183`). iOS: `PostRoundScreen.swift:193–194`
  same placeholders; M-150 "Post round" is full orange on an empty card.
- **Course search 502s swallowed (M-160, M-077, M-086).** `:6957` invoke →
  catch `:6964–6968` hides the dropdown when the cache is empty; tee cache
  `:6909` `.catch(()=>{})`. The function (`supabase/functions/courses/index.ts`)
  has no fetch timeout (`gca()` `:44–57`) and turns any upstream failure into a
  502 (`:287–291`). iOS `CourseSearchModel.run` (`DeclareRoundSheet.swift:313–327`)
  turns a failure into "No match — type the course…" (`PostCourseSearchField.swift:31–33`),
  which is a lie when search is down.
- **One phone attests four cards (M-093).** `finish_live_round`
  (`20260829090000_leagueless_live_rounds.sql:261`; member insert `:371–378`,
  visitor insert `:333–338`) inserts every seated member's round with
  `attested = true` from whichever phone finished. Spec §6 (`:149`) says
  "a playing partner taps confirm"; §13.1 (`:224`) says a live group is
  "attested by construction". D85 made every phone a scorer, but nothing checks
  that the golfer's own phone was ever in the session. `rounds` carries no
  `posted_by`; `attestations.attested_by` is free text (`baseline:874–879`).

---

## (a) DECISIONS NEEDED

The last logged entry is **D110** (+ addendum, `spec/decision-log.md:4090–4114`),
so these are **D111–D114**. Drafted in the log's format and voice; append after
the D110 addendum. They are PROPOSED — talk first.

### D111 · A round scores for a league only inside its season window — the rule is written down
*(2026-08-29, from the blind UX audit TOP-4. Mechanic level: the rule already
IS the engine; this entry logs it so a phrase family can exist. Sources:
`v_rounds_ranked` baseline:1370, post handler index.html:6583–6594, commit
`75682a1`, audit M-040/M-043, R10 in `rules-and-mental-model-audit.md`.)*
- **Current:** `v_rounds_ranked` joins `seasons` on `played_on between starts_on
  and ends_on` (status active/cup_final/complete), so a round dated before
  first tee — or backdated outside the window, or posted by a league-less
  golfer — earns no league points and never appears in a standings row. It
  still lands on the golfer's Tour Card and feeds the handicap engine. No
  sentence in spec §14 or this log says so; the pilot fix (2026-07-24) encoded
  it at the finish screen ("COUNTS ON YOUR CARD") and nowhere else.
- **Problem:** six of six audit posters were promised "LEAGUE POINTS THIS ROUND
  5/6/12" seven days before first tee, saw "R 0 · Pts 0", and were told "post
  one and you're on the board" by their own row. Home said "Rounds count from
  today" while the Clubhouse said "practice rounds hit your card, not the
  season". Every surface improvised because there was no canonical phrase.
- **Recommendation:** add to spec §14.1: *"A round scores for a league only if
  its date falls inside that league's season window; it is scored at the
  league's allowance. Rounds before first tee — or outside the window — post to
  your Tour Card and build your number; they earn no league points."* One
  phrase family derives from it and is the ONLY copy used for the state:
  · before first tee: **"Practice — season starts Sat Sep 5. This round builds
  your number; no league points yet."** (weekday derived, §14.0 v1.1)
  · backdated/after: **"Outside the season window — on your Tour Card, no
  league points."**
  · no league: **"On your Tour Card — join a league to score it."**
  "Builds your number" is said only when `profiles.index_source` is `app`
  (or null); a golfer whose typed/GHIN starter sticks (`round_refresh_index`,
  handicap_engine:100) hears "on your Tour Card" only.
  The form, the finish ceremony, the epilogue title, the receipt's League row,
  the standings empty state and the You tab all read the phrase from the one
  producer (T3's `seasonState()`; T4's `roundCounts()` adapter until it lands).
- **Principle served:** §16 (no figure without its work — "0" is a figure);
  #2 Low Friction (one rule, one sentence); the no-tutorial success metric.
- **Benefit:** the first post stops breaking a promise; Home, Clubhouse, form,
  card and receipt say the same thing on the same day.
- **Tradeoffs:** the pre-season "12" was a small dopamine hit — kept as the
  band phrase ("beat your number by 3.3") with the points withheld; multi-league
  members get one line per league where it matters (receipt), the open league
  elsewhere (D81/D94).
- **CONFLICT:** none upward. Related, unchanged: spec §9 ("posts accepted 7
  days after play, later needs override") is not enforced anywhere and stays
  a separate open item; D47 ("card" never unqualified) is honoured — the phrase
  says **Tour Card**, never "your card".

### D112 · One PvI per round — the league lens everywhere, the preview included
*(2026-08-29, from TOP-4. Mechanic-adjacent: spec §2.1 defines PvI as
`Playing Index − Differential` with `Playing Index = Index × Allowance`; this
entry makes every surface obey that definition. Sources: baseline:1359–1364,
home_feed_photo:51, tour_card_form:51/67, round_card:128–133,
index.html:6315, 11547, 11578, 16641; audit M-047/M-049/M-046.)*
- **Current:** the server view scores at the league allowance; the client
  preview, the Home feed, You/career, the Tour Card and both receipt fallbacks
  compute `index_at_post − differential` at 100%. Under Standard (95%) a
  ~13-index gets two numbers 0.7 apart for one round, which straddles a band:
  the owner's Aug 16 round is "beat your number by 3.3" on Home and "+2.6 ·
  9 PTS" on the receipt. The bylaws print "HANDICAP ALLOWANCE 95%"
  (`:12090`) and no calculation ever shows it acting. `pointsFor(-1.0)` = 7 on
  the web, `cup_points(-1.0)` = 6 on the server (`BoardTests.swift:16–21`
  documents it; iOS already follows the server).
- **Problem:** §2.1's "universal currency" has two values; the receipt's
  arithmetic does not close; the only mid-season tester read the split as a
  rigged table ("I beat it by 3.3, why 9?"). A Pro who cannot reproduce a
  points figure by hand will not keep the league.
- **Recommendation:**
  1. **The lens rule.** A round's displayed PvI, band and points are the league
     lens (`v_rounds_ranked`) whenever the round ranks in the league being
     viewed; the 100% number appears only for league-less/out-of-window rounds
     and is then labelled ("vs your number · no league lens"). Where one
     surface shows one league (Home feed, You this-season, standings) the lens
     is the viewer's open league (D81/D94); the receipt shows a League row per
     league the round ranks in.
  2. **Server:** `home_feed(p_days, p_league default null)` returns the lens
     pvi/points and a `lens` field; `round_card(p_round, p_league default null)`
     returns `playing_index`, `handicap_allowance`, `league_name`, `season_state`
     and picks the viewer's shared league rather than `order by month_rank
     limit 1`. Both param additions default (deploy-skew rule); the old
     `home_feed(integer)` overload is dropped so `{p_days}` still resolves.
  3. **Client preview:** `recalc()` scores `state.myIndex × ALLOW[state.preset]/100`
     (the constant the bylaws already print, `:12037`) inside the window; the
     panel gains one quiet arithmetic row **"Index used 14.2 × 95% = 13.5"**.
     No `preview_round` RPC for v1 — the preset and dates are already in state,
     and a round-trip per keystroke buys nothing the constant does not.
  4. **Bands:** `pointsFor`/`bandName` adopt `cup_points`' half-open edges
     (`> -1`); one `BANDS` table renders the form, the help sheet and the
     iOS composer with §2.2's ranges and the unit stated once.
- **Principle served:** §2.1/§2.2 verbatim; §16; D1/D2 (words on the card,
  arithmetic in the receipt).
- **Benefit:** one number per round on every screen; the receipt's arithmetic
  closes (`13.5 − 16.1 = −2.6`); a Pro can reproduce a points figure by hand.
- **Tradeoffs:** `home_feed`/`round_card` re-created (two migrations, both
  skew-safe); league-less lifetime stats keep 100% and say so; a member of two
  leagues with different presets sees the open league's number on Home and
  both on the receipt — accepted, that is what "lens" means.
- **CONFLICT (named, resolved):** D2 says allowance is "visible only inside
  receipts". The form's "How this round scores" panel (`:3189–3199`) IS the
  receipt-in-advance — the arithmetic row lives there as a `.sub` row, quiet,
  and never on the posted card or the feed. D8/D48 untouched: printing the
  snapshot is §16, not a dial.

### D113 · The no-number first round — the engine re-created the flat 7; name it, badge it, and pick the seed
*(2026-08-29, from TOP-4 M-048. Scoring-edge mechanic. Sources:
handicap_engine:85–88, D49, spec §5, audit `cas/56-G04-round-receipt.jpg`.)*
- **Current:** D49 retired the flat 7 — "provisional rounds score NORMALLY off
  the starter index, badged provisional". `score_round()` implements
  `coalesce(index_at_post, standing index, engine, this round's own
  differential)`. A golfer with no starter and no engine number (rounds 1–2,
  sometimes 3) therefore posts with `index_at_post = differential` → pvi 0.0
  → **7 points, "PLAYED TO IT"**, every time — the retired flat 7, back by
  accident, and printed as if it were a comparison ("YOUR NUMBER THAT DAY 27.8
  · +0.0"). No badge exists. The client separately carried a blind 18
  (`:15110`; iOS `PostCalc.fallbackIndex`) so the preview said "−9.8".
- **Problem:** the first receipt of every starter-less golfer is a tautology
  presented as a verdict; the preview and the receipt disagree by ~10 strokes;
  D49's badge never shipped.
- **Recommendation (two shapes — owner picks; (i) is the floor):**
  (i) **Badge and say it.** `score_round()` (a NEW migration, `create or
  replace`) sets `rounds.index_provisional = true` when the own-differential
  fallback fires (new nullable-default-false column). The receipt replaces the
  verdict row with **"No number yet — this round starts it (1 of 3)"**, the
  ceremony/feed say **"First round · sets your number"** instead of "played to
  your number", the points stay what the engine gives (7 — D49's "scores
  normally" needs a number and the round is the only one). The preview drops
  the blind 18: with no index it shows the differential and the same sentence,
  never a signed vs-figure.
  (ii) **Seed the starter from round one.** In addition to (i): the first
  posted differential becomes `profiles.index_current` with `index_source =
  'app'`, so round two already scores against a real number and the flat 7
  lasts exactly one round. WHS-lite still takes over at 3.
- **Principle served:** D49's own ("the first round must be a true story"),
  §16, #4 Memory > Statistics.
- **Benefit:** the first receipt tells the truth about itself; no "+0.0"
  comparisons; preview and receipt agree.
- **Tradeoffs:** (ii) lets one hot first round set a low starter for rounds
  2–3 (bounded by the 12 ceiling and the engine takeover at 3); (i) alone keeps
  a 7 that the copy now explains.
- **CONFLICT (named):** D49 ("flat-7 retired") — the engine violates it today
  for the no-starter case; (i) accepts a bounded, badged flat 7 for at most
  three rounds; (ii) removes it after one. Spec §5's provisional row already
  carries D49's note; add this entry's outcome beneath it.

### D114 · Vouching is per golfer — one phone cannot attest four cards
*(2026-08-29, from M-093. Integrity mechanic (§6, §13.1, §16). Sources:
leagueless_live_rounds:261–378, D13, D85, D86, D50; audit
`comp/57-live-finish.jpg`, `cas/86-K03-103-receipt.jpg`.)*
- **Current:** `finish_live_round` posts a round to every seated member's Tour
  Card from the finishing phone and stamps `attested = true` on each. The 103
  that appeared on the casual tester's card came from someone else's skins
  game with no notice, no name of who entered it, and moved the index counter.
  `rounds` has no `posted_by`; the receipt says "Attested · PLAYED WITH THE
  GROUP" whether or not the golfer's phone was ever in the session.
- **Problem:** §6 defines Attested as "a playing partner taps confirm"; §13.1's
  "by construction" assumed the group was scoring together on their phones
  (D85). One phone seating three members and posting three attested rounds is
  the exact shape a padded index needs, and the golfer affected cannot even see
  it happened.
- **Recommendation:** (1) **Record the fact now** (no decision needed — §16):
  `rounds.posted_by` (the finishing profile), shown on the receipt as "Entered
  by Priya · live round" and on the board/push as "Priya posted your 103 at
  Papago to your Tour Card". (2) **The mechanic (this entry):** a round posted
  to a member by another phone is `attested` only if that member's own device
  joined the live session (D85 `live_participant`) — otherwise it posts
  `attested = false` with `posted_by` set and the golfer gets a one-tap **"That
  was me ✓ / That wasn't me"** on the notice and the receipt; "wasn't me"
  voids the round (`voided = true`, logged as a D50 ruling entry, never a
  delete of someone else's row). Unconfirmed rounds still score (§6: "unattested
  rounds score but are flagged") and wear "UNCONFIRMED" on the card.
- **Principle served:** §6, §16, D13 (the word stays "vouch"), #3 Real Golf.
- **Benefit:** the attestation tier means what it says; the golfer owns their
  card; a sandbag by proxy has a witness.
- **Tradeoffs:** one more push kind and two RPCs; the finish sheet's "every
  card posts, attested" line becomes conditional; D86's doorbell already
  carries the notice pattern.
- **CONFLICT (named):** narrows spec §13.1 "attested by construction" to
  "when the golfer's own phone was in the session". Nothing upward.

### No new decision needed (restores an existing one)
| Change | Restores |
|---|---|
| Every PvI is a phrase, never `+/−` (T4-11) | D1, D2 |
| Receipt gets League row, "Index used × allowance", `vsPhrase` verdict (T4-09/10) | spec §16, D2, D95 |
| `pointsFor`/`bandName` at −1.0, half-open band labels (T4-03) | spec §2.2 |
| Blank date never fails as "try again" (T4-05) | spec §9 "a round belongs to the local date played"; the boot default `:12973` |
| Rating/slope placeholders and Post gating (T4-06) | D34's two-box post (a value is typed or picked, never implied) |
| Course search failure is said aloud (T4-14) | the pilot rule at `:6947–6952` ("cached results stand") + CLAUDE.md "never fail silent" |
| "Delete this round" on the receipt, delete-and-repost (T4-13) | spec §16 immutability, D37 (`rounds_owner_update` dead), `delete_round` (20260715170000), D50's "the record is the recourse" |
| Empty-state copy pre-season (T4-12) | D47 ("Before first tee"), D111's phrase |
| `rounds.posted_by` + "Entered by" line (T4-15) | spec §16 (who entered it is part of the work) |

---

## (b) WORK ITEMS

Dependency note — **T3 owns `seasonState()`** (the Home hero `:10076/:10105`,
kickoff `:12218–12227`, NEXT UP `:9691–9694`, the tiles). T4 needs from it:
`seasonState(league) → { stage: 'none'|'forming'|'before_first_tee'|'live'|'cup_final'|'complete',
firstTee: Date|null, firstTeeText: string, window: {start,end}|null,
counts(playedISO): boolean, sentence: string }`. Until T3 lands, **T4-02** ships
a 20-line adapter built from what exists today (`atStarter()` `:11981`,
`firstTeeText()` `:11988`, the `counts` predicate `:6588–6590`,
`state.seasonStart/End`) with the same shape, so every T4 item is re-pointed by
one edit when T3 arrives. On the phone the producer already exists:
`SeasonPhase.of` (`Models.swift:168–189`), `RoomClock.atStarter`
(`LeagueCopy.swift:83`), `PostSeasonRule.counts` (`PostCard.swift:427–435`).

| id | title | layer | effort | deploy | decision |
|---|---|---|---|---|---|
| T4-01 | Log D111–D114; spec §14.1 sentence; §5 note | spec | S | none | owner's nod |
| T4-02 | `roundCounts()` / `seasonSentence()` adapter → T3 | client | S | client push | D111 |
| T4-03 | Bands agree with `cup_points`; one BANDS table | client · ios | S | client push · iOS build | none (§2.2) |
| T4-04 | Preview through the league lens + honest panel copy | client | M | client push | D111, D112 |
| T4-05 | A blank date never reads as a transient failure | client · ios | S | client push · iOS build | none |
| T4-06 | Post-form input honesty (placeholders, tee required, Post gated) | client · ios | S | client push · iOS build | none |
| T4-07 | The posted card states the state | client · ios | S | client push · iOS build | D111 |
| T4-08 | `round_card` + `home_feed` speak the lens | rpc (db-migration) | M | db push | D112 |
| T4-09 | The receipt finishes its sentence (web) | client | M | client push | D111, D112, D113(i) |
| T4-10 | The receipt on the phone | ios | M | iOS build | T4-08, T4-09 |
| T4-11 | The sign sweep — every PvI is a phrase | client · ios · copy | M | client push · iOS build | none (D1) |
| T4-12 | Empty states before first tee (standings row, You) | client · ios | S | client push · iOS build | D111 |
| T4-13 | The correction path — delete on the receipt, post it again | client · ios | M | client push · iOS build | none (§16) |
| T4-14 | Course search says when it is down; the other 502s get a name | edge-function · client · ios · telemetry | M | functions deploy · client push · iOS build | none |
| T4-15 | `rounds.posted_by` + "Entered by" + the notice | db-migration · rpc · client · ios | M | db push · client push · iOS build | none (§16) |
| T4-16 | Confirm / "that wasn't me" for group-entered rounds | rpc · client · ios · edge-function | L | all four | **D114** |
| T4-17 | Telemetry that proves the fix | telemetry · db-migration | S | db push · client push · iOS build | none |
| T4-18 | The composer on the phone: lens, window, no "100%" line | ios | M | iOS build | D111, D112, T4-04 |
| T4-19 | Guards: preflight, app-tests, db-checks | tooling | S | none (CI) | none |

### T4-01 · Log the decisions and write the sentence
- **Layer:** spec. **Effort:** S. **Deploy:** none.
- **Files:** `spec/decision-log.md` (append D111–D114 after `:4114`);
  `spec/spec-v1.0.md` §14.1 (`:239–240`) add D111's sentence; §5 (`:141–143`)
  add D113's outcome under the D49 note; §6 (`:149`) add D114's narrowing.
- **Change:** paste the four entries above verbatim (they are in the log's
  format); D113 and D114 stay PROPOSED with the owner's pick recorded when
  made; D111 and D112 become DECIDED on the owner's "yes" and unblock T4-04/07/08/09/12.
- **dependsOn:** owner. **Verification:** `grep -n '^### D11[1-4]' spec/decision-log.md`
  returns four lines; the §14.1 sentence is the string every T4 copy item quotes.
- **Risk:** none; rule 5 satisfied before any build.

### T4-02 · `roundCounts()` and `seasonSentence()` — the adapter to T3
- **Layer:** client. **Effort:** S. **Deploy:** client push.
- **Files:** `index.html` — new classic helpers next to `vsPhrase` (`:5714`);
  the predicate moves out of the post handler (`:6588–6590`) into the helper
  and the handler calls it.
- **Change:** `roundCounts(playedISO)` = `!!window.CS?.league && !!state.seasonStart
  && !!state.seasonEnd && played >= state.seasonStart && played <= state.seasonEnd`
  (the exact `:6588–6590` test, `played` defaulting to `isoOf(new Date())`).
  `seasonSentence(playedISO)` returns D111's phrase for the three states using
  `firstTeeText()` (`:11988`) and, for the "builds your number" clause,
  `window.CS?.profile?.index_source` (say it only when `app`/null). When T3's
  `seasonState()` exists, both become one-line wrappers over it. Bridge both
  on `window.*` for the module block (landmine: classic↔module).
- **dependsOn:** D111. **Verification:** `tests/app-tests.js` cases:
  `roundCounts('2026-08-29')` is `false` with `state.seasonStart='2026-09-05'`
  and `true` for `'2026-09-06'`; `seasonSentence` contains the real weekday
  ("Sat Sep 5"), never "Sun". **Risk:** none (pure functions).

### T4-03 · Bands agree with `cup_points`; one BANDS table
- **Layer:** client · ios. **Effort:** S. **Deploy:** client push · iOS build.
- **Files:** `index.html:5693–5708` (`pointsFor` `vs>=-1` → `vs>-1`; `bandName`
  same), `:3201–3207` (form table), `:17282–17286` (help sheet);
  `CSBands.swift:46` (`bandName` `vs >= -1` → `> -1`), `PostRoundScreen.swift:313`
  (`bands`); `BoardTests.swift:11` (expectation flips to "A little loose").
- **Change:** a single `BANDS` constant (label · range · points · unit line)
  next to `pointsFor`, rendered by the form table and `openScoringHelp`; the
  labels adopt §2.2's half-open ranges: "3.0 or better" 12 · "1.0–2.9" 9 ·
  "within 0.9 either way" 7 · "1.0–3.0 over" 6 · "worse than 3.0 over" 5, and
  the unit stated once: *"measured against your number after the course's
  rating and slope"*. On the phone `CSBands.bands` (in CupSeasonKit) feeds
  `PostRoundScreen` and the scoring help. `pointsFor(-1.0)` returns 6 on both
  clients.
- **dependsOn:** none (D112 §4 is a restoration of §2.2). **Verification:**
  app-tests `pointsFor(-1.0)[0]===6`, `bandName(-1.0)==='A little loose'`,
  `pointsFor(-0.9)[0]===7`; `swift test` BoardBandTests; db-checks new check
  (T4-19) `select cup_points(-1.0)=6`. **Risk:** none. **Quick win.**

### T4-04 · The preview scores through the league's lens
- **Layer:** client. **Effort:** M. **Deploy:** client push.
- **Files:** `index.html:3189–3199` (markup: add `id="calcK"` to `:3191`, gate
  `:3198`), `:6306–6346` (`recalc`), `:12037` (`ALLOW`), `:6598` (ceremony `vs`),
  `:15110` (blind 18).
- **Change:** in `recalc()`: `const allow = window.CS?.league ? ALLOW[state.preset] : 100;
  const playing = state.myIndex!=null ? state.myIndex*allow/100 : null;` and
  `vs = playing!=null ? playing − diff : null`. `counts = roundCounts($('#inDate').value)`.
  Panel states: **counts** → `#calcK` "League points this round", `#calcPts` =
  pts, `#calcMsg` = the band sentence + `· ${leagueName}`; **league, not
  counting** → `#calcK` "This round", `#calcPts` = "—", `#calcMsg` =
  `seasonSentence(date)` (D111), band phrase kept as the reward line;
  **no league** → `#calcK` "This round", `#calcMsg` "On your Tour Card — join a
  league to score it" and `:3198` shown (only then). A new quiet row under the
  trio: `Index used ${idx} × ${allow}% = ${playing}` when a league is open
  (D112 conflict resolution). `#calcVs` and the `:3196` label become
  `vsPhrase(vs)` / "vs your number" (rides T4-11). With no index (D113): no
  vs figure — `#calcMsg` "No number yet — this round starts it", never a
  signed number; delete the `|| 18` at `:15110`. `state.lastPost` carries
  `{pts, vs, counts, allow, playing}` so the ceremony (`:6598`) and
  `post_submit` (T4-17) use the same figures — the ceremony and the epilogue
  then agree in-season (today the ceremony is 100%, the epilogue 95%).
- **dependsOn:** D111, D112, T4-02, T4-03, T4-06 (rating guard).
- **Verification:** browser (`python -m http.server 8791`, SW cleared): on
  `+blind3` (Papago Grind, first tee Sep 5) enter 45/46 on a picked tee →
  no points figure, the sentence reads "Practice — season starts Sat Sep 5…";
  set the date to Sep 6 → "9 pts · The Papago Grind" and the Index-used row
  reads `× 95%`; on the owner's Fellas account post a real round → the
  preview's pts equals the receipt's Points and the epilogue's band row.
  Telemetry: `post_submit.pts == v_rounds_ranked.points` for the round (T4-17).
- **Risk:** none server-side; `state.preset` must be loaded before the
  composer opens (it is, `:14360`); demo diorama untouched (`state.demo` paths).

### T4-05 · A blank date never reads as a transient failure (M-159)
- **Layer:** client · ios. **Effort:** S. **Deploy:** client push · iOS build.
- **Files:** `index.html:6846` (`resetPostComposer`), `:12973` (boot default →
  extract `todayISO()`), `:6462–6501` (handler), `:4116` (`humanError`);
  `PostRoundModel.swift:128` (`startOver`), `PostCard.swift:112`.
- **Change:** web — `resetPostComposer()` re-defaults `inDate` to `todayISO()`
  instead of clearing it; the click handler (`:6462`) refuses to build the
  payload when `!$('#inDate').value` — marks the field (`aria-invalid`, the
  existing `.f` error styling) and toasts "Pick the date you played"; `humanError`
  gains a branch before `:4116`: `/played_on/` → "Pick the date you played."
  (`:6501` keeps `|| null` so a genuinely absent value still fails loudly at
  the DB rather than defaulting silently). iOS — `startOver()` sets
  `day = Date()` so `card.date` is re-stamped by the `didSet` (`:19`); the
  submit guard requires `card.date != nil`; `HumanError` (`BoardText.swift:122`)
  maps `played_on` the same way.
- **dependsOn:** none. **Verification:** repro from Part 2 §2.2 — fill, Start
  over, fill, Post → posts with today's date; clear the date by hand → inline
  "Pick the date you played", no toast "try again"; `client_events`
  `client_error` rows containing `played_on` drop to zero after deploy.
- **Risk:** none. **Quick win.**

### T4-06 · Post-form input honesty (M-076, M-150)
- **Layer:** client · ios. **Effort:** S. **Deploy:** client push · iOS build.
- **Files:** `index.html:3123–3124` (placeholders), `:3156–3157`, `:6306–6346`
  (`recalc` guard), `:6845–6858` (recents survive Start over — `#courseChips`
  at `:6848` is wiped; keep the chips, clear only the selection);
  `PostRoundScreen.swift:193–194`, the CTA (`M-150`), `PostCard.swift:111–114`.
- **Change:** placeholders become "—" (rating/slope) and "front"/"back"
  (nines); `recalc()` returns early with `#calcMsg` "Pick a tee — or type the
  rating and slope — to see the score" when `rating<=0 || slope<=0`, and
  applies the ceremony's `|vs|>30` sanity gate (`:6183`) to the preview; the
  Post button is disabled until rating, slope, at least one nine and a date
  are present (the D34 two-box contract). Recent-course chips survive Start
  over. iOS: CTA dimmed until `preview != nil && card.date != nil`;
  placeholders neutral; "Recent · rating / slope" header on the recents.
- **dependsOn:** none. **Verification:** blank rating → no "−79.0", Post
  disabled, message shown; `post_blocked{reason}` event (T4-17) counts the
  saves. **Risk:** none. **Quick win.**

### T4-07 · The posted card states the state, not a noun (M-040, M-044)
- **Layer:** client · ios. **Effort:** S. **Deploy:** client push · iOS build.
- **Files:** `index.html:6186–6192` (ceremony points line), `:6081`, `:6115`,
  `:6131` (epilogue first-round copy/title); `PostEpilogue.swift:55`, `:93`,
  `:150–156`; `FinishCeremonyView.swift`.
- **Change:** `finishCeremony` takes `o.state` from `state.lastPost.counts` +
  `seasonSentence`: earned → unchanged (`+9 PTS · COUNTS FOR SQUAD 1`);
  league + before first tee → `PRACTICE · SEASON STARTS SAT SEP 5`; league +
  outside window → `OUTSIDE THE SEASON · ON YOUR TOUR CARD`; no league → `ON
  YOUR TOUR CARD · JOIN A LEAGUE TO SCORE IT`. "COUNTS ON YOUR CARD" is
  retired (D47). The epilogue title is "Your first card ⛳" and the first-round
  sub "your number and record start here" when `!counts`; "Welcome to the
  season" only when the round counts. iOS `PostCeremony.pointsLine` gains the
  same four states (`PostSeasonRule` already supplies `counts`;
  `RoomClock.firstTeeText` supplies the date).
- **dependsOn:** D111, T4-02. **Verification:** the Part 2 repro on `+blind3`:
  the ceremony reads PRACTICE · SEASON STARTS SAT SEP 5; `PostTests.swift:262–268`
  updated (`pointsLine` for the three non-earned states). **Risk:** none.

### T4-08 · `round_card` and `home_feed` speak the lens (D112)
- **Layer:** rpc (db-migration). **Effort:** M. **Deploy:** `supabase db push`
  (owner) then `node tools/build-db.mjs` after refreshing `packages/db/contract.psv`
  so `Rpc.swift` learns the new args (preflight 11/14/17).
- **Files:** NEW `supabase/migrations/20260830HHMMSS_round_lens.sql`
  (`create or replace` over `20260729180000_round_card.sql:94–145` and
  `20260723090000_home_feed_photo.sql`).
- **Change:** `round_card(p_round uuid, p_league uuid default null)` — the
  rank query (`:105–110`) filters to `p_league` when given, else to a league
  the VIEWER shares with the owner (else the owner's first), and the JSON adds
  `handicap_allowance`, `league_name`, `league_id`, `season_starts_on`,
  `season_ends_on`, `in_window` (boolean from the same join), and — with
  D113(i) — `index_provisional`. `home_feed(p_days int default 21, p_league
  uuid default null)` — `drop function if exists public.home_feed(integer)`
  then create the two-arg version: when `p_league` is given and the round
  ranks in that league's season, `pvi`/`points`/`month_rank` come from
  `v_rounds_ranked` and `lens = 'league'`; otherwise the 100% number with
  `lens = 'card'`. Both: `revoke all … from public, anon; grant execute … to
  authenticated` (D37). Client (rides T4-09): `sb.rpc('home_feed', {p_days:21,
  p_league: CS.league?.id})` at `:16769` with the skew retry that drops
  `p_league` on the schema-cache error.
- **dependsOn:** D112. **Verification:** `supabase db query --linked` for the
  owner's Aug 16 round: `round_card(...)->>'pvi'` equals `home_feed(21,
  <fellas>)` pvi equals `v_rounds_ranked.pvi`; `tests/db-checks.sql` check 3
  still passes (new signatures granted); check 11 (security_invoker) unaffected.
- **Risk:** deploy skew — the one-arg call resolves to the new function
  because the old overload is dropped (never leave both: PostgREST cannot
  choose between `home_feed(integer)` and `home_feed(integer, uuid)` for
  `{p_days}`); grants per D37; Rpc.swift regen or preflight 11 fails.

### T4-09 · The receipt finishes its sentence (web) (M-044, M-048, M-049, M-080, M-132)
- **Layer:** client. **Effort:** M. **Deploy:** client push.
- **Files:** `index.html:11495–11530` (`roundCardBody`), `:11541–11563`
  (`enrichRoundReceipt`, `:11547`), `:11570–11600` (`openRoundReceipt`, `:11578`),
  `:11830–11913` (demo receipts — the diorama must match), `:11477–11486`
  (member history rows — add course/gross per line, M-132).
- **Change:** `roundCardBody` rows become: The course · the differential
  arithmetic (unchanged) · **"Your number that day 14.2"** and, when
  `r.playing_index != null`, the sub row **"Index used 14.2 × 95% = 13.5"**
  (`allow = r.handicap_allowance ?? Math.round(playing_index/index_at_post*100)`
  — skew-safe when T4-08 is not yet pushed) · the verdict row reads
  `vsPhrase(pvi)` in words with the arithmetic in its sub label
  (`13.5 − 16.1`) — the signed figure survives ONLY there · **League row,
  always**: `r.points!=null` → `League · ${league_name} · ${points} pts ·
  counting #${month_rank} · ${month}`; mine && league && !in_window →
  `League · practice — season starts Sat Sep 5` / `outside the season window`;
  no league → `On your Tour Card · join a league to score it` · D113(i): when
  `r.index_provisional` (or `index_at_post === differential` before the
  column lands) the verdict row is replaced by **"No number yet — this round
  starts it (1 of 3)"** · then Nine holes / Attested / Played with / Entered by
  (T4-15) · then T4-13's Delete. Fallback pvi (`:11547`, `:11578`) stays 100%
  but the League row says "on your Tour Card" so the number is labelled.
  Member-history rows (`:11481`) gain course + gross and a counting-total
  footer (M-132).
- **dependsOn:** D111, D112, D113(i), T4-02, T4-08 (soft — fallbacks cover
  skew), T4-11 (phrases). **Verification:** open `nov/77`'s round (pre-season)
  → League row "practice — season starts Sat Sep 5", no "+0.0"; open the
  owner's Aug 16 round → "Index used 12.x × 95% = …", verdict "beat your
  number by 2.6", Points 9, and Home's card says the same 2.6 (after T4-08);
  the casual tester's 97 → "No number yet — this round starts it".
- **Risk:** none server-side; keep the demo receipts in step (rule: the
  diorama never shows what real doesn't).

### T4-10 · The receipt on the phone
- **Layer:** ios. **Effort:** M. **Deploy:** iOS build.
- **Files:** `ReceiptSeed.swift:12–33` (fields), `:119–152` (`ReceiptRows.build`
  — `:139` number that day, `:143–145` verdict, `:146` Points),
  `RoundReceiptSheet.swift:33–74`, `RoundsRepository.roundCard` (pass
  `p_league`), `BoardLogic.swift:37–41` (`Counting.preseason` already says
  "PRE-SEASON · NOT COUNTING" — reuse its wording family).
- **Change:** mirror T4-09 row for row: `playingIndex`, `allowance`,
  `leagueName`, `inWindow`, `indexProvisional`, `postedByName` on the seed;
  the Index-used sub row; the verdict via `CSBands.vsPhrase` with the
  arithmetic as `sub`; the League row in all four states (strings from
  `RoundCopy`, one source with the ceremony's); the provisional line; Delete
  for `isMine` (T4-13). `pviChip` is retained only for the arithmetic sub row.
- **dependsOn:** T4-08, T4-09. **Verification:** `swift test` — a new
  `ReceiptRowsTests` case per state (earned / practice / no league /
  provisional); simulator via the dev hatch on the owner's account: the Aug 16
  receipt matches the web's rows verbatim.
- **Risk:** iOS parity is the point; Rpc.swift regen after T4-08.

### T4-11 · The sign sweep — every PvI is a phrase (M-045, M-046, M-087)
- **Layer:** client · ios · copy. **Effort:** M (phase 1 is S). **Deploy:**
  client push · iOS build.
- **Files (web, all verified):** `:6339` (form) · `:4566`, `:4578` (finalist
  receipt rows) · `:11341–11347` (You career) · `:11401`, `:11418` (demo
  standings) · `:11440–11443`, `:11465` (standings; header "Avg vs index"
  `:11413`) · `:11478`, `:11481` (member history) · `:11519` (receipt — moves
  into the arithmetic sub row, T4-09) · `:12495–12503` (duel sheets) ·
  `:13560` (tour card avg) · `:13573` ("DIFF" on recent rows) · `:11830`,
  `:11852`, `:11873`, `:11881`, `:11890`, `:11913` (demo). **Explicitly not
  PvI (leave alone):** `:8591` (holes thru), `:9040`, `:9229` (Wolf/match
  points), `:13458` (rivalry duel points). **iOS:** `RoundStoryCard.swift:77–79`,
  `SeasonStats.swift:36–37`, `Career.swift:42`, `TourCard.swift:107`,
  `PostRoundScreen.swift:402`, `EventMath.swift:103` (`sgn` → keep for event
  points only; rename so it cannot be reached for PvI).
- **Change:** add `vsShort(v)` beside `vsPhrase` (`:5714`): "beat by 1.2" /
  "played to it" / "1.2 over" — for table cells and stat tiles where the full
  phrase does not fit; `vsPhrase` for rows and cards; the signed figure is
  allowed ONLY inside a receipt arithmetic row adjacent to its subtraction.
  Column headers: "Avg vs index" → "Avg vs your number"; You "Best vs index"
  → "Best vs your number" (IOS-016 already labels the phone this way);
  "DIFF 19.7" → "diff 19.7" stays (it IS a differential, M-087 asks only for
  the label and a tap → receipt, which `:13573` rows get via `openRoundReceipt`).
  Retire every `const sgn=` / `const sign=` declaration. Phase 1 (this week):
  `:6339`, `:11481`, `:11443/:11465`, `:11346–11347`, iOS `:402` and
  `RoundStoryCard`. Phase 2: the rest + demo.
- **dependsOn:** none (D1). **Verification:** preflight check (T4-19): zero
  `const sgn=` and zero `>=0?'+':''` within 80 chars of `pvi|vs|avg` outside
  the allowlisted receipt lines; blind re-run: no "-3.7" on form, posted card,
  You or standings. **Risk:** copy length in table cells — `vsShort` exists
  for that. **Quick win (phase 1).**

### T4-12 · Empty states before first tee (M-040 tail; Appendix A #20)
- **Layer:** client · ios. **Effort:** S. **Deploy:** client push · iOS build.
- **Files:** `index.html:11483` (`openMemberHist` empty state), `:2910` (You
  "Rounds posted · This season" tile — add a sub line), `:16863` ("FIRST TEE
  SUN" → `firstTeeText()` form); `ReceiptSheets.swift:98` (iOS member sheet
  empty state).
- **Change:** when `roundCounts(today)` is false because first tee is ahead:
  mine → "Your Aug 29 round is on your Tour Card — season rounds count from
  Sat Sep 5." (date from `window.career?.recent[0]?.played_on`); others → "No
  season rounds yet — the season starts Sat Sep 5."; in-season with zero →
  the existing "post one and you're on the board". The You tile gets the same
  one-liner under "0". `:16863` derives the weekday (`DOW[sd.getDay()]`), per
  §14.0 v1.1. iOS: same strings via `RoomClock.atStarter`/`firstTeeText`.
- **dependsOn:** D111, T4-02. **Verification:** `join/52-AE-marcus-row.jpg`
  repro on `+blind2` reads the new line; You tab on `+blind3` shows the
  sentence; a Saturday first tee never reads "SUN". **Risk:** none.

### T4-13 · The correction path — delete on the receipt, post it again (M-080)
- **Layer:** client · ios. **Effort:** M. **Deploy:** client push · iOS build.
- **Files:** `index.html:11495–11530` (receipt — owner-only control),
  `:11353–11369` (You ✕ — label it; replace `confirm()` at `:11360`),
  `:6845–6858` (composer prefill hook); `RoundReceiptSheet.swift`,
  `RoundsRepository.swift:137–141`, `YouScreen.swift:24–27, 97`.
- **Change:** the receipt gets, for `is_mine`, a quiet button **"Delete this
  round"** with the fine print *"Rounds are never edited — delete it and post
  it again. It leaves your Tour Card and any standings it counted toward."*
  (§16 + D50's "the record is the recourse"). Tap → an app-styled confirm
  sheet (no native `confirm`) with "Delete" and "Keep it"; on success →
  `delete_round` (`20260715170000`), toast "Round deleted", reload career /
  standings / home (as `:11364–11367`), and a second button **"Post it again"**
  that opens the composer prefilled with course_label, `api_course_id`,
  rating, slope, date, holes (scores left blank — a total cannot be split back
  into nines; if `round_holes` existed, `round_holes_of` restores the grid).
  The You ✕ becomes a labelled "Delete" and shares the sheet. No mutation path
  is added anywhere (D37 killed `rounds_owner_update`; nothing here revives it).
  iOS: the same button + sheet on `RoundReceiptSheet` via
  `RoundsRepository.deleteRound`; "Post it again" routes to the composer with
  a prefill.
- **dependsOn:** T4-09/T4-10 (the receipt rows), none for the decision.
- **Verification:** `cas/61-H05-tap-x.jpg` repro: no `[dialog:confirm]` in the
  console; delete from the receipt → the round leaves You and standings;
  `round_delete{from:'receipt'}` event lands. **Risk:** none; `delete_round`
  is owner-scoped at the DB.

### T4-14 · Course search says when it is down; the other 502s get a name (M-160, M-077, M-086)
- **Layer:** edge-function · client · ios · telemetry. **Effort:** M.
  **Deploy:** `supabase functions deploy courses` (owner) · client push · iOS build.
- **Files:** `supabase/functions/courses/index.ts:44–57` (`gca`), `:183–246`
  (search), `:287–291` (catch); `index.html:6909` (tee cache), `:6957–6968`
  (search catch), `:6640` (post catch), the finish/tee-sheet catches;
  `DeclareRoundSheet.swift:313–327`, `PostCourseSearchField.swift:31–33`.
- **Change:** function — `gca()` gets an `AbortController` timeout (8 s);
  the search branch, on upstream failure, answers **200** `{courses:
  <cache-only>, degraded: true, reason: 'upstream'}` instead of 502 (the
  cache search the client already runs stays first); the outer catch keeps
  502 only for our own faults; every path already logs (`:172–174`). Client —
  on `error` or `degraded` with no local hits, the dropdown shows *"Course
  search is down — type your course, rating and slope. ↻ Try again"* (a
  `.coursedd-msg` like `:6895`) instead of hiding; results are deduped by id
  AND by `label+place` (the "Papago ×2" case is two upstream ids for one
  course); the tee-cache `.catch` at `:6909` toasts "Couldn't load the hole
  data — rating and slope are set". Telemetry — `qaEvent('course_search_fail',
  {status, degraded, q_len})`; in the post/finish/tee-sheet catches
  `qaEvent('rpc_fail', {fn, status, msg: first 120 chars})` so the M-086 502s
  are named next time. iOS — `CourseSearchModel.run` sets a `failed` flag on
  catch; `PostCourseSearchField` shows the "search is down" line with a retry
  row instead of "No match".
- **dependsOn:** none. **Verification:** kill the `GOLFCOURSE_API_KEY` in a
  local `supabase functions serve` → search "TPC Scottsdale" → the inline
  message + retry, "Ken Mc" still answers from cache; `client_events` shows
  `course_search_fail`; the `courses` function log shows `[courses] golfcourseapi
  <status>` for the window. **Risk:** functions deploy is the owner's; the
  200-degraded contract must be read by both clients before the function
  ships (both already treat `courses:[]` as "no match", so the order is safe).

### T4-15 · `rounds.posted_by` + "Entered by Priya" + the notice (M-093, part 1)
- **Layer:** db-migration · rpc · client · ios. **Effort:** M. **Deploy:** db
  push · client push · iOS build.
- **Files:** NEW `supabase/migrations/20260830HHMMSS_round_posted_by.sql`:
  `alter table rounds add column posted_by uuid references profiles(id) on
  delete set null`; `create or replace function finish_live_round(...)` over
  `20260829090000_leagueless_live_rounds.sql:261` setting `posted_by =
  auth.uid()` on the inserts at `:333–338` and `:371–378`; `round_card` adds
  `posted_by`, `posted_by_name`; `round_to_board` (`20260712090000`) posts a
  second story to the AFFECTED golfer's leagues when `posted_by <> profile_id`:
  "PRIYA POSTED YOUR 103 AT PAPAGO TO YOUR TOUR CARD" (kind `round`, so the
  `push` function's existing `notify_rounds` rail carries it — no new kind).
  Client/iOS: receipt row "Entered by Priya · live round" (T4-09/T4-10);
  the finish sheet copy (`:9316`) drops "attested by the group" for members
  whose phone was not in the session once D114 lands (until then unchanged).
- **dependsOn:** none for the fact and the notice (§16); D114 for anything
  more. **Verification:** finish a live round on `+blind4` seating `+blind3` →
  `+blind3`'s board shows the story, their receipt names Priya;
  `select posted_by from rounds where live_round_id=…` non-null. Backfill:
  best-effort `update rounds r set posted_by = lr.started_by from live_rounds
  lr where r.live_round_id = lr.id and r.posted_by is null` in the same
  migration. **Risk:** grants unchanged (same signatures); RLS — `rounds`
  select policies already cover the column.

### T4-16 · Confirm / "that wasn't me" (M-093, part 2 — after D114)
- **Layer:** rpc · client · ios · edge-function. **Effort:** L.
- **Sketch only:** `confirm_round(p_round)` / `disown_round(p_round)` (owner
  of the card only; disown sets `voided = true` and writes a D50 ruling
  entry); `finish_live_round` sets `attested = exists(live_participant for
  that member's device)` else false; the notice (T4-15) carries the two taps;
  cards wear "UNCONFIRMED" until confirmed (§6: still score). Push kind
  `confirm_round` in `supabase/functions/push`. Not in this cycle.
- **dependsOn:** D114, T4-15.

### T4-17 · Telemetry that proves the fix
- **Layer:** telemetry · db-migration. **Effort:** S. **Deploy:** client push ·
  iOS build · db push (one founder-only view).
- **Files:** `index.html:6554–6559` (`post_submit`), `:6230–6236` (`qaEvent`),
  `PostRoundModel.swift:224–227` (`PostEvent.submit`); NEW migration
  `20260830HHMMSS_first_round_truth_view.sql`.
- **Change:** `post_submit` props gain `round_id`, `counts`, `pts`, `allow`,
  `stage`, `has_index`; new events `post_preview_state {counts, league,
  stage}` (once per composer session, when the first preview renders),
  `post_blocked {reason:'date'|'rating'|'slope'}`, `receipt_open {has_points,
  lens, provisional}`, `round_delete {from}`, `course_search_fail`, `rpc_fail`
  (both from T4-14). Founder-only view `v_first_round_truth` (revoked from
  anon/authenticated like `v_post_timings`, `20260717153000:78–89`): per
  `post_submit` with a `round_id`, the promised `pts` beside
  `v_rounds_ranked.points` for that round, plus `counts` beside whether a
  ranked row exists — the "preview matched what landed" rate. iOS emits the
  same names/props through `svc.event`.
- **dependsOn:** T4-04 (the props exist once the lens is real).
- **Verification:** `select * from v_first_round_truth order by at desc limit
  20` from the SQL editor after the first week: mismatch rate 0.

### T4-18 · The composer on the phone: lens, window, no "100%" line (parity for T4-04/06)
- **Layer:** ios. **Effort:** M. **Deploy:** iOS build.
- **Files:** `PostCard.swift:188–235` (`PostCalc.preview` — add `allowance:`
  and drop `fallbackIndex`), `:427–435` (`PostSeasonRule` — reuse),
  `PostRoundScreen.swift:386–409` (`PostHeroContent`: `:402` chip → phrase,
  `:406` "A preview at 100% of your number" line deleted, `:407–408` stays
  gated on membership), `PostRoundModel.swift:58–60` (membership supplies
  `settings.handicap_allowance`, `season`).
- **Change:** `PostCalc.preview(card, myIndex:, allowance:)` scores
  `idx × allowance/100 − diff`; the hero shows the four panel states of T4-04
  (`pointsText` becomes the state line; the Index-used sub row under the
  chips); with no index → "No number yet — this round starts it" and no chip.
  `PostTests` gain the allowance and no-index cases.
- **dependsOn:** D111, D112, T4-04 (strings), T4-03. **Verification:**
  `swift test`; sim via the dev hatch on `+blind3`'s league: same words as the
  web for the same inputs. **Risk:** parity drift — the strings live in
  `RoundCopy` once, and T4-19's preflight compares the two string tables.

### T4-19 · Guards: preflight, app-tests, db-checks
- **Layer:** tooling. **Effort:** S. **Deploy:** none.
- **Files:** `tests/preflight.mjs` (after check 17), `tests/app-tests.js`,
  `tests/db-checks.sql` (after check 14).
- **Change:** preflight **18** — no `const sgn=`/`const sign=` in `index.html`
  and no `>=0?'+':''` within 80 chars of `pvi|vs|avg` outside an allowlist of
  receipt-arithmetic lines; **19** — the D111 phrase family and the BANDS
  labels in `index.html` equal the Swift `RoundCopy`/`CSBands` strings (the
  tokens/markers checks already do this shape). app-tests — `roundCounts`,
  `seasonSentence` weekday, `pointsFor(-1.0)`, `vsShort`. db-checks **15** —
  `cup_points(-1.0)=6 and cup_points(-0.9)=7 and cup_points(3.0)=12` (pins
  §2.2 the way check 12 pins the engines), and `home_feed`/`round_card` have
  no leftover one-arg overload.
- **dependsOn:** T4-03, T4-11. **Verification:** `./tools/ship.sh` preflight
  passes; `supabase db query --linked -f tests/db-checks.sql` all PASS.

---

## (c) QUICK WINS (no decision, this week)

**T4-03** (bands at −1.0 + one table) · **T4-05** (blank date) · **T4-06**
(placeholders / Post gating) · **T4-11 phase 1** (the six loudest signed sites)
· **T4-14 client half** (the inline "search is down" message + dedupe + the
`rpc_fail` breadcrumb — the function's timeout/degraded-200 rides the next
functions deploy) · **T4-19** (the guards, so the sweep cannot regress). All
client-push-only except the iOS siblings, which ride the next build. T4-01 is
a doc, needs only the owner's "yes" on D111/D112, and unblocks everything else.

---

## (d) PARITY (D100 — nothing ships on the web alone)

| Web item | Phone | Where | Status |
|---|---|---|---|
| T4-02 adapter | already exists: `SeasonPhase.of` (`Models.swift:168–189`), `RoomClock.atStarter` (`LeagueCopy.swift:83`), `PostSeasonRule.counts` (`PostCard.swift:427–435`) | — | nothing to build; T3 mirrors the web to it |
| T4-03 bands | `CSBands.bandName` `:46`, `PostRoundScreen.bands` `:313`, `BoardTests:11` | T4-03 | same item |
| T4-04 preview | `PostCalc.preview`, `PostHeroContent` `:386–409` | **T4-18** | |
| T4-05 date | `PostRoundModel.startOver` `:128`, submit guard, `HumanError` (`BoardText.swift:122`) | T4-05 | same item |
| T4-06 inputs | placeholders `:193–194`, CTA (M-150), recents header | T4-06 | same item |
| T4-07 card | `PostCeremony.pointsLine` (`PostEpilogue.swift:150–156`), `title` `:93`, `first_round` `:55` | T4-07 | same item |
| T4-08 RPC | `Rpc.swift` regenerated by `tools/build-db.mjs` from `packages/db/contract.psv`; `RoundsRepository.roundCard(p_league:)`, the feed repo passes `p_league` | T4-10 | |
| T4-09 receipt | `ReceiptRows.build` (`ReceiptSeed.swift:119–152`), `RoundReceiptSheet` | **T4-10** | |
| T4-11 sign | `RoundStoryCard:77–79`, `SeasonStats:36–37`, `Career:42`, `TourCard:107`, `PostRoundScreen:402` | T4-11 | same item |
| T4-12 empty states | `ReceiptSheets.swift:98`, You season tile | T4-12 | same item |
| T4-13 delete | `RoundReceiptSheet` + `RoundsRepository.deleteRound` `:137–141` (exists) | T4-13 | same item |
| T4-14 search | `CourseSearchModel.run` (`DeclareRoundSheet.swift:313–327`), `PostCourseSearchField:31–33` | T4-14 | same item |
| T4-15 posted_by | receipt row via `ReceiptSeed.postedByName`; the notice is a board post (no client work) | T4-15 | same item |
| T4-17 telemetry | `PostEvent` names/props in `PostRoundModel.swift:224–227` | T4-17 | same item |

Web-only until: nothing. The phone is where D107's free door posts most rounds
(guest claim), so the receipt and ceremony parity items (T4-07, T4-10, T4-18)
ship in the same TestFlight as their web counterparts.

---

## (e) MEASUREMENT

**Events (client_events: profile_id · event · props):**
- `post_preview_state {counts, league, stage}` — how many first previews are
  pre-season (the audit's 6/6). Target after T4-04: every one of them shows
  the sentence, none shows a points figure — `props->>'counts'='false'` rows
  must never coincide with a `pts` value.
- `post_submit {round_id, counts, pts, allow, stage, has_index, …}` — joined
  to `v_rounds_ranked` in `v_first_round_truth`: **preview == landed** rate,
  target 100% (today it is undefined pre-season and wrong at 100%/95% in season).
- `post_blocked {reason}` — replaces the `client_error` rows containing
  `played_on` (target: those go to 0 after T4-05).
- `receipt_open {has_points, lens, provisional}` — the share of receipts that
  open with a League row (target 100%; `has_points=false` should only appear
  with `lens='card'`).
- `round_delete {from:'receipt'|'you'}` — the correction path is found (M-080).
- `course_search_fail {status, degraded}` and `rpc_fail {fn, status}` — the
  M-086 502s get an endpoint name within the first week.
- `home_hero_state` (exists, `:10000`) — T3's producer; T4 reads it only to
  confirm `stage='before_first_tee'` co-occurs with `post_preview_state.counts=false`.

**Funnel (growth_events, `20260828160000`):** `first_round_posted` (server-
decided) → **second round within 14 days** (`rounds` per profile, SQL). The
audit cohort is the baseline (7 first rounds, 0 second rounds — all pre-season
by construction). Target: a second post from ≥ 50% of first posters within
14 days of first tee.

**Acceptance test — blind persona re-run.** Re-drive Journey D (first round)
with the casual (A1), novice (A3) and competitive (A2) briefs on fresh
`+blind` accounts in The Papago Grind before Sep 5, and once after, plus the
observer's read-only pass on Fellas. Pass criteria, in their words: (1) no
"LEAGUE POINTS THIS ROUND N" appears before first tee; (2) the posted card
says PRACTICE · SEASON STARTS SAT SEP 5 and the tester can say why the
standings read 0 without guessing; (3) the receipt shows League, Index used ×
allowance and a worded verdict, and the competitive tester reproduces the
points by hand; (4) one round reads with one phrase on Home, receipt and You
(observer: obs/04 vs obs/10 agree); (5) no bare "−3.7" outside a receipt
arithmetic row; (6) the "Start over" → blank date path cannot produce "try
again"; (7) `rulesClear` ≥ 6 for all three (was 3–5) and the observer's
"rigged" reading is gone.

---

## (f) OPEN QUESTIONS (owner)

1. **D113 — badge only, or seed the starter from round one?** (i) keeps a
   bounded, badged 7 for up to three rounds; (ii) makes round two score
   against a real number. The engine cannot decide this; D49's text supports
   either.
2. **D112 — may the form's calc panel carry "Index used 14.2 × 95% = 13.5"?**
   D2 reserves the allowance for receipts; the plan treats the panel as the
   receipt-in-advance and puts the row in `.sub` weight. Veto → the row lives
   only on the receipt and the panel says "9 pts · The Papago Grind".
3. **D114 — which shape of consent:** auto-attest only when the golfer's own
   phone joined the session (D85), with "That was me / wasn't me" for the
   rest — or a confirm tap for every group-entered round regardless? And does
   "wasn't me" void (proposed) or merely flag?
4. **Multi-league lens on Home/You:** the viewer's open league (D81/D94), with
   every league on the receipt — confirm, or show one compact row per league
   under the feed card (the D94 amendment T5/T3 is already proposing).
5. **The typed starter never gets overtaken.** `round_refresh_index`
   (`handicap_engine:100`) skips golfers with `index_source='self'/'ghin'`,
   while the help sheet (`:17278`) and the settings copy promise "once you
   have 3 rounds your scores take over" (M-051). D111's "builds your number"
   clause is gated on `index_source` for that reason; the mechanic itself
   (does a typed starter ever yield?) needs its own entry in the rules theme.
6. **Spec §9's seven-day posting window** is not enforced anywhere; D111
   names it as separate. Enforce (a backdated round older than 7 days needs
   the Pro), or strike the line?

---

*Companion plans: `plan/t3-*.md` (seasonState, the hero, the tiles);
`plan/t1-*.md` (the lock — the same D37 RPC discipline T4-08 follows).
Audit sources: `blind-ux-audit.md` §2 TOP-4, §5.2, §11.1–11.4, Appendix A
#2/#4/#5/#10/#20; `critical-findings.md` Part 1 TOP-4, Part 2 §2.2/§2.4,
Part 5 P0 #4/#7; `issues.json` M-040…M-049, M-076, M-080, M-086, M-087,
M-093, M-132, M-150, M-159, M-160; `raw/synthesis-and-validation-results.json`
verdicts 10, 11, 13.*
