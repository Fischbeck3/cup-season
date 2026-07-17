# Cup Season — Product & UX Design Review

2026-07-16 · reviewed against: product-vision-v1.0 · spec-v1.0 · decision-log
(D1–D23) · IA blueprint (Home/Crew/⊕/You) · memory-layer-v1 · personas v1.0 ·
prelaunch-qa-2026-07-13 · the live client at v23.173. Framing: Series A
diligence + private-beta readiness. Mandate: no redesign, no new features —
simpler, clearer, more emotionally compelling.

**Overall grade: B.** A-grade product thinking, B-grade coherence, C-grade
scope discipline, and a validation record that is still effectively blank —
no league has completed a month in production, the 60-second post has never
been timed, and the timed QA run is still gated on deploy (F1). The single
most valuable thing this product can ship right now is not a feature. It is
one completed real month of PIGL.

---

## 1. The three-distance test (run against the live client)

**30 seconds — "What is this?"**
The sign-in screen says: *"Rally your crew. Post real rounds. Take the cup."*
Answer a stranger gives: **a fantasy-league app for my golf group.** Clear,
confident, honest. Pass — *for the league product.*

**30 minutes — "Can I run a competition?"**
The Pro path: wizard → lock → invite → draw → season is genuinely good — the
rebuilt wizard (D6/D8) is one-decision-per-step, the fine-print disclosure is
honest, and the draw is rigging-proof by construction. A golfer can post in
well under a minute *by inspection* — but it has never been timed (success
metric, vision §Success Metrics). Pass, with an asterisk the size of F1.

**30 days — "Why am I still here?"**
Answer the docs give: rivalries, moments, the countdown, nudges — the memory
layer. Answer the product gives *today*: standings movement and whatever the
board shows. For a league member, plausible. For the league-less individual —
the ESPN-model free hook the strategy bets on — the honest answer is
**"my index and my round history,"** which is thin. Solo retention is
asserted, not designed-in yet (archive/Wrapped/on-this-day are all Y2).

**The coherence finding.** The product has **three one-sentence identities**
in three governing docs:
- vision v1.0: *"the operating system for amateur golf leagues"* (commissioner-first)
- founding prospectus: *"where amateur golf counts"* (golfer-first)
- memory-layer v1: *"the memory layer of amateur golf"* (archive-first)

They rhyme, but they are not the same product at the door. The 30-second
screen sells identity #1. The monetization strategy (individual free forever,
guest-claim funnel) depends on identities #2/#3. A solo golfer arriving from
a guest-claim link lands in an app whose brand line tells them they need a
crew and a cup. This is not fatal — the league-less home is a complete app
(IA blueprint's own law) — but the front door and the strategy are betting on
different personas. **Name one primary identity for launch.** Recommendation:
lead with #1 (it's what's built, it's what PIGL is), and let #2/#3 stay the
north star rather than the pitch. Revisit after the guest-claim funnel has
real numbers.

---

## 2. Product vision — cohesion & creep

**Cohesive?** The mechanics are remarkably coherent: every mode is a lens
over immutable rounds; PvI is one currency; nothing ever mutates a round;
money is tracked never held. That architecture *is* the product's integrity
and it has survived 173 client versions intact. Rare, and worth saying.

**Has feature creep begun? Yes — at the surface layer, not the rules layer.**
The decision log is disciplined about *mechanics* (Hybrid killed, bonus layer
buried, 3-player Wolf hard-cut, dials collapsed — D6/D7/D8/D16 are exemplary
subtraction). But count the *surfaces* shipped pre-launch, pre-first-user:
season leagues, Cup Final + endgame dial, blind draw, Match Play, Wolf,
Skins, guest claims, live rounds, declared rounds + calendar + watch list,
The Ryder (an entire second product: rosters, sessions, taunts, MVP,
trophies, duels), named rivalries, moments, achievements, trophy case,
scenario math, auto-bye, auto-handicap engine, receipts, curated push. That
is a Year-2 surface area on a Day-0 user base. Each surface was individually
justified; collectively they are the classic pre-launch trap — building the
emotional architecture of Year 2 before validating that eight friends will
post rounds in month 1.

**Identity: clear?** Internally, yes (the hierarchy of truth is real
governance, not theater). Externally, split three ways as above.

---

## 3. Information architecture

The four-tab IA (Home / Crew / ⊕ / You) is correct and shipped. "The round is
the atom, screens are lenses" is the right organizing law. Remaining overlaps:

- **League vs Ryder — the one real duplicate concept.** Two parallel
  container types with parallel rosters, scoreboards, histories, trophies.
  The prospectus already names the fix (*Cup = one abstraction for every
  format*). Don't build that now — but stop the divergence: no new
  Ryder-only machinery that a season will eventually want, and vice versa.
  This is the architectural decision that gets expensive fastest.
- **Three "what's coming up" surfaces:** Home's Up Next, the calendar strip,
  the Watch List. They share data but are three renderings a user must learn.
  Merge direction: one "coming up" system, rendered at three sizes.
- **Identity surfaces mostly merged** (P3 did this) — You *is* the public
  card. Residual: "Tour Card" as a nav label vs "golfer card" in copy —
  one noun, per D11/D12 discipline.
- **The board carries four species** (rounds, moments, chat, announcements) —
  E3's pinned announcements helps; planned M4 threads will fragment further.
  Watch that the board stays *one* legible stream at crew scale.

Navigation is obvious. The noun hygiene work (D11/D12/D13) is genuinely good
and mostly done.

---

## 4. Mental models

Ask five users "what is this app?" today and you get: *fantasy golf* (the
tagline), *a handicap tracker* (the solo poster), *our league's spreadsheet,
alive* (the Pro), *a betting ledger* (the Wolf table), *a golf social feed*
(the board reader). The first and third are compatible; the rest are partial
views. The product's own answer — "every round counts because it belongs to
a season" — is only legible **after** you're in a league mid-season. Nothing
on the league-less home says it.

**One inconsistency worth fixing in copy:** side games settle money but never
touch cup points (correct design, spec §13.2), yet both render as "points"-
adjacent cards on the same board. The separation the *rules* make must be
made by the *screen* every time (the settlement card mostly does this; the
Wolf ledger line should never share a visual system with cup points).

---

## 5. UI hierarchy (structure only, per mandate)

- **Home** has one primary purpose (what happened / what's next) and mostly
  honors it. Risk: as moments, nudge chips, Up Next, and scenario lines all
  land on Home, its attention budget is already spent. Any new Home element
  must displace one, not join it.
- **The League Room** segmentation (standings/board/schedule/pot/league) is
  right; each pane has one job.
- **The post card** is the best screen in the app: one number in, one story
  out ("84 · beat your number by 0.6 → 7 pts"). Post-D1/D2 it is genuinely
  no-tutorial. (This review shipped the last jargon fix: the Differential
  tile is now Gross.)
- **Attention splits to watch:** (a) standings rows now carry points +
  narrative + scenario line + receipts affordance — approaching the "seven
  numbers" problem D2 killed on round cards; prune to points + one line.
  (b) You tab stacks identity, display case, stats, rounds, buddies, season
  history — it's five screens' worth of content on one; acceptable now,
  first candidate for progressive disclosure at scale.

---

## 6. Cognitive load — the full concept inventory

What a new *member* (not Pro) must eventually hold:

**Easy (self-evident or learned in one glance):** post a round · gross ·
points · the board · squads · the pot · markers · trophies · buddies ·
week rhythm.

**Moderate (one exposure + good copy):** index (auto-derived) · "your
number" · the five bands · best-4 counting cap · the 2-round floor · vouch ·
guests · 9-hole half value · receipts · declared rounds · rivalries.

**Difficult (will generate questions in every league):**
1. **Displacement** — "where did my fifth round go?" (D3's fill meter is the
   right answer; it must be *everywhere* points are, not one screen).
2. **Cup Final scored fresh** — the single biggest "wait, what?" in the
   product. D4's foreshadow shipped; keep it loud through week N−4.
3. **Auto-bye + floor interaction** — forgiving, but two-system.
4. **Provisional scoring** (first 3 rounds fixed at 7) — currently
   under-explained at exactly the moment a new golfer is most nervous.
5. **League vs Ryder containment** — which container am I in, what counts
   where.
6. **Index governance** (rise cap, exceptional-score cut) — invisible until
   it fires on someone; when it fires it MUST explain itself in band
   language, not WHS language.

**Simplification recommendations (copy/surface only, no rule changes):**
- A one-line "getting your number" explainer on the first three round cards
  ("Rounds 1–3 score a flat 7 while we learn your number").
- The auto-bye, when it fires, already has welcome-back framing (D14) —
  extend the same self-explaining pattern to the rise-cap and exceptional-
  score events. **Rule: any mechanic that fires automatically must narrate
  itself in one sentence on the surface where it fired.** That rule, applied
  everywhere, is worth more than any new feature in this document.

---

## 7. Competition systems

**Can users predict outcomes?** Since v23.170 (scenario math, D21-batch-5),
increasingly yes — and the honesty rule (never declare clinch/elimination
unless provable under the generous ceiling) is exactly right. Gap: the
personas' *"my next round matters because…"* — the one-line pre-round stake
for MY round — is the highest-value unbuilt projection, and it's a client
line over existing math, not an engine.

**Do standings make sense?** Storytelling standings are strong. Watch row
density (see §5).

**Is scoring intuitive?** The bands, post-translation, are the best-explained
part of the product. The floor's psychology ("a posted 98 beats an unposted
82") is a genuine design achievement — and the join covenant saying "you
can't hurt your squad by playing badly, only by not playing" is the single
best sentence in the app.

**Where will commissioners struggle?**
1. **Getting 7+ friends through onboarding before kickoff.** This is the
   hardest moment in the product's entire life and it happens first. It is
   also completely unmeasured.
2. **Mid-season roster attrition** — remove_member is setup-only; a month-3
   dropout has no tooling (the squad-plays-short rule exists on paper). This
   WILL happen in season 1.
3. **The index trust battleground** — the app-computed index will be
   challenged the first time it diverges from someone's GHIN. Receipts are
   the defense; make sure the index's own receipt (which 8 of 20, what
   changed on the 1st) is as tappable as a points receipt.
4. **Pot chasing** — tracked-never-held is right; the Pro still does Venmo
   archaeology. The ledger is the product; fine for v1.

---

## 8. Social & memory

The engagement research (memory-layer-v1) is the strongest document in the
repo — the emotion-named nudge policy (D23) and the anti-optimization
guardrails are a real moat against enshittification, and the lifespan
gradient (moment → achievement → trophy → archive) is a genuinely original
organizing principle.

Two honest problems:

1. **The thin-feed problem — the #1 unacknowledged risk in the whole stack.**
   Principle 5 says "opening Cup Season should reveal something new." An
   8-person league posting weekly generates ~2–3 board items a week. Most
   opens will reveal *nothing new*. No amount of moment-engine polish changes
   the arithmetic of crew-scale content volume. Mitigations that exist:
   nudge chips, countdowns, declared rounds. Mitigation to add: **shape Home
   for the quiet day** — a "since you were here" digest frame and a
   yesterday's-highlight makes 3 items/week feel curated instead of dead.
   Set retention expectations accordingly: this app's natural open cadence
   is 2–4×/week, not daily. Chasing daily opens would violate the product's
   own guardrails.
2. **17 V1 memory features is not a V1.** The set is right; the size isn't,
   pre-launch. The 80/20 by the docs' own impact ranking: countdown (#1),
   recap card (#18), rivalry update (#25) + named rivalries (#48, shipped),
   first-to-know (#22, shipped), haven't-played nudge (#26). Callout (M5 —
   ⚑ still unresolved) and trash-talk threads (M4) should wait for real
   usage signal.

**Does sharing feel natural?** The settlement card and claim link are the
right artifacts. The recap card (#18) is correctly identified as the #1
growth loop — it should outrank every remaining memory feature.

---

## 9. Onboarding — the invited friend, walked through

Text from a buddy: "join my golf league — code PIGL22."

1. Opens link. Sees "Rally your crew…" — *"this is Jake's fantasy golf
   thing"* — coherent, because they arrived WITH a crew. (The solo arrival
   has no equivalent moment — see §1.)
2. Email → 8-digit code. Friction: code latency + spam folder (Brevo). Every
   minute of email delay here is the #1 quit point of the whole product.
3. Golfer card. **The index field is the anxiety spike.** A casual invitee
   doesn't know their index and fears getting it wrong in front of friends.
   The auto-handicap engine already makes a manual index a starter that
   scores overtake — but the field doesn't SAY so. One line kills the fear:
   *"Best guess is fine — after 3 rounds we work out your real number."*
4. Join covenant — genuinely good; the floor promise lands here, where fear
   is highest.
5. Lands pre-season: "what do I do now?" — the practice-round hint exists;
   the countdown card (shipped) now gives this state a pulse.

**Excitement peaks:** seeing friends' markers already inside; the draw
reveal. **Quit risks, ranked:** email latency → index anxiety → dead
pre-season screen. Two of three have shipped mitigations; index-anxiety copy
is a 15-minute fix and is this review's cheapest recommendation.

---

## 10. Long-term engagement

- **Weekly:** solid — post, standings shift, week close, watch list.
- **Monthly:** strong — the month close is real drama (caps, floors, ledger,
  board post), and it's automated. This rhythm is the product's heartbeat.
- **Yearly:** designed (Trophy Room, run-it-back as the renewal moment) but
  UNTESTED — no league has ever finished a season. Season 1's ending is a
  product launch of its own; treat it that way when it approaches.
- **Five years:** the archive/Wrapped/traditions vision is credible and
  correctly deferred to Y2/Y5. The moat is real *if* seasons 1–2 retain.

---

## 11. Business

- **Value before payment: genuinely honored.** Everything a player touches
  is free; the pot-priced season pass ($49–99 ≈ $5–8/player) is priced
  against the pot, not the App Store — smart, and defensible to a friend
  group ("the app costs less than one skin").
- **Who benefits most:** the Pro (spreadsheet liberation) — and the Pro
  pays. Aligned.
- **Risks a Series A reviewer will name:** (1) monetization surface is ONE
  SKU on the league container; leagues without money pots lack the pricing
  anchor. (2) Zero usage data of any kind yet. (3) Single-developer,
  single-file architecture (see §14) as key-person + diligence risk.
  (4) The free tier is so complete that the paid layer must be invented
  later without betraying "free forever" promises — the Founding League
  badge partially hedges this.
- The TheGrint lesson (never resell the index) is correctly institutionalized.

---

## 12. The hard questions

**What are we pretending users care about?**
- Fairness *dials* (allowance %, verification tiers, format options). Users
  care that it FEELS fair, which receipts deliver; nobody asked for a dial.
  (The decision log already knows this — D8 — and mostly acted on it.)
- The Ryder, at launch. It's built and good; no launch league needs it in
  month 1.
- Precision. The bands exist because ±0.1 doesn't matter; some surfaces
  still whisper decimals.

**What will users actually care about?**
1. Does my round post in under a minute, every time, at the trunk of my car.
2. Does the app settle arguments (receipts) or start them (index trust).
3. Does the pot math check out to the dollar.
4. Trash talk having a home.
5. Whether the feed is alive on a Tuesday (see thin-feed, §8).

**What should we stop building?** Everything, until F1 clears, the timed QA
runs, and PIGL completes one real month. The marginal feature is now worth
less than the marginal *proof*.

**What should we double down on?** The post flow (it's the atom), receipts
(they're the trust engine), the recap/settlement/claim artifacts (they're
the growth loop), and the month-close drama (it's the retention heartbeat).

---

## 13. Kill list

**Remove from v1 surfaces (mechanics stay spec'd, dormant):**
1. **Head-to-Head format (B) from the wizard** — same argument that killed
   Hybrid (D6): a format menu is friction; nobody has asked. Points Race +
   endgame dial covers launch. One fewer explain.
2. **M5 Callout** — its own ⚑s are unresolved and it's social machinery in
   competition clothes; wait for a league to invent callouts in chat first
   (they will), then formalize what they actually do.
3. **M4 trash-talk threads** — the board IS the trash-talk surface at
   8-person scale; threads solve a fragmentation problem the product doesn't
   have yet.
4. **Watch-list projection ladder + live status** (personas) — correctly
   post-events-engine; keep deferred.
5. **"Most Improved" award tile whenever it would render "—"** — an award
   showing a dash all season is dead weight; render it only once 2+
   snapshots exist.
6. **The Ryder's creation entry point, soft-hidden at launch** — keep it
   fully working for PIGL's real event; don't advertise a second product to
   a league that hasn't finished month 1. (Cheapest possible "removal.")

**Why the product improves:** every removal above deletes a decision or a
dead surface from the first-month experience without deleting a capability.
The wizard gets shorter, Home gets quieter, and the concept inventory in §6
loses two Difficult entries.

**Explicitly NOT killed** (checked and endorsed): 9-hole half-value (real
behavior) · sim rounds (real behavior, PIGL needs it) · Wolf/Skins (shipped,
free, the acquisition surface) · auto-bye · the endgame dial (it's one
decision, honestly disclosed).

---

## 14. Design debt (pay before it compounds)

1. **The 8,855-line single-file client.** CLAUDE.md already calls the
   classic↔module boundary a landmine and has the scars (the silent-demo-
   fallback bug class). This is now also a diligence/hiring risk. The split
   into real modules should be scheduled — not now, but named as the first
   post-launch engineering epic, before surface #30 makes it twice as
   expensive.
2. **The demo diorama tax.** Every real feature pays `!state.demo` insurance;
   the ghost-string audit (A1–A12) happened because this pattern fails
   silently. Post-launch, when real screenshots exist, consider demoting the
   demo to a static tour and deleting the parallel render paths.
3. **Two container schemas** (league, ryder event) accreting in parallel —
   see §3. Freeze divergence now; unify on the Cup abstraction when (not if)
   a third format appears.
4. **The storyteller voice has no single home** — copy lives in template
   strings across 8k lines. A `voice.js` (or even one commented section)
   holding every narrated line would make the product's best asset — its
   tone — maintainable. Cheap now, painful later.
5. **Manual two-place version bump** (caption + sw.js) — a build-time stamp
   would delete a documented footgun.

---

## 15. Final deliverable

**1. Overall grade: B.** (Design intelligence A−, mechanics A−, IA B+,
legibility B+ and rising, scope discipline C+, validation D — unmeasured.)

**2. Biggest strengths**
- The immutable-rounds/lenses architecture — integrity by construction.
- The anti-sandbagging band design and floor psychology (§2.2's 12-ceiling,
  "a posted 98 beats an unposted 82").
- Receipts as a trust engine (§16) promoted to navigation law.
- The decision-log governance — subtraction actually happens here.
- The nudge policy & guardrails — a real moat against engagement rot.
- The wizard and the join covenant — fear handled at the door.

**3. Biggest weaknesses**
- Zero validated anything: no timed post, no completed month, no deploy (F1).
- Three-way identity split (league OS / counts / memory layer) at the door.
- Surface count outrunning the user count by two years.
- The thin-feed arithmetic vs the Feels-Alive principle — unacknowledged.
- League/Ryder container duplication.
- Single-file architecture as a scaling and diligence liability.

**4. Top 10 UX risks**
1. Onboarding email-code latency at the group-join moment (the funnel's neck).
2. Index-entry anxiety for the casual invitee (unexplained auto-overtake).
3. Cup Final fresh-reset comprehension (mitigated by D4; stays #1 rules risk).
4. Displacement confusion everywhere the fill meter isn't.
5. Index-trust disputes when app-index diverges from GHIN.
6. Thin feed reading as dead app on quiet days.
7. Standings row density recreating the number-soup D2 killed.
8. Provisional-scoring (flat 7) surprising new members' first three rounds.
9. Side-game money visually adjacent to cup points.
10. Mid-season dropout with no Pro tooling.

**5. Top 10 opportunities**
1. Run the timed QA — every friction target becomes a fact.
2. "Best guess is fine" index copy — 15 minutes, kills quit-point #2.
3. Self-narrating automatic mechanics (the §6 rule) — trust at zero cost.
4. "My next round matters because…" — one client line over shipped math.
5. Recap card as THE artifact (#18) — the growth loop.
6. Quiet-day Home framing ("since you were here…") — thin-feed dignity.
7. Index receipts (which 8 of 20) — pre-empt the trust battleground.
8. Season 1's ending as a designed launch moment (Trophy Room is built;
   the *ceremony* around it isn't).
9. Photos (D10 — already decided, correctly next).
10. The join covenant sentence reused as the brand's fairness promise
    everywhere fear appears.

**6. Features to remove** — §13: H2H format from wizard · M5 Callout ·
M4 threads · projection ladder (stay deferred) · dash-rendering award tiles ·
Ryder entry point soft-hidden at launch.

**7. Features to merge** — Up Next + calendar strip + watch list into one
"coming up" system · You/Tour Card noun unification · league/Ryder toward
the Cup abstraction (freeze divergence now, merge later) · announcements as
pinned board posts (done, keep it that way — no separate channel).

**8. Highest-leverage improvements** — in order: deploy (F1) → timed QA with
humans → PIGL month 1 completed and month-close verified in prod → index
copy fix → self-narration rule → recap card.

**9. What should be built next** — nothing new until the three proofs above
exist. Then: photos (D10), recap-card polish, and the "matters because"
line. That's the whole quarter.

**10. What should be postponed indefinitely** — predictions market · weather
· chemistry · nicknames · live pings/leaderboard · family lineage · clubs/
B2B (§17 trigger stands) · snake/captains draft engines (until a league
asks) · any new game mode · any new container type.

---

*Filed by the UX lane. Mechanics judgments herein are observations for the
Gameplay lane, not changes; identity/monetization observations are for the
Business lane. Nothing in this review alters a level-4 rule.*
