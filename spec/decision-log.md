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
   Home / Clubhouse / ⊕ / You — IA P5 retired the Crew tab and moved buddies
   into You; cite the SHIPPED bar, not this line's earlier draft of it)
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
- **Amendment, 2026-07-24 (`20260725210000`) — views run as their reader.**
  The anon table seal (`20260724150000`) closed the ANONYMOUS read of
  `v_event_scoreboard` at the grant layer but left the view's execution mode
  alone: no `security_invoker`, so it ran as its owner (postgres, who owns
  `event_duels`/`event_players` and skips their RLS) while still granted to
  `authenticated` — any signed-in user could read every event's team totals
  cross-league, participant or not. Aggregate-only behind unguessable event
  UUIDs, but a read no policy ever authorized, and the odd one out among the
  four API-visible views. Flipped to `security_invoker='true'`; the base-table
  policies (`is_event_member or is_event_league_member`, widened by D61's
  Major migration) are exactly the ones already gating the `event_duels` read
  the client makes in the same `Promise.all`, so the change is parity for
  every legitimate reader and zero rows for everyone else. Definer callers
  (`resolve_session`'s clinch check, the cron tick) are unaffected — they run
  as the table owner. db-checks gains **check 11**: any public view an API
  role can select must carry the option. Fixing it at the semantics layer
  rather than the grant layer means the leak stays shut even if an anon grant
  survives somewhere.

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

### D60a · Amendment — league names stay home (share payload tightening)

- **Pilot:** a round share carried the sharer's league name onto the public
  page ("Who's the bitch?" on a stranger-facing artifact). League names are
  in-joke space; the public page is not.
- **Rule:** the artifact shows only what it is ABOUT. A round is about the
  golfer (league dropped). A settlement is about the game (league dropped).
  A recap IS the league's season — the name stays, because the sharer shares
  the league itself, knowingly.
- Server-side: share_info stops returning 'league' on round + settlement
  branches (curated payload — the page never receives it). Skew-safe both
  directions (client conditionals already guard the key's absence).

---

## Batch 13 — 2026-07-23, the lineage batch (gameplay/social seam)

*Drafted from the 2030 deck session (owner-sequenced: Major lineage → Ryder
series → Last Round With → Forfeit Ledger). All four are DRAFTS logged before
build per the working protocol — each waits for its own "build it." Ranked by
machinery-already-exists. ⚑ marks the points still needing an owner call.*

### D61 · The annual Major — lineage unparked (§10.9)
- **Current:** v1 serves the annual by convention only: create by the same jug
  name each year, `trophies.season_year` stamps the year, the case reads "The
  Thanksgiving Major · 2026 / 2027 / …". No defending champion in the
  announce, no "Nth annual" counter, no champions roll, no one-tap rematch —
  each year's Major is rebuilt from scratch and its history is invisible at
  the exact moment it sells itself (create + announce).
- **Problem:** the strongest hype sentence a crew owns — "4th annual ·
  defending: Marcus" — is never rendered. The date already belongs to the
  crew (§10.9's insight); the product doesn't know it.
- **Recommendation:** lineage by EXPLICIT LINK, never name-sniffing.
  (a) The event rematch row D41 deferred: "Run it back — {jug name}" on a
  completed Major's room + Start-something, opening the Major create flow
  prefilled (name, days, buy-in, split carried; final day advanced toward
  next year's same weekday-anchor, editable). (b) A rematch-created event
  stores `events.lineage_id` = the chain's first event id (additive column).
  (c) The open/announce post names the defending champion and the count
  ("THE 4TH ANNUAL THANKSGIVING MAJOR — MARCUS DEFENDS"). (d) The event page
  carries the champions roll (completed events in the chain, year · name ·
  gross · vs-number). (e) No new nudge class; any future anticipation nudge
  rides D23's fence (named emotion: anticipation; threshold, never schedule).
- **Principle:** #4 Memory is sacred (the annual is the crew's own calendar) ·
  #5 Feels Alive · GTM §3 (the lineage artifact recruits — "official by the
  next Major" now points at a real, named next Major).
- **Benefit:** the zero-build convention becomes a real franchise object; the
  jug accumulates names; the cheapest lineage build in the corpus (D41's
  pattern, one additive column, existing posts rail).
- **Tradeoffs:** organic same-name creates do NOT link (honest: lineage is
  chosen, not guessed). ⚑ RESOLVED (build go, 2026-07-23): v1 is
  rematch-only; the "adopt into lineage" tool waits for a real stray. The
  champion's earned marker stays parked (§9) — explicitly NOT unparked by
  this entry.
- **CONFLICT check:** none upward. Pays D41's named deferral ("the event
  rematch row"); D46's ceremony untouched (each edition still mints its one
  trophy).

### D62 · The Ryder becomes a series
- **Current:** every Ryder is standalone. Completion mints the shared team
  trophy + MVP (kind-aware award branch); rooms show one edition; rosters and
  benches rebuild from scratch; the all-time tally between the two benches
  exists only in the crew's heads.
- **Problem:** the Rivalry object is the fuel, and the Ryder is its purest
  container — but "Blue leads the series 2–1" is rendered nowhere, and the
  dead air between editions has no standing score.
- **Recommendation:** the same lineage rail as D61 (one build, two doors):
  rematch tap on a completed Ryder carries name, session count, both team
  names/colors, and benches (roster editable before lock); `lineage_id`
  chains editions; the room header adds the series line computed from the
  chain ("THE 3RD RYDER · BLUE LEADS THE SERIES 2–1", shared editions counted
  as shared); the open post names the holder ("BLUE DEFENDS THE CUP").
  Series identity follows the team SLOT carried at rematch — rename freely,
  the tally follows the bench, not the label. V1 TRIM (build, 2026-07-23):
  the holder line renders in the ROOM HEADER ("BLUE DEFENDS"), not a server
  open-post — the open post rides the next pairings-post touch.
- **Principle:** the Rivalry object (2030 canon) · Memory · Feels Alive
  (between-editions air gains a score).
- **Benefit:** "the 3rd Ryder" is a sentence that re-forms both benches by
  itself; captains stop rebuilding rosters; the series line is the room's
  cheapest new drama.
- **Tradeoffs:** no cross-edition player stats in v1 (duels already archive
  to rivalry facets; a series-MVP table is a later dial). A crew that wants
  fresh random benches each year just… doesn't tap rematch — the series line
  only exists inside a chain.
- **CONFLICT check:** none upward. Trophy scarcity holds — every edition
  mints its own hardware; the series line is a tally, not a trophy.

### D63 · Last Round With — the reunion whisper (blue-sky #2 unparked)
- **Current:** shared-card facts are already auto-captured (who was on the
  tee sheet / attested rounds). The Record shows your rounds; nothing
  surfaces the friend who drifted.
- **Problem:** the one-more-round rule points at rivals and seasons; its
  purest expression — handing a lapsed Saturday back — has no surface.
  (Prospectus coda, turned proactive.)
- **Recommendation:** one quiet card (Record + Crew room, in-app ONLY, no
  push class): "You and Cole — last card together 14 months ago." One tap
  stages a gathering on the existing scheduled-rounds rails with both of you
  on it. Fires on THRESHOLD only, never a schedule: surfaces when the gap
  ≥ 12 months AND the history is real (≥ 3 prior shared cards), at most one
  name at a time, dismiss = quiet for months. ⚑ RESOLVED (build go,
  2026-07-23): 12 months · ≥ 3 shared cards · dismiss = 90 days quiet,
  device-local in v1.
  Copy law (this is the build's hard part): a statement of fact plus a door —
  never "you haven't," never streak grammar. D23 compliance explicit: the
  emotion is *longing*, named in the entry, and it must never read as guilt.
- **Principle:** the Final Rule (custodians of people's Saturdays) · Memory ·
  the one-more-round rule pointed at friendship instead of rivalry.
- **Benefit:** a retention beat that IS the mission; zero new data capture;
  arguably the purest Cup-Season-Test feature in the backlog.
- **Tradeoffs:** tonal risk is the whole risk — melancholy handled badly
  reads as guilt; copy reviews gate the ship. Uses only mutual card facts
  (both parties were on the round) — no contact scraping, no one-sided
  "misses you" surfaces.
- **CONFLICT check:** none. D23's fence is the design, not a constraint on it.

### D64 · The Forfeit Ledger — stakes past money (blue-sky #3 unparked)
- **Current:** the pot is a dollars ledger (D39). The Callout (D21) settles a
  declared number. Everything else real crews actually play for — the
  cookout, the course pick, strokes next time, the standing ace bounty —
  lives in the group chat and evaporates.
- **Problem:** a $0 league reads as the poor cousin of a money league, when
  its currency is pride — currently pride without receipts.
- **Recommendation:** named non-money stakes with pot-grade rigor. A forfeit
  = name + terms + parties + what it hangs on + settled-by + date, archived
  into the rivalry facets like any meeting ("the Lawn Bet: Ed 4–3").
  Templates first, free text second: loser hosts · winner picks the course ·
  strokes-next-time · standing bounty ("first ace: steak dinner from
  everyone — open since 2026"). COMPOSITION RULE (the D21 seam, resolved):
  a forfeit never settles anything itself — it hangs ON a thing that already
  settles (a duel, a match, a Callout, a season place); standing bounties
  settle by the parties' confirm tap. One engine of results; forfeits are
  consequences, not competitions. ⚑ RESOLVED (build go, 2026-07-23): v1
  templates = the four listed; either PARTY confirms a settle (the Pro's
  D50 ruling stays the dispute backstop, not the happy path). V1 TRIM: every
  settle is a party tap — the auto-hook onto duel/match/callout results is
  the fast-follow, so v1 ships one engine and zero result-plumbing risk.
- **Principle:** D39's exact posture extended past dollars (the ledger,
  never the bank) · Memory > Statistics (stakes become stories) · the Stake
  object (D51's line gains a non-dollar currency).
- **Benefit:** the $0 league becomes a league whose currency is pride with
  receipts; twenty years on, the Wager Archive is lore no spreadsheet kept.
- **Tradeoffs:** legibility burden — forfeits must be unmistakably NOT
  money: no dollar rendering, no champagne treatment (gold stays earned
  standings/pot language), prose voice not ledger arithmetic. Store-review
  posture guarded: no cash value, no conversion to the pot, ever.
- **CONFLICT check:** brushes D21 exactly as blue-sky flagged — resolved by
  the composition rule above (compose, don't fork). Trophy law untouched:
  forfeits archive to facets, never the case.

### D65 · The sandbox league — a season in an hour (owner tooling, 2026-07-24)
- **Current:** verifying league play end-to-end needs eight humans and three
  calendar months. The demo is a diorama (never exercises real RPCs); the QA
  walk drill covers flows one account at a time but cannot compress time.
- **Problem:** the owner cannot rehearse a full season (weeks of posting →
  month closes → cup final → crowning) before real leagues live it first —
  the endgame ships untested at season speed.
- **Recommendation:** real mechanics, fake people, movable clock. Five
  founder-gated RPCs (migration `20260724170000`): `sandbox_arm` flags a
  league sandbox and mints ≤8 bot accounts (unroutable
  `@sandbox.cupseason.test`, empty password — unloginable; non-discoverable;
  members of the sandbox league ONLY); `sandbox_rewind(w)` slides BOTH season
  dates back preserving length, so week w+1 is simply now and the cup window
  / season end arrive through the ordinary daily-tick law; `sandbox_week`
  posts the next empty week of bot rounds through the production insert path
  (score_round, round_to_board, the WHS engine — all genuine); `sandbox_advance`
  runs the sentinel-idempotent month closes + snapshot + daily tick on demand;
  `sandbox_scrap` deletes the league graph then the bot users (cascade).
  The sandbox Pro is a throwaway alias account, never the founder's real
  profile — a round fans into EVERY league its profile belongs to, so
  single-league membership IS the containment.
- **Principle:** production is never a sandbox — so the sandbox is a fenced
  production tenant, not a mock; everything shows its work (§16: bot rounds
  are real rows with real receipts, deletable only by scrap-the-diorama).
- **Benefit:** a whole season becomes a one-hour rehearsal; every future
  mechanic (majors, forfeits, endgame dials) can be walked at season speed
  before a real league meets it.
- **Tradeoffs:** fabricated rounds exist in the prod database — accepted
  because they are structurally quarantined (flagged league, single-league
  bots, alias Pro) and fully scrappable. `auth.users` direct inserts are a
  Supabase-internal shape that could drift; failure mode is a clean error at
  arm time, nothing partial. Sandbox RPCs are deliberately NOT in db-checks
  check 3 (that list is client-called RPCs; these are console-driven founder
  tools — check 3 only fails on missing grants, so omission is safe).
- **CONFLICT check:** grazes the demo-coherence law (the diorama never
  fabricates people) — resolved by scope: the demo is what PROSPECTS see and
  stays fabrication-free; the sandbox is founder-only tooling behind a flag,
  invisible to anyone else. §16 immutability holds: rounds are never edited,
  only scrapped with the whole diorama.

### D66 · The ceremony — a season has to END (close presentation + per-person settlement)
- **Current:** `close_season` writes two all-caps system posts (the story, the
  pot line) and Home swaps in a "Season wrapped · Run it back" card. The scores
  that decided the thing exist ONLY inside the post prose — `c1.score`/`c2.score`
  are computed, rendered into a string, and dropped. The pot is stated by ROLE
  ("CHAMPS $240"), never by person.
- **Problem:** the owner played a full season end-to-end in the sandbox and
  MISSED THE ENDING. On refresh all he saw was the run-it-back emblem and
  "W6/6 · 0 days left". A season that takes months to play ends in a feed item
  you scroll past, and it answers neither question anyone actually asks: who
  won and by how much, and what do I get.
- **Recommendation:** four parts.
  (a) A **takeover** on first open after status flips to `complete` — champion
  big, the margin ("58–50 · by 8"), the tiebreak rung when one decided it,
  runner-up, points king, then the viewer's OWN line: where they finished and
  what they are owed.
  (b) The pot resolves to **PEOPLE**. $240 to a two-golfer squad is $120 each;
  a golfer who is both champion and points king sees ONE summed number, not two
  rows. Money answers "what do I get", never "what does my team get".
  (c) `close_season` **stores** `champion_score` / `runnerup_score` /
  `tiebreak_rung` as columns instead of only rendering them into prose, so the
  margin is structured truth that the ceremony, the recap card, and the
  season-end email all read from ONE place — never parsed back out of a post
  body.
  (d) Re-viewable forever from the League Room and the trophy case; "Run it
  back" sits AFTER the story, earned by it, instead of standing in for it.
- **Principle:** Memory > Statistics — a season should end like something
  happened · everything shows its work (§16 extends to the crown itself: the
  margin and the deciding rung are its receipts) · D39 money posture unchanged
  (the ledger names who owes whom; the app never holds or moves a cent).
- **Benefit:** the ending becomes the artifact the league screenshots, and the
  run-it-back tap follows the feeling instead of replacing it — the single
  strongest lever on whether a league plays a second season.
- **Tradeoffs:** a takeover is an interruption — it shows once per member per
  season, dismisses on tap, and never blocks the app. Per-person money is more
  legible and therefore more consequential: the split must be exactly the
  bylaws' arithmetic with its inputs shown, or it invents a debt between
  friends. Rounding is settled explicitly — shares are computed in cents and
  any remainder rides with the highest seed, so the parts always sum to the pot.
- **CONFLICT check:** none with D39 — still a record, never a bank; no
  "collect" or "pay" affordance, and the settle line stays the D39 wording.
  Trophy law untouched: `award_season_trophies()` already runs inside
  `close_season`, so the ceremony READS trophies and never mints them.

### D67 · The career record — what you've won, and what it paid
- **Current:** `trophies` already records every title with a placement
  (`winner` / `runner_up` / `points_king`, league · major · event), but nothing
  aggregates them — `window.career` is rounds-only (count, best differential,
  average). Money is computed on the client at ceremony time and then
  forgotten: nothing anywhere records what a season actually paid.
- **Problem:** the pilot wants career earnings and bragging rights on the
  golfer card. Two obstacles. There is no aggregate record to read; and
  recomputing historical payouts is APPROXIMATE, because the pot depends on the
  member count at the time and rosters change — a recomputed dollar figure
  would silently drift as people join or leave. An approximate money number
  between friends is worse than no number at all.
- **Recommendation:**
  (a) Record the settlement as FACT at close. `season_payouts` (season,
  profile, cents, reason) is written by `award_season_trophies()`, which
  already resolves the placements and already runs inside `close_season` — so
  no gameplay function is re-plumbed to get it.
  (b) `career_record()` returns titles + an EXACT sum of recorded payouts.
  Never a re-derivation.
  (c) The card LEADS WITH TITLES — cups, crowns, majors, runner-up finishes —
  and carries the money as a secondary line in D39's frame.
- **Principle:** everything shows its work (§16) — a career figure must be a
  sum of recorded facts, not a recomputation that can disagree with what the
  league was told on the day · Memory > Statistics: the card is a record of
  what you have won, not a dashboard.
- **Benefit:** bragging rights that survive roster churn and outlive any single
  league, and the ceremony's numbers become server truth rather than a
  per-device calculation.
- **Tradeoffs:** only seasons closed from here forward get payout rows. Earlier
  completed seasons show their titles with no money attached — honest, and in
  practice there is one such season. A running dollar tally is also the surface
  most likely to read as a wagering ledger to an app reviewer, which is exactly
  why titles lead, the D39 wording stays verbatim, and there is no balance, no
  "pay" affordance, and nothing the app itself moves.
- **CONFLICT check:** none with D39 — a record of what friends settled between
  themselves, never a bank. Nothing here holds, moves, or owes money.

### D68 · The season-end email — the ceremony, delivered
- **Current:** a season ends inside the app. If you don't open Cup Season that
  week, you learn the result from the group chat or not at all. Push exists but
  is curated and easily muted; nothing reaches a lapsed member.
- **Problem:** the run-it-back decision is made in the days AFTER a season
  closes, and that is exactly when engagement is lowest. The ceremony (D66) is
  the right content and the wrong channel for someone who isn't opening the app.
- **Recommendation:** one email per season close, to the league.
  (a) A queue table written by a TRIGGER on `seasons.status → complete`, so no
  gameplay function is re-plumbed and a re-close can never double-send (unique
  on season + kind). A Database Webhook drives the `season-email` Edge
  Function — the same shape the push webhook already uses.
  (b) Content is the ceremony: champion, margin, runner-up, points king, the
  top of the table, and **the recipient's own payout line**. Body is composed
  server-side by `season_email_payload()` so the function holds no game logic.
  (c) **Consent is real.** `email_prefs` (opt-out, default on) in its OWN table
  — deliberately NOT columns on `profiles`, because that table's grant list is
  sealed and an unsubscribe token readable by a league-mate would let them
  unsubscribe each other. Every email carries a one-click unsubscribe on an
  unguessable token.
- **Principle:** the ending is the product's best artifact, and it should reach
  people where they are · consent is not a checkbox we assume.
- **Benefit:** the strongest lever on a second season, aimed at the week it is
  actually decided.
- **Tradeoffs:** this opens a SEVENTH anon endpoint (`email_unsubscribe`),
  breaking a list that has been exactly six since D37. Justified: an
  unsubscribe that demands a login is not an unsubscribe. It is fail-closed,
  takes an unguessable token, and can only ever flip one boolean OFF — it
  cannot enumerate, read, or enable anything. `tests/db-checks.sql` check 2
  moves 6 → 7 in the same commit, and CLAUDE.md's list is updated with it.
  Bot and placeholder addresses are filtered so a sandbox league can never mail
  anyone.
- **CONFLICT check:** collides with D37's "exactly six anon endpoints", named
  and accepted above rather than smuggled in. No conflict with D57 — the email
  carries no ids, and its links are tokens.

### D71 · League cancellation with consent (a started league can be ended)
- **Current:** `delete_league` refuses any started league ("a live league cannot
  be deleted") and is commissioner-only. Correct as a guard, but it leaves no
  path to end a league once it's under way — a real pilot Pro asked to cancel a
  started test league and there was no mechanism.
- **Problem:** a league that shouldn't continue (a mistake, an abandoned test, a
  crew that folded) is stuck live forever, and if there's a betting pool the
  buy-ins are in limbo.
- **Recommendation:** a Pro-initiated cancel gated by the money at stake. A FREE
  league (no buy-in) the Pro cancels alone, immediately. A MONEY league requires
  UNANIMOUS member approval; any single decline kills the request (the Pro can
  reopen or withdraw). On execution the league is fully removed (league, season,
  memberships, buy-ins, squads, board) — but every player's actual golf ROUNDS
  survive on their profile (rounds are global; the league is only a lens). Each
  member is owed their own paid buy-in back — a NOTICE, shown at consent and in
  a cancellation email; the app moves nothing (D39). The Pro then lands on
  "start another league".
- **Principle served:** the Pro runs the league (they can end it) · consent
  protects money (nobody loses a buy-in they didn't agree to) · §16 the record
  book is sacred (a COMPLETE season still cannot be cancelled) · Memory: a
  cancellation leaves each player their rounds.
- **Benefit:** a started league is no longer a dead end; a betting pool unwinds
  cleanly with everyone made whole.
- **Tradeoffs:** unanimous-for-money means one silent member blocks a cancel —
  chosen deliberately over a majority that could cancel someone out of their
  buy-in. The cancellation email fires from a self-contained snapshot written
  BEFORE the delete (its own table, no FK to the league), so the async send
  never reads deleted data. Four new authenticated RPCs
  (request/vote/withdraw/status) → `tests/db-checks.sql` check 3 moves 89 → 93
  in the same commit; no new anon surface.
- **CONFLICT check:** none with §16 — a completed season is still un-cancellable
  (the record book). None with D39 — the refund is a settle-up notice, never a
  transfer the app performs.
- **OPEN (parked, NOT built):** the Pro season pass (monetization, Stripe
  parked) — when it goes live, the pass must follow the ACCOUNT, not the league,
  so cancel-and-restart never forfeits it. That is what the "start another
  league" prompt is for. Deferred to the Stripe design; no refund path built for
  a charge that doesn't exist yet.

### Bundled with D71 · drop brand-name payment references (Venmo → generic)
- **Current:** several money posts say "settle on Venmo".
- **Change:** generic settle-up language everywhere ("settle up between
  yourselves", "the Pro collects the pot"). Not a mechanic change — copy only,
  logged here because it rides the D71 money-language pass. `close_season`'s pot
  line already reads this way (D66); the rest are brought in line.

### D72 · 9-hole rounds are a first-class post (not 18 with blanks)
- **Current:** the engine already scores a 9-hole round — enter one nine and it
  computes `((gross − rating/2) × 113/slope) × 2` and halves the points ("half
  value"), `holes_played = 9`. But the CHOICE is buried: a small "Front 9"
  toggle appears only in hole-by-hole mode, the par-entry defaults to 18, the
  post course-search never reads the API's `number_of_holes` (which the tee data
  carries), and the tee loader hard-requires 18 holes — so a real pilot playing
  9 at Palo Verde was forced to enter 18 pars and never found the escape hatch.
- **Problem:** posting a nine is a normal thing golfers do (an executive course,
  a quick after-work nine, a 9-hole club), and the app makes it feel unsupported.
- **Recommendation:**
  (a) A first-class **"18 holes / 9 holes"** choice on the post card, visible
  before you enter anything, in both entry modes.
  (b) **Auto-detect from the API:** when the picked tee is `number_of_holes = 9`,
  default to 9-hole entry and load ITS pars.
  (c) **Rating stays an 18-hole-EQUIVALENT** in the field, so the scoring math is
  untouched: a real 9-hole tee stores 2× its 9-hole rating (recalc's `rating/2`
  recovers it exactly), its slope goes in as-is. Playing a partial nine of an
  18-hole course keeps the `rating/2` approximation (the standard WHS-lite move
  when only an 18-hole rating exists — e.g. Palo Verde, which the API holds as an
  18-hole par-60 course).
- **Principle served:** meet golfers where they play (a nine is a real round) ·
  the handicap engine stays WHS-honest (a 9-hole differential is a doubled
  half-rating differential, half the points) · everything shows its work (the
  receipt already says "Nine holes · half value").
- **Benefit:** the friction that made a pilot enter 18 fake holes is gone;
  genuine 9-hole courses post correctly with their real rating.
- **Tradeoffs:** front-vs-back of a partial nine is treated as cosmetic — the
  pars only prefill the grid (the differential is driven by gross, not par), so
  a back-nine player adjusts their scores and the number is still right. The
  rare intersection (an 18-hole course that ALSO carries a distinct 9-hole rated
  tee) does NOT swap in that separate rating on the manual toggle — it uses the
  `rating/2` approximation; genuine 9-hole COURSES get their real rating via the
  auto-detect. Client-only, no migration, no mechanic-band change (the points
  bands are untouched; only entry + rating-source change).
- **CONFLICT check:** none. §16 holds (rounds still immutable, the differential
  is still computed by the trigger from stored facts). No band/points change.

### D73 · 9-hole LIVE rounds (the tee sheet learns to play a nine)
- **Current:** D72 gave the POST flow 9-hole support, but the LIVE round (the
  shared in-person scorecard: match play / Wolf / skins, live settlement) stayed
  hardwired to 18. A pilot playing a nine at Palo Verde got an 18-hole card with
  no way to declare a nine.
- **Problem:** a nine is a normal round, and the live round — the app's most
  social, money-carrying surface — pretended it didn't exist.
- **Recommendation:** thread ONE hole count (`state.live.holes`, 9|18) through
  the whole live round. A 9/18 picker on the setup sheet (auto-set to 9 when a
  9-hole tee is picked, or the front nine of an 18-that-is-really-9 like Palo
  Verde); the course loader accepts a 9-hole tee and re-ranks its stroke index
  1-9; every settlement + nav loop reads the count, not a literal 18.
- **Server:** already 9-ready — `finish_live_round`/`claim_round` detect a
  9-hole card (front nine filled, back nine null) and post it half-value (D72).
  The ONE thing starving it was the client hardcoding `nine_rating:null` into
  the tee-off snapshot; it now carries the real 9-hole rating (a 9-hole tee's
  own, or half the 18-hole rating). NO schema change — the count rides the
  jsonb course_snapshot; scores stay 18-wide with the back nine null.
- **Settlement correctness (the money part):** a nine allocates HALF the course
  handicap over the nine holes (SI ranked 1-9); match play closes out against 9
  remaining (a 5&4 on nine ends at the 5th); Wolf's comeback falls on holes 8-9;
  skins carries die at 9. Verified: on nine, CH 20→10, strokes wrap over 9,
  the match closes at 5&4, skins tallies over 9, and the finish gate stops
  reporting holes 10-18 as "missing".
- **Principle served:** meet golfers where they play · the handicap engine stays
  WHS-honest · everything shows its work (settlement reads the same hole data).
- **Tradeoffs:** the 9=front-nine-of-18 convention keeps arrays 18-wide (no
  refactor, crash-resume guards untouched) at the cost of treating front-vs-back
  as cosmetic — pars only prefill the grid, so a back-nine player adjusts scores
  and the gross (hence the differential) is still right. Client-only, no
  migration.
- **CONFLICT check:** none. §16 holds (rounds immutable, differential computed
  from stored facts). The Ryder event (`resolve_session`) is unaffected — it
  scores posted rounds via their differential, which D72 already stores at
  18-equivalent value.

### D74 · Sunningdale — the live game for groups without handicaps
- **Current:** the tee sheet runs three games (Match Play, Wolf, Skins), all
  handicap-driven: strokes off the low man, allocated by stroke index. A group
  with unestablished or distrusted indexes (sandbaggers, guests, new golfers)
  has no game that feels fair.
- **Problem:** the pilot asked for Sunningdale (Golf Digest, 2026-07-21) — the
  match-play variant built for exactly that group: NO handicaps, the equalizer
  is positional. Enter a hole 2 down and you get 1 stroke on it; 3 down, 2
  strokes; N down, N−1. The match can never run away.
- **Rule interpretation (the article leaves one point implicit):** "the very
  first time one side goes two down… a stroke on the next hole" scales per its
  own examples (3 down → two strokes, 4 down → three). We implement the only
  reading that satisfies the stated goal ("never lets you get in a hole you
  can't crawl out of"): on EVERY hole, the trailing side receives
  max(0, deficit − 1) strokes, deficit measured entering the hole. A one-time
  stroke would let the match run away again the hole after. In teams (2v2 best
  ball), each player on the trailing side receives the stroke(s).
- **The bank (the money layer, from the article's variation):** the stake is a
  UNIT. A side that wins a hole AND is strictly ahead after winning banks one
  unit; a qualifying win by the other side pulls one unit back out (through
  zero into their own favor). Wins that square the match or narrow a deficit
  bank nothing. One signed integer models it: +N = side A holds N units.
  Settled at finish alongside the match result; $0 = bragging rights, same as
  every game.
- **Not shipped (future dials):** the Nassau overlay (front/back/overall — our
  Match Play doesn't do Nassau either) and the "Colonel Dallmeyer" variation
  (strokes only at 3 up, until back to 1 up).
- **Scope:** client engine + UI alongside match/wolf/skins, one migration
  widening live_rounds' game CHECK ('sunningdale'). 9-hole aware (D73:
  closeout against liveHoles()). Handicaps deliberately ignored — no
  recomputeStrokes, no SI; that's the game's whole identity.
- **Principle served:** meet golfers where they play — the no-handicap group is
  exactly the guest-heavy, index-less foursome the guest-claim funnel courts ·
  §2.2 the first-tee argument, settled: the strokes are on the scoreboard, not
  negotiated.
- **Benefit:** the one game every mixed group can play fairly on day one, before
  a single index exists.
- **Tradeoffs:** a fourth game on the picker (seg gets tighter on small
  phones); the bank's owner semantics are subtle — the status card must always
  name who holds it and what a win does.
- **CONFLICT check:** none. Live games never touch season scoring (§13.2);
  cards still post as ordinary rounds through the same finish path.
- **AMENDMENT 2026-07-27 · the display name is "Sunningdale Rules."** The bare
  word shipped as the label everywhere, and in the pilot's own group thread it
  read as the VENUE: the settlement message opened "Sunningdale:" while the
  card's footer said ARIZONA BILTMORE CC. Sunningdale is a real and famous
  course; a mode named only after it will be misread forever. Second, sharper
  reason: iOS data detectors parse `Word:` at the head of a message as a URI
  scheme and percent-encode everything after it — the pilot's text arrived as
  `Sunningdale:%20Jerecho%20Fischbeck%20&%20Jade%20def.…`, reproduced exactly
  from the rule (space → %20, `·` → %C2%B7, `&` legal so it survived, the
  second colon → %3A). A two-word name contains a space, which is illegal in a
  scheme, so the rename also defuses the mangle. UI-level change: the stored
  key stays `'sunningdale'` in live_rounds.game, in the game CHECK constraint
  (20260725220000), and inside game_result JSONB, which finish_live_round
  branches on. No migration — a database migration for a display string would
  be a bad trade, and posted board rows are immutable (§16) so history could
  never be back-renamed anyway. Logged here rather than as its own entry
  because the mechanic is untouched; recorded so a future session doesn't
  "fix" the label back.

### D75 · Everyone for themselves — the 4-player solo modes
- **Current:** four players picking Match Play or Sunningdale are silently a
  2v2 (D74's court). The pilot: "2v2 or everyone v everyone" — the choice
  itself was missing.
- **Recommendation:** with 4 players and a team-capable game, an explicit mode
  choice — **2v2 teams** (the court) or **Everyone for themselves**:
  · **Match play solo = round-robin singles.** Six simultaneous 1v1 matches
    (every pairing), each scored hole-by-hole NET exactly like today's singles
    (strokes off the group's low man, SI allocation), none close out early.
    The card is a ladder (per-player matches up/down); each mini-match settles
    at the stake, winner from loser. The established real-world 4-way format.
  · **Sunningdale solo = deficit strokes vs the leader.** Own ball; a hole is
    won by OUTRIGHT low net (any tie halves to nobody). Entering a hole, each
    player gets max(0, gap_to_leader − 1) strokes. The bank keeps its
    single-owner walk: a qualifying win (you lead outright after winning)
    grows your bank or pulls one unit from the current holder, through zero.
    Liability is per player: at settle, each non-owner owes bank × unit.
  · **⚑ OURS, flagged:** the article defines Sunningdale as strictly 2-sided.
    The solo variant is OUR extension of its principle (the match that never
    runs away). Faithful in spirit; the rules above are the house's.
- **Principle:** §2.2 — the first-tee argument settled on the scoreboard ·
  meet the group as it actually bets (a 4-ball is not always two teams).
- **Tradeoffs:** the RR card is a ladder, not a single banner — six tallies
  compressed to per-player records with the pair detail behind the numbers.
  Solo Sunningdale's per-player bank liability is steep (3 payers) and is
  therefore stated on the card, never discovered at settle.
- **CONFLICT check:** none — live games never touch season scoring (§13.2);
  cards post through the same finish path; mode rides game_config (no schema
  change, no new game enum value).

### Casing policy · the SQL de-shout is paid down OPPORTUNISTICALLY (2026-07-24)
- **The principle stands (D66):** the scoreboard voice belongs to typography,
  not to stored data — capitals-as-data destroy proper nouns ("SANDY WEDGE" →
  no way back to "Sandy Wedge"). The right end-state is generators that store
  NATURAL case, and any surface wanting the scoreboard look uses CSS
  `text-transform`.
- **But the client registry (a6a3b23 + the b7 audit hardening) already fixes
  every VISIBLE symptom** — new posts and legacy, names/courses/Ryder teams,
  with word boundaries and a common-phrase denylist. `easeCaps` softens the
  all-caps bodies; `csLearnNames` restores the proper nouns it has loaded
  (own name, all-membership rosters, active squads, board courses, event
  teams, the 21-day circle).
- **Ruling (owner, 2026-07-24): do NOT big-bang the de-shout.** Rewriting all
  ~15-20 post generators (round_to_board, close_month, settle_major,
  resolve_session, finish_live_round, the major/forfeit posters …) is a large,
  mechanical, RISKY reproduction of consequential security-definer game
  functions, for ZERO additional user-visible benefit (the registry already
  covers it) and WITHOUT retiring the registry (legacy posts stay uppercase
  forever). It is engineer-satisfying and golfer-invisible.
- **How the debt gets retired:** whenever a generator is already being
  rewritten for another reason, de-shout THAT one in the same migration —
  compose its body in natural case so `easeCaps` (which no-ops on mixed case)
  passes it straight through. Near-zero marginal cost, no big-bang risk.
  close_season (D66) is the first one done; the rest fall as they're touched.
  A future session must not treat the de-shout as owed work, nor skip it when
  already inside a generator.

### D69 · RSVP is for the invited — visibility stays, external RSVP goes
- **Current:** a scheduled round is visible to the owner's whole league
  (can_see_round clause 4, "shares any league"), and RSVP capability is bundled
  with visibility — set_round_rsvp gates ONLY on can_see_round, so any
  league-mate who can see a round can set In/Maybe/Out on it. This was D17 /
  tee-sheet arc Stage 2's intent ("tagged players AND league-mates who can see
  it set In/Maybe/Out"), built when the tee sheet was imagined as an open
  book-a-tee-time board.
- **Problem:** a pilot found it confusing that they could RSVP to a league-mate's
  round they weren't part of. The owner's read (accepted): rounds are booked at
  the COURSE, not in this app, so an RSVP from someone you didn't invite is
  noise, not signal. The visibility itself is fine and even useful ("see where
  people are playing, if they share it") — it is the WRITE that doesn't belong.
- **Recommendation:** keep visibility exactly as is (whole-league, unchanged),
  restrict the RSVP WRITE to the owner and the players they TAGGED. set_round_rsvp
  gains an owner-or-tagged guard; the client hides the In/Maybe/Can't controls
  unless the round is yours or you're tagged. A non-tagged viewer still sees the
  round — where and when — with no RSVP affordance.
- **Principle served:** IA legibility — a control should mean something; an RSVP
  that changes nothing real (the tee time lives at the course) is a false
  affordance. The social-visibility loop (see what your crew is playing) is
  preserved; only the meaningless write is removed.
- **Benefit:** the tee sheet reads honestly — "these are the people the host
  invited," not "anyone in the league clicked a button."
- **Tradeoffs:** narrows a capability some might have used as a lightweight
  "I might join." Acceptable: if you want someone on your round, tag them; that
  is the invite, and it is one tap. Existing RSVP rows from non-tagged members
  are left in place (harmless, and there is negligible pilot data) — the change
  is write-forward.
- **CONFLICT check:** this REVERSES tee-sheet arc Stage 2 ("league-mates who can
  see it may RSVP") — a deliberate amendment, logged here, not a silent drift.
  D17's core loop (see your crew's plans, pile onto a tee time) survives via the
  unchanged visibility; only the confirm-without-invitation half is retired. No
  conflict with the base-table RLS (already owner-only; the rule lives in the
  SECURITY DEFINER RPC).

### D70 · A bragging-rights league shows no pot
- **Current:** a $0-buy-in league still surfaced the pot everywhere a staked
  one does — the gold "On the line" bar (reading "$0 · CHAMPS $0 · …"), the Pot
  segment tab, the pot stat tile — even though the ceremony (D66), the bylaws,
  and the pot pane already suppress money for $0.
- **Problem (pilot):** "if this is just for points does the pot section need to
  be displayed?" A row of $0s is noise, and it makes a bragging-rights league
  look like a mis-configured money league.
- **Recommendation:** when stake is 0, hide the money-ACTION surfaces (the
  on-the-line bar and the Pot tab) and let the label carry the meaning — the
  stat tile reads "None / Bragging rights", the bylaws read "None · bragging
  rights". Absence by design, not by breakage. Toggled both directions so
  switching to a staked league restores them.
- **Principle:** the money layer is optional (monetization revision,
  2026-07-12: identity + play are free; the pot is a league's own affair) —
  a league that opts out shouldn't carry its chrome. D39 posture unchanged.
- **Benefit:** a points-only league reads as a first-class choice.
- **Tradeoffs:** none of consequence — purely display; every scoring and
  standings surface is identical. CONFLICT check: none.

### D76 · Charcoal — the identity goes dark, and heat becomes a semantic
- **Current:** light-first UI (D35: "daylight is where golf happens"), gold-
  forward brand accent (v23.106 pass), dark available one tap away in
  Appearance. Momentum and pressure exist in the data (deltas, streaks, month
  close, carries) but have no visual dimension — a ▲2 week and a ▼2 week dress
  identically.
- **Problem:** the App Store home-screen exploration (2026-07-26, artifact
  studies) landed on an identity the current skin can't express: "Charcoal" —
  near-black ground, slate greys for everything stable, heat (amber→ember→red)
  as the ONLY color, reserved for momentum and pressure. Pilot owner approved
  it platform-wide after four palette studies and a theme study.
- **Recommendation:** three linked changes.
  1. **Charcoal default.** Ground #0C0D0F (already the meta/favicon/legal
     value — the three coexisting dark grounds converge here), cards #17191C,
     elevated #1F2226, ink #F0F2F3, slate #8E979E. Light theme SURVIVES intact
     one tap away; only the shipped default flips (cs_theme default 'light' →
     'dark').
  2. **Two metals.** Ember #FF5A2E / amber #E9A23B = LIVE heat: momentum
     chips, streak tags, carry banners, the pressure meter, action surfaces
     (post round, live CTAs). Gold #E9BE62 keeps its meaning = EARNED honor:
     trophies, settlements, recap artifacts, ceremony faces. Heat cools into
     gold when it's banked. The D30 artifact face stays gold on charcoal.
  3. **Heat grammar (new visible mechanics).** Temperature is semantic, never
     decorative: stable = slate; momentum ramps warm→hot; cooling reads slate,
     never red-means-bad. Ships as: heat-coded weekly deltas on standings,
     streak tags on round stories ("3 under his number"), a month-pressure
     burn-down meter on the number-to-beat surface, carry-heat on live skins.
     One pulse per screen, reserved for the hottest thing. All computed from
     existing data (rounds, month_rank, close dates) — no schema change.
  Ceremonies: .room-dusk becomes the EMBER-LIT room (same charcoal family,
  warmer + deeper) so entering an honor surface still feels like crossing a
  threshold when the utility theme is also dark. Serif stays the existing
  Charter/Iowan/Palatino slot ("memory & honor") — no new font, no CSP change.
- **Principle served:** everything shows its work (§16) extended to time —
  the app now shows not just where you stand but where you're HEADED, and the
  season's pressure curve (month close → Cup Final) becomes something you can
  see. One identity, ownable in the category.
- **Benefit:** the standings breathe between rounds; the shareable artifacts
  (already circulating in PIGL) keep their earned-gold face while the app
  around them sharpens; dark default = the evening-scroll and OLED case.
- **Tradeoffs:** third accent era in a month (green → gold → ember+gold) —
  accepted as the cost of finding the identity before launch scale; a mid-beta
  visual flip for PIGL testers — mitigated by the icons/og already needing
  regen (still green-era art). Light theme retained costs double-maintenance
  on new surfaces — accepted, D35's daylight rationale still real on course.
- **CONFLICT (named):** SUPERSEDES D35's light-FIRST default (light-AVAILABLE
  survives — the tap remains, the direction flips). AMENDS the v23.106
  gold-forward pass: gold narrows from "the brand accent" to "the earned
  metal"; ember takes the live layer. Both deliberate, neither silent.

### D77 · The result outranks the names on every settlement artifact
- **Current:** one string carries every settlement everywhere. A game builder
  returns `story`, and that single value is (a) the board row, (b) the OS
  share-sheet body, and (c) the push notification body. Its shape is uniform
  across all five games: `FORMAT: full name, full name, full name · config
  echo · ledger`. The result — who won, by how much — arrives last or, in
  three builders, not at all. Each consumer then truncates the tail: the share
  sheet at `.slice(0,120)`, the board at `left(…,200)`, push at
  `body.slice(0,140)` (implemented twice, independently). The tail is where
  the result lives, so the machinery amputates precisely the payload.
- **Problem observed (pilot, 2026-07-26 Biltmore round, then a full sweep):**
  the owner texted a settled 2v2 to his group and neither the message nor the
  page it opened answered "who won and by how much." The message was 115
  characters, named four people by full legal name (two of them twice), led
  with a course-sounding label, and buried `3&2` in the middle. The sweep
  found the same defect in 128 outbound strings across five surfaces, and
  three worse cases behind it: plain Match Play ships a settlement with NO
  winner and NO score while `winner` and `status` sit unused two lines above
  it (index.html:7843); solo Sunningdale runs 158 characters and truncates
  mid-word through the bank owner's name; and the round-robin story is a
  standings table that cannot resolve a tie. This is not a copy problem that
  copy can fix — one string cannot serve a feed row (which has the app's
  context around it) and a text message (which has none).
- **Recommendation:** rank every settlement artifact by what the reader came
  for, and split the string by destination.
  1. **Result first, always.** Winner and margin lead the sentence. Format
     labels, configuration echoes ("no handicaps"), and ledgers follow or are
     dropped. `Jerecho & Jade beat Will & Isaak 3&2` — not `Sunningdale:
     Jerecho Fischbeck & Jade def. …`.
  2. **`story` and `share` are different fields.** `story` stays the feed row
     and keeps full names and the ledger. `share` is authored for someone
     else's thread: first names, ASCII only, one clause, under ~60 chars, no
     leading `Word:`. Push gets its own authored `push_title` (the result) and
     `push_body` (the context) rather than forwarding a feed row to a lock
     screen. No consumer truncates an authored string, so the caps become
     backstops instead of editors.
  3. **First names leave the app; full names stay in it.** A shared helper on
     each side of the wire (client `fn1()`, SQL `first_name()`), never
     ad-hoc in a template.
  4. **Engine vocabulary is banned outbound.** "DIFF 18.9", "bank: 6 units",
     "no handicaps", "fewest rounds used", "PvI" — none of these reach a
     recipient. They are receipts, and receipts live behind the link.
  5. **The link carries the detail; the message carries the hook.** A share
     body that restates the card is spending the reader's attention twice.
- **Principle served:** everything shows its work (§16) — a settlement is a
  claim about who owes whom, and a claim nobody can read is not shown work.
  Also the product-vision filter: the shareable artifact is the entire
  marketing surface, and it currently arrives as a percent-encoded run-on.
- **Benefit:** the answer lands in the first three words on every surface a
  friend sees. The share stops being something the sender has to explain.
- **Tradeoffs:** two fields where there was one — a new builder that forgets
  `share` falls back to a feed row, so the fallback must itself be a sentence
  ("The match is settled"), never `side_a vs side_b`. Board rows get shorter
  and lose the inline ledger; the receipt is one tap away, which is the §16
  bargain everywhere else in the app. Push and email fixes need migrations
  (authored columns, a SQL first-name helper); the client half ships alone
  and is worth shipping alone.
- **CONFLICT check:** none upward. Does not touch scoring, settlement math, or
  the immutability of posted rows — historical board posts keep their original
  text by design (§16) and are not rewritten. AMENDS D2's ban on engine
  vocabulary by extending it from in-app surfaces to every outbound channel
  (push, email, share sheet, clipboard, link previews), where it was never
  explicitly enforced and where three of the worst violations shipped.

### D79 · Round robin settles per match — $5 a match means $5 a match
- **Current:** the 4-player solo Match Play variant (D75) scores six 1v1
  pairings, records a W-L-H per golfer, accepts a stake, and prints "$5 a
  match" on the board — then moves no money. `rrResult()` is the only
  settlement builder that returns no `transfers`, so the finish sheet had
  nothing to show. Until 2026-07-27 it fell through to Wolf's ledger branch and
  rendered "ALL SQUARE — NO MONEY MOVES" on staked rounds where everybody owed
  somebody; that now states the rate instead, which is honest but still leaves
  the group doing the arithmetic on a napkin.
- **Problem:** the app takes a stake, tells the league the rate, and then
  declines to say who owes whom — on the one game where the answer is least
  obvious, because six overlapping results have to be reconciled. Every other
  game on the tee sheet settles itself. §16 says nothing shows a figure without
  a path to the rounds behind it; here there is no figure at all.
- **Recommendation:** each pairing is its own bet at the declared stake. A
  golfer's net is `(wins − losses) × stake`; halved pairings move nothing.
  - Chosen because it is what the phrase already on the board MEANS. "$5 a
    match" is not a rate for something else — it is the whole rule, and the
    copy and the math finally agree.
  - It is net-zero by construction: every pairing contributes +1 to one player
    and −1 to another, so the ledger sums to zero across the group with no
    balancing step. That drops it straight into `settleTransfers(pts, val)`,
    the same minimized-transfer helper Wolf and Skins already use — no new
    settlement engine, no new rounding rule, nothing new to get wrong.
- **Rejected:** paying out on overall RECORD like a tournament (top two, or
  champion-takes-all). It needs a payout table, a tie rule, and a judgement
  about whether 3-0-0 should beat 2-0-1 by more than one unit — a lot of new
  mechanic for a casual side game, and nobody at a first tee says "we'll pay
  out top two on record." Also rejected: settling per HOLE, which is Skins.
- **Principle served:** everything shows its work (§16) — a settlement is a
  claim about who owes whom, and this game was making the claim's premise (a
  stake) without ever producing the claim. Also meet golfers where they play:
  per-match is how the bet is actually spoken.
- **Benefit:** the one tee-sheet game that took money and stayed silent now
  produces the same settlement card as every other game.
- **Tradeoffs:** a golfer can lose every pairing and be down 3× the stake,
  which is a bigger swing than the headline "$5 a match" suggests to someone
  who has not thought it through — the finish sheet states the transfers
  explicitly, which is the mitigation. No hole strip: six simultaneous matches
  have six different answers per hole, so any single 18-cell row would be a lie
  about which match it depicts (D78's ledger stays deliberately absent here; if
  round robin ever wants a visual it is a 4×4 grid of who beat whom, decided on
  its own merits).
- **CONFLICT check:** none. Does not touch scoring, the season, or any other
  game's settlement. Live games never reach season points (§13.2).

### D78 · The settlement becomes an artifact — the hole strip and the card
- **Current:** a settled game leaves the app as text plus a URL. The link opens
  a page that states the result in a sentence and lists four gross scores. Two
  canvas artifacts exist and neither covers this: `drawRecapCard` renders a
  ROUND, `drawMajorCard` renders the major jug. Match play, Wolf, Skins and
  Sunningdale Rules — every game the tee sheet actually runs — have no image at
  all. The per-hole record that every engine computes is discarded at finish:
  `game_result` stores the outcome and the ledger, never the shape of the round.
- **Problem observed (pilot, 2026-07-26):** "hard to tell who won and by how
  much… less words and more visuals." D77 fixed the words and stopped there:
  the result now leads every string, but a settlement is still ONLY strings. The
  deeper miss is that "by how much" is a poor summary of a match — 3&2 says the
  margin and nothing about the round. The group played sixteen holes with a
  four-hole swing in the middle and none of that survives the finish. Meanwhile
  the shareable artifact is the app's entire marketing surface (D77, product
  vision) and for the flagship game it is a hyperlink.
- **Recommendation:** two artifacts over one new piece of stored data.
  1. **The hole ledger is snapshotted at finish.** Each engine already walks the
     holes; the winner of each hole is a byproduct it currently throws away.
     The engines return it, the result builders put it in `game_result.holes`,
     and it is written once and never recomputed. NOT re-derived by a new
     helper reading `netOf`/`holeDone` — that would be the second source of
     truth CLAUDE.md forbids, and it would silently disagree with the engine
     the moment a game's rules change (Sunningdale's positional strokes make
     this concrete: hole winners there are net of a deficit the engine tracks).
     Shape is game-agnostic: cells of `a` | `b` | `h` | null for two-sided
     games, a player index for the solo modes, plus the hole the match closed.
  2. **The hole strip.** Eighteen cells reading left to right: heat for the
     side that took the hole, slate for the other, hollow for halved, faded for
     never played, with the closeout marked. It renders on the public
     settlement page and in the finish recap sheet. This is where "by how much"
     stops being a number and becomes a shape — the run of four, the collapse,
     the hole it ended on. Highlights ("won four straight, 5–8") are derived at
     render from the same cells, never stored: a stored highlight is a second
     source of truth about a round nobody can re-examine.
  3. **The settlement card.** A canvas PNG in the family of the existing two,
     same fixed dark face (an artifact ignores the viewer's theme — D30), the
     margin at hero scale, the two sides, the strip, and the money. Shared as a
     file through the same `navigator.share({files})` path the round recap uses.
- **Principle served:** everything shows its work (§16) — a settlement asserts
  who owes whom, and until now the evidence lived only on the phone that kept
  score. The strip is the receipt for the margin. Also the Cup Season Test: the
  artifact has to be worth sending on its own, without the sender explaining it.
- **Benefit:** the answer to "who won and by how much" is visible before a word
  is read; the round gets a memory beyond its final number; the funnel gains the
  one artifact the flagship game never had.
- **Tradeoffs:** `game_result` grows by roughly 18 cells per round — trivial in
  a JSONB column already holding the ledger. **`share_info` curates the
  settlement payload through an explicit key list (`20260723230000`, v_res),
  so the public page cannot see `holes` until a migration widens it** — the
  in-app strip ships client-only, the public strip needs a db push, and the two
  halves must be skew-safe in both orders (the page renders strip-less when the
  key is absent; the client writes the key whether or not the page can read it
  yet). Rounds settled BEFORE this ships have no ledger and never will — every
  surface degrades to the current text rather than rendering an empty strip.
  A third canvas card is a third thing to keep on-brand when the identity moves
  (it already moved twice this month — D76).
- **CONFLICT check:** none. No scoring, no standings, no settlement math
  changes — the strip reports what the engines already decided. EXTENDS D77:
  that entry said the link carries the detail and the message carries the hook;
  this decides what "the detail" is made of.
- **AMENDMENT 2026-07-27 · the preview is the card.** D77 named link previews
  as an outbound surface and nothing was done about them: every share link
  served the same seven static head tags, so a settled match, a career round
  and a whole season previewed identically as the brand image. A scraper runs
  no JavaScript, so `document.title` set at render time reaches nobody — the
  tags have to be right in the bytes we serve. A Netlify Edge Function
  (`netlify/edge-functions/share-preview.ts`) rewrites them per token on
  `/?share=`, reading the same anon `share_info` the public page calls.
  Fail-open by construction: bad token, dead RPC, revoked share or any thrown
  error serves the untouched origin HTML, and a request without the parameter
  returns before any work — a broken preview is a bad day, a broken app is an
  outage.
  **The privacy call, made deliberately:** for the image to exist for a
  scraper it must be at a public URL BEFORE the message is sent, so tapping
  "Share the settlement" now publishes the rendered card to the public bucket
  at `shared/{token}.png`. This is the same bargain D60 already struck for
  round photos travelling with a share, and the same escape hatch applies —
  `revoke_share` kills the token, a fresh share mints a new one, and revoked
  copies stay dark. It is opt-in per share and it is the act of sharing that
  publishes; nothing is uploaded by settling a round. A card that fails to
  upload costs the brand preview and nothing else, because the edge function
  HEADs the object before pointing a scraper at it — a 404 og:image renders
  as a BROKEN preview, which is worse than a generic one.
  Side names reach an HTML attribute here, so everything interpolated is
  attribute-escaped at the edge; the anon key is parsed from the HTML rather
  than hardcoded so it can never drift from the client, and the service-role
  key must never appear in an edge function.

---

## Batch 14 — 2026-07-27, the pre-launch vocabulary lane (UX)

### D80 · One noun for the golfer-to-golfer bond: buddies
- **Current:** the mutual, accepted tie between two golfers ships under four
  names, sometimes two on one screen. Home calls the pending state a
  **"Friend request"** (index.html:9470); the settled state chip says
  **"Buddies"** (index.html:11728); the section that lists them is headed
  **"Your crew"** (index.html:2618); the push says **"wants in your crew"**.
  The empty state manages both at once — "No buddies yet. Search up top to add
  your crew." The Tour Card's own subtitle is "THIS IS HOW YOUR CREW SEES YOU"
  (index.html:11939) and Card & settings says "Your card is what the crew
  sees" (index.html:12045). Underneath, the schema calls it `is_friend` and
  the round-card tag reads `BUDDY`. A separate stray: four live strings send
  the user to the fourth tab as **"your profile"** (index.html:14652, 15045,
  15210, and an unnamed jump at 9375) — a fifth name for a surface the nav
  labels "You".
- **Problem observed (orientation design pass, 2026-07-27):** the work that
  surfaced this was writing the welcome walkthrough. An orientation has to
  name the relationship once, and there is no name to pick — whichever of the
  four it uses, it contradicts three shipped screens on the way to the tab it
  is pointing at. That is the no-tutorial metric failing in the most literal
  way available: the tutorial itself cannot be written. The four names are not
  regional variants of one idea either; "friend" is the social-network frame
  the product has otherwise refused, and "crew" is load-bearing elsewhere.
- **CONFLICT (resolved by expiry, not by overruling):** D11 ruled "crew = the
  people" and beat the panel's proposal to kill the noun, explicitly on level-3
  IA authority — **because Crew was a nav tab**. It no longer is. IA P5 retired
  the Crew tab and moved buddies into You; the shipped bar reads Home /
  Clubhouse / ⊕ / You. D11's ruling is not overturned here, it is spent: the
  premise that made "crew" win has expired, so the noun reverts to open. Note
  this log's own hierarchy line (§3, "Home / Crew / ⊕ / You") was stale and is
  corrected in the same commit — a decision that cites an IA must cite the
  shipped one.
- **Recommendation:** **buddies**, everywhere, in all three grammatical jobs —
  a person ("a buddy"), a collection ("your buddies"), and the round-card tag
  (`BUDDY`, already correct). Retire "crew" wherever it NAMES THE RELATIONSHIP
  or labels the buddy list. Retire "friend request" for "buddy request". Retire the four
  "your profile" strays for the nav's own word. `is_friend` stays — schema
  words are not user words (D12's rule) and a column rename buys nothing.
  Chosen over "regulars" and "playing partners" because it is the only
  candidate already in the product: it is the shipped round-card tag, and it
  is the vision doc's own word for persona 3, the buddies trip. The fix is
  therefore a **deletion of three strays, not a migration to a fifth name** —
  the cheapest possible resolution and the only one that touches no tag.
- **Principle:** #2 Low Friction (the no-tutorial metric); D11's own law that
  each noun means one thing; the anti-generic canon, which is the reason
  "friend" loses.
- **Benefit:** the relationship can be taught in one sentence, which is the
  precondition for the orientation screen existing at all. Every screen agrees
  with the one before it.
- **Tradeoffs:** copy sweep only — no schema, no routes, no tags. "Buddies"
  reads a shade more casual than "the Pro" and "the long war"; accepted, on
  the grounds that it is what golfers actually say and that the alternative is
  a word the product does not already own.
- **Rider — the noun is half the fix.** Tapping a golfer's name opens their
  Tour Card, which has **no add action at all** (index.html:11899-11939); the
  comment at index.html:12303 claims it "just links there" and the rendered
  sheet contains no such link. So the obvious gesture dead-ends, and the copy
  must route people to the header magnifier or the You tab instead. Renaming
  the noun without fixing that leaves the sentence true and the gesture broken.
- **AMENDMENT 2026-07-27, from doing the sweep.** The draft above said retire
  "crew" from copy *entirely*. Reading all 163 candidate lines showed that
  overstates it: "crew" does two jobs, and only one is the defect.
  **Retired (the relationship sense):** it named the buddy list and the buddy
  bond — `Your crew`, the `Crew · N` section head, `THIS IS HOW YOUR CREW SEES
  YOU`, "what the crew sees", the Findable-by option, "add your crew",
  "Crew's playing", "Rounds & crew". Two names for one list is the whole
  defect, and these are now buddies.
  **Kept (the collective sense):** "crew" as the colloquial word for the people
  you play with, which never names the feature — the product TAGLINE ("Rally
  your crew", which is also the `<title>`, `og:title`, `twitter:title` and meta
  description), Home's "Around your crew" feed heading, "Invite the crew" in
  league setup, "in your crew's plans", "Same crew, same bylaws", "the crew's
  board", "real rounds, real crews". These read as register, not vocabulary,
  and the tagline in particular is a brand and share-surface decision that a
  copy sweep has no authority to make. Changing them is a separate call and
  should be its own entry if it is ever wanted.
  Also kept: "friend-to-friend" in the pot copy (D39's money posture — money
  moving between people, not the buddy feature) and `is_friend` in schema.

### D81 · Home becomes a state machine — one hero slot, one lane
- **Current:** `renderHomeHub` calls 11 children unconditionally; only ONE
  gates on lifecycle at all (`renderPulse`, index.html:9595). Home therefore
  renders the union of every state: a member in week 17 scrolls past the
  cold-start doors every morning, the greeting spends the first 40px on the
  time of day, and mobile's `order:-1` floats the desktop rail above the fold
  — eight blocks before the feed. Two of Home's surfaces duplicate the
  Clubhouse (`homeRecap` vs the switcher chips, `homeStart` vs
  `hubLeagueless`). The lifecycle switch the app DOES own (`renderPhase`,
  index.html:10660) lives in the League Room, not Home.
- **Problem observed:** the fold audit (2026-07-27). At 390×844 the first
  screen of a season-live member is "Start a league" wallpaper; the standing
  and the feed — the two things Principle 5 says should greet them — are two
  scrolls down. For a league-less user the same stack renders as a short
  orphan page with three permanent CTAs nobody reads twice.
- **CORRECTION recorded en route:** the first draft of this redesign claimed
  `homeFeed` duplicated the Clubhouse board and should crop to 3. False —
  the mapping proved `homeFeed` is the MERGED cross-group stream (buddy
  rounds + league moments), which exists nowhere else; the board is
  per-league. The feed stays whole. The duplications are only recap and the
  doors.
- **Recommendation:** Home = **one hero slot + one lane**, dispatched on
  lifecycle. Hero by state: league-less climbs a ladder of next-unmet-facts
  (0-of-3 index → "nobody's seen it" → "four makes a league, you have six"),
  forming = countdown + roster fill, season = the standing MOVE, cup_final =
  seed, complete = the record (position + purse, champagne) with run-it-back.
  Below: the up-next chips, then the merged feed. Deleted: the greeting, the
  recap block, the unconditional doors (they fold into the ladder for the
  league-less and a quiet row otherwise), three of four eyebrows, and the
  mobile `order:-1` rail flip. An OCCASION card (~6 client-side date windows
  keyed to real golf's calendar, every nod oblique per the famous-golf-wing
  rule) rides under the hero when a window is open. Weather enrichment uses
  fields the Home fetch already discards. Hero CTA taps are instrumented.
- **CONFLICT (named, resolved):** "where do I stand" as a hero is a
  STATISTIC at rest — Principle 4 says memory > statistics and Principle 5
  says opening the app should reveal something new; a static rank is
  pixel-identical to yesterday. Resolution: **the standing is a verb** — the
  hero always renders the MOVE and its cause ("Danny's 78 Saturday dropped
  him behind you"), and on quiet days points forward ("beat your number by 3
  Saturday and you take 2nd"). Data verified free: rank from
  season_scenarios, gap from rows already fetched, arrow from week
  snapshots; the movement chip is omissible by design (week 1 has no
  snapshot; snapshots are Sunday-only).
- **Principle:** #5 (alive), #4 (the move is a story, not a stat), #2 (the
  ladder shows one next thing, never a chore list), #1 (the league-less
  golfer's card is the hero, not the product's sign-up funnel).
- **Benefit:** the whole home above the fold in every state; the first
  screen answers "what's new and what's next" instead of advertising doors.
- **Tradeoffs:** Home's renderers grow a dispatcher (more branches to test —
  mitigated by per-state verification); the occasion table is maintained by
  hand (~6 rows/year); cup_final/complete heroes ship before any user can
  reach them (accepted — they are small and the first season will).

### D82 · Orientation: one screen after the golfer card, depth at the doors
- **Current:** after the golfer card, a brand-new user lands on Home with no
  model of the app. The walkthrough audit (2026-07-27) found the vocabulary
  couldn't even be taught (fixed by D80), and CLAUDE.md itself carried the
  wrong posting model ("stepper is default" — it is not; the composer
  defaults to front/back gross, D34 hid the toggle).
- **Recommendation:** ONE skippable orientation screen after the golfer
  card, teaching exactly two things: the four places (Home / Clubhouse / ⊕ /
  You) and the two ways to play ("the long game" / "the short game" — the
  app's own switcher copy). "See it with a live season" hands off to the
  existing demo diorama. A "How it works" group in the You tab reopens the
  same content forever (six short reads incl. scoring + the demo). Depth
  stays AT the doors: the ⊕ chooser and event picker already explain
  themselves. Seen-flag in localStorage (`cs_oriented`) — re-showing on a
  new device is acceptable; no migration.
- **Principle:** #2 — one tap of friction, spent exactly once, against the
  no-tutorial metric failing outright.
- **Benefit:** the mental model survives first contact; the doors stay
  self-explaining for everyone who skips.
- **Tradeoffs:** one more screen before first Home (skippable in one tap);
  guide copy is a second place the model is described and must be kept true.

### D83 · The demo season retires — the app has real things to show now
- **Current:** a full interactive diorama ("Peek at a live season" — The
  Sunday Cup, seven fictional players) reachable from the signed-out door
  (#obDemo), the league-less Clubhouse (#wDemo), the D82 orientation's "See
  it with a live season", and the D82 guide's sixth row. Demo coherence was
  once release-blocking (launch instructions of 2026-07-12 walked testers
  through it).
- **Problem:** pre-launch simplification (owner call, 2026-07-27). The
  diorama is a second product to keep coherent — its dates, names and copy
  have drifted before — and every real surface added since (the ladder
  hero, the occasion engine, claim links, the covenant) does the same
  "show, don't tell" job with real objects.
- **Recommendation:** remove every USER PATH to the demo: both entry
  buttons and their handlers, the orientation's demo CTA (single "Take me
  in" remains), the guide's demo row, and the demo render branches in the
  D81 surfaces (hero, up-next, home-start). The internal `state.demo`
  plumbing STAYS — it is the write-guard that keeps any demo-shaped code
  path from touching the database, and `demo:true` is the boot default
  before sign-in. Dead gates are inert; a missing gate is a landmine
  (CLAUDE.md: "gate every real-data path with !state.demo").
- **AMENDS D82:** the orientation loses its worked example. The screen's
  two teachings stand on their own; the guide drops to five rows.
- **Principle:** #3 Real Golf — no simulations; the demo was the one
  deliberate exception and its job is done. #2 — one less door on the
  sign-in screen.
- **Benefit:** nothing left to keep coherent; the signed-out door sells
  with its own splash, not a fiction.
- **Tradeoffs:** any outstanding tester link or instruction that says
  "peek at a live season" now points at nothing — the 2026-07-12 demo
  instructions are obsolete and should not be re-sent. Prospects lose the
  poke-around preview; the walkthrough artifacts carry that job now.

### D84 · The door wings stay, bounded — and the fiction is named as debt
- **Current:** the sign-in door's two desktop wings are hand-authored fiction:
  a feed of invented golfers on real Phoenix municipal courses (MARCUS ·
  PAPAGO GC · 82 · +9 PTS) and a four-squad leaderboard whose second place
  counts up and overtakes the leader every 5.2s.
- **Problem observed (2026-07-27):** two real defects, measured by replaying
  the shipped arithmetic. (a) RUNAWAY INFLATION — each swap set the chaser to
  `leader + 4..7` with no ceiling, so an idle tab climbed 184 → 515 by five
  minutes and 957 by twelve. (b) A DEAD BACK HALF — `order=[chaser,leader]
  .concat(order.slice(2))` only ever permuted the top two, so rows 3 and 4
  sat frozen at their seed values forever, leaving a 790-point gap to a third
  place that had never moved. A sign-in screen is a page people leave open.
- **Recommendation:** keep the art, bound the arithmetic. Every third swap
  rotates the back of the board forward so all four rungs contend; when the
  leader passes a ceiling the whole board rebases by a constant, preserving
  the spread. Verified over 1200 simulated ticks (~104 minutes): every value
  stayed in 138–232, max spread 48, all four rows moved.
- **CONFLICT (named, NOT resolved — logged as debt):** D83 retired the demo
  season citing Principle 3 (no simulations, no fake scoring, no fantasy
  players). These wings are the same species of fiction and they survive it.
  The defensible line is that the demo was an INTERACTIVE second product that
  had to stay coherent with real mechanics, while the wings are ambient,
  aria-hidden, desktop-only decoration that cannot be entered. That line is
  real but thin — and the wings are arguably worse on one axis the demo never
  touched: they attach invented scores to REAL named courses. Recorded here
  rather than settled, because the owner likes the art and launch week is not
  when to rebuild a pre-auth decoration.
- **Successor, if the debt is ever paid:** "The Heat and the Fuse" (the
  direction that won the principles lens of the 2026-07-27 panel) — the left
  wing becomes the real scoring bands drawn as a heat ramp, the right wing
  the actual current month drawn as the crest's fuse burnt down to today's
  date. Zero invention: every figure is either an existing constant
  (`pointsFor`/`bandName`) or a reading of the device clock, and it is
  different art every day of the month. Do not rebuild the wings as a
  different fiction.
- **Principle:** #5 (alive — but honestly alive); #3 flagged, see CONFLICT.
- **Benefit:** the art the owner likes survives, and stops embarrassing
  itself on any tab left open longer than a minute.
- **Tradeoffs:** the fiction remains on the one surface every prospect sees.

### D85 · Everyone's phone scores the live round (sync v2) + scoreboard-first layout
- **Current:** the tee sheet is one scorekeeper phone (gameplay-modes flag #16
  corollary, deliberate v1). Scores live in `state.live` + localStorage only
  until finish; `live_rounds`/`live_round_players` exist server-side but hold
  no in-round scores. The play screen buries game status in cards below the
  entry rows — the group scrolls up and down to learn who's up.
- **Problem:** playing partners want to input their own scores and watch the
  standings move (the 18Birdies table stake, minus our games). And the real
  screen complaint is scroll-bounce, not clicks: standings and entry never
  share a viewport.
- **Recommendation:** broadcast-first, RPC-durable sync — Realtime broadcast on
  `live:<round_id>:<join_code>` (rtClient), durable writes through
  SECURITY DEFINER RPCs, new `live_scores` cell table (LWW by writer
  timestamp), local-first snapshot stays the backbone so scoring never blocks
  on signal. Anyone in the group edits any cell (keeps flag #16's catch-up rule
  true when a phone dies). Members join via Home banner
  (`find_my_live_round`); guests join mid-round through their EXISTING claim
  link — token is identity, no account, anon-callable `guest_live_*` RPCs
  (fail-closed, extends the D57/D68 anon-endpoint list). Layout: scoreboard
  block tops the play screen — game hero line, player net/gross chips —
  collapsing to a sticky strip; game detail moves to a tap-in sheet.
  `finish_live_round` gains a row lock (two phones can't double-post).
- **AMENDS flag #16 (corollary only):** "one scorekeeper phone is v1 primary;
  everyone's-phone live sync is v2" — this is that v2, on schedule. The body
  of #16 (every state enterable after the fact; catch-up over lock) stays
  binding and picked the write model.
- **Principle:** #1 the group plays together (co-play is the product's spine);
  #16-spec every figure keeps its receipt (scores land server-side with
  attribution); Real Golf — the guest funnel deepens (same link scores the
  round, then claims it).
- **Benefit:** the round becomes a shared object while it's being played; the
  screen answers "who's up" at a glance; guests get the full experience from
  one link.
- **Tradeoffs:** a public-broadcast channel keyed by an unguessable code
  carries first names + scores (durable writes still re-auth; acceptable for a
  friend group's card). LWW can visibly correct a cell after an offline race.
  One more table and seven new functions on the grant-audit surface.

### D86 · The tee sheet calls you to it (round invite) — and the arrival is live
- **Current:** D85 gave every player a pencil but no DOORBELL. `start_live_round`
  writes `live_rounds` + `live_round_players` and returns — no board post, no
  push, no realtime event. `rehydrateLiveRound()` has exactly ONE call site,
  inside `enterLeague()`, so the "Continue your round" banner appears only on a
  cold boot or a league switch. Measured 2026-07-28 by tracing every call site,
  every visibilitychange handler, the posts realtime handler and every
  setInterval: a phone already open when the Pro tees off receives literally
  nothing, and the player has to reload before the round exists to them.
- **Problem:** the pencil is only as good as the invitation. A group standing
  on the first tee cannot be told "everyone force-refresh." And the round's
  own players are the one audience with a legitimate claim on a lock screen —
  they are about to play.
- **Recommendation:** two signals, each scoped to the people it concerns.
  (1) IN-APP, live: the starter broadcasts `live_open` on the league channel
  every open app already subscribes to (`lg-<league_id>`, D34's realtime
  spine). Receivers call `rehydrateLiveRound()`, which re-runs the existing
  roster filter — so the client never decides who is invited; the same server
  query that has always decided it decides it here too. Zero new tables, zero
  writes, no polling. (2) POCKET: `start_live_round` inserts one `push_nudges`
  row per MEMBER player except the starter — the existing per-recipient push
  path (D40, the Ryder taunt), which fans to exactly one profile. The board
  post was REJECTED for this: `posts` fans push league-wide, so eight people
  who aren't playing get woken to hear that four people teed off.
  The banner learns a second face: when `started_by` is not you it reads as an
  invitation ("Marcus put you on the tee sheet") rather than a resumption.
- **Principle:** #1 the group plays together — an invitation is the social act
  the feature was missing; "only meaningful ones, no spam" (the push rule) —
  the notified set is exactly the roster, never the league.
- **Benefit:** teeing off now reaches the group in the two states a phone is
  ever in: open (instant banner) or pocketed (one push). Cold open already
  worked.
- **Tradeoffs:** broadcast reaches only apps whose CURRENT league is the
  round's league — a cross-league round still waits for the push or the next
  boot. Accepted: the push covers it, and cross-league live rounds are rare by
  construction. The nudge is not user-mutable yet (no per-user off switch);
  it fires only for a round you were personally rostered into, which is the
  narrowest audience in the product.
- **Also fixed here (found by the same trace, both latent):** the D85 guest
  RPCs keyed on `claim_token` alone, while the older funnel keys on
  `claim_token AND member_id is null` — and the baseline defaults a token onto
  EVERY player row, members included. No member token reaches any surface
  today (tee-off stores tokens only for rows carrying a `guest_name`), so
  nothing was exposed, but a member row must never be scoreable by token:
  the guard is added. And `claimPendingRound()` deleted `cs_claim` when
  `claim_round` refused a still-live round, which permanently orphaned the
  card of a guest who signed up mid-round; the token now survives and the
  message tells the truth.

### D87 · The pencil is for the golfer, not for the account-less
- **Current:** D85's guest pencil (a `/?claim=` link that scores a live round)
  is gated on being signed OUT: `if(!CS.user && claimTok …)`. The assumption
  baked into that line was "guest = no account."
- **Problem observed (2026-07-28, tracing a real upcoming round):** the owner
  is playing with a golfer who HAS the app but is not in his league. That
  golfer can only ride the tee sheet as a GUEST ROW — `start_live_round`
  rejects a `member_id` belonging to another league, and the roster search adds
  any non-mate as `guest:true` — so the claim token is her only pencil. And the
  signed-out gate meant her link fell through to `claimPendingRound()`, the
  server refused ("Round is still live"), and she could enter nothing. Having
  an account bought her a WORSE round than a stranger got. Cross-league play is
  not an edge case; it is the friend group the product is for.
- **Recommendation:** the token, not the session, is the authorization. Let a
  signed-in golfer open the pencil with it, after boot has entered their own
  league. Two guards: never over an ACTIVE round of their own (that one is
  theirs to finish), and only while the round is live (a finished one belongs
  to the claim path). They keep their whole app — nav, tabs, their leagues —
  because `.guestlive` is a kiosk for a phone with no account and nothing but a
  reload removes it; stranding a real user behind that is a worse bug than the
  one being fixed. They lose only the round's OWN controls (finish, scrap,
  setup), which belong to a league they are not in. On finish they need no
  reload: the pencil drops, the card claims itself, they land home.
- **Depends on D86's guard:** `guest_live_*` now key on `claim_token AND
  member_id is null`, so this path can never hijack a member's row. Without
  that guard, opening this to signed-in users would have been a real hole.
- **Principle:** #1 the group plays together — the round is the unit, not the
  league roster; Real Golf — the people at your course are who you played with,
  whatever app rows say. Also the guest-funnel principle held: her card still
  posts to her own profile at the finish, and because rounds belong to profiles
  and leagues are lenses, it scores in HER league automatically.
- **Benefit:** a cross-league foursome is now four phones, not three plus a
  spectator.
- **Tradeoffs:** a signed-in visitor's pencil is authorized by a link, so
  anyone she forwards it to can score that round as her (unchanged from the
  guest model, and the round is a friend group's card, not a bank). She gets
  no D86 doorbell — the nudge is roster-members-only and the broadcast rides a
  league channel she is not on — so the link remains how she is invited. A
  targeted invite for non-member players is the obvious follow-up.

### D88 · The visitor gets a doorbell AND a door
- **Current:** D87 let a signed-in golfer from outside the league score with a
  claim link. But the link was the ONLY way in: `live_rounds` RLS is
  `is_league_member(league_id)`, so a visitor's app literally cannot SELECT the
  round, and the D86 doorbell skipped them entirely (the nudge fans to member
  players; the broadcast rides a league channel they are not on). The root
  cause sat one line up the stack: the tee-off client searched the golfer up by
  PROFILE (`#rosterFind` stores `pid`) and then threw it away, sending the
  server a bare name.
- **Problem:** the Pro has to remember to send a link before teeing off, and if
  he forgets, the player standing next to him cannot join the round he is
  standing in. A notification alone would have been worse than nothing — a
  doorbell that opens onto a wall.
- **Recommendation:** carry the identity. `live_round_players.guest_profile_id`
  makes a guest a KNOWN golfer; `start_live_round` stores it and the push-nudge
  fan-out now covers members and visitors alike (nothing to deploy —
  `push_nudges` already delivers one row to one profile and the service worker
  opens the app on tap). `my_visitor_rounds()` is the door: a definer read that
  returns exactly the rounds where I am a known guest, in the SAME shape the
  client's own resume query returns, so every path downstream is untouched.
  `_live_member_can` accepts a `guest_profile_id` match, so the visitor scores
  through the ordinary `live_*` RPCs — identity, not a token. The link keeps
  working (D87's path stands, and an account-less guest has nothing else), but
  it is no longer REQUIRED for anyone the app can recognise.
- **Boundary held:** `finish_live_round` still admits only the starter or a
  member player, and the client hides finish/scrap/setup behind the same
  `visitor` flag. A visitor scores the round; they do not end it.
- **Principle:** #1 the group plays together — the round is the unit, not the
  league roster. "Only meaningful ones, no spam" survives: the notified set is
  still exactly the people on the tee sheet.
- **Benefit:** a cross-league foursome is four phones that all get told, all
  find the round on their own, and all keep their own app.
- **Tradeoffs:** a guest row now stores a profile id, so the round is legible
  as "these two golfers played together" outside either league — correct (they
  did) but it is a new link between a profile and a league it is not in.
- **KNOWN GAP, deliberately not closed here:** a visitor's card still does not
  post at the finish — it saves against the guest row and reaches their record
  only through the claim link, so the Pro must still share it afterwards. Now
  that the server knows the profile, `finish_live_round` could post it directly
  (stamping `claimed_profile` so the link cannot double-post). That is the
  right completion and it is a posting-path change, so it gets its own pass
  rather than riding a notification build. Until then the finish toast tells
  the visitor the truth instead of claiming their round landed.

### D89 · One mark, and a settlement card that can actually travel
- **Current:** two independent inconsistencies, both found by reading a real
  shared result out of the pilot's iMessage thread.
  (a) The `shared` storage bucket was created `allowed_mime_types =
  {image/jpeg}`; the settlement card is a PNG. Every card upload since D78 was
  refused AT THE BUCKET. (b) The ember flag had replaced the four-arc orbit
  mark on the install icons, the apple-touch icon and the og-image — but the
  ring survived in the favicon, the in-app header, and `brand/*.svg`.
- **Problem:** (a) a shared settlement previewed with the generic brand card
  instead of its own 4&3 artifact — the one moment the product is most worth
  looking at, and the picture was a house ad. It failed INVISIBLY three layers
  deep: the client catches the upload error ("link ships card-less", best
  effort by design), and the edge function HEADs the object and falls back
  rather than pointing a scraper at a 404. Three correct safety nets summing to
  a feature that had never once succeeded — `storage.objects` for that bucket
  was empty all-time. (b) the app's own header disagreed with the card it
  texts you.
- **Recommendation:** (a) teach the bucket PNG rather than downgrade the card —
  it is flat-colour type on a dark ground and JPEG rings the letterforms; the
  migration RAISES if the mime list does not take, so the claim is
  self-enforcing. (b) retire the ring everywhere it survived; `brand/mark.svg`
  and `mark-light.svg` are redrawn as the ember flag and the README says which
  PNG lockups are now stale.
- **Principle:** #4 everything shows its work — a settlement's receipt is the
  artifact, and a preview that hides it is the same failure as a points figure
  with no path to its rounds. Identity: one mark or it isn't one.
- **Benefit:** the next shared result previews as itself; the tab, the header,
  the home-screen icon and the text-message card finally agree.
- **Tradeoffs:** `lockup-dark.png` / `lockup-light.png` still carry the ring
  and are flagged stale rather than regenerated — they are canvas-rendered
  assets and this pass had no image toolchain. Nothing ships them today.
- **Lesson (recorded, it will recur):** an upload path whose every failure is
  swallowed needs ONE thing that fails loudly — a check, a test, or a probe.
  The photo path shipped `.jpg`, succeeded, and made the bucket look healthy.

### D90 · The settlement card stops counting to three
- **Current:** the settlement card printed `CLOSED ON 15` under the `4&3` hero.
- **Problem:** three numbers (4, 3, 15) on an artifact that offers a key to
  none of them, and the third is derivable from the first two — 18 − 3 = 15.
  Worse, it is only true on eighteen holes: a 4&3 on a nine closes on the 6th,
  and the card never states the hole count, so the line reads as arithmetic the
  reader cannot check. "Closed" is also insider usage on the one artifact that
  routinely reaches people who have never played.
- **Recommendation:** delete the caption. The strip already says it — three
  hollow cells ARE the "&3" — and the unclosed `THRU n` variant goes with it,
  since a full strip states the same thing. Considered and rejected:
  `4 UP WITH 3 TO PLAY` (decodes the notation, but the owner's call was that
  the card is stronger with hero + strip alone).
- **Measured, not guessed:** removing a row from an absolutely-positioned
  canvas leaves a hole, so the layout was measured rather than eyeballed. The
  card's section gaps run 87 / 84 / 116 / 91 / 90 px; with the caption gone the
  strip-to-legend gap lands at 91, inside that family. It had been a cramped
  54-then-18 pair. Nothing was repositioned — the measurement said don't.
- **Scope:** the CARD only. The in-app hole strip keeps its footer; that
  surface has room and context around it, and is read by people already inside
  the product.
- **Principle:** §16 — every figure shows its work, and a figure that cannot be
  checked is worse than no figure.
- **Tradeoffs:** nothing on the artifact now explains the `4&3` notation to a
  stranger. Accepted deliberately: the card is a scoreboard, not a lesson.

### D91 · The crest is the key visual; the flag is the mark
- **Current:** the sign-in door has carried the CREST since D76 (Entry V4) —
  four tracers on the heat ramp landing on a flagged cup, rings spreading from
  the strike. Meanwhile D89 put the ember flag on every icon, favicon and link
  preview. Two good pieces of art, no stated relationship between them.
- **Problem observed:** a settlement card shared into a text thread showed the
  flag lockup in the link preview; opening the app showed the crest. Same
  product, two faces, in the space of one tap. The owner proposed promoting the
  crest to the logo.
- **Recommendation:** keep both, and say which does which job. The **crest is
  the key visual** — the door, and now the 1200×630 link preview. The **ember
  flag stays the mark** — every icon, favicon, apple-touch, maskable tile.
  This is the ordinary shape of an identity system (a mark holds at 16px, a key
  visual carries the story), and it needed stating rather than inventing.
- **Why the crest cannot be the mark — tested, not asserted:** rendered at
  icon sizes on both grounds, its tracers are 2.6px strokes on a 460-wide
  field. They thin to nothing by 32px and vanish at 16px, leaving a flag and a
  smudge. Thickening them to survive (roughly 3×, two ripples deleted, the fan
  compressed into a square) produces a legible mark that is no longer the
  drawing that was proposed. Both versions were built and compared before
  deciding; the gap between them IS the reason for the split.
- **Also:** `brand/…/converge/v1/crest-static.svg` is a static extraction of
  the door's exact geometry, so preview and door are one drawing rather than
  two that resemble each other. `tools/make-og-image.py` regenerates the PNG
  and lives outside `brand/` on purpose — `stamp-version.sh` copies `brand/`
  wholesale into `dist/`, so a script there would be world-readable.
- **Principle:** #5 alive — the door's best moment now reaches the one surface
  a stranger sees first; D89's "one mark everywhere" is unbroken, because the
  crest was never competing to be the mark.
- **Tradeoffs:** the link preview is now atmosphere rather than a legible
  lockup at thumbnail size — the wordmark carries it where the tracers fade.
  The retired-ring `lockup-dark.png` / `lockup-light.png` are still stale and
  still need regenerating; this pass did not touch them.

### D92 · The settlement post opens the scorecard
- **Current:** a settled game posts one line to the board — "Match play: Jerecho
  Fischbeck def. Jade 4&3" — and that line is inert. Traced 2026-07-29: system
  rows render as `.sysrow` divs with no data attribute, no role, no tabindex and
  no handler, in BOTH board renderers and on Home. Round posts ARE tappable (they
  open a receipt); the one post kind that reports a RESULT is the one that
  dead-ends. A real user asked for exactly this: "I'd like to be able to click in
  and see the scorecard."
- **Problem:** §16 says nothing shows a figure without a path to the rounds that
  produced it, and "4&3" is a figure. Two things block the path, both measured:
  1. `finish_live_round` inserts the settlement post with FOUR columns —
     `league_id, kind, member_id, body`. `round_id` is NULL and no live-round
     reference is written, so the row carries no way back to what produced it.
  2. NOTHING in the product reads `round_holes`. Per-hole strokes are written at
     post time and never fetched again — no RPC selects them. The only
     hole-by-hole grid that renders is the demo's, and its holes are FABRICATED.
     There is no scorecard surface for a real round anywhere on disk.
- **Recommendation:** `posts` gains `live_round_id` and the settlement insert
  sets it — the live round, not `round_id`, because a settlement is about the
  GROUP's round, not one card. A new SECURITY DEFINER `live_round_card()`
  returns the whole sheet: course, tee, date, game, result, every player and
  their strokes by hole. The client makes the settlement row a real button and
  draws par/SI, a column per hole, a row per player, and the match ledger over
  the top — reusing the `holeLedger` vocabulary the strip already speaks.
- **Where the card lives (the useful discovery):** D85 made `live_scores`
  durable and nothing deletes it, so after the round the whole group's
  hole-by-hole — members AND guests, one table — is still there keyed by
  `live_round_id`. That is the read source. The RPC falls back per player to
  `round_holes` (members) and `live_round_players.guest_strokes` (guests) so
  rounds finished BEFORE D85 shipped still open.
- **Why definer, not RLS:** the `rholes_read` policy gates hole detail on the
  round's `season_id` → your league. But `rounds.season_id` is never set by ANY
  server-side insert (the live finalize omits the column, as do the scan and
  sandbox paths); only the client's manual post supplies it, and only when a
  season is in scope. So under RLS the holes of most rounds are unreadable EVEN
  BY THEIR OWNER. A definer RPC with its own guard sidesteps that entirely.
  **The NULL `season_id` is logged as separate debt** — it is not this arc's to
  fix and it may be affecting more than hole reads.
- **Principle:** §16 shows its work — the receipt rule finally reaches the games;
  #1 the group plays together — a settlement is the group's artifact, so the card
  shows every player, not just yours.
- **Benefit:** the sentence a friend group actually screenshots becomes a door.
- **Tradeoffs:** the card is only as good as what was entered — a group that
  scored one player's column leaves gaps, and the sheet shows them rather than
  hiding them.
- **AMENDED before shipping — the old settlements ARE backfilled.** This entry
  first said no backfill, on the grounds that joining a body string to a round is
  guesswork. Measured against prod, it is not: the settlement insert and
  `update live_rounds set finished_at = now()` run in ONE transaction, and
  `now()` is the transaction timestamp — so `posts.created_at` is byte-identical
  to `finished_at` (delta 0.000000 on every settled round on disk). One trap
  found in the same read: a handicap-change post fires from a trigger inside that
  same transaction and carries the identical instant, so timestamp equality alone
  mis-attributes it. The backfill therefore also requires the body to be the
  settlement the round recorded ('Match play: …', or exactly
  `left(game_result->>'story',200)`), and refuses any instant where more than one
  round in the league finished. Dry-run on prod: two settlements matched, the
  handicap post correctly excluded. The pilot's own "4&3" post — the one that
  prompted this — opens on day one rather than staying a dead end forever.

### D93 · Three things that were sections become places
- **Current (measured 2026-07-29):** of the four objects a golfer actually
  returns for, exactly ONE has a destination. Leagues have the Clubhouse tab.
  The other three are sections inside other screens:
  · **Buddies** — one `#youPeople` div mid-page on the You tab, below the Tour
    card, trophy case, last-round-with, career record and recent rounds. The
    "go to buddies" function is literally `switchView('stats')`. Requests were
    split onto Home and search into a header overlay: THREE places for one
    relationship.
  · **The board** — 1 of 6 segments inside Clubhouse. Its full-screen form
    already exists (`#boardFull`) but only opens from an `OPEN ↗` link inside
    that segment; nothing in `switchView` reaches it.
  · **The schedule** — another of those 6, plus a 5-row echo on Home.
- **Problem:** the schedule case is not just buried, it is structurally wrong.
  `my_schedule` returns buddies' plans, league mates' and rounds you were
  tagged in — it spans leagues BY DESIGN — yet its only full view (watch list,
  month calendar, tee sheet, declare button) sits inside a per-league room, and
  `body.noleague` collapses `#view-hub` entirely. A league-less golfer with
  buddies has plans to see and no calendar to see them in.
- **Recommendation:** promote, do not rebuild. All three surfaces are complete
  DOM subtrees with renderers keyed to their IDs, so moving the nodes into real
  `.view` sections keeps every renderer working untouched:
  · `#room-schedule` leaves the room and becomes `view-schedule` — outside
    `#view-hub`, so it survives for a league-less user.
  · `#youPeople` leaves the You tab and becomes `view-people`, with search and
    requests reachable from it: one home for the relationship.
  · the board keeps `#room-board` (desktop pairs it beside standings via
    `#roomGrid[data-room="standings"]`) and gains a ROUTE to the full-screen
    form it already has.
  The Clubhouse segments for schedule now route to the destination instead of
  toggling a pane, so there is one place per thing rather than two.
- **NAV UNCHANGED — and that is the point.** The blueprint's four slots
  (Home · Clubhouse · ⊕ · You) stay exactly as shipped. These are destinations
  reached from where people already look, not new tabs, so nothing here
  contradicts the level-3 IA. **The quadrant Home was considered and rejected**
  in the same conversation: it would have overridden "the home IS the feed,
  full stop", and D81 had already deleted Home's grid as the single biggest
  fold cost. The diagnosis behind it was right — three of four things ARE
  buried — so the fix goes to the buried things instead of to Home.
- **AMENDS IA P5** (which retired the Crew tab and scattered buddies into
  three places). Buddies gets one home again. It is NOT a nav slot, so the
  four-tab bar P5 established still holds.
- **Principle:** #1 the group plays together — buddies and the schedule are the
  social spine and were the hardest things to reach; #2 fewer doors — each of
  these had two half-doors and now has one real one.
- **Benefit:** a league-less golfer finally has a calendar. Buddies stop being
  a scroll target. The board is one tap from anywhere instead of three.
- **Tradeoffs:** Clubhouse loses two of its six segments, which makes the room
  more clearly "this league" and less a catch-all — intended, but it is a
  visible change to a screen pilots know. Deep links to a routed view do not
  restore the Clubhouse segment state they came from.

### D94 · Home leads with the doors, then the hero, then three tiles, then the feed
- **Current:** D81 made Home one lane with a lifecycle hero, put the three
  cold-start doors at the FOOT as a quiet row, and hung an "Upcoming golf" list
  below the feed. Since then D93 turned the schedule, buddies and the board into
  real destinations — so Home was carrying partial echoes of places that now
  exist properly.
- **Problem:** two things, both observed rather than assumed. The doors at the
  foot are below everything on a phone, so "start a league" — the action a young
  product most needs — is the last thing a visitor reaches. And the "Upcoming
  golf" list is a five-row echo of a calendar that is now one tap away, which
  means two surfaces answering one question and neither authoritative.
- **Recommendation (option B of three drawn at a true 390 × 844):** keep ONE
  lane and change what leads it. Order becomes doors → hero → tiles → feed.
  The three tiles are league · next round · board — one fact each, each a real
  door into what D93 built. "Upcoming golf" retires into the Next tile plus the
  calendar destination.
- **Rejected, with the mockups to show it:** a four-quadrant Home (A). It fits
  390 × 844 — measured, 844 of 844, nothing scrolls — but it gives a number that
  changes weekly the same room as a round happening now, and it leaves NO room
  for the feed. Also rejected: two quadrants over a feed (C), a fair cheaper
  fallback if the hero ever proves too much machinery.
- **AMENDS D81** on two points, deliberately and not silently: the doors move
  from foot to head, and the Upcoming-golf block retires. **D81's correction
  survives untouched — the feed STAYS WHOLE.** That was the one thing D81
  protected by name, and it is the reason B was chosen over A: the merged
  cross-group stream exists nowhere else in the app, so a Home without it stops
  answering "what happened?" and only answers "where do I go?".
- **Principle:** #2 fewer doors — one authoritative surface per question, so the
  five-row echo yields to the calendar it was echoing; D27 never opens on
  nothing — every tile has an empty state that still opens, and none invents
  content to fill itself.
- **Benefit:** the first screen now offers a move (start/join), then the state of
  play, then the three places, then the story — in the order a returning golfer
  actually wants them.
- **Tradeoffs:** Home opens on "make something" rather than "here's what
  happened", which is a real change of voice and the thing to watch in use. The
  doors are also now above the hero for members who will never tap them again.
- **A REGRESSION FIXED HERE, SHIPPED IN D93:** D93's CSS was inserted before the
  first `.sysrow{` in the file — which is NOT the component rule but the one
  inside `html[data-theme="light"] .msgrow, html[data-theme="light"] .sysrow{…}`.
  That split the selector: the light-theme background was lost and a stray
  global `.sysrow{background:#FBFCFA;}` was left behind (harmless only because a
  later rule overrides it). Light theme has been serving system and chat rows on
  the wrong ground since that push. Both blocks are re-homed after the real
  component rule, anchored on a string asserted to occur exactly once.
  **Rule earned: never anchor an insert on a selector fragment — `.sysrow{`
  matches a theme override before it matches the component.**

### D95 · A posted round shows its work, and the cant means something again
- **Current:** opening a round gave "86 gross · SOMEWHERE OUT THERE · 18 HOLES"
  over "-11.5 — POSTED ANYWAY". Three separate defects sat behind that one
  screen, all confirmed against prod.
- **Problem 1 — the figure had no working.** That round is Arizona Biltmore
  Links · Copper, **rating 64.9 / slope 111** — a short, easy course — so an 86
  differentials to 21.5 against an index of 10.0, and −11.5 is exactly right.
  But the sheet showed the verdict and hid every input, so a TRUE number read
  as an accusation. §16 says no figure appears without a path to its work.
- **Problem 2 — "somewhere out there" was a field-name mismatch, not missing
  data.** `home_feed` returns the column aliased `course`; the receipt read
  `course_label`; the fallback filled the hole. The round had a course all
  along.
- **Problem 3 — the cant was leaking.** C5 gave month-close cards a 1.4° cant
  ("a hand set this"). But `.sealin` runs `csSeal` with fill `both`, and that
  keyframe set ENDED on rotate(-1.4deg) — so every post under 48 hours old kept
  the tilt permanently, "joined the league" included. The intent was that fresh
  cards land with the thock and settle straight.
- **Recommendation:** `round_card(round)` — one definer read carrying the course
  AND its rating/slope/tee, the differential arithmetic, index at post, points,
  counting rank, who attested it, and `live_round_id` so the sheet hands off to
  D92's hole-by-hole. The receipt opens instantly with whatever the caller held
  and enriches in place. `csSeal` settles straight; a new `.stamped` carries the
  cant and goes on POSTED ROUNDS — the one thing on the board a hand set down.
- **Kept, deliberately:** the month-close cant. `.sealed` needed the
  keep-variant of the arrival, because an animation's fill beats a static
  transform — without it, fixing the leak would have flattened the chapter
  close D81 gave the cant to in the first place.
- **Principle:** §16 shows its work — the receipt finally earns its verdict;
  #2 fewer doors — the round sheet now leads INTO the scorecard rather than
  competing with it.
- **Benefit:** "POSTED ANYWAY" stops being an accusation once you can see the
  course was a pushover. And the cant becomes information again instead of
  noise on every recent row.
- **Tradeoffs:** one extra read per round open (guarded, cached by nothing —
  acceptable for a tap-through). The arithmetic row is dense; it is deliberately
  quieter than the verdict it explains.
- **Also fixed — a duplicate the board has been showing:** `respond_invite`
  inserted the member row with `on conflict do nothing` and then posted
  "X JOINED THE LEAGUE" **unconditionally**. `join_league` got that guard in
  20260714040000; `respond_invite` never did, so joining by code and then
  accepting a pending invite for the same league announced you twice — which is
  exactly what prod held, ten seconds apart. Guard added, and the orphaned
  duplicate is deleted (narrowly: the earliest announcement per league+body
  survives; a dry-run against prod matched exactly one row).

### D96 · The forming hero gets the move it never had
- **Current:** every hero state offers a move except the one that needs it most.
  `complete` offers "Run it back", the league-less rungs offer "Post your first
  round" — `forming` passed no CTA at all. It described a half-built league
  ("My Cup · forming · 1 golfer in") and gave the user nothing to press.
- **Problem, measured 2026-08-04:** seven pilots created a league and stopped.
  All seven are CARDED, six have an index, three had already posted rounds —
  they cleared identity, the hardest part, and then hit a dead end. Every one
  of the seven leagues has 0 invites, 0 posts, 0 seasons, 1 member. Six are
  still sitting there. Coming back showed them a status line and no next step.
- **Recommendation:** the forming hero names the step that is ACTUALLY blocking
  and goes there. Unnamed (or still called "My Cup") → "Name your league",
  wizard step 0, cursor in the name field. Named → "Lock it in and invite your
  crew", wizard step 2 — because inviting has no pre-lock step: it lives on the
  share screen `openLockShare` opens immediately after the lock (2026-07-17,
  "the wizard's last screen is the invite link"). The copy stops reporting
  "1 golfer in" as though it were a standing and says the league is a scaffold.
- **NOT the fix for the seven:** the scaffold-name wall itself was already
  closed — the name gate landed 2026-07-22 (`108db9e`) and every league created
  since has been named, seated and played (1 for 1). This is the RECOVERY path
  the gate never had: it protects anyone who bails mid-setup, including the six
  who already did.
- **Principle:** D27 Home never opens on nothing — a hero that states a problem
  and offers no move is the same failure in a different costume; #2 fewer doors
  — one button that knows which step is blocking beats a wizard the user has to
  re-navigate from memory.
- **Benefit:** an abandoned setup becomes recoverable by the person who
  abandoned it, without anyone reaching out.
- **Tradeoffs:** the CTA guesses the blocking step from name + member count.
  A league that is named and crewed but deliberately unlocked will be told to
  lock every time it opens Home — correct, but insistent.
- **FOUND WHILE BUILDING, NOT FIXED HERE:** `renderWizAddGolfers()` still wires
  `#wzAdd` and `renderWizPicked()` still fills `#wzPicked` — both elements were
  DELETED from the markup on 2026-07-21 (`5cf7a80`, "wizard collapses to three
  steps"). Both functions no-op silently, and `state.wizInvitees` is staged by
  nothing while `lockBylaws` still reads it. Harmless today because inviting
  moved to the post-lock share, but it is dead machinery that reads as a live
  invite path to anyone touching the wizard next. Worth a cleanup pass.

### D97 · The dead wizard invite path comes out
- **Current:** the wizard used to stage in-app golfers before the lock — an
  "Add golfers" button (`#wzAdd`) that opened the People Picker, a chip list
  (`#wzPicked`), and `state.wizInvitees` holding the staged crew until
  `lockBylaws` fired `invite_golfer` for each.
- **Problem:** both elements were DELETED from the markup on 2026-07-21
  (`5cf7a80`, "wizard collapses to three steps"), and inviting moved to the
  share screen `openLockShare` opens right after the lock. The JavaScript
  stayed. `renderWizPicked()` returned at its first line, the `#wzAdd` wiring
  never ran, nothing could write to `state.wizInvitees` — so the lock's
  staged-invitee loop iterated an array that was permanently empty, and three
  separate roster/pot calculations added a constant zero. None of it broke
  anything; all of it read as a live invite path to the next person in the file.
  Found while building D96, when a CTA aimed at `#wzAdd` and hit nothing.
- **Recommendation:** delete the machinery, keep every live part.
  Removed: `renderWizPicked()`, `renderWizAddGolfers()` and its window bridge,
  `state.wizInvitees` and its three constant-zero readers, the staged-invitee
  loop in `lockBylaws`, and the header comment describing the staging flow.
  Kept and re-pointed: `renderProChip()` — `#commishChip` is still in step 0
  and the Pro identity still renders; the three call sites that reached for
  `renderWizAddGolfers` now call it directly, since that was its only surviving
  effect. Kept untouched: `updateInviteNote()` (`#inviteNote` exists),
  `invite_golfer` (the members sheet still calls it), and the email fallback.
- **Principle:** the codebase should not describe a feature it does not have —
  dead UI wiring is a false map, and the next person to touch the wizard would
  have read it as the invite path.
- **Benefit:** 60 lines out, 20 in. The wizard's remaining invite story is one
  story: lock, then share.
- **Tradeoffs:** if pre-lock staging ever returns it must be rebuilt rather
  than re-enabled — deliberate, because what was here could not have been
  re-enabled anyway without its markup.

### D98 · The wrapper comes out — three named surfaces, one React stack
*(2026-08-26, owner decision. ARCHITECTURE, level 5-6, with a named level-1-2
timing conflict. Supersedes `spec/ios-wrapper-arc.md` in full.)*
- **Current:** since 2026-07-21 the iOS plan has been a Capacitor shell in
  remote-URL mode — the app loads cupseason.app, so client updates keep riding
  Netlify pushes with no store re-release. W1-W7 all shipped; Apple enrollment
  landed today (Team ID `3F7BK4WVH8`) and the shell was roughly two days from
  submission.
- **Problem:** three things, found while auditing the shell rather than
  theorised.
  (a) **The wrapper's ceiling is permanent.** The two features that justify
  being on a phone at all — scoring on a watch during the round, and a live
  match on the lock screen — are structurally unreachable from a WKWebView.
  No amount of shell polish gets there; only a second, native project does.
  (b) **The wrapper's best argument was already spent.** Offline scoring in a
  dead zone is the strongest case for going native, and D85 already solved it
  in the web client: `window.liveSync` carries a durable localStorage queue,
  LWW by the writer's clock, poisoned-write protection and drain-on-resume.
  Native would have rebuilt that, not improved it. What was left was speed to
  the store, bought with a throwaway codebase.
  (c) **The surfaces were never named.** The web client was being treated as
  the thing native replaces. It is not: it holds the most-built commissioner
  machinery in the product (draft 117 client references, roster 97, wizard 56,
  ledger 49) and already carries 13 breakpoints at `min-width:960px`, five at
  `1100px`, and an 1120px container. It has been a desktop app for months and
  nobody called it one.
- **Decision (owner):** adopt the **Strava shape** — three surfaces, one
  account, one Postgres — and abandon the wrapper. iOS waits for the real app.
  1. **Phone — Expo / React Native, iOS first, then Android from the same
     codebase.** Owns what happens standing on a tee box: live scoring, posting
     a round, the board, push, standings read. It does NOT carry the wizard or
     the draft board; those are desk work.
  2. **Desktop — the web client, rewritten in React shortly after iOS ships.**
     Owns the Pro's desk: wizard, draft, roster, ledger, month closes, deep
     standings, receipts, founder desk. Keeps the ten `anon` endpoints that
     make claim / join / share links work for people with no account — that
     funnel is why this surface can never be retired.
  3. **Apple Watch — Swift, after the phone app, timing deliberately
     unfixed.** Scoring during play. Designed for in the phone app's round
     state model so it attaches later without a re-architecture; NOT built
     first.
- **Principle:** **#1 Golf First** — the phone and the watch serve the golfer
  mid-round, the desk serves the person running the league, and conflating
  them is exactly the "optimize for league management" failure the principle
  names. **#2 Low Friction Wins** — a draft run on a 6" screen is friction
  invented by pretending one surface fits every job. Also persona-clean:
  Persona 1 (the Commissioner) is a desktop user and always was; Persona 2
  (the Competitive Weekend Golfer) is the phone and the watch.
- **Benefit:** the two features that justify a native app become reachable
  instead of permanently out of reach. The desktop surface stops being treated
  as legacy and starts being invested in on purpose. Android arrives from the
  same codebase rather than as a third rewrite. And the whole stack lands on
  one language and one framework family, which for a solo builder is the
  difference between three clients and three copies of the same client.
- **Tradeoffs:** **iOS slips from days to months, and that is the real cost.**
  Until the phone app ships, the PWA at cupseason.app is the entire mobile
  story — PIGL gets no app icon this season. The Capacitor project
  (`ios-wrapper/`) and today's Capacitor client wiring become dead code. A
  React rewrite of a live 17,767-line client must run in parallel with a
  cutover, never in place, because the web client is serving real leagues
  throughout. Accepted deliberately: the owner's framing was "iOS waits until
  we do it right."
- **What survives the reversal** (most of it): Team ID, App ID, bundle id
  `app.cupseason.ios`, the APNs key and its secrets, the App Store Connect
  record, the corrected AASA, `device_tokens` +
  `register_device_token` / `unregister_device_token`, preflight check 9, the
  reviewer door, mute, report, account deletion, and every listing decision in
  `spec/appstore-runbook.md` — its Phases 0, 1, 4, 5 and all nine decision
  items hold verbatim. Only Phases 2-3 (Xcode/Capacitor mechanics) are
  rewritten.
- **CONFLICT (named):** **collides with D56**, which anchors the visible
  pricing model to "iOS launch" and reasons from a mid-August date that no
  longer exists. **Proposed resolution: re-anchor D56 to the web client, not
  to iOS.** D56's actual mechanism is that a Pro sees the model BEFORE the
  season-2 renewal ask, and the three surfaces it names — the wizard pot step,
  the You-tab membership card, the League Room Pro view — are all live web
  surfaces today. Nothing in D56 required an app; it required a deadline, and
  the web client can carry the same deadline. D56's substance stands unchanged;
  only its trigger moves. **Upholds:** D39 pot posture · D37 grant discipline ·
  no purchase UI in any app (now a cross-store rule, not an iOS workaround) ·
  email-OTP-only sign-in, which is what keeps Sign in with Apple optional.
  **Supersedes:** `spec/ios-wrapper-arc.md` entire, and the unlogged
  2026-07-21 wrapper decision it recorded — which never had an entry here,
  the gap that let the largest architecture commitment in the product sit
  unexamined for five weeks.


### D99 · The phone is Swift — and it owns operating the league, not authoring it
*(2026-08-27, owner decision. ARCHITECTURE + IA, level 5-6. Amends D98's
implementation half; D98's product half — three surfaces, one Postgres, no
purchase UI, email-OTP-only — stands. Full record: `docs/ios/DECISIONS.md`
IOS-006 and IOS-007; the Phase 1 audit behind it is `docs/ios/audit/`.)*
- **Current:** D98 chose Expo / React Native for the phone, reasoning from
  Android-from-one-codebase (Phase C) and one language family across three
  surfaces. It also drew the surface line at "the phone is for the tee box":
  scoring, posting, the board, push, standings read — with the wizard, draft,
  roster, ledger and founder desk desk-only.
- **Problem:** (a) The two features D98 itself named as the reason to go
  native — a live match on the lock screen and scoring on a watch — are Swift
  regardless of stack; on Expo they become extension targets bridged to JS,
  the part most likely to break on each SDK upgrade, on a project already
  pinned down an SDK to match the phone's Expo Go. The phone's scope is small
  (~10–15 screens over ~40 of 156 RPCs), which is where the shared-component
  argument for RN is weakest. Nothing in `gtm-year1.md`, the App Store runbook
  or CLAUDE.md plans for Android users. (b) The surface line was drawn one
  screen too far: the 2026-08-27 audit (`docs/ios/audit/02`, `06` §10) found
  the pot READ and mark-paid, the blind draw, "Start the season", byes and the
  ceremony are phone moments — money changes hands in the parking lot, the
  draw is the league's one appointment — while the wizard's twelve dials, the
  lock sequence, Pro-assign and ledger overrides are genuinely desk.
- **Decision (owner):** (1) **The phone is SwiftUI in Xcode.** `apps/ios/`
  replaces `apps/mobile/`; `packages/` (tokens, RPC contract, the encoded
  rules) stays the shared source and gains Swift emitters so preflight guards
  the Swift artifacts exactly as it guards the TS ones. (2) **The phone owns
  the golfer's whole life plus the Pro's pocket tools** — join with the
  covenant, quick-start league creation (name · preset · stake), create a
  Ryder or Major, the draw and Start, pot summary + mark-paid + forfeits +
  ceremony from `season_payouts` + the D71 vote, announce, starter index, bye,
  endgame dial, make Pro, invite, draft reveal read-only. The desk keeps
  authoring: full bylaw dials, the lock, Pro-assign, the pick clock, ledger
  overrides, report resolution, flags, sandbox, the founder dashboard.
- **Principle:** **#1 Golf First** — the phone serves the golfer mid-round
  *and* between rounds; **#2 Low Friction** — the Pro's four-taps-a-season
  should not require a laptop; the honest split is *authoring* on the desk,
  *operating* and *reading everything* on the phone.
- **Benefit:** Live Activity, widgets, App Intents and the Watch share one
  round-state model with no bridge; one toolchain for a solo builder; the
  directive's definition of done ("create or join a competition, track the
  pot") is met with real backend data.
- **Tradeoffs:** Android is no longer from this codebase — D98 Phase C is
  re-opened as a Year-2 question, not scheduled. The desktop React rewrite
  (Phase D) shares tokens and the contract, not components. The ~600-line
  Expo scaffold is retired (its ideas — Keychain sessions, a converting theme
  adapter — survive as built-ins and generated code).
- **CONFLICT (named):** collides with D98's stack choice and its "Owns"
  table (`spec/native-arc.md`); resolved by this entry — D98's product
  decisions are upheld verbatim, its implementation choice is replaced, and
  its Phase C/D sequencing is re-opened. Milestones now follow
  `docs/ios/IOS-005-roadmap.md` (M0–M7), not `native/b1…b6`.

### D100 · The phone gets the whole web first; the web is rethought after
*(2026-08-27, owner decision. SCOPE / IA, level 3-5. Supersedes the surface
split in D98 and the scope half of D99 (IOS-007); upholds everything else in
both. Record: `docs/ios/DECISIONS.md` IOS-018.)*
- **Current:** D98/D99 drew a line — the phone operates the league, the desk
  authors it (wizard dials, lock, assign, overrides, founder desk stay web).
- **Problem:** the first native build read as a quarter of the product, and a
  line drawn before the phone exists is a line drawn from theory. The web is
  the functional truth today; a native surface that lacks any of it cannot
  be judged against it, and the "what should the web be" question cannot be
  answered while the phone is the smaller of the two.
- **Decision (owner):** build the phone to **full parity with the web** —
  every row of the IOS-001 matrix, in the web's own copy and behaviour —
  before native departures, then decide what the web is as a standalone
  product in the Cup Season ecosystem.
- **Principle:** **#5 The app should feel alive** — on the phone, the whole
  product, not a scaffold of it; and the hierarchy of truth: the surface split
  is IA (level 3) and was being decided at level 6 (implementation) by
  default.
- **Benefit:** one complete phone product to measure against; the desk
  conversation happens with two real surfaces in hand.
- **Tradeoffs:** more phone screens than D98 wanted (the wizard on a 6"
  screen, the draft clock); the native-advantage work (IOS-004) waits behind
  parity. Accepted.
- **CONFLICT (named):** D98 "the phone is for the tee box" and D99's
  operating/authoring split — resolved by this entry; the guardrails and
  the backend decisions in both stand verbatim.

### D101 · The league pass is a year, priced under the comps
*(2026-08-27, owner decision in session. BUSINESS level (1–2). Refines D56;
the unit and the numbers change, nothing else in the model moves.)*
- **Current:** D56 — a per-league SEASON pass paid by the Pro out of the pot,
  $49 / $79 / $99 by roster band, first season free, Founding free forever,
  checkout on the web at season 2. Built on the phone 2026-08-27 behind
  `app_flags.pricing.visible = false`.
- **Problem:** "$80 for one season which could be a few months seems steep"
  (owner). The sticker is compared to consumer subscriptions before the
  per-head division lands; a crew that runs spring + fall is asked twice a
  year, and every "run it back" becomes a price moment — the renewal-mistrust
  failure D56 exists to avoid. A pack (N seasons) was considered and rejected:
  credits, breakage, "how many do I have left", and it reads as the
  SaaS-per-seat framing the canon forbids.
- **Recommendation → decision:** the unit is the **league-year**. One pass
  covers every season a league runs in twelve months, the Ryder and Majors
  included; the ask lands once, on the anniversary. Numbers are anchored to the
  per-league comps and cut 25% because the product is new and unproven —
  Golf League Tracker $119/season (≤365 days, multi-league $89–109), Fantrax
  premium league $129.95, MyFantasyLeague ~$110, LeagueLobster $19/mo ($228/yr),
  League Golfer $10–20 per regular per year (a 12-man = $120–240): median ≈
  $120 → **$89** for the standard roster, banded **$59 ≤9 · $89 10–13 · $109
  14+**, fixed at the first roster lock of the year. Per head at every band:
  $6.50–$7.80 a year (vs $50–90 a year per golfer for TheGrint Pro / 18Birdies
  / Golfshot — the handicap is still never resold). First YEAR free (was first
  season). The Pro's sentence: *"The app's $89 for the year out of the pot —
  call it seven bucks a man — and it covers every season we run."*
- **Principle served:** priced against the pot, one number said out loud;
  charge-after-proven-value (a year of it); golf-honest — the price a Pro hears
  at the wizard is the price at the anniversary, and it is lower than every
  comp they can look up.
- **Benefit:** the sticker objection is answered by the unit, not by a
  discount; a two-season crew pays ~$45 a season; revenue per league is equal
  or better; one Stripe product per band, one checkout a year; the
  run-it-back moment goes back to being a celebration.
- **Tradeoffs:** a one-season-a-year league pays for months it does not use —
  the tradeoff of every annual product; they are still under $8 a head and the
  between-season app (rounds, index, the tee sheet) is live all year. The
  anniversary needs a date the pass table will own; until checkout exists the
  phone reads the current season's first tee.
- **CONFLICT (named):** none above business level. Upholds D39 (the pass is
  paid TO Cup Season, the pot is never held BY it), Founding free forever,
  golfer free forever, no pricing on the front door, Stripe parked until the
  first real anniversary. Supersedes D56's unit ("season") and numbers
  ($49/$79/$99); D56's surfaces, kill switch and web-checkout posture stand.
- **Implementation:** migration `20260827170000_pricing_annual.sql`
  (`unit:"year"`, `first_year_free`, the bands; preserves `visible` and
  `founding`), `PricingFlags` (`firstYearFree`, `unit`, legacy key read),
  the three cards' copy, `docs/ios/pricing-surfaces.md` amendment, the
  launch-kit FAQ line, the Season Pass Plan artifact.

### D102 · Founder and Founding Member — two earned tags on the golfer, not the league
*(2026-08-27, owner: "I want my profile to remain tagged as Founder and I may
have some friends as founding member." IDENTITY/UI level; no scoring touched.)*
- **Current:** the web tags the founder's name with `✦ Founder` (`ftag`,
  `founder_id()` RPC, `profiles.is_founder`); the phone reads `founder_id()`
  only to gate the founder's desk. Founding LEAGUES (D56) carry a numbered
  gold badge on the pricing surfaces; people carry nothing.
- **Decision:** two profile-level tags, both earned, both gold. **Founder**
  (exactly one — `is_founder`) and **Founding Member** (a hand-picked set —
  new `profiles.founding_member`, set by the owner in the SQL editor, never
  self-service). One RPC `founding_ids()` returns `{founder, members}` so the
  phone tags a name wherever it appears (the You hero, the Tour Card, the
  feed) with one lookup per session. Copy: `✦ FOUNDER` · `✦ FOUNDING MEMBER`.
- **Principle:** memory & honor — the people who were there first are part
  of the record; gold is for the earned; identity is a fact on the profile,
  not a toggle in a menu.
- **Benefit:** the owner's name is the founder's name in every league;
  friends who help build it are visibly first; the tag survives leagues,
  seasons and the pricing model (a Founding Member is a person; a Founding
  League is a league — the two can be held together or apart).
- **Tradeoffs:** a hand-set column, so the owner is the only writer (the
  intent). Deploy-skew: a phone that calls `founding_ids()` before the
  migration lands falls back to `founder_id()` and shows only the founder.
- **CONFLICT:** none. Upholds D37 (explicit grants, `revoke … from public,
  anon`; the column gets its `grant select` in the same file) and the
  no-silhouette / no-fabrication rules.

### D103 · Homebase palette + seasonal looks — PROPOSED (talk first)
*(2026-08-27, owner: "rethink color schema while I outsource a logo redesign;
a homebase palette so I can add seasonal looks around majors, holidays." UI
level. Nothing built until the owner picks — the proposal is the artifact
"Homebase & the Looks".)*
- **Current:** one palette (D76 Charcoal) in `packages/tokens/tokens.json`,
  generated into `tokens.css` and `Tokens.swift`; preflight 10/15 enforce
  that every colour on either client comes from it. The Home `Occasion`
  calendar already knows the majors (opener · test · oldest · teams · fall ·
  fresh) but only changes a card's copy.
- **Proposal:** (1) **Homebase stays charcoal + ember + champagne** — the
  three non-negotiables of the identity contract — with a defined
  *neutral* ladder and the metals' roles written down for the logo designer.
  (2) A **look** is a small, bounded override set that a calendar window (or
  a league phase) turns on: `accent`, `accent2`, a `wash` pair, a `motif`
  glyph and an eyebrow word. A look may NEVER touch ground, ink, the
  semantic pair (`pos`/`neg`), the heat ramp, the squad colours, or gold's
  meaning — so contrast, meaning and the earned metal are constant across
  every look. (3) Six calendar looks (the Masters · the PGA · the US Open ·
  the Open · the Ryder · the Holidays) plus two phase looks (Cup Final · the
  Wrap) and the Fourth. (4) Looks live in `tokens.json` under a new
  `looks` group and generate to both clients; preflight 15 learns to accept
  a look's hexes from tokens.json (the source of truth), not only from
  `index.html`.
- **Principle:** one identity, many occasions — the way a clubhouse hangs
  bunting for the member-guest and is the same clubhouse in the morning.
- **Open for the owner:** approve the homebase as-is or ask for a warmer /
  cooler neutral; pick the looks; decide whether a look is automatic
  (calendar) or a per-league toggle for the Pro.

### D103a · DECIDED — Fescue is home; leagues wear a look; people pick a look or follow the calendar
*(2026-08-27, owner: "make fescue the default for now, but give the user the
ability to apply a curated palette to a league so they are differentiated,
and users can select a palette or opt for 'follow the calendar palette'."
Closes D103's open questions. UI level.)*
- **Homebase = Fescue.** The ground ladder moves from charcoal to green-black
  (`bg0 #0B100E · bg1 #151C18 · bg2 #1C2520 · line #243029 · line2 #33413A`);
  ink, the two metals, the semantic pair, the heat ramp and the squads are
  unchanged, and the light theme is unchanged (its paper was already
  green-tinted). One edit in `tokens.json`, mirrored into `index.html`'s
  `:root` so preflight 10 holds; the phone regenerates.
- **Looks are a catalogue in `tokens.json`** (top-level `looks[]`, outside
  `groups` so the token lint and the web CSS are untouched): nine calendar
  looks with the windows from the "Homebase & the Looks" artifact (the
  Ryder only in odd years) and two league-phase looks (Cup Final · the
  Wrap). Generated to `CSDesign/Generated/Looks.swift`.
- **Three dials, one precedence.** (1) A league's phase look (Cup Final, the
  Wrap) wins in that league's room. (2) A league's curated look — the Pro
  sets it (`leagues.look`, `set_league_look()`, commissioner only) — dresses
  that league's room and its hero on Home. (3) The person's own dial —
  device-local like the theme (`cs_look`: `calendar` (default) · a look key ·
  `none`) — dresses Home, You and everything not owned by a league. Homebase
  is what shows when nothing applies.
- **What a look touches / never touches:** unchanged from D103 — spine, wash,
  ⊕ halo tint, occasion card, eyebrow word, motif; never ground, ink, the
  semantic pair, the heat ramp, the squads or gold's meaning.
- **CONFLICT:** none. Supersedes D76's charcoal *values* (not its dark-first
  rule). The logo brief in the artifact changes one line: the mark sits on
  Fescue `#0B100E`, not charcoal.

### D104 · Push that means something — routed, actionable, mute-aware, badge for the actionable only
*(2026-08-27, owner: "do wave 7." NOTIFICATION level (UI/IA); scoring untouched.
Executes IOS-009 batch 2 and IOS-004 §4.)*
- **Current:** every push carries title + body and `url:'/'`; `system` posts push
  unconditionally; muting a member does not stop their pushes; `invite_golfer`
  promises a notification and sends none; the phone asks permission only from
  a Settings button; no badge discipline.
- **Decision:** (1) every APNs payload carries `kind` + the ids the phone needs
  to land on the right screen (receipt · scorecard · board · live round ·
  requests · invites · event room) and a `thread-id` per league; (2) three
  actionable categories — buddy request Accept/Decline, tee-time RSVP In/Out,
  league invite Accept — answered from the lock screen through the same RPCs
  the app uses; (3) recipients exclude anyone who muted the author, and
  `system` board posts push only when the league's Pro has not curated them
  off (`leagues.notify_system`, default on); (4) `invite_golfer` fans an
  invite nudge into `push_nudges`; (5) the badge counts ONLY actionable items
  — pending requests + open invites + live rounds you are on — never chat
  volume, and clears when the list is seen; (6) the permission ask is
  contextual — after the card is saved, the first round is posted, or a league
  is joined — with a one-screen explainer first, never on launch; (7) a local
  reminder for an open Ryder duel the evening its session closes.
- **Principle:** memory over noise — a notification is a sentence someone
  would say to you at the bar, not a metric; no engagement bait, no streak
  shame (product vision).
- **Tradeoffs:** a muted member's pushes vanish silently for the muter (that is
  what mute means); the Pro's curation flag hides floors/closes for the whole
  league, so the default stays on.
- **CONFLICT:** none. Upholds the server-enforced `notify_*` prefs, D68 (every
  push exit is named), D37 grants.

### D103b · Fescue deepened; a look reaches further
*(2026-08-28, owner: "let's make our palette shine through more, changing is
hardly noticeable." UI level.)*
- **Problem:** D103a's Fescue values sat within a few RGB points of charcoal
  (`#0B100E` vs `#0C0D0F`) — the green never read; and a look showed only as
  a 14% wash and a 3.5pt spine.
- **Decision:** the ground ladder becomes an unmistakable green-black —
  `bg0 #0B1410 · bg1 #131D17 · bg2 #1A2820 · line #24352B · line2 #34493D`
  (ink/mut unchanged; contrast holds). A look now tints, in order of reach:
  the page-header tick (accent→accent2), every eyebrow and section head, the
  tab-strip underline, the ⊕ halo, the spine of every live card (not only
  the hero), the hero wash at ~30% (was 14%), and an ambient "sky" — a band
  of accent fading down behind the page header. Still untouched by any look:
  ground and ink, primary buttons (ember), gold and its meaning, `pos`/`neg`,
  the heat ramp, the squads, ceremonies and share cards.
- **CONFLICT:** none; refines D103a's values and reach.

### D105 · The Cup Final you can see — the window race is a server view, seeds carry the crown's ladder
*(2026-08-28, from the holistic launch review. Mechanic level (seeding
tiebreak) + UI level (the race surface). PROPOSED — talk first; nothing built
until the owner says so. Sources: spec §14.0/§14.3, `enter_cup_final`
(baseline:287–327), `close_season` (20260724230000:24+), audit 02 §7.7–7.8.)*
- **Current:** §14.0 says "the final four weeks, scored fresh" and §14.3 locks
  the top-2 seeds at `ends_on − 27`. The server does this: `enter_cup_final`
  writes `cup_finalists` and posts "FRESH SLATE, FOUR WEEKS"; `close_season`
  scores the window in an inline CTE (`played_on between ends_on−27 and
  ends_on`, `month_rank ≤ cap`, + `head_start`) and crowns through the
  four-rung ladder, storing the rung. But `v_squad_standings` /
  `v_individual_standings` have no date predicate, so during `cup_final` both
  clients keep rendering FULL-SEASON totals under a header that says "fresh
  slate"; the phone never reads `cup_finalists` at all. And `enter_cup_final`
  seeds with `order by points desc limit 2` — a tie at the cut (or for the
  squads2 +10 seed) is decided by Postgres row order, with no rung stored.
- **Problem:** the flagship moment of the product is invisible — the leader
  watches a lead "vanish" behind a table that still shows it (D4's rug-pull,
  half-fixed: foreshadow shipped, the race itself never did). A tie for a seed
  is unexplainable, which breaks §16 at the one moment the whole season
  points to. The window arithmetic lives only inside `close_season`, so any
  client that computes its own race can drift from the crown.
- **Recommendation:**
  1. **One expression, shared.** Extract the window score into
     `cup_final_race(p_season)` (security definer, authenticated, member-gated)
     returning per finalist: `seed`, `head_start`, `window_points`,
     `rounds_used`, `last_round_on`, `total` (= head_start + window_points),
     and the per-round receipt rows behind it. `close_season` calls the SAME
     function for the crown, so the live race and the ceremony cannot
     disagree (§16: the figure and its receipt are one path).
  2. **Seeds carry the crown's ladder.** `enter_cup_final` orders by
     `points desc, months_won desc, best_month desc, rounds_used asc, coin`
     — the §14.3 ladder applied to the regular season to date — and stores
     the deciding rung on `cup_finalists.seed_rung` (null when points alone
     decided). The board post names it: "SEEDS ARE LOCKED — #2 BY MONTHS
     WON". One ladder, learned once, used twice.
  3. **The race leads the room.** During `cup_final`, Standings opens on the
     Cup Final race: the finalists, `window_points`, the +10 head start as
     its own visible line ("starts +10 · top seed"), rounds used of the cap,
     days left. The regular-season table drops beneath, titled "The regular
     season — final", seeds badged. Non-finalists keep their races (Points
     King, Iron Man, Most Improved) exactly as §14.3 says. Foreshadow (D4,
     `season_scenarios`) is unchanged.
  4. Both clients read the view; neither computes the race locally.
- **Principle served:** §16 (every figure shows its work) · #4 Memory over
  statistics (the Cup Final IS the story) · success metric "understand
  standings in ten seconds".
- **Benefit:** the lead doesn't vanish — it converts into a seed and a head
  start you can see; ties at the cut are explainable in the ladder's own
  words; the ceremony and the live race are provably the same number.
- **Tradeoffs:** one RPC + one column (`seed_rung`) + a re-created
  `enter_cup_final`; the ladder's `months_won`/`best_month` for seeding use
  the months closed so far (the crown's ladder keeps using the full season
  as it does today — unchanged, noted). Solo leagues seed top-2 individuals
  by the same ladder.
- **CONFLICT:** spec §4 (:122) still carries an older Cup Final tiebreak
  ("combined squad PvI for the window; then a playoff round between
  captains"). §14.0 declares §14 supersedes on conflict; this entry retires
  §4's tiebreak formally — the §14.3 ladder is the only one, for seeds and
  for the crown. Vision/principles: none.

### D106 · The pot has two numbers — owed is the roster, collected is the cash, and the ceremony pays from the cash
*(2026-08-28, from the holistic launch review. Closes the ⚑ carried in
`docs/ios/DECISIONS.md:168` and `PHASE-3-WAVE-8-PARITY.md:244` ("needs a
decision-log line before it goes into a store listing"). Mechanic level.
PROPOSED — talk first. Sources: spec §7, `mark_buy_in`
(20260712130000:20–62), `award_season_trophies` (20260725190000:73),
`close_season` payout math, audit 02 §7.6, audit 06 §9.3/§9.7.)*
- **Current:** every surface computes **the pot = buy-in × roster**: the Pot
  tab (`renderPot`, `LeagueRoomModel.potTotal`), the on-the-line bar, the
  covenant ("joining puts you on the pot sheet for $X"), and — decisively —
  `award_season_trophies` / `close_season`, which split buy-in × ALL members
  60/25/15 into `season_payouts` and post "The pot: $X". `buy_ins.paid` is
  bookkeeping only: it drives the "n/N collected" chip and cancellation
  refunds, nothing else. A member who never paid still inflates every
  "You're owed" line in the ceremony (audit 06: "'You're owed' can exceed
  collected cash").
- **Problem:** the ledger promises a truth it doesn't keep. "Owed to the
  pot" and "in the pot" are different facts and the app blends them into
  one number, so at the exact moment money is supposed to move, the champion
  is told a figure that may not exist. Pick one number and you lose either
  the Pro's collection tool (sum-of-paid hides who hasn't paid) or the
  ceremony's honesty (stake × roster overstates the cash).
- **Recommendation — two numbers, always both, never blended:**
  1. **The pot** = stake × roster: what the league agreed to. The roster is
     `league_members` at any moment (join = onto the sheet, per the
     covenant; `remove_member` already deletes the buy-in row). Unchanged.
  2. **Collected** = `sum(amount_cents) where paid`. Already computed for
     the chip; becomes a first-class figure next to the pot everywhere the
     pot appears ("$600 pot · $450 collected · 2 still owe").
  3. **The ceremony pays from collected.** `award_season_trophies` splits
     COLLECTED 60/25/15 (pennies to the champion as today) into
     `season_payouts`, and writes `seasons.pot_cents` and
     `seasons.collected_cents`. The settlement post reads "The pot: $600 ·
     collected $450 · champs $270 · runner-up $112.50 · points king $67.50 ·
     still owed: $150 (Metz, Ed)". "You're owed" can never exceed cash that
     exists. When collected = pot the two lines collapse into one.
  4. **A late payment re-runs the split.** `mark_buy_in` after `complete`
     deletes and re-inserts that season's `season_payouts` from the new
     collected total (idempotent, same function), and posts the delta. The
     ceremony re-renders from the ledger; nothing is hand-edited (§16).
  5. **Clients read, never compute.** The web ceremony (`csSettlement`)
     switches to `season_payouts` + the two stored figures, as the phone
     already does (`PotMath.fromLedger`); the Pot tab and on-the-line bar
     show both numbers from `buy_ins` (no new read).
  6. $0 leagues: D70 unchanged — no pot surfaces at all.
- **Principle served:** §7 "track, never hold — the ledger is the product" ·
  §16 show your work · Principle #3 Real golf, real money between friends,
  no fiction.
- **Benefit:** the settlement card is true on the day it's shared (it is
  the product's best marketing artifact — a false one costs a league); the
  Pro keeps a collection tool that names who still owes; store-listing copy
  ("keeps the pot's books") becomes literally accurate.
- **Tradeoffs:** a champion with a deadbeat teammate sees a smaller payout
  until the Pro marks the payment — that is the truth, and the "still owed"
  line says exactly whose. Two columns on `seasons`, one re-created
  `award_season_trophies`, one branch in `mark_buy_in`, a client read swap.
  Cancellation refunds already use `paid` — consistent.
- **CONFLICT:** none. D39 (ledger, never held) is served, not changed; D70
  untouched; D101 (the league pass paid to Cup Season) is a separate ledger
  and unaffected. Spec §7 gains one sentence: "The pot is what the roster
  owes; payouts are made from what was collected."

### D107 · The tee sheet is the free door — live rounds work without a league
*(2026-08-28, owner: "live rounds/wolf/match play should absolutely work
absent a league and membership. The pay product is the league and events
ecosystem." DECIDED — this entry is the build contract. Mechanic level.
Sources: start_live_round (20260828040000:24), live_sync (20260728120000),
visitor_rounds (20260728220000/D88), client gates index.html:9027/:9453,
LiveRoundStore.swift:227.)*
- **Current:** spec §13.4 says live rounds ship free as the acquisition
  surface, and the guest-claim funnel is the marketing engine — yet the door
  requires the paid product three times over: `start_live_round` demands
  league membership, an active season, and league-member tags;
  `live_rounds.league_id`/`season_id` are NOT NULL; `started_by` is a
  `league_members.id`; every read policy is `is_league_member`; the
  settlement board post needs `posts.league_id`. The web lets a league-less
  golfer score 18 as a local pencil then dead-ends at finish ("tee off
  again", :9453); the phone refuses at tee-off. D87/D88 already carry
  identity for account-less guests (claim tokens) and signed-in visitors
  (`guest_profile_id`) — the free door is two-thirds built.
- **Decision — the free tier is: any signed-in golfer starts a live game
  (Match Play / Wolf / Skins) with anyone.**
  1. `live_rounds.league_id` and `season_id` become NULLABLE; new
     `starter_profile_id uuid not null` (backfilled from `started_by`'s
     member row; `started_by` stays for member rounds). Position cap and
     game set unchanged.
  2. `start_live_round(p_league := null)`: with a league, byte-identical
     behaviour. Without: seats are the starter + guests + app golfers by
     @handle/buddy (all ride the D88 `guest_profile_id` rail); no member
     tags, no season check. Sync join_code, claim tokens, push nudges (to
     seated app golfers only) unchanged.
  3. Access: `_live_member_can` gains the starter-by-profile match;
     SELECT policies gain a participant arm (starter_profile_id = auth.uid()
     OR seated guest_profile_id = auth.uid()) so league-less rounds are
     readable by their players and nobody else. Tables stay RPC-write-only
     (20260828150100 discipline).
  4. Finish: every COMPLETE card posts to its golfer's PROFILE — rounds are
     profile facts already, and `v_rounds_ranked` then scores them in every
     league that golfer belongs to, exactly like a typed post. **This closes
     D88's known gap: a claimed visitor's card now posts at finish** (the
     D88 boundary stands — a visitor scores the round, only the starter ends
     it). Account-less guests still get the recap/claim link, never an
     unwanted account.
  5. No league → no board: the settlement story lives as the share card
     (already league-free, "no account needed") and each golfer's own round
     posts fan to their own leagues via `round_to_board` as usual. The
     wolf/skins ledger (`game_results`) gets the same participant read arm.
  6. Clients: web `#teeOffBtn` persists server-side without `CS.league`
     (drop the :9027 gate; :9453 dead-end disappears); iOS drops the
     LiveRoundStore:227 guard; both setups seat guests + @handle search when
     no league roster exists. The ⊕ door copy already promises this.
- **Principle served:** §13.4 (live games lean free — the acquisition
  surface) · #2 Low Friction · the guest-claim funnel, now measured by
  `growth_events` (D-instrumentation 2026-08-28).
- **Benefit:** the most shareable thing in the product stops requiring the
  thing it is supposed to sell. A Wolf game at a bachelor party becomes four
  claim links, and the funnel is finally observable end to end.
- **Tradeoffs:** two columns go nullable on a table hardened yesterday
  (mitigated: writes stay RPC-only, reads participant-scoped); a league-less
  round has no board story (the share card is the story — accepted); free
  riders can play forever without paying (that is the model: the pay product
  is the league + events ecosystem, owner's words above).
- **CONFLICT:** none upward — fulfils §13.4 against the shipped behaviour
  that contradicted it. Amends D88 (the known gap closes); supersedes the
  three league checks in `start_live_round`.

### D108 · The weekly clash — D52's build packet
*(2026-08-28, owner: "Yes on weekly clash." D52 (2026-07-21) DECIDED the
mechanic and mandated it for launch; this entry is the build plan
gameplay-modes §9b promised. Mechanic level, additive, §5 parallel-ledger
law intact.)*
- **Engine.** New table `week_clashes(id, season_id, week_no, a_member,
  b_member, opened_at, settled_at, winner_member null, a_best jsonb,
  b_best jsonb, unique (season_id, week_no))`. `open_week_clash(p_season)`
  picks the pairing exactly per D52: named rivalry (D21) → closest table
  gap → least-recently-featured (rotation guarantee); both must be active
  members. `settle_week_clash(p_season, p_week)` scores **best
  band-of-week**: each side's highest-points counting-eligible round with
  `played_on` inside the week window; winner takes a headline W into the
  faceted rivalry record ("weekly clash 3–2"); ties are ALL SQUARE (no W);
  both idle settles quiet — row settled, no post (D52's honesty rule).
  **Never cup points.**
- **Cadence rides the daily tick, not the Sunday cron.** §14.0 weeks start
  on the league's real first-tee weekday, so `daily_season_tick` (already
  daily, timezone-aware) detects a week rollover per season
  (`floor((local_date - starts_on)/7)` increments), settles week N−1, opens
  week N. The Sunday `run_week_snapshots` job is untouched (standings
  history is its job, the clash is not).
- **The two posts a week** (D52's "two guaranteed stories"): open — "THIS
  WEEK: JERECHO v MARCUS — THE CLASH" (kind `system`); settle — "MARCUS
  TOOK THE WEEK — beat his number by 3.1 Thursday", with the receipt path
  to both counting rounds. Push rides the curated rails, opt-in, muteable
  (D23's fence).
- **Clients.** A clash chip on the league hero/Standings ("THE CLASH · you
  v Marcus · through Sat"), the pair + best-round-so-far mid-week, the
  result woven into the rivalry facet both clients already render. Receipts
  tap through. Solo and squad leagues both pair INDIVIDUALS; squads are
  irrelevant to the clash.
- **Grants:** engine functions execute-revoked from client roles (the
  12/13/14 discipline); clients read `week_clashes` via a member-scoped
  SELECT policy; all writes through the tick.
- **CONFLICT:** none — D52 already cleared it upward and named the
  surface-count cost as an owner call.

### D109 · ⚑ PROPOSED — the match play tournament (bracket season format)
*(2026-08-28, owner: "a match play tournament format could be cool btw."
Logged, not scheduled. Gameplay-modes §7 item 3 currently says "semifinal
brackets: rejected for now"; the Bracket event tile has said SOON since
July. This entry supersedes neither — it parks the idea with a shape so
the next gameplay session can pick it up.)*
- **Sketch:** an EVENT type (short game, like the Ryder/Major), not a
  league format: 8/16 golfers seeded by index or standings; one live Match
  Play round per bracket window (the D107 free-door engine is the scoring
  surface); winners advance, single elim, optional consolation; the jug
  posts like a Major. Zero cup points; pot optional via the event ledger
  when events grow one (§R12.4, still unbuilt).
- **Why parked:** three event surfaces already ship; D52 (the clash) is the
  committed next mechanic; the five-question filter wants evidence a crew
  would run one — the Ryder's usage after the PIGL TestFlight weekend is
  that evidence.
- **Decision needed before build:** seeding rule, window length, walkover
  rule for idle golfers.

### D110 · The live door leads and wears ember
*(2026-08-29, owner: "the post round and play now can be differentiated
better" — picked "Live leads, ember" from three treatments. UI level.)*
- **Current:** the ⊕ door was three identical rows told apart by a 3.5-pt
  colour tick — and the ticks broke the metals contract: POST wore ember
  (the live metal) while Play now wore squad blue. The composer's "Play
  now" was a dawn text button that read as navigation.
- **Decision:** Play now is the hero — first, taller, ember spine, a
  breathing LIVE word (stilled under reduced-motion), richer sub naming the
  three games and "guests welcome, no account" (it is the D107 free door).
  Post and Plan become quiet neutral-tick rows. The composer pill gains the
  ember dot. Both clients identical.
- **Principle:** the tokens contract (ember = LIVE, gold = EARNED — Plan
  loses a gold it never earned) · D82's three tenses kept.
- **CONFLICT:** none; corrects an accidental inversion of D76/D103's metal
  roles.

**D110 addendum (2026-08-29, owner stuck in the field):** two escapes were
missing. (1) The live SETUP screen was a full-screen cover with no toolbar —
no way out but the app switcher; it now wears Close (before tee-off there is
nothing to abandon; the live stage keeps its own finish/recap exits). (2) The
⊕ opened the composer directly (old rule: cover only when a round was live),
so the three doors D110 just designed were nearly unreachable — the ⊕ and the
Clubhouse record door now ALWAYS open the cover; only explicit "post a round"
CTAs (Home/You links, the postround deep link) jump straight to the composer.

---

## The blind-audit batch — D111–D135 (2026-08-29)

Twenty-five entries proposed together by the remediation plan for the blind
usability audit of 2026-08-29 (`docs/audit/blind-ux-2026-08-29/`), read and
ruled in one sitting. Unless an entry carries its own RULING line the owner
DECIDED it as recommended. Four were put as explicit questions and their
rulings are recorded inside D112, D113, D124 and D132. Nothing in the plan's
Phases 2–6 is built before its entry appears here; the plan's Phase 0 items
restore decisions already logged (D40, D58, D14, D47, D13, D66, D106) or are
tooling, and needed no entry.

Spec amendments this batch carries: §7 (buy-in default $0 — D113), §14.1 (a
round scores for a league only inside its season window — D122), §3.3 (squads
are not size-adjusted — D120's note), §14.3 (the endgame is stated on every
surface, not only inside the window — D126); §5 and §6 gain the D124 and D125
notes.

### D111 · The lock is one server transaction — `lock_league`
*(2026-08-29, blind UX audit TOP-1 (M-001, M-017, M-007; Appendix A #1, #14). Mechanics + implementation, levels 4–6. Enforces CLAUDE.md "writes with game consequences go through security-definer RPCs". PROPOSED — talk first. Sources: `lockBylaws` `index.html:15122–15218`, `WizardService.lock` `WizardService.swift:109–146`, RLS `settings_write` baseline `:2313` / `leagues_update` `:2156`, `form_squads` `20260711130000`.)*
- **Current mechanic:** "Lock" is four client writes plus one RPC in the client's order — `league_settings` (+ `locked_at`), a dead `invites` insert, `seasons` reuse-or-insert, `form_squads`, `leagues` phase + name — with no transaction, no idempotency, and the next phase derived from LOCAL `state.structure`. The phone ports the same five-write sequence. A member's settings write is filtered to zero rows by RLS with no error; only `form_squads` happens to raise.
- **Problem (measured 2026-08-29):** a client exception after the commit (`staged is not defined`, `:15218`, shipped by D97 on 08-04) narrated a committed lock as "Lock failed" for both audit organizers; prod `lock_ok` = 1 all-time, `lock_fail` = 11. A retap after a partial lock rewrote bylaws-adjacent rows non-idempotently and left Desert Dogs at `structure=squads2 · phase=season · two empty squads · one member` — a state §15 forbids. Two codebases carry the hazard.
- **Recommendation:** one SECURITY DEFINER `lock_league(p_league uuid, p_bylaws jsonb default '{}') returns jsonb`: bylaws + `locked_at`, season 1 reuse-or-insert, `form_squads`, and phase **from the stored structure** (`solo → season`, else `draft` — today's rule), in one transaction; idempotent — when `locked_at` is already set it rewrites nothing, finishes a partial lock whose phase is still `setup`, and returns `{phase, season_id, starts_on, ends_on, code, already_locked:true}`; plain-English raises; D37 revoke/grant. Both clients call it; the direct writes go. A follow-up migration, after both clients are live, drops `leagues_update` and `settings_write` — phase and bylaws are written only by RPCs (`lock_league`, `start_season`, `set_league_finish`, `close_season`, `transfer_pro`, …). The one-line crash fix and the commit/celebration split ship first and alone (rule 3).
- **Principle served:** Principle #2 (the lock is one tap and cannot lie); spec §8 / §15 as invariants, not sentences (D58's own reasoning); the CLAUDE.md architecture rule; D40 (the lock is the moment the league opens).
- **Benefit:** the crash class becomes unreachable after a commit; retaps are safe on both clients; one implementation, one bug surface (D100 parity at the RPC, not in two ports).
- **Tradeoffs:** a migration and two client builds for a bug a one-liner hides today (the one-liner ships regardless); the phone has no legacy fallback, so the policy drop waits for its TestFlight build. Solo → `season` at one member is kept as-is (spec §8's "min 4" vs D58's solo exemption is an open question, not decided here).
- **CONFLICT:** none upward. Retires the four direct writes; supersedes nothing logged.

### D112 · Membership opens at lock — the join paths refuse a setup-phase league, and the setup code displays hide
*(2026-08-29, TOP-1 root-cause lens + the TOP-3 validators (M-020, M-022, M-030). Mechanic level (who may join when) + implementation. Sources: `join_league` `20260714040000:21–38`, `respond_invite` `20260729180000`, `add_friend_to_league` `20260712050000`, `invite_golfer` `20260827210000:55`, D40 `decision-log.md:1139`, the pilot fix "Add golfers always works" `index.html:3373–3376`.)*
**RULING (owner, 2026-08-29):** DECIDED as recommended — enforce D40. `join_league`, `respond_invite` and `add_friend_to_league` refuse a `setup`-phase league; inviting still always works. The alternative (amend D40 to "invites open at creation") was declined: consent to a moving target was the objection.
- **Current mechanic:** D40 (2026-07-20) ruled "members can only join a locked league" and "the public share link/code moves to AFTER lock" — and the code accepts a join in every phase; the code is printed in setup on three surfaces (`#phaseSub` `:12207`, `#hhCode` `:3366`, `#setupInviteSub` `:12840`), which D40 deferred as "harmless"; `switcherChip` says "Setup — invites open" (`:15512`, `:12874`). A finished (`complete`) league is joinable by code too.
- **Problem:** D40's routing backstop was load-bearing and the hero (D96) walked around it; a friend who joins an unlocked league consents to a stake — the $75 nobody chose — that is not yet fixed (S3-01's covenant becomes consent to a moving target); the pot's "owed" number (D106) is a guess while the roster can exist before the stake is set.
- **Recommendation:** one migration: `join_league`, `respond_invite` (league invites only) and `add_friend_to_league` raise in phase `setup` — "*<League> isn't open yet — the Pro is still setting the bylaws. Try the link again once it's locked.*" — and in `complete` — "*That season is finished — ask the Pro to run it back.*" — sentences the clients pass through verbatim (the `humanError` allowlist). `invite_golfer` is unchanged: the Pro may stage invites pre-lock; accepting one before the lock returns the same sentence. The three setup-phase code displays hide; `switcherChip` reads "Setup — not open yet". `join_covenant_info` returns `phase` so the door can say "not open yet" before the OTP round-trip. D37 discipline on all three.
- **Principle served:** correctness > early seat-fill (D40's own line); S3-01 — a covenant is consent to fixed terms; §7/D106.
- **Benefit:** every member of every league joined a locked league, so the member hero always has dates; no joiner consents to $50 and finds $75 at lock; the pilot's "joined a My Cup scaffold" becomes impossible by construction.
- **Tradeoffs:** a Pro who already texted a pre-lock code sends friends into a refusal — the sentence names the fix and the Pro's Home says "Lock it in" until they do; no seat-filling before the lock (D40 accepted this; the invite sheet is one tap later). §15's late-joiner rule (thinnest squad, logged) is NOT built for joins after `start_season` — flagged, out of scope.
- **CONFLICT (named): D40 vs the shipped "Setup — invites open" copy and `join_league`'s missing guard — D40 wins.** The pilot fix "an unlocked league showed no add path at all — this button always works" is kept for *inviting*; *becoming a member* waits for the lock. **Alternative for the owner:** amend D40 to "invites open at creation" and land pre-lock joins on the member/setup hero cell with a covenant line "the bylaws aren't locked yet — the Pro can still change them"; then the lock vocabulary flips the other way. One of the two; the copy cannot be honest with neither.

### D113 · Buy-in defaults to $0 at every layer
*(2026-08-29, TOP-1 (M-004, M-005, M-008; Appendix A #11, #22). Money model, level 4, with a spec conflict. Sources: baseline `:1082`, `create_league` baseline `:237`, `#stakeVal` `index.html:3263`, `resetWizard` `:14088–14097`, `applyBylaws` `:14349–14351`, spec §7, D46 `:1333`.)*
**RULING (owner, 2026-08-29):** DECIDED as recommended, and the backfill is APPROVED — the migration zeroes `buyin_cents` on unlocked (`setup`-phase) leagues only, never a locked one. Spec §7 is amended to "$0 by default (bragging rights); $25–$200 when money's in play".
- **Current mechanic:** spec §7 "Buy-in $25–$200 (default $75)"; `league_settings.buyin_cents DEFAULT 7500 NOT NULL`; `create_league` inserts the default; the wizard's `#stakeVal` is static `$75` markup behind "Customize"; `resetWizard()` zeroes `state.stake` but never re-renders; `applyBylaws()` reloads 7500 on any re-entry; `join_covenant_info` serves it to any pre-lock joiner.
- **Problem:** two of two organizers met a $75 stake they never chose (the novice's P0); prod holds seven unlocked July leagues at 7500; label and state disagree in-session ("one tap of − from $75 goes straight to None"); D46 said "$0 bragging rights is first-class and the default … surfaced so it's seen, not buried" and the schema never followed.
- **Recommendation:** `alter table league_settings alter column buyin_cents set default 0`; `create_league` inserts an explicit 0; `#stakeVal` "None"; `resetWizard()` re-renders; the buy-in row moves from `#wizDials` to above "Use these defaults →" with the D39 fine line "The pot lives on the books — money moves between you"; spec §7 → "Buy-in $0 by default (bragging rights); $25–$200 when money's in play". Backfilling the seven unlocked prod leagues is the owner's call (the statement ships commented).
- **Principle served:** D46 (money is a choice, not a default); D39 (ledger language); Principle #2.
- **Benefit:** no covenant ever asks a friend for money the Pro did not choose; label, state and row agree on every path.
- **Tradeoffs:** money crews take one more tap; the pot ritual is undersold for them (D46 accepted this). One dial leaves the single Customize disclosure.
- **CONFLICT (named): spec §7 "default $75" vs D46 "$0 default" — D46 wins, §7 amended.** A-W3's "everything else behind Customize" vs D46's "seen, not buried" — D46 wins for this one row.

### D114 · The invite sheet — the URL as text, Copy link, Copy message, on every share control
*(2026-08-29, TOP-1 (M-002, M-003, M-020, M-022, M-027). IA, level 3. Extends A-W2 / D40 / D97; builds `spec/gtm-year1.md:97–99` ("make the invite carry a preview"). Sources: `openLockShare` `index.html:14135–14167`, `shareInvite` `:14114–14129`, the five share controls, `Cup-Season-Guide.md:107`.)*
- **Current:** `openLockShare` is the only surface that prints `cupseason.app/?join=CODE` as text and is reachable only from the lock's success path; every other share control — `#draftShare`, the `.copycode` chip, Members `#msShare`, the covenant `#cvShare`, the picker's "Share an invite link instead" — calls `shareInvite()`, whose last fallback is a 2.4-s toast with the bare code. The Guide claims invite-by-email; nothing sends one (`invites` has no consumer).
- **Problem:** 7 of 7 web personas never saw a link (headless caveat: a phone gets the OS sheet first — but the desk, where the wizard lives per IOS-007, is where share/clipboard are least reliable); the Pro cannot paste anything into a group text; the Guide is a false map (D97's own principle); no surface says "N in · need K".
- **Recommendation:** promote `openLockShare` to `openInviteSheet(L)`: the URL as selectable mono text; **Share…** (OS sheet when present); **Copy link**; **Copy message** — one `inviteMessage(L)` on both clients: "{Pro} invited you to {league} on Cup Season — {n} in · first tee {date} · {"$N a player, on the books" | "bragging rights — no buy-in"}. Review and join: <url>" plus the covenant's three things to know; the seat line "N in · K more to tee off"; a Pro-only "Preview what they'll see". Every share control routes here when the OS sheet is unavailable or fails; a clipboard failure reads "Copy didn't work — long-press the link", never "sign in again". The same message is the OS-sheet text. Contact (email/SMS) invites are **not** built by this entry; the Guide is corrected to the link-first design; a Brevo-backed mailer is its own future decision (the transactional path exists in `supabase/functions/push/index.ts:290–303`).
- **Principle served:** Principle #2 (the computer writes the message); GTM year-1's leading indicator (invite → accept); D97 (no false map); D57's artifact posture.
- **Benefit:** the five friends can be invited from the app without the organizer composing instructions; the funnel's first edge (`artifact_shared → link_opened`) becomes measurable from every control.
- **Tradeoffs:** one more sheet on the phone where the OS sheet already works (the phone keeps `ShareLink` first; the sheet adds Copy message and the seat line only).
- **CONFLICT:** none upward; refines A-W2's IA without reversing it.

### D115 · The code opens a prospectus; the covenant is the decision sheet
*(2026-08-29, TOP-2 (M-023, M-024, M-026, M-133, M-020). IA level. Extends setup-QA S3-01 (`spec/setup-qa-findings.md:62`) and D57's anon-window law. Sources: `join_covenant_info` `20260722211500:29–42`, `covenantGate` `index.html:15422–15440`, `league_by_code` `20260714040000:14–19`, the share text `:14118`.)*
- **Current:** `join_covenant_info` (anon) returns name · buy-in · preset · floor · finish · structure; `covenantGate` renders four of them under "THE FINE PRINT, UP FRONT" and "Join — I'm in for $50"; `league_by_code` returns the name only, so the invite door says "You're invited to The Papago Grind" and nothing else. Nothing before `join_league` names the Pro, the roster, the dates, the bands, the split or how the $50 is paid.
- **Problem:** S3-01 scoped the covenant as a *money disclosure*, not the joiner's *decision surface*. Joiner verdict 3/10 ("I did not know who was in it — not even that Casey ran it"); the skeptic named the sheet as the bail point ("wait, fifty bucks for what?"). Growth is foursome-by-foursome with no paid acquisition, so the invite must sell itself. Every fact the joiner lacks is one join away in the database and deliberately not fetched.
- **Recommendation:** (1) **one RPC, richer, same signature** — `join_covenant_info(p_code)` gains, all nullable for skew: `pro_name`, `pro_marker`, `member_count`, `members` (name + marker, first 8; `discoverable='nobody'` → marker only; **signed-in callers only** — a bare link is not a roster reader), `phase`, `starts_on`, `ends_on`, `weeks`, `season_status`, `counting_cap`, `floor_penalty`, `draft_type`, `payout_*`, `pot_cents` (buy-in × roster — D106's *owed* number). **Never** email, handle, index, or the allowance (D2/D48); never the payment note (D129). Fail-closed null on an unknown code. (2) **The invite door renders a league card above the email box** when a code is pending: name · "Casey runs it (THE PRO)" · "5 in" · dates + weeks or "forming · first tee not set" · structure + draw · "$50 buy-in → $250 pot · 60 / 25 / 15" · the Guide's own sentence · "How scoring works →"; the status line reads "Sign in to join — you'll confirm the $50 before anything's final." (3) **The covenant becomes the decision sheet**, same two buttons: WHO · WHEN · HOW ("scored against your own number · 5–12 pts a round · best 4 a month count") · FLOOR with its consequence · FINISH in a sentence · STAKE ("$50 → $250 pot · champs 60 / runner-up 25 / points king 15 · you settle with Casey directly — Cup Season keeps the ledger; the money moves between friends") · PRESET (tappable) · D50's parked paragraph · "How scoring works →". A $0 league gets the same sheet without the STAKE row and a plain "Join" (D70 forbids pot *surfaces*, not disclosure). (4) The share text carries the offer (D114's `inviteMessage`).
- **Principle served:** product-vision #2 Low Friction ("join a league in under 30 seconds · never need a tutorial" — the tutorial is currently the friend); spec §7 and D106; spec §16; D57 (a curated, fail-closed SECURITY DEFINER window — never an anon table grant).
- **Benefit:** the invite is a yes-to-a-thing; "fifty bucks for what?" is answered on the same sheet as the button; the pot's purpose and payee are stated pre-commit; the Pro's recruiting is done by the artifact.
- **Tradeoffs:** the code becomes a read credential for the Pro's name, roster size and dates (it already leaks the name; names stay behind sign-in by default); one more payload to keep true on two clients; the sheet is longer — mitigated by D116's one-fewer-screen.
- **CONFLICT (named):** none with D83 (the cold door is D117's). Amends S3-01's scope from disclosure to decision. Restates D39's ledger language in the STAKE row (the audit's "never the cash" wording is rejected) and withholds the allowance per D2/D48 (the audit's `allowance_pct` is rejected).

### D116 · Consent on every join path; a decline is a state, not a loss; the invitee skips the orientation
*(2026-08-29, TOP-2 (M-025) + Appendix A #15. IA/flow level. Two of its three parts restore S3-01 and need no new ruling; the third AMENDS D82. Sources: `boot()` `index.html:17506–17515`, `#wCodeGo` `:17384–17396`, `resumeAfterProfile` `:17557–17575`, the card-save handler `:13190–13195`, `RootView.swift:31`.)*
- **Current:** three of five signed-in join entrances pass `covenantGate`; two do not — `boot()`'s pending-code path and the league-less Clubhouse's `#wCodeGo`. `resumeAfterProfile` removes `cs_code` BEFORE the sheet ("so a failure can't loop"), so "Not now" leaves a toast, a "None yet" tile and an empty code box; the phone clears `JoinIntent` in `.onAppear` before its sheet even opens. A first-timer arriving by invite sees the D82 orientation *before* the covenant that the code's own comment calls their teaching (`:17552–17555`).
- **Problem:** a returning user who taps a link is put on a pot sheet with zero disclosure (an S3-01 violation on the highest-value funnel); a declined invite is indistinguishable from a failed one; an invitee sees three teaching screens where one is theirs.
- **Recommendation:** (1) every signed-in `join_league` call is preceded by `covenantGate` — no exceptions, and a grep-able rule above the function. (2) The loop guard protects the *attempt*, not the *sheet*: `cs_code` is removed only when the golfer taps Join; "Not now" moves the code to `cs_invite_declined` (code · name · timestamp), which `boot()` never auto-joins from; Home's league tile and the phone's league-less doors render **"Invited · The Papago Grind · REVIEW"**; Review reopens the covenant with the code; the Join sheet pre-fills; "Not interested" and sign-out clear it. (3) For `viaInvite` the D82 orientation is skipped — door(card) → email/code → golfer card → covenant → welcome; `cs_oriented` is still set so it never fires later by surprise; You › How it works reopens it.
- **Principle served:** S3-01 on *every* path; product-vision #2 (one fewer screen for the path most recipients take); D27's spirit.
- **Benefit:** the "Not now" cohort is recovered instead of lost; the returning-user link path is honest; the invite path is one screen shorter.
- **Tradeoffs:** one more localStorage/UserDefaults key on each client; a declined card sits on Home until dismissed (bounded: one card, one league).
- **CONFLICT (named): AMENDS D82** ("ONE skippable orientation screen after the golfer card") for invitees only — the covenant + welcome carry the same two teachings for them. No conflict with D83.

### D117 · The door says the sentence; the orientation defines the four nouns — D83 and D82 amended, not reversed
*(2026-08-29, TOP-2 (M-143), the iOS survey (M-144 "the screens do not say what the game is"), terminology (M-060). UI-copy level. The validators refuted "the slogan door is a defect" — D83 is an owner decision — and asked for an amendment. PROPOSED — owner's call. Sources: the door `index.html:2635`, `<meta name="description">` `:22`, the orientation `:2700–2718`, `ForgeView.swift:161`, `GuideCopy.swift:38–48`, D82, D83.)*
- **Current:** the signed-out door is the wordmark, "Rally your crew. Post real rounds. Take the cup." (iOS drops even "Take the cup."), two buttons and the Terms line. The product's one-breath definition — *"Season-long golf with the people you already play with — points, pot, pressure."* — exists only in the meta description. The D82 orientation teaches the four places and the two ways to play without saying what a cup, a squad or the Pro is.
- **Problem:** 8/8 could not define the product's own name; five of eight said the door "is a slogan, not a mechanism"; the first sentence anywhere that says what a season is lives at the bottom of the You tab.
- **Recommendation:** (1) ONE line under the slogan on both doors, sourced verbatim from the meta description (never a third paraphrase — D82's "copy must be kept true"). (2) A quiet **"How it works"** link on the Terms line opening a three-row sheet built from the existing `GUIDE.games`, `GUIDE.posting` and the scoring bands — no new copy, callable signed-out. No demo, no cards, no pricing (D56/D101). (3) The orientation's long-game card gains one line: "A league — months long. Every round you post scores against your own number and counts toward your squad's table. The Pro runs it. The cup is the season title." (4) You › How it works gains no rows; the join-link door keeps D115's card with the sentence above it.
- **Principle served:** #2 (a visitor who wants the mechanism gets it in one tap; one who doesn't loses nothing); #3 Real Golf (no fiction returns — this is the opposite of the demo D83 retired); D82's own rule that the model must survive first contact.
- **Benefit:** the door answers "what is this" in one line and "how does it work" in one tap, for the first time on a phone; the four nouns every screen assumes are each defined once, in the one screen every user passes.
- **Tradeoffs:** one line of copy on the most-seen surface; the orientation card gains 24 words; D84's wings debt is untouched.
- **CONFLICT (named): amends D83**'s "the door sells with its own splash, not a fiction" — the splash stays; a sentence is not a fiction. **Amends D82** by one definition line, no new rows. Does not reopen D84.

### D118 · Strangers in the invite picker — exact @handle, or a buddy
*(2026-08-29, TOP-1 (M-019). Social-graph mechanic, level 4. Sources: `profiles.discoverable` default `20260712010000:16` ("hub valve one tap away"), `search_golfers` via `index.html:13398`, `openInvitePicker` `:16604–16619`, the Card's "Findable by" `:13741–13745`.)*
- **Current:** `discoverable` defaults to `'everyone'`; `search_golfers` returns any discoverable profile on a one-letter query; the invite picker lists strangers with [Add]; the Card shows "Findable by: All" selected.
- **Problem:** an organizer searching a friend's handle got two strangers with [Add] — an invite to a league with a pot can reach someone who has never met the Pro; the invitee's accept/decline protects the invitee, not the picker's intent.
- **Recommendation (A, recommended):** in invite mode, rows with `rel==='none'` are labelled "Not a buddy" and addable only on an exact `@handle` match; name search lists buddies and request-able golfers as today; the default stays `'everyone'`. **Option B:** additionally flip the default to `'friends'` for new profiles (existing rows untouched) — a stronger privacy posture that makes "find my friend by name" fail until they buddy up.
- **Principle served:** Principle #3 (real friends); D23's no-shaming fence; the consent posture of `20260713180000`.
- **Benefit:** no accidental stranger invites; the founder's discoverability (D102) unaffected.
- **Tradeoffs:** one more step to invite a golfer you know by name but not handle; B trades friend discovery for privacy.
- **CONFLICT (named):** the migration's own rationale "discoverable defaults to 'everyone'" (a level-6 comment, not a logged decision) — A keeps it; B overrides it.

### D119 · The member's Home — the hero is a role × stage matrix, and the wizard is the Pro's by rule (D40 restored over D96)
*(2026-08-29, TOP-3 (M-030, M-033, M-041, M-032, M-016). IA + UI level — the hierarchy is the fix. Sources: `renderHomeHero` `index.html:10071–10116`, `switchView` `:4153–4200`, `enterLeague` `:14494–14501`, `#wizCancel` `:15527–15538`, `home-arc.md` §2 row 4, D40 `:1139`, D96 `:3422`, `HomeView.swift:566–568`.)*
- **Current mechanic:** D40 ruled "a member must never see the Pro's configuration tool" and built it once, as the `enterLeague` route. D96 gave the forming hero a CTA — "Lock it in and invite your crew" → wizard step 2 — reasoning only about the abandoned solo Pro; its tradeoffs never mention a member. The hero has no role test and no setup/draft test; `switchView` has no wizard gate (`:4163` even redirects `draft → wizard`); `#homeSetup`'s Continue and `#wizCancel`'s native "discards it completely" confirm are unguarded; `renderProChip` stamps whoever is signed in as "THE PRO · you run this league". The Start/Start/Join doors lead Home for every account (D94's own "thing to watch").
- **Problem (audit):** four of four player personas met the Pro's lock button as the biggest thing on their Home for the whole pre-tee window; two refused to press it for fear of locking the friend's league; one walked back to a step naming *him* the Pro and a Cancel offering to discard the league — refused only by the server. The Pro of a league the server had locked was still told "Lock it in". No member persona could say what to do next. Members are 80–90 % of every league and this is their first week.
- **Recommendation:** (1) the hero is a **role × stage** matrix — (Pro | member) × (setup | draft | preseason), every cell with a move the viewer can make: Pro/setup keeps D96; Pro/draft "Draw the squads" (+ share the link); Pro/preseason "Plan the first round"; member cells name the Pro, the date and the member's own move ("Plan a round" on the D107 tee sheet; "Post a practice round — it builds your number"), every number read from the bylaws. (2) The D40 guarantee moves to the one choke point: `switchView('wizard')` bounces a non-Pro to Home with "Only the Pro edits the bylaws"; the draft→wizard redirect, `#homeSetup`'s Continue, `#lockBtn` and `#wizCancel` are role-aware; the native `confirm` becomes an in-app sheet; the wizard names the league it is editing. Server-side the guarantee is by construction once D111 lands. (3) A member's "See the squads" is read-only with a back link and member-voiced copy (restores S3-04/D58). (4) **AMENDS D94:** for a golfer with an active membership the three doors collapse to one quiet "Start something…" link; league-less accounts keep the doors leading (D94's reason was the young product's need for *first* leagues, which a member already has). (5) `home-arc.md` §2 row 4 gains the role column and the draft branch.
- **Principle served:** #5 The App Should Feel Alive — "what do I do now?" answered for the member, not only the Pro; #2 Low Friction — the Pro's one-tap lock (D40's mitigation) untouched; D27/D81 "a hero with no move is a stall" applied to the people D96 forgot.
- **Benefit:** every joiner gets a concrete first action on the day they join — the precondition for the first-round loop; the near-destructive path disappears; the "is this my job?" doubt four personas logged is gone.
- **Tradeoffs:** the hero grows six cells (one dispatcher, a 3 × 2 walk before commit); the member's pre-tee verb depends on D122's sentence being true on the post form (until then the practice link says only "builds your number"); the doors' demotion changes Home's opening voice for members (D94 called this the thing to watch — the audit watched it).
- **CONFLICT (named, resolved): D96 vs D40.** D96 put a wizard door on Home without re-reading D40, and D40's premise was never enforced (D112). Resolution: D40 wins at the IA level; D96's CTA survives *for the Pro* and gains the draft branch it lacked. **Amends D94** (the doors). The decision log did not record the regression until now.

### D120 · One league stage, one vocabulary — `leagueStage()` and `seasonState()` feed every status string and every season-aware sentence
*(2026-08-29, TOP-3 (M-041, M-021, M-084, M-130) + TOP-4's "two definitions of season" (M-040, M-043). UI level with an IA spine; both clients. Sources: the twelve web sites (`index.html:10103, 15511, 9797, 9848, 12873, 12207, 12229, 3414, 3428, 14710, 11940, 4692`), `atStarter()` `:11981`, the counts predicate `:6588–6590`, `LeagueCopy.swift:145–197`, `Models.swift:180–198`.)*
- **Current mechanic:** the league lifecycle is `leagues.phase` (setup → draft → season → complete) plus `seasons.status` (cup_final, complete) plus the calendar (`atStarter()`, `isCupFinal()`). Twelve web renderers each re-derive a label in their own words — one is dead code, one contradicts D40 ("invites open" in setup), one borrows the retired draft engine's vocabulary ("CAPTAINS READY"), one is pushed regardless of phase ("is live — post the first round"); the Home hero keys "season" on `state.phase==='season'` while the Clubhouse keys it on `atStarter()`; the post handler carries the only season-window predicate. The phone has the same problem in five places and collapses setup and draft into one `.forming`.
- **Problem:** the same locked, undrawn league read FORMING (Home), Squad formation (room chip), SQUADS ARE FORMING (Standings), LIVE NOW — CAPTAINS READY (League tab), "is live — post the first round" (Board) and SQUADS LOCKED (Clubhouse banner) at one moment; Home said "Rounds count from today" while the Clubhouse said "practice rounds hit your card". Logged by all six web personas.
- **Recommendation:** one classic-side `leagueStage(m?)` → `setup | draft | preseason | season | cup_final | complete` (`null` in demo so every demo branch stays; accepts a membership so a row needs no room load) and one `STAGE_LABEL` table (short + long per stage) consumed by every site; plus `seasonState()` → `{stage, firstTee, firstTeeText, window, counts(playedISO), sentence}` so the post form, the ceremony, the receipt and the empty states read one producer (D122's phrases). Proposed vocabulary (owner's call): **Forming → Squads drawing → Before first tee → Season live (Week n of N) → Cup Final → Season complete**; solo leagues skip "Squads drawing" and never say "squad". Retired from status copy: "captains", "LIVE NOW", "SQUADS LOCKED", "invites open", "The Pro has the list", "rosters locked/pending"; seat counts read the structure's minimum ("1 in · need 4 to tee off"), never "seats open"; the Board's empty line is stage-aware. The phone's `LeagueStage` is the same enum with the same table; `SeasonPhase.forming` splits into setup and draft.
- **Principle served:** §16 (a stage word is a number's frame); #2 fewer words for one fact; D47's one-noun discipline; §15/D105 (captains leave status copy).
- **Benefit:** the five-way contradiction collapses to one string; the Pro can answer "is setup done?" and the member "what stage are we in?" from any screen; T4's sentences and T3's labels cannot drift apart.
- **Tradeoffs:** ~12 web renderers and 5 iOS copy functions touched in one pass (pure-function tests in `app-tests.js` and `LeagueRoomTests`; the iOS tests that pin today's strings are rewritten, not deleted).
- **CONFLICT:** none upward. Corrects two lower-level contradictions of D40 ("invites open") and §15/D105 ("captains").

### D121 · One hero, and a compact row for every other league — a minimal amendment to D94
*(2026-08-29, TOP-3/TOP-5 overlap (M-072 — A7, the only tester living two real leagues). IA level. Sources: `renderHomeHero` `:10015–10018`, `loadMemberships` `:14331–14339`, the toast `:17536`, `renderClubGroups` `:9842–9855`, `native_home()` `20260827130400:299–320`, `HomeMode.of` `Models.swift:200–212`, D81, D94.)*
- **Current mechanic:** D81 made Home one hero slot; D94 measured and rejected the four-quadrant Home and kept the tiles. The hero renders the *loaded* league (`cs_last_league`); the other memberships exist only as Clubhouse switcher chips. Boot toasted "Switch groups anytime from Home", which was false.
- **Problem:** the observer's second league, and the 10-point deficit that should pull him back, was invisible until he happened to open it ten minutes in. Two-league golfers are the founding-league reality (PIGL + a buddy's league).
- **Recommendation:** keep the single hero (D81/D94 stand). Directly under it, above the tiles, one compact 44-px row per *other* active membership: `name · stage (D120 short) · your standing when in season · "you are the Pro"`; tap → `enterLeagueById(id)` and Home re-renders around that league; rows cap at three, then "and N more → Clubhouse"; the row hides when there is one league. Data from `native_home()` on the web (already granted; the phone reads it today and it carries `phase`, `season`, `standing`) — no migration; the skew fallback is `loadMemberships` with a phase-only stage. On the phone `HomeMode.of` keeps choosing one membership and the same rows render beneath `HomeHero`.
- **Principle served:** #5 alive — the deficit in the other league is the thing that changed while you were away; #2 fewer doors — the row *is* the switcher, so the toast's promise becomes true instead of deleted; D94's "one authoritative surface per question" — the row is a door, not a second standings.
- **Benefit:** a golfer in two leagues sees both standings on the first screen; "switch from Home" is finally where it says it is.
- **Tradeoffs:** ~48 px per extra league above the tiles; one more RPC on Home for the web (cached with the boot).
- **CONFLICT:** **amends D94** (one element between hero and tiles) and D81 (a new row type in the lane); does not reopen the rejected four-quadrant Home; the feed-stays-whole rule is upheld.

### D122 · A round scores for a league only inside its season window — the rule is written down
*(2026-08-29, TOP-4 (M-040, M-043). Mechanic level: the rule already IS the engine; this entry logs it so a phrase family can exist. Sources: `v_rounds_ranked` baseline `:1370`, the post handler `index.html:6583–6594`, commit `75682a1`, R10 in `rules-and-mental-model-audit.md`.)*
- **Current:** `v_rounds_ranked` joins `seasons` on `played_on between starts_on and ends_on` (status active/cup_final/complete), so a round dated before first tee — or outside the window, or posted by a league-less golfer — earns no league points and never appears in a standings row. It still lands on the golfer's Tour Card and feeds the handicap engine. No sentence in spec §14 or this log says so; the pilot fix (2026-07-24) encoded it at the finish screen ("COUNTS ON YOUR CARD") and nowhere else.
- **Problem:** six of six audit posters were promised "LEAGUE POINTS THIS ROUND 5/6/12" seven days before first tee, saw "R 0 · Pts 0", and were told "post one and you're on the board" by their own row. Every surface improvised because there was no canonical phrase — and every new league's first week is pre-season by construction (`defaultStart()` = next Saturday).
- **Recommendation:** add to spec §14.1: *"A round scores for a league only if its date falls inside that league's season window; it is scored at the league's allowance. Rounds before first tee — or outside the window — post to your Tour Card and build your number; they earn no league points."* One phrase family derives from it and is the ONLY copy used for the state: before first tee **"Practice — season starts Sat Sep 5. This round builds your number; no league points yet."** (weekday derived, §14.0 v1.1) · backdated/after **"Outside the season window — on your Tour Card, no league points."** · no league **"On your Tour Card — join a league to score it."** "Builds your number" is said only when `profiles.index_source` is `app` (or null). The form, the finish ceremony, the epilogue title, the receipt's League row, the standings empty state and the You tab read the phrase from D120's `seasonState()`.
- **Principle served:** §16 ("0" is a figure and needs its work); #2 (one rule, one sentence); the no-tutorial success metric.
- **Benefit:** the first post stops breaking a promise; Home, Clubhouse, form, card and receipt say the same thing on the same day.
- **Tradeoffs:** the pre-season "12" was a small dopamine hit — kept as the band phrase ("beat your number by 3.3") with the points withheld; multi-league members get one line per league where it matters (receipt), the open league elsewhere (D81/D94).
- **CONFLICT:** none upward. Related, unchanged: spec §9 ("posts accepted 7 days after play, later needs override") is not enforced anywhere and stays a separate open item; D47 honoured — the phrase says **Tour Card**, never "your card".

### D123 · One PvI per round — the league lens everywhere, the preview included
*(2026-08-29, TOP-4 (M-047, M-049, M-046). Mechanic-adjacent: spec §2.1 defines PvI as `Playing Index − Differential`, `Playing Index = Index × Allowance`; this entry makes every surface obey it. Sources: baseline `:1359–1364`, `home_feed_photo:51`, `tour_card_form:51/67`, `round_card:128–133`, `index.html:6315, 11547, 11578, 16641`, `BoardTests.swift:16–21`.)*
- **Current:** the server view scores at the league allowance; the client preview, the Home feed, You/career, the Tour Card and both receipt fallbacks compute `index_at_post − differential` at 100 %. Under Standard (95 %) a ~13-index gets two numbers 0.7 apart for one round, which straddles a band: the owner's Aug 16 round is "beat your number by 3.3" on Home and "+2.6 · 9 PTS" on the receipt. The bylaws print "HANDICAP ALLOWANCE 95 %" and no calculation ever shows it acting. `pointsFor(-1.0)` = 7 on the web, `cup_points(-1.0)` = 6 on the server (iOS already follows the server).
- **Problem:** §2.1's "universal currency" has two values; the receipt's arithmetic does not close; the only mid-season tester read the split as a rigged table ("I beat it by 3.3, why 9?"). A Pro who cannot reproduce a points figure by hand will not keep the league.
- **Recommendation:** (1) **the lens rule** — a round's displayed PvI, band and points are the league lens whenever the round ranks in the league being viewed; the 100 % number appears only for league-less/out-of-window rounds and is then labelled; one-league surfaces (Home feed, You this-season, standings) use the viewer's open league (D81/D94); the receipt shows a League row per league the round ranks in. (2) **Server:** `home_feed(p_days, p_league default null)` returns the lens pvi/points and a `lens` field; `round_card(p_round, p_league default null)` returns `playing_index`, `handicap_allowance`, `league_name`, `in_window` and picks the viewer's shared league; both params default (skew); the old `home_feed(integer)` overload is dropped. (3) **Client preview:** `recalc()` scores `state.myIndex × ALLOW[state.preset]/100` inside the window; the panel gains one quiet arithmetic row **"Index used 14.2 × 95 % = 13.5"**; no `preview_round` RPC for v1. (4) **Bands:** `pointsFor`/`bandName` adopt `cup_points`' half-open edges (`> -1`); one `BANDS` table renders the form, the help sheet and the iOS composer with §2.2's ranges and the unit stated once.
- **Principle served:** §2.1/§2.2 verbatim; §16; D1/D2 (words on the card, arithmetic in the receipt).
- **Benefit:** one number per round on every screen; the receipt's arithmetic closes (`13.5 − 16.1 = −2.6`); a Pro can reproduce a points figure by hand.
- **Tradeoffs:** `home_feed`/`round_card` re-created (skew-safe); league-less lifetime stats keep 100 % and say so; a member of two leagues with different presets sees the open league's number on Home and both on the receipt — that is what "lens" means.
- **CONFLICT (named, resolved): D2 says the allowance is "visible only inside receipts".** The form's "How this round scores" panel IS the receipt-in-advance — the arithmetic row lives there as a `.sub` row, quiet, and never on the posted card or the feed. The owner may veto the panel row; then it lives only on the receipt. D8/D48 untouched: printing the snapshot is §16, not a dial.

### D124 · The no-number first round — the engine re-created the flat 7; name it, badge it, and pick the seed
*(2026-08-29, TOP-4 (M-048). Scoring-edge mechanic. Sources: `score_round()` `20260716100000:85–88`, D49, spec §5, `index.html:15110` (the blind 18), `PostCard.swift:194`.)*
**RULING (owner, 2026-08-29):** DECIDED — option (i), badge it. The bounded flat 7 stays for up to three rounds and is NAMED on the card and the receipt ("No number yet — this round starts it (1 of 3)"); `score_round` flags `index_provisional`. Seeding the starter from round one (ii) is not built.
- **Current:** D49 retired the flat 7 — "provisional rounds score NORMALLY off the starter index, badged provisional". `score_round()` implements `coalesce(index_at_post, standing index, engine, this round's own differential)`. A golfer with no starter and no engine number (rounds 1–2, sometimes 3) therefore posts with `index_at_post = differential` → pvi 0.0 → **7 points, "PLAYED TO IT"** — the retired flat 7, back by accident, printed as a comparison ("YOUR NUMBER THAT DAY 27.8 · +0.0"). No badge exists. The client separately carried a blind 18 so the preview said "−9.8".
- **Problem:** the first receipt of every starter-less golfer is a tautology presented as a verdict; preview and receipt disagree by ~10 strokes; D49's badge never shipped.
- **Recommendation (two shapes — the owner picks; (i) is the floor):** **(i) Badge and say it.** `score_round()` (a NEW migration) sets `rounds.index_provisional = true` when the own-differential fallback fires; the receipt replaces the verdict row with **"No number yet — this round starts it (1 of 3)"**; the ceremony/feed say "First round · sets your number"; the points stay what the engine gives; the preview drops the blind 18 and shows the differential and the same sentence, never a signed vs-figure. **(ii) Seed the starter from round one.** In addition, the first posted differential becomes `profiles.index_current` with `index_source='app'`, so round two scores against a real number and the flat 7 lasts exactly one round; WHS-lite still takes over at 3.
- **Principle served:** D49's own ("the first round must be a true story"); §16; #4 Memory > Statistics.
- **Benefit:** the first receipt tells the truth about itself; no "+0.0" comparisons; preview and receipt agree.
- **Tradeoffs:** (ii) lets one hot first round set a low starter for rounds 2–3 (bounded by the 12 ceiling and the takeover at 3); (i) alone keeps a 7 the copy now explains.
- **CONFLICT (named): D49 (flat-7 retired)** — the engine violates it today for the no-starter case; (i) accepts a bounded, badged flat 7 for at most three rounds; (ii) removes it after one. Spec §5's provisional row gains this entry's outcome.

### D125 · Vouching is per golfer — one phone cannot attest four cards
*(2026-08-29, TOP-4 (M-093). Integrity mechanic (§6, §13.1, §16). Sources: `finish_live_round` `20260829090000:261, :333–338, :371–378`, D13, D85, D86, D50; `comp/57`, `cas/86`.)*
- **Current:** `finish_live_round` posts a round to every seated member's Tour Card from the finishing phone and stamps `attested = true` on each. The 103 that appeared on the casual tester's card came from someone else's skins game with no notice, no name of who entered it, and moved the index counter. `rounds` has no `posted_by`; the receipt says "Attested · PLAYED WITH THE GROUP" whether or not the golfer's phone was ever in the session.
- **Problem:** §6 defines Attested as "a playing partner taps confirm"; §13.1's "by construction" assumed the group was scoring together on their phones (D85). One phone seating three members and posting three attested rounds is the exact shape a padded index needs, and the golfer affected cannot even see it happened.
- **Recommendation:** (1) **Record the fact now** (no decision needed — §16): `rounds.posted_by` (the finishing profile), shown on the receipt as "Entered by Priya · live round" and on the board as "Priya posted your 103 at Papago to your Tour Card". (2) **The mechanic (this entry):** a round posted to a member by another phone is `attested` only if that member's own device joined the live session (D85 `live_participant`) — otherwise it posts `attested = false` with `posted_by` set and the golfer gets a one-tap **"That was me ✓ / That wasn't me"** on the notice and the receipt; "wasn't me" voids the round (`voided = true`, logged as a D50 ruling entry, never a delete of someone else's row). Unconfirmed rounds still score (§6) and wear "UNCONFIRMED".
- **Principle served:** §6, §16, D13 (the word stays "vouch"), #3 Real Golf.
- **Benefit:** the attestation tier means what it says; the golfer owns their card; a sandbag by proxy has a witness.
- **Tradeoffs:** one more push kind and two RPCs; the finish sheet's "every card posts, attested" line becomes conditional; deferrable past the re-audit — the fact (posted_by) ships first.
- **CONFLICT (named):** narrows spec §13.1 "attested by construction" to "when the golfer's own phone was in the session". Nothing upward.

### D126 · The endgame is a sentence you can always see — and Points King ties get the ladder
*(2026-08-29, TOP-5 (M-055, M-059, M-124, M-056; Appendix A #12). UI + IA level on a decided mechanic (§14.0/§14.3, D105); one engine sub-point (the King). Sources: `#statFinal` `index.html:9605–9637` (the sort `:9632`), `LeagueCopy.deadline` `LeagueCopy.swift:224–247`, the hero `:10041–10066`, the climb note `:4477–4481`, `season_scenarios` meta, `cup_final_race`, `close_season` `20260828170100:385–386`.)*
- **Current:** D4 ordered a season-long foreshadow and accepted "persistent banner real estate" as the cost. What shipped is one line in the Season tile that competes with "Week closes Sun" and "Month closes" under a nearest-deadline sort, so it renders on one day in 155 (Fellas, reproduced with the code's arithmetic; the phone carries the identical sort). The hero's season branch carries the gap and the floor, never the endgame; the standings caption speaks D24's engine vocabulary ("EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS", "PROJECTED UNDER A GENEROUS CEILING", "LOCKED"); the only plain-English sentence is the Pro-only wizard tooltip. `close_season` picks the Points King by `points desc` alone — a tie is decided by row order and no rung is stored.
- **Problem:** 8/8 blind testers could not say how the Cup is won; the only mid-season tester scored stakes 3/10 and found the Cup Final in a bylaw row after four taps. D105 itself records "foreshadow shipped, the race itself never did" — and the foreshadow did not ship either, in effect. A leader can coast on a lead that decides only the seed and learn what it was worth on the day the slate resets: exactly the rug-pull D4 named.
- **Recommendation:** (1) **one producer, `endgameLine()`** (web classic; iOS `LeagueCopy.endgame`), from `finish`, `structure`, `climbCut(meta).K`, roster n, `cupFinalStart()`/`seasonE()` and `cup_final_race.status` — squads2: "Both squads reach the Cup Final — 4 weeks from Tue Dec 22, scored fresh. The season decides who starts +10." · squads3/4: "Top 2 squads reach the Cup Final — 4 weeks from {date}, scored fresh. The season decides the seeds." · solo: "Top 2 golfers meet in the Cup Final …" · points_table: "The points table crowns it — the season ends {date}. No reset." · during: "The Cup Final is on — {N} days left. Only rounds since {date} count; {seed 1} started +10." (2) **Three homes, always:** the hero's season branch under `gapLine`; the Season tile pinned with a countdown ("Cup Final · Tue Dec 22 · 115d") — the week/month closes keep the slot only within 1 day of firing; the climb note becomes the structure sentence (D24's clinch/elimination facts move to the badges and the scenario line). (3) **Every rendering taps** — pre-window the ENDGAME help section, during the window the race receipt (`endgame_open{from}`). (4) **Vocabulary:** `LOCKED` → **`IN`** (aria "clinched a seat in the Final"); "PROJECTED UNDER A GENEROUS CEILING" leaves the screen (D24 says it is an engine property); "HAS LOCKED THE TOP SEED · +10" → "{name} has the top seed and the +10 — nobody can catch them before the Final"; clinch captions render only when at least one row has points. (5) **Points King ties get the ladder:** `close_season` ranks the King by `points desc, months_won desc, best_month desc, rounds_used asc, coin` — the §14.3 rungs — and stores `seasons.king_rung` so the ceremony can say it. Until built, the TIES copy says "the Cup and the seeds" and never promises a King ladder.
- **Principle served:** #5 The App Should Feel Alive (anticipation is drama — D4's own line) · "understand standings in ten seconds" · §16 (the sentence taps to its receipt) · D24's honesty rule kept as an engine property, not a caption.
- **Benefit:** the Final becomes an anticipated event with a date and a prize on every screen where a standing is, from week 1; the lead converts into a seed you can see coming (D4: "a playoff, not a theft"); a member can answer "how do we win" without the Pro; a King tie is explainable in the ladder's own words.
- **Tradeoffs:** one more line on the hero and the climb (D4 accepted this); the Season tile loses its "week closes Sunday" beat on most days — the press meter carries the month and the hero foot the floor deadline; copy is structure-aware in five variants (app-tests make drift visible); a fourth re-creation of `close_season` (diff against the D105 body before pushing).
- **CONFLICT:** none upward. Executes D4 as written and D105 §3 ("foreshadow unchanged" — this *repairs* the foreshadow, it does not touch the race). Retires the D24-era caption strings as UI copy; D24's engine untouched. Amends the C4 "nearest deadline wins" rule for `#statFinal` (a code comment, never a logged decision).

### D127 · The hollow Final — when the roster cannot fill more seats than it has contenders, say so
*(2026-08-29, TOP-5 corner case (M-124, M-055, M-021). Mechanic-adjacent: no scoring change; a warning and honest copy. Sources: `season_scenarios` meta.k, `climbCut` `:4297`, `STRUCT_NOTES` `:12002–12007`, the lock sheet's seat math; both audited live leagues are 2-player / 2-seat.)*
- **Current:** at roster n ≤ K (K = seats: 2 for squads3/4 and solo, 1 for squads2 and points_table) every contender reaches the Final by construction. The engine still runs — seeds lock, +10 applies, the window scores fresh — and the standings say "EVERYONE ADVANCES". Nothing tells the Pro at lock; nothing tells a member what is actually at stake.
- **Problem:** the flagship moment is structurally trivial for the owner's own two real leagues and for every founding league that starts small, and the product describes that as a feature. A member reads it as "the season doesn't matter"; the Pro never learns that two more golfers would make it real.
- **Recommendation:** no mechanic change. (1) `endgameLine()`'s n ≤ K variant: "With 2 of you, both reach the Final — the season only decides who starts +10 (the seed)." / "With {n} contenders and 2 seats, everyone reaches the Final — the season decides the seeds." (2) At lock (the wizard review and the invite sheet) and on the Pro's League pane pre-season: "{n} golfers · everyone would reach the Final. Add golfers to make the seed race real — 4+ for two squads, 3+ for solo." (3) **⚑ owner's call:** whether a season whose roster is still ≤ K at `ends_on − 27` auto-falls-back to `points_table` (a mechanic change: the tick would flip `league_settings.finish` and post it) — recommended *no* for v1; the honest sentence is enough and the +10 race is still a race.
- **Principle served:** golf-honest voice (say what is true now) · §16 · #1 Golf First (a two-man league is a real league; it just needs the truth).
- **Benefit:** the Pro learns the fix at the moment they can still act; the member stops reading "everyone advances" as "nothing matters".
- **Tradeoffs:** one more Pro-facing line at lock (D114's sheet carries it). If ⚑ resolves to auto-fallback, that is its own entry.
- **CONFLICT:** none. §14.3 and D105 unchanged; D24's K is read, not redefined.

### D128 · Rules are a place, not a disclosure — and the Pro Shop leaves the rules
*(2026-08-29, TOP-5 (M-054, M-056, M-057, M-058, M-060 "bylaws §4", M-012). IA level. Sources: `<details class="hubmore">` `index.html:3555–3570`, `.byrow` `:1330`, `openScoringHelp` `:17274–17294`, `LeaguePane.swift:58–90`, `BylawsCard.swift`, D82, D93, D101.)*
- **Current:** the rules that decide the winner are filed as league administration — sixth segment, then a collapsed "League rules & Pro Shop" disclosure that shares its panel with an upsell; the bylaws table is engine keys (`COUNTING CAP`, `HANDICAP ALLOWANCE 95 %`, `−5 sqd pts`), untappable; the explainer has four sections and no link; the individual-race footnote cites "bylaws §4", a document the app never shows. The organizer found the rules 18 minutes in, by accident; the competitive tester never found ties because they are nowhere.
- **Problem:** a competition whose rules are in an admin drawer cannot be understood in ten seconds, and every persona said the Pro would explain it in the parking lot — the zero-instruction test's clause 6.
- **Recommendation:** (1) **Rules lead the League pane, open, in sentences.** Keep six segments. `#room-league` opens with a "How this season is won" block — D126's endgame sentence · D14's floor sentence · "Best {cap} a month count" · the buy-in line with D129's payment path — from one `rulesSentences(bylaws)` producer, then "How scoring & the Cup Final work →" as a real button, then the bylaws table; Members & invites / Share / Squads / Look / Notices follow; the `<details>` goes. (2) **Every bylaw row is a door** — `.byrow` rows open `openScoringHelp(section)` at their section; engine keys get plain labels ("Best 4 a month count", not "COUNTING CAP" — D51; "HANDICAP ALLOWANCE 95 %" stays in the table only, per D2/D8, but opens its explanation). (3) **"How scoring works" grows three sections** — THE SQUAD (the formula in one sentence, incl. "squads aren't size-adjusted"), THE ENDGAME, TIES (§14.3's ladder in golf voice); conditional on structure; one source on iOS (`GuideCopy.scoring`; `RoomScoringHelpSheet` reads it). (4) Link it where a number is shown: the hero endgame line, the climb note, the post form's band table, wizard step 2, the welcome sheet, the individual-race footnote. (5) **The Pro Shop leaves the rules:** the block becomes a **League pass** card at the *foot* of the pane, rendered from `app_flags.pricing` exactly as the phone's `PotPassCard`/`MembershipCard` do; the false "Custom rules, every dial unlocked" line is deleted. **⚑ owner:** keep the three remaining teasers (draft night, trades, multi-season) as a "coming" list, or retire the teaser until it is a decided roadmap.
- **Principle served:** "understand standings in ten seconds · never need a tutorial" · #2 (one tap from any number to its rule) · D82's depth-at-the-doors · §16 (a rule is a receipt for a number).
- **Benefit:** "how do we win", "what happens if I miss a month", "what counts" and "what do I owe" are answered on one screen in sentences, one tap from every place a member meets the number. The money copy stops living inside the rules.
- **Tradeoffs:** the League pane gets longer (Members, Share, Squads move below the fold for a member who already knows the rules — those are Pro tools and D93 gave them doors). Two producers (`rulesSentences`, `floorSentence`) kept in step across clients by tests.
- **CONFLICT:** none upward. Refines D82 and D93 (a section becomes a place *inside* the League pane rather than a new tab); upholds D56/D101 (pricing behind the flag; the noun "league pass").

### D129 · The pot gets a payment path — a Pro-set note and due date on the bylaws, never a transfer
*(2026-08-29, TOP-5 (M-110, M-111; rule R30 "0/8 could say how/when/whom"). Money-model level (4), additive. Sources: `buy_ins` baseline `:885–893`, `league_settings` `:1073–1105`, `mark_buy_in` `20260828170000:410–471`, `renderPot` `index.html:7125–7180` (the fake buttons `:7168`), `PotPane.swift:95–130`, `join_covenant_info`, D39, D66, D106, D23.)*
- **Current:** the ledger records *who has paid* (`buy_ins.paid`, Pro-marked) and D106 shows the two numbers. It records nowhere *how* — the app's whole payment instruction is "money moves between you" and, on a member's tap, "The Pro marks buy-ins as money moves between you". Six weeks into the owner's real season the pot reads $0 collected; the audit's four joiners each said they would text the organizer to ask. The Pot pane's member rows are buttons that do nothing.
- **Problem:** a pot nobody knows how to settle is not a stakes mechanism and not a pricing anchor — D101's pass is "paid by the Pro out of the pot", and today the app cannot say how the pot is gathered.
- **Recommendation — instructions on the bylaws, status on the sheet, the self-only line on Home:** (1) two columns on `league_settings`: `buy_in_note text` (≤ 140 chars; "Venmo @casey or cash at the first tee") and `buy_in_due_on date` (null → "before first tee"); a bylaw, so it rides `loadBylaws` and `LeagueRoom.Settings` with zero new reads. **RPC `set_buy_in_terms(p_league, p_note, p_due_on)`**, SECURITY DEFINER, `is_commissioner`-gated, editable at any phase, posts a system line "BUY-INS · $50 TO CASEY · Venmo @casey · due before Sat Sep 5"; D37 grants and self-check. (2) **The Pot pane renders the terms** — "Pay Casey · Venmo @casey · by Sat Sep 5"; the Pro sees "Edit"; **member rows become status rows** ("Paid ✓" / "Not yet"; the ✓ absent from the DOM when unpaid); only the Pro keeps `.payer` buttons. (3) **Self-only on Home (D23):** when `stake > 0`, the viewer's own row is unpaid and terms exist, the hero foot's second line reads "You still owe $50 · Venmo @casey · by Sat Sep 5" → the Pot pane. Never anyone else's name. The Pro's variant is the collector's tool: "Pot · $75 of $150 in · 1 owes". (4) **The covenant and the welcome:** `join_covenant_info` gains `buy_in_due_on` and `has_pay_note` — **never the note** (a join code is guessable; a Venmo handle is members-only); the covenant row reads "$50 · due before first tee · the Pro has posted how to pay"; the post-join welcome shows the note verbatim. (5) The settlement post (D106) is unchanged.
- **Principle served:** §7 "track, never hold — the ledger is the product" (a note is instructions, not a transfer) · #3 Real Golf, real money between friends, no fiction · D23 (a money line names one emotion — obligation to one's own crew — and only to the person it concerns).
- **Benefit:** "how, whom, by when" is answered on the sheet, in the covenant and on Home; the fake affordance disappears; D106's two numbers finally have a mechanism that moves them; D101's "out of the pot" has a pot.
- **Tradeoffs:** a free-text field the Pro can leave empty (then the line reads "Ask the Pro how to pay — money moves between you", today's truth said plainly); a handle is PII shared with the league — members only, RLS holds. One migration, one RPC, both clients, the snapshot regenerated.
- **CONFLICT:** none. D39 (ledger, never held): a note is not a rail — legal.html stays accurate. D66 (no pay/collect affordance): the member row *loses* an affordance. D106 untouched. D23: the Home line is self-only and fires from state, not a schedule. Spec §7 gains one sentence: "The Pro states how and by when buy-ins are paid; the ledger records who has."

### D130 · "This round matters because" — the Home stake line, D51's named remainder resolved under D23
*(2026-08-29, TOP-5 (M-123, M-133; R27 "your Sunday round matters because…" — D24's own benefit line). Mechanic-adjacent UI (a nudge under D23's fence) — needs the OWNER (D51 said so by name). Sources: D51 `:1478`, gameplay-modes §8, D23 `:393`, `season_scenarios.rows[me].needs` (fetched, unrendered), D108 `week_clashes` (rendered only in the Standings column, `index.html:14611–14617`, `4589–4638`), `heroMyRung`, `heroFloorFoot` `:9970–9993`.)*
- **Current:** D51 built the honest marginal-value ladder for the *post* screen (unbuilt in code) and left the Home surface open because a floor-at-risk line is a nudge; D24 computes a per-viewer magic number nobody renders; D108's clash is rendered only in the Standings column. Home says where you stand and how far the gap is — never why this week's round changes it.
- **Problem:** the product's retention loop is "why open the app between rounds"; the answer exists in three engines and reaches no Home surface. The observer's Home was a rank and a floor bar; the competitive tester "would play for the skins and shrug at the table".
- **Recommendation — one line, one emotion, silent by default (D23):** `homeStakeLine()` under the hero's endgame line, first rung that applies wins, else nothing: (1) **the clash** (rivalry): "THE CLASH · you v Marcus · through Sat · your best so far: Beat your number (9)" from the latest `week_clashes` row when the viewer is in it; settled: "Marcus took the week" once, then quiet. (2) **Floor at risk** (anticipation, once per condition): "1 more round by {month end} keeps the floor — or your squad gives back 5" — only when short with ≤ 7 days left, once per month, never after the close. (3) **The seed / the crown closable:** from the viewer's `season_scenarios` row when `needs` is finite and ≤ what one round can add: "{needs} more points lock your seat in the Final" / "…the +10" / "…the crown". (4) **The cut line closable:** gap to the rung above ≤ 12 and finish is cup_final: "8 back of the last cup spot — one top-band round closes it" (never claims a resulting position — D24). (5) Otherwise quiet. Tap → the clash, the month's slot meter, or the climb. Push: none. `native_home()` gains `clash` + `needs` so the phone reads the same facts (and, in the same re-creation, `leader_name` + `field` for the rank card — M-144 — and `buy_in` for D129's foot line). The post-screen stake line (D51 as designed) is a separate build item.
- **Principle served:** #5 (anticipation between rounds) · D23 (names an emotion, fires once, no badge counts, no shame) · §16 (every line taps to its receipt) · D24's honesty rule inherited.
- **Benefit:** the season's three engines finally speak on the one screen everyone opens; the clash gets its Tue–Sat beat on Home (D52's whole point); the floor-at-risk golfer — who by definition is not visiting the post screen — is the one D51 could not reach.
- **Tradeoffs:** a line that speaks most weeks risks wallpaper — mitigated by rung 1 being only *the viewer's* clash (1 in n/2 weeks) and by silence otherwise. Rung 2 is the nudge D51 flagged; it fires once per month and names the number, not the person — the owner may strike it.
- **CONFLICT (named):** resolves D51's named remainder; brushes D23 exactly as D51 predicted — keeps D23's three fences (emotion named, once, no push). D24's engine is read, never re-projected client-side.

### D131 · Noun sweep III — the collisions get one owner each (card · stake · tee sheet · cup · the books)
*(2026-08-29, terminology §5 items 3, 9 and runners-up (M-061, M-062, M-074). UI-copy level (5) with one IA-level (3) assignment — "tee sheet". Sources: D47, D64, D86, D107, §13.2, `Cup-Season-Guide.md:37–40`.)*
- **Current:** D47 assigned "card never unqualified", "books = money", "scheduling = the tee sheet", "one code noun". Since then **card** ships in five senses — profile (`index.html:13718`), the record ("counts on your card" `:2978, :3198, :9945, :13228`; "COUNTS ON YOUR CARD" `:6191`; "PRACTICE ROUNDS HIT YOUR CARD" `:3428/:12225`), the scorecard (`:3169`, `:3127–3137`, `:3012`), the recap artifact ("Share the card" `:3721, :6124, :9453`) and the composer (`:16714`). **Stake** means money on a live game (`:3042/:8833`; §13.2) and never-money on the Pot tab ("Post a stake · Pride, on the books — never money", `:3543–3544, :11168`) — and D51's "stake line" is a third sense waiting to ship. **Tee sheet** means the calendar (D47; `:3618–3620, :16931, :17066`) and the live scorer (D86's invitation copy `:7866/:7889`, the plan bridge `:8527–8528`, D107's title, the Guide). **The books** covers money (D39/D47) and pride bets. **Cup** is the title, the points, the Final, a count ("Cups & events" `:2886`) and the winners ("Cup champs"). Every site is mirrored on the phone.
- **Problem:** eight of eight testers listed "card" or "stake" or "tee sheet" as a term they had to re-derive; the worst instance is the post-round verdict "COUNTS ON YOUR CARD", which every tester read as "counted" when it meant "not in the season". One noun with two opposite senses ("stake") on adjacent tabs is D11's disease regrown at the money seam. D47's rules were right and are unenforced.
- **Recommendation (assignments, copy-only except one route label):** **card** = the golfer card (the profile), used only on You / Card & settings / onboarding; the hole-by-hole thing is **the scorecard**; recap / settlement / Tour Card are named artifacts; the record-of-rounds sense retires ("counts on your card" → "posts to your rounds — every league you're in reads it"); the post-round verdict is D122's state sentence. **stake** = money on a live game only (§13.2); the Pot tab's pride bets take D64's own noun, **forfeits** ("The forfeits · pride, never money", "Post a forfeit", "Put it on the record"); D51's line is "what's on the line". **the books** = money, full stop. **tee sheet** = the shared calendar of planned rounds; the live scorer is **a live round** ("Play now" is its door; "Live round" its screen) — D86's invitation face reads "Marcus put you on a live round", the plan bridge "load it into the live round", the Guide's heading "Live rounds — one round, scored together". **cup** = the season title; "Cup points" → "points"; "Cups & events" → "Leagues & events"; "Cup champs" → "the winning squad"; "Cup Final" keeps its name and gets its sentence (D126). A preflight lint keeps the retired words out.
- **Principle:** #2 Low Friction — the no-tutorial metric; D11/D12's law that each noun means one thing; D47, restated with teeth.
- **Benefit:** the post-round verdict stops lying by accident; the Pot tab and the live setup stop using one word for opposite things; the Guide, the door and the app agree on what a tee sheet is.
- **Tradeoffs:** "forfeit" reads a shade more legal than "stake" — accepted, it is D64's word and unmistakably not money. "Live round" for the D86 banner loses D86's charm — copy, not mechanic. ~90 strings across two clients; no schema (`forfeits`, `settle_forfeit` already carry the noun).
- **CONFLICT (named):** D86's and D107's *titles* use "tee sheet" for the live round — amended by assignment, neither reversed. D64's title "stakes past money" stays as history; its object noun ("forfeit") wins the UI. D47 "books = money" is upheld against the shipped pride copy. Nothing upward.

### D132 · "The Pro" stays and is defined at first contact; "Pro Shop" and "the pilot" retire — D15's revisit trigger has fired
*(2026-08-29, terminology §5 item 4 (M-012, M-060). UI-copy level. PROPOSED — owner's call on the noun itself; the retirements are restorations. Sources: D15, D56, D101, IOS-021, CLAUDE.md monetization; "Pro Shop" `index.html:3241, :3286, :3556–3563`, `LeaguePane.swift:62–86`, `WizardState.swift:361, :371`; "the pilot" `:3565, :13783, :15553, :15559`, `MembershipCard.swift:42`, `EventPickerSheet.swift:27, :31`.)*
**RULING (owner, 2026-08-29):** DECIDED — "the Pro" STAYS and is defined at first contact (the orientation, the covenant's WHO row, the Clubhouse chip). "Commissioner" is declined. "Pro Shop" and "the pilot" retire as proposed.
- **Current:** D15 logged the collision between "the Pro" (the commissioner) and "Pro Shop" (the paid tier) and chose it, with a revisit trigger: "first paid-tier screen design". D101 / IOS-021 designed and built the paid-tier surfaces under the noun **league pass** — the trigger fired and nobody revisited. Shipping today: "Pro Shop", "THE PILOT RIDES FREE" / "Nothing to pay during the pilot" / "after the pilot", and "the Pro" undefined at every first contact (43 web + 70 iOS strings; the phone's Clubhouse header "THE PRO · GALEN").
- **Problem:** every persona paused on "the Pro"; three read it as the club professional. "Pro Shop" makes it worse (a pro shop sells gloves) and names a tier D101 already renamed. "The pilot" is a project word on a customer surface ("am I the pilot?" — A3, A5). The paid model has a decided noun and a decided sentence and neither appears.
- **Recommendation:** (1) **Keep "the Pro"** — it is the product's voice and it is in 113 strings — and **define it once at first contact**: the orientation's long-game card (D117), the covenant's WHO row ("Casey (the Pro — runs the league)"), the Clubhouse header chip's first render ("THE PRO · GALEN · runs the league"). (2) **Retire "Pro Shop"** for D101's **league pass** everywhere: the League tab section becomes "The league pass" (D128's card); the wizard (i)s drop "unlocks with Pro Shop". (3) **Retire "the pilot"** for the decided posture: "Free this year · founding leagues play free forever" (D56/D101; the price itself stays behind `app_flags.pricing.visible`). (4) The alternative the audit prefers — renaming to "Commissioner" — is recorded as the owner's option: the same sweep plus the brand voice, the Guide and the store listing, gaining a word every fantasy player already knows.
- **Principle:** #2 (a golf word used against its golf meaning is the most expensive kind of jargon); D12's "schema words are not user words" in reverse: the tier's decided user word is "league pass", not the schema's `pro`.
- **Benefit:** the collision D15 chose is closed at the cost of three definitions; the money surfaces say what D101 decided instead of a placeholder.
- **Tradeoffs:** keeping "the Pro" keeps the first-beat misread for golfers who skip the orientation — mitigated by the covenant and the Clubhouse definitions, which every member passes.
- **CONFLICT (named):** D15 (chosen collision) — resolved by its own trigger. D56's "no pricing on the front door" upheld. Nothing upward.

### D133 · The live setup teaches every game before the seats fill — and says once what side games never touch
*(2026-08-29, §7 side games (M-063, M-064, M-094). UI level; the games' mechanics (§13.2, D16, D74–D79) untouched. Sources: the picker `index.html:3032–3040`, `GN` `:9063–9065`, `renderMatchPrev` `:8833–8857` (Wolf at exactly four `:8846–8847`, Sunningdale at 2 or 4 `:8840–8841`), `LiveModels.swift:39–41`, `LiveCopy.swift:289–294`.)*
- **Current:** the game picker shows a one-line blurb per game; the how-to renders inside `renderMatchPrev` only once the seat count is legal. "Bank unit · $0 = bragging rights" never says what a unit is. A guest with no index is silently "EST 18.0 IDX" and a $5 match's strokes derive from it. No surface says "side games settle between you and never touch season points".
- **Problem:** the rule that would help a group *meet* Wolf's precondition is hidden behind the precondition ("Wolf: never explained. If you don't know Wolf, this line tells you nothing" — A3). Four testers could not parse "bank a unit". `sideGamesCompelling` split exactly on ran-one (7–8) vs read-about-one (4–5).
- **Recommendation:** (1) every game card carries an (i) that opens a three-line how-to **regardless of seats** — who plays, how a hole is won, how it settles (Wolf: "Four players. The wolf tees last and picks a partner after any drive — or goes lone for triple. Points settle at the dollar-per-point you set." Sunningdale: "No handicaps. Go 2 down and you get a stroke a hole until you climb inside 1. Win a hole while ahead and you bank a unit — a unit is the stake you set at tee-off ($5 a unit, or $0 for pride)." Skins: "Low net takes the hole; a tie carries it forward." Match play keeps the strokes line). (2) The seat rule renders as its own always-visible line ("Wolf · exactly 4"), not only as a tee-off toast. (3) One sentence on the setup card and again on the settlement sheet: **"Side games settle between you at the finish. They never touch season points — your score posts like any round."** (4) The stake labels align: "$ per side / $ per point / $ per skin / $ per unit · $0 = bragging rights". (5) "riding" → "carried over"; "unit" keeps D74's word with the definition (renaming to "point" is the owner's option). (6) The estimated index is announced where it decides money: "Jordan · no index — playing as 18 (tap to change)". One `GAME_RULES` table on each client, lint-checked.
- **Principle:** §13.4 (the free door is the acquisition surface — it must teach itself) · D107 (a Wolf game at a bachelor party becomes four claim links only if the four can learn Wolf on the tee) · #2.
- **Benefit:** the two least-common games become learnable at the moment a group is deciding what to play; the "does this affect the season" question every teeing-off tester asked is answered in one place.
- **Tradeoffs:** four (i) sheets to keep true in two clients (one table each, lint-checked).
- **CONFLICT:** none. D16 (no 3-player Wolf) stands — the (i) says "exactly four" and offers Skins for a 3-ball.

### D134 · The season points at the live round — placements, no mechanic
*(2026-08-29, §7 discovery and §13 "what it looks like it sells" (M-064, M-153). IA level (3): where the live door is *referred to* from the season's own surfaces. Sources: D107, D110, D94, D82, D86; the one pointer `index.html:3454` / `StandingsPane.swift:320`; the plan bridge `renderPlanBridge` `:8512–8531`; the day sheet `:17066`; Home's Next tile `:9891`.)*
- **Current:** all seven web testers found live play through exactly one door, the ⊕; none from Home's hero, the welcome sheet, the wizard, Standings or the League tab. The one pointer that exists — a bare `Live round` mini-button inside a card whose sentence is about the floor — was recognised by nobody. The live setup bridges *from* a planned round, but nothing points the other way. The board story a settled game posts (D92) is the only place a season surface shows a live round happened.
- **Problem:** the layer that scored 7–8/10 from everyone who ran it is unmentioned by the layer meant to retain them. §13's diagnosis: Cup Season sells season-long rivalry and *looks like* it sells administration and a money ask, with side betting as the part people enjoyed — and the season never introduces the part people enjoyed.
- **Recommendation — six placements, one copy, no new mechanic:** (1) Standings › NEXT UP becomes two lines: the month line plus "Playing Saturday? **Score it live** — match play, Wolf, skins; guests welcome." (named when a planned round exists in 14 days); the mini-button reads "Play live". (2) The day sheet gains "Play it live → match play, Wolf, skins" on the day itself, opening the live setup with the plan bridge pre-loaded. (3) Home's Next tile keeps one fact; on a day with a planned round its sub reads "TODAY · PAPAGO · SCORE IT LIVE" (no fourth tile — D94). (4) The League tab gains a quiet "Live games · match play, Wolf, skins, Sunningdale Rules · no account needed for guests · **Play now**" row. (5) The Pot tab gets D133's sentence as a footer: "Side-game cash settles between you at the finish and isn't tracked here." (the second clause changes if a side-game ledger is decided). (6) The welcome sheet gains one line above the share ask: "Saturday's foursome can score live from the ⊕ — guests need no account."
- **Principle:** #5 The app should feel alive (a season surface that never mentions Saturday is a table, not a league) · §13.4 / D107 (the free door is the funnel — a member who has never been shown it cannot bring a guest through it) · D82 (these are doors, not depth).
- **Benefit:** the most-praised layer gets six sightings inside the season instead of one; the `growth_events` funnel gains its member-side top.
- **Tradeoffs:** six more strings in each client; the NEXT UP card gets taller; the Home tile sub only changes on a planned-round day (D27: never opens on nothing).
- **CONFLICT (named):** D94 (one fact per tile) — upheld by design; D82 — upheld. Nothing upward.

### D135 · The monetization gate — the pass becomes visible on evidence, not on a date
*(2026-08-29, blind-ux-audit §9 (would-pay median 3.5/10). BUSINESS level (1–2). Refines D56 / IOS-021 / D101. Sources: `app_flags.pricing` seeded `visible:false` (`20260827160000`, re-seeded `20260827170000`); the flip is a one-line SQL update (`docs/ios/pricing-surfaces.md:46`); the web reads `app_flags` only for `scan` (`index.html:6734`).)*
- **Current mechanic:** the visible pricing model exists on the phone behind `app_flags.pricing.visible = false`; the web has no pricing surface at all. IOS-021's trigger for the flip is "the owner flips it after confirming the anchor"; D101's trigger for checkout is "the first real anniversary". Nothing else gates either.
- **Problem:** twelve blind result rows put *would pay for another year* at a median 3.5/10; the skeptic's own $79 justification is a sentence made entirely of built mechanics none of which he saw on the day he joined. §9 lists seven things that must be true before pushing monetization; none is a condition anywhere in the product or the ops docs. A flip on judgement alone would put a price in front of the exact organizer who cannot lock a league today.
- **Recommendation:** the flip (and, later, D101's checkout) is gated by an **eight-item checklist, each item evidenced by a named metric**: (1) a real season has ended well — one league `complete` with `season_payouts` and its ceremony opened by ≥ half its members; (2) the race is visible all season — `endgame_open` per member per month ≥ 1 and a `week_clashes` row on the next tick; (3) pre-season honesty — Re-audit B passes and `v_preseason_exposure` shows no league whose members posted pre-season rounds under a points promise; (4) the pot is true — D106 live, `collected = pot` for PIGL at close, a payment note set on ≥ 1 real league, `pot_mark_denied` → 0; (5) the invite works — `v_lock_health` 30-day `lock_fail = 0` with ≥ 3 `lock_ok`, invite → accept ≥ 60 % on ≥ 3 real leagues; (6) the price is stated where the buy-in is set, on both clients; (7) D56's focus-group deck has been run against those real surfaces (≥ 6 Pros) and the re-audit's *would pay* median is ≥ 5; (8) `pricing.founding.ids` names PIGL so no founding league is ever shown a price. Only then `update app_flags set value = value || '{"visible": true}'`. `tests/db-checks.sql` check 15 makes (1) and (8) self-enforcing. Stripe stays parked per D101.
- **Principle served:** "charge after proven value" (`spec/gtm-year1.md` §11; product-vision Real Golf / Low Friction); D56's own "the flag makes it a one-row change" — made for a reason the numbers can show; §16 applied to ourselves (D33's precedent: the verdict shows its work).
- **Benefit:** the price lands on a product that has demonstrated the sentence it is selling; the owner has a dashboard answer to "are we ready" instead of a feeling; a founding league cannot be surprised.
- **Tradeoffs:** delays revenue until at least one real season closes (PIGL's first close is the earliest date); eight conditions is a lot of process for a one-person company — mitigated by making every item a row on the founder desk and a `db-checks` line, not a meeting.
- **CONFLICT:** none upward. Amends IOS-021's trigger sentence ("after confirming the anchor" → "after the gate is green and the anchor is confirmed"); D101's dates and numbers untouched; D56's deck becomes gate item 7 rather than a prerequisite to build the surfaces.

### D136 · The open questions of the blind-audit batch, answered
*(2026-08-29. Owner accepted the recommended answer to each of §6's open
questions in `docs/audit/blind-ux-2026-08-29/remediation-plan.md`. Recorded
here because several are mechanic- or IA-level and the builds depend on them;
each remains reversible on its own line.)*

- **Stage vocabulary (D120 · §6 Q-14):** six words — *Forming · Squads drawing ·
  Before first tee · Season live (Week n of N) · Cup Final · Season complete.*
  "Forming" means SETUP only; testers read it as "squads forming", so the
  squads-drawing stage gets its own word.
- **The member's first verb (D119 · Q-15/Q-16):** "Plan a round" leads before
  first tee, "Post a practice round — it builds your number" second; the three
  Start/Start/Join doors collapse to one quiet "Start something…" link for
  members (D94 named this the thing to watch; the audit watched it).
- **The covenant's reach (D115 · Q-08/Q-09/Q-11):** roster NAMES only after
  sign-in (a league code escapes the group chat; the Pro's name and the head
  count are enough to decide); a $0 league DOES get a decision sheet — the same
  rows minus the stake and a plain "Join" — because D70 forbids pot *surfaces*,
  not disclosure, and today a bragging-rights league shows nothing at all.
- **The pot's payment path (D129 · Q-27):** fail-closed — before joining, the
  sheet says only that the Pro has posted how to pay; the note itself appears
  once you are in. Default due date when the Pro sets none: *before first tee*.
- **The endgame (D126/D127 · Q-23/Q-25/Q-26):** the clinched badge word is
  **IN** ("SEEDED" collides with seeds 1/2, which only exist once the window
  opens). The Points King tie ladder is NOT built yet — the surface states "a
  tie stands as a shared crown" until a real tie happens. At a roster too small
  to fill the Final the Pro is WARNED; no automatic fall-back to the points
  table (that would change the endgame under a league mid-season).
- **Contact invites (Q-07):** not scheduled. The link plus a prewritten Copy
  message is the invite; the Guide's false claim is already corrected. Revisit
  only if a real Pro asks.
- **Repo posture (Q-40):** commit `docs/audit/` after a redaction pass (the
  observer's report names real league members); `screenshots/` stays ignored.
- **First-tee default (Q-29):** UNCHANGED — next Saturday, 1–7 days out. The
  audit's "my round earned nothing" confusion is a COPY failure, fixed by
  D122's season-window sentence; moving a date default has knock-on effects on
  month boundaries and floors and would not have prevented the confusion. The
  sketched "≥ 7 days out" is declined for now.
- **Spec §9's seven-day posting window (Q-28):** struck as unenforced. Nothing
  has ever enforced it, backdated entry is legitimate (scorecard scan, guest
  claims, a round posted the following week), and enforcing it now would break
  those paths to solve a problem nobody has reported. The date field's own
  prominence (Q-21) is the control.
- **Telemetry names (Q-37):** the WEB's names win where the clients differ
  (`league_create`, `lock_ok`) — they carry prod history; the phone's
  `league_created` / `league_locked` retire.
- **CONFLICT:** none upward. D136 answers questions the batch left open; where
  an answer narrows an entry (D115's roster reach, D126's ladder) the narrower
  reading governs.

### D137 · The runoff, answered — placement is the consolation; there is no toilet bowl
*(2026-08-30, season simulation study `docs/audit/season-sim-2026-08-30/` — 64 seasons, 26 configs, 3 replicates, 8,624 counting rounds. MECHANIC level (4), and the UI level (5) beneath it. Owner's question: "Do we need runoff competition? Example, play for third/fourth/fifth? Thinking like in fantasy football, the championship may be out of reach but you want to avoid being last place.")*
- **Current mechanic:** a season pays three prizes — champion 60 %, runner-up 25 %, points king 15 % — and in a Cup Final league `enter_cup_final` cuts the field to exactly two rows in `cup_finalists`. Nothing else is a named outcome. Home named the winner by reading the top of the points table (`teams[0]`), which in a Cup Final league is a **different race** from the crown.
- **Problem:** two, compounding. (a) Home named the WRONG champion: in `Encanto Ten` the engine crowned Vic Slice 28–26 and the card said "Ray Fairway took it"; the same block tells the table leader "Your name goes on the cup" when they did not win it. (b) In a ten-player solo league only **2 of 10 are alive** in the last 28 days and only **2 of 10 are paid**; the other eight have no named outcome at all, which is exactly the owner's instinct.
- **Evidence for the runoff question:** the middle of the table is a real race and the bottom is not. Mean final gap between adjacent places: 2→3 **3.2**, 3→4 **3.4**, 4→5 **3.6**, 5→6 **3.2**, 6→7 6.8, 7→8 10.3 — then 8→9 **21.6** and 9→10 **27.9**. **72 % of all adjacent pairs finish within 7 points**, one good round. But last place sits **34.0 points** adrift of second-last and was within one round of it in only **4 of 25** seasons. A non-finalist won Points King in **3 of 13** solo cup seasons, so places 3+ do already hold a live prize — invisibly.
- **Recommendation:** **placement becomes a stated outcome for every seat; there is no last-place mechanic.** Built now: (1) the crown is read from `seasons.champion_*`, never inferred from standings; (2) a settled season renders **the final table** — no cut line, no IN/OUT, the champion marked `CUP` — so 4th is a recorded fact rather than a leftover; (3) a non-finalist in the cup window is told who the cup is actually between and pointed at the place race that is still live. **Deferred to its own decision** once a real season has closed: paying 3rd, or a consolation bracket over the final four weeks. **Declined outright:** a last-place punishment or "toilet bowl" — the fantasy-football analogy does not transfer, because there last place is an unlucky full roster and here it is someone who stopped posting, 34 points adrift. A mechanic aimed at them would shame precisely the golfer the auto-bye (D14) was written to be gentle with.
- **Principle served:** §16 (no figure without its work — the crown must come from the ledger that decided it) · #5 the app should feel alive (eight of ten golfers need something true to play for) · D14's posture toward the person who missed a month.
- **Benefit:** the finale stops lying; every seat below the cut gets a real, tight race (3-point gaps) named and visible; the pot question stays open on evidence rather than being pre-empted by a punishment nobody asked for.
- **Tradeoffs:** placement without money is a weaker hook than a paid 3rd — deliberately, until a real season shows whether the mid-table race holds attention; the "CUP" badge adds a fourth badge state to the climb.
- **CONFLICT (named):** none upward. Narrows D126/D136's badge vocabulary (IN/OUT are race states and do not survive the close).

### D138 · The Cup Final's silent field — a non-finalist is told the truth
*(2026-08-30, season sim. UI level (5) under D137.)*
- **Current mechanic:** during `cup_final` the Home hero shows every member a figure labelled **"seed"** with their points-table rank, plus a gap to the golfer above.
- **Problem:** the field was cut to two weeks earlier. A ten-player solo league shows eight golfers a "3 seed", a "5 points back" and "2 weeks left" for a place that no longer exists — an invitation to grind for a sealed outcome. The clubhouse already says `OUT` and "the regular season — final"; Home contradicted it on the same data.
- **Recommendation:** a member with no row in `cup_finalists` gets their **place** (not a seed), the names of the two golfers actually contesting the cup, and the table gap — which stays, because that race is real (D137's 72 %). A finalist's card is unchanged and now shows their true `cup_finalists.seed` rather than their table rank.
- **Principle served:** §16 · #2 honest competition — never show a chase that cannot be run.
- **Benefit:** the eight keep a true reason to post; the two keep their duel.
- **Tradeoffs:** the non-finalist card is longer; it names two other people on your own home screen.
- **CONFLICT:** none. Upholds D105 (the Final leads the room) by making the room honest for everyone not in it.

### D139 · A settled season is not a race
*(2026-08-30, season sim. UI level (5).)*
- **Current mechanic:** the climb renders a cut line, `IN`/`OUT` badges and a recent-form column from `season_scenarios`, regardless of season status.
- **Problem:** a finished league still drew "CUT LINE · 15 BACK" with the actual champion sitting second and unmarked. The race UI outlived the race, and disagreed with the crown.
- **Recommendation:** when `seasons.status = 'complete'` the ladder becomes **the final table** — eyebrow "The final table", no cut row, no clinch/eliminate badges, and the champion carries a `CUP` badge read from the season row.
- **Principle served:** §16 · IA (a settled thing is described in the past tense).
- **Benefit:** the last screen a season shows agrees with the ceremony and the ledger.
- **Tradeoffs:** one more branch in `renderClimb`.
- **CONFLICT:** none.

### D140 · The solo floor tracks a habit; it does not run a clock
*(2026-08-30, season sim — verified across all 25 completed solo seasons. MECHANIC-adjacent (4/5): no rule changes, the claim does.)*
- **Current mechanic:** `close_month` assesses the participation floor by walking `squad_members`. A solo league has no squads, so **no floor penalty, forfeit or auto-bye can ever fire**. The copy is already honest ("in a solo league that is a habit, not a penalty — there's no squad to dock"), but the Home foot rendered a progress bar and a "· 1d" countdown.
- **Problem:** the countdown borrows urgency from a consequence that does not exist. That is the same class of untruth as D138's phantom seed, in miniature.
- **Recommendation:** keep the bar (habit tracking is legitimate and motivating); drop the deadline in solo leagues. The floor keeps its teeth wherever squads exist. **Left open:** whether a solo league should have an enforceable floor at all — that is a rule change and wants its own decision, informed by whether the pilot's drifters actually drift.
- **Principle served:** §16 · never manufacture stakes.
- **Benefit:** the one number a solo golfer sees every day stops implying a penalty that cannot arrive.
- **Tradeoffs:** removes a nudge; if solo participation sags in the pilot, the honest fix is a real rule, not a fake clock.
- **CONFLICT:** none. Consistent with the D122/D136 floor sentence already shipped.

### D141 · `sandbox_scrap` clears its children
*(2026-08-30, season sim, migration `20260830150000`. Implementation level (6).)*
- **Current mechanic:** D65's `sandbox_scrap` deletes the league first, commenting that the cascade "clears every no-action member_id reference before the users go".
- **Problem:** it does not. Fourteen tables reference `league_members` with `ON DELETE NO ACTION`, and `seasons` carries champion/runner-up/points-king pointers. The moment a sandbox league closes a month with a floor penalty — i.e. the moment it becomes worth looking at — the scrap fails `23503`. The founder tool for throwing a diorama away could not throw away any diorama that had run long enough to be interesting.
- **Recommendation:** clear children in dependency order (season pointers → `season_adjustments`/payouts/snapshots/clashes/finalists/buy-ins/lead → posts and comments → league graph → bots). Same signature, same founder gate, same return shape. Self-enforcing `do` block asserts the two clauses are present.
- **Principle served:** a tool that cannot clean up is a tool that stops being used.
- **Benefit:** the sandbox is disposable again.
- **Tradeoffs:** the delete list must be extended whenever a new table references `league_members`.
- **CONFLICT:** none.

### D142 · The counting cap is the quality dial — set to 3, and named for what it does
*(2026-08-30, season sim. MECHANIC level (4). BUILT 2026-08-30 — owner ruled "build your recommendations"; migration `20260830180000` + client. )*
- **Current mechanic:** `counting_cap` caps how many rounds count per calendar month; `lock_league` defaults it to **4**. The wizard presents it as a fairness guard ("your best N count"), not as a competitive lever.
- **Problem:** measured within each league, season points correlate **+0.96 with rounds counted** and **+0.04 with points-per-round**, and rounds-counted is the stronger driver in **61 of 61** leagues. 64 % of all rounds land in the bottom two bands, so the best golfer in a league out-scores the worst by **1.83 points per round** while one extra posted round is worth **6.6**. Showing up once more is worth ~3.6× being the best player on the course. The cause is the handicap engine working correctly — across 576 golfers the WHS-lite index settled **4.7 strokes below** true ability, so a lower index makes every band harder; volatile golfers lose most (improvers −6.8, steady −3.5). The sim is *flattering* (35.5 % of rounds reach "played to it or better" vs 20–25 % in real golf), so the real effect is stronger.
- **The lever, measured:** the cap is the only thing that changes this. At **cap 2** the bottom two bands fall to 47.5 %; at cap 4, 64 %; at **cap 8**, 71.4 %, and the workflow's independent pass found the points/quality relationship *inverts* at cap 8. At cap 4, **83 %** of golfer-months sit at or above the cap, so the marginal round is already worthless to a regular and the spread comes almost entirely from who missed months.
- **Recommendation (for ruling):** decide what a point is meant to mean, then set the default to match. If Cup Season sells "post your rounds and stay in it with your friends", the current behaviour is correct and the **copy should stop implying skill**. If it sells "the best golfer over a season wins", the default cap should drop to **2 or 3** and the wizard should name it as the quality dial. My recommendation for the pilot is **3** with the wizard sentence rewritten; it keeps a missed week survivable while making a good round matter.
- **Principle served:** product-vision "Real Golf" · §16 (the table should mean what it says).
- **Tradeoffs:** a tighter cap shortens the grind and reduces the reward for enthusiasm — which is the point, but it is a real change in who wins; it also makes a single bad month cheaper.
- **CONFLICT (named):** potentially with §2.2's band design — if the bands are meant to be the skill signal, they are too compressed at the bottom to be one, and the cap is compensating for that. Naming it here rather than silently tuning around it.

### D143 · The season window is the truth; season_months only describes it
*(2026-08-30, season sim. MECHANIC level (4). BUILT 2026-08-30, migration `20260830180000` + client.)*
- **Current mechanic:** `league_settings_season_months_check` is `>= 3 AND <= 12`. `lock_league` also takes explicit `starts_on`/`ends_on`, so the stored bylaw and the real window can disagree without anything complaining.
- **Problem:** a four- or six-week trial season cannot be expressed, which is exactly the shape a first pilot wants. And in any season without a **whole** calendar month the participation floor is never assessed at all (partial edge months are waived), so a short season silently has no floor — a second, quieter disagreement between what the bylaws say and what the engine does.
- **Recommendation (for ruling):** either lower the floor to 1 month and make the wizard warn that floors need a whole month, or keep 3 and have `lock_league` reject dates that contradict `season_months` so the two can never drift. Doing neither leaves a constraint that blocks the honest case and permits the dishonest one.
- **Tradeoffs:** allowing very short seasons invites leagues that end before the engine's monthly machinery does anything, which is its own confusion.
- **CONFLICT:** none upward; touches §14.0's season shape.

### D144 · The Ryder's session resolver has never run — two stacked name collisions
*(2026-08-30, Ryder simulation study. Implementation level (6), but it gates the whole mode. Migration `20260830160000`.)*
- **Current mechanic:** `run_event_sessions` (cron, 07:15 UTC) opens a session with `generate_pairings` and closes it with `resolve_session`, which scores every duel on best PvI inside the window.
- **Problem:** `resolve_session` cannot run. `update event_duels set … a_pvi = a_pvi, b_pvi = b_pvi` is ambiguous between the plpgsql variable and the column, and once that is cleared a second collision appears — the duel loop declares `d record` while the session-story and MVP queries in the same function alias `event_duels` as `d`. Both have been present since 20260713120000 and survived all three rewrites. **Production evidence:** the cron FAILED on 2026-08-30 at 07:15 UTC with `42702`, and the only live event ("The Grudge") holds a session that opened 2026-08-23 and cannot close. The six duels that look resolved are seed fixtures — each has a NULL `a_round` and all six share the event's own creation second. CLAUDE.md's "the Ryder runs end-to-end" describes the build, not anything that has run.
- **Recommendation:** rename the plpgsql names (`a_pvi`/`b_pvi` → `v_apvi`/`v_bpvi`, `d` → `dl`) and leave the SQL aliases alone; they are unambiguous once nothing shadows them. **Also add the R6 idempotency guard** the Ryder never got: a re-run on a closed session returns immediately, as `settle_major` has done since 20260727160000. Without it a stale client (the button is only hidden on `status === 'closed'`) re-posts the session story and can retro-flip a decided duel when a round is voided or posted late — which §R10 forbids.
- **Base discipline:** the newest definition is `20260727180000_ryder_session_voice.sql`, written `CREATE OR REPLACE FUNCTION "public"."resolve_session"` in uppercase with quoted identifiers — a lowercase grep misses it and finds `20260716160000` instead. A first draft of this patch was built on that older body and would have silently reverted the board voice. The migration carries a self-enforcing check that the session voice is still present, so the wrong base cannot ship again.
- **Principle served:** the mode has to run at all · §16 (a result must come from the rounds that produced it).
- **Benefit:** the Ryder can finish. Proven in a rollback against the real stuck session and across nine simulated events.
- **Tradeoffs:** none — thirteen renamed lines and one guard.
- **CONFLICT:** none.

### D145 · A shared Ryder cup engraved every event player in the database
*(2026-08-30, Ryder simulation. Implementation level (6). Migration `20260830170000`.)*
- **Current mechanic:** `award_event_trophies` mints one trophy per player of the winning team, or — when a Ryder ends level — one per player on either side.
- **Problem:** the shared branch reads `from event_players ep where ep.team_id is not null` with **no `ep.event_id = p_event`**. A level Ryder therefore engraves its own name onto every seated player of every event anywhere in the database. The simulation produced **eight** trophies for a two-player event: its own two plus the six players of the unrelated live event "The Grudge". `trophies` RLS is `profile_id = auth.uid()`, so each of those strangers sees, in their own case, a cup for an event they were never in. The winner branch escapes only by accident, because team ids are unique per event.
- **Recommendation:** scope both Ryder branches explicitly to `p_event`, and assert in the migration that two such clauses exist so a future edit cannot drop one. No cleanup is needed and the migration proves it rather than assuming: the shared branch had never run, because D144 blocked completion entirely.
- **Principle served:** a trophy is a claim about a person's record — it has to be true.
- **Benefit:** the shared cup is safe to reach, which matters because the tie is reachable two ways (`draw_rule = 'shared'`, and `team_pvi` when total PvI is also level).
- **Tradeoffs:** none.
- **CONFLICT:** none.

### D146 · The Ryder's finish says WHY, and dead rubbers go on the record
*(2026-08-30, Ryder simulation. MECHANIC/UI (4–5). BUILT 2026-08-30, migration `20260830210000`.)*
- **Current mechanic:** when the sides finish level the cup is decided by `draw_rule` — `shared` splits it, `team_pvi` gives it to the side with the higher total PvI, `defender` (see D147) is unreachable. The completion post reads `"<Team> take the <Event> 5–4."`, or for a tie `"<A> and <B> share the <Event>, 4½–4½."`
- **Problem:** a `team_pvi` decision announces a **tie and a winner in the same sentence**. A simulated 1v1 finished 2–2 and posted a winner with no reason given; a player reads "2–2" and "X take the cup" and has no way to learn that total PvI broke it. Season-side, §14.3's ladder surfaces its rung (`tiebreak_rung` is stored and shown); the Ryder stores nothing and says nothing. Separately, **a clinched event strands its remaining sessions**: `run_event_sessions` only scans events `in ('setup','live')`, so once the cup is mathematically won the rest of the calendar never opens — a simulated 8-session event clinched at 7 and left session 8 `upcoming` forever, with no explanation on any surface. (There is also a same-tick edge: because the cursor is a snapshot, a session whose window opens on the very tick the event completes still gets paired, opening a session on a settled event.)
- **Recommendation (for ruling):** (1) store the deciding rung on the event the way the season stores `tiebreak_rung`, and name it in the completion post — "level on the sheet, <Team> take it on total PvI". (2) Decide what a dead rubber is: either mark the remaining sessions `void` with a reason and say "the cup is already won — these are for pride", or keep opening them and let them resolve for the record (spec §R4 asks for the latter and neither happens today). My recommendation is to say it out loud and keep playing, because the Ryder's whole appeal is the weekly duel, not the aggregate.
- **Principle served:** §16 — no result without its reason.
- **Tradeoffs:** storing the rung needs a column; resolving dead rubbers means the tick must keep scanning completed events, which changes the cursor predicate.
- **CONFLICT (named):** spec §R4 says remaining duels "still resolve for the record" — the engine does not do this, so either the spec or the engine is wrong and this decision settles which.

### D147 · Two Ryder dials were advertised but not wired — one removed, one inherited
*(2026-08-30, Ryder simulation + engine spec. MECHANIC (4). BUILT 2026-08-30, migration `20260830190000`.)*
- **Current mechanic:** `events.draw_rule` accepts `team_pvi | defender | shared` (CHECK-enforced), and `events.allowance` exists as an integer with default 100.
- **Problem:** **`defender` is unreachable.** The branch is `if v_rule = 'defender' and v_def is not null`, and `events.defender_team_id` is never written by any RPC, trigger or client — grep finds only reads. A league choosing "the holder keeps the cup on a draw" silently gets the `team_pvi` rule instead. Spec §R8 says the winner "becomes `defender_team_id` for the next run"; nothing implements it, even though D62's lineage rail now knows which event is a rematch of which. **`allowance` is frozen at 100.** No RPC sets it and no client field exists, so every `× allowance / 100.0` in the engine is an identity — and a Ryder therefore scores at **full handicap while its own league scores at 95**. Two golfers can play the same round and have it valued differently depending on which surface reads it, with nothing saying so.
- **Recommendation (for ruling):** either wire both or remove both. For `defender`: set `defender_team_id` from the previous event in the lineage chain when a rematch is created, which is a natural fit for D62 — or drop the value from the CHECK so the wizard cannot offer it. For `allowance`: decide whether an event should inherit its league's allowance (my recommendation — one number per crew) or stay at 100 deliberately, and if it stays, say so where the event is created. Leaving a CHECK value that cannot fire is the same class as the +10 head start D137 removed.
- **Principle served:** never offer a rule the engine does not have.
- **Tradeoffs:** inheriting the league allowance makes a standalone (league-less) event ambiguous — it would need its own default anyway.
- **CONFLICT (named):** spec §R8 (defender) and §R12.1 (the per-event allowance escape hatch) both describe behaviour that does not exist.

### D148 · The Ryder roster asks first, and the attached league can watch
*(2026-08-30, engine spec. IA/mechanic (3–4). BUILT 2026-08-30, migration `20260830200000`.)*
- **Current mechanic:** `add_event_player(event, profile)` is organizer-gated and inserts any profile straight into the field. `invite_golfer` + `respond_invite` exist and do ask, but nothing forces that door. Separately, `event_teams` still carries its original RLS (`is_event_member(event_id)`) while `events`, `event_players`, `event_sessions`, `event_duels` and `posts` were all widened to attached-league members in `20260720193000`.
- **Problem:** (1) an organizer can enter anyone in the database into their Ryder with no invitation, no shared league and no consent — the client's picker restricts to friends and league-mates, but the RPC does not, and every other roster door in the product asks first. (2) A league member who has not entered the event can see the event, the field, the sessions and the duels, but **zero team rows** — so `renderEvent` falls back to placeholder names and the spectator is shown a **0–0 scoreboard between "Team A" and "Team B"**. The attach is sold as "borrow its crew and its board"; what the crew actually sees is an empty game. (3) Compounding it, Ryder posts are never dual-homed to the league board (`event_post` leaves `league_id` NULL, unlike `major_post`), so the attached league sees neither the score nor the story.
- **Recommendation (for ruling):** widen `event_teams` SELECT to match its siblings (one-line policy change — this is the actual spectator bug and should probably just be done); decide whether `add_event_player` should require an accepted invite for a non-league-mate; and decide whether an attached Ryder's session and cup posts should dual-home to the league board the way a Major's do.
- **Principle served:** #5 the app should feel alive (a spectator seeing 0–0 is worse than no surface at all) · consent parity with every other join path (D57 / setup-QA S3-01).
- **Tradeoffs:** dual-homing Ryder posts adds volume to a league board that did not opt into the event.
- **CONFLICT:** none upward.


### D149 · What was built when the owner said "build your recommendations"
*(2026-08-30. Record of the rulings taken on D142/D143/D146/D147/D148, and of the three questions each left open.)*
- **D142 — cap 3, and the dial renamed.** Standard becomes best 3, Cutthroat tightens to best 2 (which its own description already promised), Casual stays unlimited. The help text now says what the cap decides rather than only what it prevents. **Not taken:** the alternative reading — that the table is *meant* to rank attendance and the copy should simply stop implying skill. The build is reversible in one field if a real season says the enthusiasts feel punished.
- **D143 — the dates win.** `lock_league` derives `season_months` from the window when dates are given, and derives the end date from the months when they are not. The CHECK opens to 1..12. The wizard warns when a window holds no whole calendar month, because the floor is waived in part-months and would never fire. **Not taken:** rejecting contradictory input outright, which would have failed locks for leagues already mid-flow.
- **D146 — say the rung, play the dead rubbers.** `events.decided_by` is the Ryder's `tiebreak_rung`; the post reads "Level at 2–2 — Red take the Grudge on total PvI." The tick now scans `complete` so the remaining calendar resolves for the record, and `resolve_session` refuses to re-decide a settled event so the cup cannot move. Verified: an 8-session event that clinches at 7 now closes 8 of 8 with the same winner. A clinch requires *more* than half the available points, so the scoreboard can never end up contradicting the cup.
- **D147 — remove one, inherit the other.** `defender` leaves the CHECK: it was unreachable, unimplementable without guessing which new team inherits the old winner, and the client hardcodes `team_pvi` so nobody could pick it. `shared` stays — it works. An attached event now inherits its league's `handicap_allowance` (verified: a 90% league produces a 90% event); a standalone event keeps 100.
- **D148 — the roster asks, the league watches.** `event_teams` SELECT now matches its four siblings, so an attached-league member stops seeing a 0–0 board between "Team A" and "Team B". `add_event_player` requires a league-mate, an accepted buddy, or yourself; anyone else goes through `invite_golfer`, which already asks and can be declined. The error names that door rather than only refusing.
- **STILL OPEN, deliberately:** (1) whether a solo league's floor should have teeth at all (D140 left it a habit); (2) whether an attached Ryder's posts should dual-home to the league board the way a Major's do — it adds volume a league did not opt into; (3) whether 3rd place should be paid or a consolation bracket run (D137 parked it until a real season closes).
- **CONFLICT:** none upward. D147 narrows spec §R8 (the defender carry-over is declined, not deferred) and D146 settles §R4 in the spec's favour.

### D150 · Course identity — a round remembers WHERE, so the card can say it
*(2026-08-30. Owner ruling on all four forks. MECHANIC/IA (3–4): it changes what a round records and adds a fact to the Tour Card. Built same day.)*
- **Current mechanic:** two course systems, both broken, neither talking to the other.
  **(1)** The legacy `courses` / `course_tees` tables hold **zero rows** and always have. `rounds.course_id` and `live_rounds.course_id` still FK into them and `finish_live_round` faithfully copies `lr.course_id` into every round it writes — propagating a null out of an empty table. **(2)** `api_courses` (36 cached, from the `courses` Edge Function) is the real catalogue, reached by `rounds.api_course_id`, a deliberately SOFT reference so a round can never fail on a cold cache (`20260714050000`).
- **Problem:** of 211 live rounds, **0** carry a `course_id` and **15** carry an `api_course_id`. By path: quick post 15/206 (**7 %**), live **0/5**, scan text-only. The live path is the worst and it matters most — a live round is a foursome at a real place together, and its `course_snapshot` records the course's *shape* (pars, stroke index) while recording nothing about *which course it was*; `start_live_round` is called with `p_course_id:null` hardcoded even though the setup screen ran the picker and holds the id in the DOM. Meanwhile the quick post's own placeholder — "Search a course, or type your own" — offers free text as a peer, so free text wins. The result is 29 distinct labels for ~13 real courses, with `Papago GC` (32) sitting beside `Papago Golf Club` (3) and `Aguila GC` (29) beside `Aguila Golf Course` (9). **"Who else has played Pinehurst No. 2" cannot be built on a string that is spelled three ways in our own data.**
- **Recommendation (owner ruled all four):**
  1. **Free text is kept but DEMOTED.** Picking a real course is the path; typed text still posts (a muni the API lacks, a friend's club) but is marked an *unlisted course* and does not feed course history or discovery. Nobody is ever blocked from posting a round. *Rejected: requiring a catalogue pick — it would break scorecard scan and guest claims and block real golf.*
  2. **The live path captures and carries identity.** `live_rounds.api_course_id`, `start_live_round` gains a defaulted `p_api_course_id`, `finish_live_round` writes it onto the round instead of the dead `course_id`.
  3. **Backfill by EXPLICIT MAPPING only.** A hand-written label→course table in the migration, applied only where the pair is verifiable; everything ambiguous stays unbound. *Rejected: trigram/fuzzy auto-match — it would silently attach rounds to the wrong course, and a wrong course on someone's card is worse than a missing one.*
  4. **Discovery is CARD-ONLY for now.** The Tour Card gains courses played and, the point of the whole exercise, the courses you and the viewer have **both** played. *Deferred: a "who else played here" course view and course search in the people finder — both turn the product into a location index of its users and want their own decision.*
  5. **Privacy rides the Tour Card's existing gate** — self, accepted buddy, shared league, shared event, or `discoverable = 'everyone'`. One rule, already built, nothing new to explain. *Rejected: a separate opt-in toggle (another setting, mostly-empty feature) and buddies-only (inconsistent with everything else on the same sheet).*
- **Principle served:** §16 (a fact on a card must come from something real) · product-vision "Real Golf" · #5 the app should feel alive — "you have both played Papago" is the first thing in the product that gives two strangers a reason to talk.
- **Benefit:** the card answers the question people actually ask about a stranger; every future course feature (who played here, course leaderboards, a travel log) becomes possible because the identity is finally recorded.
- **Tradeoffs:** the catalogue has duplicates of its own — `Papago Golf Course` is cached under two ids (`6325`, `hpag0kx6`) — so "both played Papago" must match on the course's IDENTITY, not its row id, or it will miss. Free-typed rounds stay invisible to course history forever unless someone re-picks them; that is the accepted cost of not guessing. The backfill only reaches labels a human verified.
- **CONFLICT (named):** none upward. Supersedes nothing; retires the *use* of `courses`/`course_tees` without dropping them (the FKs stay, unwritten — removing them is riskier than ignoring them and buys nothing today).

### D151 · Signup ends on a crew, not a menu — and the card asks where you play
*(2026-08-30. IA level (3) with a UI half (5). Owner: "build em". Measured against the 23 real profiles in prod, sandbox and test aliases excluded.)*
- **Current mechanic:** the golfer card gates onboarding on `marker` AND `handle`. After it saves, a first-timer sees the D82 orientation once and is then dropped into the league-less app shell (`showWelcome`, "no foyer" — v23.55), whose three tiles read **Start a league · Start an event · Join a league**, in that order. The card itself asks for name, handle, optional index, optional GHIN and a marker, and defers the rest: *"City and home course live on your card — add them any time from the You tab."*
- **Problem:** the card is NOT the leak — **20 of 23 (87 %) finish it**. The cliff is the step after. Only **10 of 23** end up in any league, only **4** in a league containing another human, **7** ever post a round and **3** reach the three rounds that establish an index. Six golfers pressed *Start a league* and are still sitting in a league of one — the same failure D96 recorded in August ("seven pilots created a league and stopped, six are still alone in it"). Nothing in signup ever asks the one question that decides whether they come back: **who do you play with?** The "I have a league code" door exists only on the SIGNED-OUT splash, so the moment a golfer has an account is the moment that door disappears. Meanwhile the two fields that make a stranger worth adding — city and home course — are deferred to a tab most people never open (43 % / 39 % filled), and `search_golfers` already RETURNS both while the result row renders neither: asked for late, then ignored when present.
- **Recommendation:**
  1. **A one-time crew step between the card and the app**, for cold arrivals only. Code box first ("got a code from a buddy? this is where it goes"), then find-your-buddies, then start-a-league as the quiet option. Shown once (`cs_crew`), never to an invited golfer, never again after.
  2. **Home course and city move INTO the card**, both optional. Home course is the best "is this guy worth adding" signal, it feeds the search row, and after D150 it anchors course history.
  3. **The search result row renders what it already fetches** — home course and index, not just name/@handle/city.
  4. **The league-less tiles reorder to Join · Start a league · Start an event**, so the first thing offered is the thing that works.
  5. **The handle line stops lying.** The card says "A starting handle — tap to change it"; `set_handle` locks it for 60 days after the first change and announces that change to every league you are in. Corrected here as copy; the formal change flow is its own piece of work.
- **Explicitly NOT done:** a foyer. v23.55 put league-less golfers in the same app deliberately and that stands — the crew step is part of SIGNUP, shown once, not a room anyone returns to. The invited path (`?join=` → covenant → joined on this session) is untouched: it works, and it is the path the AZ pilot will actually use.
- **Principle served:** #5 the app should feel alive (a card with nobody to show it to is not a product) · §13 the funnel is foursome-by-foursome · D96's own diagnosis, finally acted on.
- **Benefit:** the question that determines retention gets asked while intent is highest, and the two fields that make search useful are collected while the golfer is still filling in a form.
- **Tradeoffs:** one more screen between signup and the app — mitigated by showing it only to golfers with no invite, only once, and giving it a quiet skip. Two more optional fields lengthen the card, which is why both stay optional and sit below the marker.
- **CONFLICT (named):** brushes v23.55's "no foyer" — resolved above: signup step, not a room. Nothing upward.

### D152 · Landscape scoring — rotate into the two-up, toggle to the card
*(2026-08-30. UI level (5), no mechanic changes. Owner picked the shape: "default to B but you can toggle A to get a whole round view, see where points were earned if applicable"; hole handicap confirmed available.)*
- **Current mechanic:** live scoring is hole-by-hole — a hole header with arrows, one row per player with a −/+ stepper — and the side games sit in a second column that only exists at `min-width:960px`. There is not one `orientation: landscape` rule in the client, and iOS pins the app to portrait in two places in `project.yml`.
- **Problem:** rotating today would be WORSE than not rotating. `.playgrid` becomes two columns at 960px and a phone in landscape is 844–932px wide, so a rotated phone gets the STACKED portrait layout crushed into a 390px-tall window. And the deeper question stands: a golfer turns a phone sideways to see MORE, and re-arranging one hole earns nothing.
- **Recommendation:** **rotate into two-up, toggle to the card.**
  · **Two-up** is `.playgrid`'s breakpoint moving 960 → 740 so the layout that already exists engages on a landscape phone: hole entry left, the side games that were below the fold on the right. One media query.
  · **The card** is a `HOLE / CARD` toggle in the scoreboard opening the whole round — every player, all eighteen holes, OUT/IN/TOT, the stroke index above the pars, and a ledger strip showing **which holes the side game paid on**.
  · **Scope: live rounds only.** Every other screen is portrait-first; unlocking rotation app-wide means auditing the wizard, every sheet and every hero for a feature nobody asked for there.
- **Three things already existed, which is why this is small:**
  1. **The ledger.** D78 made every engine keep `cells` — who took each hole — with a comment saying the engines "already decide who took each hole and then throw it away… never re-derived by a helper reading netOf(), that would be the second source of truth CLAUDE.md forbids." `matchCalc` returns `'a'/'b'/'h'`, `skinsCalc` the winner's index or `'c'`, `wolfPointsThrough(limit, cells)` `'w'/'o'/'h'`. Where the points were won is a RENDER, not a calculation.
  2. **The visual grammar.** Filled = took the hole, hollow = halved or carried, is already how the in-app strip and the shareable settlement card say this. The card reuses it rather than inventing a second way to state the same fact.
  3. **The stroke index.** `api_course_holes.handicap` is cached for **5,652 of 6,102 holes across 341 tees (92.6 %)**, the client already loads it into `SI_LOADED`, and `SIEST` records when it had to estimate instead. The card prints SI and says when it is a guess.
- **The one thing the card must NOT show:** season points. They are scored per ROUND — the §2.2 bands read a whole round's differential against the index — so there is no per-hole season figure to draw. The strip is the SIDE GAME only, and a "just score" round gets no strip at all, because nothing was won hole by hole and drawing one would invent a competition nobody is playing.
- **Principle served:** §16 (every mark on the card traces to the engine that owns the rule) · #5 the app should feel alive (the card is what a foursome actually passes around).
- **Benefit:** rotating earns information rather than rearranging it; the side games stop being a scroll away; the question "where does everyone stand" gets a one-glance answer.
- **Tradeoffs:** one new read-only surface. Mitigated by it being read-only — no tap targets to protect in a 390px-tall window, and no second entry path to keep in sync with the first. iOS is a SEPARATE piece of work: this decision covers the web client, and the native portrait lock stands until someone does the SwiftUI half.
- **CONFLICT:** none. D78's ledger is consumed exactly as its author intended.

### D152a · Landscape scoring on the phone — the iOS half
*(2026-08-30, addendum to D152. Owner challenged the web-only scope: "wait why does iOS stay portrait locked?" — the honest answer was that it was convenience, not reasoning.)*
- **Why the original scope was wrong:** iOS has a FULL native live module (`LivePlayView`, `LiveSetupView`, `LiveRoundStore`, `LiveFinishViews`) with the same hole-by-hole shape as the web, it already carries `LiveLedger` AND a `LiveHoleStrip` that draws it, and `LiveEngines.match/skins/wolfPointsThrough` are faithful ports returning the same `cells`. Every piece D152 leaned on already existed natively. And the phone is where this matters most — a golfer on a course is holding the app, not a browser. "Different codebase" is not a reason.
- **Built:** `OrientationGate` (main-actor, set by the one screen that may rotate) + `AppDelegate.application(_:supportedInterfaceOrientationsFor:)`, which UIKit re-asks on every rotation attempt. Landscape is DECLARED in the Info.plist and HANDED OUT only while `LiveRoundHost` is on screen; every other screen still answers `.portrait`, so none of them had to be audited for a rotation they will never perform. Leaving the round requests portrait back rather than stranding the phone sideways. `LiveCardView` is the web's `renderHoleCard()`, reading the same engines.
- **The bug this caught before it shipped:** the card was first gated on `horizontalSizeClass == .regular`. An iPhone in landscape is still `.compact` HORIZONTALLY on every model except the Max, so that would have hidden the card on exactly the devices it was built for. The reliable "phone is sideways" signal is a COMPACT VERTICAL size class; `.regular` horizontal picks up iPad and any genuinely wide window. Only found by building and looking.
- **Verified, and the limit of that verification:** the delegate was logged being asked repeatedly and answering `allowed=true`, the app rotated, and the card rendered with the real stroke index, real per-hole match ledger, gold OUT/IN/TOT and green birdies (`docs/design/shots/ios-landscape-card.png`). What could NOT be done headlessly is physically rotating a simulated device — `osascript` cannot send the rotate keystroke without Accessibility permission — so `-cs_dev_landscape` asks for landscape on appear instead. A human should still rotate a real phone once before this ships.
- **Two DEBUG hatches added, both following the established `CSDevHatch` / `-cs_dev_door` pattern:** `-cs_dev_live` seeds a match-play round fourteen holes in and overlays the tee sheet over the root whatever the session is (`-cs_dev_door` already does exactly this for the door), so the live surfaces can be reviewed without an account, a league and a played round; `-cs_dev_landscape` opens it sideways on the card. Neither exists in Release, and the seed never touches the server.
- **Principle served:** the phone owns operating the league (IOS-007) — a scoring feature that exists only on the web is not a scoring feature.
- **Tradeoffs:** the app now declares landscape support, so App Review will rotate every screen and find them portrait — which is correct and intended, but it is a newly declared capability and should land deliberately (the owner confirmed nothing is in review).
- **CONFLICT:** none. D152 said the iOS half was separate work; this does it and supersedes that sentence.


### D152b · The card reads bigger, the sideways hole fits, and a shadowed name gets caught
*(2026-08-30, addendum to D152/D152a. Owner, from the simulator: "the by hole view needs to exist on one screen without scrolls. The card can exist a tad bigger and provide more detail IMO.")*
- **The by-hole overflow, and why it read as two separate bugs.** Sideways, the HOLE column stack was ~415pt tall in a ~380pt window. SwiftUI overflows a too-tall `VStack` **symmetrically**, so the last player's row fell off the BOTTOM and the `HOLE / CARD` toggle fell off the TOP at the same instant — which reads as "the last row is clipped" plus "the toggle is missing", two symptoms of one cause. Recorded because the next person to see a missing header in a landscape stack should look for a height overrun, not a rendering condition.
- **What gave the height back (~55pt, no information lost):** the player CHIPS now stand down in BOTH landscape views, not just the card. In CARD they are restated by the table underneath; in HOLE they are restated by the four rows, which already carry the same name / thru / net. The scoreboard's vertical padding drops to 7 whenever the window is wide, and player rows lose 2pt each. The sync badge STAYS in the hole view — it is the only thing on screen saying whether scores are reaching anyone else.
- **What "bigger and more detail" became on the card:** scores at 16pt mono instead of 13, headers at 13 instead of 11, cells 26 → 32pt, and two additions — a **`+/-` column** (where each golfer stands against par over the holes they have actually finished, the number a golfer reads off a paper card) and a **gold pip** on every hole where that golfer gets a shot. Both landed on the web card too; the two clients are meant to be siblings and one growing a column the other lacks is how they drift.
- **The pips are gated on a REAL stroke index.** `SIEST`/`siEst` means the app guessed the order from par, and the SI row already refuses to print a guess (D152). A pip asserting "you get a shot here" off a guessed order is the same quiet lie in a smaller mark, so it refuses on the same condition. The allocation itself is `strokeOn()` / `strokeTable` — the engine that owns it — never re-derived for the drawing.
- **Bug caught, and it was mine:** D152's new zero-argument `holeLedger()` in `index.html` **shadowed a pre-existing six-argument `holeLedger(mode, cells, played, closedOut, hot, legend)`** that builds the hole strips on every settlement and board card. Function declarations hoist, the later one wins, and all five of those call sites had been silently getting the wrong shape back since D152 landed. Renamed to `cardLedger()`. `tests/preflight.mjs`'s free-identifier check cannot see this — both names are declared — so the lesson is the older one: in a 19k-line single file, grep for the name before declaring it.
- **Verified:** both landscape layouts screenshotted on the simulator (card complete with the `+/-` column and pips; hole view whole, on one screen, nothing scrolling), portrait unchanged, and the web card rendered headlessly with every row at a matching 23 columns. Preflight 20/20. The D152a limit still stands: nobody has physically rotated a real phone.
- **CONFLICT:** none.

### D153 · The finish block gives its space to the side games, and its volume to the round's state
*(2026-08-30. UI level (5), no mechanic changed. Owner, testing on a real phone: "in portrait I think we can fill the space around post round better. Or replace until the round is complete?")*
- **Current mechanic:** below the four player rows, portrait ran — on every hole, all eighteen of them — a "Group phones" pill, a full-width BRAND "Finish round & post to season" button, a five-line auto-attest paragraph, and Scrap. The side games sat under all of that, below the fold.
- **Problem:** on hole 5 the loudest control on the screen is the one you don't want yet, the second-loudest is copy you read once, and the one thing that changes every hole — where the match stands — is the only thing you have to scroll for. D152's landscape column had already fixed this by accident by putting the games alongside the entry.
- **Why "replace it until the round is complete" is not quite the answer:** finishing early is legitimate — rained out, quit after nine — and the finish sheet already handles it properly: it names the missing holes per player and skips partial cards rather than losing them ("A partial card is skipped, not lost"). So the button must stay reachable at every hole. What should change is its **volume**, not its existence.
- **Recommendation, built:**
  1. **The side games move above the finish block** in portrait, permanently. On the web that meant splitting `.playgrid` into THREE children — `.pgentry` / `.pggames` / `.pgfinish` — so a narrow screen takes them in source order while the wide layout re-places them exactly where D152 had them (entry and finish stacked in column 1, games spanning column 2).
  2. **Finish is quiet and says "End the round early" until every seated card would post**, then promotes to the brand button and the full "Finish round & post to season". The landscape column follows the same rule with shorter labels.
  3. **The teaching paragraph speaks once, before the first score.** Its content is restated where it has consequence — the finish sheet opens with "Complete cards post to the season, attested by the group; N guests get a recap to claim."
- **One rule, not two.** Readiness is `LiveCopy.roundReadyToPost` on the phone and `liveReadyToPost()` on the web, and both read `cardHoles` (18 | 9 | 0, the same rule as `finish_live_round`) — which on the web meant HOISTING `cardHoles` out of the finish sheet's closure where it was trapped. Two notions of "the round is done" is exactly how a screen ends up promoting a button the sheet then refuses. `CupSeasonTests/LiveReadyTests` pins it by asserting the promote and the sheet's warning always disagree — five cases including D73's clean front nine and an unmapped round that must not vacuously pass.
- **Principle served:** #5 the app should feel alive — mid-round the screen answers the question a golfer actually has. §16 is untouched: nothing about scoring, posting or eligibility moved; a partial card is skipped exactly as before.
- **Benefit:** the match state is legible without scrolling on a phone in portrait; the button stops shouting eighteen times for a thing you do once; the teaching copy stops being furniture.
- **Tradeoffs:** the finish button is now two taps of reading away from where habit put it, and a golfer who ends every round early meets a quiet button. Judged worth it — "End the round early" is more honest about what that tap does at hole 5 than "Finish round & post to season" ever was.
- **CONFLICT:** none. D152's wide layout is preserved cell-for-cell.

### D153a · The `-cs_dev_live` hatch was a room with no door
*(2026-08-30, same session. Owner: "I scrapped the round, and tried to back out and was stuck in live round settings, had to cancel out of app.")*
- **What happened:** `RootView` presented `LiveRoundHost(links: LiveLinks())` — the DEFAULT `LiveLinks`, whose `done` is an empty closure. Scrapping calls `links.done()`, nothing happened, the host fell through to `LiveSetupView`, and setup's own Close button called the same dead closure. Only the app switcher freed them.
- **Production was never affected:** `MainTabView` passes `done: { presenter.showLive = false }`, which dismisses the full-screen cover. A real user cannot reach this.
- **Why it is still worth a decision entry:** this is the SECOND time this exact shape has bitten (D110 addendum: setup had no toolbar and "the owner got stuck; only the app switcher freed them"). A review hatch wired to a no-op exit cannot exercise the exit, so it hides precisely the class of bug it was built to find. Rule: a DEBUG presenter gets the same `done` wiring as the real one, or it is not a review surface — it is a trap with better lighting.
- **CONFLICT:** none.

### D153b · "End the round early" is withdrawn; the line above the button carries the state
*(2026-08-30, revises D153 the same day. Owner: "I think we backtrack on end round early. It doesn't sit well imo… I think we should have something there and then when all holes are completed a post round option, but need a way to post if not example it gets cut short or group plays 9.")*
- **What was wrong with D153's wording:** "End the round early" passes judgement on a decision that is usually just weather. It also made the button carry the round's state in its LABEL, which is the wrong place — a label should say what the tap does, and this one does the same thing at every hole.
- **The shape, chosen by the owner from three:** a **status line** above a **neutrally worded button**. The line fills the space with the one thing there that changes every hole; the button reads "Finish round" (quiet) until every seated card has every hole in play, then "Finish round & post to season" (brand).
- **The promote rule changed too, and this was a real bug in what D153 shipped.** `cardHoles` returns 9 for a clean front nine WHETHER OR NOT the round was set up as eighteen, so promoting on postability turned the button brand at the TURN and quiet again the moment someone scored hole 10. Promotion is now `roundComplete` — every seated card has every hole IN PLAY — which is strictly stronger than the sheet's test, so it can never promote a button the sheet then warns about.
- **Cut short and nine-and-done never depended on the button's volume.** The sheet has always handled them: it names who is missing which holes, offers "Post N cards to the season" for the complete ones, and "This one was casual — post nothing." A group that quits after 9 of a planned 18 taps the same quiet button and posts four nine-hole cards.
- **Two bugs the swept test found, neither of which a screenshot would have.** `completeAlwaysImpliesTheSheetIsSilent` walks every card-length pair for 9- and 18-hole rounds:
  1. **A nine carrying stray back-nine scores.** Reachable — start an eighteen, score past the turn, Change setup → 9; `setHoles` does not clear holes 10–18 and `backToSetup` keeps the scores. `cardHoles` reads all eighteen because it mirrors `finish_live_round`, so it refuses the card, while "every hole in play is filled" said done. `roundComplete` now requires `everyCardPostable` as well. The sheet ALSO rendered the nonsense "missing holes ." with an empty list here, and told you to "fill in" when the problem is extra scores; it now names the case and adapts the instruction.
  2. **"Short" must mean SKIPPED, not behind.** The first cut called a card short if it had a gap behind the group's furthest hole — so the instant one player entered first, the line read "3 CARDS ARE SHORT". It now means a gap before that card's OWN last score, which is the genuine anomaly. Somebody always enters first.
- **The status line, in full:** nothing scored → no line (the teaching copy speaks there instead) · a skipped hole → "GARY'S CARD IS SHORT" · every hole in play filled but unpostable → "A CARD HAS SCORES PAST HOLE 9" · a clean nine of an eighteen → "THRU 9 · 4 CARDS READY IF YOU STOP HERE" (postable AND not over, both true at once) · otherwise "THRU 14 · 4 TO PLAY" · complete → "ALL 18 IN · 4 CARDS READY" in gold.
- **Principle served:** §16 — the line states what is true of the cards, and every branch of it is pinned by a test. #5 the app feels alive: the space now moves every hole.
- **Tradeoffs:** more copy states to keep true, which is why they are tested rather than eyeballed.
- **CONFLICT:** supersedes D153's wording and its promote rule. D153's structural half — side games above the finish block, teaching copy once — stands unchanged.

### D154 · The tee sheet leads with who you actually play with
*(2026-08-30. Social-graph mechanic, level 4. Owner: "If I am playing with three friends… I build a round, app sees Galen and Jade" — the first of three rungs, the one that needs no permission.)*
- **Current mechanic:** `primeRoster()` fills the live picker with **me + every member of my league, in roster order**. Buddies do not appear at all — the web's own comment says "the chips lead with the LEAGUE; buddies (and anyone else) arrive through the app-wide search, landing as non-posting players." A friend who is not in your league is typed in as a guest every single time.
- **Problem:** the app has recorded every live round you have ever played and uses none of it to answer "who is standing on this tee with me". In a twelve-person league the four names you want are scattered through a list ordered by nothing; outside the league they are not there at all. This is the single cheapest fix to the setup flow and it needs no new permission, no location, and no new disclosure.
- **Recommendation:** a `recent_partners(p_limit)` RPC returning the profiles you have **shared a live round with**, most recent first, with `last_played` and `rounds_together`. The live picker gains a leading section — your regulars — above the league chips; the league list and the app-wide search stay exactly as they are beneath it.
- **The disclosure envelope does not move.** It returns the SAME columns as `search_golfers` (id, handle, display_name, city, home_course, marker, index_current, rel) under the SAME `discoverable` gate, for a strictly NARROWER set of people: those you have demonstrably played golf with. A golfer who has hidden themselves stays hidden and is added as a guest exactly as today. Nothing here is visible that a name search would not already have returned.
- **Principle served:** #3 Real Golf with real friends — the picker should know the difference between your regular foursome and the twelve names on a roster. #5 the app feels alive.
- **Benefit:** the common case ("the same three guys, again") becomes three taps; a buddy outside the league stops being retyped as a guest every week.
- **Tradeoffs:** one migration and one more list section. The ordering is a heuristic — recency and frequency — and will be wrong for a golfer whose regular partners changed; the league list underneath is the escape hatch, so nothing is unreachable.
- **CONFLICT:** none. The web's "buddy chips no longer auto-crowd the picker" comment is respected — this section is not the buddy list, it is the *played-with* list, and it leads rather than crowds.

### D155 · The Live Activity — the round on the lock screen and in the Dynamic Island
*(2026-08-30. UI level (5), no mechanic. Owner: "if a round is started can we have a top bar widget so if you exit app you quickly tap to rejoin?" Executes the roadmap's M3 placement — `IOS-005-roadmap.md`: "the Live Activity IS the match experience on a phone and shares RoundState".)*
- **Current mechanic:** leaving a live round leaves nothing behind on the phone. Re-entry is: unlock, find the app, open it, tap the "Continue your round" banner on Home. The round itself survives fine (local snapshot first, server row second) — it is the *route back* that is four steps.
- **Problem:** a golfer puts the phone away between every shot. The one moment the app must be one tap away is the one moment it is furthest.
- **Recommendation:** an ActivityKit Live Activity started at tee-off and ended at finish or scrap. It shows what the scoreboard shows and nothing more: the hole, the group's thru, and the side game's one-line state ("ALL SQUARE", "2 UP", "HOLE 7 WORTH 3 SKINS"). Tapping anywhere opens the round. Compact Dynamic Island: hole number leading, match state trailing. Expanded: adds the thru line and the next-hole par. Lock screen: the same three facts at reading size.
- **What it must NOT show, for the same reason the card must not:** season points. They score per ROUND (§2.2 bands read a whole round's differential), so there is no per-hole season figure — drawing one would invent a competition nobody is playing. A "just score" round gets the hole and the thru, no game line.
- **One state, one source.** The activity's content is derived from `LiveRoundState` by a producer in `LiveCopy`, the same place the scoreboard and the card get their sentences, so the island can never disagree with the screen.
- **Principle served:** IOS-007 — the phone owns *operating* the league. §16 is untouched: the island states what the engines already decided.
- **Benefit:** re-entry is one tap from a locked phone; the round is visible without unlocking, which is what a golfer actually wants standing over a ball.
- **Tradeoffs:** a second Xcode target (widget extension) and a lifecycle to keep honest — an activity that outlives its round is worse than no activity, so ending it is wired to finish, scrap and abandon, and a stale one is cleared on launch. Live Activities are iOS 16.1+; the app targets 17+, so no floor moves.
- **CONFLICT:** none.

### D156 · Proximity is Bluetooth, never location — and a nearby phone is a HINT, not an identity
*(2026-08-30. New privacy surface, level 4. Owner: "Friend and location awareness? I build a round, app sees Galen and Jade are in proximity and 'Add Jade, Add Galen' populate".)*
- **Current mechanic:** none. The picker has no idea who is standing next to you.
- **Problem, stated before the feature:** the obvious implementation — share everyone's location — is the wrong one for this product. It needs a background-location permission, it puts a record of where your users are on a server that has no other reason to hold one, and it answers a question ("where is Jade") that nobody asked in order to answer the one they did ("who is on this tee").
- **Recommendation:**
  1. **Bluetooth / local peer discovery (MultipeerConnectivity), never CoreLocation.** No location permission, nothing about anyone's whereabouts server-side, and it works in a canyon with no signal — which is a golf course. "We are standing on the same tee" is literally the signal, measured directly instead of inferred from two coordinates.
  2. **Only while the Add-players screen is open, and only after an explicit opt-in.** No background advertising, ever. Leaving the screen stops it.
  3. **A peer is NAMED only if you already know them.** Phones exchange profile ids over the encrypted session; a new `nearby_resolve(p_profiles uuid[])` RPC returns rows ONLY for profiles that are already your buddy or your league mate, in the same envelope as `search_golfers`. A stranger's phone produces nothing at all — not a name, not a count, not a "someone is nearby". The RPC cannot enumerate: you must already hold the uuid.
  4. **Nearby fills the picker; it never fills the round.** You still tap to add. Proximity is a suggestion with no authority.
- **The residual risk, named:** a device can claim a profile id that is not its own, and if that id is your buddy's you would see your buddy's name on a tee they are not standing on. It is bounded by (3) — a stranger cannot be spoofed into your list, only someone you already know — and by (4), the tap. The real backstop is **D125**: a round posted to a member whose own phone never joined the session is not attested, is stamped `posted_by`, and gets that golfer a "That wasn't me". Proximity is therefore explicitly ordered AFTER D125 in the build queue; shipping it first would remove the one guard that makes a wrong add harmless.
- **Principle served:** #3 Real Golf with real friends; the consent posture of `20260713180000` and D118 (a stranger is not addable from a picker).
- **Benefit:** the foursome fills itself for the group that plays every Saturday.
- **Tradeoffs:** local-network permission has its own scary-sounding prompt, which is why the opt-in states plainly what it does and does not do. It needs both phones on the app and on the same screen — this is a "we are all standing here setting up" feature, not an ambient one, and it is not sold as one.
- **CONFLICT:** none. Explicitly rejects a location-based implementation; that rejection is the decision.

### D157 · The three follow-ons from D156 are WITHDRAWN, and the evidence is recorded
*(2026-08-30. Supersedes the recommendation I made in the same session. An adversarial review of my own plan, plus four measurements against prod, refuted all three.)*
- **What was recommended and is now withdrawn:** (A) resolve nearby peers locally on the device instead of via `nearby_resolve`, "so the server never learns two accounts were co-present"; (B) a Strava-style post-hoc "was Jade in your group?" prompt; (C) a short spoken code so a phone can join a live round by typing it.
- **(A) fails on its own premise.** Tapping a nearby name seats both golfers in `live_round_players` seconds later, and `recent_partners` (D154) is built on exactly that table — the product records co-presence durably the moment the feature is USED. The local version deletes a transient query and pays for it with a plaintext social graph in unencrypted Application Support JSON, and with a **revocation failure**: a cached list names a golfer who has since unfriended you, left the league, or deleted their account, where the definer RPC re-reads `friendships`, `league_members` and `deleted_at` every call. Net privacy: worse.
- **(B) fails on the data, measured, not argued.** Across the entire production history there are **7** (course_key, played_on) groups with more than one golfer — and **0** of them are golfers who were not already in the same live round. The feature's whole yield today is people the product already links. The predicate is also indefensible at scale: `course_key` is club-level by design (D150), `rounds` carries a DATE and no tee time, so the match is literally "same club, same calendar day" — a 6am group and a 4pm group are identical to it, and precision falls as adoption rises. And the prompt is itself a disclosure: "was Jade in your group?" tells you Jade played there that day regardless of your answer — which is the "who else played here" course view **D150 rec 4 deliberately deferred**, delivered one name at a time.
- **(C) fails on the security model.** There are **zero** Realtime Authorization policies in the database (`select count(*) from pg_policies where schemaname='realtime'` → 0), so the channel name IS the access control — the client comment says as much: guests "ride the SAME transport with the anon key". Any join-by-code RPC must return `join_code` to be useful, which makes a short code transitively equivalent to the 122-bit channel key. And a seat is not a read-only thing: `live_set_score` checks only that the player belongs to the round (this is D85's deliberate "any phone can fix any score"), so a self-seated stranger can rewrite every card in a money game. No rate limiting exists anywhere in the schema. A code CAN be built — separate `short_code` column, never the channel key; the code PROPOSES and the starter admits; expires at `status='final'` — but that is a different, larger feature and it wants its own entry.
- **The real precondition, restated: D125 is not built.** `rounds.posted_by` appears in no migration. D156's own residual-risk paragraph orders proximity AFTER D125 — and D156 shipped first anyway, in this session, by me. All three withdrawn builds are the same class (unverified self-association with a scored round) and all three were already told to wait for the same guard.
- **Principle served:** §16 — the evidence is written down so the next person does not re-derive it. The Cup Season Test: none of the three made the Saturday foursome better; (B) made it noisier and (C) made it riskier.
- **CONFLICT:** withdraws a recommendation made earlier the same day. D156 stands as built; its ordering violation is recorded here rather than hidden.

### D157a · Two real defects the withdrawn work turned over
*(2026-08-30. Both built, neither needing a decision — they restore stated intent.)*
- **`finish_live_round`'s MEMBER insert dropped `api_course_id`.** The function writes rounds on two paths; the guest path carried the course identity and the member path did not, so every round a league member finished from the tee sheet landed with a null `api_course_id` and fell out of the Tour Card's shared-courses block — D150's entire point. Fixed in `20260830260000` on the live body, with a check that counts the inserts (2) and the `api_course_id` occurrences (4 — a name and a value on each) so the member path cannot silently drop it again. The phone also never SENT one: `LiveStartCall` had no `p_api_course_id` although `course.courseId` is the api id it already queries tees with. Added as an OPTIONAL arg so the skew retry can drop it.
- **`20260830250000`'s header claimed a `discoverable` gate on `nearby_resolve` that does not exist** (`position('discoverable' in prosrc)` = 0 in prod). The BEHAVIOUR is right and is unchanged — that setting governs stranger search, and everything `nearby_resolve` can return is an accepted friend or a league mate who already sees your name. What was wrong is the claim, and the check defending it: the old one asserted only that the strings `friendships` and `league_members` appeared, so it would pass a version that named a stranger as long as those words were in the text. `20260830270000` replaces it with a BEHAVIOURAL check — impersonate a profile, hand the function an unconnected profile's id, require zero rows — and that check was proved to bite against a deliberately broken version that passes the old one. CLAUDE.md said this in its own words already: "a grant assertion in this file is worth nothing until something fails on it."
- **CONFLICT:** none.

### D158 · A nearby phone ASKS. Proximity proposes an identity; only the golfer confirms it
*(2026-08-30. Consent mechanic, level 4. Amends D156. Owner wrote the flow with the step the code was missing: "Jade do you want to join Jerecho's round at Bajamar golf club?")*
- **Current mechanic:** D156 shipped with proximity ending at the picker. Jade's id arrives over Bluetooth, `nearby_resolve` names him, his chip appears under NEARBY, and one tap on **Jerecho's** phone puts Jade in a scored round. Jade's phone is never asked anything.
- **Problem, two-sided:**
  1. **Identity.** D156's own residual-risk paragraph names it: a device can CLAIM a profile id that is not its own. The guard was "you still tap" — but the tap is on the wrong phone. Tapping confirms that *Jerecho* wants Jade, not that the phone across the tee *is* Jade.
  2. **Consent.** Even with no attacker, a golfer can today be entered into a money game by someone standing near them without ever being told. That is the boundary D118 and `20260713180000` hold from the other direction — a stranger is not addable from a picker — and proximity walked around it.
- **Recommendation:** a nearby add becomes an **invitation**, carried over the Bluetooth session the two phones are already on. Jerecho taps "Add Jade" → Jade's phone shows "Jerecho wants you in a round at Bajamar Golf Club — Join / Not me" → only an accept seats Jade in Jerecho's picker. Until then the chip reads ASKING, and a decline removes it.
- **Why Bluetooth and not the server:** the two phones are already connected — that connection is what produced the suggestion. It needs no signal (the case the feature exists for), no push permission, and no seat-after-tee-off machinery, because the invite resolves during SETUP, before `start_live_round` writes any seat. `my_invites` / `respond_invite` remain the right shape if this ever needs to survive Jade pocketing the phone; it does not need to today.
- **What this closes:** the spoof dies on its own. A device broadcasting Jade's id gets Jerecho a chip that says "Jade", but the invitation travels to that peer and only the phone actually holding Jade's session can accept — and if it is a faker, the real Jade is simply never in the round, which is the correct outcome rather than a silent wrong one.
- **What this does NOT close, stated plainly:** attestation. Jade can accept on the first tee, put the phone in the bag, and have Jerecho enter all eighteen holes. That is **D125**'s problem (`rounds.posted_by`, "that wasn't me"), it is unbuilt, and it is not gated on this — the two are independent and both are worth having.
- **Scope: nearby chips only.** A league mate tapped from the roster, a regular from D154, a golfer found by search — unchanged. Those taps assert nothing about who is present; proximity does, and only the assertion needs a witness.
- **Principle served:** #3 Real Golf with real friends; §16 (the round records what actually happened, including who agreed to be in it); D118's consent posture.
- **Benefit:** the feature becomes honest in the ordinary case, not only the adversarial one — nobody is put in a scored round without being asked.
- **Tradeoffs:** one more beat on the first tee, and a nearby add can now fail (Jade's phone asleep, app backgrounded). Mitigated by every other add path being untouched: the league list and the regulars are one tap away underneath.
- **CONFLICT (named):** amends D156 recommendation 4 — "Nearby fills the picker; it never fills the round. You still tap to add" — which located the guard on the wrong phone. D156's ordering-after-D125 argument is narrowed: it was written about unverified self-association, and the invitation verifies the association. The attestation half of it still stands and still points at D125.

### D125a · Attestation now reads a fact instead of asserting one — stage 1 built
*(2026-08-30. Builds D125 (2026-08-29), which stages itself: "the fact (posted_by) ships first".)*
- **The fact that was missing, and why D125 could not simply be implemented.** D125's test is *"that member's own device joined the live session (D85 `live_participant`)"* — but `_live_participant` tests **seating**, not presence: `starter_profile_id = auth.uid() or exists (a seated guest_profile_id = auth.uid())`. Whether a golfer's phone was ever in the session was recorded **nowhere**; `live_round_players` had no timestamp at all. So this build adds the fact before reading it.
- **Built:** `live_round_players.joined_at`, set by a new `live_join(p_live_round)` RPC that both clients call as they join the realtime session. It takes **no player argument on purpose** — a phone can only mark its own seat, so no device can claim another golfer was present. It is silent on a miss rather than raising, because "you are not in this round" is a membership oracle. `rounds.posted_by` records the profile whose phone pressed finish. `finish_live_round` stops stamping the literal `attested = true` and computes `(this golfer = the finisher) or (their seat has joined_at)` on **both** insert paths.
- **Verified end-to-end against real prod data, in a rolled-back transaction, in both directions:** A starts a round seating A and B, only A's phone joins, A finishes → A's card `attested = true`, **B's card `attested = false`**, both `posted_by = A`. Re-run with B's phone also joining → **both attested**. That is the mechanic, not an inspection of it — the earlier version of this session's work would have shipped on a code read.
- **Presence was not enough.** The realtime channel already knows who is on it, and that was tempting. It is ephemeral — it survives neither a backgrounded phone nor a dropped socket nor the gap between the last hole and the finish — and `attested` is written once, at the end. A fact that outlives the socket is the only thing that can be read at that moment.
- **A guest pencil does not call it.** There is no account to stamp; guests stay on the claim-link path exactly as before, and their cards keep their existing behaviour.
- **What is NOT in this stage, per D125's own staging:** the one-tap **"That was me ✓ / That wasn't me"** on the notice and the receipt, and the void it triggers. Unconfirmed rounds still score (§6) and should wear "UNCONFIRMED" wherever a round is shown — that copy is stage 2 as well. Until it lands, the honesty is in the DATA and not yet on the screen.
- **The self-check earns its place:** it fails the push if the literal `'live', true,` returns to either insert, if `posted_by` is not on both, if `joined_at` stops being read, or if D150's `api_course_id` is lost from an insert while rebuilding on this body.
- **Principle served:** §6 (Attested means a playing partner vouched) · §13.1 narrowed from "by construction" to "when the golfer's own phone was in the session" · §16 (the round records what actually happened, including who typed it) · #3 Real Golf.
- **Tradeoffs:** a golfer whose phone is in the cart now posts UNCONFIRMED, which is correct and will surprise people until stage 2 explains it on screen. Three features (D156's proximity, and the two withdrawn in D157) were told to wait for this; the wait is now over for the fact, not yet for the recourse.
- **CONFLICT:** none. Implements D125; narrows spec §13.1 exactly as D125 said it would.

### D159 · A handle you give up is not given away — the formal change process
*(2026-08-30. Identity mechanic, level 4. Completes D151 item 5, which corrected the CARD COPY and explicitly left "the formal change flow is its own piece of work". Owner: "Making usernames concrete or at least a more formal change process like with larger social companies?")*
- **Current mechanic:** `set_handle` already enforces more than most — format `[a-z0-9_]{3,20}`, a reserved-word list, uniqueness, a **60-day cooldown** on a genuine change (Instagram has none), and a system post to every league you are in ("JERECHO IS NOW @jfish"). The phone can SET a handle at the card gate and cannot change one at all.
- **Problem, and it is not the cooldown.** The moment you move from `@jerecho` to `@jfish`, the name `@jerecho` is free and anyone can take it. A cooldown slows the golfer down, not the person taking the name they left. In a product where the handle is how buddies find each other (D118, `search_golfers`) and how a golfer is named in a money game, an instantly re-issuable handle is an impersonation vector. There is also no record on the profile that a rename happened — the system post tells the leagues, and a stranger reading the Tour Card sees only the name of the day.
- **Why this is small: the hard part is already done.** `display_name` is free-form and freely editable; `handle` is the unique key. That separation — the whole of Discord's 2023 migration — already exists here. This is guardrails on a shape that is already right, not a re-architecture.
- **Recommendation, built:**
  1. **`handle_history`** — one row per abandoned handle, keyed on the handle itself, so a released name is **permanently reserved** rather than recycled. Chosen over a release window because at this scale the storage is nothing and "your old name can never become someone else" is a promise that needs no clock to explain.
  2. **`set_handle` refuses a handle abandoned by someone else** ("That handle belonged to another golfer") and **lets you reclaim your own** — taking `@jerecho` back deletes its reservation, because it was always yours.
  3. **A confirmation sheet before the change commits** — the "more formal look". It states all four consequences in the golfer's own terms: the new name, that it cannot move again for 60 days, that the old one is held and cannot be taken, and that every league will be told.
  4. **The phone gets a change path**, which it did not have.
- **Deliberately NOT in this build, and named so it is not mistaken for done:** the "was @jerecho until Aug 30" line on the Tour Card. `handle_history` records what it needs, but `tour_card` is a large function and it wants its own pass.
- **The owner's own handle is corrected in the same migration** — `jerechofischbeck` → `jerecho`, which the cooldown would otherwise refuse (set 2026-07-22, 39 days ago). Done as a guarded, idempotent data fix that also writes the history row, so the old handle is reserved exactly as any other would be. A prod data change rides a migration rather than a console so a human pushes it and it is in the record.
- **Principle served:** #3 Real Golf with real friends — a name is how they find you, so it should not become someone else. D118's consent posture; §16 (the change is recorded, not just applied).
- **Benefit:** a rename stops being a silent hazard; the golfer is told what they are agreeing to before they agree to it.
- **Tradeoffs:** handles are consumed permanently, so a golfer who churns through three names holds four. Acceptable at this scale, and reversible later by adding a release window to a table that already records the dates. The confirmation sheet adds a beat to a rare action, which is the point.
- **CONFLICT:** none. Completes D151 item 5.

### D160 · The copy says what happens to you, not what the system does — four surfaces rewritten
*(2026-08-30. UI level (5), copy only, no mechanic. Owner, before the pilot push: "it needs some organic elements… lots of choppy AI language", with four named examples.)*
- **The pattern being removed, named so it stops coming back:** middot chains standing in for sentences ("Hole-by-hole on every phone · Match Play, Wolf & Skins · … · guests welcome, no account") and aphorisms that name a rule without saying what it means to the reader ("pick once, argue never" · "locks at first tee" · "every season starts level"). Feature lists read as written by the system; a person explains the consequence.
- **Rewritten, on BOTH clients (the strings live once in `WizardCopy`/`CareerRecord` on the phone):**
  · The Golf hub's header now says what the page is for: "Play one live, post one you just finished, or plan the next."
  · The live door: "Everyone scores from their own phone — Match Play, Wolf or Skins — and it settles up at the end. Friends without the app just play; their card is waiting when they want it." (The demo diorama's variant matches.)
  · The wizard: eyebrow "Create your league — set the rules once, lock them in"; the competitiveness step asks "How serious is your league?" and its help now carries the why: "…Deciding this before anyone tees off is what keeps October friendly." The aside hint explains the lock instead of naming it; "Forming · locks at first tee" → "Forming — the rules aren't locked in yet"; the bylaws hub header → "The bylaws — the rules this league plays by."
  · The trophy case: "The case is empty — for now. Cups, crowns and event wins hang here when you take them."
- **Principle served:** D82's "copy must be kept true" and the product canon's plain-spokenness; a label is for the reader, not the schema.
- **Tradeoffs:** longer lines on three surfaces. Accepted — the middot chains were short because they were lists.
- **CONFLICT:** none.

### D161 ⚑ · Mid-season joins are ungoverned — D112 is ruled and unbuilt, and the spec's own halfway rule is unbuilt too
*(2026-08-30, PARKED for the owner's queue. Owner: "why can I add players to Who's the Bitch which is a few weeks into the season?")*
- **Why it happens, precisely:** neither `join_league` nor `add_friend_to_league` checks league phase at all — verified against the live function bodies. The code path admits into ANY phase; the Pro's add-a-buddy path checks only commissioner + friendship + not-already-member. "Who's the Bitch?" is `phase='season'` (Aug 3 → Nov 2), so both doors are open.
- **This is two unbuilt things, not one bug:**
  1. **D112 (ruled 2026-08-29, unbuilt):** join paths must refuse `setup` ("the Pro is still setting the bylaws") and `complete` ("ask the Pro to run it back"). One migration, sentences already written.
  2. **The mid-season rule the spec already has:** §15 — "Mid-season joins until halfway (provisional scoring; floor prorates)… late joiners assigned to the thinnest squad, logged." So a join a few weeks in is *per spec* — what is missing is the HALFWAY CUTOFF, the floor proration, and the thinnest-squad assignment. None are built; today a late joiner lands ungoverned and un-prorated, which is worse than either allowing or refusing properly.
- **Decision needed from the owner:** build D112's refusals as ruled, and then either (a) build §15's halfway rule as specced, or (b) simplify: joins close at first tee, full stop (amends §15). (b) is less machinery; (a) is what the spec promises.
- **CONFLICT if (b) is chosen:** amends spec §15's mid-season-joins sentence — must be logged as such.

### D161 · RULED (option A) and built — the code closes at first tee, the Pro's door closes at the halfway turn
*(2026-08-30, same day as the ⚑. Owner: "Build A." Supersedes the parked entry above; amends spec §15 and §14.1's floor proration as named below.)*
- **The two doors, now with different rules because they are different acts:**
  · **The code** (`join_league`) admits between the lock and the first tee, and then stops working: *"The season's underway — ask the Pro to add you. You're welcome on the tee sheet meanwhile."* Nobody self-joins a race that has started with money in it.
  · **The Pro's door** (`add_friend_to_league`, and `respond_invite` for league invites — both Pro-initiated) stays open to the season's halfway turn, then: *"Past the halfway turn — the roster's set for this season."* A decline is never gated; saying no must always work.
  · Both also carry **D112 as ruled**: setup refuses ("<name> isn't open yet — the Pro is still locking in the rules"), complete refuses ("ask the Pro to run it back").
- **A late joiner is governed, not merely admitted:** their join-month floor is **waived** — `close_month`'s floor loop skips a member whose `joined_at` falls inside the month being closed, the §14.0 partial-month blanket rule applied to a partial member-month (replaces §14.1's unbuilt proration; simpler, and `joined_at` already held real data for all 47 members). In a squad league they land on the **thinnest squad** and the board says so (§15). One internal `_join_gate` + `_late_squad` pair, revoked from everyone, so three functions cannot drift.
- **Found broken while building, repaired in the same file:** the live `add_friend_to_league` calls `are_friends(uuid, uuid)` — **a function that does not exist in prod** (only `friend_request`/`friend_respond`/`my_friends` do). Every call has raised "function does not exist" since it shipped; the owner's mid-season adds that prompted this whole question went through the INVITE flow, not this function. The check is now the inline `friendships` test the rest of the schema uses. Caught by the behavioural probe, not by reading — the fourth time this session that pattern has paid.
- **Proved in a rolled-back transaction against prod:** a setup league refuses the code with its name in the sentence · a live season refuses the code · the Pro's add before halfway seats the joiner on the thinnest squad ("…THE THINNEST SQUAD TAKES THEM: BRAVO"), stamps `joined_at` today · past halfway the Pro door refuses · `join_covenant_info` now carries `phase` so the door can say "not open yet" before the OTP round-trip.
- **Clients:** the refusal sentences pass through verbatim (web `humanError` allowlist; the phone's `HumanError.text` gains the same pass-through it never had). Setup stops flaunting a code that admits nobody — web `#phaseSub`/`#setupInviteSub`/`#hhCodeSlot` and the phone's `phaseSub`/`seatFill`/code chip all read "lock the bylaws to open invites" or hide the code until the lock.
- **Principle served:** D112's own line — a covenant is consent to fixed terms, and once money is in, the roster is one of them. §15's human intent (the straggler gets in, vouched) survives; the stranger with a leaked code does not.
- **Tradeoffs:** a Pro who texted the code early now sends friends into a sentence instead of a seat — the sentence names the fix. §15 amended: "mid-season joins until halfway" is Pro-only; "provisional scoring" remains undefined and unbuilt, noted, not promised.
- **CONFLICT (named):** amends spec §15 (mid-season joins: Pro-only) and §14.1 15th rule (proration → join-month waiver). D112 is hereby BUILT for `join_league`/`add_friend_to_league`/`respond_invite`; its remaining client copy items rode along.

### D165 · The board stops shouting — natural case at the generator, permanently
*(2026-08-31. Copy/mechanic boundary: no competition rule changes, but the ruling is permanent and binds future SQL. Owner: "Yes kill CAPs". Implements the ruling in `spec/voice-and-tone.md`.)*
- **The ruling:** authored SENTENCES — anything a person reads as prose — are written in **natural case at the generator, in SQL**. ALL-CAPS survives only as typographic furniture that was never a sentence: eyebrows, status chips, data rows (`THRU 14 · +2`), settlement headlines.
- **Why it is a defect and not a preference — three findings, each verified:**
  1. **`easeCaps()` cannot do this job.** It guards on `s === s.toUpperCase()` (`index.html:5050`), so the moment a generator interpolates one lowercase fragment — a name, `' v '`, `@handle` — the guard fails and the WHOLE line ships raw caps. Every generator here interpolates something.
  2. **Push has no lowercasing pass at all** (`supabase/functions/push/index.ts`), so every shouted body reached the lock screen shouting — the surface with the least context and the most people.
  3. **Even when it fires it destroys proper nouns.** The client's own comment says no cleverness recovers a proper noun from an all-caps source. `upper(v_course)`, `upper(s.name)` and `upper(name)` were erasing real course, event and squad names *on the way into the database*.
  It was already proven safe: `20260727160000_board_voice.sql` wrote its floor branches in natural case and they read best on the board. This finishes what that started, across **35 functions**.
- **Five bugs fixed in passing, each found by the audit and verified against prod before being believed:**
  · **Mojibake.** `finish_live_round` and `start_live_round` carried **10** double-encoded sequences (U+00E2 U+0080 U+0094 for an em dash, U+00C2 U+00B7 for a middot). Four sat in LIVE COPY — including the live-round **push body** and the halved-match settlement line. No garbled post is on the board yet *only because those paths had not fired*. All 10 retyped.
  · **The solo round robin reported the wrong result.** `rrResult()` returns no winner and no sides, so every 4-player solo round robin fell into the halved branch: the board read "side A and side B halved the match — no money moves" **while the client had already moved real money**. The fix is a RESTORATION — `20260727240000_name_resolution.sql` wrote a client-story branch and a later create-or-replace chain dropped it.
  · **`posts.push_title` stopped being written** by that same regression, so settlement pushes lost their titles.
  · **"with pick 0".** `make_pick` captured the draft row `for update` before incrementing `current_pick`, so every draft's opening pick announced itself as pick zero.
  · **"Jerecho take the Cup Final".** In a SOLO league the champion is a person; `v_solo` was already in scope and unused here.
- **`declare_round` was the generator no auditor found** — it upper()s the course and every tagged golfer. De-shouted here (its 5-arg overload, named explicitly since two exist). **FLAGGED, NOT FIXED:** both clients call the SIX-arg overload, which posts **nothing to the board at all**, so a declared round never reaches the league. That is a gap worth its own decision, not a silent change inside a copy migration.
- **Method, because it is the reusable part:** every body is the LIVE definition pulled with `pg_get_functiondef`, patched fragment-by-fragment by script with each fragment asserted to match exactly once, and re-emitted whole. 65 of 68 fragments applied on the first pass; the 3 failures were exactly the mojibake sites, whose invisible C1 bytes cannot survive being quoted — they were repaired by code-point substitution instead. A self-check now fails the push if a shouted sentence returns, if the mojibake returns, if `push_title` or the story branch is lost again, if any function upper()s a proper noun, or if any of these opens to `anon`.
- **Principle served:** the canon's "Confidence without volume" · §16 (every fact each post carried, it still carries: names, numbers, consequences).
- **Tradeoffs:** 35 functions replaced in one migration — large, but each is a verified fragment patch on its own live body rather than a rewrite. Squad-name plurality ("Frost take the Cup") is still unresolved in `make_pick` and `close_season`; noted for a later pass.
- **CONFLICT:** none. Supersedes the ALL-CAPS house style wherever it applied to prose.

### D166 · The moments the product never had
*(2026-08-31. New mechanic: the board gains six events it never observed. Owner: "address missing moments". Implements the gaps named in the D165 audit against `spec/voice-and-tone.md`.)*
- **Current mechanic:** the board's entire emotional vocabulary was **three lines** — a barrier broken, a personal best, a streak — plus one lead-change post. Everything the canon cares about most was silent.
- **Problem:** the product's whole premise is that a Saturday round becomes part of a season, and the season could not observe its own turning points. `20260716200000_post_round_peak.sql` opens by promising "the comeback/collapse tag (#23)" and no copy was ever written.
- **Built, each from data that already exists — nothing here invents a table:**
  1. **The blown lead.** `squad_lead_moments` posted from the NEW leader's side only; the side that just lost first place — the most story-shaped event in a season — got nothing. It now reads `season_lead.since` and the weekly `standings_snapshots` to say how far the deposed side had been clear, and how long they held it: *"…were 14 points clear at their best. A commanding lead. Formerly."* / *"…held first for 21 days. Once upon a time."* / *"Well. That didn't last long."*
  2. **The comeback.** New `post_week_comeback(season, week)`, called by `snapshot_week` on a genuine insert.
  3. **Last place**, at season close only: *"Someone had to complete the field."*
  4. **The bad round:** *"Not the day X had in mind. We'll leave that one on the scorecard."*
  5. **Rivalry heat** in the weekly clash: *"Three clashes in a row to X. This is becoming a problem."* / at five, *"Annoyingly good."*
  6. **Welcome back**, for a golfer returning after six weeks away.
- **THE GUARDS ARE THE DESIGN**, and each exists because the review found a way the line could hurt someone:
  · **Last place must never fire inside a Cup Final.** `_ranked` there holds ONLY the finalists, so the bottom row is the **fourth-best team in the league** — naming them "last" is precisely what the canon's punch-at-the-golf rule forbids. `and not v_cup`.
  · **The bad round must never land on a beginner.** `index_at_post` for a new golfer is a *starter index they guessed at signup*, so someone who typed 12 and shot a 20 differential would trip it on their **first ever posted round**. Requires 5+ prior rounds AND `index_source_at_post = 'app'` (a number the app derived from their own scores), 18 holes, and at most once per 60 days — and every warmer headline outranks it, so a return or a streak wins instead.
  · **The comeback must not guess.** Nothing before week 4 (`p_week - 3` would read week ≤ 0); silence rather than a guess when a snapshot is missing, or a skipped cron run makes the comparison NULL and the line could re-fire every week; and **no week numbers** — `snapshot_week` computes the week as `floor(days/7.0)` while `open_week_clash` uses `floor(days/7)+1`, so on the same day they disagree by one and "back in week 40" would contradict "the clash this week" on the same board. "Three weeks ago" is safer and better copy.
  · **Rivalry heat** measures true run length, so it fires once at three and once at five, never every week after.
- **Verified behaviourally, not by reading:** ten assertions run inside the migration — the comeback stays silent at week 2 and with no snapshot; the bad round is guarded on both history and index source; welcome-back outranks the bad day in the cascade; last place exists AND refuses a Cup Final; the blown lead speaks and no shouting returned; rivalry heat fires at 3 and 5; the new function is not anon-callable. The probe is left in the file as a **gate** — any failure raises and the push stops.
- **Principle served:** the canon's own priority order for moments; #5 the app should feel alive; §16 (every line states something the data supports).
- **Tradeoffs:** six new voices on a board that had one. Mitigated by every one being rare by construction and by the cascade ordering, which prefers a warm line to a cold one whenever both qualify.
- **CONFLICT:** none. Completes the promise in `post_round_peak.sql`.

### D168 · Nearby follows the app, not one screen — and the invitation belongs on push
*(2026-08-31. Amends D156 recommendation 2. Owner, after a two-phone test: "I envision someone saying to the group 'I'll put the round together, just join when prompted.' If all parties need to open phone and do 5-6 clicks then this defeats the point.")*
- **Current mechanic:** D156 confined Bluetooth advertising to the **Add-players screen**, started `onAppear` and stopped `onDisappear`. So a foursome could only be assembled if all four golfers were on the same screen at the same moment.
- **Problem, in the owner's words:** that defeats the point. The real shape of the moment is ONE person building the round while the others stand there talking. Requiring everyone to navigate to a particular screen makes the feature slower than typing names.
- **Built now:** advertising follows the **app**. Foreground and opted in = askable by your buddies, on any screen; the tab shell starts it on `.active` and stops it on `.background`. `startNearby()` became idempotent so it is safe to call from anywhere, and a live round still stops it — the foursome is set, there is nobody left to ask.
- **The constraint that does NOT move, stated plainly:** MultipeerConnectivity has **no background mode**, so "app merely active in a pocket" is impossible on this transport. D156's "there is no background mode and this file must never acquire one" stands. The CoreBluetooth workaround is rejected: two backgrounded iOS apps discovering each other is unreliable, it is a permission App Review scrutinises, and it would still be slower than the rail we already have.
- **The real answer, PROPOSED and not yet built: the invitation moves to PUSH.** `PushActions.swift` already registers notification categories whose buttons *"run in the background — no `.foreground`"*, calling the same RPC the screen would; three ship already (invite, request, RSVP). A fourth — `CS_JOIN`, with **Join / Not me** — makes the owner's sentence literally true: buzz in the pocket, one tap on the lock screen, seated, app never opened. Proximity then becomes what it should always have been: a **hint for building the foursome**, never the channel that delivers the invitation. Tapping a nearby chip would push that golfer rather than depending on their screen.
- **Two questions for the owner before that is built:** (1) push reaches only an account with a registered device — buddies and league mates; a guest with no app keeps the claim-link path, which is a narrowing versus Bluetooth, which can reach anyone standing there. (2) Does push REPLACE the Bluetooth ask or sit beside it? Recommendation: replace. Two invitation channels means two ways to be half-invited, and the Bluetooth one is the fragile one.
- **Principle served:** the Cup Season Test — a feature that needs five taps from four people is not the feature the sentence describes.
- **Tradeoffs:** a wider advertising window (any screen, still foreground-only, still opt-in, still resolving only buddies and league mates). D156's disclosure envelope is untouched.
- **CONFLICT (named):** amends D156 rec 2 ("only while the Add-players screen is open"). Its background prohibition is reaffirmed, not weakened.

### D173 · The live sheet had no door either — D110's bug, one screen over
*(2026-08-31. Owner, from a two-phone test: "when my phone was pulled into the round I was barred from the rest of the app, no back button… couldn't leave that page within the app".)*
- **Current mechanic:** `LiveRoundHost` presented `LivePlayView` BARE inside a full-screen cover — no `NavigationStack`, no toolbar, no Close. Its own `.navigationTitle("Live round")` rendered nothing, because nothing wrapped it.
- **Why it went unseen until now:** the D110 addendum fixed exactly this for the SETUP branch and left a comment three lines below the live branch saying "a full-screen cover with no toolbar (the owner got stuck; only the app switcher freed them)". Nobody had ever ARRIVED at the live view without walking through setup first — until D163 began pulling an invited golfer straight into a running round. The trap was always there; the new door led to it.
- **Built:** the live branch gets its own `NavigationStack` and a Close. **Close dismisses, it does not leave the round** — the round keeps running on the server and on the wire, and `LiveNowBar` sits above every tab offering the way back. Scrap and Finish remain the only ways to end a round.
- **Principle served:** a screen a golfer cannot leave is not a screen, it is a trap. #5.
- **CONFLICT:** none. Completes the D110 addendum, which fixed one of the two branches.

### D174 · Quick wins from the ship audit — the composer stops lying about points
*(2026-08-31. Owner: "any quick wins we can change from the audit". The audit is `Before First Tee`; these are its cheapest three.)*
- **THE COMPOSER SCORED AT 100% WHILE THE ENGINE PAID THE LEAGUE'S ALLOWANCE.** `vs = state.myIndex - diff` applied no allowance; every league defaults to **95%**. Measured in prod, not asserted: **11 of 11 real 18-hole scored rounds displayed a figure the engine did not pay, and 4 of them crossed a points band.** The owner's own 2026-08-16 round showed 12 points on screen; the engine paid 9.
  · Fixed with ONE producer, `pviFor()`, that matches `v_rounds_ranked` exactly — `round(index × allowance/100 − differential, 1)`, rounding the whole expression so the band edges (≥3, ≥1, >−1, ≥−3) agree at the boundary. Verified numerically: 13.6 index, 10.3 differential, 95% → **2.6 → 9 points**, identical to the engine, where the old code showed 3.3 → 12.
  · `leagueAllowance()` prefers the league's **stored bylaw** (`select('*')` already returns it; the client had never read it back) and falls back to the preset map. **A league-less round stays at 100%, which is correct** — it is scored against the golfer's own number.
  · This matters beyond arithmetic: the product's promise is that every point has a receipt, and a Pro who cannot reproduce a points figure by hand will not keep the league.
- **The marker grid now says what it is for.** The blind audit's severity-9 finding hit 7 of 7 personas — "every member shows the identical cactus" — while Settings promised "the marker always backs it up" to people with no photo. One line, both clients: *"This is your icon on the board and in the standings until you add a photo."* This is what that finding actually asked for; it is NOT more photo machinery (see the audit's KEEP BUT DO NOT INVEST ruling).
- **Six shouted board posts, written hours before D165 landed**, are backfilled by `20260831150000`. `easeCaps` cannot rescue them — the interpolated lowercase " v " breaks its strict-equality guard — and the weekly idempotency guard pins them at the top of the board for about a week. The migration is narrow by construction (system posts, the clash shape, written before D165) and idempotent.
- **CONFLICT:** none. D123 logged the one-PvI-per-round principle; this builds its client half.

### D175 · The radio followed the app; the door didn't
*(2026-08-31. Owner, four separate test sessions: "it still sits at asking unless I am in the post round section" · "phone still needed to be in post round to be found".)*
- **The diagnostic settled it.** D173 added `nearbyPrint()` to `startNearby()`'s guard so it names the failing precondition instead of failing silently. Attached to the owner's phone with `devicectl … --console`, a cold launch printed **`startNearby OK — advertising`** before any screen was opened. So D168 (advertising follows the app) and D170 (keyed on identity, not on the view appearing) both work — the radio was never the problem after D170.
- **Current mechanic:** the invitation ALERT lived on `LiveSetupView` and nowhere else. A phone was therefore **discoverable on every screen and answerable on exactly one**. Three fixes had each moved the radio further out and left the door where it was, which is why the owner's sentence never changed.
- **Built:** `csNearbyInvite(_:enabled:)`, one modifier, mounted in **two** places — the tab shell (`MainTabView`, `enabled: !presenter.showLive`) and the setup sheet. Two hosts is not redundancy: **an alert cannot present from a view a full-screen cover is sitting on top of**, and the tee sheet IS that cover. They are mutually exclusive by the `showLive` guard.
- **The binding's setter is deliberately empty.** The original `set: { if !$0 { answerIncoming(false) } }` turns any *programmatic* dismissal — the cover rising underneath it, a scene change — into a silent **decline of a round the golfer never saw**. Both buttons clear `incoming` themselves and an alert cannot be swiped away, so nothing is lost and a whole class of phantom "Not me" disappears.
- **Principle served:** proximity's promise is *"I'll put the round together, just join when prompted"* (the owner's own words). A prompt you can only receive on one screen is not a prompt.
- **Method note worth keeping:** three consecutive guesses cost a two-phone testing session each. One `print()` behind `devicectl --console` cost four minutes and named the answer. When a user reports the same sentence twice, stop reasoning and instrument.
- **CONFLICT:** none. Completes D158's handshake across D168/D170's surface.

### D176 · The lead card, and the clash finally reaches the two people in it
*(2026-08-31. Owner, after the Home artifact: "Lets do C building on A like you propose." Copy rulings in the same message — "tonight" → "today", "Next" → "Next round", an empty calendar says "Put a round on the calendar".)*

**Current mechanic:** Home ran the same ten slots in the same fixed order every day. Sunday looked like Wednesday; the last day of the month looked like the first. The only variance on the whole screen was the hero's ▲ chip and the occasion card's seasonal wink — and the occasion card is about the *calendar*, never about your season. Meanwhile `UpNextChips` stated four facts and offered no tap at all: **"Month closes in 1 day" — the difference between points counting and points evaporating — was inert**, and so was "Needs you · 2 invites", which is a person waiting on you. The calendar's only door was item four of five inside a `+` menu, and a plus sign reads *make something*, not *go somewhere*.

**Built — A (the floor, ships regardless):**
- **Every chip names a destination.** `UpChip.Go` on the phone, `data-upgo` on the web: next round → the round, buddy's playing → the round, needs you → your buddies, month closes → the league room where the arithmetic lives. A chevron is the only visual change.
- **"Coming up" gets `THE CALENDAR ↗`** — the identical pattern "Around your buddies" has used for the board all along. No new vocabulary.
- **The section no longer VANISHES when nothing is booked**, which was exactly the moment a golfer needs the calendar most. It shows *"Put a round on the calendar"* instead (the owner's own words; the web's Next tile said "PLAN A ROUND", which is the app talking to itself).
- **Amber is spent where it means something.** The month chip appeared at ten days out wearing warm the whole time; it is plain until three days, then warm. Amber that is always on says nothing.

**Built — C (the lead card):** ONE slot above the hero that changes with what is true today, on a **fixed, documented ladder**, first match wins, one card, never a stack:
1. **the clash** — the only rung with a hard deadline *and* a named opponent
2. **the floor** — also a deadline, but arithmetic rather than a duel; skipped entirely when `partial` (§14.0 waives floors in edge months, and asking for a waived floor is the exact contradiction the audit logged elsewhere)
3. **your move** — it happened, it is worth telling, nothing is owed
4. **a buddy's milestone, today** — someone else's news; the feed carries it anyway, so this only lifts it when nothing of yours is pressing
5. **nothing** — and **no card is the resting state.** The hero below is already a good one.

The two rules that keep a changing screen learnable: one card at a time, and the ladder never reorders. The hero says where you stand; the lead card says what today is asking. Everything it reads was already loaded — rank, `prev_rank`, the month floor, the feed — except the clash.

**Built — the clash's missing beats.** The clash was a duel announced to an empty room: `open_week_clash` named two people and stopped. No stakes, no deadline, and **the two named were never told they were named.**
- **Beat 1 · the open post carries the mechanic**: *"The clash: Galen v Jerecho. Best round of the week takes it."* A named rivalry (D21) earns the headline — *"'The Cactus Cup' is on again"* — the one line all season where that name belongs.
- **Beat 2 · the two get told** — the lead card, for them only. A clash you are *not* in belongs on the board, not on your Home (ruling).
- **Beat 3 · `clash_last_call`**, the owner's own instinct, on the window's final day, from the tick that already runs at 00:20 local: *"The clash closes today. Neither of them has posted."* / *"…Galen has answered. Jerecho has not."* / *"…Galen leads it. One round to change that."* **"today", never "tonight"** — the window closes at the end of the calendar day and hardly anyone plays golf in the dark. Both clients say it the same way, and a check in the migration RAISES if the word "tonight" ever appears in that function.
- **Beat 4 · settle** was already good and is untouched but for all-square, which re-announced the pairing instead of stating the result: → *"All square in the clash. Nothing settled."*

**`home_clash(p_league)` is an RPC, not an embed, for two reasons.** Home does not load `v_rounds_ranked`, so "best so far" on the client would be a **second implementation of the settle's pick** and the card and the result would drift. And `week_clashes` carries TWO FK paths to `league_members` (`a_member`, `b_member`) — the D171 PGRST201 trap exactly. One SECURITY DEFINER function, granted to `authenticated` only, null unless you are in the clash.

**Verified against prod in a rolled-back transaction, not asserted:** the owner in the clash gets the card; a league-mate who is not in it gets NULL; a non-member gets NULL; last call writes the right sentence and is idempotent (one row after two calls); the open post reads as intended.

**Also — the buddies door moved.** On You it sat **seventh**, under five sections of record, and it is the only DOOR on a page that is otherwise all reading. You do not scroll past your own trophy case to reach a person. It now sits directly under the hero; everything below that line is the record. (The full You reorganisation — grouping *your golf* and *in this league* — is NOT in this decision; it is the next one.)

**Principle served:** #5, everything shows its work — a figure with a deadline is worth nothing if the deadline is never stated. And the product vision's "make ordinary moments feel like stories": a weekly duel nobody is told about is not a story.

**CONFLICT:** none. D108 built the clash engine and its Clubhouse card; this gives it a voice and a home. D94's web tile row already carried the calendar door the phone lacked — the two clients had diverged, and A closes the gap from the phone's side.

### D177 · Your card and your people — a spine for You, and a request that reaches you
*(2026-08-31. Owner: "then we fix You and friends interface", then chose grouping by SCOPE with no league picker after I corrected the premise of my own proposal.)*

**A correction first, because it changed the design.** My proposal grouped the bottom of You under an "In ‹league›" head and asked the owner whether that head should be a picker. Reading the loaders showed the premise was wrong: **only one of those three sections is league-scoped.** `my_rivalries()` takes no league argument — it is your lifetime clash record across every league. `loadLeagueRecord(me:)` returns one row per membership, so it spans every league by construction. Only `loadSeasonStats(me:leagueId:)` is scoped, **and its head already names its league.** An "In ‹league›" head would have been a lie over two of its three children. The groups therefore split by **scope**, not by league, and there is no picker — the Clubhouse is where you switch rooms.

**The people findings, which are bugs wearing a design costume:**
- **A buddy request had NO Home surface on iOS.** `InvitesBanner` carries league and Ryder invites only; the header comment in `HomeView.swift` had claimed since the port that it also carried "buddy requests (inside the banner)". It never did. The web has had `renderHomeRequests` on Home since D81 — the port dropped the row and kept the promise. So a person asking to be your golf buddy incremented a badge, was counted by the "Needs you" chip as an *invite*, and appeared in exactly one place: the buddies screen, third section down, behind a door that sat seventh on You. **Distance was never the problem; silence was.** `BuddyRequests` is now ONE renderer with two homes — D93's rule, which the web already followed — and it costs zero pixels on the days nobody has asked.
- **Two search entry points, stacked.** A "Find a golfer" button that opens a sheet *whose first element is a search field*, sitting directly above an inline search field doing the same job. On the page named after buddies the inline one is real; the button is gone from both clients. The People Picker is untouched and still serves every other caller.
- **Requests now LEAD.** A person waiting on you outranks a search box.
- **The empty search handed nothing over.** *"Invite links still work for everyone else"* named a thing and did not offer it. The link is a permanent door under the field now, because the golfer you most want to add is usually the one without an account. It is the **league** join link — the only invite link that exists; a buddy-invite link is a different mechanic and would need a decision, not a tidy, so this offers what is real or nothing.
- **"Findable by" reads as a setting** — a rule above it and a sentence saying what it does, rather than looking like another section of the list.
- **The buddies door reports**: *"1 request waiting"*, with an ember edge, on both clients.

**You, regrouped.** The page carried **five sections about your history under four names**, interleaved with people and with the app's manual:
- *The record* was silverware counts + money; *Your display case* one section above held the same trophies as objects. **Merged** — the counts are the case's top strip, the objects sit under them.
- *Lifetime* → **All time**. It shares two row LABELS with *This season* ("Rounds posted", "Avg vs index") and the only thing telling them apart was a small grey sub four sections away.
- *League record* → **Every season**. It was the third heading meaning "record" and the only one that was not one: it is a season-by-season list of where you finished.
- *Rivalries · your record* → **Rivalries · all leagues**, because it sits beside a season-scoped strip that would otherwise lend it the wrong scope.
- Two `CSGroupHead`s — **Your golf** and **Your seasons** — brand at rest, a heavier rule, real air above. New in CSDesign, with the rule written into its doc comment: *two on a page is a spine; four is a table of contents.*
- **"Post a round" removed.** A primary button two-thirds down a page about the past, competing with a ⊕ that is permanently on screen an inch below it.
- **"How it works" moved into ⚙ Card & settings** on both clients. It is reference material — the same rows the Pro reads and a brand-new golfer reads — and it was filed under a page about your own record. On the web the click handler had to become a delegated listener: the sheet is built at open time, so the load-time `getElementById` would have bound to nothing.

**Nothing was deleted and no arithmetic moved** — every figure, tap target and receipt is where it was. This is order and naming.

**CONFLICT:** none. D93 split the relationship three ways deliberately (list on You, requests on Home, search in the header) and the phone only ever built two of the three; this completes it.

### D178 · The pre-TestFlight sweep — a crash on the default path, and a preview that lied
*(2026-08-31. Owner: "what else can we ship before we push to app store connect". Four parallel auditors + adversarial verification; every item below re-verified by hand before it was fixed.)*

**THE BLOCKER: Tee off crashed on the app's most-tapped button.** `LiveRoundState.defaultTeams(count:)` returned a hardcoded `[[0,1],[2,3]]` for **every count that was not 2**, and `teeOff` read `s.teams[0]/[1]` into `players[...]` **unconditionally, before the per-game switch** — so a round with ONE player (the default: "Just score", only you selected, which `teeOffProblem` explicitly allows at `n >= 1`) or THREE (legal for skins) indexed past the end of the array. Play now → Tee off, changing nothing, hard-crashed the app.
- It survived because nobody had ever played that shape: prod `live_rounds` by player count is 1→1 (July, game `none`, predating the iOS live wave), 2→16, 4→7. Every human tester so far brought a partner. A solo TestFlight tester would have hit it on their first tap.
- Fixed at BOTH ends: `defaultTeams` is now in-range by construction for any count, and the call site filters through `players.indices.contains` — the same guard `LiveResult.swift:111` and `LiveCopy.swift:24` have always applied when reading that array. The tee-off site was the one reader that skipped it. `wolfOrder` got the same treatment.

**THE SECOND BLOCKER: the phone previewed points at 100% while the engine paid 95%.** D174 fixed exactly this on the web that morning and **no Swift was touched** — the header comment in `PostCard.swift` even asserted "the web does the same", which had stopped being true hours earlier. Measured, not asserted: every league in prod runs 95% (the wizard's default preset), and **71 of 289 real scored rounds would land in a different `cup_points()` band than the phone showed**, always over-promising. `PostCalc.pvi` is now the engine's own expression, rounding the WHOLE expression so the half-open band edges agree at the boundary, fed the league's `handicap_allowance` (already loaded on `Me.Membership`). A league-less round stays at 100%, which is correct. The "preview at 100%" caption is gone with it.

**`declare_round` had TWO overloads and both clients call the wrong one.** The 5-arg one validates tags and posts to the board; the 6-arg one — the `p_course_id` variant, which is what `index.html:18638` and `ScheduleService.swift` *always* send — did neither. So for as long as it has existed:
- **nothing posted to the board when a round was declared**, while the sheet's fine print promised "Posts to your leagues' boards" and the toast said "your group is named on the boards". D107 made the tee sheet the free front door and its whole point was silent.
- **the tag guard was missing** — no seven-tag cap and no "buddies and league mates" consent check on the only path anyone uses. Nothing was exposed (RLS covers the read either way) but a consent rule was unenforced.
Both restored; verified in a rolled-back prod transaction: 2 board posts written where there were 0, the sentence reads right, and tagging a stranger now raises *"You can tag buddies and league mates."* **The migration's self-check asserts BOTH overloads post and BOTH guard** — the drift was invisible for weeks precisely because one was right and nobody read the other.

**Six smaller ones, four of them mine from D176/D177:**
- **The Clubhouse's "Add golfers" was inert.** `ClubhouseView:65` emits `NavigationLink(value: HomeRoute.people)` and the Clubhouse stack declared only `ClubRoute` — SwiftUI logs "the link will not work" and the tap does nothing. On the league-less Clubhouse, which is exactly what a new tester lands on, four affordances and the last was dead.
- **D177's "Your seasons" head rendered over nothing** for a league-less golfer — all three children are conditional. A group head is structure; structure over an empty room is a bug, not a spine. Now gated on its children.
- **D177's empty-search line promised a link that wasn't there.** "The link below works for anyone" — but the invite link needs a league with a code, and the golfer most likely to search and find nobody is the one least likely to have one. The copy branches now.
- **D177's Accept didn't refresh the list it moved you into.** Two models, one screen: the request vanished, the toast said "Golf buddies ✓", and the Buddies section directly below still said "No buddies yet".
- **D177's guide destroyed the sheet it opened from.** There is one `#sheet`, `openSheet` overwrites it with no stack. On the You *page* there was nothing to clobber; inside Card & settings there is. The way back **rebuilds** the host via `openProfileHub()` rather than restoring its innerHTML — every control in that sheet is wired in JS after `openSheet`, so pasted HTML would come back as a photograph of a sheet with every control dead.
- **The web's floor rung could never fire.** `league_pulse` returns no `member_id` (it returns `is_me`), so `find(r => r.member_id === CS.member?.id)` was always null and the two clients disagreed about whether you were about to miss a floor.
- **The web's clash was read once at boot.** You could post the very round the card asked for and read "Post a round" again on landing. Every path that changes the answer now re-reads it.

**Two more, honestly scoped:**
- **The Live Activity never went stale.** `staleDate: nil` on both request and update, every update is main-actor app code, and no cron job reaps `live_rounds` — while abandoning is the NORM, 20 abandoned to 4 final in prod. A forgotten round asserted HOLE 4 / THRU 3 with full confidence until the app was reopened. 45 minutes now: three holes at a normal pace, long enough that a slow group never sees it.
- **The Dynamic Island printed the tail of a sentence.** It kept the last two words of any status over 12 characters — the worst ten characters in a leaderboard string. "NO SKINS CLAIMED YET", the state of every skins round until the first skin falls, rendered as **"CLAIMED YET"**. `LiveCopy.compactStatus` authors a compact form instead; the widget keeps a `thru/holes` floor for activities started by older builds.

**Deliberately NOT in this build:** reaction bars on moments and settlement cards — 130 of 356 prod posts (37%) are unreactable, including every settlement card, but it is pre-existing, a few hours across two clients, and belongs with the next binary rather than delaying this one.

**CONFLICT:** none. This is defect repair; the only judgement call is the 45-minute stale window, which is stated in the code with its reasoning.

### D179 · The two calls before TestFlight — a warned lock, and a badge that means unseen
*(2026-08-31. Owner ruled both from rendered options: "warn, then let them" on the join code; "unseen — build seen_at" on the badge. The badge ruling went AGAINST my recommendation, which was to keep "unanswered" and fix the doc; the owner's reading is the one built.)*

**1 · A first tee of today makes the join code dead at lock, and nothing said so.**
- D161's window is `_join_gate`'s `if v_today < v_starts then return` — **strictly less than.** `lock_league` takes `coalesce(p_starts_on, current_date)` as given. So a first tee of *today* kills the code the instant lock completes; a date in the past kills it and makes the season retroactively underway.
- **The default was never the problem**: `defaultStart()` is the next upcoming Saturday and skips today even when today IS Saturday. The exposure is the picker — a bare `<input type="date">` with no `min`, under a label reading *"First tee — Pick any day."*
- **Backdating is kept on purpose.** A group three weeks into a season they are already playing on paper wants those weeks to count; bounding the picker would take that from them to prevent a mistake the default already prevents. The review states the consequence instead, and names the way out in the same breath — *"You'll add golfers yourself from the Clubhouse — the Pro's door stays open to the halfway turn"* — because a warning that only takes something away is a scold.
- Fires only when the chosen date is today or earlier. Web only: the phone does not lock leagues (IOS-007 — the desk owns authoring).

**2 · The badge means UNSEEN now, and the SQL finally matches the document.**
- `actionable_count_of` counted pending friendships + invites + open live rounds with **no notion of having looked**, so the number only moved when you ACTED. `docs/ios/push-contract.md` §4 has said *"Seeing the list clears it — acting is not required"* for three months, and **three call sites quote that line in their comments.** The SQL said "unanswered", the contract said "unseen", and nobody could tell because prod holds exactly **one push-registered device**.
- Built the contract's version: `profiles.actionable_seen_at`, consulted by `actionable_count_of`; `mark_actionable_seen()` returns the count AFTER marking, so the phone can never paint a number the server has already superseded.
- **ONE timestamp, not three.** The badge is one number over three sources and the contract's own clause is coarse the same way ("Requests, Invites, or the live round"). Three columns would let the number disagree with itself.
- **An empty list was not seen — it was absent.** `BuddyRequests` and `InvitesBanner` mark only when they render rows; otherwise they merely recount. Marking on an empty render would silence an invite sitting on another surface. Opening the live round marks; closing it recounts.
- The `profiles` column seal bit again in advance: `actionable_seen_at` ships with its own `grant select` in the same migration, because a column added without one fails 42501 with a message that never names the column — weeks later, on boot.
- The migration's self-check is **behavioural, not structural**: it finds a real pending friendship, proves the count is non-zero before the look and zero after, then inserts a request dated one second later and proves the badge comes back. All verified against prod and rolled back.
- The doc keeps its sentence and gains a dated note saying it was aspirational until today — the claim was worth nothing until something failed on it (CLAUDE.md's own lesson about assertions in prose).

**Recorded because I was overruled and the reasoning matters:** I argued for "unanswered" — that a friend request is an open loop with a person on the other end, and Cup Season's whole posture is that these things matter. The owner's counter is the stronger one: a badge you cannot clear by looking is one people learn to ignore, and an ignored badge misses the next real thing. The open loop does not vanish — the request is still a row with two buttons on Home and on the buddies screen. Only the icon nag stands down.

**CONFLICT:** none. D104 §4 wrote the contract; this is the first time the database has obeyed it.

### D180 · The roster has a door, and the Pro holds the handle — superseding D179's warning
*(2026-08-31. Owner, on the warning I had just shipped: "This is confusing and against our voice, what is the real issue? ... all sounds band aid solution." Then: "or do we add a manual close league". They were right on both counts.)*

**THE EVIDENCE, measured before it was theorised: five of the seven locked leagues in production were born with a DEAD join code.** *Fellas* locked 2026-07-20 with a first tee of 2026-07-20 — **its code has never worked once.** Sunset Match, Fairway Society, Ridgeline Cup and Sandbox the same. This was never an edge case to warn about; it was the majority case.

**The real issue:** D161 wrote the window as `[lock, first tee)` on the assumption that lock precedes first tee, and never handled `lock >= first tee`. The lock screen says *"Lock opens the invite link"* — for those five, **lock closed it.** The app handed the Pro a link and invalidated it in the same action.

**Why D179's warning was the wrong instrument** (and is deleted in the same commit): it explained an incoherence instead of removing it, and it made the app argue with the Pro about a choice the app had made badly. *"You'll add golfers yourself from the Clubhouse"* is the app handing back its own job. The Cup Season Test asks whether a line has quiet confidence; a warning that scolds you for using a date picker as labelled does not.

**The second half, which nobody had named until the owner asked for a manual close: THERE WAS NO WAY TO CLOSE A CODE.** No rotate, no close, nothing in the schema. A league that filled on day one with a first tee a month out had a live link for a month, screenshots and all, and its Pro could do nothing. So a manual close was never an *alternative* to the fix — it was the missing control, and the floor is its backstop.

**Built — the door:**
- **opens** at lock · **closes** when the Pro closes it, or at first tee if they never do · **floor**: a league locked ON OR AFTER first tee gets a week regardless, so a link is never born dead.
- The floor is a backstop, not a rule anyone learns: it exists only so *"lock opens the invite link"* is true in every case. It does **not** widen the window for a league locked before first tee — that is D161's ruling, untouched.
- `close_roster(p_league, p_open)` is commissioner-gated and posts to the board both ways: the roster is one of the season's terms (D112's covenant), so changing it is not a private setting.
- `RosterDoor.of()` on the phone and `rosterDoor()` on the web read **the same three facts `_join_gate` reads** — the Pro's close, the lock time, first tee — so the screen and the server cannot say different things.
- The Pro's close is armed (*"Sure? The link stops working"*) because it turns off a link they may already have texted to people. Recoverable, but not a stray tap.

**NAMING, deliberately against the owner's own suggestion of "Tee it up".** The season still starts on `seasons.starts_on`, which drives week numbers, clash windows, month closes and the Cup Final trigger (`ends_on − 27`). A button called *Tee it up* that closed a roster would repeat **the exact two-concepts-one-date conflation that caused this bug.** It is called **"Roster's set"**, and the pane says *ROSTER OPEN · 5 IN*. (The bigger idea — that tee-it-up should also *start the season*, removing the date picker for new leagues — is real and worth its own decision; it reworks the scoring spine and removes backdating, so it must not ride along here.)

**The lock screen now states a fact instead of a warning**, in every case, which it never did before — not even the normal one: *"Lock opens the invite link. It works until first tee — Sat Sep 6. You can close the roster yourself once everyone's in. Four to tee off."* The old line promised *"anyone can also join later with the league code"*, which D161 stopped; it had been wrong since D161 shipped.

**Verified against prod, rolled back — five behaviours, not assertions:** a league locked on its own first tee now admits a code join; eight days later it does not; the Pro's close refuses a code join with the right sentence; the Pro still gets through their own closed roster; and the refusal text is checked, not assumed. Seven client-side assertions mirror them (`RosterDoorTests`) including the Fellas shape by name.

**CONFLICT:** amends D161 (the window gains a floor and a manual close; its first-tee rule is otherwise intact) and **supersedes D179's first half** — the lock warning is deleted. D179's badge ruling is untouched.

### D181 · The board's silent half learns to talk, and the push chain stops eating its own testers
*(2026-08-31. Owner: "build 1 and 2" — the reaction gap D178 deferred, and the buildable half of the TestFlight push gate.)*

**1 · 130 of 356 posts had no way to say anything back.** Measured in prod, not assumed: `posts` by kind is round 222 · moment 85 · system 45 · chat 4. Reactions were gated on `kind === 'chat' || kind === 'round'` on both clients (`index.html`'s feed builder attached `post_id` to those two only; `BoardItem.social` said the same in Swift), so **every moment and every settlement card was unreactable** — the barrier broken, the lead change, the skins ledger, the month close. The artifact the pricing plan leans on hardest for word of mouth was the one nobody could answer.
- The database was already willing: `post_kudos`'s `kudos_all` policy checks `is_league_member(p.league_id)` on the post, with a WITH CHECK of `my_member_id(p.league_id)`. Any post in your league was always reactable. **No migration — this was two client gates, nothing else.**
- Moments and settlements **react but do not thread**, like chat. They are events, not conversations; the round post remains the place a thread belongs.
- **The Pro's announcement stays out, deliberately.** It is a notice, not a story.
- **The structural rule, which is the whole risk:** a settled-game row is a `role="button"` whose delegated handler reads `e.target.closest('[data-card]')` (D92). A chip rendered *inside* it would open the scorecard on every reaction. The web wraps the pair in `.sysgrp` so the bar is a SIBLING; the phone does the same with a `VStack` outside the `Button`. Both are asserted, not eyeballed: `app-tests.js` checks `querySelector('.social').closest('[data-card]') === null` and that the door still opens; the click was also driven headless — chip tap = 0 opens, row tap = 1.
- One producer per row shape on each client (`momRowHtml`, `sysRowHtml` with an optional wiring index) for the same reason `sysRowHtml` was one already: an affordance must never appear on one board surface and not the other. Home and the demo diorama pass no index and draw the bare row, so the diorama still never writes.

**2 · The push sender deleted the tokens it misrouted.** `BadDeviceToken` was treated as a death sentence alongside `410 Unregistered` — but APNs returns exactly that reason for **a perfectly good token posted to the wrong environment**. So a routing mistake did not merely fail to deliver: it **unregistered the tester**, permanently, until they happened to relaunch the app. With one push-registered device in all of prod, this had never once been exercised.
- **Only `410` / `Unregistered` prunes now.** `BadDeviceToken` retries the *other* APNs host; if that host takes it, the send counts, the `device_tokens.platform` is corrected, and the log says `MISROUTED`. Refused by both hosts = genuinely malformed, and only then is it dropped. 403/429/5xx never touch the row.
- **`APNS_SANDBOX` no longer wins globally.** It now decides only rows that carry no usable platform (its actual purpose — the pre-`20260828010000` rows). A row that says which environment it came from is believed over the env var. One forgotten secret used to send every TestFlight token to the sandbox host, and the runbook's gate 6 was the only thing standing between us and that.

**3 · The phone could hold a token nobody ever asked for.** `PushService.requestAppleToken()` awaited a continuation with **no timeout** (APNs can simply never call back) and **overwrote a pending one** if a second ask arrived — a leaked continuation, which traps in Debug. `syncOnLaunch` then ran `catch {}` around the registration RPC, which is precisely the runbook's *"permission granted, no token, nothing ever arrives"*: the toggle reads ON off a local `UserDefaults` key while the server has never heard of the device. Now: one ask at a time, a 10s ceiling with a generation guard so a late timeout can never answer the next ask, two attempts at the RPC, and `unconfirmed` — surfaced in Settings in gold — when the server still has not confirmed. **The switch is no longer allowed to imply a row that isn't there.**

**Verified:** 363 Kit tests pass (one added for the reaction gate), the app builds clean with no new warnings, `app-tests.js` runs 35/35 headless against a local serve, preflight is 0/0, and the console on a clean signed-out boot carries only the GoTrue lock-deprecation warning.

**CONFLICT:** none. Item 1 completes D178's stated deferral; items 2 and 3 are defect repair on a path D104 specified and nothing had ever exercised.

### D182 ⚑ · PROPOSED — the round that stops at eleven
*(2026-08-31. Found the hard way: the owner played Raven Silver, entered ten holes, ran out of daylight and walked. The round does not exist.)*

- **Current mechanic:** `finish_live_round` accepts exactly two card shapes — 18 complete holes, or holes 1–9 with **nothing** scored after them. Anything else is `skipped · incomplete card`: no `rounds` row, no board post, nothing to the season. The finish sheet warns first ("missing holes 11, 12…"), then finalizes anyway; `status` goes `final`, a second call returns `already_final`, and **no RPC turns a finished-but-unposted card into a round.** The copy on that sheet reads *"A partial card is skipped, not lost"* — the strokes do survive in `live_scores`, in a table with no door to them.
- **Problem:** ten holes is one hole past the cutoff, the cruelest possible shape. Prod evidence: live round `a5429048` holds holes 1–10, 46 strokes, inside a live season window at 95% — a real round that scored nothing. **And the nine-hole escape hatch is dead anyway:** the engine's guard demands a `nine_rating`, `api_course_tees` has no such column, and Raven's snapshot carries `null` — so even a clean nine at that course would have been skipped for "no 9-hole rating". Prod holds **1 nine-hole round out of 211**.
- **What the sport says:** WHS accepts 10–17 holes as an 18-hole score with **net par** on the holes not played, and 7–9 as a nine. That would have posted this card as an 83 gross-equivalent (46 + 37 net par), differential ≈ 10.9.
- **The competition objection, which is ours alone:** net par on the remainder means **walking off after a hot ten banks it** — you keep whatever you were up and can never give it back. Fine for a handicap, a live exploit for cup points.
- **Owner's leaning (2026-08-31): the nine-hole rescue** — if the first nine are complete, post the nine and drop the extras — *"maybe should depend on league settings?"*
- **The answer to that question is that the dial already exists and already works.** `league_settings.nine_hole_allowed` (baseline `:1085`, DEFAULT true) is read by `v_rounds_ranked` (`:1373`) and gates whether a nine scores for the league at all. **It has no UI on either client** — no Pro has ever seen it. And `score_round` **already** falls back to `p_rating/2` when the nine rating is missing, and already halves the points. So the engine is more capable than the finish path that feeds it: the block is one over-strict guard, not a missing mechanic.
- **Recommendation:** (1) relax `finish_live_round` — a complete front nine posts as a nine regardless of what was scored after it, and the missing `nine_rating` stops being a hard stop (fall through to the engine's own halved rating, labelled as derived on the card, per §16). (2) Give `nine_hole_allowed` a door in the wizard and the League pane with a plain sentence. (3) Make "not lost" true: a finished round with an unposted card keeps a **Post this card** action, so a walk-off is recoverable instead of final. (4) Say what is being dropped at finish — *"Posting your front nine; holes 10 and 11 won't count toward it"* — rather than discarding strokes silently.
- **Principle served:** everything shows its work (§16); the product should not be stricter than the sport without saying why.
- **Tradeoffs:** a golfer who plays 14 and stops still only banks nine. That is the cost of the simplest honest rule, and it is the owner's call to accept it.
- **NOT built.** Logged before anything is written (rule 1). The owner has ruled the shape; the open piece is whether the league dial gets exposed in this pass or the next.

### D183 · Free until a thousand golfers — the price question is parked, not answered
*(2026-08-31. Owner, ending a pricing session: "I think we currently scratch price model stuff. We go free until we hit 1000 users then we reevaluate.")*

**Current:** D101's league-year pass ($59 ≤9 · $89 10–13 · $109 14+, first year free, paid by the Pro out of the pot) is BUILT on the phone behind `app_flags.pricing.visible = false`, gated further by D135's eight-item evidence checklist. The web has no pricing surface at all — but it does ship a **Pro Shop teaser** promising four things that do not exist ("Custom rules, every dial unlocked · Live draft night · Trades & waiver wire · Multi-season history", `index.html:3795–3811`), under a banner reading "COMING AT LAUNCH · THE PILOT RIDES FREE" — both nouns retired by D132 and neither retirement built.

**Problem, measured:** the book is **40 profiles, 30 fully onboarded, 23 who have posted a round, 7 locked leagues, 1 completed season.** Every candidate model — per-league year, per-Pro year, per-seat, a percentage of the pot — is a bet on behaviour that a sample this size cannot show. The session that produced this entry moved through all four in an hour and the deciding facts were always the same two: nobody has run a second season, and nobody has been asked for money. Two further findings made the parking easy rather than reluctant:
- **Every real league sits in the bottom band.** Rosters are 9, 8, 8, 6, 5, 2, 2. The $89 and $109 tiers price leagues that do not exist, so the three-band structure is three Stripe products doing the work of one.
- **The option with the best economics cannot ship now anyway.** A percentage of the pot scales with stakes where the pass never does ($2,650 of pot across seven leagues today, $1,900 already collected through `buy_ins`; 5% of a 12-man $500 league is $300 against a $109 pass) — but holding stakes for months is custody, D39 named it "money-transmission territory," and a rake on a real-money golf contest changes the answer D3 gave App Review, in writing, on a build that is in TestFlight right now.

**Decision: the product is FREE until 1,000 onboarded golfers, then the question reopens with real data.**

**The trigger is a number, not a feeling** (D135's own discipline, kept): **an onboarded golfer is a profile carrying BOTH a marker and a handle** — the live onboarding gate — excluding test accounts. **Today: 30 of 1,000.** It is shown on the founder desk beside the count who have actually posted a round (23), because a seeder that sets only `marker` would otherwise inflate it — the exact m001 trap CLAUDE.md records.

**What changes now (cleanup, no new mechanic):** the Pro Shop teaser is deleted rather than rewritten — D132 already killed the noun and this kills the promise; the two wizard (i) lines that sell an unlock ("Every individual dial unlocks with Pro Shop" `:3471`, "on the Pro Shop roadmap" `:3517`) go with it; the You plan row stops saying "FREE · PILOT / Nothing to pay during the pilot" and says something durable and true. **The App Store answer gets simpler and safer**: the app is free, there are no in-app purchases, nothing costs money — which makes `appstore-launch-kit.md`'s existing claim literally true and removes a review surface instead of adding one. The launch-kit FAQ line ("about $89 a year") and the reviewer note in `app-store-listing.md` are corrected in the same pass.

**What does NOT change:** the phone's three pricing cards stay built and dormant — they cost nothing at rest and are the fastest road back. `app_flags.pricing` keeps its bands as the record of D101's arithmetic. **D135's eight-item checklist survives as the quality bar**; only its trigger moves — the gate now reads "1,000 golfers AND the eight items," not "the eight items." And nothing about the free product changes: identity, the handicap index, rounds, receipts, buddies, the tee sheet and live scoring were always free and remain so.

**Principle served:** "charge after proven value" read literally (`gtm-year1.md` §11); D56's "the flag makes it a one-row change" — the flag is why this costs nothing to enact and nothing to reverse.

**Tradeoffs:** no revenue for at least a year, and probably longer. "Founding League — free forever" loses some of its scarcity while everything is free for everyone; the badge becomes a thank-you rather than a deal, and D102's tags carry that weight instead. And a year of free is a year of teaching people the product is free — at 1,000 the decision will be harder to reverse than it is to make today. That is the accepted cost.

**CONFLICT (named):** supersedes **D135's trigger** (which was the eight items alone) and **parks D101/D56's numbers** — parked as a record, not retired, and reopened by the counter above. D39's ledger language and its open door to a pot service stand untouched; the pot-service opportunity is flagged below rather than lost.

### D184 ⚑ · PARKED — the pot as the business, when the company can hold money
*(2026-08-31, from the same session. Logged so the reasoning survives D183's parking.)*
- **The observation:** the pass has a ceiling of $109 no matter how much a season matters to a crew; a percentage of the pot does not. Measured today: **$2,650 of pot across seven locked leagues, $1,900 of it already marked collected in `buy_ins`** — real money moving between friends, already tracked by the app, with the app taking nothing. A 12-man league at a $500 buy-in is a $6,000 pot; 5% is $300 from one league against a $109 pass.
- **The second observation, which is the interesting one:** the owner's objection to the Pro fronting the fee ("why am I fronting this?") has no good answer under any subscription shape — per-seat billing turns one sale into N checkouts, N renewals, N churn events, and creates a group-integrity failure with no acceptable resolution when two of nine do not pay. It has a *trivial* answer once the pot is held: the golfer pays $82, $75 goes to the pot, $7 is the app, at the moment they were already paying, with no invoice and no renewal. **Per-golfer pricing and holding the pot are the same decision.**
- **Why parked, not scheduled:** custody. Holding stakes for months and distributing to winners is money transmission, state by state; D39 already named it. The proven path exists (LeagueSafe has held fantasy pots for years) and Stripe Connect with the league as merchant of record is the likely shape, but it is a compliance project with counsel before code, not a sprint. And it cannot go in front of App Review while D3's "no gambling flags of any kind" is the standing answer on a build in TestFlight.
- **The open consequence to decide later:** if the long-run model is a share of the pot, a $0-buy-in league pays nothing forever. One already exists in prod. That is either fine (it is the funnel and it costs almost nothing) or it is the hole in the model — and it means a pass of some kind survives as the floor for leagues that play for nothing.
- **Not built, not scheduled.** Reopens with D183's counter.

### D185 · The first screen a stranger sees, and the funnel that was never recording
*(2026-08-31, ahead of the Broken Tee Society post. Owner: "what do we need before broken tee." Four defects, all on the path a person who has never heard of Cup Season walks in their first two minutes.)*

**1 · Home told a golfer with no league that their squad would be penalised.** `renderPulse`'s hero branch printed the monthly-floor rule on `state.floor > 0 && !state.demo` and **never on `CS.league`** — and `state.floor` holds the wizard's default of 2 whether or not a league exists. So the first screen after signup read *"Post 2 rounds a month… from the second miss your squad loses 5 points for every round you're short"* — three lines under a tile reading **LEAGUE · None yet**. Bylaw copy, with a penalty, for a squad the reader does not have. Measured live on a fresh account before the fix: `CS.league: null`, `state.floor: 2`, line printed.

**2 · `.league-only` was a class with no CSS rule.** Twenty-two elements carried it and **nothing anywhere hid one.** The Clubhouse escaped only because a separate rule (`body.noleague #view-hub > *:not(#hubLeagueless)`) hides that whole view; the You page has no such parent, so a league-less golfer read a **"Your seasons · This season · your league"** block over four em-dashes. The head carries the class now too — D178 recorded gating it on its children, but the children's class was inert, so the head and the dashes shipped together.

**3 · The orientation's exit line named a door that D177 removed.** *"Reopen this any time from You › How it works"* — the guide moved into ⚙ Card & settings months ago, and the only "How it works" label left in the file is inside that sheet. The one screen whose job is teaching the map misdirected you on the way out.

**4 · THE FUNNEL HAS NEVER RECORDED A SIGNUP.** `growthEvent()` opened with `if(state.demo || !window.sb) return`. **`state.demo` starts `true`** — the diorama behind the door — and is cleared only in `showWelcome()` and `resetToBlank()`, both of which run **after** the golfer card is saved and **after** boot consumes `?join=` / `?claim=`. Every `profile_created` and every `link_opened` therefore returned at that first line, always. `growth_events` held, all-time: `first_round_posted` ×7 and one `artifact_shared` — the only nodes that fire late enough to survive. Thirty onboarded golfers, not one recorded, and the function swallows its own errors (`.then(null, ()=>{})`) so nothing ever complained.
- **The guard is deleted, not narrowed.** `log_growth_event` was built fail-closed and is the real gate: a signed-out caller may log only a `link_opened` whose token resolves to a real league, claim or share; a made-up token logs nothing and returns the same void. The diorama cannot fabricate an event the server would accept, so the client guard bought nothing and cost the entire top of the funnel.
- **Proven end to end against prod, not asserted:** a signed-out visitor opened a real invite link on the fixed build with `state.demo` still `true` — the exact condition that used to swallow it — and `growth_events` took `link_opened · join · SAND2LJ1`, attributed to the right league. (`profile_created` rides the identical guard; it is covered by the same one-line fix but was not re-tested, because testing it means minting another production account.)

**Why these four together:** the next arrivals are strangers from a golf forum, not friends of a Pro. Every one of them lands on a league-less Home and a league-less You, and the whole point of the wave is the data — which was going to be zero.

**Verified:** preflight 0/0; `app-tests.js` 42/42 headless, including **seven new regressions** — that `.league-only` hides at all, that the seasons head hides with its children, that the floor line is silent without a league *and still speaks inside one*, and that a breadcrumb survives the diorama guard with the node intact. Clean signed-out boot carries only the GoTrue lock-deprecation warning.

**CONFLICT:** none. Defect repair. The phone is unaffected by 2–4 (its `Growth.log` never had a demo guard, and the other two are web markup); iOS keeps its own gap — no orientation and no crew step — which is P2 and named in the pre-launch list, not here.

### D186 · The card travels — a fourth share kind, a public golfer page, and the invite that has a face
*(2026-09-01, from the IOS-028 audit. Owner ruled all three calls in one line: "B, A, A. Build it!" Written before any code, per rule 1.)*

- **Current mechanic.** `create_share` mints a revocable token for exactly three artifacts — `('round','settlement','recap')` — and `share_info` is the one anon window onto them. The **Tour Card is not one of them.** It is the app's only object shaped like a thing people post (a face, a gold number, engraved trophies, a form row, in the fixed dark identity D30 gives every artifact) and it cannot leave the app. Separately, the only invite link in the product is a **league** join code: `PeopleScreen.swift:104` states the gap in a comment — *"A buddy-invite link is a different mechanic and would need a decision, not a tidy"* — so a league-less golfer has no way to bring anyone at all.
- **Problem, measured.** 39 profiles, **1 with a photo**. 211 posted rounds, **7 shares ever minted**. 22 buddy links of which **10 are still pending**. The artifacts are finished and the occasions are missing: every round share lives in a sheet that closes after thirty seconds, and the identity object has no door out of the app in any direction. The next arrivals are strangers from a golf forum, every one of them league-less — the exact golfer for whom the product currently has no invite.
- **Recommendation, as ruled.**
  1. **A fourth kind, `card`.** `create_share('card', <your own profile>)`. You may share only your OWN card, and only when `discoverable <> 'nobody'` — the same valve that already governs whether a stranger can open your Tour Card at all (`tour_card`, `20260726190000`). Revocable by the same `revoke_share`.
  2. **The number travels** (Call 2 · A). The public card carries `index_current`. It is already visible to any league-mate and to anyone at `discoverable = 'everyone'`; withholding it on the shared page would cost the link preview its only sentence — *"Jerecho Fischbeck plays to 12.4"* becomes *"…is on Cup Season"*, which is the generic headline the edge rewrite (D77/D78) exists to eliminate. `discoverable = 'friends'` shares the card **without** the number to a viewer who is not a buddy.
  3. **The card is the invite** (Call 3 · A). The public page grows one button, "Add me on Cup Season". A new authenticated RPC `share_buddy(p_token)` resolves the token server-side and runs the existing `friend_request` logic — so the profile UUID never leaves the server for an anon reader, and no second token surface, no second revoke path, and **no ninth anon endpoint** is created. Rejected: a dedicated `?buddy=` token, which is a page with nothing to look at and a permanent D37 audit obligation.
- **Principle served.** §16, everything shows its work — a shared card names the rounds behind the number. Product-vision principle 5 (the app is alive outside itself): the artifact that leaves is the one a golfer actually wants to be seen holding. And the covenant of D57 is unchanged: the golfer publishes, the app never does.
- **Benefit.** The identity object becomes shareable; the league-less golfer gets an invite; the invite carries a face and a number instead of an eight-character code; one artifact serves both "look at my card" and "add me", which is the shape every product that grows this way uses.
- **Tradeoffs.** A handicap index on the open web is a handicap index on the open web — the mitigation is that it is opt-in twice (a share you mint, on a `discoverable` you set), revocable, and behind an unguessable token that is never enumerable. `share_info` grows a fourth branch, so the fail-closed rule now has one more path to hold: an unknown, revoked, deleted or `nobody` card returns the same `null` as every other dead token. The growth funnel's `kind` domain gains `card`, which touches `growth_events`, `profiles.came_via_kind` and `log_growth_event` together.
- **CONFLICT:** none. Nothing about the competition model moves — no points, index, pot or settlement path is touched. The Call 1 half of the same ruling (the ⚙ opens Settings; the card editor is reached by touching the card; the face goes to 88pt and prompts for a photo) is a **surface**, not a mechanic, and is logged as IOS-029 rather than here.

### D187 · The scan is not broken — it is unchosen, and we were blind to which
*(2026-09-01, IOS-028 E9. The audit found `scan_claims` = 0 all time and recommended finding out why before more is invested in the claim funnel. This is the answer.)*

- **Current mechanic.** D36 built the scorecard scan: the `scan` Edge Function reads a photo with vision, the D34 grid returns as the confirm surface, and every partner row on the card mints a `/?claim=` link. IOS-004 calls the claim link "the product's strongest acquisition path".
- **What the evidence actually says.** Every link in the chain works, and nobody walks it:
  - `app_flags.scan` is `{enabled: true, daily_per_user: 5, monthly_global: 400}` — **the kill switch is not tripped and no cap is near**.
  - The button renders. Driven headless on the built client with a real-shaped session: `#postScanBtn` computes to `display: block`, 156×35, **602px down an 844px viewport — above the fold**, on a composer whose full scroll length is 1342px.
  - The Edge Function works: `scan_usage` holds **4 rows, 4 ok, 0 failed**, all on **2026-07-18** — the day it shipped.
  - Both clients extract partner rows and both raise a partners sheet (`scanPartnersSheet` / `PostPartnersSheet`), and the function's normalizer emits the `holes_read` / `total` the filters read.
  - **`post_open` = 92 since the scan shipped. `scan_usage` since the scan shipped = 0.** Ninety-two composer opens, zero invocations, six weeks.
- **So `scan_claims = 0` is not a broken mint.** It is downstream of a door nobody has opened since build day. The claim loop cannot produce a row until somebody scans a multi-player card, and nobody has scanned anything.
- **Problem 1 — we cannot say WHY, and that is our fault.** The only scan breadcrumbs are `scan_post` (fires after a completed post; 1 row, 2026-07-18) and `scan_claim_minted` (0 rows). Nothing records the button being shown, tapped, read, or abandoned. "Nobody taps it" and "everyone abandons the confirm grid" are indistinguishable in the data — the exact shape of D185's funnel failure, one feature over.
- **Problem 2 — a scanned round leaves no trace.** The composer hardcodes `source: 'quick'` on every post (`index.html:7183`), so a round that came from a scan is indistinguishable from two typed numbers. `rounds` holds **206 `quick` + 5 `live` and 0 from a scan, and none ever can**. `rounds_source_check` was widened to `('quick','live','scan_claim')` for the *claim* path; the poster's own scanned round was never given a value.
- **Recommendation — instrument first, judge second.** (1) `source = 'scan'` when the post came from a read, so the durable record can measure it. (2) Three breadcrumbs at the door — `scan_tap`, `scan_read` (with the player count), `scan_unavailable` — so the gap to `scan_post` becomes the abandonment rate. (3) Name the value where the decision is made: the button says "Scan the card", which describes the mechanism, and the only reason to prefer it over two boxes — *it posts everyone on the card* — appears nowhere near it.
- **NOT recommended yet: promoting the scan.** Offering it after a live round with guests, or from the board, is a positioning change, and the honest position is that we do not know whether the door is unattractive or the confirm step is too long. The three breadcrumbs answer that in weeks, and the answer should decide it.
- **Principle served.** Everything shows its work (§16) — applied to ourselves. A feature we cannot measure is a feature we cannot argue about.
- **Tradeoffs.** `source = 'scan'` needs the check constraint widened, and every historical scanned round (there are none) stays `quick`. The breadcrumbs are `client_events` rows, which RLS lets only `authenticated` write — fine here, since the scan is signed-in by construction.
- **CONFLICT:** none. No competition rule moves; `source` is not read by `v_rounds_ranked` for scoring, only by the `<> 'sim'` filters in `tour_card` / `share_info`, which `'scan'` passes exactly as `'quick'` does.

### D188 · The share link opens the app, and the page finally knows the app exists
*(2026-09-01, IOS-028 E8. Held back from the D186 pass on purpose — both halves were blocked on something real, and this is those blockers cleared.)*

- **Current mechanic.** `?share=` is the one public window onto an artifact (D57): four kinds now, all rendered by a single web page. The AASA claimed `?claim=` and `?join=` only, so **every shared round, settlement, recap and card opened in Safari — including for someone who has the app installed.** And no page in the product had ever mentioned that an iPhone app exists: `grep -r "apps.apple.com"` over the whole repo returned nothing.
- **Blocker 1, now cleared: the phone could not draw a shared card.** Claiming `?share=` without a renderer would have opened the app to **Home** from a card link — strictly worse than Safari, which at least shows the card and takes the tap. `SharedCardSheet` renders it now, in the SAME object the owner sees (`CredentialCard`, the fixed dark face, D30), reading `share_info` — which is anon, so a **signed-out** phone still sees the card and only needs an account to press the button.
- **The trap that came with it, and the fix.** The AASA cannot inspect a token, so claiming `?share=` claims **all four kinds**. A round, settlement or recap would have parsed as "not a card" and been shown as **dead** — a regression on three link types that work today. `SharedCardRepository.load` therefore answers a three-way enum: `.card` renders natively, `.web` hands the token to its own good web page **in-app** (`SFSafariViewController`, never `UIApplication.open` — this app claims the link, so opening it would route straight back and loop), and `.dead` is the one answer every unknown, revoked, deleted or since-hidden token shares (D57).
- **Blocker 2, now cleared: there was nowhere to point a store link.** The share page is **anon**, and `app_flags` is readable only by `authenticated` (policy `flags_read`), so the URL could not come from a table read there. `door_flags()` — already the anon door's flag endpoint and already one of the twelve — grows an `app_store_url` key instead of the anon surface growing a thirteenth. It is **null until the owner sets it**, and a blank string reads as null, so a half-configured flag can never render a dead App Store link into somebody's group thread. The CTA also renders **only on iOS**; a store link on Android or a desktop is noise.
- **Recommendation.** Ship both halves; leave `app_store_url` unset until the listing is live. The Universal Link is safe the moment the build with `SharedCardSheet` is on a phone — and harmless before then, because a phone without the app follows the link to the web exactly as it does today.
- **Principle served.** The artifact is the invitation (product-vision principle 5): a link that opens the real thing, natively, for someone who already chose the app — and that tells a stranger where to get it.
- **Tradeoffs.** Three of the four kinds still render on the web, in an in-app browser rather than natively — the honest position, since each needs its own renderer and only the card was the identity object worth building first. `?share=` is now an app-claimed link, so a user who wants the web page must long-press → Open in Safari; that is standard Universal Link behaviour and the in-app browser covers the case that matters.
- **CONFLICT:** none. No competition rule moves. IOS-004's "the public claim / join / share pages stay web" still holds for the pages themselves — what changed is who gets to render the CARD, and the web page is still the thing every non-app reader sees.
