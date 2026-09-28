Use `$impeccable` for this whole program. You have my explicit permission to use sub-agents (`spawn_agent`) wherever Impeccable wants them: critique's two isolated assessments, parallel captures, and the scoring panel. Don't stop to ask about that.

# Cup Season UI/UX to 10/10, on the phone and the web

## The goal

Take Cup Season to a 10 on its own scale. The scale comes from BRIEF §29 and §35, as `docs/ui-overhaul-2026-09-06/UI_SCORECARD.md` and `ROAD_TO_TEN.md` apply it:

- **10:** would sit beside the best consumer sports apps with no apology.
- **8:** finished.
- **Below 6:** needs a redesign, not polish.

Score each surface on the ten dimensions (H T Sp C B P R E D M) using ROAD_TO_TEN's method. The last full score was a 6.24 mean, taken 2026-09-07 at `ee321bf`. A great deal has shipped since then, so re-derive every number at the new HEAD. Inherit none of them.

Two constraints outrank everything else:

1. **Don't put the October 1 launch at risk.** D371 makes October 1 the App Review submission and public launch. `docs/planning/2026-09-22-visual-ui-sprint.md` sets the visual freeze for September 30. Nothing from this program goes into the launch build unless I name it.
2. **Talk first** (CLAUDE.md rule 1, AGENTS.md §4). Phases 0–3 change no product source. Stop at the checkpoint and wait for me to say "build it".

## Phase 0 · Isolate and orient

- **The old checkout.** `/Users/fischbeck3/cup-season` is the old, dirty `codex/testflight-visual-refresh-2026-09-11` checkout, about 255 commits behind `origin/main`. Don't edit, stash, commit or clean anything in it. Its DesignV1 pack (`cup-season-visual-implementation-pack/` and `docs/design-designv1-implementation.md`) is design input you may read. It is not a baseline, and never copy it wholesale.
- **Create the worktree.** Run `git fetch origin`, then `git worktree add -b codex/impeccable-ten-2026-09-27 /Users/fischbeck3/cup-season-ten origin/main`. Work only in that worktree. It lives outside /private/tmp because this program runs for days.
- **Read first:**
  - AGENTS.md, CLAUDE.md and `docs/planning/ACTIVE_WORK.md`
  - the Sep 22 visual sprint and `spec/launch-readiness-2026-10-01.md`
  - BRIEF, UI_SCORECARD, ROAD_TO_TEN and UI_SYSTEM in `docs/ui-overhaul-2026-09-06/`; read UI_SYSTEM through its amendments
  - `spec/brand-canon.md` and `packages/tokens/tokens.json`
  - `spec/decision-log.md` from D358 on. D396 was the latest on Sep 26; check again.
- **Check for collisions.** Look at `git worktree list` and ACTIVE_WORK for any live lane that touches `index.html`, CSDesign or the native views. Don't overlap one; name it at the checkpoint.
- **First commit.** Save this prompt as `docs/planning/2026-09-27-impeccable-ten-prompt.md`, and add an ACTIVE_WORK entry that claims this lane.

**Stale guidance.** Read it, but don't follow it. Later rulings supersede AGENTS.md §11–12 ("Ember = live + the one primary action", "The brand mark is not final"), and they also supersede DESIGN_SYSTEM.md ("Ember means: LIVE, the one primary action" and the "older mark family"):

- **D358:** the CS pennant is the production mark.
- **D359 + F11:** ember marks competition (upcoming, live or finished) and the identity hairline, nothing else. Ordinary actions use `act`.
- **Gold** is earned only.
- **Secondary text** is opaque `mut`, never `dim` or faded.

Don't encode the stale versions anywhere. Propose the doc corrections at the checkpoint.

## Phase 1 · Impeccable context

1. **Setup.** Let Impeccable's setup run (`scripts/impeccable context`); it downloads its engine the first time. If the launcher fails, follow the skill's fallback and quote the error to me. If `$impeccable` doesn't resolve at all, stop and tell me to enable the plugin.

2. **`$impeccable init`.** Write PRODUCT.md as a compiled, cited view of the existing canon. It is not a new authority, and the canon wins any conflict. Treat these answers as my interview round:
   - **Users and job.** The users are amateur golfers in real friend groups who post real, handicapped rounds from anywhere, plus the Pro who runs their league. On the phone, at the turn and just after golf, the job is to post a round in seconds and see what it did to the season. On the web, at the desk, the job is to read the season and run the league. That split is D234: two clients, one product, two shapes.
   - **Mechanism.** Cup Season turns the rounds golfers already play into a season: standings, rivalries, a Cup Final or points-table endgame, and a record that accumulates. It asks for no extra work during play, and every points figure traces back to its rounds (§16). Cup Season keeps the ledger; the money moves between friends. It is not a shot tracker, a GPS, a swing coach, a betting app or a stats collector.
   - **Durable constraints.**
     - AGENTS.md §9–10 (the laws, the five-question filter, the language), as amended above
     - brand-canon, the tokens and UI_SYSTEM, plus the D305/D313 looks
     - one fact, one place (D360)
     - dark-first (D76)
     - the clients: an iPhone-only SwiftUI app on iOS 17+, so iPad checks are n/a, plus a single-file PWA
     - the repo is public: no real person's data goes into evidence
   - **Evidence on hand.** PIGL, the beta league, and the fixtures. No testimonials, press or customer claims exist; don't invent any.
   - **Accessibility.** WCAG AA contrast in both themes, 44pt targets, Dynamic Type through AX3, VoiceOver and Reduce Motion.
   - **Workflow.** buildPath is `code`. This is refinement of a committed world; make a comp only for a surface we agree to redesign.
   - **Platform.** The root PRODUCT.md is `web` (index.html) and carries the shared truth. `apps/ios/PRODUCT.md` is `ios` and holds phone-only scope. Run `$impeccable doctor --target apps/ios` as a report only, repairing nothing, and confirm that phone targets load the iOS guidance and `index.html` resolves to web.
   - **Gaps.** Mark anything the docs don't answer `(inferred — confirm)` and keep it for the checkpoint. Don't stop mid-phase for it.

3. **`$impeccable document`, scan mode.**
   - DESIGN.md's frontmatter mirrors tokens.json exactly, with no new values. It uses the project's own role names: `act`, ember, `gold`, `mut`, `pos`, `neg`, `cool`, the grounds, the identity pigments and the ceremony colors.
   - Its first line says it is generated from tokens.json and UI_SYSTEM, and that to change the system you regenerate it rather than edit it.
   - Take the qualitative language from brand-canon and UI_SYSTEM; mark anything unsourced PROPOSED.

4. **Surface briefs.** Give each family a mode:
   - **Operate:** the app.
   - **Persuade:** the door, `/get`, the public round, claim and invite pages, the share card and the App Store screenshots.
   - **Read:** legal, support and the rules.

   Carry BRIEF §31's per-surface character into each brief, so the surfaces don't all look the same: Home social, Profile identity, Course editorial, Season narrative, Event moment, History archive.

5. **Hooks and config.** Run `$impeccable hooks on` in the worktree. You may commit `.impeccable/config.json` and the critique snapshots. Never commit `config.local.json` or the hook manifests. `$impeccable live` is optional and web-only; never edit `netlify.toml` or the CSP for it.

## Phase 2 · Baseline, evidence first

Reach the checkpoint by Monday, September 28; the freeze is Wednesday. Baseline the launch path first (door → first round → post → share → Home), then everything else.

**Surfaces.**
- Start from ROAD_TO_TEN's 23 surfaces plus UI_SCORECARD's extras: events, pot, sheets, onboarding and web.
- Add what has shipped since: Scoreboard and the Book (D381), the course pages, the widgets and Live Activity, the share card, the public round and claim pages, `/get` and `/support`.
- Group them into families. Give each family a phone target and a web target wherever the surface exists on both.

**Captures come from fixtures only.**
- **Hatches.** Use the DEBUG hatches: `-cs_dev_appearance`, `-cs_dev_text_size`, `-cs_dev_look`, `-cs_dev_open`, `-cs_dev_home_state`, `-cs_dev_morning_review` with `-cs_review_scene`, and `-cs_dev_compete_selected`. Grep `-cs_dev_` in `apps/ios` for the rest.
- **Harnesses.** Reuse `docs/review/2026-09-25-morning/capture-native.py`, `capture-web.cjs` and `docs/design/compete-2026-09-24/capture*.py`.
- **Native matrix.** Dark and light; iPhone SE 3rd gen (375pt) and iPhone 17 Pro; default text and AX3. Add long-name, no-photo, empty, error, keyboard-up and offline states wherever a family has them. Pin the status bar at 9:41.
- **Web matrix.** 375, 402, 1280 and 1600 wide, in both themes, served on 8791, with the service worker and caches cleared first.
- **Missing fixtures.** A state with no fixture is "not captured, not scored". Never guess it; list it as a fixture gap in PLAN.md.

**The repo is public.**
- Commit a representative subset of the fixture captures to `docs/design/ten-2026-09-27/`, along with a manifest giving each file's sha256 (as capture-native.py writes it). Keep the full set in a local gallery outside the repo.
- Anything captured from a real account goes to `renders/`, which is gitignored.
- Use simulators you create yourself, never one of mine that is signed in. Never post, react, lock, invite or change data on any account.

**Instruments.**
- **`$impeccable critique <target>`,** for each family on each client.
  - On iOS targets, Assessment B's evidence is the simulator capture set, because the detector and browser overlay are web-only. Record that in Run Notes as the fallback signal.
  - Run the critiques back to back. Put each run's targeted questions in `docs/design/ten-2026-09-27/QUESTIONS.md`, then close the run with "Questions skipped: batched into the program checkpoint at the owner's request."
  - Commit the snapshots in `.impeccable/critique/`.
- **`$impeccable audit`.** Run the native audit over `apps/ios` and the web audit over `index.html`, `get.html`, `support.html` and `legal.html`.
- **The §29 panel.** Three fresh sub-agents, none of which wrote code, score every surface on H T Sp C B P R E D M from the captures alone. Give them ROAD_TO_TEN's three lenses: category, craft and owner. Report the median, and flag any disagreement over one point with your reading, in the format of ROAD_TO_TEN §1.

**Precedence.** Impeccable's findings are evidence; ratified D-entries and the tokens decide. These collisions are already known:
- the custom tab band (D269) vs ios.md's "no custom global nav"
- the three-voice type system (serif story, condensed board, mono record) vs "SF carries the UI"
- record-voice labels vs the craft floor's eyebrow ban
- dark-first (D76)

Judge each one by real user impact: 44pt targets, VoiceOver names and order, Dynamic Type scaling, safe area, Reduce Motion and edge-swipe back. Delete a label that only repeats its heading (one fact, one place); keep one that carries a fact of its own. A material conflict becomes a proposal, never a silent revert.

**Content ceilings.** ROAD_TO_TEN §4 found that emotion, premium feel and density are capped without real content: photographs, faces, live leagues. Never fabricate content to lift a score; the demo never fabricates faces. For each capped cell, name the content it needs and where that content could come from (§6-A).

## Phase 3 · Plan, then CHECKPOINT (stop here)

Write these to `docs/design/ten-2026-09-27/`:

- **BASELINE.md.**
  - At the top: launch-path blockers, meaning any P0 between the door and the share.
  - The §29 table: surface × dimension, with medians and verdicts.
  - Per-dimension means, compared with September 7.
  - Critique totals and P0–P3 counts for each target.
  - The audit score out of 20 for each client.
- **PLAN.md.** A ranked list of slices. Each slice gives:
  - the defect and its evidence
  - the cells it lifts
  - the Impeccable command
  - the phone-half and web-half files
  - the token and source changes, and the tests
  - one tag: PRE-FREEZE SAFE (small, verified, reversible, on the launch path) or POST-LAUNCH

  Re-check ROAD_TO_TEN §2's still-standing caps at the new HEAD, and fix systemic causes at their source first:
  - spacing literals vs the `space` tokens
  - type growth
  - 375pt and AX3 geometry
  - a light theme designed rather than inverted
  - state coverage
  - motion and haptics

  A surface still below 6 gets a redesign proposal inside the committed world, not polish. Design passes and structural builds ride separately (CLAUDE.md rule 3).
- **CONFLICTS.md.** The stale docs, the collisions between Impeccable and the canon, and any proposed decision. Draft each proposal in decision-log format as "PROPOSED D-next"; none is ratified.
- **A local before/after gallery,** in the style of the 2026-09-25 morning review.

Then reply with:

1. the baseline, in ten lines
2. the launch-path blockers, each with its minimal fix described exactly (files, what changes). Don't write the fixes yet.
3. the top slices
4. one batched set of at most five questions, drawn from QUESTIONS.md, each with two or three options and your recommendation first. Cover:
   - which PRE-FREEZE items go into the October 1 build
   - approval of PRODUCT.md and DESIGN.md, and of the stale-doc fixes
   - rulings on the conflicts
   - the content plan
   - anything off-limits

**Then stop and wait for "build it".**

## Phase 4 · Build, only after "build it" and only within the approved scope

For each slice:

- **Run the command.** Load the craft floor, then run the mapped command (polish, layout, typeset, clarify, harden, adapt, onboard, distill, quieter, colorize, animate, delight or extract) on the slice's target.
- **Both halves ship in the slice (D234).** One copy producer serves both clients, and each client keeps its own shape. The web is desktop-first (a sidebar and a wide two-column body), never the phone's tabs reflowed.
- **Tokens and generated files.** New values go into `packages/tokens/tokens.json`, then run `node tools/build-tokens.mjs`. Never hand-edit Tokens.swift, Markers.swift, Rpc.swift, BetaMark.swift or `__CS_VERSION__`.
- **Keep:**
  - every points figure's drill-down (§16)
  - the money sentence
  - the terminology: the Pro, Run it back, and named bands (never PvI or differential)
  - the five destinations
  - gameplay and photo-consent semantics
- **No database, RPC, Edge or scoring change.** If a fix needs payload data, it becomes a proposal.
- **bolder, animate, colorize and delight stay inside the world.** No glow, wash, glass, sports gradients, bounce or gamification (BRIEF §33). Motion conveys state, and Reduce Motion is honored.
- **Verify in bounded rounds,** following Impeccable's rule: recapture the same matrix, fix everything in one batch, confirm once.
  - Run the affected native suites, then the full suite at the end of the slice.
  - Run the browser suites in `tests/` and `npm run preflight` (0 failures, 0 warnings). The web console must be clean.
  - Never weaken a test that encodes a ratified rule.
- **Close the slice.**
  - Make one narrow commit with before/after evidence.
  - Re-run `$impeccable critique` on the family for a trend line, and let polish close the snapshot.
  - A surface rebuilt through new-work ends with Impeccable's finish review; report its disposition word verbatim.
- **Pre-freeze slices.** The ones I approve go on their own branch, cut from the launch candidate and done by September 29, so the release owner can take or leave each one.

## What done means

Say plainly when we're short. A claimed 10 without evidence is worse than an honest 8.

- **The §29 panel.** No cell below 9, and a product mean of 9.5 or better. Every cell below 10 names what stands between it and 10 (content, a ratified decision, or device or human evidence) and the proposal that would remove it.
- **Impeccable.**
  - Every critique target at 36/40 or better, with no heuristic below 3.
  - The native and web audits at 18/20 or better.
  - Zero open P0s or P1s.
  - Every remaining web detector finding either fixed or recorded as a verified false positive, with a reason.
- **The craft floor is green everywhere:**
  - contrast of 4.5:1 for text and 3:1 for large text and controls
  - 44pt targets
  - no clipping at 375pt or AX3
  - the keyboard never covers the primary action
  - correct VoiceOver names and order
  - Reduce Motion honored
  - both themes designed
- **Human proof is mine to run.** Prepare the timed unassisted-task sheet per the pilot protocol. A screenshot is not a usability pass.

## Never, without my explicit yes in chat

- Merge to main, push, or deploy (Netlify, Supabase or Edge).
- Archive or upload to TestFlight, or touch App Store Connect.
- Change the mark, the app icon or production brand assets.
- Add a dependency.
- Ratify a decision.
- Commit a real person's name, handle, round or email.

End every stop with the AGENTS.md §14F handoff. Every deploy owed stays "none" until I approve something.