# Cup Season — Year 1 Go-To-Market Strategy

Growth Leadership Team · drafted 2026-07-16 (post App Store launch) · GROWTH/LAUNCH lane.
Governed by `spec/product-vision-v1.0.md` (five principles, five-question filter, the
Cup Season Test) and the monetization canon in `CLAUDE.md`. **Talk-first doc — strategy,
not a build order.** Numbers marked *(assume)* are working assumptions to validate; see §14.

---

## 0. The one idea this whole plan rests on

**We do not acquire golfers. We acquire *leagues*, one Pro at a time.**

The unit of adoption is a **group**, and every group has exactly one person who
summons it into existence — the Pro. Win the Pro and 8–16 golfers arrive with them,
pre-sorted into a competition that already has stakes (the pot), a calendar (the
season), and a reason to come back tomorrow (someone is beating them right now).

So the entire funnel, budget, and content plan optimize for one thing: **the number
of Pros who create a league, get their crew posting, finish a season, and run it
back.** An install with no league is worth ~nothing and will churn. We will
repeatedly refuse tactics that buy installs but don't create active groups. That is
the Final Rule, operationalized.

**North-Star Metric: Active Recurring Leagues (ARL)** — leagues that are either
mid-season with live weekly posting *or* have finished ≥1 season and started another.
It is the only metric that fuses group + recurrence + retention in a single number.

---

## 1. Success Metrics (Year 1)

### The group-activation funnel (our AARRR)
Discover → **Create league** → Invite crew → **Roster locks** (≥60% accept) → **First
rounds posted** → **First month closes** (shows-its-work standings land) → **Season
completes** → **Season 2 starts** (retention) → **Pro/player spawns a second league**
(referral). Every metric below sits on one of these gates.

### Leading indicators (predict the future; move weekly)
| Metric | Why it matters |
|---|---|
| **Leagues created / week** by a real Pro | Top of the only funnel that matters. |
| **Roster-lock rate** (leagues that reach ≥60% accepted invites) | The empty-league killer. A created-but-unlocked league is a dead league. |
| **Invite→accept rate** | Measures whether the invite artifact does the recruiting for the Pro. |
| **Time-to-first-round** per member; **% posting ≥1 round in week 1** | Activation. A member who never posts never returns. |
| **First-month-close reached** | The "aha" — shows-its-work standings ("leads by 25 · 25 back") is the product's magic; a league that sees one month close is retained. |
| **Live games played** (Match / Wolf / Skins) + **claim-link conversions** | The guest-claim wedge: a non-user plays one settlement-carded game and becomes a user. Our cheapest acquisition. |
| **Artifact shares → signups** (settlement card, recap, claim link) | Instruments the organic loop's actual coefficient. |

### Lagging indicators (confirm the model; move quarterly)
| Metric | Why it matters |
|---|---|
| **Season-completion rate** (leagues that finish a full season) | The retention arc; a completed season is a renewal candidate and a recap-share event. |
| **Season-2 renewal rate** | *The* retention number. This is what a subscription business lives or dies on. |
| **Referred leagues** (a Pro/player who starts or joins a *second* league) | Organic viral coefficient at the group level. Target k > 1 by Q4. |
| **Paid season passes / revenue per league** | The only revenue that exists (individual is free forever). |
| **Multi-league Pros / multi-season Pros** | LTV concentration — our best users run several leagues for several years. |

**One dashboard number to run the company on:** ARL, with the funnel's weakest gate
called out each week. Vanity metrics we will *not* celebrate: total installs, total
signups, social followers.

---

## 2. Market Segmentation & the Beachhead

| Segment | Attractive? | Pain today | How CS solves it | Channel | Message |
|---|---|---|---|---|---|
| **Standing buddy leagues** (Sat groups, men's-league-adjacent crews already running a "season" on a spreadsheet + GroupMe + Venmo) | ★★★★★ recurring, has a clear Pro, hair-on-fire pain | Spreadsheet fatigue, pot/Venmo tracking, "who's actually winning?", handicap arguments | Replaces the spreadsheet; keeps the pot's ledger (money moves between friends); shows-its-work standings; auto-handicap | The Pro directly (r/golf, local FB golf groups, course boards, word of mouth) | *"Retire the spreadsheet. Run your season in your pocket."* |
| **Men's / women's associations** (course-run leagues) | ★★★★ big rosters, recurring | Manual scorekeeping, board-driven, low-tech | Same, plus board/settlement automation | Course pro shop, association organizers | *"Your league, minus the clipboard."* |
| **Golf-trip crews** (Bandon/Scottsdale buddies trips) | ★★★ high passion, but *episodic* not recurring | Formats, live scoring, memories | Tee sheet (Match/Wolf/Skins), settlement cards, recap | Trip organizer, r/golf trip threads | *"The trip deserves a trophy."* |
| **Charity tournaments** | ★★ high visibility, **one-and-done** | Day-of logistics | Live games + settlement, but no season → no retention | Event organizers | (Use as a *demo* surface, not a core segment) |
| **Corporate golf leagues** | ★★ budget exists, gatekept, slow | Coordination across busy people | Season structure, low-friction posting | HR/culture leads (Q3 experiment only) | *"The company league that runs itself."* |
| **Country clubs** | ★★ prestige, **gatekept**, long sales cycle | Legacy systems, staff-run | Season + history + club championship | GM/head pro (Y2 territory) | *"Season-long, with a real record."* |
| **Public-course regulars** | ★ diffuse, no natural Pro | No group at all | We can't manufacture a group | (weak — deprioritize) | — |

### Dominate first: **standing buddy leagues in year-round-golf metros, starting Phoenix/Scottsdale.**
Three reasons, in order:
1. **They already run a season** — the behavior exists; we're replacing a spreadsheet,
   not inventing a habit. Fastest path to activation.
2. **They have an identifiable Pro** with real pain (pot tracking, standings disputes).
   One conversation converts a whole group.
3. **Year-round golf = no off-season churn cliff** in Year 1, and it's the founder's
   backyard (PIGL, Tempe). We can white-glove these leagues in person. Cold-climate
   metros come in Q2 timed to spring — never as a winter cold-start.

Win 25–50 of these deeply before widening. Depth over breadth: a segment we *own*
becomes a referral engine; a segment we sample evaporates.

---

## 3. The Organic Growth Engine (already half-built — instrument and sharpen)

The product ships the loop; growth's job is to *measure and amplify* it, never to
bolt on spammy virality (that violates Principle 2 and the Final Rule).

- **The invite** does the Pro's recruiting: the join covenant + auto-join link means a
  Pro forwards one link to GroupMe and the crew self-assembles. *Sharpen:* make the
  invite carry a preview of the league (name, crew, pot) so accepting is a yes-to-a-thing.
- **The settlement card** (Match/Wolf/Skins) is a share-native artifact: it names a
  winner, shows the money, and carries a **claim link** for any not-yet-user in the
  group. *This is the guest-claim wedge* — the single best acquisition surface we own.
  Instrument card-share → claim → signup end to end.
- **The season recap / annual "Wrapped"-style summary** — an emotional, screenshot-ready
  story of a crew's season (champion, rivalries, moments, trophy case). Drops at season
  end and New Year. People share pride, not ads.
- **Named rivalries & lead-change moments** — "the Cup changed hands" is a share moment;
  a christened rivalry is a story people tag each other in.
- **Group milestones** — first month closed, roster locked, Cup Final seeding — each a
  board post that can become a share.

**Design rule for every shareable moment:** it must (a) make the *sharer* look good
(pride, not promotion), (b) contain a **claim/join path** for the viewer, and (c) show
the product doing something a spreadsheet can't. If it doesn't carry a path back in,
it's decoration.

**Referral loop (see §8) rewards the *downstream league*, not the install** — the only
way to keep the loop from filling with dead signups.

---

## 4. 12-Month Roadmap (quarters mapped to the golf calendar)

### Q1 — Beachhead & Instrument (launch → early spring)
- **Objective:** 25 active leagues completing/mid-season in Phoenix/Scottsdale + founder network. Prove the loop.
- **Product (small eng team):** close activation gaps found in the timed QA (`spec/prelaunch-qa-2026-07-13.md`); ship **spreadsheet import** ("bring your season"); fully **instrument the artifact→claim→signup loop**; first-round nudge.
- **Marketing:** founder-led only. r/golf + local FB golf groups, course-board flyers with QR, PIGL run loudly in public.
- **Community:** white-glove onboard *every* Pro (30-min call). Founding-League badges (PIGL + first 5–10) free forever.
- **Partnerships:** 3–5 local courses; 1–2 niche golf newsletters/podcasts warm-up.
- **KPIs:** leagues created, roster-lock rate, time-to-first-round, artifact→signup instrumented.
- **Risks:** empty-league death; activation gaps; loop not yet measurable. Mitigate with white-glove + instrumentation.

### Q2 — Ambassadors & Content Engine (Masters season / spring wakeup)
- **Objective:** 100 active leagues; first paid renewals from Q1 leagues finishing; expand to a 2nd–3rd metro (a year-round + a spring cold-climate).
- **Product:** self-serve Pro onboarding (codify the white-glove into an in-app checklist); recap polish; off-season/Ryder event hooks.
- **Marketing:** content engine on (see §5); Masters-timed "start your season" push.
- **Community:** **Pro Champions / Ambassador program** recruited from Q1's best Pros; commissioner community (a place for Pros to swap playbooks).
- **Partnerships:** 2–3 niche newsletter/podcast placements; teaching-pro pilots.
- **KPIs:** ARL to 100; season-completion rate on Q1 cohort; first renewals; ambassador-sourced leagues.
- **Risks:** onboarding doesn't codify (still needs founder); cold-metro cold-start. Mitigate: keep white-glove for high-value Pros, self-serve for the long tail.

### Q3 — Referral Loop & Revenue Proof (summer peak golf)
- **Objective:** 300 active leagues; season-2 renewal proof; referral k approaching 1.
- **Product:** referral mechanics (reward on downstream activation); the Ryder as an off-season/event add-on; corporate/charity **experiments** (not core).
- **Marketing:** amplify leagues-spawning-leagues; small paid *retargeting* test on warm artifact-viewers only.
- **Community:** ambassador-run local meetups / "league nights"; early-adopter recognition (founding wall).
- **Partnerships:** expand course network in the 2–3 metros; first equipment/brand conversation (low priority).
- **KPIs:** referred-league count, season-2 renewal rate, revenue per league.
- **Risks:** renewal number disappoints → the whole model is questioned. This is the make-or-break read; instrument early.

### Q4 — Retention, Renewal & Annual Wrapped (season endings / off-season)
- **Objective:** benchmark renewal rate; sustainable revenue signal; go/no-go on paid scale for Year 2.
- **Product:** **Annual Summary / "Season Wrapped"** viral drop; winter modes for cold metros; Year-2 scale prep.
- **Marketing:** New-Year "start your season" + Wrapped campaign (the year's biggest organic moment).
- **Community:** season-end trophy/recap celebration; renewal drive ("run it back").
- **Partnerships:** convert the warm partners into recurring channels.
- **KPIs:** season-2 renewal rate (the number), ARL, revenue run-rate, viral coefficient.
- **Risks:** off-season churn; renewal mistrust on price. Mitigate with Wrapped re-engagement + charge-after-proven-value pricing.

---

## 5. Content Strategy (year-long, community-fed)

**Platforms, prioritized:** (1) **Reddit r/golf & niche golf subs** — where Pros with
the pain already are; participate, don't advertise. (2) **Instagram** — the settlement
cards/recaps are natively visual; UGC engine. (3) **Founder blog/newsletter "How We Run
PIGL"** — SEO + genuinely useful, captures Pros Googling "golf league app / skins
calculator / how to run a golf league." (4) **TikTok/Shorts** — founder personality &
share moments, secondary. YouTube long-form is Year 2.

**Themes (each maps to the brand):**
1. **Artifacts-as-content** — real recaps, settlement cards, rivalry moments. *Supports Memory > Statistics; every post shows the product making a memory.*
2. **"How to run a league" educational** — the definitive, honest guide. *Supports Golf First + captures high-intent Pros via search.*
3. **Founder / build-in-public / PIGL diary** — authentic, cheap, compounding trust. *Founder-led growth with limited brand recognition; people back a person.*
4. **Community stories** — this crew's season, this rivalry. *Real Golf principle; social proof that converts Pros.*
5. **Seasonal campaigns** — Masters ("start your season"), majors, Ryder Cup week (lean into the Ryder events feature), New Year Wrapped, spring cold-climate kickoff. *Rides existing golf attention.*
6. **Product updates** — shipped in the community's voice, not changelog-speak.

**Ratio:** ~60% community stories + artifacts, 25% educational, 15% founder/product.
We are a documentary of real leagues, not a brand shouting.

---

## 6. Community Strategy (how CS becomes routine)

- **Commissioner community** — a private space (Discord/Circle) for **Pros only** to
  swap playbooks, request features, and feel like founders of a movement. Pros are the
  fulcrum; make being a CS Pro a *status*.
- **Ambassador / Pro Champions program** — recruit from Q1's best Pros. Reward with
  founding badges, free seasons, early features, and recognition — *not cash*. Their job:
  onboard nearby Pros and host league nights.
- **Beta champions & early-adopter recognition** — a permanent "Founding League" wall;
  PIGL as league #1, publicly. Status is the cheapest, stickiest currency we have.
- **Feedback loops** — the five-question filter run *with* the commissioner community;
  ship visibly in their voice; close the loop publicly ("you asked, we built").
- **Routine hooks** — the app "feels alive" (Principle 5): the weekly push that someone
  posted, standings shifted, a rivalry moved. Community + product together make opening
  CS a Saturday-night habit.

---

## 7. Partnerships (ranked by impact ÷ effort)

| Rank | Partner | Impact | Effort | Why |
|---|---|---|---|---|
| 1 | **Local courses / men's-league boards** (in the 1–3 target metros) | High | Low | Deliver *whole groups* with a Pro attached; warm, high-intent, flyer/QR at point of play. |
| 2 | **Niche golf newsletters** (Fried Egg-adjacent, local/regional) | High | Low | Audience overlaps with organizers; they need content; a founder story is cheap. |
| 3 | **Mid-tier golf podcasts** | Med-High | Low-Med | Organizer-heavy audiences; hungry for guests/stories. |
| 4 | **GHIN league organizers / local golf associations** | Med | Med | Sit on top of exactly our segment; slower, relationship-driven. |
| 5 | **Teaching professionals** | Med | Med | Have groups, but low tech-adoption; good for pilots not scale. |
| 6 | **Charity events** | Low-Med | Med | Great *demo* surface, no retention; use to seed, not to grow. |
| 7 | **Equipment brands** | Low (Y1) | High | Slow, gatekept, low intent-match. Y2 at earliest. |

**Do first:** courses + newsletters/podcasts. **Do not chase in Y1:** equipment brands,
PGA, big media. They flatter the ego and starve the funnel.

---

## 8. Referral Strategy (reward groups, not installs)

- **What's rewarded:** a Pro/player whose referral results in **another league that
  locks a roster *and* closes its first month** — i.e., a *real, activated* league, not
  a signup. Downstream activation is the trigger.
- **When earned:** at the referred league's **first month-close**, never at install or
  even at signup. This structurally blocks low-quality referrals.
- **The reward:** free season pass(es), **Founding-adjacent status/badges**, "brought N
  leagues" recognition, early features. **Never pot credit** (the pot is tracked, never
  held — money never flows through us; §CLAUDE.md). Status + free seasons align with the
  monetization model and cost us nearly nothing.
- **Two-sided:** the new Pro already gets their first season free (existing model), so
  the ask is frictionless on both ends.
- **Why they participate:** Pros are proud of their league and *want* rivals to play —
  "start a rival league" is an in-character ask, not a bounty. The reward is recognition
  in a community they already value.

---

## 9. Lifecycle Marketing (relevance over volume)

| Audience | Push | Email | In-app |
|---|---|---|---|
| **New player** | "You're in {league} — {Pro} drafted you. Post your first round." | — (keep it in-app/push; email is for Pros) | First-round checklist; who you're playing. |
| **New Pro** | "Your league is created — invite the crew." | White-glove sequence: invite → lock roster → first month, with the Pro playbook. | Onboarding checklist mirroring the human white-glove. |
| **Inactive member** | "The crew posted 6 rounds this week — you're 3 back." (competitive FOMO, throttled) | Monthly only. | Standings nudge on open. |
| **Commissioner (ongoing)** | Month-close digest: "Here's the board post + who's slipping." | Monthly league health + renewal runway. | Pro tools to nudge their own crew. |
| **Active competitor** | Rivalry pings, number-to-beat, lead-change moments (already built). | — | Live "someone's coming for you." |
| **Season ending** | "Your season's done — here's the recap + who owes what." | Recap + **"run it back?"** renewal CTA. | Trophy case, settlement, recap share. |
| **Off-season** | "Start a winter mini / a Ryder event." | Annual Wrapped drop; spring "new season" for cold metros. | Off-season modes surfaced. |

**Governing rule:** every message must be true to *this golfer's* league this week, or
it doesn't send. Volume is the enemy of Principle 2. Relevance is the whole game.

---

## 10. Paid Acquisition (small, late, warm-only)

- **Default stance:** near-zero in H1. Paid buys installs; installs without a group
  churn. Stripe/ad-spend stays parked until the organic loop's coefficient is measured.
- **If we test (Q3+), in priority order:**
  1. **Retargeting warm artifact-viewers** (people who opened a shared settlement card/recap) on Meta/IG — highest intent, closest to a group.
  2. **Google Search** on high-intent Pro queries: "golf league app," "golf league spreadsheet," "skins game calculator," "how to run a men's league." Captures the exact pain.
  3. **Reddit r/golf** — intent-rich, cheap, native.
- **Creative concepts:** the settlement card ("here's who owes what"), the "who's
  winning" standings line, **"Retire the spreadsheet,"** the Wrapped recap. Show the
  product doing the un-spreadsheet-able thing.
- **Experiments:** CPI is a trap; measure **Cost per Activated League** (roster locked +
  first month closed). Run search vs retargeting vs Reddit on that metric.
- **When to scale:** only when Cost-per-Activated-League < league LTV *and* the organic k
  is known — then paid *pours fuel on a proven fire*. **When not to:** ever, if we're
  buying installs to hit a downloads number. That's the exact trap the Final Rule forbids.

---

## 11. Revenue Strategy (charge after proven value; never gate the golfer)

- **The model (canon):** one general membership; the **season pass is paid by the Pro
  out of the pot** (~$49–99/season ≈ $5–8/player *(assume, PARKED pending focus groups)*);
  **individual identity + handicap free forever**; live games lean free (the guest-claim
  funnel). Founding leagues (PIGL + first 5–10) free forever.
- **When to introduce paid:** at the **end of a league's first free season** — the moment
  of maximum proven value (the recap just landed, the season "just worked"). "Run it back
  for ${X}/season." Not at signup, not mid-first-season.
- **Who pays first:** Pros of *established* leagues who felt the spreadsheet pain and now
  can't imagine going back. They are the least price-sensitive and the most evangelical.
- **Upgrade moments:** starting Season 2; unlocking the **Cup Final** endgame; running a
  **second league**; adding a **Ryder** event. Charge at a moment of *added* value, not as
  a toll on core play.
- **Pricing experiments:** price *against the pot* not against other apps ($5–8/player of
  a $500 pot is a rounding error); test season-1-free scope, per-league flat vs per-head,
  and a multi-league Pro discount. Run these as small cohort tests in Q3–Q4, not a
  launch-day paywall.
- **LTV without hurting adoption:** LTV lives in **multi-season retention** and
  **multi-league Pros**, never in squeezing the individual golfer. Keep the golfer free
  forever (the TheGrint lesson — never resell the handicap); grow revenue by growing
  *leagues per Pro* and *seasons per league*.

---

## 12. Founder-Led Growth — 10 hrs/week on what compounds

Ranked by compounding return (do them top-down):
1. **White-glove every new Pro (≈4 hrs).** A 30-min onboarding call per Pro is the
   highest-leverage hour in the company right now — it saves the league from empty-league
   death and mints an evangelist. Each onboarded Pro is a durable, referring asset.
2. **Run PIGL loudly in public + turn its moments into content (≈2 hrs).** The reference
   league *is* the marketing. Every settlement/recap/rivalry is a post. Compounds as a
   growing library of proof.
3. **Show up where organizers gather (≈2 hrs).** r/golf, local FB golf groups, the
   commissioner community — answer "how do you run a league" questions *with* CS as the
   honest answer. Builds authority and inbound.
4. **Write the "How We Run PIGL" playbook / build-in-public posts (≈1 hr).** Evergreen,
   SEO-compounding, converts searching Pros for years.
5. **Recruit & activate ambassadors (≈1 hr).** Turn the best Q1 Pros into the people who
   do #1 and #3 in *their* metros — the only way founder-led growth escapes the founder.

Avoid (non-compounding): manual social posting volume, chasing big partnerships, tweaking
ads. Delegate or defer.

---

## 13. Failure Modes (5 most likely misses + mitigation)

1. **Pro adoption stalls** — we win golfers but not organizers; leagues never get
   created. *Mitigate:* white-glove Pro onboarding, spreadsheet import ("bring your
   season"), the Pro playbook, commissioner-community status. This is the #1 risk.
2. **The empty-league problem** — Pro creates a league but the crew never posts; it dies
   before the first month closes. *Mitigate:* aggressive-but-relevant first-round nudges,
   the **live-game wedge** (run one Skins round together to seed real data + a settlement
   card), pot stakes, roster-lock gating in onboarding.
3. **Off-season / post-season churn** — season ends and the crew evaporates, never
   renews. *Mitigate:* Sun-Belt-first beachhead, off-season Ryder/winter modes, the recap
   + Annual Wrapped as re-engagement hooks, the "run it back" renewal moment.
4. **Renewal/price mistrust** — Pros balk at paying after a free season ("the spreadsheet
   was free"). *Mitigate:* charge only after proven value, price against the pot, founding
   free tier for evangelists, never gate the individual golfer.
5. **The "betting app" perception → platform/legal/trust friction** — the pot reads as
   gambling to a reviewer, a store, or a cautious Pro. *Mitigate:* hold the line on
   **"the app keeps the ledger — money moves between friends, not through the app"**
   (D39 phrasing) in every surface and store
   listing (Product Vision explicitly: *not a betting app*); keep this as a standing
   assumption to re-validate (§14).

*(Latent sixth: single small eng team can't close activation gaps fast enough — protect
eng time for the funnel's weakest gate, not feature breadth.)*

---

## 14. Assumptions to validate EARLY (before spending on them)

1. **Pros will pay ~$49–99/season from the pot.** *(PARKED — focus groups.)* If false,
   the whole revenue model changes. Validate in Q2 with the first finishing leagues.
2. **The artifact→claim→signup loop actually converts** at a rate that makes organic the
   primary channel. Instrument in Q1; if the coefficient is low, the plan's paid stance
   changes.
3. **White-glove onboarding lifts activation** enough to justify founder hours (and can
   later be codified into self-serve). A/B in Q1.
4. **The ledger-only pot posture (D39) clears App Store review and Pro trust** without gambling
   friction. Confirmed enough to launch; re-validate on any store-policy change.
5. **Year-round metros retain across the calendar** without a churn cliff, and cold-metro
   spring launches activate. Watch Q1→Q2 cohorts.
6. **Standing leagues will migrate off their spreadsheet** (switching cost isn't a wall).
   Spreadsheet-import adoption in Q1 is the tell.
7. **Referral triggers on downstream activation don't feel too slow** to motivate. Watch
   referral participation once live in Q3.

---

## 15. Where the team disagrees — and the call

| Tension | The disagreement | Recommendation |
|---|---|---|
| **Paid vs organic (Performance Mktg ↔ Founder/VP Growth)** | Perf wants early Meta/Google tests for signal; Founder says paid buys installs not groups. | **Organic-first.** Paid stays near-zero in H1, used only for *warm retargeting* and *high-intent search* tests in Q3+, measured on Cost-per-Activated-League. Scale only after organic k is known. |
| **Breadth vs depth (Content ↔ Community)** | Content wants broad top-funnel reach; Community wants deep engagement with few. | **Depth first.** Own the buddy-league segment in 1–3 metros; content *amplifies community stories* rather than chasing generic reach. A owned segment refers; a sampled one evaporates. |
| **Big vs local partnerships (Partnerships ↔ Founder)** | Partnerships eyes equipment brands/PGA; Founder says gatekept and slow. | **Local courses + niche newsletters/podcasts win Y1.** Big brands are Y2. Impact ÷ effort is decisive (§7). |
| **Polish vs authenticity (Brand ↔ Founder-led)** | Brand wants a polished, scalable identity; founder-led wants raw, personal presence. | **Authenticity now, polish as we scale.** With no brand recognition, people back a person and real leagues; keep a consistent visual system (the existing gold-forward brand) but let the founder's voice lead. |
| **Charge early vs free longer (Lifecycle/Revenue ↔ Growth)** | Revenue wants earlier monetization signal; Growth fears a paywall chilling adoption. | **Charge after the first proven season, never at signup.** Free-forever golfer + free first season protects adoption; the Pro pays from the pot at peak value. |

---

## Deliverables index (this doc contains all six)
1. **One-year launch strategy** — §0–§3, §15.
2. **Quarterly execution roadmap** — §4.
3. **Monthly marketing calendar** — see the month grid below.
4. **Prioritized experiment backlog** — see the ICE table below.
5. **Success-metrics dashboard** — §1 (ARL north star + funnel gates).
6. **Assumptions to validate early** — §14.

### Monthly marketing calendar (skeleton — golf-calendar anchored)
| Mo | Anchor | Primary move | Content beat |
|---|---|---|---|
| M1 | Launch | White-glove first Pros; r/golf presence | PIGL diary kickoff |
| M2 | — | Course-board flyers/QR (metro 1) | First community story |
| M3 | Masters | "Start your season" campaign | Masters-timed educational |
| M4 | Spring | Metro 2 + cold-metro spring launch | Ambassador recruit |
| M5 | — | Commissioner community opens | Pro playbook publish |
| M6 | Majors | Newsletter/podcast placements | Rivalry-moment reel |
| M7 | Summer peak | Referral loop live | Leagues-spawning-leagues stories |
| M8 | — | Corporate/charity experiments | UGC push |
| M9 | Ryder Cup wk | Lean into Ryder events | Ryder-event campaign |
| M10 | Season ends | Renewal drive ("run it back") | Recap shares |
| M11 | Off-season | Winter modes; warm-partner recurring | Retention stories |
| M12 | New Year | **Annual Wrapped** viral drop | Wrapped + "start your season" |

### Experiment backlog (ICE-ranked; run top-down)
| # | Experiment | Impact | Confidence | Ease | Note |
|---|---|---|---|---|---|
| 1 | Instrument artifact→claim→signup loop | H | H | H | Prereq for everything; do first. |
| 2 | White-glove vs self-serve Pro onboarding | H | M | H | Validates founder-hour ROI. |
| 3 | Spreadsheet-import as acquisition hook | H | M | M | Kills switching cost. |
| 4 | Live-game (Skins) wedge to seed a league | H | M | M | Beats empty-league death. |
| 5 | First-round nudge timing/copy | M | H | H | Cheap activation lift. |
| 6 | Founding-league badge as referral driver | M | M | H | Status-as-reward test. |
| 7 | Course pro-shop QR/flyer conversion | M | M | H | Point-of-play acquisition. |
| 8 | Season-recap share → new-Pro attribution | H | L | M | Measures true virality. |
| 9 | Warm-retargeting paid test (Cost/Activated League) | M | L | M | Gate for scaling paid. |
| 10 | "Start a rival league" referral CTA | M | M | M | In-character referral. |

---

**Final Rule check:** every section above is scored against *"does this help another
golf group discover, adopt, and continue playing on Cup Season together?"* Anything that
only moved installs (broad paid, download campaigns, vanity partnerships) was
down-ranked or cut. The plan optimizes leagues, not logins.
