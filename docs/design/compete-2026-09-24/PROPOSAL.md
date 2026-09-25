# Compete, with the competition in view

**Selected and implemented:** the owner approved Scoreboard + the Book's Weeks view, with Race inside the Book, followed by normal app code and a read-contract migration. The branch is pushed, the database applied, and the web app deployed through Git → Netlify; [release evidence](DEPLOYMENT.md) records the result. TestFlight is held. See [the selected build](SELECTED-BUILD.md) and D381. The proposal and its original captures below are preserved as the exploration record.

September 24, 2026 · local design study · owner review, not a shipping decision

**Three native directions: Scoreboard, Race, and Broadsheet.** All three open the same fixture season and the same points receipts. My ranked recommendation is **Scoreboard first, Race second, Broadsheet third**. The Book is useful independently of that choice: ship its weekly table before treating a historical race as reliable.

- Review gallery: `/Users/fischbeck3/cup-season-compete-explorations-review/index.html`.
- Worktree: `/Users/fischbeck3/cup-season-compete-explore`.
- Branch: `codex/compete-explorations-2026-09-24`, local only.
- Governing brief: [the complete prompt](../../planning/2026-09-24-codex-compete-explorations-prompt.md). The owner's name ruling is settled: **the Book**. Code types for it use `SeasonBook…`.

## What changes from the shipped tab

The shipped Compete root puts a neutral contour masthead over one F11 ember season band, then quiet slats. Its rank is the loud figure; points and the course of the season remain behind the door. The earlier September 12 “bold” captures enlarged the name and rank but kept that basic list. The consistency gallery regularized the same season/event doors; the course/Compete study organized intents and lengths; the runback/topo and contour reviews explored the background and return paths. None supplied a whole-season, member-by-week view.

This study changes the composition, not just the colour. Scoreboard gives the current points total the display tier and gives the season table larger numeric rows. Race gives the season's accumulation actual spatial width and height, with visible time left. Broadsheet puts all memberships into one tight comparative table and then prints the leading field. Each opens a season standings head and a visible door into the Book. Multi includes three seasons and a separate upcoming moment; its lower capture verifies that the moment remains reachable.

### The hierarchy conflicts, stated

The brief explicitly asks that ember mean **live competition**. D359 says active competition; its F4 application leaves ordinary standings quiet. The newer token source's F11 note broadens competition identity to upcoming, live **and finished**, and the shipped `CSCompetitionBand` follows that. Old `UI_SYSTEM` §2.4 also prohibits a broad ember field, which F11 demonstrably superseded. The prototypes follow this task's stricter live-only brief, use F11's existing broad-band construction, and do not change tokens or canon. Keeping upcoming/final heads neutral is a proposal requiring the owner's selection, not an assertion that production is wrong.

`AGENTS.md` / `DESIGN_SYSTEM.md` still summarize the former look substitution of `brand`; D359 and the current `Theme.swift` instead substitute `act`. The prototype reads `brand` for live competition and livery accents only for terrain. The mark's older “open” language is also superseded by D358 in brand canon. No mark is changed here.

## 1. Scoreboard

**Thesis:** opening Compete should feel like walking up to the board and finding your points in large type.

A full-width ember lead carries the season, one factual gap sentence, a large points figure, and the table's standing. Terrain takes a broad, empty strip of the band rather than sitting behind numerals. Other seasons stay neutral and smaller. In the season room, large point columns and taller standings rows make the whole field feel consequential. The Book enters directly below the head and initially opens **Weeks**.

**Proposed exception to the brief’s livery-topo rule:** the full ember band uses `brandInk` contours, keeping that band to two colours. League livery colours return in neutral heads and the Book. This is an art-direction proposal, not a contrast necessity, because the contour strip contains no text. The owner must approve this exception or require livery-coloured contours in the ember band too. Race follows livery colour on its neutral terrain and plot; Broadsheet follows it at the season head.

**What earns ember:** the lead season while active; the current week header in the Book. It does not colour the Book door, ordinary navigation, missing data, a pending season, a finished season or a moment merely scheduled to happen. A champion alone earns the gold caption. Points and ranks are not coloured by performance.

**41–41:** both standings rows say `1st · Tied`; the root repeats precisely that standing for you. The sentence is “Two golfers. The lead is shared.” There is no fabricated leader, gap or movement.

**On the desk:** a wide board above the other seasons, with points, standing and the supported gap on one horizontal line. The season page can put the field beside the Book; the Book gets all 15 columns when space allows. The desktop shape uses the same facts and copy under D234, not a stretched phone screenshot.

**Effort and risk:** approximately 3–5 engineering days for production composition and shared standing integration, plus the common Book work below. Lowest visual risk: it extends an existing band and existing type roles. Its main cost is vertical space on an SE or at AX3. The entry captures deliberately show the door after scrolling instead of claiming it is always above the fold.

## 2. Race

**Thesis:** see where the season's points came from and how much of the calendar is still open.

The root is a named race over 15 weeks, drawn on a quiet livery terrain ground, rather than an orange scoreboard. Solid/dashed lines distinguish competitors without relying on colour. The current-week line is ember. The season head carries the same race, then the standings and the Book door. The Book opens **Race**, with a “Follow” selector: leading three or any named golfer/squad alongside two leading comparisons. Weeks and Totals remain one tap away.

**What earns ember:** the current-week rule and current-week table head of an active season. The race lines stay ink. Terrain follows Claret or Two Teams in these fixtures; livery cannot repaint the signal. Upcoming seasons have no fabricated chart. A finished season has no current-week signal.

**41–41:** the equal cumulative lines coincide honestly, with separate named legend entries; your standing and both table rows say `1st · Tied`. No line is nudged to imply a different total.

**An essential limit:** the prototype is titled **Points counting today**. It groups currently counting rounds by the week played and adjustments by the week recorded. A later best-N displacement can restate an earlier week. That is how today's total adds up; it is **not** a reconstruction of what the table said on each historical Sunday. Missing weekly snapshots must remain gaps in a true historical race. There is no supported movement sentence in the fixture, so none is manufactured.

**On the desk:** the race can be a broad horizontal plot with a named competitor selector to its side, and the matrix beneath. Selecting a line filters the existing receipt list; selecting a week narrows the time column. Use the same current-contribution versus historical-snapshot labels as the phone.

**Effort and risk:** approximately 5–8 days beyond the common Book work. Most distinctive long-term direction. Highest semantic risk: a familiar-looking line chart invites an unsupported historical reading. Equal lines need textual keys and exact values; do not use livery colour as the only differentiator. Production adoption should wait for the data semantics ruling below.

## 3. Broadsheet

**Thesis:** print the entire competitive life on one compact sports page.

The root is a comparative season table: season and standing left, points right, thin ember rails on active seasons. With three memberships, they fit far more compactly than either hero direction. The leading field follows as a short box score. The season room is a dense name/rank/this-week/total table. Terrain is an editorial strip at the season head; it does not break the table's alignment. The Book opens Weeks with its most compact head.

**What earns ember:** active-season rails and the current Book week. All other rules and totals are ink. Final and upcoming rows are neutral. Gold is reserved for an earned champion, not table chrome.

**41–41:** `1st · Tied` appears in the season row and both golfer rows. Equal points have equal rank; alphabetical order is only a stable display order.

**On the desk:** this is the most natural desk composition: seasons across the top, full field below, then the Book's 15-column grid and an adjacent receipt drawer. Keyboard and screen-reader table semantics would be required; do not reproduce the phone's nested scroll gesture on desktop.

**Effort and risk:** approximately 3–5 days beyond the common Book work. Best for several simultaneous leagues and the smallest phone. It trades some season atmosphere for scanning speed. At accessibility sizes, names and standing labels wrap naturally, the optional weekly column disappears, and headings take their full width.

## The Book

### Entry and threshold

Recommend a prominent **Open the Book** door for **10 or more golfers, or any season with squads**, including a four-squad season. Ten is the point at which reading the field across weeks is meaningfully harder than following two people; it also complements the shipped standings table's windowing above ten. The difference between `>= 10` here and the table's `> 10` is intentional and open to the owner, not an accidental shared constant.

Small solo seasons get **Rounds & points**: one standing per golfer, tapping through to that person's rounds and adjustments. No combined “82 points” figure for two golfers tied at 41. A pending season has no standing or faux zeroes and explains when the Book becomes available. Finished large seasons retain it as a record.

The threshold controls the prominent door, not permissions or scoring. The owner's ruling should settle whether small leagues also get a secondary link into the full Book.

### One season, three views

- **Weeks:** 16 golfers × 15 weeks, or four squad rows. Names and season totals stay fixed while the week columns scroll horizontally. Weeks derive from the actual first tee, not an assumed Sunday. The names column is 140pt; week cells are 64pt wide and at least 64pt high, with a synchronized row height. Shortened given names make long surnames readable; receipts retain full names.
- **Totals:** the same grid accumulates the included contributions through each week. Empty history is `—`, not a pretend zero. Future weeks are `•`, not projected totals. All figures remain exact integers; there is no `1.2k` rounding that could hide a reconciliation error. If a future supported format needs more digits, widen cells rather than round the value.
- **Race:** currently counting contributions over the same weeks, with the semantic limit described above. Select Squads or Golfers; filter golfers to a named squad. That filtered golfer table is the squad's contribution view. Squad-only adjustments must be separate rows and must never be divided among members by the client.

At **AX3**, the matrix becomes a week menu and a list of full names with that week's exact contribution. This preserves the same receipts while avoiding a 15-column, enlarged horizontal sentence. The capture set covers this mode in both printings.

### A number always opens its evidence

A cell opens all its rounds and adjustments. A week can contain more than one round; it must never route arbitrarily to the first one. Tap a row total for all included and displaced entries. Tap one entry for its receipt. The local receipt explicitly states when gross/rating/slope/holes are not supplied; it does not invent a scorecard. Production should use the existing round receipt, scoped to that league's scoring lens.

`D` means only dropped rounds; `12D` means 12 included points with a dropped round still in the receipt. `B` is a recorded bye. `*` marks an adjustment, including a zero-point adjustment when one was actually recorded. `—` means no round or adjustment, and `•` means future. Spoken labels use those words, not “dash points.”

Adjustments have their own rows below the matrix, with the assessed week and the reason. The fixture contains an August floor deduction in week 9, July/August byes, and a finished-season historical bonus. The historical bonus is a deliberately imported old record, **not a revived hybrid mechanic**. The rows say “Already included above”; they are not added twice. A squad filter also scopes these adjustment rows, so another squad’s floor never appears as part of the selected contribution total. Week 9 starts August 31, so a September 1 assessment belongs there even though it applies to August.

Month caps and floors come from the room settings. They do not reset every week. The fixture authors count flags and seeds the real `LeagueRoomModel`; the prototype sums those facts and never implements a new best-N scorer. Tests reconcile every row total, weekly sum and squad contribution against that room model.

### A different visual object from the pot

The Book uses board type, week columns, rank rules, restrained terrain and an ember current week. It shows no currency, payout, collection state, money total or PotPane settlement treatment. There is no money copy on screen. The already settled naming does not appear in the list of open decisions.

## Data: what is here, what is missing

| Source already in the client | Usable facts | Missing for this design |
|---|---|---|
| `Me.Season`, `Me.Standing`, `Me.Squad` | dates, week number/count, own points, rank, leader/gap, names, optional previous rank | complete field, reliable shared tie semantics, all member-week contributions |
| `LeagueRoomRows.Settings`, members and squads | cap, floor, structure, finish, roster and current squad seats | authoritative historical attribution after transfers; complete rule-version context |
| `LeagueRoomRows.RankedRound` / `v_rounds_ranked` | round id, member, played date, points, month rank, floor credit, scoring lens facts | an explicit included contribution and exclusion reason, reliable full-season read rather than a limited list |
| `LeagueRoomRows.Adjustment` | kind, points, member/squad, affected month, reason | assessed timestamp/week is absent from the current Swift row |
| `LeagueRoomRows.Snapshot` | week and standings JSON, optional capture time | guaranteed complete weekly coverage; an explicit missing-snapshot state |
| generated `Rpc.swift` | existing round/room/scenario contracts | no `season_book` contract; do not hand-edit the generated file |

### Proposed read contract, in prose only

**RPC `season_book(p_league_id uuid, p_season_id uuid)`**, returning one versioned snapshot. These are proposals, not installed functions or migrations.

1. **Envelope:** contract version, league/season ids, generated timestamp, season status and timezone, first/last dates, current week, explicit complete/partial coverage, canonical standings revision, and scoring settings as applied to this season (cap, month basis, floor, penalty, eligibility, finish). A completed season must use its locked season facts, not the next season's edited settings.
2. **Weeks:** week ordinal, starts/ends dates, active/future flag. Boundaries derive server-side from the real first tee in the league timezone. Include partial final weeks honestly.
3. **Competitors:** member and squad ids, display names, squad membership/attribution, own row flag. Canonical standing carries points rank, tied flag, display order, optional competition tiebreak rung and qualification seed as separate fields. Name is a display-order key, never part of a points tie calculation. Round and adjustment attribution is decided by the server's actual competition rules, not guessed from today's roster.
4. **Entries:** stable entry id; round id or adjustment id; member/squad attribution; played date or assessed timestamp; affected calendar month; display week; scored points; included contribution; count state (`counting`, `dropped`, `ineligible`, `adjustment`, `bye`); month rank/cap; reason; and receipt destination. Dropped rounds remain full rows with their original scored points and zero included contribution. Forfeits remain explicit adjustments rather than client rewrites of rounds. A `month_closed` sentinel is not a score row. An unknown old assessment date gets an explicit undated-adjustment section and remains in the total; it is never silently placed in the month-ending week.
5. **Aggregates:** authoritative member-week and squad-week contributions, cumulative values, current totals and receipt-entry ids. Return true zero, missing, future and unavailable distinctly. Include squad-only adjustment rows so member contributions plus squad adjustments equal the squad total. A total with partial coverage must display the coverage warning and must not pretend to reconcile.
6. **Optional historical series:** captured weekly totals/ranks with `captured_at`, scoring revision and missing flags. Never fill missing history from today's best-N set. If existing snapshots cannot support the season's start weekday, do not relabel the Sunday capture as an exact close-of-week standing.

**Access:** authenticated members of that league only, including historical seasons they are authorized to read. Check membership inside any security-definer function; pin its search path; revoke public/anon execution, grant authenticated explicitly, and retain table RLS. A client-supplied member id does not confer access. The ordinary round receipt must preserve league/member privacy. Reads only; no writes or new collection from golfers.

**Size at 16 × 15:** 240 member-week cells, 60 squad-week cells when applicable, roughly 240 rounds at one per golfer per week plus 10–30 adjustment rows. An illustrative 300–400 bytes per entry plus ids/references, cells, names and settings is **about 120–180 KB uncompressed JSON**, approximately **15–35 KB compressed** depending on names/reasons. This is an estimate, not a production measurement. Several rounds per week can double or triple the entry section; load scorecard details on drill-down. A production contract needs a measured limit/pagination design before extending to hundreds of golfers; never silently truncate a season and retain its full total.

**Shared standing prerequisite:** add the canonical standing fields to the existing home/room reads or introduce a shared read used by both. Both web and native must consume that same definition. This study does not add a root-level per-league query waterfall as a production solution.

## The 41–41 defect: code-level cause

The supplied phone audit's F-7 is reproducible from source without a production query:

- `20260906090000_the_strip_has_its_own_facts.sql:336` ranks individuals over **points descending, display name**. At 41–41, Galen and Jerecho have different ordering tuples and therefore different `rank()` values. Squad ranking has the same name tie-break at line 295. These are the latest checked-in `native_home()` definition's windows.
- `CompeteRoot.swift:217` reads `Me.Standing.rank`; it does not recompute the table's points rank. `CompeteScreen` hands it to the lead band.
- `StandingsTableView.swift:88` uses `StandingsMath.competitionRanks` on the displayed points. Equal points receive equal ranks.
- `LeagueRecord.finish` independently returns sorted-array index + 1. That is another path by which equal points become different finish positions.

This explains the root/table disagreement without invoking a real scoring tiebreak. It does **not** establish which path produced every live story/seed sentence in the audit, or that a qualification seed should be erased. The production follow-up needs the owner to distinguish points rank, qualification seed and final tiebreak result, then make the surfaces agree. No historical migration, production producer, Compete screen, You record or shipped standings renderer was changed here. All prototype rank labels use the actual room teams and the table's existing `StandingsMath`.

## Contrast and terrain

Measured from **current** `packages/tokens/tokens.json`, not the older hexes printed in the orientation documents. Reproduce with `python3 docs/design/compete-2026-09-24/contrast.py`; complete output is [evidence/contrast.txt](evidence/contrast.txt).

| Actual pair | Dark | Light |
|---|---:|---:|
| `brandInk` on ember | 5.27:1 | 5.76:1 |
| primary ink on page / band / raised row | 16.05 / 14.10 / 11.60 | 15.49 / 14.02 / 12.29 |
| secondary ink on page / band | 7.07 / 6.21 | 5.85 / 5.30 |
| primary ink over Claret topo at a08 on page | 14.81 | 13.57 |
| secondary ink over Claret topo at a08 on page | 6.52 | 5.12 |
| primary ink over Two Teams topo at a08 on page | 14.63 | 13.72 |
| secondary ink over Two Teams topo at a08 on page | 6.44 | 5.18 |

These cover both themes for Scoreboard's band, Race's plotted ground, Broadsheet's tables and the Book's active week. Terrain at a56 is allowed in **empty strips only**. Secondary text over it would fail (2.72–2.83 dark; 1.88–2.07 light). Similarly, `brandInk` over the a24 terrain stroke on ember would fall to 3.51/3.65. The implementation separates those strips from every text block; they cannot sit behind text when Dynamic Type grows. That separation is part of the design, not an unmeasured opacity promise.

## Scope, verification and evidence

Every new Swift type is under `#if DEBUG`; the root requires `-cs_dev_compete_exploration`. The exploration route skips session startup, look loading, push sync, telemetry foreground handling and URL handling. Fixtures never sign in or load production room data. Release follows the original RootView and startup paths. No token sources, generated files, backend files, migrations, web client, version strings or production assets were modified.

The abandoned run's fixture model, reconciliation approach and receipt scaffolding were retained. Its nearly identical heads, generic Book type names, labels, all-tied large-field scores, single-round cell assumptions and small-league combined view were corrected. Fixture scoring flags remain authored facts.

Capture and verification results are recorded in [VERIFICATION.md](VERIFICATION.md). The gallery holds original simulator PNGs and manifests with launch arguments, device ids and SHA-256 checksums. `capture.py` reproduces them only on an already booted simulator; it does not erase or boot someone else's device. `gallery.py` builds the local review page from those manifests. No photograph is an HTML mockup or an AI-generated screenshot.

### Additional shared-component defect found

`CSFigure` with `over: .ember` renders its small label using `brandInk` at a56. Measured over current ember, that is **2.72:1 dark / 2.86:1 light**, below the small-text requirement. The Scoreboard prototype draws its figure's label at full `brandInk` (5.27/5.76) using the same type and rule tokens. The shared production component is untouched; it needs a separate contained fix. This was found in the simulator, not hidden by measuring only the large numeral.

## Ranked recommendation and owner rulings

1. **Scoreboard + the Book's Weeks view.** The clearest increase in competitive presence, grounded in the existing F11 band. It puts real stakes on the page while the full field and receipts stay immediately available.
2. **Race.** The strongest expression of a season unfolding, but only if the owner accepts the explicit “counting today” semantics or sponsors a trustworthy historical series. It can first live inside the Book while Scoreboard leads Compete.
3. **Broadsheet.** Best at several memberships and large fields, particularly on desktop. Choose it first if comparison speed matters more than a dominant lead season.

**Common production effort:** approximately 6–10 engineering days for the read contract, authorization tests, reconciliation, loading/failure states, existing-receipt integration and two-client Book implementations, after standing semantics are settled. Estimates are additive ranges for review, not commitments; a true historical reconstruction is excluded and needs a separate investigation.

**Still for the owner:**

- Which direction should proceed, and should Race first be an optional Book view?
- Confirm the live-only ember scope in this study, or retain F11's broader upcoming/final competition identity. No new D359 exemption is required for the live-only prototypes.
- Approve or reject Scoreboard’s monochrome contour exception inside its full ember band; the other terrain follows league livery.
- Approve `>= 10 golfers OR squads` for the prominent Book door; decide whether small solo leagues also receive an optional full Book link.
- Approve “counting today” reconstruction, or require actual historical snapshots. Do not approve a historical-looking chart without approving that meaning.
- Rule the shared display relationship between points ties, qualification seeds and final tiebreaks. Recommend displaying them as separate facts rather than quietly using name order as rank.

Naming is closed. This proposal does not request permission to rename the Book, change the competition rules, revive hybrid scoring or ship any prototype.
