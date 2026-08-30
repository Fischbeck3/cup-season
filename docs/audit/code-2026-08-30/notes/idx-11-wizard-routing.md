# idx-11 · `index.html` 12372–13427 — blank slates, phase/wizard/routing, init

Read every line of 12372–13427 plus the call sites needed to judge them:
`state` initialiser (3812–3821), the header/wizard/hub markup (2775–3400, 3748),
`renderSetup`/`seasonStartDate`/`seasonEndDate` (7591–7625), `leagueStage`/
`STAGE_LABEL`/`stageLabel` (5810–5875), `renderStats`' complete-season branch
(9960–10070), `renderHomeHero` (10420–10527), `enterLeague`/`applyBylaws`/
`resetWizard` (14540–14915), `lockBylaws` + the `#lockBtn` handler + `lockErr`/
`lockedPhase` (15641–16160), `#wCreate` (18068–18100), the init tail (13415–13427).
Cross-checked against `spec/decision-log.md` (D71, D120, D122, D126/D127),
`supabase/migrations/20260726100000_league_cancellation.sql`,
`20260829091000_weekly_clash.sql`, `20260829220000_lock_league.sql`,
`20260712110000_enable_cron_spine.sql`, and read-only `supabase db query --linked`
against prod (`seasons`, `league_settings`).

## The session's own changes inside this slice

Only three hunks of `34d20b6..HEAD` land in 12372–13427:

1. `renderPhase`'s `#phaseSub` draft branch now reads `${STAGE_LABEL.drawing}` (12657).
2. The `.copycode` toast copy (13376).
3. The install-nudge `busy()` / `csHideInstallNudge` block (13391–13401), plus the
   banner's relocation to the top of the viewport (markup, 3748).

All three were reviewed harder than the rest. Two of the three carry defects
(F2/F3/F4 below), and the first one is the *invisible half* of a D120 sweep that
left the visible halves untouched (F8).

## What is genuinely wrong

**The wizard's season start survives a league change (F1, worst thing here).**
`resetToBlank()` goes out of its way to null `state.seasonStart` / `state.seasonEnd`
and to reset `state.finish` with the comment *"never carry one league's dial into
the next"* — and then leaves `state.startISO`, which is the field that actually
becomes the new season's `starts_on`. `seasonStartDate()` reads `startISO` first;
`renderSeasonDates()` only fills it `if(!state.startISO)`, so it is never refreshed;
`applyBylaws()` writes League A's start into it on entry. A Pro who is in League A
and taps "Start a league" gets League B's first tee pre-set to League A's — and
`durWeeks` rides along too, because neither `resetToBlank` nor `resetWizard` clears
it. Lock then sends that date to `lock_league` verbatim. Prod holds three seasons
whose `starts_on` predates their league's `created_at` by 40–159 days.

**The install nudge comes back after you dismiss it (F2).** `dismiss()` sets the
localStorage flag and hides the node but leaves `shown === true`; the new
`csHideInstallNudge()` runs at the end of every `switchView()` and its
`else if(shown) n.style.display = 'flex'` re-shows it. Dismiss it, tap any tab,
it is back — for the rest of the session, on every navigation.

**The nudge's new home covers the header (F3), and its BUSY list names the wrong
view (F4).** Q-13 moved the banner off the ⊕ and put it at `top: safe-area + 8px;
z-index: 24` — directly on top of `.hdr` (`position:sticky; top:0; z-index:20`),
whose only two controls are `#hdrSearch` and `#hdrLogo`. And `BUSY` lists
`view-record` (the three-card *menu*) where the comment says "the composer";
the composer is `#view-post`, which is not in the list — so the surface the guard
was written for is the one it does not guard, and `switchView('post')` will
explicitly re-show the banner over it.

**A guard on a value that cannot occur (F5).** `enterLeague` collapses
`league.phase === 'complete'` into `state.phase = 'season'`. The file already knows
this — `renderStats` has a `done` branch with a comment naming the mapping, and
`#hhPhase` checks `CS.season.status === 'complete'`. The danger-zone gate does not:
`state.phase !== 'complete'` is always true, so the Pro of a crowned league is shown
"Cancel this league — the season is under way", and `request_league_cancel`'s honest
refusal ("completed seasons are the record book…") is filtered by `humanError` into
"Something went wrong — please try again" because it starts lowercase and so fails
`looksLikeOurSentence`'s `/^[A-Z]/` test.

**A roster count that can only ever be 1 (F6).** A-W2 removed `#emailSlots`;
`renderEmails()` now returns on its first line and nothing writes into
`state.emails`. `wizRoster()` therefore returns 1 forever, which dims every squad
option to 40% opacity, prints "1 golfer staged — solo fits", toasts on every squad
tap, and makes `wizPortrait()` draw a one-player pot.

**Two week-counters that disagree (F7).** `totalWeeks()` computes
`ceil((e−s)/7d)`; the server computes `ceil((ends_on−starts_on+1)/7)`. Because
`seasonEndDate()` returns `start + 7N` days, every season the current client locks
has a span that is an exact multiple of 7 (prod: 42, 91, 119, 182, 273), and the
two formulas differ by exactly one. On the final day the engine mints
`week_clashes.week_no = N+1` while the header still reads "Wk N / N", `renderClash`
draws that week's window six days past the season end, and the settle predicate
does not fire until a week after `ends_on` — by which time `ensure_week_clash`'s
`status in ('active','cup_final')` gate has closed.

**D120 is half-applied (F8).** The one site the session touched (`#phaseSub`) is
inside `<div class="title" style="display:none">` and is never seen. The visible
sites in this same slice still print the exact strings D120 retired: "LIVE NOW —
CAPTAINS READY" (12674), "Setup — invites open" / "Squad formation" (13317–13318),
"SEATS OPEN" (13285, 13291) — while Home and the Clubhouse row now read
`STAGE_LABEL`. The five-way contradiction the decision was logged to kill is still
live, one screen apart.

## Smaller things

- `#phaseSub` is dead scenery (F9): eleven lines of branching, including the only
  `isCupFinal()` consumer with no `complete` case, rendering into a hidden node.
- Calendar day cells are `<div data-cd>` with click handlers — no keyboard or
  screen-reader route to a day (F10); the column heads are single letters with no
  accessible name.
- `Number(b.pvi||-99)` sends a level (0.0) exhibition card to the bottom of the
  Major's board while its own row says "LEVEL" (F11).
- The bylaws card derives allowance/verification/penalty from the preset index
  rather than the settings row `CS.settings` now holds (F12, latent — prod is
  currently consistent).

## Outside the range, flagged because the brief asked

The `#lockErr` surface and the lock handler live at **16093–16159**, not in this
slice. I read them anyway. `lockErr()` and the `btn.disabled` discipline are sound
(`disabled=false` is on the single fall-through path; a second click is safe
because `lock_league` is idempotent on `locked_at`). But `lockedPhase()` **drops
the `{error}`** — the whole point of that probe is to distinguish "the commit
failed" from "the client tripped on the way home", and a transient read error
returns `{data:null, error}`, which it reads as *not locked* and narrates as
"Lock failed." on a league the server just locked. That is F13; it is the same
failure shape Q-01 was written to end, moved from the commit to the probe.

Also noted and not filed: `lockViaRpc`'s `already_locked` branch (15678) writes
`state.seasonStart/End` from the wizard's *recomputed* `seasonStartDate()/
seasonEndDate()` rather than from the `data.season` the server just returned, so a
re-lock after a dial change shows a span the DB does not hold; and the wizard
Cancel at 16184 still gates on native `confirm()`, which CLAUDE.md's setup-QA S4-03
landmine says installed PWAs swallow.

## Coverage gaps

Nothing in 12372–13427 went unread. I could not exercise anything at runtime
(no servers, no browser), so the header-overlap geometry (F3) is reasoned from the
CSS box model rather than measured, and F7's downstream clash behaviour is read
from the migration rather than observed on a season that has actually reached its
last day.
