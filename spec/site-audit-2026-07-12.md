# Cup Season — Full-Site Audit (fine-tooth comb)

2026-07-12 · v23.60 · every view scored against spec-v1.0, product-vision-v1.0,
personas-dashboards-v1.0, and the live code. Items numbered A1, B2… for
work-through. Status: batch 1 (P0, A1–A12) SHIPPED v23.61. Batch 2 (B1–B4, C1) SHIPPED
v23.62 — decisions: pre-kickoff phase named "At the starter"; NO global
progress bar (C3 dropped — week-by-week progress detail moves to the
calendar/timeline build, D3/task #16). Batch 3 (D2 pot + D3 calendar-as-tab
+ C2 kickoff post) SHIPPED v23.63 with migration 20260712130000 — decisions:
buy-in marks post to the board; Calendar is a first-class 5th tab; intro
hero copy rewritten; pilot error bar OFF by default (/?debug re-enables).

Root cause of most of it: the prototype-era markup and render functions carry
demo defaults ("SNDYCUP", "16 Joes", "$1,200") that the real-league path never
overwrites. `resetToBlank()` clears the DATA arrays but not the STRINGS, and
several renderers still compute from demo-shaped state (`state.emails`,
`PLAYERS[]`, `feed.who==='You'`) instead of DB truth (`CS.members`,
`v_individual_standings`, `v_rounds_ranked`, `buy_ins`).

**Sweep rule going forward: no string a real league can see may live in markup
or a constant — it must render from CS/DB state or be hidden.**

---

## P0 — Trust breakers: demo data shown as real (fix first)

- **A1. `renderPhase()` setup branch** hardcodes `SETUP · CODE SNDYCUP · 9 OF
  16 JOINED` for ANY real league in setup. → `SETUP · CODE {league.code} ·
  {CS.members.length} JOINED`.
- **A2. Hub "Members & invites" row** — static `16 JOES · CODE SNDYCUP`
  (markup, never touched). → real count + code; see D1 for the full build.
- **A3. Home setup checklist step 2** — static `CODE SNDYCUP · 9 OF 16
  JOINED`. → real code + joined count.
- **A4. `homeDraft` hero** — static `12 JOES IN THE POOL`. → real
  `unassignedMembers().length`.
- **A5. Sidebar footer** — static `16 Joes · 4 squads`; brand says `Season
  III`. → real member count + structure + season number, or drop the line.
- **A6. On the line tile** — `renderBylaws()` computes `state.stake * 16`
  (SIXTEEN, hardcoded). → `stake × CS.members.length`, splits from
  league_settings (fallback 60/25/15).
- **A7. `renderPot()` real branch** derives player count from **wizard email
  slots** (`state.emails`) — wrong the moment anyone joins by code, and
  irrelevant after setup. → `CS.members.length`; collected from `buy_ins`.
- **A8. Counting rounds + floor card dead** — `yourMonthCredits()` counts feed
  rows where `who==='You'`; real feeds use display names → always 0. Real
  users see "2 counting rounds to go" forever. → read `v_rounds_ranked` for my
  member_id, current month, `month_rank ≤ cap` (0.5 credit for 9-hole).
- **A9. You tab entirely demo-fed** — `renderIndStats()` reads the `PLAYERS[]`
  demo array; `resetToBlank` zeroes it, so real leagues show 0 rounds / — /
  zeros in "Your season," and the Points King table lists just "You · 0". →
  wire to `v_individual_standings` (race + awards) and `v_rounds_ranked`
  (my rounds, avg/best PvI). Most Improved needs index history — snapshots
  exist now; v1 can show "— · from Wk 1" until 2+ snapshots.
- **A10. Home "Your index" delta** — static `▼ 0.3 this month`. → compute from
  snapshots when available, else hide the delta line.
- **A11. Chart footnote** — static `CUP LINE = TOP 2 AT W36 ADVANCE`. → real
  week count + structure-aware line (2-squad leagues: both advance).
- **A12. Verified League panel in hub** — advertises the tier we KILLED
  (monetization revision 2026-07-12). → remove outright. Pro Shop panel copy
  also predates one-membership; reframe or mark as roadmap, and the dead
  "Upgrade the league" button (Stripe parked) becomes "Coming at launch".

## P1 — Navigation & orientation (the "which league am I in" problem)

- **B1. League switcher is a hidden `prompt()`** on the league name, hinted by
  a single boot toast. → real affordance: league name + chevron (⌄) always
  visible; tap opens a bottom sheet listing every membership (marker, name,
  phase chip, role), plus "Your clubhouse" (league-less home) and "Start or
  join a league". Same sheet from the profile hub's league list.
- **B2. No context reinforcement** — Home board, standings, pot all switch
  silently with the league. → the board card and standings eyebrows carry the
  league name; the switcher sheet is one tap from anywhere (header).
- **B3. Tab labeled "League" shows Pro Shop upsells above the fold** in a real
  league. → reorder: league header card (name · code · phase · kickoff · the
  Pro) first, then members, pot, squads, bylaws, calendar strip, upgrades last.
- **B4. Back-of-house views (pot, draft) have no league identity** — fine on
  desktop sidebar, headerless on mobile. Covered by B1's persistent header.

## P2 — Kickoff & season clarity ("when does this thing start?")

- **C1. No pre-season state exists.** After squads form + start_season, the
  header says `Wk 1 / N` even when starts_on is next Sunday. → new phase
  wedge: when `today < starts_on`, header reads `KICKOFF SUN JUL 19 · 7 DAYS`,
  and homeSeason shows a kickoff hero (first tee date, countdown, squads
  locked, "post practice rounds — they hit your card, not the season").
- **C2. Kickoff moment is silent.** → daily_season_tick posts to the board
  when a season flips live: "⛳ SEASON I IS LIVE — Week 1. First counting
  rounds start now." (server-side, rides existing rails).
- **C3. Week-progress is a number, not a feeling.** → thin progress bar under
  the header (weeks elapsed / total, Cup Final zone shaded gold), month
  boundary ticks. One element, all views.
- **C4. Month machinery invisible.** Personas: "Week closes Sunday · month
  closes on the 1st". → the Season stat card's sub-line rotates: days to week
  close / month close / Cup Final start (nearest wins).

## P3 — Build-outs the audit demands (each its own work item)

- **D1. Members & invites page (real).** Nothing lists league members
  anywhere except squad formation. → hub row opens a members view: every
  member (marker, name, @handle, index, role badge, squad), pending invites,
  invite code + share link, Pro actions (remove member, resend invite,
  transfer Pro — confirm-gated, ledger-logged).
- **D2. Pot page (real).** Wire `buy_ins`: target = stake × members, collected
  = sum paid; payer list = all members, Pro taps to toggle paid (RPC,
  security-definer, logged), non-Pro read-only. Splits from league_settings
  (006 columns) with 60/25/15 default. "On the line" tile reads the same
  source (kills A6/A7 double-entry).
- **D3. Calendar v1 — the strip, not the dream.** Task #16 (declared rounds,
  watch list, projections) stays post-events-engine, but a zero-schema
  calendar strip is buildable NOW from season dates alone: kickoff, month
  closes, Cup Final start, season end, "week closes Sunday". Lives on the
  League page + a line on Home. Personas' anticipation features layer on
  later without rework.
- **D4. You tab: season history section** — per-league season record rows
  (personas' "League History" seed): league, season, finish, points. v1 reads
  current memberships + standings; archives accumulate as seasons close.
- **D5. Wizard prefill polish** (punch #1, still open): league name field
  ships EMPTY with placeholder (currently pre-filled "The Sunday Cup" — real
  leagues get named that by accident); commissioner email done (read-only).
  Full wizard rebuild stays task #9.

## P4 — Polish / consistency (batch into any pass)

- **E1.** `copycode` fallback copies literal "SNDYCUP" when `shareInvite` is
  missing — make the fallback read the codebox text instead.
- **E2.** Points King fine print says "15% of the pot" — read the settings
  split once D2 lands.
- **E3.** Announce rows: pin the latest announcement to the top of the compact
  board card (personas: announcements ≠ chat).
- **E4.** `#paidChip` / `#hubPotSub` demo strings in markup — covered by D2,
  listed for the sweep.
- **E5.** Draft view "Restart" link + "Draft night · snake" eyebrow visible
  pre-render in real leagues — hide behind demo flag.
- **E6.** Demo diorama alignment (Sunday-season model) — old punch #9,
  cosmetic, unchanged.

## Deliberately NOT in this list

- Live rounds / tee sheet (task #11), course cards (#12), photos (#13),
  events-engine workstreams 3–8 (task #5), Ryder (#6), migration 008 (#4) —
  already tracked.

## Suggested batches

1. **v23.61 "no more ghosts"** — A1–A12 (strings + wiring; client-only except
   nothing — all client).
2. **v23.62 "you are here"** — B1–B4 + C1 + C3 + C4 (switcher, header,
   kickoff state, progress bar; client-only).
3. **v23.63 "the pot is real"** — D2 + E1/E2/E4 (one migration: buy-in RPC +
   splits read; client).
4. **v23.64 "the clubhouse roster"** — D1 (one migration: remove/resend/
   transfer RPCs; client).
5. **C2 kickoff post** — rides the next server migration.
6. **D3 calendar strip + D4 history** — client-only, slot anywhere.
