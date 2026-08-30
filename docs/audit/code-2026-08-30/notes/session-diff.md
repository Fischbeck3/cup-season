# Slice: every line the 2026-08-29 session changed (`git diff 34d20b6..HEAD`)

Reviewer's brief: 17 commits, 912 changed lines in `index.html`, two new migrations,
three new preflight checks, one new app-test block, and a large parallel edit on the
phone. Written fast, in one sitting, by the agent that is now reading it. I read the
diff hunk by hunk, then opened each changed function in its file, then re-derived the
ten items the brief named against the engine (`cup_points`, `v_rounds_ranked`,
`close_month`, `randomize_squads`, `enter_cup_final`, `season_scenarios`) and against
prod (`supabase db query --linked`, read-only).

Headline: the commits are unusually honest about *why* each change exists, and the
mechanics they re-derive (the −1.0 band boundary, the pot's penny rule, the floor's
solo claim, `lockedPhase()`'s split) are correct where I could check them against the
engine. What they are **not** honest about is *coverage*. Several commits announce a
fix as global ("one producer feeds all three", "both standings tables", "consent on
every join path", "one league stage") and land it on one call site while the other
one, two, or three keep the old behaviour — and in three cases the session
**relabelled the surface without changing the value under it**, which is worse than
leaving both alone. That pattern accounts for a third of what follows.

---

## 1 · The lock (Q-01, D111) — the split is right, the recovery has a trap

`lockBylaws()` now tries `lock_league` first and keeps the four-write path only for
skew, gated on a message test that lets a real refusal ("Only the Pro can lock the
bylaws.") through instead of retrying it down a weaker path. That is the correct
shape. `lockedPhase()` probes the server rather than the exception, and the
`lock_ok / lock_recovered / lock_ui_fail` triage is a genuine improvement — an
exception after the commit can no longer be narrated as a failed lock.

Two things are wrong under it.

**The idempotency trap.** `lock_league` returns early on `locked_at is not null` and
hands back `v_league.phase` — whatever that is. The fallback path writes `locked_at`
**first** (index.html:15699) and `leagues.phase` **last** (index.html:15774). A
failure between them leaves `locked_at` set with `phase='setup'`, and from that moment
`lock_league` can never finish the job: every retry takes the early return, hands the
client `phase: 'setup'`, and the client's `if(locked)` branch fires `lock_ok`, toasts
"Bylaws locked" and opens the celebration for a league that is still in setup with no
season and no squads. This is the same "success on failure" class the commit set out
to kill, moved one layer down. Prod is clean today (I checked: 0 leagues with
`locked_at` set and `phase='setup'`), so it is a live hazard rather than live damage —
but the fallback that creates it is retained deliberately, so the hazard is retained
deliberately too. The fix is one line: treat `already_locked and phase = 'setup'` as
*not yet locked* and fall through.

**`state.emails`.** I checked, because this is where `staged` died: `state.emails` is
declared at index.html:3816 and the wizard's email slots are gone, so the fallback's
`state.emails.filter(...)` is a no-op rather than a second ReferenceError. Fine.

Preflight 18 (the free-identifier lint) is real work and it is correctly scoped: I
verified it matches all four `<script>` blocks (not two), the fixture is the actual
2026-08-04 bug, and the check FAILs itself if the fixture stops being detected. It
runs green today. This is the best thing in the session.

## 2 · The bands at −1.0 (Q-20) — correct, and correctly pinned

`cup_points` is `p_pvi > -1 → 7` (initial_baseline.sql:251). The web now reads
`vs > -1` in `pointsFor`, `bandName` and `vsPhrase`; `CSBands` matches; the Swift test
that pinned `bandName(-1.0) == "Played to it"` was corrected rather than deleted; and
both clients gained a property test walking the range asserting name-vs-points
agreement — which is the class of bug, not just its instance. db-checks 17 pins the
engine end. Nothing to report. This one is done properly.

## 3 · `vsShort` (Q-23) — the null guard is right, the rollout is not

The guard is correct and the comment about `Number(null) === 0` is a real save.

But Q-23 claims `vsShort` "replaces the sign on the post preview, **both standings
tables**, the member tile and the receipt's verdict line." It reaches the preview, the
receipt, and `renderIndStats` — which is the **demo** renderer, dead since D83.
`renderIndStatsReal`, the one every real league sees, still prints `sgn(p.avg)` at
index.html:11905 and `sgn(me.avg)` at 11882; the career tile `#clAvg` still prints
`sign(c.avg)` at 11786. And the session **did** relabel those surfaces — the markup
headers at 2895/2921 and the table header at 11898 now read "Avg vs your number" —
so a real golfer reads a column headed *"Avg vs your number"* whose cells say `-3.7`,
while the composer two taps away says `3.7 over` and the receipt says
`3.7 over — POSTED ANYWAY`. That is verbatim the "the same round appeared as '-3.7',
'3.7 over' and '+0.0' on three consecutive screens" defect the commit says it removed.
The colour thresholds diverged with it (`p.avg>-1` in the demo table, `p.avg>=0` in
the real one).

## 4 · The season window (D122) — right rule, wrong input

`v_rounds_ranked` gates eligibility on `r.played_on between s.starts_on and s.ends_on`
(initial_baseline.sql:1370). The **post handler** already knows this: index.html:6892
computes `counts` from `payload.played_on`. `seasonState()` does not — it reads
`leagueStage()`, which reads today's clock. So the two disagree whenever the round's
date and today's date fall on different sides of a boundary, which is exactly what
backdating does, and D136 explicitly kept backdating legitimate. Live season, round
dated before first tee: the composer prints "League points this round · 9", the
ceremony prints "COUNTS ON YOUR CARD". Season past `ends_on` (before `settle_season`
flips the league phase): `isCupFinal()` is true, stage is `final`, `seasonState()` is
`live`, and the composer promises points for a round the view will never score —
`leagueStage()` has no "season is over" branch at all, while `#hhPhase` right beside
it does (`CS.season.status==='complete'`). The phone got this right: `PostSeasonRule.note`
takes `playedOn`. The web's `seasonNote()` takes nothing.

Also: for a league-less golfer `seasonState()` returns `no_league`, and `recalc`'s
gate is `_ss === 'live'`, so the headline points figure becomes an em dash for every
account without a league — the majority of new users, and the exact figure the old
copy ("points apply in any league you join") existed to show them. The commit never
mentions the `no_league` case; it got swept in with `pre` and `over`.

## 5 · The hero matrix (D119) — two of six cells never render

`starter = state.phase==='season'` (index.html:10465) is evaluated *before* the stage
matrix and short-circuits both the body copy and the CTA block. `atStarter()` also
requires `phase==='season'`, so **every preseason league has `starter === true`**.
Consequence: the `!isPro && stage==='preseason'` and `stage==='preseason'` body
branches are unreachable, the CTA and the sub-CTA are both suppressed
(`(starter || !nextStep) ? '' : cta + sub` — `+` binds before `:`), and the card
renders the eyebrow `"<name> · before first tee"` above the body
`"The season's on. Rounds count from today."` A member seven days out gets a hero that
contradicts itself in two lines and offers neither "Plan a round" nor "Post a practice
round". The iOS commit (dc0ae12) names this exact contradiction, says it came from the
web, and fixes it on the phone. It was not fixed on the web.

The other four cells are sound, and the role test is a real improvement.

## 6 · The doors (Q-14/Q-15/Q-18/D114)

**The covenant can hang the boot.** `covenantGate` returns a promise resolved only by
`#covJoin` or `#covNo`. The sheet it opens is the app's shared `#sheet`, which closes
on `#shClose`, on a backdrop click, and on Escape — three paths that resolve nothing.
Before this session that stranded a click handler. Q-14 moved the gate into `boot()`
(index.html:18173), so now closing it with the X leaves `boot()` awaiting forever:
`bootStep` never leaves `'memberships'`, the 8s watchdog prints *"Boot stalled at
[memberships] — network or auth hang"*, the `finally` never runs, and `safeBoot`'s
`booting` flag never clears — so no later auth event can re-boot either. The pending
code is now deliberately retained, so a reload re-offers the same sheet. Escapable
only by finding "Not now".

**The Back button is not symmetric.** `#obBack` is created lazily inside
`openEmailBox`. On a cold signed-out load nobody has called it, so tapping "I have a
league code" hides `#obEmail` and finds no `#obBack` to show — the golfer is on the
code door with the email door gone and no way back but a reload. The commit says
"symmetric across the email and league-code doors."

**Q-15's generic line survives** at index.html:18598 —
`"You're invited. Enter your email and you're in."` — and is load-bearing: the
`league_by_code` resolver at 18506 matches on `/^You're invited\. /` to swap in the
league name. So the claim Q-15 removed is still what a recipient reads whenever that
lookup is slow or fails.

**`openInviteSheet` is good.** Listeners are attached after `openSheet` writes the
body synchronously, the body is replaced on every open so nothing accumulates, the
URL is on screen before any clipboard is touched, and a clipboard rejection says so
instead of blaming the session. The one soft edge: `growthEvent('artifact_shared')`
now fires on sheet *open* rather than on a share, so that funnel number changes
meaning; and `inviteMessage` only names the Pro when the *sharer* is the Pro, though
`CS.members` carries the name (the hero four hundred lines up uses it).

Preflight 19 counts `join_league` calls against `covenantGate(` occurrences. It does
catch the naive regression (a sixth ungated join fails it today), but it proves a
count, not an association: any change that adds a join path and a `covenantGate(`
reference elsewhere passes.

## 7 · The pot (Q-28 / D129)

The penny rule is right and it matches the server: `20260828170000_pot_two_numbers.sql:82`
does `c_cents := greatest(0, col_c - r_cents - k_cents)`, champion absorbing. The
client's tiles now do the same.

But there is a **third** producer the fix did not touch: `#lineSplit`, the gold "On the
line" bar in the League Room (index.html:12590), still runs three independent
`Math.round`s. A 5-player $50 league at 60/25/15 now reads **CHAMPS $150** on the bar
and **$149** on the Pot tab — the two surfaces disagree by a dollar on the same screen
flow, which is a worse failure than the $251 sum it replaced, because now the app
contradicts itself rather than merely arithmetic. The demo branch at 7556 has the same
bug (dead path).

Smaller: renderPot carries a duplicated `if(!window.CS?.season?.id)` line (7534/7535,
leftover from swapping out the `if(!isPro)` guard); a member's row is now a `<div>` but
`.payer` still sets `cursor:pointer`, so it still reads as tappable on a pointer
device; and `set_buy_in_terms` is not deployed yet, so the Pro-only "Say how the crew
pays you" link currently fails with "give it a second and try again" — permanently,
not for a second. That last one is announced in the commit as an owner action.

`join_covenant_info` gained `has_pay_note` and `buy_in_due_on` — anon-reachable — that
no client reads. The note itself is correctly withheld.

## 8 · The floor (Q-27)

The solo claim is **true** and I verified it the way the commit says it did:
`close_month` drives its penalty loop from `squad_members join squads`
(20260727160000_board_voice.sql:236), and a solo league has no squads, so no floor
penalty can fire. Good.

The "one producer feeds all three" claim is not true. `floorSentence()` feeds
`renderPulse` twice. The wizard's (i) sheet (`#ih-floor`, index.html:3331) is still a
hand-written string, was *edited by this session* rather than replaced, still says
"the squad takes the penalty: −5 points per round short under Standard rules"
regardless of structure or preset — the exact thing `floorSentence` was built to stop —
and now leaks an internal citation, **"(D14)"**, into user-facing copy, three commits
after Q-26 removed "bylaws §4" for being a citation members cannot open. The GUIDE
sheet at 17946 is a fourth wording, and the dial's own `<small>` hardcodes
"−5 SQD PTS SHORT".

`floorSentence` also derives the penalty from `state.preset` rather than from
`floor_penalty`, which is the column the engine actually reads. All 18 prod leagues
are `standard`/`deduct` so they agree today; but D129 just put the raw settings row on
`CS.settings`, so the correct source is now one property access away.

## 9 · The stage vocabulary (D120)

`leagueStage()` + `STAGE_LABEL` is the right idea and preflight 20 (web table vs Swift
`Stage.label`) is a real cross-client guard. Three call sites were migrated. Two were
not, and they are both prominent:

* `#hhPhase`, the Clubhouse league header (index.html:13317-13322), still prints
  **"Setup — invites open"** and **"Squad formation"** — the two strings the commit
  says it retired, one of which it says contradicts D112.
* `renderLeagueRecord` (index.html:17511-17512) prints **"Forming — invites open"**
  and **"Squad formation"**.

So the same league is still described two ways in one session: the switcher chip says
"Squads drawing", the room header says "Squad formation". Preflight 20 cannot see
either, because it only compares the two tables to each other.

`leagueStage(m)` also cannot answer `preseason`/`final` for a non-current membership
and falls back to `'season'`, so the switcher labels a not-yet-teed-off league
"Season live". The function documents this; the switcher shows it anyway.

## 10 · The endgame line (D126/D127)

Two factual errors against the engine.

**"The leader carries +10 in."** is printed for every `cup_final` league.
`enter_cup_final` sets `head_start = case when st.structure = 'squads2' then 10 else 0 end`
(20260828170100_cup_final_race.sql:226) and gives solo finalists no head start at all.
So on squads3, squads4 and solo the sentence built to explain how the title is decided
states a head start that does not exist.

**The seat line contradicts it on the default structure.** For `squads2`,
`season_scenarios` sets `v_k := 1` (both squads reach the Final; the race is for the
+10 seed) and `climbCut` returns `{K:1, line:'TOP SEED · +10'}`. So the note renders
`TOP 1 ADVANCE TO THE CUP FINAL` immediately above `The top 2 squads seed into a
four-week Cup Final`. The session made the first half louder ("ADVANCE" →
"ADVANCE TO THE CUP FINAL") and added the second half beside it.

`endgameLine`'s `seats` is `structure === 'solo' ? 2 : (structure === 'squads2' ? 2 : 2)` —
a three-way ternary that always returns 2. It happens to be right for every current
structure, which is why nothing caught it, but it reads as if it varies.

D127's "NOBODY TO RACE YET" and D126's endgame sentence are web-only. `ClimbMath.note`
on the phone still returns `"EVERYONE ADVANCES — 1 CONTENDER, 2 SEATS"` for a
one-contender league — and the Swift test still pins that string. The badge word (IN)
did cross. Preflight 20 does not cover the note.

## 11 · Errors (Q-08)

The allowlist is a good idea executed loosely. Four of its eleven alternatives —
`isn't open yet`, `is still being set up`, `has wrapped`, `season is finished` — match
no `raise exception` in any migration or edge function; they were written from memory,
not from the source. `is empty — draw again` appears twice in the same regex.

`looksLikeOurSentence` is not conservative enough to be the last gate before showing
raw text to a golfer. `\berror\b` does not match "TypeError" (no word boundary inside
the word), so
`"Cannot read properties of undefined (reading 'league')"` — 52 chars, capital first
letter, spaces, no underscores, no `::` — passes every test and is printed verbatim,
e.g. `"Could not join. Cannot read properties of undefined (reading 'league')"`. Before
this change it fell to the shrug.

## 12 · The formation guard (Q-08) — a hard dead end

`renderFormation` disables the Draw button when `pool.length < CS.squads.length`. The
server's rule is `total < sq_n` where `total` is **every** league member
(20260722210000:45), not the unassigned pool. One golfer joining a 2-squad league after
the first draw gives `pool = 1 < 2`: the Draw button renders disabled with the wrong
number ("1 in · need 2"), and because "Start the season" is gated on `!pool.length`
that button disappears at the same moment. The Pro can neither deal the new joiner nor
start the season, from a UI the server would have accepted. Three prod leagues sit in
`phase='draft'` today.

## 13 · The install nudge (Q-13)

Moving it off the ⊕ is right, and `busy()` now tests `.active`, which is the class
`switchView` actually sets — the commit's own note about `.on` vs `.active` was a real
catch. But `csHideInstallNudge` re-shows the banner on `else if(shown)`, and `dismiss()`
never resets `shown`. So: tap ✕ → banner hides → tap any tab → `switchView` calls
`csHideInstallNudge` → `busy()` false, `shown` still true → `display='flex'`. The
dismissed banner comes back on the next navigation and every one after it, for the rest
of the session.

## 14 · The tests

`tests/preflight.mjs` 18 is genuinely good. 19 counts rather than associates. 20 is a
real cross-client guard with a narrow blast radius (it only covers the six labels).
`db-checks` 15/16/17 are well-aimed; 16's description mentions "or an unseated member"
but the SQL only detects empty squads.

`tests/app-tests.js` is where the trust breaks. The two lock assertions live inside a
`.then()` that resolves **after** `const fails = R.filter(...)` and after the function
returns, so `{ total, failures }` — the number the commits quote — cannot include them.
A share sheet that stopped printing the join URL would still report **PASS**; the only
signal is a console line printed after the summary. The comment acknowledges the timing
and treats it as cosmetic.

And nothing at all was committed for the session's new client functions. There are zero
references to `vsShort`, `floorSentence`, `endgameLine`, `seasonNote`, `seasonState`,
`leagueStage`, `inviteMessage`, `openInviteSheet` or the pot trio anywhere under
`tests/`. The commits report "12 invite assertions", "8 pot assertions across both
roles", "8 endgame assertions across both dials", "Ten role × stage assertions",
"7 stage/state assertions" — 45 assertions that exist only as console drives someone
did once. Five of the findings above are in exactly those functions, and every one of
them would have been caught by the assertions the commits say were made.

## 15 · Smaller things worth a line

* `#postBtn` still says **"Enter at least one nine first"** when the nines *are*
  entered and the rating is missing, because Q-22's new branch nulls `state.lastPost`
  before the handler's first guard. The panel two inches away says "Pick a tee".
* `seasonNote` calls `firstTeeText()`, which falls back to `defaultStart()` for an
  unlocked league — so a Pro mid-wizard is told "the season starts Sat Sep 5" about a
  date nobody has committed to.
* `switchView`'s wizard gate runs before the `v==='draft' && phase==='setup' → 'wizard'`
  remap two dozen lines down, so the one route `switchView` invents for itself skips
  the gate the commit says "every route passes".
* The web's `proName` fallback is lowercase `'the Pro'` and is used sentence-initially
  ("the Pro is setting the bylaws."); the Swift sibling capitalises it.
* `theirs(vsShort(pvi))` is now a no-op — `vsShort` dropped the word "your".
* A root `package.json` + `package-lock.json` now exist for two dev-only packages.
  `netlify.toml` pins `command = "bash ./stamp-version.sh"`, but Netlify installs
  dependencies from a base-directory package.json before running the command, so every
  client deploy now depends on an npm install that nothing in the build uses.
* `Cup-Season-Guide.md` still describes "Name it, add golfers (find them by name or
  @handle), set the buy-in" as the create flow. Q-17 removed the email half; the
  wizard has no add-golfers step either (`#wFind` lives in the league-less Clubhouse).
* `#invUrl` is assigned an id nothing reads.

## Verified against the engine or prod, and found correct

* `cup_points` half-open at −1.0 — client now matches (baseline:251).
* Champion-absorbs penny rule — matches `20260828170000:78-82`.
* Solo leagues cannot take a floor penalty — `close_month` drives from `squad_members`.
* `live_round_players_live_round_id_fkey` exists in prod; M-085's hint is correct.
* `league_settings` carries table-level SELECT for `authenticated` in prod, so
  `select *` picks up `buy_in_note` / `buy_in_due_on` with no column-grant work — the
  `profiles` landmine does not apply here.
* `lock_league`'s revoke/grant signature has all 19 parameters in the right order.
* No prod league is currently half-locked (`locked_at` set, `phase='setup'`).
* `state.emails` still exists; the retained fallback will not repeat `staged`.
* `preflight` runs 20/20 green with the single expected "pending deploy" warning; the
  free-identifier check matches all four script blocks, not two.
