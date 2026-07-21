# Cup Season — Brand Bible v1

Version 1.0 · Growth/Launch lane · 2026-07-17

**What this is:** the operating manual for how the brand shows up in the world —
positioning, messaging, the asset system, the storefront, content, email, press.
It **builds on** `spec/brand-canon.md` and never repeats it: the canon says who
we are (promise, palette, voice laws, guardrails, the mark brief); this bible
says what we *do* with that. Strategy lives in `spec/gtm-year1.md`; where the
bible touches strategy it points, not duplicates.

**The three-doc stack** (read in this order):
1. `brand-canon.md` — who we are (identity core, the two filters)
2. `brand-bible.md` — how we show up (this doc)
3. `gtm-year1.md` — where we go (funnel, roadmap, budget)

**Adapted honestly from the 9-phase brief:**
- Phase 1 (foundation) — DONE, it's the canon. This doc adds the two pieces the
  canon deliberately left out: the positioning statement and the messaging
  hierarchy (§1–2).
- Phase 4 ("App Store kit") — the product is a **PWA**; there is no store
  listing today. The storefront is **cupseason.app + the og card + the install
  moment**. Store-listing copy is drafted anyway (§5) so a future wrapper ships
  with zero new writing — and it doubles as landing copy now.
- Phase 6 (90-day teaser calendar) — the template assumes a pre-launch teaser
  arc. Reality: the product is live, PIGL is playing, and the launch gate is
  the timed QA + Pro recruiting. §7 is the *real* 90 days.

---

## 1. Positioning statement

> **For the golfer who runs the group** — the one with the spreadsheet, the
> Venmo thread, and the group chat — **Cup Season is the operating system that
> runs the season for them**: real rounds from any course, handicapped fairly,
> scored into standings everyone understands at a glance, with the pot kept
> as a ledger everyone can see. **Unlike golf apps that measure swings or collect stats,**
> Cup Season makes the rounds a crew already plays count for something — a
> season, a rivalry, a record that lasts.

The three moves inside it, each load-bearing:
- **Who:** the Pro, not the golfer-in-general. One buyer, whole-group adoption
  (GTM §0 — we acquire leagues, not golfers).
- **Category:** *operating system for amateur golf competition* — deliberately
  not "golf app." We never compete on measurement (canon guardrail: not Arccos,
  not GHIN, not a stat collector).
- **Enemy:** the spreadsheet, never other apps. "Retire the spreadsheet"
  positions against the pain, flatters the Pro's current effort, and picks a
  fight no incumbent will defend.

## 2. Messaging hierarchy

**Level 0 — the promise (everywhere, verbatim):**
*Where amateur golf counts.*

**Level 1 — the one-liner, per audience:**
| Audience | First sentence they should hear | Why this one |
|---|---|---|
| The Pro (35–65, runs the season) | **"Retire the spreadsheet. Run your season in your pocket."** | Names the pain; promises less work, not more features. |
| The competitive golfer (25–55) | **"Every round counts."** | The vision doc's own promise; rounds stop disappearing. |
| The guest (claim-link viewer) | **"That round you just played? It's yours. Claim it."** | The wedge: they already played; the app just makes it real. |
| The trip guy | **"The trip deserves a trophy."** | Episodic play → the Ryder/tee-sheet door. |
| Press / partners | **"The operating system for amateur golf competition."** | Category claim; invites the how-it-works question. |

**Level 2 — the three pillars** (every marketing surface leads with one):
1. **A real season.** Draft, months, a cup, a pot — structure that makes
   Saturday mean something. *(Proof: the wizard, storytelling standings, the
   endgame dial, "leads by 25 · 25 back.")*
2. **Fair by math, shown in full.** Auto-handicap from the scores themselves;
   every points figure taps through to the rounds that produced it. *(Proof:
   the handicap engine, receipts, named bands — "beat your number by 0.6."
   This pillar kills the #1 league-killer: handicap arguments.)*
3. **The record.** Rivalries, trophies, recaps — a golf life that adds up.
   *(Proof: trophy case, moments, season recap, the coming Wrapped.)*

**Level 3 — proof artifacts, not claims.** When a surface has room for only one
thing, show a real artifact (settlement card, recap card, standings line) over
any sentence. The product doing an un-spreadsheet-able thing *is* the message
(GTM §3 design rule).

**Money language — fixed, non-negotiable (amended 2026-07-20 per D39):**
*"Cup Season keeps the ledger; the money moves between friends."* Door
headline: *"Every dollar on the books."* "Tracked, never held" and "takes no
cut" are RETIRED — present-tense ledger facts only, no forever-promises.
Appears wherever money is visible: landing, FAQ, store listing, press
boilerplate. (Canon §3 as amended; GTM failure mode #5.)

## 3. Audiences (who we talk to, in priority order)

1. **The Pro** — the only *buyer*. Hears pillars 1+2. Channels: r/golf, local
   FB golf groups, course boards, word of mouth (GTM §2).
2. **The crew member** — arrives via the Pro's invite; needs zero convincing,
   only zero friction. Hears "you're in — post your first round."
3. **The guest** — arrives via a claim link on a settlement card. Our cheapest
   acquisition (GTM §3). Hears the claim line, nothing else.
4. **The next Pro watching** — a member of someone else's league who could run
   their own. Every recap/wrapped artifact quietly speaks to them ("start a
   rival league" — GTM §8).
5. **Press/partners** — hears the category claim + the founder story (§10).

## 4. The asset system

### Core identity — status
| Asset | State | Source of truth |
|---|---|---|
| Palette, type, motion, radii | **SHIPPED** (v23.131 tokens) | canon §4 |
| The mark + family | **OPEN** — five territories under exploration | canon §6 brief; execution = design lane; regen checklist in `brand/README.md` |
| Illustration style | Direction set, nothing drawn: engraved/stamped/printed metaphors, never glassy app-fashion (the archive test) | canon §5 |
| Iconography | Roots in the four objects (Crew/Cup/Rivalry/Record); mono-weight line icons, one-color survivable | canon §5 |
| Photography | Rules set (real crews, munis, morning/dusk light), **no library yet** — shoot PIGL first | canon §7 |

### Social templates — the rule before the list
**The product already makes our best templates.** The settlement card, the
round recap card (v23.175), the storytelling standings line, and the coming
season recap/Wrapped are shipped, share-native artifacts. Marketing templates
therefore *inherit product artifacts* — same dusk ground, serif story line,
mono record line, earned-gold accents — so that a marketing card and a product
card are indistinguishable. A template that couldn't plausibly be a screenshot
of the app is off-brand by definition.

Every template passes the GTM §3 shareable rule: (a) flatters the sharer,
(b) carries a claim/join path, (c) shows something a spreadsheet can't.

| Template | Job | Must contain |
|---|---|---|
| **Settlement card** (product) | The guest wedge | winner · the money line · claim link |
| **Round recap card** (product, v23.175) | Golfer pride share | the round's story line · named band · league mark |
| **League spotlight** | Convert the next Pro | crew name · season shape · one standings story line · join covenant line |
| **Weekly recap graphic** | Rhythm + FOMO | "this week in {league}" · 3 story lines · leader in gold |
| **Winner / trophy card** | Ceremony | trophy render · engraved-style name (archive test) · season record |
| **Announcement card** | Product news in community voice | serif headline · one artifact screenshot · zero changelog-speak |
| **Quote card** | Social proof | Pro's words verbatim · their league name · founding badge if earned |
| **Founding League invite** | Seed the panel | "Founding League №N of 10" · what it means · the soft obligation |

Template *specs* live here; template *files* are a design-lane deliverable
after the mark decision (no point building 8 templates around a mark that may
change).

## 5. The storefront

### cupseason.app landing (the real Phase 3 — currently the app boots straight to sign-in; a marketing front door for the not-yet-convinced Pro does not exist)
Brief for the UX/design lane — one page, dusk system, in this order:
1. **Hero:** "Retire the spreadsheet." + subline "Run your golf season in your
   pocket — draft the crew, post real rounds, watch the cup race itself."
   CTA: **Start your league** (→ wizard) · secondary: **I have a code**.
2. **The proof row:** three real artifacts, not screenshots-with-captions —
   a settlement card, the standings story line, a recap card. (Replaces
   "product video" until one exists; a 30s screen capture of the wizard →
   first round → standings is the v1 video when someone records it.)
3. **How it works, in the Pro's grammar:** Draft → Post from anywhere → The
   month closes → The Cup. Four steps, one line each.
4. **The money sentence:** the D39 ledger line — verbatim, its own block.
5. **Founding wall:** "Founding League №1: PIGL, Tempe AZ" + open slots
   counter (scarcity per focus-group plan; grows into the §10 press asset).
6. **Pricing:** honest and parked-aware: "Your first season is free. Seasons
   after that cost less than one skin." No numbers until the focus groups
   decide (never contradict a parked decision in public copy).
7. **FAQ:** handicap fairness (the engine, shown work) · money (the sentence)
   · "my crew is 6 people" (league shapes) · data ownership (your rounds are
   yours — the Record).
8. **Footer CTA:** the claim-line for guests + "talk to the founder" mailto —
   white-glove is the Q1 model (GTM §12); a founder email beats a waitlist.

No waitlist section: the product is live; a waitlist would be theater.

### Store-listing kit (SUPERSEDED 2026-07-20 — the current, D39-correct
listing lives in `spec/appstore-launch-kit.md` §1; this sketch stays as
og/meta copy reference only. Note its name exceeds Apple's 30-char limit.)
- **Name:** Cup Season — Golf League Seasons
- **Subtitle (30ch):** "Run your golf season"
- **Short description:** "Real rounds. Real handicaps. A season your crew
  actually finishes — standings everyone understands, and a pot that's a
  ledger between friends."
- **Keywords:** golf league, golf season, handicap, skins, match play, wolf,
  golf trip, ryder cup, golf with friends, league standings
- **Screenshot captions (5):** ① "Draft the crew" ② "Post in under a minute"
  ③ "Standings that explain themselves" ④ "Game day: Match, Wolf, Skins"
  ⑤ "The season ends in a Cup"
- **Preview-video script (30s):** wizard (0–6s: "your league in minutes") →
  hole-by-hole grid (6–12s: "post from any course") → standings line lands
  (12–20s: "leads by 25 · 25 back") → settlement card + trophy (20–30s: "the
  season ends in a Cup"). No voiceover; serif captions; `--roll` motion.
- **Release-notes voice:** community voice, never changelog-speak — "The Wolf
  now howls: rotation, comeback, and a net-zero ledger" not "Added Wolf mode."

## 6. Content pillars (reconciled with GTM §5 — one system, not two)

The 9-phase brief's six pillars map onto GTM's five themes; adopt GTM's ratio
(~60% community/artifacts · 25% educational · 15% founder/product) and treat
the pillars as the *recurring formats* inside those themes:

| Pillar (recurring format) | GTM theme it serves | Cadence |
|---|---|---|
| League spotlights, weekly champions, rivalry moments | Community stories + artifacts | weekly (from real leagues, PIGL first) |
| "How to run a league" / Pro tips / format explainers | Educational | weekly-ish, SEO-first |
| PIGL diary / build-in-public / why-I'm-building-this | Founder | 1–2× month |
| Feature reveals, design decisions (in community voice) | Product updates | on ship |
| Seasonal campaigns (Masters, majors, Ryder week, New Year Wrapped) | Seasonal | per golf calendar (GTM month grid) |
| Beautiful-courses/quotes/traditions "culture" filler | **CUT** — decoration; fails the Final Rule (no claim path, nothing un-spreadsheet-able). The crew's own photos serve this need with proof attached. |

## 7. The real 90 days (2026-07-17 → mid-Oct; compresses GTM Q1)

**Weeks 1–2 — the gate.** Run the timed five-gate QA (`prelaunch-qa-2026-07-13.md`
— F1 is cleared, it's unblocked); fix stack from findings. Begin Founding
League recruiting — **the focus group, the QA testers, the Founding panel, and
the first white-gloves are the same 8–10 arms-length Pros** (one motion; see
focus-group plan). Press kit live (§10). PIGL diary post №1.
**Weeks 3–4.** White-glove Founding Leagues №2–4. Ask the eng lane for the
artifact→claim→signup instrumentation (GTM experiment №1 — prereq for
everything). First settlement-card shares out of PIGL.
**Month 2.** Founding wall public on the landing page; r/golf presence begins
(participate, don't advertise); warm outreach to 2–3 niche newsletters/
podcasts (GTM §7 ranks); run focus-group Blocks A–E with the recruited Pros.
**Month 3.** Pricing decision lands (+ decision-log entry); Founding cap
(~8–10) announced and **closed loudly** (scarcity artifact); first month-close
stories from non-PIGL leagues; "How We Run PIGL" playbook published; Wrapped
planning handed to product lanes for the New-Year drop.

**Not in the 90 days:** paid anything, big partnerships, follower goals —
per GTM §10/§15 these are Q3+ or never.

## 8. Community (pointer — GTM §6 owns this)

One addition the GTM doc doesn't say explicitly: **the commissioner advisory
board already exists in embryo — it's focus-group Seat 3 = the Founding League
panel.** Don't build a Discord for an audience of eight; the advisory board is
a group thread + monthly call with the Founding Pros until it outgrows that.
Formalize (Discord/Circle, ambassador program) only at the GTM Q2 trigger.

## 9. Email system (sequences specced; sending infra is an open decision)

Infra note: Brevo SMTP exists for **auth OTP only**. Marketing/lifecycle email
needs a list + campaign tool (Brevo's own campaigns is the low-friction
candidate — same vendor, no new secret surface). Decision belongs to the user;
nothing sends until then. Product-triggered pushes already cover most in-app
lifecycle (GTM §9 table) — **email is for Pros and ceremonies, not for
day-to-day nudges.**

| Sequence | Trigger | Audience | Beats (each its own send) | Voice |
|---|---|---|---|---|
| **Pro onboarding** | League created | The Pro | mirror of the white-glove: invite the crew → lock the roster → seed with one live game → your first month-close, explained | The friend who's run this before |
| **Welcome golfer** | First sign-in via invite | Member | one email only: you're in {league}, here's the crew, post your first round | Warm, brief |
| **Month-close digest** | `close_month()` | Pro (opt: all) | the board post + who's slipping + one story line | The record, speaking |
| **Season recap** | Season ends | Everyone in league | the recap artifact + trophies + "run it back" CTA | Ceremony |
| **Annual Wrapped** | New Year | All actives | the Wrapped artifact + share prompt | Pride, not promotion |
| **Product notes** | Monthly-ish | Pros who opted in | what shipped, in community voice; one ask (feedback loop) | Build-in-public |
| ~~Waitlist / beta invite~~ | — | — | CUT: product is live; invites are league invites | — |

Governing rule inherited from GTM §9: relevant to *this golfer's league this
week* or it doesn't send.

## 10. Press kit (assemble once, answer every podcast/newsletter in one link)

Lives at a `/press` page (or a public folder) once the landing ships; contents
are ready now:

- **Boilerplate (use verbatim):** *Cup Season is the operating system for
  amateur golf competition. Friend groups draft squads, post real handicapped
  rounds from any course, and race a season-long cup — with standings anyone
  can read and receipts behind every number. Cup Season keeps the ledger; the
  money moves between friends. Built in Tempe, Arizona by a
  golfer who got tired of running his league on a spreadsheet. Founding league:
  PIGL. Live at cupseason.app.*
- **Founder bio (outline):** Jerecho — founder; runs PIGL (the beta league),
  ~12 index; built Cup Season to replace his own spreadsheet; Tempe, AZ.
  (2–3 sentences max; the PIGL story *is* the bio.)
- **The story, in one paragraph:** spreadsheet pain → built for one league →
  the league got better (fairness ended the handicap arguments; the season got
  a story) → opened it to other crews. Angle for press: *founder-scratches-
  own-itch + "golf apps track swings; nobody was keeping score of the thing
  friends actually argue about."*
- **Fact sheet:** founded 2026 · Tempe, AZ · PWA at cupseason.app · the pot
  is a ledger — money moves between friends, not through the app (lead with
  it — preempts the gambling question) · leagues play free today · Founding
  Leagues program (№1 PIGL). *(2026-07-20: D39 wording; the assembled,
  current press kit lives in `spec/appstore-launch-kit.md` §4.)*
- **Assets:** lockups + marks from `brand/` (regenerate after the mark
  decision), og-image, 3–5 product-artifact screenshots (settlement card,
  standings, recap), one founder photo (does not exist yet — take one).
- **FAQ for journalists:** is it betting? (no — the sentence, then the §14.3
  fairness machinery) · how is handicapping fair? (the engine, shows its work)
  · what's it cost? (first season free; pricing in focus groups — honest).
- **Contact:** the founder, directly — jerechofischbeck@gmail.com.

## 11. Next steps (sequenced; owner in brackets)

1. **Pick the mark territory** (canon §6 board; the ⭐ Marker is the
   recommendation) → design lane executes → regenerate `brand/` family per its
   README. Blocks: templates (§4), press assets (§10), landing hero polish.
   **[user decides · design lane builds]**
2. **Run the timed QA + start Founding-Pro recruiting** — same 8–10 people,
   one motion (§7 weeks 1–2). Nothing in this bible matters more. **[user]**
3. **Landing page** per §5 brief. Unblocks press kit link, founding wall,
   guest FAQ. **[UX/design lane; copy is in this doc]**
4. **Artifact-loop instrumentation** (GTM experiment №1). **[eng lane]**
5. **Press kit assembly** — boilerplate/bio/facts above are final-draft; needs
   the founder photo + post-mark assets. **[user + design lane]**
6. **Email infra decision** (Brevo campaigns vs other) then the Pro-onboarding
   sequence first — it mirrors white-glove and scales it. **[user decides]**
7. **Focus groups → pricing → landing pricing section gets real numbers +
   decision-log entry.** **[user; plan is written]**
8. **Wrapped brief to product lanes** in time for the New-Year drop (GTM M12's
   biggest organic moment). **[Social/Gameplay lanes]**

---

*Maintenance: this bible changes when positioning, messaging, or a §11 step
lands — note the change inline with a date. Identity-level changes belong in
the canon, not here. Strategy-level changes belong in gtm-year1.md.*
