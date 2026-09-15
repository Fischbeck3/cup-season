# Phone review: course cards, round states, color and appreciation

2026-09-15. Owner feedback captured by Codex on `codex/brand-parity-brief-2026-09-14`. Documentation only; Claude retains implementation ownership. No screenshots or account data committed. Source inspection used the current `cup-season-brand` checkout; screenshots are observations, not proof of its installed version.

## Owner direction and decisions still open

- Track the scheduled-course graphic and confusing round-points versus total-gain copy from the preceding review.
- Rethink the course's whole-scorecard organization and how saved courses/rounds are understood.
- Audit misplaced ember: the owner sees it on a Home bag icon but not in Compete.
- **New owner direction:** replace the reaction menu with one appreciation action, and redesign how it is communicated/notified. Subsequently approved: **option A, quiet icon + count**, with **applause / applauded** vocabulary. This supersedes the earlier multi-icon and visible-text-button directions. Historical-data treatment and push policy remain proposals, not activated delivery.

## Findings and proposed acceptance

### F1 — Course scorecard selection

`CourseWholeCardScreen` in `CourseCardLeaf.swift` loops through `book.tees` and expands one tee inline. The selected card can therefore sit below several other rating variants. `CourseBook.swift` documents the upstream ordering by holes and descending course rating; that ordering is not a golfer's selected tee. Front/back paper leaves themselves are useful; the surrounding selector hierarchy is the problem. Per-hole yardage is available in the model but absent from the leaf's displayed rows.

Proposal: course heading → selected tee and rating category control → that tee's concise facts → front/back card. Put other tees behind Change tees / Compare tees. Show yardage when actually available. Preserve distinct men's/women's ratings; never infer the desired rating category from a name or avatar. An explicitly selected plan/round tee wins; otherwise offer a deliberate choice rather than silently presenting the longest as the golfer's preference. Use stable tee identifiers and preserve offline support.

Acceptance: opening from a plan retains its exact tee/category; changing tees changes the entire facts/card together; unknown/incomplete cards are explicit; no ten-screen rating list before the chosen card; small-phone and enlarged-text readability.

### F2 — Saved course versus round lifecycle

`CourseBook.savedLine` describes the device's offline course copy, not a saved playing round. The whole-card screen promotes that storage status beside course facts. The owner's phrase "saved rounds" may cover both; audit the whole journey rather than silently choosing one interpretation.

Proposal: distinguish a saved course (reference/offline availability), a planned round (date/time/people/tees), an in-progress round or unfinished draft (resume), and a posted round (factual record/receipt/competition impact). These are presentations of existing objects, not authorization for new tables. Use "Available offline · updated today" as proposed secondary course copy. Course-reference cards must remain distinct from a golfer's played scorecard. Preserve plan-to-post context, explicit draft restoration and offline freshness information.

### F3 — Scheduled-round visual and points copy

`CSDrawnCard` encodes yardage as height and par as width, with par fallback when yardage is absent. The scheduled sheet does not make that encoding clear. Its "three that decide it" selects the lowest stroke indexes, not a prediction of decisive holes.

Proposal: compact course invitation with existing paper/fescue identity and supporting topo; people, time and selected tees lead. Full scorecard behind View scorecard. Credited, authorized course photography is optional; no invented aerial map or course contours presented as geography. Remove the unsupported decisive-hole headline.

`RoundWorth.gain` is maximum incremental counting gain, not the round's earned points. Explain earned points and replacement separately: a possible 12-point round replacing a 5-point counter increases the total by 7. Combine matching league explanations only when actual rules, date and counters agree. Respect 9/18-hole scoring and do not reuse an eighteen-hole ceiling as a nine-hole promise. No scoring-rule change.

### F4 — Ember audit

`HomeWireBag` still draws its bag glyph with `cs.brand`. Correct ordinary bag/activity decoration to the appropriate neutral or ordinary-action role. Existing owner ruling: ordinary Compete standings/navigation may stay neutral; active competition carries restrained ember wherever shown, including Home. Compare the same active clash in both locations, plus finished and noncompetitive states. A routine plan is not automatically competition. No blanket orange repaint of Compete; record any proposed broader Compete identity change separately.

### F5 — One appreciation action: option A approved

**Owner-approved 2026-09-15:** option A from the [comparison study](../brand/references/2026-09-15-applause-options.png): one recognizable two-hand applause icon plus a count, no visible button capsule and no persistent word beside it. Resting: outlined muted icon. Selected: filled green icon, optional light haptic. Keep at least a 44pt touch target. Tap to give applause, tap again to undo; the count opens the people who applauded. The enlarged study is a composition reference, not production icon geometry or an exact token-color source; implement a code-native glyph within the existing icon system.

**Approved vocabulary:** applause (noun), applaud (action), applauded (completed action). Do not ship "clap", "clapped" or "Clap sent" copy from the comparison study. First-use feedback: "Applause sent". Accessibility: "Give applause" / "Remove applause", exposing selected state and count. Activity: "Alex applauded your round" / "Alex and 2 others applauded your round". People list: "Applause". No permanent "Applauded" label in the feed. Comments remain for conversation. Applause appreciates participation and connection, not necessarily a good score.

Proposed identity: one golfer's appreciation per round across league copies, consistent on Home, board and receipt. Audit `HomeSocial`, `BoardKudos`, `post_kudos`, their permissions and uniqueness before changing writes. Existing data includes profile/member identities and emoji values; do not silently delete or sum all historical reactions. Prepare explicit deduplication/migration semantics and a shared backend contract. Historical appreciation changes must never generate new notifications.

Proposed communication: immediate local selected feedback; durable in-app activity such as "Alex and 2 others applauded your round" linked to that round and its people. Group by round and distinct actors. Push is separately opt-in and batched; no alert for each tap, own activity, undo/re-add, retry or backfill. Exact batching/cap and audience rules need a recorded decision. Honor existing visibility, mutes, removal and access changes. Reuse and audit notification infrastructure; do not claim APNs delivered because an event or route exists.

### F6 — Pride bet: meaning, placement and agreement

**Owner observation, 2026-09-15:** the pride-bet composer looks engaging but its purpose and place in the app are unclear. `ForfeitCopy` asks for a name, prose terms and a prose settlement trigger, then says nobody gets notified. `create_forfeit` records the parties and those words; an optional league/event/planned-round reference supplies context. Creation does not ask the other golfer to accept. `settle_forfeit` allows a party (or the applicable Pro) to name the winner manually; it does not interpret the prose condition into scoring or automatically award season points. The D299 rename was a terminology repair; D64/D242 and L-20/L-22 describe the underlying record-only behavior.

Proposal: make this an optional agreement attached to a competition the golfers understand, such as an existing clash, event or an explicitly defined game for a planned round. Entry from a person should select that context before asking for terms. Lead with who, what decides the winner, what is on the line and how the result is confirmed; name optional or generated. Example: existing clash → "Winner picks our next course" → opponent reviews and accepts → result from the actual competition, or explicit confirmation where the app cannot establish it → retained in the rivalry/round record. Avoid invented handicap comparisons, automatic awards and a generic text field masquerading as a scored contest.

This is a **proposal**, not an approved mechanics change. A proposal/acceptance lifecycle, direct invitation notification and authoritative settlement are changes to today's record-only/no-push contract. Record a decision and define permissions, decline/edit/cancel and dispute/correction behavior before implementation. Preserve existing pride-bet records. If the product retains record-only behavior, label it honestly as recording an agreement made elsewhere; do not present it as sending a challenge. Do not activate notifications or modify the frozen release from this finding.

Acceptance proposal: a first-time golfer can say what the button creates, whether the other golfer has agreed, what decides the winner, who confirms it, where it appears later and whether it affects league points. Both clients show the same lifecycle. Naming alone will not close this finding.

### F7 — Play a person: misleading dates and lost golfer context

**Owner observation, 2026-09-15:** opening Play from a golfer's profile offers “This Saturday,” which sounds like a date restriction. The weekly choice feels like another pride bet. The live choice opens a group containing only the owner; the selected golfer must be selected again.

Source inspection at `a8b3fe3d`: native `CalloutLength` hard-codes “This Saturday,” but `MainTabView.takeLength` only sets `presenter.showLive = true`, dropping its `who` argument. Web `csAskTheLength` similarly switches to Play without carrying its `pid`. This is confirmed context loss on both clients, not evidence that play is restricted to Saturday. The season branch also opens a generic wizard without passing the person; include that route in the continuity audit.

The current native weekly branch opens `CalloutSheet`, not `ForfeitSheet`. Its competition/date line is followed immediately by “What's on it?” and “A pride bet,” with no-stake selected by default. Thus the observed confusion is supported by the composition, but a route substitution has not been reproduced. The installed build's exact behavior remains to be walked. The web length handler calls `call_out` directly with no stake, a further review/confirmation disparity. `defaultClose` selects Sunday and can skip to the following Sunday when fewer than three days remain: “One week” is not an exact duration. Show the actual closing date from the shared rule; do not silently change that rule.

Proposed presentation: **“Play with [name]”** → **“Play a round”** (one round together), **“Go head to head”** (each posts a round before the stated closing date), **“Start a season”** (rounds over time). The round path can use the existing now/plan choice, carrying the person through either path. No weekday promise unless the golfer actually chooses that date. Retain the established competition comparison and explain it plainly before optional stakes; do not invent a new scoring rule. Keep any pride agreement contextual as described in F6.

Requested continuity behavior: entering live setup from a person preselects that person's stable profile identity in the proposed group alongside the owner, removable before starting. Use the existing handicap producer; do not copy a displayed handicap into a fabricated playing handicap. Opening or cancelling setup must not create a round, notify the person or assert that they accepted. Preserve an existing live round/draft and handle an already-selected golfer, full group, failed lookup and account change explicitly. For a season, preserve the intended invitee without silently enrolling them or bypassing consent.

Acceptance: walk profile → round now, profile → planned round, weekly contest and season on both clients. Verify opponent identity across navigation, course/tee changes, back/cancel/reopen and persistence; no duplicate selection or stale opponent in generic Play. Assert writes occur only at the existing confirmation boundary. Prove weekly setup states its actual deadline, scoring basis and invitation state before optional stakes, and that no-stake remains a complete path. Capture narrow-phone and enlarged-text screens. Update R-F/D237 copy rules and their pinned tests together once the replacement wording is agreed; the old wording is explicitly pinned, not a reason to preserve the reported confusion.

Status: source-confirmed live context loss and date-copy defect; weekly composition issue identified, installed route reproduction outstanding. Documentation only. Claude owns the paired implementation; no new contest mechanics or notification policy approved here.

### F8 — Course search results hidden by the keyboard

**Owner observation, 2026-09-15:** in live setup, typing a course leaves the search field just above the keyboard and matching courses below it. The golfer must scroll to discover whether search found anything. Expected behavior: results come into view automatically while typing.

Source: `LiveSetupView` has an ordinary `ScrollView` with interactive keyboard dismissal. `LiveCourseField` inserts its courses and tees beneath the input, without a result-visibility callback or scroll anchor. Its search waits 320ms after at least three characters and can show local results before a later network answer; field visibility alone does not ensure asynchronously inserted results are visible. This supports the reported native defect. Equivalent Safari behavior has not been reproduced.

Acceptance for Claude's paired fix: while the field is focused, reveal the input and first complete matching course row above the actual keyboard when results arrive. Show additional rows when space permits; keep the list scrollable. Reveal loading, no-match and offline outcomes in the same visible region so a hidden answer never looks like a missing course. Course selection must bring the tee choices into view too. Preserve keyboard focus while typing, retain the query, and do not select a result automatically. Adjust only when needed; do not jump on every keystroke or fight deliberate scrolling. Honor reduced motion. At very large text sizes or short heights, prioritize a usable search/results region rather than squeezing rows to meet an arbitrary visible count.

Verify with the plan banner present and absent, slow search, cached-to-network updates, empty/offline results, changed queries, course-to-tee selection, keyboard show/hide and enlarged text. Assert actual result frames against the unobscured viewport, not merely element existence. Audit the other course-search entry points and mobile Safari keyboard behavior for the same failure. Native source finding confirmed; paired implementation and physical-device proof outstanding. No search-provider or scoring change requested.

## Sequencing and ownership

1. Keep the frozen counting release separate. Record these findings now; do not silently extend its migration.
2. Claude: bounded paired course selector / saved-state language / worth-copy and color fixes, followed by visible mobile proof.
3. Codex: review selected-tee continuity, round-state routes, numerical wording and paired color states.
4. Appreciation: option A and applause/applauded copy are approved. Implement shared behavior and both clients together after specifying historical-reaction conversion and notification preferences. Server and client deployment states reported separately.

Track each finding as observed → specified → built web/iOS → verified → available on phone. No automatic agent messages or notification delivery were configured by this note.
