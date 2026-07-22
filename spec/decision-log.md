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

## Batch 4 — 2026-07-16, the memory layer (spec/memory-layer-v1.md → V1 build)

Backlog lives in the task list as M1–M10. Entries below cover the checkpoints
that change or add a mechanic; M1 (voice pass), M6 (ceremony presentation),
M8 (recap-card render), and M10 (identity presentation) are level-5/6 and are
logged as non-entries at the batch foot. (Batch follows Batch 3; the memory-
layer entries are renumbered D18–D23 to clear the calendar lane's D17 — the
M1–M3 commit messages predate the renumber and cite the old D17–D18.)

### D18 · The post-round beat: the poster hears it first (M2)
- **Current:** posting a round fans straight to the board; the poster learns
  what their round *meant* (PB, streak, rivalry flip, points) the same way
  everyone else does — by reading the feed.
- **Problem:** the emotional peak of the product is spent broadcasting, not
  celebrating. Your own win reaches you second-hand.
- **Recommendation:** a private post-round epilogue sheet, shown to the poster
  before they land back on the board: new PB / achievement / streak /
  rivalry-record change ("You're now 4–3 up on Jake, all-time") / points
  context. One gather RPC (`round_epilogue`). Also: a round that flips a
  squad standing gets comeback/collapse framing in the existing lead-change
  moment (create-or-replace, new migration). If the round's foursome was
  tagged, the sheet offers a one-tap partner shoutout that posts a board line.
- **Principle:** #4 Memory > Statistics; #5 Feels Alive.
- **Benefit:** the win is yours first; the board gets drama, not just data.
- **Tradeoffs:** one more surface in the post flow — must not break the
  60-second-post friction target (sheet is dismissible, never blocking).

### D19 · Rivalries can be christened (M3)
- **Current:** rivalries are a computed facet (`my_rivalries()`,
  `rivalry_weeks()`) — real records, no identity. Every rivalry is anonymous.
- **Problem:** "memory > statistics" — a lifetime record with no name is a
  statistic. Friend groups already name these things ("The Grudge").
- **Recommendation:** a `rivalry_names` table keyed on the unordered profile
  pair (league-agnostic — a rivalry is between people, not lenses). Either
  rival can name or rename it (must have actual head-to-head history); the
  name rides everywhere the rivalry surfaces — facet, board lines, epilogue,
  pre-game card. Pre-game card ships in the same checkpoint: when a declared
  round's tagged foursome contains an opponent with history, the board/
  countdown surfaces the all-time record before the round.
- **⚑ Resolved (build):** misuse valve — EITHER rival can rename or CLEAR the
  name (name = '' deletes the row). That is the valve: if one side names it
  something ugly, the other renames it. Pro-side clear deferred until real
  abuse appears (a global block "only if it ever actually happens").
- **SPLIT (build):** the pre-game head-to-head card (#7) moved to **M4** — it
  wants the countdown surface M4 builds ("the record, before the round" has no
  home until the countdown exists). M3 shipped the naming system alone; the
  record already rides the M2 epilogue and the rivalries facet.
- **Principle:** #4; #5; D12 (rivalry is the lifetime-record noun — naming
  deepens it, no new noun introduced).
- **Benefit:** the rivalry becomes a possession; the pre-game card gives
  every shared tee sheet stakes.
- **Tradeoffs:** rename ping-pong between rivals is possible — acceptable at
  crew scale (it IS banter); revisit only on real abuse.
- **Shipped:** M3 at v23.165 (migration 20260716210000_named_rivalries).

### D20 · The trash-talk thread anchors to the round, then archives (M4)
- **Current:** chat is one league-wide stream on the board; an upcoming round
  (declared, tee time set, foursome tagged) has no conversational home.
- **Problem:** anticipation is the most under-built phase; pre-round talk is
  the cheapest real anticipation there is, and today it dissolves into the
  general stream and is lost to the round it was about.
- **Recommendation:** `posts` gains a nullable `scheduled_round_id`; the
  countdown card opens that round's thread; when the round posts, the thread
  archives into the round's story (the round card links its pre-game talk).
  Still `kind='chat'` — no new post kind, no new realtime surface.
- **Principle:** #5 Feels Alive; guardrail — the thread serves the round's
  story and then closes; it is not a standing sub-feed (no generic social
  features).
- **Benefit:** the board reads like a locker room before a round and a
  scrapbook after; the talk becomes part of the memory.
- **Tradeoffs:** threads fragment chat attention slightly; mitigated because
  thread posts can still render inline on the board (anchored, not hidden).

### D21 · The Callout — a declared number settles itself (M5)
- **Current:** no pre-round commitment mechanic exists. The Ryder has
  number-to-beat chips (computed, not declared); regular rounds have nothing.
- **Problem:** stakes before a round currently require a side game; there is
  no lightweight "I'm calling my shot" primitive.
- **Recommendation:** from the countdown card, a player can publicly commit —
  a number to beat, or a straight-up callout of a tagged opponent. It posts
  to the thread; when the round(s) post, it auto-settles as its own row plus
  a board settlement line. Rounds are never mutated (§16); a callout is
  bravado with a receipt, worth zero points — it never touches scoring.
- **⚑ Open (need the Pro's call before build):** (a) settle basis — gross or
  net? recommendation: the named band's own terms, i.e. "beat your number" =
  net vs your number, "beat Jake" = head-to-head on net; (b) tie — push, no
  line posted or a "push" line? recommendation: a push line (the receipt
  exists either way); (c) no-post by settle date — quietly expires or posts
  "never showed"? recommendation: quietly expires — shame mechanics violate
  the D23 nudge policy's spirit.
- **Principle:** #5; #3 (competition with receipts); §16 show-your-work.
- **CONFLICT check (level 4):** none — no points, no handicap interaction; it
  is social machinery wearing competition clothes. Named here so that stays
  true: if a future version ever wants callouts to score, that is a NEW
  level-4 decision, not an extension of this one.
- **Benefit:** every casual round can carry stakes a bar can repeat.
- **Tradeoffs:** a settle engine (small) + one more pre-round affordance;
  gated to rounds with a declared schedule so quick-posts stay 60 seconds.

### D22 · Mark This — the golfer's memory outranks the machine's (M7)
- **Current:** `round_moments()` picks ONE headline per round by fixed
  priority: milestone barrier > personal best > iron-man streak. Entirely
  computed; the golfer has no say in what a round is remembered for.
- **Problem:** the machine remembers scores; people remember *moments* — the
  ace, the bet-winning putt. Today the system cannot know hole 14 mattered.
- **CONFLICT (level 4, named):** the one-headline-per-round rule ("a round is
  one story, not three") is deliberate and stays. Adding a user mark risks
  either two headlines or silently discarding one.
- **Resolution/Recommendation:** the rule survives intact — the mark joins
  the priority chain at the TOP: mark > barrier > PB > streak. One tap in the
  stepper marks at most one hole per round; a marked round's headline is the
  golfer's moment (computed milestones still ride the receipts/achievements
  path, so a PB set on a marked round still pins as an achievement — the
  achievement lifespan is unaffected, only the board headline yields).
- **Principle:** #4 Memory > Statistics (this is the purest expression of it
  in the product); #2 (one tap, zero new screens, 60-second post preserved).
- **Benefit:** the round is remembered for what the golfer felt, not what the
  math noticed.
- **Tradeoffs:** a marked mediocre round can bury a PB headline — accepted
  by design (the golfer chose); receipts still show everything.

### D23 · The nudge policy — every nudge names its emotion (M9)
- **Current:** push is curated by kind + per-user mutes; there are no
  re-engagement nudges of any kind. Nothing resurfaces.
- **Problem:** days-later resurfacing is the retention loop, and it is the
  easiest place in the product to slide into engagement-bait.
- **Recommendation (the policy, codified):** a nudge must name one of the
  eight emotions (pride, nostalgia, anticipation, belonging, rivalry, joy,
  reflection, achievement) or it doesn't render. Each nudge fires ONCE per
  triggering condition — no repeat-nagging, no shame framing, no badge
  counts. V1 nudges are HOME-SURFACED chips only, never push: (a)
  "You and Jake haven't played together in 47 days" (nostalgia) — tap starts
  a declare-round with them pre-tagged; (b) "Your iron-man streak (7 weeks)
  needs a round by Sunday" (anticipation) — one reminder, streak already
  live in `round_moments()`. Push escalation is a Year-2 decision with its
  own entry.
- **Principle:** #1 Golf First (a nudge is a reason to play, not a reason to
  tap); #4; the memory-layer guardrails (level 2).
- **Benefit:** retention through relationships and traditions, with dignity.
- **Tradeoffs:** deliberately weaker short-term re-engagement than push —
  accepted; the point is the five-year relationship.

---

## Batch 5 — 2026-07-16, the events engine's competitive half (task #5)

### D24 · Season clinch & scenario math (the magic number)
- **Current:** clinch/"needs" math exists for the Ryder
  (`FIRST TO 9½ · TEAM A NEEDS 3`), but the **season/Cup race has none** —
  standings show points, never what they *mean* for the endgame. The Social
  lane owns the emotional half of the events engine (moments, voice,
  rivalries); this is the missing **competitive projection** half.
- **Problem observed:** the tension of the final weeks is invisible. A points
  leader can't see they've locked a Cup seed; a chaser can't see they're
  eliminated or exactly what they need. The endgame's drama is unstated, and
  spec §16 ("every number shows its work") stops at the current total — it
  never projects.
- **Recommendation:** a `season_scenarios(season)` engine over
  `v_squad_standings` / `v_individual_standings` that computes, per contender:
  **magic number** (points to guarantee a seed/crown), **clinched**,
  **eliminated**, and the **cut line** — feeding one storytelling line the
  standings/Home render. Seeds follow the endgame dial (008): `cup_final` →
  top 2 seed (2-squad → both in, so the race is the **#1 seed / +10**), solo →
  top 2; `points_table` → the leader (K=1). Seed race ends at `ends_on − 27`
  (Cup Final) else `ends_on`; once `status = cup_final`, seeds are locked and
  the engine reports the locked seeds instead.
- **The honesty rule (the load-bearing design choice):** clinch/elimination
  are declared **only when true under a deliberately GENEROUS remaining-points
  ceiling** — `roster × months-left × counting_cap × 12` (the top band; bonuses
  are off per D7, and a floor credit never exceeds cap×12, so this is a valid
  upper bound). Erring generous means the engine **never** falsely says
  "clinched" or "eliminated"; borderline stays "in the hunt." A wrong certainty
  would be a §16/trust violation; a cautious one is just quiet.
- **Principle:** spec §16 (show your work — now for the *endgame*); #5 Feels
  Alive (the last weeks acquire stakes); #1 Golf First (fairness is felt —
  no false math).
- **Benefit:** "your Sunday round matters because…" becomes literal; the race
  reads as a race, and the numbers are trustworthy because they're conservative.
- **Tradeoffs:** with an unlimited counting cap the ceiling is huge, so nothing
  clinches until the window closes — honest (unlimited posting = unlimited
  swing), if less dramatic; most leagues set a cap. The generous bound also
  means a mathematically-decided-but-not-provably-so race shows "in the hunt" a
  little longer than a human would call it — accepted, per the honesty rule.
- **Boundary (no collision):** the Social lane renders standings storytelling;
  this produces the *numbers*. New engine + one new client line in a new
  element — no edits to their moment/feed/rivalry surfaces.

---

*Batch-4 non-entries (checked, no mechanic change): M1 storyteller/settlement
voice (level-5 copy; the mechanic-visible rule "mixed-case bodies pass
`easeCaps` untouched" is implementation, unchanged) · M6 roster-reveal +
kickoff ritual (presentation of events that already post) · M8 recap card
(render of existing facts; D2's no-jargon rule applies to the card) · M10
living identity card (presentation; identity FACTS it surfaces are all
already earned objects — any new fact type would need its own entry).*

---

## Batch 6 — 2026-07-16, the board reacts back (Social lane)

### D25 · Reactions & comments become real, with a crew vocabulary
*(assigned **D25** at merge — reconciled with the memory batch's numbering;
the lane had numbered adjacent to D20/D21 independently.)*
- **Current:** the board's 🔥 kudos and 💬 comments are **theater** — a local
  counter and an in-memory array (`f.kud++`, `feed[fi].cm.push`), gone on
  reload. The backend has always been there: `post_kudos` (PK `post_id,
  member_id`) and `post_comments` ship in the baseline with RLS
  (`kudos_all`, `comments_add`/`comments_read`) and both sit in the
  `supabase_realtime` publication. The client simply never wrote to them.
- **Problem:** the two pillars this lane owns are "feels alive" and "memory >
  statistics," and the single most-touched surface — reacting to a mate's
  round — persists nothing and says nothing back. A reaction is also
  one-note: an undifferentiated cheer can't carry a golf crew's actual voice,
  where a suspicious 79 earns a 🦅 and a 🚨 in the same breath.
- **Recommendation:** wire the existing spine, and give a reaction an **emoji
  vocabulary** — six curated: 🔥 heater · 🦅 the eagle · ⛳ dialed · 🧊 ice ·
  🐍 snake · 🚨 sandbagger. One row per `(post_id, member_id, emoji)` (PK
  repointed to include emoji, Slack-style stacking), so a card collects a pile
  of distinct reactions. Reactions ride **round story cards and chat** in both
  feed views; comments thread on **round cards only** (a per-line reply thread
  on chat is noise). Counts show *who* reacted (chip title) — §16, shows its
  work. Demo stays ephemeral (the diorama never writes). Realtime: a light
  social-only refresh on `post_kudos`/`post_comments` change, not a standings
  refetch.
- **Principle:** #5 Feels Alive (the board answers back); memory > statistics
  (the reactions + talk become part of the round's record); §16 (who cheered
  is legible).
- **CONFLICT check (level 4 — vs D20):** D20's guardrail reads "not a standing
  sub-feed… no generic social features." Named and resolved: the reaction/
  comment tables **predate** D20 — they were always in the intended model, not
  a new generic-social bolt-on. Reactions/comments **anchor to a specific
  post** (a round or a chat line) and travel with it; they serve the exact
  locker-room→scrapbook arc D20 wants, rather than opening a rival feed. The
  guardrail still holds: no standing sub-feed, no follows, no DMs — reactions
  live *on the memory*, not beside it.
- **Benefit:** the highest-frequency social act finally persists and speaks the
  crew's language; a round card becomes a small, permanent scene.
- **Tradeoffs:** (a) one migration repoints the `post_kudos` PK — safe (the
  table has never had a client writer, so it's empty in prod); deploy-skew
  falls back to a plain 🔥 kudos on a missing-column error so a live tap never
  breaks. (b) A social realtime refresh mid-typing collapses an open comment
  thread — same class of behavior the existing chat realtime already has;
  flagged as a follow-on (preserve open-thread + in-progress input across
  social re-renders), not fixed here. (c) The emoji palette is fixed/curated,
  not user-defined — deliberate; an open reaction picker is a generic-social
  feature D20 rules out.

*Ships:* migration `20260716230000_post_reactions.sql` (needs a `db push`) +
client (`index.html`). Verified in the demo diorama: add/toggle reactions,
post comments, both feed views, clean console. Real-path persistence/realtime
follows the established `sendChatFrom` + RLS pattern (untestable in-sandbox
without an authed league).

---

*Non-entries (checked, no change and no conflict): the single-player
heartbeat / individual free hook is already approved direction (ESPN model,
2026-07); the translation pass (D1–D3) touches no level-4 rule; Cup Final
mechanics (D4) unchanged pending migration 008's endgame dial.*

## Batch 7 — 2026-07-16, the season race gets a face (gameplay lane)

### D26 · The Climb — a you-centered cup-line ladder (replaces the race chart)
*(assigned **D26** at merge.)*
- **Current:** the season race renders as a multi-line cumulative-points chart
  (`renderChart`, `buildRealSeries`, `SQHEX` — a **4-color** palette). It is
  the most statistical object in the app, it **duplicates** what the standings
  table, the story line, and the D24 clinch line already say, it becomes
  unreadable spaghetti past ~4 competitors, and it is **broken for solo**:
  a squad-less player falls through `memCi`'s fallback (`return 1`), so every
  individual draws in the same orange — the "solo point graph is wrong" report.
- **Problem observed:** a points-over-time line graph fails the Cup Season Test
  ("would golfers miss it because it made their golf life richer, or because it
  was another stat they occasionally glanced at?") — it lands on the wrong side.
  It answers "who has more points" (the table already does) but never the
  question a golfer actually feels: *where am I in this race, who's right above
  me, and how far to the cup line.* And its color model assumes ≤4 squads, so
  it cannot represent a solo field at all.
- **Recommendation:** replace it with **The Climb** — a focused vertical ladder
  centered on the viewer. Rungs show **your row**, the **rung above** (the
  player/squad to catch), the **rung below** (who's chasing you), the **leader**,
  and the **cup line** drawn across the ladder — with **points-back** labels on
  each gap ("6 back of Jake for the last cup spot · Dana +4 behind you"). It
  renders a **window** (you ± neighbors + cutline + leader), never all N, so it
  is legible at 4 players or 20 and needs no per-competitor palette. Gap and
  cutline numbers read from `season_scenarios` (D24) so they stay honest and
  match the clinch line exactly. Squad leagues get the same ladder (squad rungs).
  The cutline follows the endgame dial (008): `cup_final` → below seed #2 (2-squad
  → the #1-seed / +10 line); solo → below #2; `points_table` → below #1.
- **Optional texture (keeps the season arc without the spaghetti):** a single
  **self-trajectory sparkline** — the viewer's own weekly points from
  `seasonHistory`, one line in one color — tucked beside their rung. Preserves
  "am I climbing?" for the competitive/trip personas with zero palette collision.
- **Principle:** #4 Memory > Statistics (a target and a rivalry, not a stat);
  #5 Feels Alive (the race has a face — the person one rung up); §16 (every gap
  traces to D24's conservative math, which traces to rounds); #2 Low Friction
  (one glance answers "where do I stand").
- **Benefit:** the season race becomes personal and emotionally legible; the
  solo color bug is **deleted at the root** rather than patched; squads gain a
  clearer read too. One fewer redundant, generic surface.
- **Tradeoffs:** loses the whole-field arc a few analytically-minded users
  liked — mitigated by the optional self-sparkline. A **spectator** with no
  membership (or a pre-first-round league) has no "you" to anchor on → fallback:
  show the top of the ladder + the cutline, no self-anchor. The ladder is a
  *snapshot*, not history; history lives in the sparkline and the receipts.
- **CONFLICT check:** none. Removing a redundant statistical surface *serves*
  the IA and the memory-layer guardrails rather than contradicting them.
- **Boundary (no collision):** the **data + framing** (what to show, the gap
  math, the cutline rule) is this lane; the **finished visual polish** is UX's.
  This ships a working, legible first version reading D24's output — no edits to
  Social's feed/moment/rivalry surfaces.

---

## Batch 8 — 2026-07-17, the quiet day (Social lane)

### D27 · Home never opens on nothing (the thin-feed problem)
*(assigned **D27** at merge.)*
- **Current:** Home's "Around your circle" renders a bare reverse-chron list of
  the last 21 days of circle rounds + league posts (`renderHomeFeed`), with an
  empty state only when there is literally nothing.
- **Problem:** the design review (2026-07-16 §8.1) names this the **#1
  unacknowledged risk in the stack**, and it's arithmetic, not polish: an
  8-person league posting weekly generates ~2–3 board items a *week*, so most
  opens reveal **nothing new**. Principle 5 promises "opening Cup Season should
  reveal something new." Today the product quietly breaks that promise ~4 days
  out of 7, and no amount of moment-engine work changes the volume.
- **Recommendation:** a **quiet-day frame** above the feed (`renderHomeDigest`).
  A per-profile seen-mark (localStorage, read ONCE per load so a re-render can't
  erase the digest you're reading) splits two cases: (a) **something changed** →
  lead with what ("Since you were here: 3 rounds, a personal best from Diego,
  and Rosa broke 80"); (b) **genuinely quiet** → resurface the best recent thing
  instead of a dead list ("Quiet since your last visit · Today — Diego set a
  personal best"). Ranking for (b): milestone (PR > sub-80 > first round) beats
  a good score beats a recent one, inside a 14-day window. First visit shows no
  digest — the feed itself is the reveal.
- **Principle:** #5 Feels Alive — **the rule this encodes: an open never
  reveals nothing.** If there's no new content, curate rather than fabricate.
- **CONFLICT check:** none, and one guardrail explicitly honored. The
  memory-layer's anti-optimization stance (and D23's nudge policy) forbid
  manufacturing engagement. This does **not** invent content, notify, or nag —
  it re-frames facts the user already had access to, in-app, on a surface they
  chose to open. The review's own retention guidance stands: natural cadence is
  **2–4×/week, not daily**; chasing daily opens would violate the guardrails,
  so this deliberately makes a quiet day read as *calm*, not as failure.
- **Benefit:** 3 items/week feels curated instead of dead; the quiet day gets a
  reason to exist rather than punishing the opener with an empty screen.
- **Tradeoffs:** (a) the seen-mark is per device (localStorage), so the digest
  is per-device, not per-account — acceptable for V1; a server-side last_seen is
  the upgrade path. (b) A highlight can repeat across consecutive quiet days —
  accepted; the best thing that happened is still the best thing. (c) Adds one
  more block above the feed on Home's already-long tree.
- **Boundary (no collision):** this is Social's retention loop (§8 Social &
  memory), rendering into a new `#homeDigest` slot; it reads `home_feed`/
  `homePosts` and touches no UX/onboarding copy, no Gameplay rule, and none of
  the Climb/standings surfaces.

### D28 · Reactions reach Home's circle feed (through the shared-league post)
*(assigned **D28** at merge.)*
- **Current:** reactions (D25) live on the board's two views only. Home's
  "Around your circle" — the IA's P1 one-feed and the surface most opens land
  on — renders circle rounds with no social affordance at all.
- **Problem:** the highest-traffic surface is the one place you can't cheer a
  round. And reactions are thin-feed fuel (board activity that requires nobody
  to play golf) — but only if they live where the opens happen.
- **The fork this entry decides:** Home is profile-first and cross-league
  (`home_feed` = friends ∪ league-mates ∪ event-mates), while a reaction is
  league-scoped (`post_kudos` → `posts` → league; a round fans into one post
  PER league via `round_to_board()`). So "react on Home" must pick a board.
  Options weighed: (A) react through a shared-league post, deterministically
  chosen; (C) new profile-scoped `round_kudos` so reactions belong to the round
  itself. **Decision: A.** C is architecturally purer (every circle row becomes
  reactable, including friend-only connections) but costs a migration, circle-
  visibility RLS, and a two-source merge on every board card — built when a
  real user hits the gap (D8's rule), i.e. tries to react to a friend-only
  round and can't.
- **The deterministic-league rule (mechanic-visible, hence logged):** when the
  viewer shares several leagues with the poster, the reaction lands on the
  **currently-open league's** board if it is one of them, else the board whose
  round-post is **oldest**. One tap = one row, always; a reaction never fans.
  Rows with no shared-league post (friend-only circle members) show **no
  reaction strip** — an affordance that would fail is worse than none.
- **Write-path correctness:** reacting from Home into a league that is not the
  currently-open one must send the viewer's member id **in that league**
  (RLS `kudos_all` enforces `member_id = my_member_id(league)`), resolved via
  memberships — never `CS.member` blindly.
- **Principle:** #5 Feels Alive (the open surface answers back); §16 (who
  reacted stays legible on Home too).
- **Benefit:** the tap happens where the eyes are; board cards inherit the
  count because it IS the board's row underneath.
- **Tradeoffs:** (a) multi-league overlap lands the cheer on one board, not
  all — honest, minor; (b) friend-only rows stay inert until/unless C is ever
  built; (c) comments stay a board-only thing (Home rows are too dense for
  threads — same split as chat).

### D29 · The digest mentions what landed on YOUR rounds ("Ed 🔥'd your 84")
*(assigned **D29** at merge; extends the quiet-day-frame and
option-A entries above.)*
- **Current:** the digest counts new rounds and league notes; reactions and
  comments happen silently — you find them only by scrolling to your own card.
- **Problem:** attention on your golf is the single cheapest "something new"
  the thin-feed arithmetic allows — it requires nobody to play. A 🔥 at 11pm
  is news at 7am, and today the 7am open doesn't say it.
- **Recommendation:** reactions + comments on **your** rounds since the
  seen-mark join the digest sentence ("…and Ed 🔥'd your 84"; several →
  "and 2 more chimed in on your rounds"). Crucially, a mention can **rescue a
  quiet day**: no new rounds but a fresh reaction still opens "Since you were
  here" instead of the fallback highlight. Your own taps are never news.
  Requires `post_kudos.created_at` (new migration `20260717010000` — the table
  had no time dimension; "since" was unanswerable). Skew rule honored the
  honest way: rows with no timestamp in the payload are *skipped*, never
  guessed at.
- **Principle:** #5 (the open answers back with what happened *to you*);
  D23's spirit intact — this is in-app framing of real facts, not a nudge,
  not a notification, nothing manufactured.
- **Tradeoffs:** pre-migration reaction rows get stamped at migration time, so
  each may be mentioned once as slightly newer than it was, then ages out —
  accepted (days old, low stakes). Demo seeds carry no timestamps, so in the
  diorama mentions ride only alongside other news and the demo's quiet day
  stays demonstrably quiet.

### D30 · The Round Recap Card — the peak becomes a shareable artifact (#18)
*(assigned **D30** at merge.)*
- **Current:** the post-round peak is private (D18's epilogue sheet: band,
  points, milestones, rivalry lines — poster hears it first) and it stays in
  the app. Shareable artifacts exist only for live-round games (settlement
  cards) and guests (claim links). The ordinary posted round — the app's
  commonest event — produces nothing you can put in the group chat.
- **Problem:** memory-layer #18 names this the artifact of the peak and **the
  #1 growth loop** (design review §8 concurs: "the settlement card and claim
  link are the right artifacts"). Pride is the emotion; a proud golfer with
  nothing to post shares nothing.
- **The fork, decided:** the artifact is an **image** (canvas-rendered PNG,
  branded dark/gold, shared via the native share sheet on mobile; download +
  caption-to-clipboard on desktop). Weighed against a tokened public round
  page with OG unfurl (stronger click-through funnel, but real server
  machinery — public read RPC + per-round OG on a SPA), which is Growth-lane
  work that can later reuse this same card design. The printed `cupseason.app`
  is the funnel for now; claim links remain the clickable path.
- **Placement:** a "Share the card" action on the epilogue sheet — the moment
  pride peaks. NOT on the live-round finish recap yet: `finish_live_round`
  returns no per-player pvi, so a card from there would lack the band phrase;
  extending that RPC is a named follow-on, not smuggled scope. Retrieval-later
  (share any past round) is a cheap follow-on once the renderer exists.
- **Card content under D2's law:** gross (the hero) + the named band phrase +
  course/date/points + at most one milestone badge + marker emblem + wordmark.
  No differential, no index, no jargon — the receipts stay in the app.
- **Principle:** #4 Memory > Statistics (the round becomes a keepsake); Pride
  (memory-layer's named emotion); growth = shareable artifacts,
  foursome-by-foursome, no paid acquisition (monetization canon).
- **Benefit:** every posted round can end with a thing worth showing off; the
  group chat outside the app sees the brand weekly.
- **Tradeoffs:** (a) no click-through from an image — accepted, Growth lane
  owns the link-unfurl upgrade; (b) canvas text rendering varies slightly by
  platform fonts (Charter → Georgia fallback) — accepted, it's a keepsake not
  a spec sheet; (c) a no-content epilogue (rare: no pvi, nothing earned)
  shows no share button — the card needs its hero number.

### Correction to D25 — the reaction skew-fallback silently wrote 🔥
Not a mechanic change; logged because it corrupted a shipped mechanic's intent.
D25's client carried a deploy-skew guard that, on a column/schema error,
retried the `post_kudos` insert **without** the emoji — and the column's
`default '🔥'` then stamped fire. So a 🦅 tap persisted as a 🔥 (reported from
the live board). The pre-migration window it guarded is over
(`20260716230000` is live; PostgREST serves the column — verified against the
live API). **Removed**: a reaction now saves as chosen or fails loudly, never
becomes a *different* reaction. Standing lesson: a skew guard may degrade
loudly, never silently substitute data. Also: the `☺ react` pill is now a
plain `+` (the picker hangs off it; nothing in the affordance should read as a
reaction itself). Possible residue: rows written while the fallback fired are
indistinguishable from genuine 🔥 — see the handoff diagnostic.

---

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

## Batch 8 — 2026-07-17, the Climb gets its finish (UX lane)

### D31 · The Climb's visual finish — presence, voice, motion, and real semantics
*(assigned **D31** at merge. Level 5 (UI) on top of
D26's level-4 mechanic; no gameplay change. Drafted before build, per protocol.)*
- **Current:** D26's ladder is live and honest — window logic, `season_scenarios`
  gaps, cutline, spectator fallback all work — but visually it is a table with
  one gold-bordered row. Every rung has identical padding in a uniform 3px
  stack; the viewer's rung differs only by border/name color. Gaps render as a
  right-aligned mono column (`+6` / `-4`) with no names attached. The
  "··· N more ···" ellipsis is a 1px-padded row, so 2 hidden players and 14
  hidden players look the same. Rank changes rebuild `innerHTML` wholesale — no
  motion. The container is `role="img"` with one static `aria-label`, so a
  screen reader hears the ladder's name and none of its content. The
  self-sparkline strokes `SQHEX[t.ci]` — the very palette D26 exists to escape.
- **Problem observed:** D26 promised a race with a face ("6 back of Jake for
  the last cup spot · Dana +4 behind you") and specified spacing rhythm,
  gap-label framing, and motion on rank change as the unfinished polish. As
  built, the ladder answers "where do I rank" (orienting) but not "who do I
  catch" (rivalry) — the emotional register D26 chose. Bare signed numbers are
  a stat, not a stake (#4). Silence for screen-reader users is an access bug,
  not a style choice. And a passed rival teleports instead of falling — the one
  moment the ladder exists for goes unfelt (#5).
- **Recommendation (five moves, one pass):**
  1. **Spacing rhythm — the viewer has weight.** The `.me` rung gets taller
     padding and a slightly larger name; the rungs directly above/below tuck
     close so they read as *adjacent*; the leader stands apart. The ellipsis
     divider scales its vertical presence with the count it hides, so distance
     looks like distance.
  2. **Gap voice — names on the two rungs that matter.** The rung above the
     viewer carries catch-framing ("6 back of Jake"); the rung below carries
     chase-framing ("Dana +4 behind you"); when the rung above is also the
     cup-line boundary, the label absorbs the stake ("…for the last cup spot").
     All other rungs keep the bare mono number. Numbers are D24's, verbatim —
     **no recomputation, no rounding**; this is framing only.
  3. **Motion on rank change.** Route the render through the existing
     `flipRows` FLIP helper (proven on the standings table), keyed by rung id,
     `var(--roll)` timing, `prefers-reduced-motion` honored. A rung entering or
     leaving the window fades (~200ms) rather than popping — FLIP can't express
     enter/leave, and a hard cut on the "you passed them" beat wastes the
     moment.
  4. **Real semantics, not a picture.** Replace `role="img"` with a list
     (`<ol>`/`role="list"`) whose rungs read naturally: "3rd — Jake, 41 points,
     6 ahead of you." The cutline becomes a labeled separator. Deletes the
     access bug; costs nothing visually.
  5. **Sparkline goes gold.** The self-trajectory strokes `var(--gold)` (the
     viewer's color everywhere else in the ladder) instead of `SQHEX[t.ci]`.
     One viewer, one line, one color — the squad-palette dependency D26
     deprecated exits the component entirely.
- **Principle:** #4 Memory > Statistics (a name and a stake, not a signed
  integer); #5 Feels Alive (overtakes are *seen*); #2 Low Friction (the two
  rungs you act on are the two that speak); §16 unchanged (every number still
  taps back to D24's math). Access: standings legible to every golfer is the
  10-second-standings success metric applied honestly.
- **Benefit:** the ladder finally reads in D26's chosen register — a climb with
  you on it — at zero change to the underlying math or data flow; screen-reader
  users get the standings for the first time; the last trace of the retired
  squad palette leaves the component.
- **Tradeoffs:** (a) name-bearing gap labels are longer than bare numbers —
  small-screen truncation must degrade to the number, never clip the name
  mid-word. (b) Enter/leave fades add a second motion primitive beside FLIP;
  kept subtle and reduced-motion-gated. (c) Catch/chase voice heats up the
  neighbor relationship by design — it stays descriptive (states the gap, names
  the person, never "go get them"); anything push-shaped is D23's fence
  (Social), not this surface.
- **CONFLICT check:** none. Level 5 executing D26's explicit handoff; the
  mechanic, gap math, cutline rule, and window logic are untouched. The voice
  guideline (D1–D3 plain language, named bands) is served, not bent.
- **Boundary:** in-app render only — no nudges, no feed/moment surfaces, no
  schema, no migration. Pure client (`index.html`); needs a `git push` only.
- **Build notes (found while building, same pass):** (a) the demo diorama
  rendered the *spectator* fallback — demo mode never set a viewer, so the
  marketing surface couldn't demo the you-centered ladder; it now anchors
  DEMO_ME's squad (demo coherence, not a mechanic change — the real spectator
  fallback is untouched). (b) Demo teams carry no `id`, so FLIP keys fall back
  to the name. (c) A *trailing* hidden player vanished silently (the ellipsis
  only drew between shown rungs) — the window now ends with "··· N more ···"
  when the field continues below it.

---

### D32 · Front-and-back becomes the default post; hole-by-hole is the opt-in card
*(Gameplay/UX · amends decision #5, which made the hole-by-hole grid the default.)*
- **Current:** the quick-post card defaults to the par-prefilled **hole-by-hole
  grid** (`state.post.mode='holes'`), eighteen ±steppers a card; "Just the total"
  (two boxes, Front 9 gross + Back 9 gross) is the flagged escape hatch, badged
  "Fastest way in."
- **Problem observed:** entering every hole is friction the number does not need.
  The handicap is computed from the **gross total only** — `differential =
  (gross − rating) × 113 ÷ slope` (score_round, §2.1); **nothing reads
  `round_holes`**, and there is no net-double-bogey / ESC capping. So the
  hole-by-hole grid and a front/back total produce the **identical index**. The
  grid buys the per-hole card (storytelling / the §16 receipt), not accuracy —
  yet it is what every poster pays by default. Fails principle #2 (Low Friction,
  the 60-second post).
- **Recommendation:** make **front-and-back total the default** entry mode
  (`state.post.mode='total'`), reframed as the front door — how golfers already
  keep score ("41 out, 43 in"), not a lesser shortcut. Keep **hole-by-hole as
  the opt-in "full card"** for anyone who wants the per-hole receipt; it still
  writes `round_holes` exactly as before. No capability is removed — the diligent
  still get their card, the quick-poster gets two boxes.
- **Principle:** #2 Low Friction (fewer taps to post); #4 Memory > Statistics
  (front/back is how the round is remembered); §16 unaffected — the total still
  shows its work (gross → differential → band), and the per-hole card remains
  available for those who want the finer trace.
- **Benefit:** the common path is two numbers; the handicap is unchanged; the
  full card is one tap away for the golfer who wants it.
- **Tradeoffs:** most rounds will no longer carry a per-hole `round_holes` card,
  so the hole-by-hole storytelling surface (birdie/par colouring, the receipt's
  finer trace) appears only on opted-in rounds. Accepted: it was always
  decoration on the number, never part of it.
- **Deliberately deferred:** persisting the F9/B9 **split** as columns (for
  "41/43" texture in the record) is a migration; not built now. The split is
  captured at entry and summed to gross — the record stores gross, as today.
- **CONFLICT check:** none. Amends a UI-default decision (#5); the scoring
  mechanic and the hierarchy above it are untouched.

---

### D33 · Pilot instrumentation — the QA gates become passive funnels
*(Ops/QA, not a competition mechanic — logged for the record because it adds a
table golfers write to and reshapes how task #14 runs.)*
- **Current:** the pre-launch QA plan is a stopwatch walkthrough with fresh
  alias emails; zero instrumentation exists — the 60-second post is a stated
  pass/fail gate we cannot measure.
- **Problem observed:** the pilot puts real golfers on the app this week. A
  supervised walkthrough measures one tester once; the pilot measures the whole
  cohort continuously — but only if the measurements are captured.
- **Recommendation:** (1) a skinny `client_events` breadcrumb table — four
  events (`post_open`, `post_submit`, `post_mode_switch`,
  `post_even_par_confirmed`), insert-only for the golfer, unreadable through
  the API; (2) `v_pilot_gates` + `v_post_timings`, operator-only views that
  compute gates 1–3 from existing rows + breadcrumbs; (3) gates 4–5 stay
  human (ride-alongs + `pilot_feedback`). Pass thresholds become cohort
  medians. No third-party analytics vendor.
- **Privacy stance:** breadcrumbs carry timings and mode choices, never
  scores-by-hole or free text; the golfer can only insert their own; views
  joining `auth.users` are revoked from the API roles.
- **Principle:** §16 applied to ourselves — the QA verdict shows its work
  (every "gate passed" traces to queryable rows, not a memory of a stopwatch).
- **Benefit:** gate 3 measured on every real post forever; D32's mode-mix
  question answers itself; F2 becomes a count, not a worry.
- **Tradeoffs:** breadcrumbs are client-fired and lossy by design (swallowed
  on failure) — acceptable: they inform friction fixes, they are not the
  competition record. Rounds remain the only facts.
- **CONFLICT check:** none. Adds observation, changes no mechanic.

---

### D34 · The quick post is front & back only — the hole-by-hole card is pulled
*(Amends D32 — same day. D32 demoted the grid to opt-in; the first two pilot
users on the site still messaged the Pro about the complex post. Real-user
friction on day one outranks the phased approach; the audit spoke first.)*
- **Current:** D32's shape — front & back default, hole-by-hole one tap away
  behind a mode toggle.
- **Problem observed:** the toggle itself still surfaces the complexity. Two
  for two real users stumbled on posting; at pilot scale that is 100% of the
  evidence. The 60-second post (principle #2) is the acceptance test, and the
  test is failing at the door.
- **Recommendation:** hide the mode toggle — the quick post is **two boxes,
  period**. The grid code stays DORMANT (hidden, not deleted): restoring it, or
  wiring a prefill into it, is a one-line unhide. Per-hole data still has two
  living paths: **live scoring** (the tee sheet pencil, entered hole-at-a-time
  during play — unaffected by this change) and, long-term, **scorecard photo
  OCR** riding the photos arc (#13): snap the card → vision model → grid
  prefilled → confirm. When OCR lands, the grid returns as the *confirmation*
  surface, which is what it should have been all along.
- **Principle:** #2 Low Friction — the 60-second post is a gate, not a hope;
  §16 unaffected (gross → differential → band still shows its work).
- **Benefit:** the post screen has exactly one shape; nothing to explain.
- **Tradeoffs:** no retrospective per-hole card until OCR — quick-posted rounds
  carry no hole detail for stats/moments (live rounds still do). The
  even-par soft block and D33's mode-mix telemetry go dormant with the grid.
- **CONFLICT check:** amends D32 (UI level) within hours — named, deliberate,
  evidence-driven. The scoring mechanic and everything above it: untouched.

---

### D35 · Light mode becomes the default; dark stays one tap away
*(UI level. Reverses the dark-first assumption the app was built on — named,
not slid past: CLAUDE.md calls the product "dark UI," and every design pass
until v23.65 was dark-only.)*
- **Current:** `cs_theme` defaults to `'dark'`; light and auto exist in
  Appearance but nobody lands there.
- **Problem observed:** golf happens in daylight. The app's core moments —
  posting at the 19th hole, the tee sheet mid-round, checking the cup line in
  a cart — happen outdoors, where a dark UI fights the sun. The Pro called it
  during pilot week.
- **Recommendation:** default `'light'` for anyone without an explicit
  Appearance choice (both the pre-paint script and the settings marker), and
  the PWA manifest goes light so the installed launch flash matches. An
  explicit choice always wins and always persists.
- **Caveat (honest mechanics):** the preference lives in localStorage, so
  "new users" really means "anyone who never touched Appearance" — a device
  that had the old default flips to light on its next visit. At pilot scale,
  post-wipe, that is effectively everyone, and it is the intended outcome.
- **Principle:** #2 Low Friction (legibility where the product is actually
  used); the brand's gold-forward pass (v23.106) already tuned both palettes.
- **Benefit:** first impressions happen in daylight and now read in daylight.
- **Tradeoffs:** installed PWAs may briefly flash light for the dark-chosen
  until their manifest cache refreshes; the light palette has had fewer
  eyeball-hours than dark — pilot feedback will surface any rough spot fast.
- **CONFLICT check:** contradicts the "dark UI" line in CLAUDE.md's
  architecture note — that line should read "light-first, dark one tap away"
  at the next docs pass. Named here so the contradiction is never silent.

---

### D36 · Scorecard scan: the camera becomes the fastest way to post (photos arc)
*(Mechanic-adjacent — changes how rounds are ENTERED, never how they SCORE.
Scoring still reads only gross/rating/slope; per-hole data stays storytelling
and side-game fuel, exactly as D32/D34 established.)*
- **Current:** quick post is front & back only (D34); the hole grid is hidden;
  per-hole detail lives only in live scoring.
- **Problem:** typing is the tax on every post, and the first two pilot users
  flagged entry friction the day invites went out. The ideal state was named
  in the D34 discussion: "pull the data."
- **Recommendation:** a Scan button on the composer photographs the paper
  scorecard; a vision model (claude-opus-4-8, structured outputs, key held
  server-side in the `scan` Edge Function) reads par row + every player row;
  the D34 grid returns as the CONFIRMATION surface — the model proposes, the
  golfer fixes cells, the round stores what the GOLFER confirmed (§16 holds).
  Partner rows mint claim links (`scan_claims`, same /?claim= funnel as tee
  sheet guests): one scan can post the whole foursome.
- **Cost discipline (structural):** kill switch + per-golfer daily cap +
  global monthly cap in `app_flags`, checked server-side BEFORE spending;
  prepaid API credits with no auto-reload; every failure path degrades to
  typed entry. Worst case is a number chosen in advance (~2¢/scan, ~$5 per
  league-season at Best-4 cadence). `scan_usage` + the `scan_post` breadcrumb
  (cells fixed) make accuracy and spend measurable, so a cheaper model is a
  data-driven one-line change later.
- **Principle:** #2 Low Friction (the 60-second post becomes a 20-second one)
  · #16 receipts (golfer-confirmed, never model-asserted) · growth canon
  (foursome-by-foursome: the partner claim IS the invite).
- **Benefit:** per-hole detail returns to quick posts without typing 18
  numbers; every scan can seed three claim funnels.
- **Tradeoffs:** a real (capped) marginal cost per post; handwriting OCR is
  ~90% not 100% (the confirm grid is the design, not a patch); scan photos of
  scorecards may incidentally contain names — league-scoped visibility and
  the private bucket cover the pilot, revisit at public launch (#34).
- **CONFLICT check:** none upward. D34 anticipated exactly this return path
  for the grid. Pricing question ("who pays for scans at scale") is PARKED
  with the pricing decision — the caps make the interim safe.

---

### D37 · Security hardening — the enforcement floor, before strangers
*(Enforcement of existing rules, not new mechanics: it makes the DB actually
enforce what the spec always promised — §16 rounds immutable, "identity is
checked at the database," the pot/points ledger is commissioner-only. Two
sub-items are pure bug fixes to mechanics that were silently broken.)*
- **Current (pre-hardening):** an RLS/grant floor that assumed trusted users.
  A principal-engineer audit (`spec/launch-audit-2026-07-18.md`, five
  parallel deep-dives + line-by-line verification) found the intent
  architecture sound (definer RPCs, `search_path` pinned, no dynamic SQL, no
  secrets leaked) but the floor holed: any member could `PATCH` their
  `league_members.role` to commissioner; any owner could `PATCH` a posted
  round's `differential`; season-lifecycle + Ryder-engine functions were
  anon/authenticated-callable; and `ALTER DEFAULT PRIVILEGES` silently granted
  EXECUTE-to-anon on every function. Plus two functional time bombs: a CHECK
  that made every month-close abort, and one that made every scan-claim abort.
- **Problem:** the pilot is friends (nobody malicious), so none of it bit —
  but "public launch" is the opposite of trusted, and the two bombs break for
  everyone on a timer (month-close Aug 1; scan-claim on first use).
- **Recommendation (shipped):** two surgical migrations —
  `20260718172300` (blockers: drop `members_self` + `rounds_owner_update`;
  revoke lifecycle/engine functions from the API roles; flip default
  privileges so future functions aren't auto-granted; revoke `email` column +
  drop `profiles_read`; drop legacy `finish_live_round(uuid)`; widen the two
  CHECKs) and `20260718173100` (medium: league/friend-scoped media reads,
  round sanity bounds NOT VALID, legacy course-write drops, round FK → SET
  NULL, courses cost cap). Client: the ~18 unescaped XSS sinks in the
  competition tables + tee sheet now `esc()`; deploy: `publish = "dist"`
  allowlist + security headers + a Report-Only CSP.
- **Principle:** the product canon's trust model ("identity is checked at the
  database, not by hiding a button") — now actually true · §16 (rounds never
  mutated) — now enforced, not just intended · Low Friction preserved (every
  fix is invisible to honest users).
- **Benefit:** the app moves from "safe among friends" to "safe in front of
  strangers" without a redesign; the two bombs are defused before they fire.
- **Tradeoffs:** the default-privilege flip is a **durable new rule** — every
  future migration MUST explicitly `grant execute ... to authenticated` on any
  new client-called RPC (they no longer auto-grant). Recorded in CLAUDE.md.
  Some medium items (live-round foursome-scoping, event-roster consent, join
  phase-gating) are DEFERRED as reviewed SQL in the handoff — they touch live
  flows and want a test round before they ride, and join-gating is a product
  call (late joiners) not a pure security fix.
- **CONFLICT check:** none upward — this is the IA/mechanics levels finally
  matching the vision/principles level that always claimed DB-enforced trust.

---

### D38 · The League Room calendar is league-scoped; the round becomes an object
*(IA + level-5 change now; a build-toward arc for the object. No competition
mechanic changes — pure visibility + a future social layer.)*
- **Current:** the calendar tab was retired into the League Room (IA P2), but
  `my_schedule` returns your rounds **plus friends' plus league-mates'**, each
  labeled. So a buddy you share no league with appeared inside a specific
  league's room. Pilot batch-3 flagged it as confusing.
- **Problem:** "the schedule lives in the League Room" (IA) collides with "the
  schedule is your whole social calendar" (the my_schedule design). A room about
  *this* league showing a stranger-to-the-league reads as a leak.
- **Recommendation (shipped, `4991af9`):** the League Room calendar — grid,
  on-the-books list, and watch list — scopes to `mine || shared_league ||
  tagged_me`; pure-buddy rounds drop to **Home** (`renderUpNext`, untouched),
  where the full social calendar belongs. Decided WITH the owner: "scope the
  League Room, and make Home the richer social/planning surface."
- **The build-toward (`spec/scheduled-rounds-arc.md`):** promote a scheduled
  round from a calendar row to a **clickable object** — a detail sheet (Stage 1,
  the keystone) that later carries RSVP (who's in), comments (a mini board),
  course info (from the cache), and weather (Open-Meteo, keyless). Home gets rich
  cards that tap into the same sheet. Adds **no paid dependency**.
- **Principle:** IA (the League Room is about the league) · #5 Feels Alive (a
  round you rally the crew around) · #2 Low Friction (one sheet, all the info) ·
  the bank-account contract (free to run).
- **Benefit:** the League Room reads true; Home becomes the social planning hub;
  the round gains a home for coordination.
- **Tradeoffs:** `shared_league` is a cross-league proxy (a round isn't tied to
  a league) — Stage 1's `course_id` migration is where an optional `league_id`
  can retire that. The arc is DESIGN-logged, not yet built — awaits a "build it."
- **CONFLICT check:** none upward — resolves an IA-vs-implementation collision in
  the IA's favor.

---

### D39 · Pot canon: "never held" retired for ledger language
*(2026-07-20, owner decision in the desktop-arc session. Voice/business level;
no gameplay mechanic changes.)*
- **Current:** the pot's canonical phrase is "tracked, never held" — D3's
  covenant third rule, the wizard payout help, scoring help, the pot pane,
  README, the guide, GTM messaging. legal.html states the present-tense facts
  ("does not collect, hold, transfer, or distribute money, takes no fee or
  cut").
- **Problem:** "never" is a permanent promise. The owner wants the option to
  offer pot **collection/distribution as a service** later; a forever-promise
  on every surface forecloses it or forces a public walk-back.
- **Recommendation:** retire "never held" everywhere the product speaks.
  Canon becomes present-tense **ledger language** — standard line: *"Cup
  Season keeps the ledger; the money moves between friends."* Door headline:
  *"Every dollar on the books."* Also drop "takes no cut" from marketing copy
  (a future service might take one). legal.html is untouched: it is
  present-tense fact, accurate today; if a money service ever ships, that is
  a compliance project (money-transmission territory), not a copy edit.
- **Principle:** golf-honest voice (say what is true now; promise nothing
  structural) · business optionality (monetization posture is the owner's
  call, and Stripe is parked).
- **Benefit:** every surface stays truthful if collection/distro ships; no
  public reversal of a "never."
- **Tradeoffs:** loses a punchy trust differentiator; D3's covenant line
  softens slightly. Mitigation: ledger language keeps the trust claim
  concrete ("keeps the tab, shows who owes what") without the forever clause.
  The focus-group "revenue structurally capped" argument (pricing doc) now
  carries a D39 asterisk — the cap is posture, not structure.
- **CONFLICT (named):** supersedes the desktop-arc brief's voice canon
  ("'tracked, never held' — match legal.html exactly") and rewords D3's third
  covenant rule. GTM risk-mitigation #5 and assumption #4 re-anchor on the
  ledger posture ("money moves between friends, not through the app" — still
  true today). Frozen artifacts (prospectus, ia-blueprint, season-lifecycle,
  sent pilot PDFs) and immutable migration comments keep the old phrase as
  historical record.

---

### D40 · Invites gate on lock (reverses the 2026-07-17 invite-during-setup)
*(2026-07-20, owner decision after a pilot mis-route. League-lifecycle/flow
change; no scoring mechanic touched.)*
- **Current:** the invite link/code was shared DURING setup — the wizard's last
  step showed "Share invite link" above the lock button, and the setup-Home
  checklist had an "Invite the players" step with a live seat counter (the
  2026-07-17 growth decision: fill seats early). enterLeague routed ANY member
  of a setup-phase league into the wizard (8889).
- **Problem (pilot 2026-07-20):** a Pro created a league, never locked it, and
  shared the pre-lock link. The invited member joined the unlocked league and
  enterLeague dropped them into the wizard — which scaffolds as "My Cup" — so it
  read as if they'd created a duplicate league. Pre-lock joins + wizard routing
  = a broken invited-member experience on the highest-value funnel.
- **Recommendation (built):** (1) enterLeague routes only the Pro
  (role=commissioner) to the wizard in setup; members land on Home's forming
  state — the backstop. (2) The public share link/code moves to AFTER lock:
  removed from the wizard's pre-lock step and the setup checklist's invite
  action. The post-lock `openLockShare` sheet (already built) is the single
  share moment; the pre-loaded email/in-app roster still gets invited AT lock.
- **Principle:** correctness > early seat-fill; a member must never see the
  Pro's configuration tool. Low Friction preserved — locking is one tap and
  openLockShare hands over the link immediately, so the funnel barely moves.
- **Benefit:** members can only join a locked league → they always route
  correctly; the "created a My Cup league" confusion is impossible.
- **Tradeoffs:** loses pre-lock seat-filling. Mitigated: openLockShare fires the
  instant you lock, so "one link fills the league" is preserved, one tap later.
- **CONFLICT (named):** reverses the 2026-07-17 "invite during setup" growth
  decision. Passive code displays still remain in two setup surfaces (the phase
  subtitle at renderPhase, the hub-header code chip) — deferred as optional
  follow-ups; the routing backstop makes them harmless.

---

### D41 · Run it back (post-season renewal moment)
*(2026-07-20, desktop-arc 3d. Retention/lifecycle surface; no scoring mechanic
touched. V1 built.)*
- **Current:** when a league finishes (phase `complete`), the season just ends.
  Nothing prompts the crew to continue — the group chat is hottest exactly when
  the app goes quiet. GTM year-1 names "the run-it-back renewal moment" as the
  mitigation for off-season churn (risk #3), but it was unbuilt.
- **Problem:** the highest-leverage retention beat — a season *just settled* —
  had no product surface. Re-creating next season meant the Pro rebuilding all
  the bylaws from scratch.
- **Recommendation (V1, built):** a "Run it back — Season 2" card on Home's
  Start-something when the user has a `complete` league. It opens the create
  wizard PREFILLED with the old league's bylaws (`applyBylaws(loadBylaws(id))`)
  and a `· S2` name; the Pro reviews and locks → a new league carrying the same
  structure/endgame/pot split/season length. Reuses the entire existing create
  flow (runItBack stashes the bylaws, clicks `#wCreate`, a hook applies them
  after the scaffold+wizard appear) — **no new engine, RPC, or schema.**
- **Principle:** #5 Feels Alive (the season continues) · #4 Memory (S1 → S2, a
  franchise) · GTM retention (the renewal moment, now real).
- **Benefit:** the settled season becomes the on-ramp to the next; the Pro
  re-creates in two taps with everything carried over and editable.
- **Tradeoffs:** V1 mints a NEW league id — continuity by *convention* (the
  `· S2` name + carried bylaws), not a linked object. **True multi-season
  continuity** (same league id, running back-to-back history, "defending
  champs", the grudge/margin line) is a Pro Shop / Gameplay-lane build with its
  own decision. Deferred from V1: the champion+margin detail on the card, the
  event rematch row, and the settlement-post-tail + ended-league-room seams
  (V1 lives on Home only).
- **CONFLICT check:** none upward — a new retention surface consistent with the
  vision. Flags the future linked-multi-season Gameplay build.

---

## Batch 9 — 2026-07-20, the Major (gameplay lane, majors arc)

*The Major was a name at the IA level with zero mechanic (listed beside Ryder
and Bracket under "Start something"; `trophies` reserved `kind 'major'` on day
one). This batch designs it. All five entries resolved WITH the owner
2026-07-20 before any build; the design lands as gameplay-modes §10.*

### D42 · The Major is a standalone championship on the event rails (the ⚑ shape decision)
- **Current:** "Major" is IA canon only — no section in gameplay-modes, no
  schema, no engine. Two honest readings existed: a standalone championship
  event, or in-season "major weekends" scoring bonus weight toward the Cup.
- **Problem:** the in-season reading touches `cup_points()`, caps, and §14's
  fairness story — a rewrite of the flagship mode's math at launch time. The
  standalone reading rides rails that already run (events, sessions tick,
  event board, trophies).
- **Decision (owner):** **standalone championship event** on the events spine
  (`events.kind='major'`), league-attachable exactly like the Ryder (borrow
  crew + board; always a parallel ledger, never cup points — gameplay-modes
  §5). **The A→B port is named, not built:** if a season ever adopts a Major
  ("this one counts toward the Cup"), it enters through `season_adjustments` —
  a ledgered, reasoned, receipted bonus assessed at settle, the exact port
  §14.2 built for `close_month()` — never through `cup_points()`/caps/§14
  machinery. V1 ships nothing behind that door.
- **Principle:** IA level 3 (Major is a peer of Ryder under Start something);
  #2 Low Friction (smallest honest v1); §16 (the future port is a ledger with
  reasons, not silent math).
- **Benefit:** PIGL runs its Major this season without touching the season
  engine; the B reading collapses from a machinery rewrite into one parked
  flag behind a named door.
- **Tradeoffs:** a league that wants an adopted major waits for the port to be
  built — accepted; no league has asked.

### D43 · The championship window — days, not weeks; your best card stands
- **Current:** no mechanic. The session's opening recommendation was four
  weekly rounds, cumulative (real majors' four days mapped onto the crew's
  weekly cadence).
- **Decision (owner redirect, reasoning adopted and recorded):** **a
  compressed window of days** — the organizer picks the **final day** (any
  weekday; wizard defaults the next Sunday) and **length 2–4 days** (default
  4, Thu→Sun — real-major grammar). **Your best eligible card in the window
  is your score**, unlimited attempts. The owner's argument: flexibility over
  a one-day (nobody herds twelve calendars), differentiation from the league's
  week/month machinery, and the hype loop lives *inside* the window — "X
  carded an 82, Y carded an 84, Y just booked another round for the last
  day." The product line spreads by time-grain: the Season is months
  (squads) · the Ryder is weeks (teams) · **the Major is a weekend (the
  field)**.
- **Scoring:** best card by PvI at 100% allowance off `index_at_post`, same
  as everywhere (a frozen-at-entry index was rejected — it forks the app's
  one currency and muddies receipts). Leaderboard wears golf's own grammar
  vs your personal par: "JERECHO 82 · −4.2" — gross is the story,
  vs-your-number is the ranking; the named bands stay the per-card voice
  (D1/D2 law). **No band ceiling:** the round of your life pays in full —
  that is what a Major is for. The ringer vector closes at the field line
  (D44), not by muting the heater; revisit trigger: the first suspicious win.
- **Eligibility:** duel rules verbatim (never voided, never sim) **plus
  18-hole cards only** — a 9 still feeds season and index; the Major is the
  full test (a dial later if a twilight crew asks).
- **No card = NO CARD:** an honest unranked row at the foot. Best-card
  scoring needs no synthetic penalty arithmetic — the empty row is the sting.
  A no-card buy-in settles as a donation, visible on the settlement card.
- **The window tells its story** (server posts, existing rails): open post at
  the tick ("THE PIGL CHAMPIONSHIP IS LIVE — CARDS IN BY SUNDAY NIGHT");
  every card / clubhouse-lead change posts to the event board ("JERECHO CARDS
  82 — CLUBHOUSE LEADER AT −4.2"); **a round booked during the window posts
  the chase** ("MARCUS BOOKED SATURDAY — CHASING −4.2" — the owner's own hype
  beat, riding `scheduled_rounds`); a final-day-morning stakes post via the
  daily tick. Push: stories ride the existing curated webhook; **no new
  opt-in nudge class** — `notify_target` is duel-shaped and a Major has no
  assigned opponent (deferred until a real ask).
- **Principle:** #5 Feels Alive (a leaderboard that moves all weekend); #1
  Golf First; #2 (create = pick a weekend); §16 (every figure taps to its
  card).
- **Tradeoffs:** a compressed window rewards whoever is free that weekend —
  accepted: it's an event, not the season, and the season already honors the
  busy. Unlimited attempts give the thrice-a-weekend player more draws at
  variance than the once-er — golf-honest (the Ryder's comparator has the
  same property), naturally capped by the window's length. Settlement rides
  the daily tick, so the Sunday-night horn crowns Monday morning; the
  organizer's manual settle stays as the override.

### D44 · The field line — two tiers, one leaderboard (exhibition rows)
- **Current:** no mechanic. Substrate: the auto-handicap engine (WHS-lite,
  establishes at 3 rounds; a manual index is a starter that scores overtake).
- **Problem:** a Major with money is the sandbag jackpot — the self-declared
  20 who shoots 82 steals the jug. But a strict established-only door kills
  the guest-claim funnel (the GTM's cheapest wedge) at its hottest moment.
- **Decision (owner):** **two-tier.** An established (engine-derived) index
  at entry → contends for title and pot. The un-established join anyway and
  appear on the leaderboard **flagged exhibition** — name up in lights, can't
  win title or money, official by the next Major. The claimed guest plays
  THIS Major; the conversion hook is the flag itself.
- **Late entry:** allowed until the horn (a Saturday joiner with a Sunday
  card is legal; entries post to the board). No roster lock needed —
  best-card scoring makes late entry self-limiting. The window auto-opens
  with ≥2 entered (the Ryder's both-benches rule, translated). The organizer
  plays like anyone (role-blind).
- **The line is checked once, at add-time,** against the engine's own
  established definition (never a parallel count). Establishing mid-window
  still finishes exhibition — a card that rode a starter number must not
  contend for money; that is the exact hole the line exists to close.
  (Settle-time re-check considered and rejected for v1 on that ground.)
- **Principle:** #1 (fairness is felt); growth canon (the funnel stays open
  mid-event); #2 (one check at entry, zero per-day logic).
- **Tradeoffs:** an exhibition row can top the raw numbers while the jug goes
  to #2 — an awkward beat but an honest one; board copy must crown the
  champion while letting the exhibition line be seen (voice work at build).

### D45 · Ties — the countback ladder, best-card edition
- **Current:** §14.3's ladder exists for the Cup Final; nothing for majors.
- **Decision (owner):** countback, no playoff in v1 — the Major decides at
  the horn and the ceremony fires on time. The ladder, receipts at every
  rung: **tied best card → better second-best card in the window** (the
  deeper weekend wins; any second card beats none — playing more is the
  covenant's own value) → **earliest-posted best card** (they set the number;
  the field had to match it) → **logged coin flip** (§14.3 precedent, posted
  with receipts). Applies to every paying place, not just the title. Stated
  in the fine print at create so it's chosen, not discovered.
- **Rejected:** sudden-death playoff window (real drama, but ceremony and
  settlement wait a week for everyone — logged as the fast-follow when a real
  tie earns it) · shared titles (a Major that can't produce THE champion
  loses its point; the shared cup stays a Ryder thing).
- **Principle:** decidable without a human; §16; #5 (the horn means
  something).
- **Tradeoffs:** the earliest-posted rung mildly rewards posting early — it
  is rung 3 of 4; a countback crowns without a head-to-head moment — accepted,
  the playoff is the upgrade path.

### D46 · Ceremony & pot — champion-only hardware, ledger money, the recap card
- **Ceremony:** completion mints **one trophy row per Major — the
  champion's** (`trophies` kind 'major', title = the event's name). The case
  stays scarce because the jug engraves one name; the runner-up lives in the
  recap and the settlement post, never the case. The champion story posts to
  the event board and — when league-attached — the league board. A
  **share-ready recap card** renders at settle (the D30 canvas pattern:
  champion + marker, event name, final top-3, gross + vs-number, date,
  wordmark) and carries the join path (GTM §3: the sharer looks good, the
  card carries a claim/join path, it shows what a spreadsheet can't).
- **Earned champion's marker:** §9's parked idea has its perfect candidate
  here — flagged, own decision entry when unparked, nothing built silently.
- **Pot:** D39 posture verbatim — a ledger; the settlement card; money moves
  between friends. Buy-in set at create, **$0 bragging rights is first-class
  and the default** (money is a choice, not a default). Paying places default
  **60/25/15** — the season's own split, one fewer number to invent — with a
  winner-take-all preset; no custom-% editor in v1 (D8). Exhibition rows
  never pay (D44); a no-card buy-in settles as a donation, on the card.
- **Naming & calendar:** the user-facing noun is **"a Major"**, "the Majors"
  as branding plural (D12 discipline — "event", "session", "window" stay
  schema words). One at a time as practice, unconstrained. The order-of-merit
  circuit (player of the year across majors) parks until multi-event
  aggregation earns it. Real-major-week anchoring is marketing (Socials
  lane), never a mechanic dependency.
- **Principle:** #4 Memory > Statistics (the case means something because
  it's scarce); D39; growth canon.
- **Tradeoffs:** runner-up hardware will be the first ask — the answer is a
  placement dial later, not default hardware. The $0 default may undersell
  the pot ritual for money crews — the create step surfaces the choice
  ("Buy-in · $0 = bragging rights") so it's seen, not buried.

### D47 · Noun sweep II (2026-07-20, from the pre-build comprehension review)
- **Current:** post-D11 copy grew a second people-noun set ("circle,"
  "buddies" as labels); "on the books" covers both money and scheduling;
  the Home "Record" button collides with the Record (the 2030 archive
  object); "card" runs unqualified in four senses (profile / scorecard /
  recap / settlement); wizard dial groups speak system nouns ("Competition
  structure," "Season format," "The endgame"); "CUP-CODE" vs "league code";
  "At the starter" labels the pre-season state.
- **Problem:** tester feedback (relayed 2026-07-20) — comprehension tax at
  the door and in the wizard; five nouns for two ideas was D11's exact
  disease, regrown at the edges.
- **Recommendation (assignments, copy-only):** **crew = the people**
  everywhere ("circle" retires; "buddies" survives only inside prose, never
  as a label) · **books = money** (D39 door headline keeps it), scheduling
  moves to **the tee sheet** ("Put it on the tee sheet") · Home button
  **"Live round"** replaces "Record" · **"card" never unqualified** (Tour
  Card the artifact, scorecard idiom in the post flow, recap/settlement
  cards as artifact class) · wizard groups in the Pro's grammar (**Teams ·
  How teams fill · How it's scored · How it ends · House rules**) · one code
  noun: **league code** · **"Before first tee"** replaces "At the starter."
- **Principle:** #2 (low friction); the no-tutorial success metric; D11/D12
  noun discipline (one noun, one thing).
- **Benefit:** the wizard speaks the Pro's language; the door explains
  itself; "Record" is free for the archive when Wrapped ships.
- **Tradeoffs:** none mechanical — copy sweep only. Sweep rides the UX arc
  (design-review-2026-07-20 Part II, task 1.5).

---

### D48 · The subtraction batch — H2H, Hybrid, bonus layer, allowance dial retired
*(2026-07-21, gameplay-audit session. Spec subtraction; no engine code exists
for any of these, so nothing is deleted from the client.)*
- **Current:** spec carries Format B (Head-to-Head months, §4), Format C
  (Hybrid +15, §4 — already wizard-removed by D6), the bonus layer (§2.3 —
  never surfaced per D7), and the handicap-allowance dial 100/95/90 (Custom-
  only per D8). All four are dormant: no league uses them, no engine built.
- **Problem:** dormant rules are explain-surface and spec debt. Both design
  reviews flag "H2H in or out" as unresolved; the audit's verdict: "gone means
  gone — from spec too." Every dormant dial re-appears in every future wizard,
  QA pass, and two-minute explanation.
- **Recommendation:** spec v1.1 removes all four. Formats collapse to Points
  Race + the endgame dial (points_table | cup_final). Presets keep their fixed
  allowance values (Casual 100 / Standard 95 / Cutthroat 90) as internal
  constants; no user-facing dial anywhere, including Custom. §2.3 deleted;
  preset-matrix rows (§8) updated. The weekly-clash packet (D52) covers the
  weekly-competition itch H2H aimed at.
- **Principle:** "Set it once, argue never" + the Cup Season Test — nobody
  would miss these because none ever made a golf life richer.
- **Benefit:** shrinks the explainable surface; closes a two-review open
  question; kills three dials that were each "a support ticket wearing a
  settings icon" (D8).
- **Tradeoffs:** a future league wanting monthly match-ups waits for a
  deliberate rebuild. Acceptable: engines were never built, so revival is a
  re-spec, not a restoration.
- **CONFLICT (named):** supersedes spec §4 Formats B/C, §2.3, and the §8
  preset-matrix rows for format/bonus/allowance. Subsumes D6 (Hybrid hidden)
  and D7 (bonuses unsurfaced) — both were half-measures this completes.

---

### D49 · Provisional rounds score normally — flat-7 retired
*(2026-07-21, gameplay-audit session. Scoring-edge change; build rides a
future client+SQL plan, not this session.)*
- **Current:** spec §5 — a new member's first 3 rounds score a fixed 7
  ("New member provisional").
- **Problem:** special arithmetic lands at the moment a new golfer is most
  nervous (both design reviews name this cliff). A great first round scoring
  a flat 7 reads as robbery; a terrible one scoring 7 reads as charity.
  Either way the first score — the first story — is a lie with an asterisk.
- **Recommendation:** provisional rounds score NORMALLY off the starter
  index, badged "provisional" on the card until the engine establishes
  (3 rounds — the engine's own definition, never a parallel count). No
  special points path anywhere.
- **Principle:** Low Friction (one less rule) + Memory > Statistics (the
  first round must be a true story).
- **Benefit:** deletes a rule that needed explaining exactly when explaining
  is most expensive; the first-round moment lands honestly.
- **Tradeoffs:** a sandbagged starter index can buy up to 12/round for 3
  rounds (was capped at 7). Bounded: the 12-point band ceiling (§2.2), the
  exceptional-score cut (§5), and engine takeover at round 3 limit exposure
  to a few points across a nine-month season.
- **CONFLICT (named):** amends spec §5 "New member provisional." Nothing
  upward — principles #1–#3 all served or neutral.

---

### D50 · The Pro's ruling — the dispute procedure, written down
*(2026-07-21, gameplay-audit session. Governance rule; copy-only build —
the covenant and fine print gain one paragraph in a future UX pass.)*
- **Current:** personas-dashboards grants the Pro "resolve disputes" and
  "lock scores"; no doc anywhere says HOW. The override log, the adjustments
  ledger, and D43's no-retro-flip rule all exist — but no user-facing rule
  ties them together.
- **Problem:** the first contested 79 in a money league is improvised. A
  dispute with no procedure escalates in the group chat — the exact failure
  "set it once, argue never" exists to prevent.
- **Recommendation:** one paragraph, stated at join (covenant) and in league
  fine print: **"The Pro rules. Every ruling is a logged entry with a
  reason, visible to the whole league, receipts attached. Settled events
  never change after the fact — the record of the ruling is the recourse."**
  No appeal machinery in-app; the crew's own governance is the appeal.
- **Principle:** "Set it once, argue never" + §16 (everything shows its
  work). A ruling is just another number that shows its work.
- **Benefit:** disputes end in one place, in one tap-through; the Pro's
  power is legitimized by visibility instead of resented as fiat.
- **Tradeoffs:** Pro-as-judge in the Pro's own league is a real conflict of
  interest. Mitigated, not solved: the log is public to the league, and the
  no-retro-flip rule means a ruling can't quietly rewrite history.
- **CONFLICT (named):** none upward — makes personas' asserted power
  concrete; consistent with D43 ("settled cards never retro-flip") and the
  §9 override-log rule.

---

### D51 · The stake line — what your next round is worth (unparked from §8)
*(2026-07-21, gameplay-audit session. Unparks gameplay-modes-working §8;
BUILD is a separate client plan on an explicit "build it." The audit ranked
this the highest value-to-effort item in the backlog: the one-more-round
rule as a mechanic.)*
- **Current:** designed in full (gameplay-modes §8), parked 2026-07-17 with
  three ⚑. ⚑2 (placement) already answered by the UX lane: the post-a-round
  screen. No line exists in the product.
- **Problem:** the product never tells a golfer what today's round is
  actually worth — and the naive version ("worth up to 12!") is a lie for
  anyone at cap. The honest marginal is computable client-side today.
- **Recommendation:** ship §8 as designed. Priority ladder (floor at risk →
  index not established → at cap → cup-line closable → below-cap default →
  silent). ⚑1 RESOLVED (owner, 2026-07-21): show the at-cap line, reframed —
  "your best four are banked; today's round is for your number, the Iron
  Man, and the board" — honest, never deflating (a round never scores zero
  to the golfer's life, only to the table). ⚑3 RESOLVED (owner, 2026-07-21):
  silent by default when nothing on the ladder applies. Inherited laws
  restated for the build: never claim a resulting position (D24); never say
  "counting cap" — say "your best four" (D2); line taps through to the
  month's slot meter (D3, §16); read `b.floor_penalty` directly, never
  infer from preset.
- **Principle:** Every round counts + the one-more-round rule; §16 (the
  line is a receipt with a verb).
- **Benefit:** the post screen answers "why post today" at the exact moment
  the golfer is present because they played; floor-at-risk becomes a
  17-point swing stated plainly.
- **Tradeoffs:** the at-cap truth can still cool a table-chasing golfer.
  Chosen deliberately over the alternative (a comforting lie). The
  floor-at-risk Home surface (the golfer who most needs the line never
  visits the post screen) stays OPEN — it is a nudge, so it rides D23's
  fence and needs Social-lane coordination; logged here as the named
  remainder, not silently dropped.
- **CONFLICT (named):** none upward. Brushes D23 only via the deferred
  Home-surface remainder, which is explicitly not shipped here.

---

### D52 · The weekly clash — one spotlighted pairing per week
*(2026-07-21, gameplay-audit session. NEW mechanic — the audit's structural
finding made concrete: the flagship season lacks the weekly anticipation
loop the Ryder has. Owner call: build for LAUNCH, not gated on month-1
proof.)*
- **Current:** week snapshots write headlines ("won Week 4") and the events
  engine detects rivalry weekly clashes — but nothing RIDES on a week.
  Between month closes the standings drift; no appointment, no deadline.
- **Problem:** fantasy football's engine is the week-as-episode
  (anticipation Tue–Sat, resolution Sunday). Cup Season's unit is the
  month — too long for an anticipation loop. The most exciting mode built
  so far is the Ryder, a side product, precisely because it has weekly
  duels.
- **Recommendation:** each season week, spotlight ONE clash per league.
  Engine picks the pairing: named rivalry (D21) > closest table gap >
  least-recently-featured (rotation guarantee). Best band-of-week takes a
  headline W; result feeds the faceted rivalry record ("weekly clash 3–2",
  per the item-18 one-object-per-pair law). NO cup points — parallel
  ledger, §5 unchanged. Board post at week open ("THIS WEEK: Jerecho v
  Marcus"), settle post at week close; both-idle settles quiet (no
  headline, honest). Push rides curated rails, opt-in (D23 + the item-17
  number-to-beat precedent). BUILD: for launch (owner, 2026-07-21) — the
  build plan spawns from this entry; the heartbeat outranks surface-count
  discipline.
- **Principle:** The App Should Feel Alive + anticipation between rounds —
  at crew scale, where the thin-feed arithmetic (2–3 posts/week) can't
  fill a daily feed, a weekly episode is the honest cadence.
- **Benefit:** the season gets the Tue–Sun appointment beat; the rivalry
  record gets a steady diet; the board gets two guaranteed stories a week.
- **Tradeoffs:** a spotlight excludes everyone not in it that week —
  rotation rule mitigates; small leagues (4–5) cycle fast anyway. Adds one
  engine surface to a product the reviews say is already too wide — the
  owner accepts that cost for the launch heartbeat.
- **CONFLICT (named):** none upward. §5 parallel-ledger law respected;
  D23's fence respected (push opt-in, board posts are not nudges). Departs
  from both design reviews' "proof before features" posture — named here
  as a deliberate owner call, not an oversight.

---

### D53 · The month-close podium — the close becomes a ceremony
*(2026-07-21, gameplay-audit session. Storytelling extension of close_month;
no scoring change, no hardware. Build is a server-post copy extension.)*
- **Current:** close_month() posts "JULY CLOSED" + a standings snapshot.
  Correct machinery, zero ceremony.
- **Problem:** the month is the product's natural episode and its ending is
  administrative. Member-member golf runs on podium moments; the close is
  the one guaranteed monthly beat every league shares, and it currently
  spends itself in one line.
- **Recommendation:** the close post becomes a short ceremony, all from
  data already computed: month podium (top squad-month score), month MVP
  (best individual points), biggest climb (largest table move). No new
  points, no hardware, no new tables. The ghost list (who fell short)
  stays PRIVATE — floors already handle it in the ledger; shame is not a
  mechanic (D23).
- **Principle:** Memory > Statistics — the episode ender is a story;
  "JULY CLOSED" is a fact.
- **Benefit:** a recurring screenshot-shaped artifact every month; the
  month gains a finale worth checking the app for.
- **Tradeoffs:** none material. Copy discipline required so the podium
  never reads as a leaderboard-of-shame for the bottom.
- **CONFLICT (named):** none upward. Rides §14.2's existing close post;
  D23 respected (no shame surface).

---

### D54 · Draft night — the blind draw learns to take its time
*(2026-07-21, gameplay-audit session. Reveal mechanics only; the draw rule —
server-side shuffle, rigging-proof — is untouched.)*
- **Current:** §15 blind draw runs instantly and reveals as one board post.
- **Problem:** draft night is the highest-retention day in fantasy sports —
  people schedule around it — and Cup Season spends it as a feed item. The
  audit's missing moment #1.
- **Recommendation:** the Pro may SCHEDULE the draw (default remains
  instant). A scheduled draw shows a countdown on Home; at T-0 squads
  reveal card-by-card as paced board posts (~30s stagger), reactions live
  between reveals. The shuffle itself is unchanged — one server-side
  shuffle at T-0, then paced disclosure of a result already fixed
  (rigging-proof property preserved by construction).
- **Principle:** create memories — the same information, delivered as an
  event instead of a record.
- **Benefit:** the season opens with theater instead of paperwork; the
  first shared-appointment moment of every league's life.
- **Tradeoffs:** needs a pacing mechanism (server-timed posts vs a client
  reveal over one post — the implementation lane decides; neither touches
  the draw's integrity). Scattered-timezone crews may watch alone — at
  crew scale, usually fine; countdown copy can nudge a shared time.
- **CONFLICT (named):** amends §15's reveal mechanics only; the formation
  rules (blind draw default, assign, captains-pick roadmap) are untouched.

---

### D55 · The sunlight chip — index movement shown where money enters
*(2026-07-21, gameplay-audit session. Transparency surface; no eligibility
rule, no block, no enforcement.)*
- **Current:** PvI off index_at_post is the load-bearing currency of every
  money surface. The season is protected by the 12-band ceiling; the Major
  removes the ceiling ("the round of your life pays in full") and its
  field line (D44) only stops the un-established. The Ryder ships with no
  anti-sandbag at all.
- **Problem:** the one place a padded index pays linearly is exactly where
  dollars appear, and the integrity of the number is asserted, not shown.
  The first suspicious Major win (D43 names it as the revisit trigger) is
  cheaper to pre-empt than to adjudicate.
- **Recommendation:** on money-event entry surfaces (Ryder roster, Major
  field), each player carries a neutral fact-chip: current index vs 60/90
  days ago — "12.4 · was 11.2 in May" — from the index snapshot history
  already kept. New profiles with no history show "—". No block, no flag,
  no threshold, no accusation copy: sunlight, and the crew polices itself
  the way real money games always have.
- **Principle:** §16, everything shows its work — extended from scores to
  the number the scores are measured against. Anti-sandbagging by
  transparency, not enforcement (the same philosophy as the 12 ceiling).
- **Benefit:** closes the audit's money-integrity gap for both events with
  one chip; no accusation UI to build or moderate.
- **Tradeoffs:** an honest improver's falling index wears the chip too —
  acceptable because the chip is a neutral fact and falling indexes read
  as bragging rights anyway. A rising index has innocent explanations
  (injury, rust); the chip states, never judges — copy law.
- **CONFLICT (named):** none upward. Complements D44's field line (which
  gates the un-established); neither replaces the other.

---

### D56 · Pricing unparked — visible model at iOS launch, checkout waits for season 2
*(2026-07-21, pricing-arc session, owner decision. BUSINESS level (1–2).
Discovery + deck + integration plan only; zero app code ships from the arc.)*
- **Current:** pricing PARKED 2026-07-15 pending focus groups (CLAUDE.md
  monetization canon). Blanket public silence in force: socials plan forbids
  pricing talk in any reply; `appstore-launch-kit.md` FAQ deflects ("long-term
  pricing is honestly still being decided"). Working model on the books but
  unshown: per-league season pass paid by the Pro out of the pot ($49–99/season
  ≈ $5–8/player), individual golfer free forever, Founding Leagues (PIGL +
  first ~5–10) free forever, charge at the season-2 "run it back" moment
  (gtm-year1 §11; assumption §14.1).
- **Problem:** the mid-August iOS launch onboards the leagues whose season-2
  renewal lands early 2027. If the first time a Pro hears a number is the
  renewal ask, "wait, it was free" becomes the fight — GTM failure mode #4
  (renewal/price mistrust) predicts exactly this. And the focus groups the
  park is pending need an instrument: a shown, concrete model to react to,
  not a hypothetical "$X?" (focus-group-plan's own trap #2).
- **Decision (owner):** UNPARK, at bounded depth. (a) **Scope: REFINE the
  canon model** — per-league pass, Pro pays from pot, golfer free forever,
  Founding free forever, charge at season 2 — the field does not reopen.
  (b) **Launch depth: VISIBLE MODEL, NO CHECKOUT** — at iOS launch the model
  is public and honest on the wizard pot step, the You-tab membership card,
  and the League Room Pro view, all wearing first-season-free messaging; no
  payment rails ship; charging begins when the first leagues hit season 2.
  (c) The arc produces discovery, the focus-group deck
  (`spec/handoffs/pricing-deck.html`), surface mockups, and an eng
  integration plan — the deck is the instrument the parked focus groups run
  on, and the script's answers close the price point.
- **Principle:** charge-after-proven-value (GTM §11) · golf-honest voice —
  say what is true now, D39 lineage: a price stated up front is honest, a
  price revealed at renewal is a trap · business optionality (Stripe stays
  parked; nothing structural is promised).
- **Benefit:** every league recruited at launch signs up under a stated
  model, so the season-2 ask arrives pre-announced; the focus groups react
  to real surfaces instead of hypotheticals; App Store metadata can answer
  "what does it cost" truthfully.
- **Tradeoffs:** public numbers before the point is focus-group-final —
  mitigated by range/anchor framing owned by the deck until the owner ships
  copy. Competitors see the model — accepted; the moat is the crew and the
  record, not the price sheet.
- **CONFLICT (named):** **overrides** the blanket no-public-pricing-talk
  posture (the 2026-07-15 park's public half: socials forbidden-list line,
  launch-kit FAQ deflection — both re-anchor on the visible model when the
  owner ships copy). **Upholds:** no pricing on the app's front door (the
  door stays clean; D47's door headline untouched) · Stripe parked · Founding
  Leagues free forever · golfer free forever · D39 ledger posture (the pass
  is paid TO Cup Season; the pot is never held BY it — the two stay visibly
  distinct on every surface). **Stays parked:** the exact price point (until
  the script's answers are in) · checkout/payment rails (build gated on the
  first real season-2) · pot collection/distro as a service (D39's future
  door, untouched).

---

## Batch 10 — 2026-07-22, the shareability lane (Growth)

### D57 · Public share pages — a tokened, revocable window onto one artifact
*(IA/visibility level — touches §16's visibility posture and D37's anon
surface, so it's logged BEFORE the migration ships. Scoring mechanics
untouched; this changes who can SEE a curated snapshot, never what counts.
Owner pre-approved the build 2026-07-22: "full send" in the arc brief.)*
- **Current:** every share artifact is an image or an invite. The recap/jug
  cards leave as PNGs (D30/D46 — no click-through by design, Growth owns the
  link upgrade); game settlements produce nothing tappable at all (audit F5);
  the only public token surfaces are the claim funnel (`claim_round_info`,
  `scan_claim_info`), the join code (`league_by_code`), and `founder_id` —
  D37's four anon endpoints, checked literally by `tests/db-checks.sql` #2.
  A recipient who wants to SEE the round behind a card must make an account.
- **Problem:** the acquisition motion is shareable artifacts (marketing
  canon), and the strongest artifact — a real round with a name, a course,
  and a band phrase — dead-ends in a screenshot. D30 named the tokened public
  page as Growth-lane work; the lane is here. Meanwhile any naïve "public
  round page" (`/?round=<id>`) would leak enumerable ids and violate the
  §16-adjacent posture that the DATABASE decides visibility, not the URL.
- **Recommendation (the token model):** a `shares` table — `token uuid` PK
  (`gen_random_uuid()`, unguessable), `kind` (`round|settlement|recap`),
  `ref_id`, `created_by` (profile), `revoked`, `created_at`. RLS ON with **no
  policies** — definer-only access, the client never touches rows.
  `create_share(p_kind, p_ref)` (authenticated) verifies the caller owns or
  played the artifact and returns the token — **minting is lazy**: no share
  row exists until a golfer explicitly chooses "Share a link" (§16 spirit —
  the golfer publishes; the app never does). Re-minting returns the existing
  live token (one artifact, one link). `revoke_share(p_token)` (creator only)
  kills a link that escaped the group chat. `share_info(p_token)` — **the ONE
  new anon endpoint** — is security definer and returns a curated jsonb
  snapshot: display name, marker, gross, the band phrase inputs, course
  label, date, league name, settlement story/transfers. NEVER email,
  never raw rows, never ids. **Fail-closed:** unknown, revoked, and
  wrong-kind tokens all return the same empty answer — no error texture to
  enumerate against; a bad link and a revoked link are indistinguishable
  outside. Client route `/?share=TOKEN` renders a lightweight card view on
  the existing shell — artifact big, "Built with Cup Season," one CTA to the
  door — no nav, no app boot beyond the card.
- **Why fail-closed instead of expressive errors:** an anon endpoint is a
  probe surface. Distinct answers for "no such token" vs "revoked" vs "wrong
  kind" turn the token space into an oracle; one empty answer makes the whole
  surface worth exactly one bit. The recipient-side cost (a dead link says
  only "nothing here") is accepted — the sharer can always re-mint.
- **D37 discipline (enforcement, in the same migration):** explicit
  `revoke ... from public, anon` on the two authenticated RPCs; explicit
  grants (`share_info` → anon + authenticated); `tests/db-checks.sql` check 2
  literal list goes 4 → 5, check 3 gains the three names; CLAUDE.md's "four
  public endpoints" line becomes five. Checks 2/3/9 run after push.
- **Principle:** growth canon (the artifact carries the join path — GTM §3);
  #4 Memory > Statistics (the round is worth a page, not just a PNG); §16
  (the snapshot shows its work: gross + band + course, receipts stay in the
  app); D2's law holds on the way out (no differential, no index, no jargon
  in the public snapshot).
- **Benefit:** "send me the link" finally has an answer; every settlement
  and recap can travel as a tap instead of a screenshot; the door CTA turns
  a viewed round into a started crew.
- **Tradeoffs:** (a) a share link is a bearer instrument — anyone holding
  the token sees the snapshot; mitigations are unguessability, revocation,
  and the curated (already-shoutable) payload. (b) Static OG v1: a pasted
  share link unfurls as the generic app card, not the round (audit F6) —
  per-share OG needs a crawler-serving edge function, ⚑ flagged follow-up,
  NOT smuggled into this migration. (c) One more anon endpoint widens the
  D37 surface by exactly one definer function — priced here, checked by
  tests. (d) Revocation is manual; nothing expires by time — acceptable for
  artifacts whose content is already the group chat's business.
- **CONFLICT check:** none upward. Extends D30 exactly along its named seam
  ("Growth-lane work that can later reuse this same card design"). D37's
  rule survives BECAUSE the entry + checks move together; §16's "rounds are
  never mutated" untouched — shares reference, never copy or edit.

## Batch 11 — 2026-07-22, the setup-QA lane (UX/QA)

### D58 · Formation integrity — the hat learns to count

- **Current mechanic:** `randomize_squads` dealt unassigned members round-robin
  from index 0 on every call and checked nothing else; `start_season` checked
  only for unassigned members. `state.draftType` was set by the wizard dial and
  never read back from bylaws.
- **Problem (setup-QA S4-01/S4-02, prod walk):** a 1-golfer "draw" produced
  1–0; a redraw after one join stacked 2–0 with Squad 2 empty and no recovery
  control; a Pro-assign league rendered (and server-ran) the blind draw; a
  degenerate formation could start a season under "minimum four to tee off."
- **Recommendation (built):** the draw deals each pool golfer into the
  currently smallest squad (ties shuffled) so draws and redraws always balance;
  it refuses non-random `draft_type` and leagues with fewer golfers than
  squads; zero-pool calls return silently (no phantom board story).
  `start_season` refuses <4 golfers, any unassigned golfer, any empty squad.
  Client rehydrates `state.draftType` from bylaws on every league entry.
- **Principle served:** §2.2 (the draw is argument-proof only if it can't
  produce an argument); §16 (a board story never announces a draw that moved
  nobody); "minimum four to tee off" stops being copy and becomes a gate.
- **Benefit:** the assign engine's absence is now an honest server refusal
  instead of a silent wrong-engine run; no league can wedge itself into an
  unstartable or unfair formation during setup.
- **Tradeoffs:** a redraw still never RESHUFFLES already-seated golfers (that
  stays the Pro's assign/delete recourse — reshuffle-on-every-draw would tear
  up seats people already saw); min-4 blocks tiny test leagues from starting
  (accepted: that is the spec's floor).
- **CONFLICT check:** none upward; enforces §14.0/§2.2 as written. Snake/live
  draft engines remain unbuilt and now refuse loudly instead of misfiring.

## Batch 12 — 2026-07-23, photos arc 2 (Social/Growth seam)

### D59 · Profile photos — the marker becomes the floor (the D36 reversal)

- **Current mechanic:** D36 skipped profile photos deliberately — "the marker
  is identity." Faces existed nowhere; every identity surface rendered the
  chosen ball-marker glyph. (Note: spec/photos-arc-2.md drafted this as "D58";
  the setup-QA lane claimed D58 for formation integrity first — this entry is
  the same decision under its real number.)
- **Problem:** the marker carries recognition among strangers poorly (twelve
  saguaros in a growing league), and the Tour Card — the identity object — has
  no face on the door. Pilot photos proved the appetite: golfers post photos of
  rounds, not abstractions.
- **Recommendation (built):** `profiles.photo_path` in the EXISTING private
  `media` bucket (`{uid}/avatar.jpg`, own-prefix policies already fit; 8MB +
  image-only caps hold). Avatars render wherever identity renders on league
  surfaces; **the fallback is always the marker — no gray-silhouette state
  exists in the app.** Per-league marker override (`league_members.marker`,
  self-set via `set_league_marker`) keeps the marker a living choice, not a
  relic. Round photos and the receipt hero carry the poster's marker medallion
  (attribution + brand). Moderation: avatars stay signed-in-only (bucket
  private); `report_content` widens to `kind='profile_photo'` targeting a
  profile; the founder desk gains a reports pane (the report table finally has
  a reader). Pro-side takedown deferred until real abuse (D19 precedent).
- **Principle served:** #4 Memory > Statistics (the card is a person, not a
  row); §16 adjacency (a report lands where someone actually looks).
- **Benefit:** recognition at a glance in leagues past the first foursome; the
  Tour Card reads like a card; the marker gains a second job (stamp) instead
  of losing its first.
- **Tradeoffs:** a moderation surface now exists and must be watched (desk
  pane is the watch); signed-URL cost per league load (one batched call, 1h
  TTL, same pattern as round photos); crop/upload UI weight in the You sheet.
  Friends-only surfaces (picker rows for non-league buddies) keep the marker
  floor in v1 — `my_friends` is untouched this checkpoint.
- **CONFLICT (named, D36):** D36 said the marker IS identity; D59 demotes it
  to identity FLOOR + brand mark. Owner call, 2026-07-22, recorded in
  spec/photos-arc-2.md ("DESIGN APPROVED"). The demo diorama still never
  fabricates faces — markers only there.

### D60 · The photo travels — publish-by-copy onto the share page (extends D57)

- **Current mechanic:** D57 share pages are text-only snapshots. Round photos
  live in the PRIVATE `media` bucket; the anon share page cannot sign storage
  URLs (definer SQL can't mint them; an edge-function proxy would add server
  machinery and per-request cost).
- **Problem:** the round card is the app's strongest artifact and its photo is
  the strongest part — the shared page drops exactly the thing the group chat
  would stop scrolling for.
- **Recommendation (built):** **publish-by-copy.** A new PUBLIC bucket
  `shared`; when a shared round carries a photo, the MINT flow (the sharer's
  own device, which holds read access to the original) uploads a compressed
  copy to `shared/{TOKEN}.jpg`. Storage policies gate writes by the `shares`
  table itself — insert/delete allowed only where the filename's token is a
  row with `created_by = auth.uid()`. Flat token path: no uid, no ids in the
  URL (D57 law holds). `share_info`'s round branch gains `'photo': exists`
  (definer reads `storage.objects`); the page renders the photo as the card's
  backdrop under a dark wash with the marker as a corner medallion.
  `revoke_share` deletes the copy first, then revokes the token — revoke
  kills both.
- **Publish consent:** the photo already went to the league board; tapping
  "Share a link" is the publish act (D57's golfer-publishes spirit). The
  button reads **"Share a link — card + photo"** when a photo will travel.
- **Principle served:** growth canon (the artifact carries the join path);
  #4 Memory > Statistics; D57's fail-closed token law unchanged.
- **Benefit:** the shared round finally looks like the round; zero server
  pieces, zero signing, stable public URL.
- **Tradeoffs:** (a) the copy is a SNAPSHOT — replacing the round photo later
  does not update an existing share (canon: the share is a snapshot; re-mint
  after revoke picks up the new photo). (b) A public bucket exists now —
  bounded to 2MB jpeg, writable only through the shares fence, unlisted flat
  tokens. (c) Avatars still never reach the share page — the marker stays the
  public face (D59 boundary).
- **CONFLICT check:** none upward. Extends D57 along its named seam; §16
  untouched (the original round row and photo are never modified).
