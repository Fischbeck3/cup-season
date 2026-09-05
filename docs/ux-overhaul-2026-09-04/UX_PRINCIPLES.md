# Cup Season — UX principles for the overhaul

*Written 2026-09-05 against `INFORMATION_ARCHITECTURE.md`. Repo at tip `3bba87e`.*

## 0 · How to read this

Every rule below is written as a **triple**:

- **This means** — the positive obligation. What a screen must do to satisfy the rule.
- **This forbids** — the specific thing that is now a defect. Written so a reviewer can point at it.
- **How we check** — a test somebody can actually run: a preflight grep, a walk, a query, a screenshot at AX3. **A principle with no check is a slogan**, and this document has none of those.

Three tiers, and they do not negotiate with each other:

| Tier | What it is | What happens on a conflict |
|---|---|---|
| **The wall** (§12) | Laws L-01…L-45, from vision, brand canon, spec and hard engineering rules | A design that violates one is **disqualified**. There is no argument that survives it |
| **The principles** (§1–§11) | This document | A conflict between two principles is resolved by the lower number, and the resolution is written into the decision entry |
| **The rulings** | The decision log, D1…D250 | A ruling may be superseded by a higher-level entry with a named CONFLICT line (P-02, P-03) |

**The one sentence the whole document serves**, from the brief: *"Don't make me understand Cup Season. Make me want to use Cup Season."*

---

## 1 · The brief's principles

### P-1 · Within seconds, five questions are answered without terminology

The brief's acceptance test: within seconds of opening, a first-time user knows **what is happening · why it matters to me · what I can do right now · who I am competing with · what happens next** — without understanding league vs season, scoring terms, commissioner mechanics, side-game or pot configuration.

- **This means** every state of Home answers Q1 and Q3 at **zero taps**, and Q2, Q4 and Q5 at **zero taps whenever the data exists**. The lead answers Q1; the ME strip answers Q2 and, through its season row, Q4 and Q5; the four doors answer Q3 unconditionally.
- **This forbids** any Home state whose top screenful requires a scroll to reach an action; any answer that depends on a golfer knowing what "league", "bylaws", "allowance", "counting cap", "participation floor", "structure", "preset", "seed", "duel" or "session" mean; and any state where the five questions are answered *only* inside a league.
- **How we check.** The five-question walk on all thirteen Home states (`INFORMATION_ARCHITECTURE.md` §4.5), counting taps and seconds from a cold open, on the App Review seed and on a leagueless seed. Plus the terminology lint (§7) reading 0.

### P-2 · Play before league

The smallest useful action is **Add my round** — course, score, done — and it works before anything else exists.

- **This means** the composer is reachable in one gesture from anywhere (⊕ long-press, any "Add a round" CTA, Home's first foot door), needs one number, and inherits everything it can from the last round at that course. A golfer with no buddies, no season and no index can complete it and get a real receipt.
- **This forbids** requiring a league, a season, an index, a GHIN, a buddy or a tee selection to post; asking for five fields where one number and one editable line will do; and any funnel step that must be completed *before* the first act rather than offered *after* it.
- **How we check.** A cold-account walk: install → door → card → composer → posted, counting taps and elapsed seconds, against the existing `post_submit` baseline (n=24, p50 39 s, p90 76 s). The number must go down.

### P-3 · The funnel is a sentence, not a card wall

Casual → competition → recurring competition happens at the one moment a golfer is provably engaged: three seconds after a good round.

- **This means** the post-round epilogue is a page with **exactly one ranked next act**, chosen by what is true (`INFORMATION_ARCHITECTURE.md` §5.4), and each rung names a person or a competition that exists.
- **This forbids** a grid of promotional tiles after a round; a next act that is the same sentence for every golfer; and **"make the next one count" appearing in more than one row** — it appears once, so it means one thing.
- **How we check.** Read the epilogue table: eight rows, eight distinct sentences, each with a named read and one door. Walk three of them on a seeded account.

### P-4 · Creation starts from intent, and configures progressively

An organiser says what they want to do; the app chooses the object.

- **This means** the intent sheet names **intents, never objects**, and each resolves to an engine object the golfer never hears named. Three questions in order — **Who? · When? · What's on it?** — then Start. Everything else is behind **More settings**, unchanged and complete.
- **This forbids** a menu of schema objects (the retired `EventPickerSheet` is the specimen: "Ryder LIVE · Bracket SOON · Major"); minting a database row before all three questions are answered; asking a name before there is anything to name; and a preset card that recites its dials (`WizardState.swift:68-72` is the live violation).
- **How we check.** After an abandoned wizard, `select count(*) from leagues where status='setup'` is unchanged. The preset lint (§7). A count of taps to a published season on the commissioner walk.

### P-5 · Home is never an empty dashboard, and never a dead end

- **This means** every Home state ends in a next move, including brand-new, no-buddies, between-seasons and read-failure. The four doors are **always present at the foot**.
- **This forbids** the empty-feed sentence doubling as the failure state (`HomeView.swift:283-288`); a spinner in content; and a state that renders a fact with no door.
- **How we check.** §6's rule, below.

### P-6 · Complexity is hidden, not deleted

- **This means** every dial that exists today still exists, one tap deeper. Every receipt survives. Every RPC survives. What is deleted is **vocabulary**, not capability.
- **This forbids** removing a dial to simplify a screen; replacing a receipt with a summary; and "simplifying" by making a mechanic unreachable rather than unnamed.
- **How we check.** A dial-by-dial inventory of the wizard's twelve settings before and after; a receipt-by-receipt inventory of every figure that taps through today.

### P-7 · The data model and the user's model are separated by a wall

- **This means** the backend keeps League → Season → Event → Match; the user holds **a round, a season, a moment, a golfer, my record** (`INFORMATION_ARCHITECTURE.md` §2), and every screen maps between them through a named producer.
- **This forbids** a schema noun on a user surface — and the mapping table in §2.2 is the list of what each user noun is allowed to be.
- **How we check.** The terminology lint (§7), extended with a schema-noun list.

---

## 2 · The vision's five, made testable

| # | The vision's words | This means | This forbids | How we check |
|---|---|---|---|---|
| **V-1** | **Golf First.** "The golfer is the product… never optimize for league management at the expense of making golfers excited to return." | ME leads for everyone, including the Pro. A Pro's pending action is one ranked item, never the identity of a screen | A hero addressed to a role; an administrative checklist where a standing belongs; a screen a member sees that is about somebody else's job | Open the Pro's Home and the member's Home on the same seeded season: the first block is the same object |
| **V-2** | **Low Friction Wins.** "Can the computer infer it instead?" | The composer inherits course, tee, rating, slope and date. The season's structure is derived from the roster. The marker and handle are defaulted. "What kind of golf do you play?" is inferred from the buddy graph, not asked | Any field the server could compute; any onboarding question whose only use is re-ordering a list; any "choose one of fourteen" with no default | Count the frames and the required fields in onboarding, before and after: eight surfaces → four frames, and two required choices → zero |
| **V-3** | **Real Golf.** "No simulations. No fake scoring. No fantasy players." | Empty states hold real doors and real facts, never fabricated content or faces. An assumed course rating is never invented to produce points | A demo diorama on any user path; a placeholder that reads as a value (`72.1` / `128` at `PostRoundScreen.swift:194-195`); a points figure computed from a rating nobody measured | Grep for the demo path on the phone (zero); read the composer's placeholders; confirm a no-rating round posts and earns **no** season points, and says so |
| **V-4** | **Memory > Statistics.** "Golfers don't remember 'I averaged 31.8 putts.'" | The story line sits **above** the table; each table row carries one clause of why; each record row opens a story page, not a dead table | A KPI strip; a table with no narrative above it; a career screen that is four counters | Look at the season page and the record: is the first thing a sentence with a subject? |
| **V-5** | **The App Should Feel Alive.** "Opening Cup Season should reveal something new." | Nine consecutive opens produce nine different true sentences, in a season and with none (§5's week-in-the-life) | Rotation, randomisation, or a countdown to a date that is not real, used to create the feeling of change | The week-in-the-life acceptance test, run on paper before a line is written and on a seed before Wave 1 ships |

---

## 3 · The audit's lessons, as rules

Nine things the audit and the persona walks proved, each now a rule with a check.

| # | Lesson (and its evidence) | The rule | How we check |
|---|---|---|---|
| **A-1** | Home led with `2nd of 2 — held` over a 40-word paragraph | **A bare standing can never lead.** (§5, the veto) | The lead's headline has a human subject or a first-person verb, in every state |
| **A-2** | The largest real cohort — 14 of 39 profiles, plus every member between seasons — has no rung below the league: no story home, no push, no reaction, no invite | **Every rail works without a season.** A round, a milestone, a reaction, a push and an invite must each function for a golfer in no league | Four probes on a leagueless seeded account: post a round → it has a story home; a buddy reacts; a buddy gets a push; a person link mints a buddy request |
| **A-3** | Six of six `setup` leagues in prod are a founder alone, because the wizard mints on a name | **Nothing is minted until the golfer has said what they want.** (P-4) | The abandoned-wizard query |
| **A-4** | `prev_rank` is a Sunday snapshot, so a Tuesday climb reads "held" | **A movement label carries its own clock, or it does not render.** | Grep for a bare `▲`/`▼`/`held` with no "since"; the epilogue's event-driven movement sentence |
| **A-5** | The rank-3 golfer is told a gap with no name; the person above them is unnamed | **A gap is always attached to a name.** | `next_up`/`next_down` present on every standing render at rank ≥ 3 |
| **A-6** | The same fact rendered three times on one screen (a buddy's personal best) | **One fact, one place** — enforced by the producer, not by per-screen judgement: the lead hands the deck a `suppress: Set<Fact>` | Render the persona-F state and count the occurrences of the milestone: exactly one |
| **A-7** | An in-app invite calls `respond_invite` directly, so a golfer accepts a $50 season without ever seeing the $50 | **Every join passes the covenant** — code, link, in-app invite, and $0 | Preflight 19 extended to the in-app path; a $0 join walk on both clients |
| **A-8** | `orientation_shown` 5, `orientation_done` 0 | **No screen teaches the tabs.** What must be taught is taught where it is needed | The orientation file is deleted |
| **A-9** | Two clients, no ruled reference, no per-law producer, no platform stamp | **One producer per law per client, one lint per law, one reference client.** | The lint suite; `platform` stamped centrally in `CSTelemetry`; the reference named in the log |

---

## 4 · The identity contract — kept whole

`IOS-003 §1` survives the overhaul intact. It is not a style; it is the reason two metals mean two things and a spine can carry state without a word.

**The metals.** Ember `#E8622C` = **LIVE** — the primary action, momentum, the ⊕, anything with a clock on it. Champagne gold `#D8B25A` = **EARNED** — a lead held, a trophy, the pot, a champion's name, a personal best, movement up.

- **This means** the 3.5-px spine on every dispatch card does all the state signalling: ember for closing, gold for earned, squad colour for squad-scoped, a mut hairline for quiet-and-true. The solo champion **finally gets gold**, because `champion_member_id` is decoded and unread (`Models.swift:50` vs `HomeView.swift:869,980`).
- **This forbids** gold on a button, a tab or a nav — that is a defect, not a taste call. Gold on a handicap index (a fact about you, not a thing you took off someone). Ember on anything with no clock. Swapping the two under any theme or look (L-28: a look may tint spines, washes, eyebrows and the ⊕ halo — never ground, ink, `pos`/`neg`, the heat ramp, the squads, gold's meaning, ceremonies or share cards).
- **How we check.** Preflight's palette purity check; a gold-audit screenshot pass on every new surface in both themes; a grep for gold tokens inside button and tab styles.

**The three type voices.** Serif = the story and the honor (**never on a control**). Mono = the record — labels, eyebrows, tabular numerals (**never prose**). Sans = the workhorse. No fourth family.

- **This means** the card grammar is exactly these three doing their three jobs: **mono dateline / serif headline / sans standfirst / one ember verb**. The gross-score entry box is a **control**, so it is sans, not serif.
- **This forbids** a serif control label, a mono paragraph, a fourth family, and anything below 11 pt at the default size.
- **How we check.** AX3 screenshots of the ME strip and the lead card (the two densest new objects); a font-role review of every new view.

**The motion.** One easing everywhere — the roll, `cubic-bezier(.16,.84,.36,1)`. Nothing bounces. Reduced motion rests on the frame. The Forge door plays once per device.

- **How we check.** Grep for any other easing curve in new code; a Reduced Motion pass on the ceremony, the climb and the dispatch's arrival.

**The ceremonies are product, not polish** (L-31). POSTED ✓, the finish, the split-flap rank, the climb, the engraver, the month seal, the season takeover once per member, the Trophy Room. The overhaul **adds one caller** (the takeover fires from Home, not only from the room) and removes none.

---

## 5 · The ranking rule for Home

One sort, six tiers, one veto, one fence. It is written down **once**, here, and implemented **once**, on the server, in `home_dispatch()`. It is not restated on any screen spec, so it cannot drift.

### 5.1 The tiers

| Tier | Name | Fires on |
|---|---|---|
| **1** | **CLOSING** — something ends inside 72 hours and **I can still act on it** | my live round is open · the clash has ≤ 2 days left and it is not idle · an invite is waiting · a buddy request is waiting · I am tagged on a plan and have not answered · the month closes in ≤ 3 days and I am short **(squads only, D140)** · a first tee inside 72 h · a callout closing · a cancel vote is open |
| **2** | **CHANGED** — a fact about **me** moved since my last open | my rank changed (honestly clocked) · a round of mine posted · a clash settled · a season kicked off or wrapped · my number went live at three rounds · I was passed |
| **3** | **COMING** — a dated thing inside 8 days | my next round · buddies playing this weekend · the first tee in N days · the Final opening · the month closing in 4–10 days |
| **4** | **CIRCLE** — someone I know did something | the top story, ranked by proximity: an opponent in an open clash > a named rival > a buddy > a league mate |
| **5** | **CHAPTER** — the standing truth of the season, retold when it changes, **at most weekly** |
| **6** | **OPPORTUNITY** — the door worth walking through today, fired only on a real shape: three buddies and no season · a wrapped season and no live one · a friend's plan with an open seat · a declined invite still holding a seat |

**Within a tier:** mine before an opponent's before a buddy's before a league mate's; newer before older; a door I have never used before one I have.

**The one-sentence version, for anyone who has to remember it:** *the top slot goes to the thing that has a clock on it and that I can still change.* That is Tier 1, and it is what D176's fixed ladder was actually protecting.

### 5.2 The veto

> **The lead must have a human subject or a first-person verb. A bare standing can never lead.**

- **This means** `2nd of 2 — held` is a **fact**, and facts live in the ME strip. The lead is what a person did, or is about to do, or is about to lose.
- **This forbids** a lead whose headline is a number, a rank, a stage word, or a sentence whose subject is the app.
- **How we check.** A unit test on the ranker: for every one of the thirteen states, the chosen lead's headline parses to a subject that is a person (named or "you") or a verb in the first person. It is one assertion and it is the whole difference between this Home and the shipped one.

### 5.3 The fence

- A tier fires only on **a fact with a door**. If only Tiers 5 and 6 exist, that is the lead, and it says something true and quiet.
- **Nothing rotates, nothing is randomised, nothing counts down to manufacture pressure.** D216's yield is kept verbatim: a clash nobody has played in does not lead.
- **No sentence ever says "you haven't."** The app says what is true about the world and leaves the move to me.

### 5.4 The engineering rules that make the rule survivable

1. **The ranking is a server producer** returning `tier`, `rank` and `rank_reason` per item, so the second client renders a list rather than reimplementing a ladder, and a QA screen can dump the ranking (`-cs_dev_dispatch`, DEBUG only).
2. **A ranking bug degrades; it never blanks the app — and the fallback is named against the renderer that will exist.** "Render as today" is not available, because the wave that adds `home_dispatch` also retires `HomeMode`, `HomeLead` and `HomeHeroCopy`. The declared fallback is a **client producer, `HomeFallbackItems`**: items composed from `native_home` + `home_feed` + `my_invites` + `home_clash`, sorted by the static tier-less order **CLOSING → CHANGED → COMING → CIRCLE**, **no lead card**, and the ME strip drawn from `native_home.profile` plus the `home_feed.is_me` row. Items that come back with no tier take the same order. Every new argument is defaulted (`CLAUDE.md:77-80`), and **a preflight check fails the push if the fallback producer is absent** — migrations here are applied by hand, so a client-ahead deploy is a real Tuesday, not a hypothetical.
3. **The lead hands down a `suppress: Set<Fact>`.** L-34 becomes a producer rule instead of a per-screen judgement.
4. **Home makes exactly one read.** The ME facts and the ranked list come back together; nothing is composed twice on one open.

### 5.5 The acceptance artifact — the week in the life

**Any Home that cannot produce this has not shipped.** Nine consecutive opens, nine different true sentences, every one traced to a named read.

**In a season** (week 5 of 13, 2nd of 8, $50 owed):

| Day | The lead | Kind · tier | Read |
|---|---|---|---|
| Mon | "Mike has led for four straight weeks. He has not been caught since the second Sunday of the season." | CHAPTER · 5 | `season_story` |
| Tue | "Jade posted 81 at Troon North. Her best of the season." | VERDICT · 4 | `home_stories` |
| Wed | "Your clash with Galen opens. Best round of the week takes it." | WEEK · 3 | the inlined clash |
| Thu | "Galen posted 79. That is the number to beat, and you have three days." | WEEK · 1 | the inlined clash |
| Fri | "Saturday, 7:10 at Papago. Three in, one seat open." | UPCOMING · 3 | `my_schedule` |
| Sat am *(push the night before)* | "Papago at 7:10 tomorrow. Galen's 79 is still standing." | push | `my_schedule` + the clash |
| Sat pm | "You shot 78. You beat your number by 3.1 — and you beat Galen." | VERDICT + settle · 2 | `round_epilogue` + `settle_week_clash` |
| Sun | "The clash is yours. Second week running." | WEEK verdict · 2 | `week_clashes.winner_member` + `head_to_head` |
| Sun pm | "You moved to first. Mike is four back for the first time this season." | STANDING change · 2 | `standing` + `prev_rank` |

**With no season at all** (five buddies, nine rounds) — the state the shipped app has nothing to say to:

| Day | The lead | Kind · tier | Read |
|---|---|---|---|
| Mon | "Your number is 14.2. Nine rounds in, and it has not moved in three weeks." | CHAPTER · 5 | `index_current` + `my_streaks` |
| Tue | "Dev broke 90 for the first time." | VERDICT · 4 | `home_stories` over `achievements` |
| Wed | "Three of your buddies are playing Saturday. None of you is playing for anything." | OPPORTUNITY · 6 | `my_schedule` + `my_friends` |
| Thu | "You have beaten Dev on four of the last six days you both played." | RIVALRY · 4 | `head_to_head` |
| Fri | "Saturday at Papago, 7:40. Dev is in. Two seats open." | UPCOMING · 3 | `my_schedule` |
| Sat | "You shot 86. Dev shot 88. The callout is yours." | VERDICT · 2 | `round_epilogue` + the session settle |
| Sun | "Four rounds between the two of you this month. Four is a season." | OPPORTUNITY · 6 | `home_feed` counted over the circle |

**Nothing on the second list requires a league.** That is the answer to "Home alive with no season", demonstrated rather than asserted.

---

## 6 · The empty-state rule

> **An empty state is an opportunity, a failed read is not an empty state, and neither is ever a dead end.**

- **This means** every empty surface has four parts and no more: a quiet icon · one line in voice · one true fact if one exists · **one next move**. Home's four foot doors are present in every state, including the empty ones, so the floor is never zero.
- **This means** a failed read renders **honestly and separately**: cached content under an `AS OF … · OFFLINE` dateline with no action disabled, or — with nothing cached — *"Cup Season can't reach the desk right now. Nothing here is missing — it just hasn't arrived."* with **Try again**.
- **This forbids** the empty-feed sentence doubling as the failure state (`HomeView.swift:283-288`); a spinner inside content (a redacted shape instead); fabricated content or faces to fill a space (L-23); and an empty state whose door is optional (`CSEmptyState`'s optional door is the pattern defect).
- **This forbids** an empty state that names the golfer's absence. *"Nothing posted this month"* opens on absence; *"Two rounds gets you back in the Fellas table before it closes"* opens on the move. The second is the only legal shape.
- **How we check.** Walk every empty surface in the app with the network off and with a fresh account; assert a door on each; grep `CSEmptyState` call sites for a nil door; read every empty string aloud and ask whether its first four words are about the world or about the golfer's failure.

---

## 7 · The terminology rule

> **One word for one thing, produced in one place per client, and guarded by one lint per law.**

- **This means** the vocabulary ships as a table (`INFORMATION_ARCHITECTURE.md` §15.5) implemented by the proven mechanism — one producer per client per law plus a preflight check in the shape of check 20 (the D120 `STAGE_LABEL` pattern, roughly 25 lines each). It is **not** a rewrite project and it is not a copy pass.
- **This means** a word ruled once is defined **at first contact** and never again: *"Galen runs the season (the Pro)"*, *"the board — where the season talks"*, *"a unit is the stake you set"*.
- **This forbids** a schema noun on a user surface — `COUNTING CAP`, `PARTICIPATION FLOOR`, `STRUCTURE`, `PRESET`, `VERIFICATION`, `duel`, `session`, `differential`, `bylaws`, `Clubhouse` as a tab label.
- **This forbids** one fact produced in more than one place. The named hazards and their single producers: **the week number** → `native_home.season.week_no` (six formulas today) · **the band name** → `band_name(p_pvi)` (seven copies) · **the head-to-head record** → `head_to_head()` (three implementations) · **the PvI lens** → the server's league-aware `home_feed`/`round_card` (D123's unbuilt half).
- **This does not forbid** a ruled phrase that sounds technical but is the ruling's own words: *"scored fresh"* (D126) and the bylaws' allowance row (D128(2)) stay.
- **This forbids** a grep so narrow it lets the same law through in another phrasing. The retired *record* sense of "your card" has six phrasings; the check is **`\bon your card\b`** with the **profile** sense allowlisted by call site (the card gate, the marker footnote, the ME strip's tap target). The record sense is **"posts to your rounds"**, and where nothing is lost it is **"your rounds stay where they are"**.
- **How we check.** The suite reads **0** at ship on both clients, or the ship stops. **Twenty-nine checks**, listed in `TERMINOLOGY.md` §4 (which supersedes the shorter list in `INFORMATION_ARCHITECTURE.md` §15.5), plus a grep for each hazard's second producer. **Four of the twenty-nine need a call-site-aware extractor** — they hit column lists inside `.select(…)` and property paths inside string interpolation — and ship behind it; the other twenty-five ship first. **These are the terminology checks and they are numbered separately from the twelve component checks, which are `CL-1 … CL-12`** (`COMPONENT_SYSTEM.md` §8) — and neither register may reuse the wall's `L-nn`.

---

## 8 · The disclosure rule

> **Ask three questions, then start. Everything else is one tap deeper, complete and unchanged.**

- **This means** creation asks **Who? · When? · What's on it?** and nothing else before Start. Presets carry **one sentence each** and never name a dial. **More settings** holds all twelve dials verbatim with their ⓘ paragraphs. The rules page states the same mechanics as sentences a golfer would say, and every figure on it taps to its receipt.
- **This means** progressive disclosure runs in the *other* direction too: the composer shows one box and folds nine things beneath it; the live setup shows **Who · Where · What are we playing** and folds strokes, stakes, guests and Bluetooth.
- **This forbids** a preset that recites its dials (D8's rule is that presets never mention them, not that they mention them in nicer words); a review step of ten all-caps rows; a setting deleted in the name of simplicity; and a fold that hides something a golfer needs in the next thirty seconds.
- **How we check.** Count the concepts above the fold on the wizard's three steps, the composer and the live setup (`LiveSetupView.swift:24-184` is the 20-concept specimen). Diff the dial inventory before and after. Run the preset lint.

---

## 9 · The notification rule

> **A notification names one of D23's eight emotions or it does not render. Once per condition. No shame, ever. And none of it ships until one production token has received one real push.**

- **This means** every kind is fenced by L-20: one emotion, once per condition, no badge counts beyond the actionable ones (`actionable_count_of`: requests · invites · live rounds you are on), and the ask stays contextual (after the card, after the first round, after the first join — never on launch).
- **This means** a notification creates **anticipation about a real event**: "Galen just passed you", "Galen posted 79. Two days to answer", "Papago at 7:10 tomorrow", "Mike called you out for Saturday", "The Fellas starts Saturday".
- **This means** a round fans **by person, not per league** — today one round fires N pushes to a golfer who shares N seasons with the poster.
- **This forbids** pushing a **standing** ("you're 4 points from 2nd") — a standing is not an event, and pushing one is the definition of manufactured urgency, which D130's own "Push: none" already ruled. **Streak pushes.** **"Your friends are more active than you."** A badge for anything but the actionable count. A push to the author of the thing that triggered it.
- **This forbids** designing a recipient list to solve a producer problem: a buddy's round with no shared season cannot fire the webhook at all until the producer moves to the round-insert path.
- **This means** the emotion is **named per kind, from D23's eight** — pride, nostalgia, anticipation, belonging, rivalry, joy, reflection, achievement — and the table lives in `INFORMATION_ARCHITECTURE.md` §14 and in D248, not as a caption on a list of kinds. Nine of the ten new kinds map: `rank_change`/`clash_pressure`/`callout` → **rivalry**; `clash_verdict`/`index_live` → **achievement**; `tee_tomorrow`/`season_countdown` → **anticipation**; `friend_round`/`seat_open` → **belonging**.
- **This means** the one kind that is **not** an emotion is ruled outside this policy by name rather than given a word that is not one of the eight. `season_cancel` carries a **consent notice** — a vote is opening on money and on a season somebody paid into — and it is filed as a transactional notice under D71/L-38. It still fires once per condition and still lands on a page that exists.
- **How we check.** The table exists, with one row per kind naming its trigger, its emotion (or its explicit exemption), its once-per-condition key, its copy and its landing route — and every landing route must resolve to a page that exists. A kind with a blank emotion cell does not ship. Then the gate: **one production APNs token, one real notification, before any of it is built.**

---

## 10 · The story rule

> **Numbers are spoken as story first, table second. Every sentence the app says is computable, or it is not written.**

- **This means** the season page leads with a story line chosen by a **fixed ladder** over named reads, so the sentence is learnable rather than a mood. **Rung 7 reaches into history** (**R-H**, the owner's ruling): when nothing has happened this week the line looks further back for something that is *still true* — an unsettled rivalry, a streak, a record between two people, the anniversary of a result — computed from `head_to_head` (**R4**), `my_streaks` (**R8**), `rivalry_weeks` or `standings_snapshots`, and never from anything else. **The fence is untouched and absolute:** nothing is invented, nothing is inflated, and **no line manufactures a stake that does not exist**. What changed is how far back the ladder may look. When even that finds nothing, **rung 7b** says *"nothing has moved since Sunday"* — still the honest sentence for a quiet week.
- **This means** each table row carries one clause of why (`held four weeks`, `up one since Sunday`, `her best week was 3`), and each record row opens a story page rather than a dead table.
- **This means** the three voice layers do three jobs and no more: the Broadcaster sets the scene, the Clubhouse gives the facts, the Instigator undercuts — and **the Instigator punches at the golf, never at the person**. *"Your cut of the pot is nothing, which he has mentioned"* fails that test and does not ship.
- **This forbids** a probability, a projection dressed as a fact, or any guess at an outcome (D24). Predictions may state what is **clinched, eliminated or needed** — never what is likely.
- **This forbids** a sentence whose facts the server did not measure (L-44), a number that counts nothing, and a hero that claims a table rank as a seed.
- **How we check.** Every quoted string in the IA traces to a named read in §15. The seven rungs are each a count over one table. A voice pass against `spec/voice-and-tone.md` on every authored string: no exclamation, no emoji in prose, natural case for authored sentences, **function first on controls** ("Add my round", "Open the season", "See the terms").

---

## 11 · The money rule

Money is the fastest way to lose a friend group, so it gets its own rule.

- **This means** $0 is the default and selected (L-11). The pot is a **ledger with two numbers** — pot (stake × roster) and collected — never blended. The ceremony pays from **collected**. A $0 season shows **no pot surface anywhere**. The ledger line is **one constant per client, printed verbatim**: *"Cup Season keeps the ledger; the money moves between friends."*
- **This means** an unpaid state is **self-only** and lives in one always-present place — the ME strip's `STILL OWE` slot — where it fires from state on every open, and taps to the books. It is D129 **relocated, not demoted**: never a once-per-condition card, never a rung that a closing clash can preempt.
- **This means** the Pro's payment note is **required at publish**, so the golfer who owes $50 can always find out how to pay it — the fact two persona walks hit and could not get. And the stake ladder gains an **Other** numeric field, because $20 is impossible today.
- **This forbids** a due-date countdown, a red badge, a shame line, or gold on an owed figure (money is never urgency and never earned). A covenant a golfer never sees. Any purchase UI or pricing on the front door (L-39).
- **How we check.** A $0 walk (no pot surface anywhere), a $50 walk (the owe line present on every open until paid, and its terms reachable in one tap), and a covenant walk on all four join paths including $0 and the in-app invite.

---

## 12 · The wall — the laws that bound everything

All 45 are immutable. This table names, for each surface the overhaul touches, the laws that decide whether it may ship. Full text: `scratchpad/ux/audit/reader-canon-and-constraints.md` §3A.

| Surface | Laws that bind it |
|---|---|
| **Home / the dispatch** | **L-21** (never opens on nothing; curate, never fabricate) · **L-22** (no vanity metrics, no engagement bait, no infinite scroll, no addictive mechanics) · **L-34** (one fact, one place) · **L-44** (every number counts something; a failed refresh keeps what is on screen) · **L-24** (marker first, names from server producers) · **L-32** (every empty ends in a move) · **L-13** (each item carries its own season's lens and says which) |
| **The ME strip** | **L-34** · **L-10** (self-only unpaid state; two numbers never blended) · **L-14** (one lens, one word for one figure; a bare float always labelled) · **L-17** (the endgame always visible) · **L-29** (three voices, 11-pt floor, AX-tolerant) |
| **⊕ Play and the composer** | **L-40** (the free door; live leads the ⊕ in ember; guests need no account; side games never touch season points) · **L-03** (game-consequence writes are RPCs — the direct `rounds` insert becomes `post_round`) · **L-02** (rounds immutable) · **L-15** (two numbers and one band phrase) · **L-19** (a tag is never a vouch) · **L-29** (a focused numeric input is a control: never serif) |
| **Creation** | **L-16** (dials only inside Custom; presets never mention them) · **L-11** ($0 default) · **L-09** (the ledger line verbatim) · **L-41** (formation integrity; `lock_league` is one transaction) · **L-12** (membership at lock; a member never sees the Pro's tool) · **L-43** (six stage words, one producer, preflight 20) |
| **Joining** | **L-12** (**every** join passes the covenant) · **L-06** (code-only email, 8 digits) · **L-08** (the gate is marker **and** handle — *set*, not chosen) · **L-36 / L-45** (the anon surface: twelve endpoints, fail-closed, tokened, definer, a db-check edit for any change) |
| **The season page** | **L-35** (story first, table second) · **L-01** (every number shows its work) · **L-17** (the endgame; the Final scored fresh; no last-place mechanic) · **L-18** (season shape; solo floors never assess) · **L-10** (the pot) · **L-43** (the stage line) |
| **Moments** | **L-40** (guests) · **L-42** (one headline per round; six-emoji reactions) · **L-44** (a flag-closed Major must not be advertised) |
| **Golfers / the person page** | **L-37** (the Tour Card gate is the one privacy rule; exact @handle or a buddy) · **L-22** (no attention metrics on the board) · **L-24** (the marker is the floor) · **L-38** (report, block, hide, suspend, delete on every surface where content is) |
| **Every surface carrying another golfer's content** | **L-38**, stated as a pattern rather than an aspiration: **P-17** (`COMPONENT_SYSTEM.md` §4) mounts report · block · hide · mute on the person page, the head-to-head page, every wire row, every moment page, the board and a round's comments, plus the delete-account path in Card & settings. It is in the **immutable** wall and it must *survive any redesign* — which is precisely what promoting `TourCardSheet` (mute at `:134-137`, the two-step report at `:151-169`) into a page threatens. `COMPONENT_SYSTEM.md` §9's P-17 column is the coverage check and `INFORMATION_ARCHITECTURE.md` §18.1's fourth test is the walk |
| **The record** | **L-01** · **L-44** (no $0 earnings figure dressed as a stat) · **L-14** |
| **Notifications** | **L-20** (one emotion, once per condition, no shame, badge = actionable only) · **L-22** |
| **Every screen** | **L-25** (two metals, never swapped) · **L-26** (one heat axis, semantic never decorative) · **L-27** (dark default, light one tap away) · **L-28** (what a look may tint) · **L-29** (three type voices) · **L-30** (one easing) · **L-31** (the ceremonies are product) · **L-32** (empties, loading, "Sure?") · **L-33** (the Gentleman Instigator; function first on controls) · **L-39** (no purchase UI) |
| **Every migration and read** | **L-04** (explicit grants; a new `profiles` column needs its `grant select` in the same file) · **L-05** (timestamp-named, never edited after they run) · **L-07** (dates are strings, parsed only by `localDate()`/`CSDate.local`) |

### 12.1 The two places the wall is tested, and how each is resolved

1. **L-40's "live leads the ⊕ in ember"** appears in the immutable wall **and** in the overridable list (O-07), both citing the same self-declared UI-level D110. **This design holds it immutable**: the ⊕ keeps its cover with live first in ember, and the 90 % case is served by a long-press, by every explicit "Add a round" CTA jumping to the composer (D110's own addendum), and by Home's first foot door. The alternative is filed as an owner question; it changes one screen and nothing else.
2. **L-17 / D126(2)'s "the endgame is a sentence you can always see"** is satisfied by a **split**, which is an explicit UI-level amendment and is written as such (D235): a short clause in the ME strip, which is present on every Home open, and the full sentence permanently under the season page's table. The law's requirement — always visible — is met on both surfaces; what changes is that a 40-word paragraph no longer pushes the rest of Home below the fold.

---

## 13 · What this document deliberately does not decide

**The owner has ruled eight of the ten questions this set opened** (`OWNER_RULINGS.md`, R-A…R-H), and they are merged into the artifacts rather than left standing. Two of the three principles-shaped ones are now answered:

- **Which of the "beat one guy" offers is first** — **R-F**: the length is asked, all three are always offered, and the words are the owner's. The person's state may *order* them; it may never withhold one.
- **Whether a quiet week may reach into history** — **R-H**: yes, under the same absolute fence. §10 carries it.

What remains for the owner, principles-shaped and named here so nobody resolves it by default:

- **Whether the ranker should ever be tunable per golfer.** The recommendation is to ship it fixed and resist. A per-golfer ranker is a different product with a different set of laws.
- **Whether rung 7b still reads as flat.** History makes the quiet week rarer, not impossible; when even a rivalry and a streak find nothing, the line says nothing has moved. That is honest under L-21 and it may still be the wrong feeling.
- **Whether a starter index may score.** §11.1's band writes a figure the engine scores against, which is the option D124 declined. It is a level-4 consequence inside a level-5 screen and only the owner may overturn an owner ruling (`INFORMATION_ARCHITECTURE.md` §19 item 1).

The full list, with what happens if each is declined, is `INFORMATION_ARCHITECTURE.md` §19.

---

## 14 · Known gaps

| # | The gap | Why it is recorded rather than resolved | What reopens it |
|---|---|---|---|
| **1** | **Nine of the eleven rules here are checked by a walk, not by a test.** §5's veto and §6's empty-state walk are assertions a person makes with a device in hand. | Two of them **are** automatable and are: the veto is one unit assertion on the ranker (`HOME_STATE_MATRIX.md` T2), and the terminology suite is 29 greps. The rest — "read every empty string aloud and ask whether its first four words are about the world" — is judgement, and pretending otherwise would be the same dishonesty the rules forbid. | A rule that fails twice in a row is a rule that needs a check, not a stronger sentence. |
| **2** | **§9's whole rule is gated on a channel that has never delivered.** One `ios-sandbox` token, zero accepted prompts. | It is a gate rather than a risk: no notification work begins until one production token receives one real push. Everything in §9 is a specification until then. | The Wave-0 gate passing. |
| **3** | **§2's five vision principles have no measurement yet.** Activation, time-to-aha and competition creation are named as success metrics with no baseline but `post_submit` (n=24, p50 39 s). | Wave 0 stamps `app_open` / `home_state_seen` / `cta_tapped` / `first_act` and `platform` centrally; until then every target in this set is a target and says so. | The first month of those events. |
