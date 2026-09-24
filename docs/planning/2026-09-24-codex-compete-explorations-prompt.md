# Codex prompt · Compete explorations and the season ledger · 2026-09-24

Written by Claude at the owner's request. The owner's words:

> Explore and propose multiple revised Compete interfaces. Bolder displays of
> data and competition, more use of our ember and topo compete themes.
>
> I also think large leagues could use a full ledger so you can view the
> season holistically and look at points accrued by team or individual.

This is an **exploration and proposal pass**. You design and prototype
directions. You do not choose one for the owner, and you do not replace the
shipped Compete tab.

## Where you are

- Worktree: `/Users/fischbeck3/cup-season-compete-explore`
- Branch: `codex/compete-explorations-2026-09-24`, from `321ca3e`
  (`claude/owner-beta-release`, the line TestFlight **986** was built from)
- Before anything else, read `AGENTS.md`, `CODEX_START_HERE.md`,
  `DESIGN_SYSTEM.md`, and the dated notes at the top of
  `docs/design-designv1-implementation.md`. Then read
  `docs/planning/ACTIVE_WORK.md` for current state.

## Boundaries

- Commit locally to this branch only. **Do not push, merge, or rebase onto
  main.** The owner reviews first.
- No production actions of any kind: no `supabase db push`, no remote SQL, no
  Edge deploys, no Netlify, no `tools/asc.py`, no archive/upload/TestFlight.
- No migration files. If a direction needs data the client does not have,
  specify the read contract in prose (see "Data" below).
- Do not edit any other worktree, and do not touch the main checkout at
  `~/cup-season`. It is on a `codex/*` branch with uncommitted changes that
  belong to someone else.
- Release behaviour stays exactly as shipped. Every prototype is DEBUG-only,
  behind a launch argument in the style of `-cs_dev_compete_fixture`
  (`apps/ios/CupSeason/Compete/CompeteFixture.swift`).
- Use a simulator for captures. Do not sign in to production accounts. Use
  fixture payloads.

## What exists today (read these, don't re-derive them)

- `apps/ios/CupSeason/Compete/CompeteScreen.swift`: the tab root. There's a
  masthead on a `CSTopoField`, one `CSCompetitionBand` ember band for the lead
  season (F11), then quiet fescue slats with a trailing `CSFigure` rank.
  Ordering and sentences come from `CompeteRoot` in CupSeasonKit.
- `apps/ios/CupSeason/League/StandingsTableView.swift`: the season board.
  It's one `CSStandingsBoard` of `CSSlat`s. For fields over ten, it windows
  to leader, cut neighbours and you ±1, with a link to the full field.
- `apps/ios/CupSeason/Season/SeasonPage.swift`: the season room.
  `SeasonPane` has story, table, board, schedule, pot, album and rules.
- CSDesign: `Contour.swift` (`CSTopoField`), `Structure.swift` (the `ember`
  ground and `brandInk`), `Figures.swift`, `Board.swift`, `Brand.swift`, and
  `Generated/Tokens.swift` / `Generated/Looks.swift` (with their JSON
  sources).
- The web client is `index.html` at the repo root, in its own desktop-first
  shape (D234: the same sentences and payloads, but a different layout).
  `apps/mobile` is retired (D99), so ignore it. Cover the web half in the
  proposal doc only (how each direction and the ledger would sit on the
  desk). Prototype natively.
- Points data: `v_rounds_ranked` scores each round into each league.
  `v_squad_standings` is counting rounds plus the `season_adjustments`
  ledger (floors and bonuses from `close_month()`, each with a reason).
  Spec §16 says no points figure appears without a path to the rounds that
  produced it. `spec/spec-v1.0.md` is the source of truth for every scoring
  rule.
- Earlier Compete work, read-only: `~/cup-season-compete-review` (09-12,
  includes `compete-bold-{light,dark}.png`, an earlier "bold" pass),
  `~/cup-season-compete-consistency-review`, `~/cup-season-course-compete-review`,
  `~/cup-season-runback-topo-review` and `~/cup-season-contour-review`. Go
  further than they did, and say how each direction differs from what shipped.

## Rules the directions must respect, or explicitly ask to change

Read each one in `spec/decision-log.md`, `spec/brand-canon.md` and
`docs/ui-overhaul-2026-09-06/UI_SYSTEM.md` before designing.

1. **D359 and BRAND-02 (`tests/preflight.mjs`).** Ember is the competition
   colour and is reserved. Gold is only for things that were earned. Pos/neg,
   ink and the ground are never tinted by a look. That's why "more ember" is
   allowed: ember marks live competition. But it must still *mean* live
   competition. If ember is on everything, it means nothing. For each
   direction, state what earns ember and what does not.
2. **Topo follows the livery.** The owner said on Compete, *"topo can follow
   themes"* (`apps/ios/CupSeason/Post/PostCoverView.swift` ~L271). Topo can
   be bolder: denser, larger, carried into rows or the ledger, or used as a
   data ground. It must never lower text contrast. Measure every ink-on-ember
   and ink-on-topo pair in both printings (the `brandInk` note in
   `Tokens.swift` explains why ember flips ink between light and dark).
3. **One standing, one source.** Today's launch audit (F-7, on 986, in
   `~/cup-season-launch-audit/docs/audit/launch-2026-09-24/evidence/coord/phone-986.md`,
   read-only) found a 41–41 tie drawn three ways. The season table says
   "1st · Tied", Compete's hero says "2nd · level with Galen", and You says
   "2ND". No direction may add a fourth rendering. Every figure you draw must
   come from the same standing the table uses, and ties must read identically
   everywhere. If you find the root cause, write it up. Don't fix it on this
   branch unless the fix is contained to the prototype path.
4. **"Ledger" is already taken.** In this product, "the ledger" is the pot.
   D39's line is *"Cup Season keeps the ledger; the money moves between
   friends."* It's verbatim canon (`spec/brand-canon.md` §3, `MoneyCopy.ledger`),
   and `spec/design-review-2026-07-16.md` says the money ledger must never
   share a visual system with cup points. The owner used "ledger" for the
   points view. Use it as the working title, then propose two or three names
   that don't collide and flag the naming for the owner to rule on. Keep the
   points ledger visually distinct from `PotPane`.
5. Voice: `spec/voice-and-tone.md`. Past tense for finished weeks, true
   sentences only, and no stat that is guessed or padded.

## Deliverable 1 · Compete directions (3 or 4, genuinely different)

Each direction needs a name, a one-line thesis, and what it makes bolder.
Examples of the range we want, not a menu:

- **Scoreboard**: the lead season as a full-bleed ember scoreboard with big
  figures (rank, points, gap to the leader, weeks left) and a live movement
  line.
- **Race**: a season shown as a race over time, with running totals or a
  bump chart on a topo ground, where you can see your line.
- **Topo room**: every season row carries its own topo, following that
  league's livery, and ember is kept for the one that's live this week.
- **Broadsheet**: a dense, sports-page table of every season you're in, with
  figures first and prose second.

For each direction, prototype these screens:
- the Compete tab root
- the season room's standings head
- the ledger entry point

Draw each against these fixtures, which you add to `CompeteFixture` and
`SeasonFixture`:
- a two-golfer solo season, including the **41–41 tie**
- a 16-golfer solo season
- a 4-squad team season, with 4 golfers per squad
- an upcoming season with no standing
- a finished season with a champion
- Compete with three seasons and a moment

Capture every screen in light and dark, on a small phone (SE class) and a
standard phone, plus one accessibility Dynamic Type size.

## Deliverable 2 · The season ledger for large leagues

This is a holistic view of the whole season. It shows points accrued, week by
week, by individual and by team.

- **When it appears.** Propose a threshold, such as field size or squads
  present, and justify it. Say what small leagues get instead.
- **Views.** Individual and team, with a way to switch or filter. It needs a
  week-by-week points matrix (golfers or squads × weeks), cumulative totals,
  and the running race over the season. Where it's useful, add a per-golfer
  contribution to their squad.
- **Drill-down.** Tapping a cell opens that round's receipt or scorecard.
  Nothing is a number without a receipt behind it.
- **Adjustments are rows too.** Floors, bonuses and byes from
  `season_adjustments` appear in the week they were assessed, with their
  reason, so every total adds up on screen. Its name is "ledger" in the
  schema, so be clear about which one you mean.
- **Scale.** Show how it reads at 16 golfers × 15 weeks on a phone: frozen
  names column, horizontal weeks, and how figures abbreviate. Show dropped or
  best-N rounds, byes, and weeks with no round honestly, without zeros that
  look like scores. Read the season's scoring rules from the settings; don't
  assume them.
- **Emphasis.** Show how ember and topo are used, and how the ledger stays
  visually separate from the pot.
- Prototype it natively for at least two of your directions.

## Data

Before you design each figure, check whether the client already has it
(`Me`, `Standing`, `Squad`, `LeagueRoomRows`, `CupSeasonKit/Generated/Rpc.swift`).
For anything missing, such as per-week points per member or per-squad
contribution, write the read contract you'd want. Include the RPC name,
arguments, the rows it returns, how best-N and dropped rounds appear, who can
read it (RLS: members of the league only), and an estimate of payload size at
16 × 15. Do not write the migration.

## Output

1. A proposal doc at `docs/design/compete-2026-09-24/PROPOSAL.md`. Include:
   - each direction and its thesis
   - what earns ember, and contrast measurements
   - how each direction renders the tie
   - the ledger design and threshold
   - the data contracts
   - effort and risk for each direction
   - the rulings the owner has to make (ledger name, any D359 exceptions, the
     threshold)
   - a ranked recommendation with reasons
2. A new review gallery at `~/cup-season-compete-explorations-review/index.html`,
   with real simulator captures, grouped by direction, so the owner can compare
   the directions side by side. Follow the same pattern as the earlier
   `~/cup-season-*-review` galleries. Don't write into any existing gallery.
3. The prototypes, as DEBUG-only code behind launch arguments, committed on
   this branch. Keep the native package tests, `node tests/preflight.mjs`,
   and a Debug build green. Report any that are red, with their output.
4. At the end, add a short entry at the top of `docs/planning/ACTIVE_WORK.md`
   saying what was built, where it is, what's unpushed, and what the owner
   needs to decide.
5. Commit with clear messages. **Don't push.**

Report back in plain language with:
- where the gallery and the proposal are
- the directions
- your recommendation
- the owner's open rulings
- anything you found broken along the way
