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

### D-NN · The Climb's visual finish — presence, voice, motion, and real semantics
*(placeholder — coordinator assigns the number at merge. Level 5 (UI) on top of
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
