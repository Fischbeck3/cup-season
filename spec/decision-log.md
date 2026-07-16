# Cup Season — Decision Log

Status: STANDING PROTOCOL. Every recommendation to change or remove a mechanic
gets an entry here BEFORE it's built. Entries cite the hierarchy of truth and
name conflicts explicitly — a recommendation that collides with a higher level
is logged as a CONFLICT with a proposed resolution, never silently adopted.

## Hierarchy of truth

1. **Vision** — `product-vision-v1.0.md` (+ founding prospectus as north star)
2. **Product principles** — the five principles, five-question filter, Cup
   Season Test (§ of the vision doc)
3. **Information architecture** — the IA blueprint (four questions;
   Home / Crew / ⊕ / You)
4. **Gameplay mechanics** — `spec-v1.0.md`, `gameplay-modes-working.md`
5. **UI** — the shipped client
6. **Implementation** — schema, migrations, code

Lower levels may not contradict higher ones. Changes at level N require only
level-N authority unless they leak upward.

Entry format: **Current mechanic · Problem observed · Recommendation ·
Principle served · Expected user benefit · Tradeoffs** (+ CONFLICT where one
exists).

---

## Batch 1 — 2026-07-15, from the gameplay-mechanics panel audit

### D1 · PvI as the user-facing currency
- **Current:** round cards and standings surface "PvI +1.4" and band numbers;
  spec §2.1 makes PvI the universal currency.
- **Problem:** the core currency is an acronym no golfer says aloud; the
  no-tutorial success metric fails at the first round card.
- **Recommendation:** PvI stays the engine currency (level 4 unchanged);
  the *display* becomes "beat your number by 1.4" and the bands wear their
  spec §2.2 names (Torched it / Beat your number / Played to it / A little
  loose / Posted anyway). Level-5 change only.
- **Principle:** #2 Low Friction; success metric "understand standings in 10s,
  never need a tutorial."
- **Benefit:** first-session comprehension without teaching an acronym.
- **Tradeoffs:** power users lose at-a-glance precision → mitigated by
  receipts (D5). Copy length on small chips.

### D2 · The number soup on a round
- **Current:** a posted round can surface gross, net, differential, index,
  playing index, PvI, and points — seven figures.
- **Problem:** seven numbers describing one event reads as machinery, not golf.
- **Recommendation:** two numbers survive on the card — gross and points —
  joined by one phrase ("84 · beat your number by 0.6 → 7 pts"). Differential,
  playing index, allowance become **never-shown** terms, visible only inside
  receipts.
- **Principle:** #2 Low Friction; #4 Memory > Statistics.
- **Benefit:** the round reads as a story, not a ledger row.
- **Tradeoffs:** the leaguemate who wants to check the math taps once (D5
  makes that tap always available).

### D3 · Cap/floor machinery surfaced as prose
- **Current:** counting cap (best 4/month) and participation floor (2/month)
  exist as bylaw language; displacement is silent.
- **Problem:** "where did my fifth round go?" + the nervous high-index never
  learns the floor protects them.
- **Recommendation:** a 4-slot fill meter for the month; displaced rounds
  shown grayed with "bumped by your 81 ✓"; join-league copy states verbatim:
  *"You can't hurt your squad by playing badly. Only by not playing."*
- **Principle:** #2; spec design principle 1 ("the floor exists so nobody
  ghosts") — this is the floor doing its intended job *visibly*.
- **Benefit:** kills the casual golfer's fear at the door; displacement
  reframes as upgrade.
- **Tradeoffs:** screen space on standings/You; none structural.

### D4 · Cup Final reset, unforeshadowed
- **Current:** §14.3 Cup Final scores the final 4 weeks fresh; seeds lock at
  ends_on − 27. Nothing in the UI foreshadows the reset.
- **Problem:** the points leader discovers at reset time that the lead
  "vanished" — reads as a rug-pull.
- **Recommendation:** season-long foreshadow ("Season crowns 4 Cup seeds ·
  Cup starts fresh Aug 30") + the leader visibly keeps something (top seed).
  Mechanics unchanged; level-5 only. Rides migration-008/endgame-dial work
  (task #4).
- **Principle:** #5 Feels Alive (anticipation is drama); spec principle 4
  ("argue never").
- **Benefit:** the reset lands as a playoff, not a theft.
- **Tradeoffs:** persistent banner real estate.

### D5 · Receipts exist in schema, not in UI
- **Current:** spec §16 (every number traces to rounds) is true in the
  database; on screen most figures are un-tappable.
- **Problem:** the first "this is rigged" in a group chat has no one-tap
  answer; trust never compounds (pre-mortem cause #3).
- **Recommendation:** every points figure opens the rounds that produced it.
  Gap-closure, not a mechanic change — §16 promoted from schema truth to UI
  truth.
- **Principle:** spec §16; #1 Golf First (fairness is felt).
- **Benefit:** disputes settle in the app instead of returning to the
  spreadsheet, whose real feature was legibility.
- **Tradeoffs:** build cost only; views already exist.

### D6 · Hybrid season format (C)
- **Current:** spec §14 formats A (points race), B (h2h months), C (hybrid:
  points + 15/month to h2h winner); 7c #12 already spawned an edge-case rule
  for C.
- **Problem:** two scoreboards welded together; not explainable in a sentence;
  third-option trap in the wizard.
- **Recommendation:** remove C from the wizard v1 (stays spec'd, dormant).
  Revive when a real league asks.
- **Principle:** #2; five-question filter Q1 ("does this reduce friction?" —
  a format menu is friction).
- **Benefit:** the format choice becomes a real choice instead of a
  comparison-shopping session.
- **Tradeoffs:** a league wanting both textures loses the option at setup;
  acceptable until demanded.

### D7 · Bonus points layer (§2.3)
- **Current:** optional birdie/net-eagle/PB bonuses, off by default.
- **Problem:** widens the sandbag surface the 12-ceiling exists to close;
  adds per-hole verification questions; the moments engine already
  celebrates birdies socially for free.
- **Recommendation:** never surface in the wizard v1 (spec keeps it, off).
- **Principle:** #4 (celebration ≠ points); anti-sandbagging design intent
  of §2.2.
- **Benefit:** one fewer organizer decision; sandbag surface stays closed.
- **Tradeoffs:** casual leagues lose point texture — moments compensate
  without touching the ledger.

### D8 · Allowance dial (100/95/90) and dial exposure generally
- **Current:** spec: presets bundle values, Custom exposes every dial.
- **Problem:** no golfer chooses an allowance % with information; every
  exposed dial is a support ticket wearing a settings icon.
- **Recommendation:** confirm dials live ONLY inside Custom (collapsed);
  presets never mention them. Same rule for Wolf toggles (blind/carries/loss
  cap) and Ryder dials (weighting, MVP cut): default-off AND absent from v1
  surfaces. Build a dial's UI when two leagues ask for it.
- **Principle:** #2; ESPN-fantasy lesson (presets with conviction beat
  configuration).
- **Benefit:** wizard stays one-decision-per-step.
- **Tradeoffs:** the 4% who enjoy dials wait; that is the point.

### D9 · Side-game build order (Wolf before Skins)
- **Current:** gameplay-modes §6: Match Play → Wolf; skins parked on the
  Nassau roadmap line.
- **Problem:** order optimizes for demo-ability (Wolf's turn tracker) over
  familiarity — skins is the most-played money game in amateur golf and is
  nearly free once hole-by-hole + game_ledger exist.
- **Recommendation:** pull skins forward as a checkpoint-3 companion to Wolf
  (same ledger/settlement machinery: carry-over pot on hole wins). Nassau
  stays roadmap.
- **Principle:** #3 Real Golf (the game people actually play); #1.
- **Benefit:** instant familiarity — zero rules teaching for most foursomes.
- **Tradeoffs:** splits ckpt-3 focus; mitigated by shared machinery.

### D10 · Feed texture before new modes (comments + one photo per round)
- **Current:** board reading is real; composing shipped; photos don't exist
  (task #13 pending). Feed is system-post monotone.
- **Problem:** nothing happens between rounds; the feed is a ticker, not a
  clubhouse (pre-mortem cause #4).
- **Recommendation:** one photo per round post + comment affordances rank
  above any new game mode. Pull task #13 forward.
- **Principle:** #4 Memory > Statistics; #5 Feels Alive; vision functional
  requirements already name photos.
- **Benefit:** the "remember when" artifact; between-round opens.
- **Tradeoffs:** one storage build + a moderation surface (small at
  crew scale).

### D11 · Container nouns: league / crew / clubhouse
- **Current:** "crew," "league," "clubhouse," "season," "squad" used
  near-interchangeably in copy.
- **Problem:** five nouns for two ideas (the people; the competition).
- **CONFLICT:** the panel's raw recommendation was "kill crew as a noun" —
  that contradicts the approved IA (level 3), where **Crew is a nav tab**.
  IA wins.
- **Resolution/Recommendation:** assignment, not removal. **Crew = the
  people** (the tab, the social surface). **League = the competition
  container.** "Clubhouse" retires from copy. Ban interchangeable use;
  one sweep through client copy.
- **Principle:** level-3 IA supremacy; #2.
- **Benefit:** each noun means one thing; nav and copy agree.
- **Tradeoffs:** none — copy sweep only.

### D12 · Head-to-head noun set: match / duel / rivalry / Ryder / event
- **Current:** four-plus h2h nouns across docs and UI plans.
- **Recommendation:** user-facing set is **Match** (on-course), **Rivalry**
  (lifetime record, faceted per 7c #18), **Ryder** (the event product).
  "Duel" and "event" become schema/doc words only — a Ryder duel is "your
  match this week." Same rule for the round lifecycle: one noun, three
  states (your round — planned / playing / posted), never
  declared/live/posted as three nouns.
- **Principle:** #2; no-tutorial metric.
- **Benefit:** h2h vocabulary a bar can repeat.
- **Tradeoffs:** docs carry a display-name mapping; trivial.

### D13 · "Attestation" → "Vouch"
- **Current:** schema and spec say attestation; the UI verb is already vouch.
- **Recommendation:** "Vouch" is the only user-facing word, everywhere.
- **Principle:** #2.
- **Benefit/Tradeoffs:** copy consistency; none.

### D14 · Bye grant: Pro-granted → auto-granted
- **Current:** 1 bye per player per season, granted by the Pro (punch list:
  commissioner grant-bye tool).
- **Problem:** floors punish the lapsed and the Pro must adjudicate life
  events; guilt is a churn accelerant (pre-mortem cause #2).
- **CONFLICT (level 4, named):** spec design principle 1 says "the floor
  exists so nobody ghosts" — softening enforcement tugs against it. This is
  a tension, not a contradiction: the bye ALREADY exists in spec; only its
  grant mechanism changes.
- **Resolution/Recommendation:** the season's one bye auto-applies to the
  first floor breach ("Life happens — your July bye kicked in"), with
  welcome-back framing. The Pro can still grant/revoke via the ledger.
  Floors bite from the second breach — the ghost-deterrent survives intact.
- **Principle:** #1 Golf First (the golfer is the product, including the one
  having a bad month); #2.
- **Benefit:** the drifted return to a hand extended, not a fine.
- **Tradeoffs:** strategic bye-hoarding disappears (players can no longer
  save it deliberately) — minor, arguably good.

### D15 · "The Pro" terminology collision — FLAG, no change
- **Current:** decided 2026-07: UI says "the Pro," tier is "Pro Shop."
- **Problem observed:** "the Pro set your index" vs "go Pro" will eventually
  share a screen, and the club professional is a real person users know.
- **Recommendation:** none now — the decision stands (level 5, decided).
  Logged so the collision is *chosen, not discovered* when the Pro Shop tier
  ships. Revisit trigger: first paid-tier screen design.
- **Tradeoffs of inaction:** one future ambiguous screen; acceptable.

### D16 · 3-player Wolf ("pig")
- **Current:** deferred with a ⚑ in gameplay-modes §3.1.
- **Recommendation:** hard-cut from all v1 surfaces (no greyed option, no
  mention). Deferral becomes invisible.
- **Principle:** #2.
- **Tradeoffs:** none until a 3-ball asks; then it's a real request, not a
  broken button.

---

## Batch 3 — 2026-07-16, calendar & tee-sheet connective tissue (tasks #11/#16)

### D17 · The Watch List and "I'm in" (join a friend's declared round)
- **Current:** declared rounds live on the calendar; a league mate's round
  shows as a passive gold dot you must find by tapping its day. The loop
  CLAUDE.md names — "Logan's playing Pebble, get something on the books" — is
  *described* in comments but never *delivered* as a surface, and there is no
  way to act on someone else's plan.
- **Problem observed:** the highest-retention moment in amateur golf (a buddy
  is already going — join them) is buried one tap deep and has no verb. The
  calendar is a passive record, not an active nudge.
- **Recommendation:** a **Watch List** — buddies' and league-mates' rounds in
  the next ~14 days, surfaced atop the Calendar (compact echo in Home's Up
  Next), each with a one-tap **"I'm in"** and **"Put my own up."** "I'm in"
  *declares your own round* on that day/course and auto-tags the host — reusing
  `declare_round`, no new table and no shared-roster schema. The two rounds
  then cluster on the same day, and each golfer's round still posts and scores
  independently (an outing is two rounds, not one shared record).
- **Principle:** #4 the app feels alive (a plan you can act on, not just read);
  #2 Low Friction (join in one tap); #5 Memory > Statistics (the outing becomes
  a shared moment on both boards).
- **Benefit:** converts a friend's plan into your round at the exact moment
  intent is highest; makes the calendar the between-rounds retention loop the
  vision asks for.
- **Tradeoffs:** two rounds per outing rather than one shared roster — chosen
  deliberately: it keeps scheduling profile-scoped and schema-free, and mirrors
  reality (each golfer posts their own card). A true shared tee sheet (one
  roster, one record) is a later call if leagues ask for it.
- **Not a mechanic change (built alongside, no separate entry):** the Plan→Play
  prefill (tee off a declared round with its group + course pre-filled) and the
  `upcomingFromSchedule` field-name fix (`played_on`→`play_on`, split mine from
  watch) are plumbing/bug-fix at level 5–6.

---

*Non-entries (checked, no change and no conflict): the single-player
heartbeat / individual free hook is already approved direction (ESPN model,
2026-07); the translation pass (D1–D3) touches no level-4 rule; Cup Final
mechanics (D4) unchanged pending migration 008's endgame dial.*

*Status notes: D1–D3, D5, D11 shipped v23.153 · D4 (foreshadow + dial)
shipped v23.160 with migration 008 · D9 (skins forward) shipped v23.157 ·
batch-3 #17/#18 shipped v23.158–159 (Ryder) · D6 + D8 shipped v23.161 (wizard
rebuild — Hybrid gone, cap/floor behind a disclosure; D7 bonus-layer was
never in the wizard, so N/A) · D14 (auto-bye) + D16 (3-player Wolf hard-cut)
shipped v23.162 (migration 20260716180000_auto_bye). Open: D10 (photos, next
sprint) · captains-pick + snake draft engines (decision #2's fuller formation
— server-side draft engines unbuilt; wizard shows the built two + roster-fit
guidance, roadmap-honest). **Decision log fully reconciled except the two
noted roadmap items.***
