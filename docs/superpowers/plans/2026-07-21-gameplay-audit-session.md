# Gameplay Audit → Decision Session Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline — every task has an owner-approval gate that needs the live session; do NOT dispatch subagents past a gate). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the 2026-07-21 gameplay design audit into logged decisions (D48–D55) and parked follow-ups, in one Gameplay-lane session, docs-only.

**Architecture:** Each task = one decision packet: draft entry (full text below) → present to owner via AskUserQuestion → finalize per the call → append to `spec/decision-log.md` → cross-reference updates → commit. No app code ships from this plan; approved entries that need builds each get their OWN build plan later (CLAUDE.md rule 3: design passes and structural builds ride separately).

**Tech Stack:** Markdown only. Files touched: `spec/decision-log.md`, `spec/spec-v1.0.md` (amendment notes only), `spec/gameplay-modes-working.md`.

## Global Constraints

- **Talk first.** No entry is appended until the owner answers its gate question. A "skip" answer parks the packet (Task 9's park list catches it).
- **Entry format (hierarchy-of-truth, non-negotiable):** `### D## · Title` + date line, then **Current · Problem · Recommendation · Principle · Benefit · Tradeoffs · CONFLICT (named or "none upward")**. Match D40's shape exactly.
- **D-numbers:** log head is **D47** (verified 2026-07-21). Before EACH append, re-check the head — parallel lanes exist: `grep -E "^### D[0-9]+" spec/decision-log.md | tail -1`. If the head moved, renumber your entry to head+1.
- **Never edit spec-v1.0 sections destructively.** Amendments are appended notes citing the D-entry (the §14.0 pattern); v1.1 reconciles prose later.
- **Noun laws:** never "counting cap" in user-facing copy → "your best four" (D2); "the Pro" not commissioner (UI); crew = people, league = competition (D11/D47); "a Major" is the user noun (D47).
- **No app code, no migrations, no version stamping this session.** `__CS_VERSION__` untouched (nothing in `index.html`/`sw.js` is touched at all).
- **Commits:** one per task, `docs(spec): …`, ending with the standard Co-Authored-By line.
- **Branch:** all work on `gameplay-arc-2026-07-21` off `main` (Task 0). Do not commit to `main`.
- **Parallel-lane fetch rule:** fetch before branching (memory: deploy-fetch-before-main).

**Priority order is the task order.** If the session runs out of time, everything not reached is auto-parked by Task 9 — run Task 9 and Task 10 regardless.

---

### Task 0: Session pre-flight

**Files:**
- No file changes; git + verification only.

**Interfaces:**
- Produces: branch `gameplay-arc-2026-07-21`; confirmed D-head number used by all later tasks.

- [ ] **Step 1: Fetch and branch**

```bash
git -C /c/Users/17203/Downloads/cup-season fetch origin
git -C /c/Users/17203/Downloads/cup-season checkout main
git -C /c/Users/17203/Downloads/cup-season pull --ff-only origin main
git -C /c/Users/17203/Downloads/cup-season checkout -b gameplay-arc-2026-07-21
```

Expected: `Switched to a new branch 'gameplay-arc-2026-07-21'`.

- [ ] **Step 2: Confirm decision-log head**

```bash
grep -E "^### D[0-9]+" spec/decision-log.md | tail -1
```

Expected: `### D47 · Noun sweep II …`. If higher, shift every D-number in this plan up accordingly (D48 → head+1, etc.) and note the shift in each commit message.

- [ ] **Step 3: Confirm working tree clean**

```bash
git status --short
```

Expected: empty output.

---

### Task 1: D48 · The subtraction batch (H2H, Hybrid, bonus layer, allowance dial)

**Files:**
- Modify: `spec/decision-log.md` (append after D47)
- Modify: `spec/spec-v1.0.md` (amendment notes at §2.3, §4, §8)
- Modify: `spec/gameplay-modes-working.md` (§1.3 formats line)

**Interfaces:**
- Consumes: D-head from Task 0.
- Produces: D48 logged; resolves the two-review open question "A-W5: H2H in or out" (answer proposed: out).

- [ ] **Step 1: Present the gate question to the owner**

Use AskUserQuestion:

> **Question:** "Audit + both design reviews flag dormant rules as explain-surface debt. Kill from spec v1.1 (not just the wizard): Head-to-Head format, Hybrid format, the bonus layer (§2.3), and the Custom allowance dial (presets keep their fixed values)?"
> Options:
> 1. **Kill all four (Recommended)** — formats collapse to Points Race + endgame dial; revival cost is a re-spec, no code loss (engines never built).
> 2. **Kill bonus + allowance dial only** — keep H2H/Hybrid dormant in spec.
> 3. **Skip** — park the packet.

- [ ] **Step 2: Append D48 to `spec/decision-log.md`** (adjust scope to the call; full-kill text below)

```markdown
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
```

- [ ] **Step 3: Add amendment notes to `spec/spec-v1.0.md`**

At the end of §2.3, §4, and §8 (do not delete prose), append one line each:

```markdown
*(D48, 2026-07-21: retired — see decision log. v1.1 removes this section/row.)*
```

- [ ] **Step 4: Update `spec/gameplay-modes-working.md` §1.3**

Replace the formats line:

```markdown
Formats: Points Race only (D48 retired B/H2H and C/Hybrid). Endgame stays the
bylaw dial: points_table | cup_final.
```

- [ ] **Step 5: Verify format completeness**

```bash
grep -A2 "^### D48" spec/decision-log.md | head -3
grep -c "D48" spec/spec-v1.0.md
```

Expected: D48 heading present; spec has 3 amendment mentions (2 if partial-kill).

- [ ] **Step 6: Commit**

```bash
git add spec/decision-log.md spec/spec-v1.0.md spec/gameplay-modes-working.md
git commit -m "docs(spec): D48 subtraction batch — retire H2H, Hybrid, bonus layer, allowance dial

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: D49 · Provisional scoring simplified (flat-7 retired)

**Files:**
- Modify: `spec/decision-log.md` (append)
- Modify: `spec/spec-v1.0.md` (§5 amendment note)

**Interfaces:**
- Consumes: D-head check.
- Produces: D49 logged; a future build plan implements the badge + removes flat-7 scoring.

- [ ] **Step 1: Present the gate question**

AskUserQuestion:

> **Question:** "First 3 rounds currently score a fixed 7 (spec §5). Audit: special arithmetic at the moment a new golfer is most nervous — a great first round scoring 7 reads as robbery. Replace with: score normally off the starter index, rounds badged 'provisional' until the engine establishes (3 rounds)?"
> Options:
> 1. **Replace flat-7 with provisional badge (Recommended)** — bands already cap damage (12 ceiling / 5 floor); exceptional-score rule still applies.
> 2. **Keep flat-7** — log the audit objection and close it.
> 3. **Skip** — park.

- [ ] **Step 2: Append D49**

```markdown
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
```

- [ ] **Step 3: Amendment note in `spec/spec-v1.0.md` §5**

Append to the §5 table's provisional row area:

```markdown
*(D49, 2026-07-21: flat-7 retired — provisional rounds score normally,
badged until established. See decision log.)*
```

- [ ] **Step 4: Verify + commit**

```bash
grep -A2 "^### D49" spec/decision-log.md | head -3
git add spec/decision-log.md spec/spec-v1.0.md
git commit -m "docs(spec): D49 provisional rounds score normally, flat-7 retired

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: D50 · The Pro's ruling (dispute procedure, written)

**Files:**
- Modify: `spec/decision-log.md` (append)

**Interfaces:**
- Produces: D50 logged; one paragraph of covenant/fine-print copy a future UX pass drops verbatim into the join covenant and league fine print.

- [ ] **Step 1: Present the gate question**

AskUserQuestion:

> **Question:** "Personas grant the Pro 'resolve disputes' / 'lock scores' with zero written procedure. First contested card in a money league is where trust is minted or lost. Adopt one written rule: the Pro rules, every ruling is a logged override with a reason visible to everyone, settled events never retro-flip?"
> Options:
> 1. **Adopt (Recommended)** — rides the existing override log + D43's no-retro-flip precedent; zero new machinery.
> 2. **Adopt, different wording** — you edit the paragraph in the entry before it's logged.
> 3. **Skip** — park.

- [ ] **Step 2: Append D50**

```markdown
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
```

- [ ] **Step 3: Verify + commit**

```bash
grep -A2 "^### D50" spec/decision-log.md | head -3
git add spec/decision-log.md
git commit -m "docs(spec): D50 the Pro's ruling — written dispute procedure

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: D51 · The personal stake line, unparked

**Files:**
- Modify: `spec/decision-log.md` (append)
- Modify: `spec/gameplay-modes-working.md` (§8 header: PARKED → DECIDED, pointer to D51)

**Interfaces:**
- Consumes: §8 of gameplay-modes-working.md (the full design — priority ladder, honesty rule, implementation note). ⚑2 already answered (post screen).
- Produces: D51 logged; the follow-up BUILD plan (separate session, explicit "build it") implements client-side: marginal value `max(0, 12 − worst counting round)`, reads `b.floor_penalty` directly (never inferred from preset), priority ladder 1–5 else silent.

- [ ] **Step 1: Present the two open ⚑ as the gate question**

AskUserQuestion (two questions in one call):

> **Q1 (⚑1 — the at-cap line):** "When a golfer's best four are banked and their worst is a 12, the honest line says today's round adds 0 to the table. Show it reframed — 'your four are banked; today's round is for your number, the Iron Man, and the board' — or hide the line entirely at cap?"
> Options: 1. **Show, reframed (Recommended)** — honest + redirects to what still counts. 2. **Hide at cap** — line only ever speaks when the table can move.
>
> **Q2 (⚑3 — silence):** "Should the line be silent whenever nothing on the priority ladder (floor risk / index not established / at cap / cup-line closable) applies?"
> Options: 1. **Silent by default (Recommended)** — a line that speaks daily is wallpaper by week three. 2. **Always show something** — fallback: "even a rough day banks 5."

- [ ] **Step 2: Append D51** (adjust ⚑ resolutions to the calls; recommended-path text below)

```markdown
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
  silent). ⚑1 RESOLVED: show the at-cap line, reframed — "your best four
  are banked; today's round is for your number, the Iron Man, and the
  board" — honest, never deflating (a round never scores zero to the
  golfer's life, only to the table). ⚑3 RESOLVED: silent by default when
  nothing on the ladder applies. Inherited laws restated for the build:
  never claim a resulting position (D24); never say "counting cap" — say
  "your best four" (D2); line taps through to the month's slot meter (D3,
  §16); read `b.floor_penalty` directly, never infer from preset.
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
```

- [ ] **Step 3: Update `spec/gameplay-modes-working.md` §8 header**

Replace the §8 status line:

```markdown
## 8. The personal stake line (DECIDED — D51, 2026-07-21; build pending its own plan)
```

- [ ] **Step 4: Verify + commit**

```bash
grep -A2 "^### D51" spec/decision-log.md | head -3
grep "D51" spec/gameplay-modes-working.md
git add spec/decision-log.md spec/gameplay-modes-working.md
git commit -m "docs(spec): D51 stake line unparked — at-cap reframe, silent default

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: D52 · The weekly clash (the season's heartbeat)

**Files:**
- Modify: `spec/decision-log.md` (append)
- Modify: `spec/gameplay-modes-working.md` (new §11 stub pointing at D52)

**Interfaces:**
- Consumes: events-engine weekly-clash rivalry detection (built); week snapshots (built); D23 nudge fence; §5 parallel-ledger law.
- Produces: D52 logged with launch-timing call; future build plan scopes engine + board posts.

- [ ] **Step 1: Present the gate question**

AskUserQuestion:

> **Question:** "Audit's core structural finding: the season has no weekly stake — the Ryder (side mode) has the heartbeat the flagship lacks. Proposal: each season week, the engine spotlights ONE clash per league (priority: named rivalry > closest table gap > least-recently-featured); best band-of-week takes a headline W feeding the faceted rivalry record. No cup points (parallel ledger, §5). Board post at week open, settle at close; push opt-in per D23. When?"
> Options:
> 1. **Log now, build after month-1 proof (Recommended)** — decision banked, build gated on one real completed PIGL month (both reviews' verdict: proof before features).
> 2. **Log now, build for launch** — the heartbeat matters more than surface-count discipline.
> 3. **Redesign** — you want different pairing/stake rules; capture your version in the entry.
> 4. **Skip** — park.

- [ ] **Step 2: Append D52** (text assumes option 1; adjust the build-gate line to the call)

```markdown
### D52 · The weekly clash — one spotlighted pairing per week
*(2026-07-21, gameplay-audit session. NEW mechanic — the audit's structural
finding made concrete: the flagship season lacks the weekly anticipation
loop the Ryder has. Build gated on one real completed month.)*
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
  number-to-beat precedent). BUILD GATE: after one real completed PIGL
  month — the decision is banked now so the build starts warm.
- **Principle:** The App Should Feel Alive + anticipation between rounds —
  at crew scale, where the thin-feed arithmetic (2–3 posts/week) can't
  fill a daily feed, a weekly episode is the honest cadence.
- **Benefit:** the season gets the Tue–Sun appointment beat; the rivalry
  record gets a steady diet; the board gets two guaranteed stories a week.
- **Tradeoffs:** a spotlight excludes everyone not in it that week —
  rotation rule mitigates; small leagues (4–5) cycle fast anyway. Adds one
  engine surface to a product the reviews say is already too wide — hence
  the build gate.
- **CONFLICT (named):** none upward. §5 parallel-ledger law respected;
  D23's fence respected (push opt-in, board posts are not nudges).
```

- [ ] **Step 3: Add stub to `spec/gameplay-modes-working.md`** (append at end, before any parked sections from Task 9)

```markdown
## 11. The weekly clash (DECIDED — D52; build gated on one real completed month)

One spotlighted pairing per league per season week; best band-of-week takes a
headline W into the faceted rivalry record. Never cup points. Full packet in
D52 — design detail lands here when the build unlocks.
```

- [ ] **Step 4: Verify + commit**

```bash
grep -A2 "^### D52" spec/decision-log.md | head -3
git add spec/decision-log.md spec/gameplay-modes-working.md
git commit -m "docs(spec): D52 weekly clash — the season's weekly heartbeat, build-gated

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: D53 · Month-close podium (the episode ender)

**Files:**
- Modify: `spec/decision-log.md` (append)

**Interfaces:**
- Consumes: `close_month()` rails (built, cron, idempotent); month headlines data already computed in standings/ledger.
- Produces: D53 logged; future build extends the close post server-side.

- [ ] **Step 1: Present the gate question**

AskUserQuestion:

> **Question:** "Month close currently posts one line ('JULY CLOSED'). Audit: the month is the product's natural episode — make the close a ceremony: month podium (top squad-month), month MVP (best individual points), biggest climb. No new points, no hardware, all from data already computed. Ghost list stays private (D23, no shame). Adopt?"
> Options:
> 1. **Adopt (Recommended)** — copy + one server-post extension when built.
> 2. **Adopt + month hardware** — also mint a small monthly trophy/marker (bigger scope, brushes §9 earned markers).
> 3. **Skip** — park.

- [ ] **Step 2: Append D53** (text assumes option 1)

```markdown
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
```

- [ ] **Step 3: Verify + commit**

```bash
grep -A2 "^### D53" spec/decision-log.md | head -3
git add spec/decision-log.md
git commit -m "docs(spec): D53 month-close podium — the episode ender

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: D54 · Draft night (the blind draw gets a reveal)

**Files:**
- Modify: `spec/decision-log.md` (append)
- Modify: `spec/spec-v1.0.md` (§15 amendment note)

**Interfaces:**
- Consumes: §15 blind draw (built: server shuffle, board-post reveal).
- Produces: D54 logged; future build plan decides pacing mechanism (server-timed posts vs client reveal animation — implementation lane's call).

- [ ] **Step 1: Present the gate question**

AskUserQuestion:

> **Question:** "Blind draw currently reveals as one instant board post. Audit: fantasy's flagship moment reduced to a feed item. Proposal: the Pro MAY schedule the draw — countdown on Home, then squads reveal card-by-card (~30s stagger) with reactions live. Instant draw stays the default; the shuffle rule is untouched (still server-side, rigging-proof). Adopt?"
> Options:
> 1. **Adopt (Recommended)** — pure theater on an unchanged rule.
> 2. **Adopt, simpler** — no scheduling; just pace the reveal whenever the draw runs.
> 3. **Skip** — park.

- [ ] **Step 2: Append D54** (text assumes option 1; option 2 drops the scheduling sentence)

```markdown
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
```

- [ ] **Step 3: Amendment note in `spec/spec-v1.0.md` §15**

```markdown
*(D54, 2026-07-21: the Pro may schedule the draw for a paced card-by-card
reveal; instant remains default. See decision log.)*
```

- [ ] **Step 4: Verify + commit**

```bash
grep -A2 "^### D54" spec/decision-log.md | head -3
git add spec/decision-log.md spec/spec-v1.0.md
git commit -m "docs(spec): D54 draft night — scheduled paced reveal for the blind draw

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 8: D55 · The sunlight chip (money-event index transparency)

**Files:**
- Modify: `spec/decision-log.md` (append)

**Interfaces:**
- Consumes: index snapshot history (kept since the snapshots build); Ryder roster + Major field surfaces (built/spec'd); D44 field line.
- Produces: D55 logged; future build renders one chip per player on money-event entry surfaces.

- [ ] **Step 1: Present the gate question**

AskUserQuestion:

> **Question:** "The Ryder ships with no anti-sandbag; the Major's field line only stops the un-established — not a padded established index. Money pays off index_at_post. Proposal: money-event entry (Ryder roster, Major field) shows a neutral fact-chip per player — index now vs 60/90 days ago ('12.4 · was 11.2 in May'). No block, no accusation; sunlight — the crew polices itself. Adopt?"
> Options:
> 1. **Adopt (Recommended)** — closes the audit's integrity gap with zero enforcement machinery.
> 2. **Adopt for Majors only** — Ryder stays chip-free until a real dispute.
> 3. **Skip** — park.

- [ ] **Step 2: Append D55** (text assumes option 1; option 2 narrows the surface list)

```markdown
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
```

- [ ] **Step 3: Verify + commit**

```bash
grep -A2 "^### D55" spec/decision-log.md | head -3
git add spec/decision-log.md
git commit -m "docs(spec): D55 sunlight chip — index movement shown on money-event entry

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 9: Park the remainder (nothing from the audit gets lost)

**Files:**
- Modify: `spec/gameplay-modes-working.md` (append new final section)

**Interfaces:**
- Consumes: audit items NOT covered by D48–D55, plus any packet the owner answered "Skip" to in Tasks 1–8.
- Produces: a parked-ideas section matching the repo's §8/§9 parking convention.

- [ ] **Step 1: Append the park section to `spec/gameplay-modes-working.md`**

Include every "Skip"-answered packet from this session, plus this base list:

```markdown
## 12. Parked from the 2026-07-21 gameplay audit (captured, not committed)

Each needs its own decision entry before any build. One line each so the
reasoning is findable; the full arguments live in the audit report.

- **2-player rivalry season** — a season-long duel with one buddy as the
  front door (min league size is 4; the hardest ask is 8 friends × 9
  months). Duel machinery exists; league becomes the upgrade path. The
  audit's biggest radical idea — needs its own brainstorm, not a batch line.
- **Defending-champion continuity** — D41 extension: "defending" badge,
  revenge headlines, Season 2 as sequel. Rides linked multi-season
  continuity, which D41 already deferred.
- **The records book** — league/lifetime firsts (lowest round ever posted,
  longest streak in league history) from data already held; turns every
  round into a potential history event.
- **Final-day horn + eliminated-squad race** — live cut-line surface on the
  season's last Sunday; Points King foregrounded for non-finalists once
  Cup Final seeds lock (half the league goes emotionally dark for 4 weeks).
- **The Callout (M5)** — public number-to-beat with auto-settle; still ⚑ in
  the memory layer; the audit ranks it the trash-talk engine. Needs the
  D51 stake-line math + D23 coordination.
- **9-hole floor-credit simplification** — kill the 0.5-credit fraction
  (9s count fully toward the floor, or not at all). Small, real, not
  batched into D48 because it changes a rule rather than deleting one.
- **Annual Major lineage** — already parked at §10.9; the audit co-signs it
  as the strongest legacy mechanic in the corpus. Unchanged, re-flagged.
- **Earned markers** — already parked at §9. Unchanged, re-flagged: the
  Major champion's marker is the natural first entry.
```

- [ ] **Step 2: Verify + commit**

```bash
grep "Parked from the 2026-07-21" spec/gameplay-modes-working.md
git add spec/gameplay-modes-working.md
git commit -m "docs(spec): park gameplay-audit remainder — nothing lost, nothing silently built

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 10: Session close — reconcile and hand off

**Files:**
- Modify: `spec/gameplay-modes-working.md` (§6 build-order note)

**Interfaces:**
- Consumes: everything logged this session.
- Produces: updated build-order note; the handoff summary for the owner.

- [ ] **Step 1: Update §6 (build-order implication) in `spec/gameplay-modes-working.md`**

Append after the existing numbered list:

```markdown
Post-audit addendum (2026-07-21): approved decisions D48–D55 spawn builds in
this order, each on its own explicit "build it" — (1) D51 stake line
(client-only, highest value-to-effort), (2) D53 podium + D54 draft-night
reveal (copy/server-post extensions), (3) D55 sunlight chip, (4) D52 weekly
clash (GATED on one real completed month). D48–D50 need no build beyond
spec v1.1 reconciliation and one covenant paragraph.
```

- [ ] **Step 2: Final verification — every appended entry is complete**

```bash
grep -E "^### D(48|49|50|51|52|53|54|55)" spec/decision-log.md
for d in 48 49 50 51 52 53 54 55; do
  echo "D$d fields:"; sed -n "/^### D$d/,/^---$/p" spec/decision-log.md | grep -cE "\*\*(Current|Problem|Recommendation|Principle|Benefit|Tradeoffs|CONFLICT)"
done
```

Expected: every logged entry lists 7 (skipped packets legitimately absent).

- [ ] **Step 3: Commit + summarize to owner**

```bash
git add spec/gameplay-modes-working.md
git commit -m "docs(spec): gameplay-audit session close — build-order addendum

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git log --oneline main..gameplay-arc-2026-07-21
```

Then report to the owner: which D-entries logged, which parked, and that merging `gameplay-arc-2026-07-21` to `main` is their call (docs-only branch — no version bump, no db push, no client deploy needed).

---

## Self-Review (completed)

**Spec coverage:** Audit's top-20 mapped — items 1,3,4,5,8(kill),9,11(chip),15,16-adjacent covered by D48–D55; UX-lane items (OTP, index copy, wizard, nomenclature) deliberately OUT of scope (wrong lane — this is the Gameplay session); remainder captured by Task 9's park list. Gap check: none silently dropped.

**Placeholder scan:** No TBDs. Every D-entry text is complete and paste-ready; every AskUserQuestion has full question + options; every command exact.

**Consistency:** D-numbers sequential 48–55 with the re-check rule for parallel-lane drift; every entry uses the D40-verified field format; cross-reference targets (spec §2.3/§4/§5/§8/§15, gameplay-modes §1.3/§6/§8 + new §11/§12) all exist in the current files.
