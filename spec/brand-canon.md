# Cup Season — Brand Canon

Version 1.0 · Growth/Launch lane · 2026-07-17

**What this is:** the single page that says what the brand *is* — what's decided,
where it's going (the 2030 prospectus), and what's still open. It codifies
decisions already shipped (v23.106 de-Arccos → v23.130 Batch A → v23.131 Batch B);
it invents nothing at the vision or principles level. In the hierarchy of truth
this doc lives at the **UI level**, governed by `product-vision-v1.0.md` and the
founding prospectus above it. Any future designer starts here.

**What's decided:** the promise, the voice, the palette + its one rule, the type
system, the motion signature, the guardrails.
**What's open:** the mark (§6 is the exploration brief — Jerecho is explicitly
not set on any logo), merch beyond the Founding hats, and the photography
library (nothing shot yet).

---

## 1. The promise

> **Cup Season is where amateur golf counts.**

Counts three ways, all load-bearing: your rounds are **scored** (real handicaps,
real points), they **matter** (a season, a pot, someone chasing you), and they
**add up** (the Record — a golf life that accumulates for decades). Every brand
artifact should express at least one of the three; the best express all three.

Supporting promises, one per persona (from the vision doc, verbatim):
- To the Pro: *"I'll run the league so you can enjoy it."*
- To the golfer: *"Every round counts."*

The 2030 north star ("the operating system for amateur golf competition") adds
the four objects the brand will increasingly be *about*: **Crew** (the people),
**Cup** (the competition, every format), **Rivalry** (the fuel), **the Record**
(the memory — the 40-year archive nobody else is building). Iconography,
naming, and campaign structure should map to these four, not to app features.

## 2. The character (if it were a…)

**A person:** the friend who has run the Saturday game for fifteen years. Knows
everyone's index without asking, never lets a bet get ugly, remembers your first
birdie better than you do. Competitive and generous in the same breath. Keeps
the book — and the book is why the group still exists.

**A clubhouse:** not the gated club. The good muni's back room at dusk —
dark wood, low champagne light on the trophies, this season's standings on the
wall. Anyone can walk in; the board is earned. (This is literally the visual
system: "the trophy room at dusk" is the dark theme, "the morning tee sheet"
is the light one.)

**A magazine:** an almanac crossed with a club newsletter. Serif headlines that
tell stories, box scores in monospace, one great photo of Saturday morning.
Reads like the record of something real, never like content.

**Emotional register:** proud, warm, a little ceremonial, quietly funny in the
crew's own voice. Never hype, never urgency, never shame.

## 3. Voice (already shipped in-product — these are laws, not suggestions)

- **"The Pro,"** never "commissioner" (DB keeps the internal name; UI never).
- **Named bands, never math jargon:** "beat your number by 0.6," never
  "PvI"/"differential" on any user surface.
- **"Tracked, never held"** — the money sentence, verbatim, everywhere money
  appears in marketing or store copy. It is the anti-"betting app" vaccine
  (GTM failure mode #5).
- **"Run it back"** — the renewal verb. Seasons aren't "resubscribed."
- **The join covenant** doubles as the fairness promise wherever fear appears
  (design-review recommendation, standing).
- Notifications and marketing inherit the vision rule: **only meaningful ones.**
  If it wouldn't be said across a cart at the turn, don't say it.
- Numbers are spoken as story first, table second: "leads by 25 · 25 back."

**Banned vocabulary:** engagement-speak ("don't miss out," "you won't
believe"), streak-shame (streak mechanics were killed by the one-more-round
rule), sportsbook framing (odds, action, units), corporate golf-speak
("synergy scramble"). The crew's own vocabulary (already in reactions) beats
any invented slang.

## 4. The visual system (LIVE — v23.131 tokens, verified in index.html 2026-07-17)

Two rooms, one club:

### The trophy room at dusk (dark — the app's home mood)
| Token | Hex | Role |
|---|---|---|
| Dusk | `#0A0E0C` | the ground (green-black, not gray-black) |
| Ink | `#ECEEF2` | text |
| **Fairway** | `#2FA46A` | **primary action + brand** — deep Masters green |
| Pine | `#0E3B24` | the tee, gradient partner, depth |
| **Champagne** | `#D8B25A` | **earned only** — see the one rule |
| Dawn | `#63ADFF` | links · live |
| Mint | `#43E07C` | semantic only: up, positive, birdie, LIVE dot |
| Squad quartet | `#57A8FF` `#FB8B4B` `#A78BFA` `#2FD3BE` | squads (blue/orange/violet/teal) |

### The morning tee sheet (light/"paper")
Paper `#EFF2EE` ground · fairway deepens to `#15743F` · champagne goes ink-dark
`#9A7418` · dawn `#2C6E9E`. Same system, morning light.

### The one rule (the most important sentence in this doc)
> **Champagne gold means *earned* — a lead, the pot, a trophy, a founder,
> movement up. It is never chrome.**

Gold on a button, tab, or nav is a defect. This rule is *why* the brand reads
premium: scarcity of gold is the design-system version of "the board is
earned." (History: gold carried brand chrome v23.106–130 to solve the Arccos
problem; Batch B moved chrome to fairway and made gold strict. Both moves were
deliberate; don't relitigate either without a decision-log entry.)

### Type — three families, three jobs
- **Serif** (Charter/Iowan/Palatino stack) — **the story.** Headlines, hero
  numbers, anything with ceremony. Speaks in sentences.
- **Mono** — **the record.** Eyebrows, labels, points, standings, tabular
  numerals always. Speaks in entries.
- **Sans** (system) — **the workhorse.** UI controls, body, forms.
Serif never on controls; mono never for prose; no fourth family, ever.

### Shape & motion
- Radii tokens 16 / 10 / 24 (cards / controls / sheets) — Batch A.
- **One easing everywhere: `--roll` `cubic-bezier(.16,.84,.36,1)` — "the
  roll-out," a putt dying at the hole.** Motion is how the brand feels alive
  without being busy. Nothing bounces; things *roll out and settle*.
- Backgrounds may carry the faint dawn/champagne radial glows (shipped) —
  atmosphere, never decoration on components.

## 5. The 2030 trajectory (what the brand must grow into)

The prospectus's moat is **the Record** — the 40-year archive. That sets the
brand's aging requirement, which becomes our second standing filter:

> **The archive test: would this artifact still look right printed in the
> crew's season book in 2046?**

Consequences:
- Prefer **engraved/stamped/printed** metaphors (trophy plates, ball markers,
  scorecard print) over glassy/gradient app-fashion. Fashion dates; engraving
  doesn't.
- Season recaps, settlement cards, and Wrapped artifacts are **documents, not
  posts** — designed like things worth keeping, because keeping them is the
  product.
- The four objects (Crew/Cup/Rivalry/Record) are the icon language's roots.
  New iconography should ladder to one of the four.
- The prospectus's paper/pine/champagne duality is already live (§4); its six
  signature micro-interactions live in the prospectus doc (repo-root artifact,
  not in this worktree) — the roll-out is canon now, the rest adopt as the
  design lane reaches them.

## 6. The mark (OPEN — this section is the exploration brief)

**Current state:** `brand/mark.svg` — a flag standing in the green's cup,
orbited by a four-arc ring in squad colors, drawn in perspective. Full asset
family exists (light variant, lockups, PWA icons, maskable, og-image; see
`brand/README.md`). It shipped ~v23.70 and **predates the palette evolution**:
its lead arc is neon mint `#43E07C` (now semantic-only) and its quartet doesn't
match the current squad teal. The wordmark is IBM Plex Mono caps — set before
the serif voice existed. The mark is *functional, not final*; Jerecho is
explicitly not set on it.

**Gates any candidate must clear (in order):**
1. **The hat test** — would someone wear it on a hat having never heard of the
   app? (The standing Final Rule for all brand work.)
2. **The archive test** (§5) — right in 2046?
3. **Embroidery** — survives 2–3 thread colors, no gradients, no hairlines, at
   ~2 inches.
4. **One-color version exists** — for engraving (trophies!), stamping (ball
   markers), and favicon/16px.
5. Reads in a circle crop (avatar) and the maskable 80% safe zone; works on
   dusk *and* paper.

**Territories worth exploring** (described, not drawn — sketches in the board
below; execution belongs to the design lane):

1. **The Marker** ⭐ — the mark *is* a ball marker: a stamped coin. Circular
   badge, one-color relief (flag-in-cup or CS monogram), champagne on dusk.
   Why it's the favorite on paper: golfers already carry one; **the ball marker
   is already the in-app identity token** (the golfer card's marker field) — so
   brand mark, profile identity, and a $3 piece of merch every golfer would
   actually use are *the same object*. Clears embroidery/engraving trivially.
2. **The Cup, Held** — the pun the name deserves: the trophy cup and the cup on
   the green are the same word. A chalice silhouette whose bowl reads as the
   green's cup, flagstick rising from it. What you play for and where the ball
   ends up, one shape.
3. **The Roll-out** — motion-native: a putt's dotted path curving in and dying
   into the cup (line + circled dot). Static favicon, animates as the splash
   with `--roll`. The brand's easing made visible.
4. **Orbit, evolved** — keep the current flag-in-cup + ring, recolor the arcs
   to the true squad quartet, deepen mint to fairway. Cheapest path; evolution
   not revolution; preserves the installed-icon equity PIGL already knows.
5. **The Record monogram** — a serif CS ligature, engraver's cut, as the
   *secondary* mark for trophies, season books, and the wordmark's ceremony
   moments. Probably not the primary (monograms read country-club on a hat)
   but the family wants it.

**Cliché bans:** swinging-silhouette man, crossed clubs, heraldic crest with
"EST. MMXXVI," argyle, cartoon gopher, generic tech swoosh. A flag/cup is
allowed — it's the name — but it must be *ours* (the perspective cup, the
marker coin), not clip-art.

**Recommendation:** run territories 1–3 hard against 4 as the control; kill
anything the hat test doesn't love (the "too safe → kill 70%" instinct applies
here, and only here). Decision needs no decision-log entry (UI level) but the
chosen mark re-generates the full `brand/` family — that's a design-lane task
with a checklist already written in `brand/README.md`.

## 7. Guardrails — what Cup Season must never look like

Each of these was paid for or reasoned once; the list is the receipt.

- **The Arccos problem** (paid for, v23.106): neon signal-green as brand on
  black, sensor-tech gradients, data-hero screens. We are not a measurement
  device. Mint is a signal, never the brand.
- **The sportsbook**: odds-board urgency, money as hero, flashing red/green.
  Money renders in champagne (earned, celebratory) or ink — never urgent.
  "Tracked, never held" in every money surface. This guardrail is a legal/
  store-review posture as much as taste (GTM §13.5).
- **The gated club**: crests, velvet-rope luxury, exclusion as aesthetic. We
  are muni-proud; heritage warmth without the gatekeeping. The board is earned,
  the door is open.
- **The SaaS dashboard**: KPI grids, stat-forward heroes. Memory > Statistics —
  stats exist to support stories, and layouts should physically demote them
  (story line above the table, always).
- **The content brand**: pro-tour b-roll, swing-tip thumbnails, hype captions.
  The one-more-round rule killed pro-golf content as a feature; it's equally
  dead as an aesthetic.
- **Photography** (when we shoot): real crews on real munis, phones out on the
  green, morning and dusk light, faces mid-laugh mid-argument. Never stock
  swing-form, never drone-porn of courses no one in the crew plays, never
  golf-as-luxury-lifestyle.
- **Type sins**: script "clubby" fonts, aggressive sports slabs, a fourth
  family, serif on buttons, mono paragraphs.
- **Tone sins**: shame mechanics, countdown pressure, "last chance." The app
  is the friend who keeps the book, not the app that needs you back.

## 8. The two standing filters (apply to every brand decision)

1. **The hat test:** would someone proudly wear it having never heard of the
   app? If not, refine.
2. **The archive test:** would it still look right in the crew's season book
   in 2046? If not, it's fashion — cut it.

---

*Changes to this canon: palette/type/motion changes ride the design lane with
a note here; anything that touches a competition surface's meaning (e.g., what
gold signifies) is a mechanics-adjacent change and gets a decision-log entry
first.*
