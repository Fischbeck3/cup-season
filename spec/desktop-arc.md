# Desktop arc — the front door & the big screen

*Design brief for a UX-lane session (level 5–6 of the hierarchy). Talk-first:
this file scopes the work; nothing builds without an explicit "build it."
Design passes ride separately from structural builds (CLAUDE.md rule 3) — no
schema, no RPCs, no IA changes (Home/Crew/⊕/You is settled).*

## Why this arc

The welcome page is nine words. *"Rally your crew. Post real rounds. Take the
cup."* — then an email field. The splash art is excellent and the auth path is
fast, but a stranger learns nothing: not that captains draft squads, not that
real handicapped rounds from any course count, not that points accumulate
across months into an endgame, not that the pot is kept on the books
between friends.

Desktop is where that stranger matters most. Member signup mostly happens on a
phone (an invite link in the group chat), but **the Pro — the one person who
has to *get it* deeply enough to bring a whole crew — evaluates on a big
screen**: a link a buddy sent, opened at a desk, read for three minutes. There
is no Pro checkout today (Stripe parked); "Pro signup" = create a league. The
door's job is **convince, then start.**

Meanwhile the signed-in desktop is a stretched phone: a 232px sidebar
(index.html:106) beside one mobile column capped at 1120px. Serviceable, not
elevated.

## Current state (line anchors)

- **Tokens / design system:** index.html:30–79. Read the comments — they ARE
  the brand spec. Dusk green-black ground; `--brand` fairway `#2FA46A`
  (primary action; deliberately not the neon sensor-green); `--gold` champagne
  **EARNED only** (leads, pot, trophies — never decoration); `--dawn` links &
  live; `--pos` neon is SEMANTIC only; squad quad `--sq0..3`. Three type
  voices: IBM Plex Sans (now), IBM Plex Mono (the scorer's tent), Charter
  serif (memory & honor — hero numbers, headlines, trophies; hookup at
  index.html:1406). Radii 16/10/24. Two shadow levels. **One motion physics:
  `--roll: cubic-bezier(.16,.84,.36,1)` — fast start, long soft settle, like a
  putt dying at the hole.** Light theme = same bones, dawn palette (D35:
  light-first, dark one tap away).
- **Onboard CSS:** index.html:1130–1218. The `.onboard` layer is
  `position:fixed; overflow-y:auto` — a scroll container; read the
  auto-margin centering comment at 1134 before adding content. Desktop ≥760px
  composition at 1143–1155: lockup anchored left, schema art owns the right
  (`min(60vw, 880px)`), 54px serif h1.
- **Onboard markup:** index.html:1484–1591. Schema art (four squad-color shot
  tracers dive to a flagged hole, radar rings answer) 1486–1514 · hero
  1516–1531 · the door `#obDoor` 1533–1551 (email OTP + invite code + the
  legal fine-print line — that line stays, it's compliance) · golfer card
  1552–1578 · version caption `#obCaption` 1587 (deploy diagnostic — stays).
- **Motion vocabulary that exists:** `csWipe` (squad-panel splash), `csDraw`
  (tracer line draw), `csUp` (rise-fade, staggered .35–1.5s), `csRing`
  (radar), `csPulse`, `csFade`. Reduced-motion kill at 1184. Extend this
  vocabulary; don't invent a second one.
- **Desktop shell (signed in):** sidebar 103–138, `.wrap` 1120px cap 143,
  tabbar hides ≥960px at 1107, hover states gated `@media(hover:hover)` 1294.

## The three strands (staged; each gets its own "build it")

### Stage 1 · The story on the door
The signed-out layer grows an explanation below the fold — **desktop AND
mobile** (decided: the group-chat invite link opens on a phone; mobile gets
the same sections, lighter). The door itself stays above the fold — a
returning member's time-to-signin must not regress; measure the
splash-to-door time first and keep it. Sections to write, in the app's voice,
roughly:

1. **What this is** — a season-long cup for your real crew. Captains draft
   squads; everyone posts real handicapped rounds from anywhere; points build
   for months; the endgame settles it.
2. **How a round counts** — post from any course, hole-by-hole or just gross.
   Your number comes from your scores (establishes at 3 rounds). Beat your
   number, score for the squad. Every point has a receipt.
3. **The season shape** — months, caps and floors in plain words, then the
   Cup Final (or the points table — the Pro's dial).
4. **The pot** — ledger language: every dollar on the books, money moves
   between friends ("never held" retired — D39). Bragging-rights leagues
   exist ($0 stake).
5. **For the Pro** — you set the structure with the wizard (roster, endgame,
   pot split, fine print); the app runs the season: standings, receipts,
   month closes, the board. Bring the crew you already text.
6. **Live games on the tee** — Match Play, Wolf, Skins; guests get a claim
   link and walk in with their round already posted (the growth funnel).

Illustrate with **drawn inline-SVG vignettes in the schema-art style** (like
the four-tracer hole), not real screenshots — screenshots go stale and bloat
the single file. Real DOM copy, no fetches; this is also the only page Google
ever reads.

### Stage 2 · Motion aligned with the style
One orchestrated moment beats scattered effects. Candidates: scroll-triggered
`csUp` reveals per section (IntersectionObserver in the first classic script
block, near the forceReveal net); tracers that draw when their section enters;
a count-up on an example points figure; hover lift (desktop only) using the
existing two shadow levels. **Everything on the `--roll` curve,
transform/opacity only.** The splash timing budget is fixed — new motion lives
below the fold, not in front of the door.

### Stage 3 · The big-screen shell
Scope decided: **all three surfaces**, in this order (the Pro's conversion
path first) — propose each layout, then build it on its own "build it":
1. **The wizard** — desktop form composition, fine print beside choices
   instead of stacked.
2. **Home** — feed + right rail (standings pulse, coming up, pot) two-column.
3. **League Room** — standings and board side-by-side.
The 232px sidebar itself can carry more (season pulse, month meter, pot).
Layout may change; nav structure may not.

## Voice & canon (non-negotiable on the door)

- Plain language, second person. "Your number," "beat your number by 3" —
  never PvI, never differential.
- "The Pro," never commissioner. No prices anywhere (pricing PARKED). No
  tiers, no "verified" anything, GHIN never a product.
- Pot: ledger language — "every dollar on the books"; "never held" is
  retired (D39: collection/distro stays open as a future service).
  legal.html stays present-tense factual, untouched.
- Golf-honest tone; no growth-hack hype. Vary punctuation (the em-dash
  monoculture was deliberately broken once — don't rebuild it).
- Raw material to mine: CLAUDE.md's opening paragraph (the one-breath pitch),
  `spec/product-vision-v1.0.md` (five principles, the Cup Season Test),
  `cupseason-2030-prospectus.html` + `pilot-welcome.html` +
  `design-launch-brief.html` in the repo root (local artifacts, not deployed
  — prior worked copy), the wizard's covenant/fine-print voice.

## Landmines (each already cost real time)

1. **Never gate visibility on an animation.** Every new `fill:both` entrance
   must be covered by the forceReveal net (index.html:2509) — extend its
   selector list — and scroll-reveal sections must be VISIBLE by default when
   JS or motion is absent. (Memory: landmine-animation-gated-reveal.)
2. **Reduced motion:** the `.onboard *{animation:none}` kill at 1184 must
   cover everything new; IntersectionObserver work checks
   `prefers-reduced-motion` before animating.
3. **iPhone PWA freeze fix:** `.onboard.hide` pauses ALL onboard animation
   (1157–1161). Any new infinite loop lives under `.onboard` so it pauses, or
   manages its own pause.
4. **Browser-MCP screenshots time out on the splash** — verify with
   `javascript_tool`/`read_page`; screenshot only after the splash settles.
   `/?exit` resets auth so you can see the door while signed in.
5. **Mixed middot encodings** in index.html — anchor Edits on ASCII lines.
6. **`__CS_VERSION__` untouched** (index.html ×2 + sw.js); `#obCaption`
   stays present and legible.
7. **Classic ↔ module boundary:** presentation JS goes in the first classic
   block; anything module-side needs a `window.*` bridge.
8. **New served assets must join the dist allowlist** in `stamp-version.sh`
   or they 404 in prod. Prefer inline SVG — zero new assets.
9. **Perf:** transform/opacity only, `will-change` sparingly, no CLS when the
   story loads; this same file boots on phones at the first tee.
10. If any signed-in surface is touched: `esc()` all user data; gate real
    reads with `!state.demo`.

## Verify before every commit

`python -m http.server 8791` → browser MCP → **clear SW + caches first**
(`getRegistrations().unregister()` + `caches.delete`) → drive the door at
desktop (1280×800) and mobile (375×812), light and dark, reduced-motion
spot-check → console clean but for the one known boot rejection → confirm
returning-member time-to-door unchanged.

## Decisions (resolved with the user, 2026-07-19)

- **Founding League hook on the door: NO.** The program exists; the front
  door doesn't advertise it. No pricing or free-forever language anywhere on
  the door.
- **Mobile gets the story: YES.** Same sections, lighter, below the door.
- **Stage-3 scope: all three** — wizard, Home, League Room, in that order.

## Still open (raise in the design plan; defaults stand unless argued)

- **D-a · Story placement:** default = below-door scroll on the same
  signed-out layer (single file, door stays instant). A separate route needs
  a case.
- **D-e · Vignette style:** default = drawn schema-art inline SVG.
  Screenshots need a case.

*Ship gate for Stage 1: a golfer who has never heard of Cup Season can read
the door for 60 seconds and explain the game back — draft, post, months,
endgame, pot.*
