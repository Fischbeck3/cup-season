# CupSeason — The Memory Layer (v1)

*Head of Engagement & Memory Systems · strategy map · 2026-07-16*

> CupSeason is not a social network for golfers. It is the **memory layer of
> amateur golf** — the system that turns a round into a memory, a story, a
> rivalry, a tradition, and a reason to play again. We do not optimize for
> screen time. We optimize for the **lifetime value of every golf experience.**

## The one test every idea passes

An idea earns a place here only if it answers **yes** to at least one, ideally
several:

1. Does this make a **future round more likely**?
2. Does this create a **memory**?
3. Would someone **talk about this in the clubhouse**?
4. Would this **matter five years from now**?

And every idea names **one** primary emotion — Pride · Nostalgia · Anticipation
· Belonging · Rivalry · Joy · Reflection · Achievement. If we can't name the
emotion, the idea isn't strong enough and it's cut.

## What already exists (the spine we build on)

The memory *engine* is live. This map is the temporal arc **around** it — do not
re-propose the engine, extend it.

| Live system | What it does | Migration |
|---|---|---|
| **Moment engine** | One headline per round (barrier > PB > iron-man streak), posted to the board | `round_moments` |
| **Lead-change moments** | Standings drama auto-narrated | `lead_change_moments` |
| **Achievements** | Same event as a moment, but *pinned to your card* — first round, PB, streaks | `achievements` |
| **Trophies** | Career hardware — Ryder wins, champion, points king | `trophies` |
| **Rivalries** | Faceted object — weekly clash, all-time head-to-head, named duels | `rivalries` |
| **League pulse** | Month activity readout | `league_pulse` |
| **Settlement ledger** | Net-zero who-owes-whom, per side game | `wolf_skins_claim` etc. |
| **Tee time** | A scheduled round has a stored time | `tee_time` |
| **Identity** | Golfer card — marker, home course, index journey, GHIN | `tour_card_and_ghin` |

**The design principle this reveals:** an event should have a *lifespan
gradient* — it scrolls the board today, pins to a card this season, and enters
the archive forever. Every idea below inherits that gradient.

---

## The 50 opportunities

Organized by the emotional arc of a round. Each row carries all six required
attributes: **Emotion** (the one primary) · **Impact** (★1–5, emotional weight)
· **Effort** (◆1–5, build complexity; more = harder) · **∞** (becomes permanent
product DNA) · **Ver** (V1 / Y2 / Y5).

### I. BEFORE — anticipation, the round that hasn't happened yet

*The most under-built phase. A round you're looking forward to is a round you'll
show up for. This is where retention is actually won.*

| # | Opportunity | What it is · why golfers care | Emotion | Impact | Effort | ∞ | Ver |
|---|---|---|---|---|---|---|---|
| 1 | **The Tee-Time Countdown** | A scheduled round becomes a live card: "3 days to The Grudge · Papago · 4 confirmed." Turns a date into an event you feel approaching. Builds on the existing `tee_time`. | Anticipation | ★★★★★ | ◆◆ | ✓ | V1 |
| 2 | **Pre-round trash-talk thread** | A banter channel that *opens* when a tee time is set and *archives into that round's story* after. Talk is the point; the archive makes it a memory. | Rivalry | ★★★★☆ | ◆◆ | ✓ | V1 |
| 3 | **The Callout (number-to-beat)** | Publicly declare a target or call out an opponent before teeing off; it auto-settles after. Extends the Ryder's number-to-beat chip to any round. | Rivalry | ★★★★☆ | ◆◆ | ✓ | V1 |
| 4 | **Predictions market** | Before a Cup/Ryder session everyone predicts the winner; right calls score bragging points, logged forever. Skin in the game before a ball is struck. | Anticipation | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 5 | **The Invitation as a moment** | Inviting someone is a *designed card* they receive ("Ed wants you in Saturday's foursome"), not a raw link. First touch sets the tone of belonging. | Belonging | ★★★☆☆ | ◆◆ | – | V1 |
| 6 | **Weather-linked anticipation** | "72° and calm at Papago Saturday — scoring weather." Real conditions folded into the countdown; makes the day tangible. | Anticipation | ★★★☆☆ | ◆◆◆ | – | Y2 |
| 7 | **Head-to-head pre-game card** | When two rivals land on the same tee sheet, surface their all-time record *before* the round. The rivalry engine already holds it. | Rivalry | ★★★★☆ | ◆◆ | ✓ | V1 |
| 8 | **First-time-at-course scouting** | A round at a course you've never played gets a "first time at ___" badge + a mini scouting card. Novelty is a reason to go. | Anticipation | ★★★☆☆ | ◆◆ | – | Y2 |
| 9 | **The roster-reveal ceremony** | Team selection as suspense — the blind draw already animates; extend the reveal beat to every team pick and post it. | Anticipation | ★★★★☆ | ◆◆ | ✓ | V1 |
| 10 | **Season kickoff ritual** | Opening-day post: last year's champion, the field, the stakes, the pot. The season starts with a story, not a settings screen. | Tradition | ★★★★☆ | ◆◆ | ✓ | V1 |

### II. DURING — capture without distraction

*The phone must never compete with the round. Everything here is one-tap or
zero-tap. We are a passenger in the cart, not the driver.*

| # | Opportunity | What it is · why golfers care | Emotion | Impact | Effort | ∞ | Ver |
|---|---|---|---|---|---|---|---|
| 11 | **Live milestone pings (quiet)** | A birdie run / sub-par stretch surfaces to the group feed live, sourced from the hole-by-hole stepper — no phone-poking required. The group feels the round as it happens. | Joy | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 12 | **Signature-moment capture** | One-tap "mark this" on a hole (ace, eagle, bet won) that becomes a story card. The single most important *during* interaction. | Joy | ★★★★★ | ◆◆ | ✓ | V1 |
| 13 | **Live group leaderboard** | During a match-play / wolf / skins round, the live state is one glanceable card. Settlement exists; the *live* tension is the gap. | Rivalry | ★★★★☆ | ◆◆◆◆ | ✓ | Y2 |
| 14 | **Photo-moment prompts** | At natural highs (a made card, a milestone) prompt a photo. *(Deferred by owner — parked, not cut.)* | Nostalgia | ★★★★★ | ◆◆◆◆ | ✓ | Y2 |
| 15 | **The "on-pace" whisper** | Quietly tells you you're on pace for a PB or to beat your number, mid-round. A private thrill that pulls you to finish. | Anticipation | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 16 | **Rivalry-moment live** | When you pass or get passed by your rival in a head-to-head, a single quiet ping. The rivalry breathes in real time. | Rivalry | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 17 | **Course-record watch** | On pace for your personal best *at this course*, a subtle nudge on the last few holes. | Pride | ★★★☆☆ | ◆◆◆ | – | Y2 |

### III. IMMEDIATELY AFTER — the emotional peak

*The highest-value moment in the whole product. The round just ended, the
feeling is at its maximum, and CupSeason is the scorekeeper, the storyteller,
the highlight reel, and the clubhouse all at once.*

| # | Opportunity | What it is · why golfers care | Emotion | Impact | Effort | ∞ | Ver |
|---|---|---|---|---|---|---|---|
| 18 | **The Round Recap Card** | Every round auto-generates a shareable story/settlement card — the artifact of the peak. Extends existing settlement cards to *all* rounds. This is also the #1 growth loop. | Pride | ★★★★★ | ◆◆◆ | ✓ | V1 |
| 19 | **Deepen the storyteller voice** | The moment engine writes one headline per round; invest in its voice — dry, knowing, clubhouse-toned, never corporate. Cheap, enormous felt-quality return. | Joy | ★★★★☆ | ◆ | ✓ | V1 |
| 20 | **The day's highlight reel** | End-of-day auto-digest for a group: "Saturday at Papago — 4 rounds, 1 PB, Ed took the skins." The clubhouse recap that used to happen at the bar. | Belonging | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 21 | **Settlement as a story** | Who owes whom, framed as ribbing not accounting ("Jake owes Ed a beer and his dignity"). The ledger exists; the *voice* is the opportunity. | Rivalry | ★★★★☆ | ◆◆ | ✓ | V1 |
| 22 | **First-to-know beat** | The poster gets a private "here's what just happened for you" moment (new PB, rivalry flip, streak extended) *before* it hits the board. Your win is yours first. | Pride | ★★★★☆ | ◆◆ | ✓ | V1 |
| 23 | **Comeback / collapse tag** | A round that flips a standing gets special framing. Drama is memory. | Rivalry | ★★★★☆ | ◆◆ | ✓ | V1 |
| 24 | **Playing-partner shoutout** | After a shared round, a prompt to credit your partner — seeds the friendship system with real signal. | Belonging | ★★★☆☆ | ◆◆ | ✓ | V1 |
| 25 | **Instant rivalry update** | "You're now 4–3 up on Jake, all-time." The scoreboard of a friendship, updated the moment it changes. | Rivalry | ★★★★★ | ◆◆ | ✓ | V1 |

### IV. DAYS LATER — resurfacing

*The re-engagement loop, done with dignity. Never "you have 3 notifications."
Always a memory or a relationship. Every nudge here is a reason to play, not a
reason to tap.*

| # | Opportunity | What it is · why golfers care | Emotion | Impact | Effort | ∞ | Ver |
|---|---|---|---|---|---|---|---|
| 26 | **"You and Jake haven't played in 47 days"** | Re-engagement *through a relationship*, not a metric. The single best nudge we can send. | Nostalgia | ★★★★★ | ◆◆ | ✓ | V1 |
| 27 | **On-this-day / "3 years ago today"** | Golf memories resurface on their anniversary. The Apple-Photos-Memories principle, for rounds. | Nostalgia | ★★★★★ | ◆◆◆ | ✓ | Y2 |
| 28 | **The standing challenge callback** | "You've never beaten Sarah from the blues." A specific, beatable near-miss surfaced as a dare. | Rivalry | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 29 | **Streak-at-risk nudge** | "Your iron-man streak (7 weeks) needs a round by Sunday." Loss-aversion in service of a genuine tradition — built on the live streak system. | Anticipation | ★★★★☆ | ◆◆ | ✓ | V1 |
| 30 | **Course-memory resurface** | "Last time at Aguila you shot your best. Back this weekend?" Ties a place to a feeling to a future round. | Nostalgia | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 31 | **Rivalry heat check** | A dormant rivalry gets a "time for a rematch" nudge when it's gone cold. | Rivalry | ★★★☆☆ | ◆◆ | – | Y2 |
| 32 | **Weekly personal digest** | A quiet Sunday-night "your week in golf." Reflection, not a leaderboard. Opt-in, one per week, never more. | Reflection | ★★★☆☆ | ◆◆◆ | – | Y2 |
| 33 | **"Closest you've come"** | Surfaces your best-ever near-misses (within 1 of a PB; one hole from beating your rival). The pull of unfinished business. | Anticipation | ★★★☆☆ | ◆◆◆ | – | Y2 |

### V. YEARS LATER — the personal golf archive

*The moat. Nobody leaves the app that holds their entire golf life. This is what
makes CupSeason a decade-long relationship instead of a season-long one.*

| # | Opportunity | What it is · why golfers care | Emotion | Impact | Effort | ∞ | Ver |
|---|---|---|---|---|---|---|---|
| 34 | **The Personal Golf Archive** | Every round you've ever posted, browsable as a life. The foundation the whole "years later" tier stands on. | Reflection | ★★★★★ | ◆◆◆ | ✓ | Y2 |
| 35 | **Season Recap / Wrapped** | The annual Spotify-Wrapped story of your golf year — rounds, PBs, rivalries settled, your arc. The most shareable artifact we can make. | Reflection | ★★★★★ | ◆◆◆◆ | ✓ | Y2 |
| 36 | **Playing-partner chemistry** | A "chemistry" history with each regular partner — rounds together, records, who you play your best golf beside. The FIFA-Ultimate-Team principle applied to friendship. | Belonging | ★★★★★ | ◆◆◆◆ | ✓ | Y2 |
| 37 | **Course history book** | Your personal record at every course — best, average, times played, your story there. | Pride | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 38 | **The all-time rivalry ledger** | The deep head-to-head archive with each opponent — every clash, the running record, the named duels. Extends the rivalry object into a career. | Rivalry | ★★★★★ | ◆◆◆ | ✓ | Y2 |
| 39 | **League hall of records** | The league's book — every champion, biggest blowout, lowest round ever, longest streak. Auto-maintained superlatives. | Tradition | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 40 | **The Trophy Case as a career** | Deepen the pinned achievements into a lifetime cabinet with eras and rarity. Trophies exist; the *cabinet* is the vision. | Pride | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 41 | **Traditions system** | Recurring *named* events (the annual "Turkey Cup") that accrue history year over year — a permanent home for the thing a friend group already does every year. | Tradition | ★★★★★ | ◆◆◆◆ | ✓ | Y2 |
| 42 | **League lore / founding era** | Origin story, "member since," era markers, the founding roster. The Founding-League badge, deepened into identity. | Belonging | ★★★☆☆ | ◆◆◆ | ✓ | Y5 |
| 43 | **Family / legacy lineage** | Pass a record, a rivalry, or a home course down — multi-generational golf history. The furthest-horizon moat. | Nostalgia | ★★★★☆ | ◆◆◆◆◆ | ✓ | Y5 |
| 44 | **Lifetime milestone ladder** | Career counters — rounds played, courses seen, birdies, aces — with a celebration at each milestone (100th round, 50th course). | Achievement | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 45 | **Your evolution arc** | Your index/handicap journey visualized across years — the story of getting better (or the honest story of not). | Reflection | ★★★★☆ | ◆◆◆ | ✓ | Y5 |

### VI. CROSS-CUTTING SYSTEMS — identity & tradition

*Not tied to one phase; they thread through all of them.*

| # | Opportunity | What it is · why golfers care | Emotion | Impact | Effort | ∞ | Ver |
|---|---|---|---|---|---|---|---|
| 46 | **Living identity card** | The golfer card as a growing identity — marker, home course, era, signature stat. Exists; make it *evolve* visibly over time. | Belonging | ★★★★☆ | ◆◆ | ✓ | V1 |
| 47 | **Earned nicknames** | Performance earns personas — "The Closer," "Sandbagger," "Mr. Papago." The clubhouse names you; the app makes it stick. | Belonging | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 48 | **Named rivalries** | A rivalry can be christened ("The Grudge") and carries its name forever across every clash. Small build, huge identity payoff. | Rivalry | ★★★★☆ | ◆◆ | ✓ | V1 |
| 49 | **League record book (live)** | League-level superlatives auto-maintained and always current — a living record book the group checks and argues over. | Tradition | ★★★★☆ | ◆◆◆ | ✓ | Y2 |
| 50 | **Anniversary & tradition triggers** | The system remembers the league's birthday, the annual cup date, member anniversaries — and ritualizes them unprompted. | Tradition | ★★★★☆ | ◆◆◆ | ✓ | Y5 |

---

## Ranking 1 — by emotional impact (the top 15)

The ideas that move the most feeling, regardless of cost. These define what
CupSeason *is*.

1. **#12 Signature-moment capture** — Joy — the one-tap that turns a shot into a story
2. **#18 Round Recap Card** — Pride — the peak, captured and shareable
3. **#26 "Haven't played with Jake in 47 days"** — Nostalgia — retention through relationship
4. **#25 Instant rivalry update** — Rivalry — the scoreboard of a friendship
5. **#35 Season Wrapped** — Reflection — the year, told back to you
6. **#36 Playing-partner chemistry** — Belonging — who you play your best golf beside
7. **#1 Tee-time countdown** — Anticipation — turns a date into an event
8. **#34 Personal golf archive** — Reflection — the moat, the whole life
9. **#41 Traditions system** — Tradition — a permanent home for the annual thing
10. **#38 All-time rivalry ledger** — Rivalry — the career of a friendship
11. **#27 On-this-day** — Nostalgia — the memory resurfaced on its anniversary
12. **#14 Photo moments** — Nostalgia — *(parked)* the face of the memory
13. **#43 Family/legacy lineage** — Nostalgia — golf across generations
14. **#10 Season kickoff ritual** — Tradition — the season starts with a story
15. **#7 Head-to-head pre-game card** — Rivalry — the record, surfaced before the tee

## Ranking 2 — by implementation complexity (the quick-wins matrix)

**High impact, low effort — build first (the V1 core):**
#19 storyteller voice · #25 instant rivalry update · #48 named rivalries · #1
countdown · #7 pre-game card · #12 signature capture · #26 haven't-played nudge ·
#29 streak-at-risk · #22 first-to-know · #21 settlement voice · #46 living
identity · #2 pre-round trash talk · #9 roster reveal · #10 kickoff ritual.

**High impact, high effort — invest deliberately (Year 2 flagships):**
#35 Wrapped · #36 chemistry · #34 archive · #41 traditions · #13 live
leaderboard · #14 photos · #11 live pings.

**High impact, highest effort — the horizon (Year 5):**
#43 family/legacy · #45 evolution arc · #50 anniversary triggers · #42 league
lore.

**Lower impact — do only when adjacent work makes them nearly free:**
#5 invitation card · #6 weather · #8 first-time scouting · #17 course-record
watch · #31 rivalry heat check · #32 weekly digest · #33 closest-you've-come.

## Ranking 3 — the "forever" set (permanent product DNA)

These are not features; they are what CupSeason *is*. Removing any one would
make it a different product. Marked ∞ throughout; the irreducible core:

- **The lifespan gradient** — moment → achievement → trophy → archive (already
  live; the organizing principle of everything above).
- **The Round Recap Card** (#18) — the artifact of the peak and the growth loop.
- **The rivalry ledger** (#25, #38, #48) — the scoreboard of friendships.
- **The countdown/anticipation layer** (#1, #2) — the before-phase we're missing.
- **The archive** (#34) — the moat.
- **Wrapped & chemistry** (#35, #36) — the annual and relational memory.
- **Traditions** (#41) — the reason a league comes back for year two, three, ten.
- **The storyteller voice** (#19) — the connective tissue; every surface speaks it.

---

## The roadmap

### Version 1 — *"Every round is a story, and the story is yours first"*

The thesis: we already capture and score rounds; V1 makes them **feel like
events** on both ends — anticipation before, the peak after — using systems that
already exist. Almost entirely client + light RPC work; no new capture burden on
the golfer.

- **Before:** #1 countdown · #2 pre-round trash talk · #7 head-to-head card · #9
  roster reveal · #10 kickoff ritual · #48 named rivalries · #3 the callout.
- **During:** #12 signature-moment capture *(the one during-round build)*.
- **After (the peak):** #18 recap card · #19 storyteller voice · #21 settlement
  voice · #22 first-to-know · #23 comeback tag · #24 partner shoutout · #25
  instant rivalry update.
- **Days later:** #26 haven't-played nudge · #29 streak-at-risk.
- **Identity:** #46 living card.

*Why this set:* every item leans on the live moment/rivalry/tee-time/settlement
spine, each names a strong emotion, and together they close the two weakest
phases (before + resurfacing) without adding a single new thing the golfer has
to do mid-round. Primary emotions covered: Anticipation, Rivalry, Pride, Joy,
Nostalgia, Belonging, Tradition.

### Year 2 — *"CupSeason remembers your golf life"*

The archive and the annual/relational memory systems — the flagships that need
real data depth (which V1 spends the year accumulating).

- #34 personal archive · #35 Wrapped · #36 playing-partner chemistry · #37
  course history · #38 all-time rivalry ledger · #39 hall of records · #40 trophy
  cabinet · #41 traditions system · #44 milestone ladder · #47 nicknames · #49
  live record book · #27 on-this-day · #28 standing-challenge callback · #30
  course-memory resurface.
- The deferred *during* investments once photo + live pings clear their bar: #11
  live pings · #13 live leaderboard · #14 photos · #15 on-pace whisper · #16
  rivalry-moment live · #4 predictions market.

### Year 5 — *"A golf life, across generations"*

The legacy horizon — only reachable once there are years of real history to draw
on.

- #43 family/legacy lineage · #45 evolution arc · #42 league lore · #50
  anniversary & tradition triggers.

---

## Guardrails (what we will *not* build)

Per the anti-optimization list, these are permanently out of scope no matter how
much they'd "boost engagement":

- **No infinite scroll.** The board is finite and story-shaped.
- **No vanity metrics** — no follower counts, no likes-as-currency, no leaderboards
  of attention.
- **No engagement-bait notifications.** Every push is a memory or a relationship
  or a genuine competitive stake. If a nudge can't name one of the eight
  emotions, it doesn't send.
- **No addictive mechanics** — no streak-shame beyond a single dignified reminder,
  no manufactured FOMO, no dark patterns.
- **No generic social features** — comments and reactions exist only in service of
  the round's story, never as a feed unto themselves.

---

*This document is level 2–4 strategy (vision → mechanics) and governs feature
decisions in the Social & Engagement lane alongside `product-vision-v1.0.md`.
Any idea promoted to a build logs a `decision-log.md` entry first, per the
working protocol.*
